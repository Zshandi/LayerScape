extends Object
class_name PolygonUtil

static func get_global_polygon_of(polygon_node: Node2D) -> PackedVector2Array:
	if not ("polygon" in polygon_node): return []
	var points: PackedVector2Array = []
	
	for point in polygon_node.polygon:
		points.push_back(polygon_node.to_global(point))
	
	return points

static func get_child_node_polygons(parent: Node) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	
	for child in parent.get_children():
		var child_polygon := get_global_polygon_of(child)
		if len(child_polygon) > 0:
			result.push_back(child_polygon)
	
	return result

# Pre-condition: `polygons` is an array of non-overlapping polygons
# Results in an array of non-overlapping polygons which is the union of `polygons` with `other`
static func merge_polygons_with_other(polygons: Array[PackedVector2Array], other: PackedVector2Array) -> Array[PackedVector2Array]:
	var result = []
	for polygon in polygons:
		var merge := Geometry2D.merge_polygons(polygon, other)
		# TODO: For now assume there's no holes in the resulting shape,
		#  since if there are holes they will be added as additional shapes
		#  and that needs to be checked for and dealt with somehow
		if len(merge) > 1:
			# No overlap, so just add the shape as-is
			result.push_back(polygon)
		else:
			# Overlapped with other, so update other and continue checking
			other = merge[0]
	result.push_back(other)
	
	return result

# Results in an array of non-overlapping polygons which is the union of all polygons in `polygons`
static func merge_polygons_together(polygons: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result = []
	for polygon in polygons:
		result = merge_polygons_with_other(result, polygon)
	
	return result

static func intersect_polygons(poly1: Array[PackedVector2Array], poly2: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for polygon in poly1:
		for other_polygon in poly2:
			var intersection := Geometry2D.intersect_polygons(polygon, other_polygon)
			result.append_array(intersection)
	return result

static func get_child_node_polygons_merged(parent: Node) -> Array[PackedVector2Array]:
	return merge_polygons_together(get_child_node_polygons(parent))

static func shift_polygon(polygon: PackedVector2Array, amount: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for point in polygon:
		result.push_back(point + amount)
	return result

static func shift_polygons(polygons: Array[PackedVector2Array], amount: Vector2) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for polygon in polygons:
		result.push_back(shift_polygon(polygon, amount))
	return result

static func offset_polygons(polygons: Array[PackedVector2Array], amount: float, join_type:=Geometry2D.JOIN_SQUARE) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for polygon in polygons:
		result.append_array(Geometry2D.offset_polygon(polygon, amount, join_type))
	return result

# Generates nodes to be added to a parent
# Assumes node_or_scene is one of:
#  - Polygon2D,
#  - CollisionPolygon2D,
#  - a PackedScene whose root is one of the above
#  - a path to a PackedScene as above
#  - null, indicating to just use a default Polygon2D
# Assumes that the parent will have a global position of zero to match the polygons exactly
static func generate_polygon_nodes(polygons: Array[PackedVector2Array], node_or_scene: Variant = null, should_free_base_node: bool = false) -> Array[Node2D]:
	var result: Array[Node2D] = []

	var base_node: Node2D = null

	if node_or_scene is String:
		node_or_scene = load(node_or_scene)
	if node_or_scene is PackedScene:
		base_node = node_or_scene.instantiate()
		should_free_base_node = true
	if node_or_scene == null:
		base_node = Polygon2D.new()
		should_free_base_node = true
	else:
		base_node = node_or_scene
	
	assert(base_node is Node2D)
	assert("polygon" in base_node)

	for polygon in polygons:
		var new_node = base_node.duplicate()
		new_node.polygon = polygon
		result.push_back(new_node)

	if should_free_base_node:
		base_node.queue_free()

	return result

# Assumes that the parent will have a global position of zero to match the polygons exactly
static func add_polygon_nodes(parent: Node, polygons: Array[PackedVector2Array], node_or_scene: Variant = null, should_free_base_node: bool = false) -> void:
	var generated_nodes := generate_polygon_nodes(polygons, node_or_scene, should_free_base_node)
	for node in generated_nodes:
		parent.add_child(node)

# Like add, but first removes child polygons
# Assumes that the parent will have a global position of zero to match the polygons exactly
static func replace_polygon_nodes(parent: Node, polygons: Array[PackedVector2Array], node_or_scene: Variant = null, should_free_base_node: bool = false) -> void:
	var generated_nodes := generate_polygon_nodes(polygons, node_or_scene, should_free_base_node)
	for child in parent.get_children():
		if "polygon" in child:
			child.queue_free()
	for node in generated_nodes:
		parent.add_child(node)
