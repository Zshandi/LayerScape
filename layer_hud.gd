extends CanvasLayer
class_name LayerHud

func update_for_layers(layers: Array[Layer]):
	for child in %LayerItems.get_children():
		child.queue_free()
	
	for layer_to_update in layers:
		var new_item: LayerItem = preload("res://layer_item.tscn").instantiate()
		%LayerItems.add_child(new_item)
		new_item.update_to_match(layer_to_update)

		if layer_to_update == layers[-1]:
			new_item.show_arrow(false)
		else:
			new_item.show_arrow(true)
