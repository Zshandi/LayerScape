extends RefCounted
class_name PolygonLayer

var blend_operation: Geometry2D.PolyBooleanOperation

var shapes: Array[PackedVector2Array]

func apply_to(other: PolygonLayer) -> Array[PackedVector2Array]:
	match blend_operation:
		Geometry2D.OPERATION_INTERSECTION:
			return apply_intersection(other)
		Geometry2D.OPERATION_UNION:
			return apply_union(other)
	return apply_union(other)

func apply_intersection(other: PolygonLayer) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for shape in shapes:
		for other_shape in other.shapes:
			var intersection := Geometry2D.intersect_polygons(shape, other_shape)
			result.append_array(intersection)
	return result

func apply_union(other: PolygonLayer) -> Array[PackedVector2Array]:
	var result := other.shapes
	for shape in shapes:
		var new_result: Array[PackedVector2Array] = []
		for other_shape in result:
			var combined := Geometry2D.merge_polygons(shape, other_shape)
			if len(combined) == 2:
				# They didn't overlap, just add the other shape
				new_result.push_back(other_shape)
				if other_shape == result[-1]:
					new_result.push_back(shape)
			else:
				# They did overlap, update to new shape
				shape = combined
				if other_shape == result[-1]:
					new_result.push_back(shape)
		result = new_result
	return result
