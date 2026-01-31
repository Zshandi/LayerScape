extends Node2D

func _process(delta: float) -> void:
	var layer1: PolygonLayer = $Layer1.polygon_layer
	var layer2: PolygonLayer = $Layer2.polygon_layer
	var polygons := layer1.apply_to(layer2)
	while $StaticBody2D.get_child_count() < len(polygons):
		var shape_to_copy: CollisionPolygon2D = $StaticBody2D/OriginalShape
		var new_shape: CollisionPolygon2D = shape_to_copy.duplicate()
		new_shape.polygon = []
		$StaticBody2D.add_child(new_shape)
	var idx = 0
	for point_array in polygons:
		$StaticBody2D.get_child(idx).polygon = point_array
		idx += 1
