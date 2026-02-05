class_name Earcut
extends Node

# ISC License
#
# Copyright (c) 2024, Mapbox
#
# Permission to use, copy, modify, and/or distribute this software for any purpose
# with or without fee is hereby granted, provided that the above copyright notice
# and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
# THIS SOFTWARE.

# GDScript port of 'mapbox/earcut' JavaScript library.
# Source: https://github.com/mapbox/earcut
# Note: This conversion has been made by the help of ChatGPT.

# Has not been optimized for performance. Most earcut.js test-cases have not been validated against this port.

class PolygonNode:
	## vertex index in coordinates array
	var idx: int
	
	## vertex coordinates
	var x: float
	var y: float
	
	## previous and next vertex nodes in a polygon ring
	var prev: Variant = null
	var next: Variant = null
	
	## z-order curve value
	var z_order: int = 0
	
	## previous and next nodes in z-order
	var prev_z: Variant = null
	var next_z: Variant = null
	
	## indicates whether this is a steiner point
	var steiner: bool = false
	
	func _init(idx_val: int, x_val: float, y_val: float):
		idx = idx_val
		x = x_val
		y = y_val

static func earcut(
	data: PackedFloat32Array,
	hole_indices: Array[int]=[],
	dim: int = 2
) -> Array[int]:
	var has_holes: bool = hole_indices.size() > 0
	var outer_len: int = hole_indices[0] * dim if has_holes else data.size()
	var outer_node: PolygonNode = _linked_list(data, 0, outer_len, dim, true)
	var triangles: Array[int] = []
	
	if outer_node == null or outer_node.next == outer_node.prev:
		return triangles
	
	var min_x: float
	var min_y: float
	var inv_size: float = 0.0
	
	if has_holes:
		outer_node = _eliminate_holes(data, hole_indices, outer_node, dim)
	
	# if the shape is not too simple, we'll use z-order curve hash later; calculate polygon bbox
	if data.size() > 80 * dim:
		min_x = data[0]
		min_y = data[1]
		var max_x: float = min_x
		var max_y: float = min_y
		for i in range(dim, outer_len, dim):
			var x: float = data[i]
			var y: float = data[i + 1]
			if x < min_x: min_x = x
			if y < min_y: min_y = y
			if x > max_x: max_x = x
			if y > max_y: max_y = y
		
		# minX, minY and invSize are later used to transform coords into integers for z-order calculation
		inv_size = max(max_x - min_x, max_y - min_y)
		inv_size = 32767.0 / inv_size if not is_zero_approx(inv_size) else 0.0
	
	_earcut_linked(outer_node, triangles, dim, min_x, min_y, inv_size, 0)
	
	return triangles

## create a circular doubly linked list from polygon points in the specified winding order
static func _linked_list(
	data: PackedFloat32Array,
	start: int,
	end: int,
	dim: int,
	clockwise: bool
) -> PolygonNode:
	if dim < 2 or data.size() < end or start < 0 or end <= start:
		return null

	var last: PolygonNode = null
	var area_positive: bool = _signed_area(data, start, end, dim) > 0

	if clockwise == area_positive:
		# forward iteration
		var i: int = start
		while i < end:
			if i + 1 >= data.size():
				break
			@warning_ignore("integer_division")
			last = _insert_node(i / dim, data[i], data[i + 1], last)
			i += dim
	else:
		# reverse iteration
		var i: int = end - dim
		while i >= start:
			if i + 1 >= data.size():
				break
			@warning_ignore("integer_division")
			last = _insert_node(i / dim, data[i], data[i + 1], last)
			i -= dim

	if last and _equals(last, last.next):
		_remove_node(last)
		last = last.next

	return last

## eliminate collinear or duplicate points
static func _filter_points(start: PolygonNode, end: PolygonNode = null) -> PolygonNode:
	if not start:
		return start
	if end == null:
		end = start
	
	var p: PolygonNode = start
	var again: bool = false
	
	while true:
		again = false
		if not p.steiner and (_equals(p, p.next) or is_zero_approx(_area(p.prev, p, p.next))):
			_remove_node(p)
			p = p.prev
			end = p
			if p == p.next:
				break
			again = true
		else:
			p = p.next
		
		if not again and p == end:
			break
	
	return end

## main ear slicing loop which triangulates a polygon (given as a linked list)
static func _earcut_linked(
	ear: PolygonNode,
	triangles: Array[int],
	dim: int,
	min_x: float,
	min_y: float,
	inv_size: float,
	pass_value: int
) -> void:
	if ear == null: return
	
	# interlink polygon nodes in z-order
	if pass_value == 0 and not is_zero_approx(inv_size):
		_index_curve(ear, min_x, min_y, inv_size)
	
	var stop: PolygonNode = ear
	
	while ear.prev != ear.next:
		var prev: PolygonNode = ear.prev
		var nxt: PolygonNode = ear.next
		
		if ((not is_zero_approx(inv_size) and _is_ear_hashed(ear, min_x, min_y, inv_size))
		or (is_zero_approx(inv_size) and _is_ear(ear))):
			triangles.push_back(prev.idx)
			triangles.push_back(ear.idx)
			triangles.push_back(nxt.idx)
			
			_remove_node(ear)
			
			ear = nxt.next
			stop = nxt.next
			continue
		
		ear = nxt
		
		if ear == stop:
			if pass_value == 0:
				_earcut_linked(_filter_points(ear), triangles, dim, min_x, min_y, inv_size, 1)
			elif pass_value == 1:
				ear = _cure_local_intersections(_filter_points(ear), triangles)
				_earcut_linked(ear, triangles, dim, min_x, min_y, inv_size, 2)
			elif pass_value == 2:
				_split_earcut(ear, triangles, dim, min_x, min_y, inv_size)
			break

## check whether a polygon node forms a valid ear with adjacent nodes
static func _is_ear(ear: PolygonNode) -> bool:
	var a: PolygonNode = ear.prev
	var b: PolygonNode = ear
	var c: PolygonNode = ear.next
	
	# reflex vertex can't be an ear
	if _area(a, b, c) >= 0.0:
		return false
	
	var ax: float = a.x
	var ay: float = a.y
	var bx: float = b.x
	var by: float = b.y
	var cx: float = c.x
	var cy: float = c.y
	
	# triangle bbox
	var x0: float = minf(ax, minf(bx, cx))
	var y0: float = minf(ay, minf(by, cy))
	var x1: float = maxf(ax, maxf(bx, cx))
	var y1: float = maxf(ay, maxf(by, cy))
	
	# check all vertices between c and a
	var p: PolygonNode = c.next
	while p != a:
		if p.x >= x0 and p.x <= x1 and p.y >= y0 and p.y <= y1 \
		and _point_in_triangle_except_first(ax, ay, bx, by, cx, cy, p.x, p.y) \
		and _area(p.prev, p, p.next) >= 0.0:
			return false
		p = p.next
	
	return true

static func _is_ear_hashed(ear: PolygonNode, min_x: float, min_y: float, inv_size: float) -> bool:
	var a: PolygonNode = ear.prev
	var b: PolygonNode = ear
	var c: PolygonNode = ear.next

	if _area(a, b, c) >= 0.0:
		return false

	var ax: float = a.x
	var ay: float = a.y
	var bx: float = b.x
	var by: float = b.y
	var cx: float = c.x
	var cy: float = c.y

	# triangle bbox
	var x0: float = minf(ax, minf(bx, cx))
	var y0: float = minf(ay, minf(by, cy))
	var x1: float = maxf(ax, maxf(bx, cx))
	var y1: float = maxf(ay, maxf(by, cy))

	# z-order range
	var min_z: int = _z_order(x0, y0, min_x, min_y, inv_size)
	var max_z: int = _z_order(x1, y1, min_x, min_y, inv_size)

	var p: PolygonNode = ear.prev_z
	var n: PolygonNode = ear.next_z

	# search both directions within z-range
	while p and p.z_order >= min_z and n and n.z_order <= max_z:
		if p.x >= x0 and p.x <= x1 and p.y >= y0 and p.y <= y1 and p != a and p != c \
		and _point_in_triangle_except_first(ax, ay, bx, by, cx, cy, p.x, p.y) \
		and _area(p.prev, p, p.next) >= 0.0:
			return false
		p = p.prev_z

		if n.x >= x0 and n.x <= x1 and n.y >= y0 and n.y <= y1 and n != a and n != c \
		and _point_in_triangle_except_first(ax, ay, bx, by, cx, cy, n.x, n.y) \
		and _area(n.prev, n, n.next) >= 0.0:
			return false
		n = n.next_z

	# remaining in decreasing z
	while p and p.z_order >= min_z:
		if p.x >= x0 and p.x <= x1 and p.y >= y0 and p.y <= y1 and p != a and p != c \
		and _point_in_triangle_except_first(ax, ay, bx, by, cx, cy, p.x, p.y) \
		and _area(p.prev, p, p.next) >= 0.0:
			return false
		p = p.prev_z

	# remaining in increasing z
	while n and n.z_order <= max_z:
		if n.x >= x0 and n.x <= x1 and n.y >= y0 and n.y <= y1 and n != a and n != c \
		and _point_in_triangle_except_first(ax, ay, bx, by, cx, cy, n.x, n.y) \
		and _area(n.prev, n, n.next) >= 0.0:
			return false
		n = n.next_z

	return true

## go through all polygon nodes and cure small local self-intersections
static func _cure_local_intersections(start: PolygonNode, triangles: Array[int]) -> PolygonNode:
	var p: PolygonNode = start
	while true:
		var a: PolygonNode = p.prev
		var b: PolygonNode = p.next.next
		
		if not _equals(a, b) and _intersects(a, p, p.next, b) and _locally_inside(a, b) and _locally_inside(b, a):
			triangles.push_back(a.idx)
			triangles.push_back(p.idx)
			triangles.push_back(b.idx)
			
			_remove_node(p)
			_remove_node(p.next)
			
			p = b
			start = b
		
		p = p.next
		if p == start:
			break
	
	return _filter_points(p)

## try splitting polygon into two and triangulate them independently
static func _split_earcut(
	start: PolygonNode,
	triangles: Array[int],
	dim: int,
	min_x: float,
	min_y: float,
	inv_size: float
) -> void:
	var a: PolygonNode = start
	while true:
		var b: PolygonNode = a.next.next
		while b != a.prev:
			if a.idx != b.idx and _is_valid_diagonal(a, b):
				var c: PolygonNode = _split_polygon(a, b)
				
				# filter collinear points around the cuts
				a = _filter_points(a, a.next)
				c = _filter_points(c, c.next)
				
				_earcut_linked(a, triangles, dim, min_x, min_y, inv_size, 0)
				_earcut_linked(c, triangles, dim, min_x, min_y, inv_size, 0)
				return
			b = b.next
		a = a.next
		if a == start:
			break

## link every hole into the outer loop, producing a single-ring polygon without holes
static func _eliminate_holes(
	data: PackedFloat32Array,
	hole_indices: Array[int],
	outer_node: PolygonNode,
	dim: int
) -> PolygonNode:
	var queue: Array = []
	
	for i in range(hole_indices.size()):
		var start: int = hole_indices[i] * dim
		var end: int = hole_indices[i + 1] * dim if (i < hole_indices.size() - 1) else data.size()
		var list: PolygonNode = _linked_list(data, start, end, dim, false)
		if list == list.next:
			list.steiner = true
		queue.append(_get_leftmost(list))
	
	# sort by x/y slope
	queue.sort_custom(_compare_x_y_slope)
	
	for hole in queue:
		outer_node = _eliminate_hole(hole, outer_node)
	
	return outer_node

static func _compare_x_y_slope(a: PolygonNode, b: PolygonNode) -> bool:
	var result: float = a.x - b.x
	if is_zero_approx(result):
		result = a.y - b.y
		if is_zero_approx(result):
			var a_slope: float = (a.next.y - a.y) / (a.next.x - a.x)
			var b_slope: float = (b.next.y - b.y) / (b.next.x - b.x)
			result = a_slope - b_slope
	
	return result < 0

## find a bridge between vertices that connects hole with an outer ring and link it
static func _eliminate_hole(hole: PolygonNode, outer_PolygonNode: PolygonNode) -> PolygonNode:
	var bridge: PolygonNode = _find_hole_bridge(hole, outer_PolygonNode)
	if bridge == null:
		return outer_PolygonNode
	
	var bridge_reverse: PolygonNode = _split_polygon(bridge, hole)
	
	# filter collinear points around the cuts
	_filter_points(bridge_reverse, bridge_reverse.next)
	return _filter_points(bridge, bridge.next)


## David Eberly's algorithm for finding a bridge between hole and outer polygon
static func _find_hole_bridge(hole: PolygonNode, outer_node: PolygonNode) -> PolygonNode:
	var p: PolygonNode = outer_node
	var hx: float = hole.x
	var hy: float = hole.y
	var qx: float = - INF
	var m: PolygonNode = null
	
	if _equals(hole, p):
		return p
	
	while true:
		if _equals(hole, p.next):
			return p.next
		elif hy <= p.y and hy >= p.next.y and p.next.y != p.y:
			var x: float = p.x + (hy - p.y) * (p.next.x - p.x) / (p.next.y - p.y)
			if x <= hx and x > qx:
				qx = x
				m = p if (p.x < p.next.x) else p.next
				if x == hx:
					return m
		p = p.next
		if p == outer_node:
			break
	
	if m == null:
		return null
	
	# check points inside triangle
	var stop: PolygonNode = m
	var mx: float = m.x
	var my: float = m.y
	var tan_min: float = INF
	
	p = m
	while true:
		var ax: float = hx if hy < my else qx
		var bx: float = qx if hy < my else hx
		
		if (hx >= p.x
		and p.x >= mx
		and hx != p.x
		and _point_in_triangle(ax, hy, mx, my, bx, hy, p.x, p.y)):
			var ptan: float = absf(hy - p.y) / (hx - p.x)
			
			if (_locally_inside(p, hole)
			and (ptan < tan_min
				or (ptan == tan_min
					and (p.x > m.x
						or (p.x == m.x
							and _sector_contains_sector(m, p)))))):
				m = p
				tan_min = ptan
		p = p.next
		if p == stop:
			break
	
	return m

static func _sector_contains_sector(m: PolygonNode, p: PolygonNode) -> float:
	return _area(m.prev, m, p.prev) < 0.0 && _area(p.next, m, m.next) < 0.0;

## interlink polygon PolygonNodes in z-order
static func _index_curve(start: PolygonNode, min_x: float, min_y: float, inv_size: float) -> void:
	var p: PolygonNode = start
	while true:
		if p.z_order == 0:
			p.z_order = _z_order(p.x, p.y, min_x, min_y, inv_size)
		p.prev_z = p.prev
		p.next_z = p.next
		p = p.next
		if p == start:
			break
	
	p.prev_z.next_z = null
	p.prev_z = null
	
	_sort_linked(p)

## Simon Tatham's linked list merge sort for z-order PolygonNodes
static func _sort_linked(list: PolygonNode) -> PolygonNode:
	var in_size: int = 1
	
	while true:
		var p: PolygonNode = list
		var new_list: PolygonNode = null
		var tail: PolygonNode = null
		var num_merges: int = 0
		
		while p:
			num_merges += 1
			var q: PolygonNode = p
			var p_size: int = 0
			for i in range(in_size):
				p_size += 1
				q = q.next_z
				if not q:
					break
			var q_size: int = in_size
			
			while p_size > 0 or (q_size > 0 and q):
				var e: PolygonNode
				if p_size != 0 and (q_size == 0 or not q or p.z_order <= q.z_order):
					e = p
					p = p.next_z
					p_size -= 1
				else:
					e = q
					q = q.next_z
					q_size -= 1
				
				if tail:
					tail.next_z = e
				else:
					new_list = e
				
				e.prev_z = tail
				tail = e
			
			p = q
		
		# close the merged list
		if tail:
			tail.next_z = null
		
		in_size *= 2
		list = new_list
		
		if num_merges <= 1:
			break
	
	return list

## z-order of a point given coords and inverse of the longer side of data bbox
static func _z_order(x: float, y: float, min_x: float, min_y: float, inv_size: float) -> int:
	# coords are transformed into non-negative 15-bit integer range
	var xi: int = int((x - min_x) * inv_size)
	var yi: int = int((y - min_y) * inv_size)
	
	xi = (xi | (xi << 8)) & 0x00FF00FF
	xi = (xi | (xi << 4)) & 0x0F0F0F0F
	xi = (xi | (xi << 2)) & 0x33333333
	xi = (xi | (xi << 1)) & 0x55555555
	
	yi = (yi | (yi << 8)) & 0x00FF00FF
	yi = (yi | (yi << 4)) & 0x0F0F0F0F
	yi = (yi | (yi << 2)) & 0x33333333
	yi = (yi | (yi << 1)) & 0x55555555
	
	return xi | (yi << 1)

static func _get_leftmost(start: PolygonNode) -> PolygonNode:
	var p: PolygonNode = start
	var leftmost: PolygonNode = start
	
	while true:
		if p.x < leftmost.x or (is_equal_approx(p.x, leftmost.x) and p.y < leftmost.y):
			leftmost = p
		p = p.next
		if p == start:
			break
	
	return leftmost

## check if a point lies within a convex triangle
static func _point_in_triangle(
	ax: float,
	ay: float,
	bx: float,
	by: float,
	cx: float,
	cy: float,
	px: float,
	py: float
) -> bool:
	return (cx - px) * (ay - py) >= (ax - px) * (cy - py) \
		and (ax - px) * (by - py) >= (bx - px) * (ay - py) \
		and (bx - px) * (cy - py) >= (cx - px) * (by - py)

## check if a point lies within a convex triangle but false if it’s equal to the first point of the triangle
static func _point_in_triangle_except_first(
	ax: float,
	ay: float,
	bx: float,
	by: float,
	cx: float,
	cy: float,
	px: float,
	py: float
) -> bool:
	if is_equal_approx(ax, px) and is_equal_approx(ay, py):
		return false
	
	return _point_in_triangle(ax, ay, bx, by, cx, cy, px, py)

## check if a diagonal between two polygon nodes is valid (lies in polygon interior)
static func _is_valid_diagonal(a: PolygonNode, b: PolygonNode) -> bool:
	return a.next.idx != b.idx and a.prev.idx != b.idx and not _intersects_polygon(a, b) and \
		(
			(_locally_inside(a, b) and _locally_inside(b, a) and _middle_inside(a, b) and (_area(a.prev, a, b.prev) != 0 or _area(a, b.prev, b) != 0)) or \
			(_equals(a, b) and _area(a.prev, a, a.next) > 0 and _area(b.prev, b, b.next) > 0)
		)

# signed area of a triangle
static func _area(a: PolygonNode, b: PolygonNode, c: PolygonNode) -> float:
		return (b.y - a.y) * (c.x - b.x) - (b.x - a.x) * (c.y - b.y)

## check if two points are equal
static func _equals(p1: PolygonNode, p2: PolygonNode) -> bool:
	return is_equal_approx(p1.x, p2.x) and is_equal_approx(p1.y, p2.y)

## check if two segments intersect
static func _intersects(p1: PolygonNode, q1: PolygonNode, p2: PolygonNode, q2: PolygonNode) -> bool:
	var o1: int = _sign_int(int(_area(p1, q1, p2)))
	var o2: int = _sign_int(int(_area(p1, q1, q2)))
	var o3: int = _sign_int(int(_area(p2, q2, p1)))
	var o4: int = _sign_int(int(_area(p2, q2, q1)))
	
	if o1 != o2 and o3 != o4:
		return true
	
	if o1 == 0 and _on_segment(p1, p2, q1):
		return true
	if o2 == 0 and _on_segment(p1, q2, q1):
		return true
	if o3 == 0 and _on_segment(p2, p1, q2):
		return true
	if o4 == 0 and _on_segment(p2, q1, q2):
		return true
	
	return false

## for collinear points p, q, r, check if point q lies on segment pr
static func _on_segment(p: PolygonNode, q: PolygonNode, r: PolygonNode) -> bool:
	return (
		q.x <= maxf(p.x, r.x) and q.x >= minf(p.x, r.x) and
		q.y <= maxf(p.y, r.y) and q.y >= minf(p.y, r.y)
	)

static func _sign_int(n: int) -> int:
	if n > 0:
		return 1
	elif n < 0:
		return -1
	else:
		return 0

## check if a polygon diagonal intersects any polygon segments
static func _intersects_polygon(a: PolygonNode, b: PolygonNode) -> bool:
	var p: PolygonNode = a
	while true:
		if p.idx != a.idx and p.next.idx != a.idx and p.idx != b.idx and p.next.idx != b.idx:
			if _intersects(p, p.next, a, b):
				return true
		p = p.next
		if p == a:
			break
	return false

## check if a polygon diagonal is locally inside the polygon
static func _locally_inside(a: PolygonNode, b: PolygonNode) -> bool:
	if _area(a.prev, a, a.next) < 0:
		return _area(a, b, a.next) >= 0 and _area(a, a.prev, b) >= 0
	else:
		return _area(a, b, a.prev) < 0 or _area(a, a.next, b) < 0

## check if the middle point of a polygon diagonal is inside the polygon
static func _middle_inside(a: PolygonNode, b: PolygonNode) -> bool:
	var px: float = (a.x + b.x) / 2.0
	var py: float = (a.y + b.y) / 2.0
	var inside: bool = false
	
	var p: PolygonNode = a
	while true:
		if ((p.y > py) != (p.next.y > py)) and p.next.y != p.y:
			var x_cross: float = (p.next.x - p.x) * (py - p.y) / (p.next.y - p.y) + p.x
			if px < x_cross:
				inside = not inside
		p = p.next
		if p == a:
			break
	
	return inside

## link two polygon vertices with a bridge; if the vertices belong to the same ring, it splits polygon into two;
## if one belongs to the outer ring and another to a hole, it merges it into a single ring
static func _split_polygon(a: PolygonNode, b: PolygonNode) -> PolygonNode:
	var a2: PolygonNode = PolygonNode.new(a.idx, a.x, a.y)
	var b2: PolygonNode = PolygonNode.new(b.idx, b.x, b.y)
	var an: PolygonNode = a.next
	var bp: PolygonNode = b.prev
	
	a.next = b
	b.prev = a
	
	a2.next = an
	an.prev = a2
	
	b2.next = a2
	a2.prev = b2
	
	bp.next = b2
	b2.prev = bp
	
	return b2

## create a PolygonNode and optionally link it with previous one (in a circular doubly linked list)
static func _insert_node(i: int, x: float, y: float, last: Variant) -> PolygonNode:
	var p: PolygonNode = _create_node(i, x, y)
	
	if last == null:
		p.prev = p
		p.next = p
	else:
		p.next = last.next
		p.prev = last
		last.next.prev = p
		last.next = p
	
	return p

static func _remove_node(p: PolygonNode) -> void:
	p.next.prev = p.prev
	p.prev.next = p.next
	
	if p.prev_z:
		p.prev_z.next_z = p.next_z
	if p.next_z:
		p.next_z.prev_z = p.prev_z

static func _create_node(i: int, x: float, y: float) -> PolygonNode:
	return PolygonNode.new(i, x, y)

## return a percentage difference between the polygon area and its triangulation area
static func deviation(data: PackedFloat32Array, hole_indices: Array[int], dim: int, triangles: Array[int]) -> float:
	var has_holes: int = hole_indices != null and hole_indices.size() > 0
	var outer_len: int = hole_indices[0] * dim if has_holes else data.size()
	
	var polygon_area: float = absf(_signed_area(data, 0, outer_len, dim))
	if has_holes:
		for i in range(hole_indices.size()):
			var start: int = hole_indices[i] * dim
			var end: int = hole_indices[i + 1] * dim if (i < hole_indices.size() - 1) else data.size()
			polygon_area -= absf(_signed_area(data, start, end, dim))
	
	var triangles_area: float = 0.0
	for i in range(0, triangles.size(), 3):
		var a: int = triangles[i] * dim
		var b: int = triangles[i + 1] * dim
		var c: int = triangles[i + 2] * dim
		triangles_area += absf(
			(data[a] - data[c]) * (data[b + 1] - data[a + 1]) -
			(data[a] - data[b]) * (data[c + 1] - data[a + 1])
		)
	
	if is_zero_approx(polygon_area) and is_zero_approx(triangles_area):
		return 0.0
	return absf((triangles_area - polygon_area) / polygon_area)

## signed area of a polygon (shoelace formula variant used by earcut)
static func _signed_area(data: PackedFloat32Array, start: int, end: int, dim: int) -> float:
	# Must have at least 2D coords (x,y)
	if dim < 2 or data.size() < end or start < 0 or end <= start:
		return 0.0

	var sum: float = 0.0
	var j: int = end - dim
	var i: int = start

	while i < end:
		# ensure i+1 and j+1 are safe
		if i + 1 >= data.size() or j + 1 >= data.size():
			break
		sum += (data[j] - data[i]) * (data[i + 1] + data[j + 1])
		j = i
		i += dim

	return sum

## turn a polygon in multi-dimensional array form (e.g. as in GeoJSON) into Earcut input
static func flatten(data: Array, dimensions: int) -> Dictionary:
	var vertices := PackedFloat32Array()
	var holes := PackedInt32Array()
	
	var hole_index: int = 0
	var prev_len: int = 0
	
	for ring in data:
		for p in ring:
			for d in range(dimensions):
				vertices.append(float(p[d]))
		if prev_len > 0:
			hole_index += prev_len
			holes.append(hole_index)
		prev_len = (ring as Array).size()
	
	return {
		"vertices": vertices,
		"holes": holes,
		"dimensions": dimensions
	}