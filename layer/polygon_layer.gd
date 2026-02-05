extends RefCounted
class_name PolygonLayer

var blend_operation := Geometry2D.OPERATION_UNION

var shapes: Array[PackedVector2Array] = []

func _init(_shapes: Array[PackedVector2Array]=[], _blend_operation:=Geometry2D.OPERATION_UNION):
	shapes = _shapes
	blend_operation = _blend_operation

func duplicate() -> PolygonLayer:
	return PolygonLayer.new(shapes, blend_operation)

func shifted(amount: Vector2) -> PolygonLayer:
	return PolygonLayer.new(PolygonUtil.shift_polygons(shapes, amount), blend_operation)

func offset(amount: float, join_type:=Geometry2D.JOIN_SQUARE) -> PolygonLayer:
	return PolygonLayer.new(PolygonUtil.offset_polygons(shapes, amount, join_type), blend_operation)

func apply_to(other: PolygonLayer) -> PolygonLayer:
	var result := PolygonLayer.new()
	result.blend_operation = other.blend_operation
	
	match blend_operation:
		Geometry2D.OPERATION_INTERSECTION:
			result.shapes = apply_intersection(other)
		Geometry2D.OPERATION_DIFFERENCE:
			result.shapes = apply_difference(other)
		Geometry2D.OPERATION_UNION:
			result.shapes = apply_union(other)
		_:
			result.shapes = apply_union(other)

	return result


func apply_difference(other: PolygonLayer) -> Array[PackedVector2Array]:
	return PolygonUtil.subtract_polygons(other.shapes, shapes)

func apply_intersection(other: PolygonLayer) -> Array[PackedVector2Array]:
	return PolygonUtil.intersect_polygons(shapes, other.shapes)

func apply_union(other: PolygonLayer) -> Array[PackedVector2Array]:
	var result := shapes.duplicate()
	result.append_array(other.shapes)
	result = PolygonUtil.merge_polygons_together(result)
	return result
