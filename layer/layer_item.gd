extends MarginContainer
class_name LayerItem

static func instantiate() -> LayerItem:
	return preload("./layer_item.tscn").instantiate()

func update_to_match(layer: Layer):
	if not is_node_ready(): return
	if layer.visible:
		%Visibility.texture = preload("res://assets/graphics/ui/visibility-svgrepo-com.png")
	else:
		%Visibility.texture = preload("res://assets/graphics/ui/visibility-off-svgrepo-com.png")
	
	if layer.locked:
		%Lock.texture = preload("res://assets/graphics/ui/lock-closed-svgrepo-com.png")
	else:
		%Lock.texture = preload("res://assets/graphics/ui/lock-open-svgrepo-com.png")
	
	match layer.blend_operation:
		Geometry2D.OPERATION_UNION:
			%BlendMode.texture = preload("res://assets/graphics/ui/blen_mode_union.png")
		Geometry2D.OPERATION_INTERSECTION:
			%BlendMode.texture = preload("res://assets/graphics/ui/blen_mode_intersect.png")
		Geometry2D.OPERATION_DIFFERENCE:
			%BlendMode.texture = preload("res://assets/graphics/ui/blen_mode_subtract.png")

	%LayerSelectBorder.visible = layer.selected

	for child in %LayerShapeContainer.get_children():
		child.queue_free()
	
	for polygon_array in layer.polygon_layer.shapes:
		add_polygon(polygon_array)
	for obj in layer.get_game_objects():
		var shape := obj.get_preview_shape()
		%LayerShapeContainer.add_child(shape)
	
	%LayerShapeContainer.position = layer.global_position * 0.001


func add_polygon(shape: PackedVector2Array):
	var polygon := Polygon2D.new()
	polygon.color = Color.BLACK
	polygon.polygon = shape
	%LayerShapeContainer.add_child(polygon)

func show_arrow(_visible: bool) -> void:
	%RightArrow.visible = _visible
