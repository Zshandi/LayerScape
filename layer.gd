@tool
extends Node2D
class_name Layer

@export
var blend_operation: Geometry2D.PolyBooleanOperation

var polygon_layer: PolygonLayer

func _ready() -> void:
	polygon_layer = PolygonLayer.new()
	polygon_layer.blend_operation = blend_operation
	for child in get_children():
		if child is Polygon2D:
			polygon_layer.shapes.push_back(_global_polygon(child))

func _global_polygon(polygon: Polygon2D) -> PackedVector2Array:
	var points: PackedVector2Array = []
	
	for point in polygon.polygon:
		points.push_back(polygon.to_global(point))
	
	return points
