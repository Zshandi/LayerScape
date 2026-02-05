@tool
extends CanvasLayer
class_name LayerHud

@onready var positioning_container: MarginContainer = %PositioningContainer

@export_enum("Top Right", "Top Left", "Bottom Right", "Bottom Left")
var container_position: int = 0:
	set(value):
		container_position = value
		_update_container_position()

func _ready() -> void:
	_update_container_position()

func _update_container_position() -> void:
	if positioning_container == null: return
	match (container_position):
		0: # Top Right
			positioning_container.size_flags_horizontal = Control.SIZE_SHRINK_END
			positioning_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		1: # Top Left
			positioning_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			positioning_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		2: # Top Right
			positioning_container.size_flags_horizontal = Control.SIZE_SHRINK_END
			positioning_container.size_flags_vertical = Control.SIZE_SHRINK_END
		3: # Top Left
			positioning_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			positioning_container.size_flags_vertical = Control.SIZE_SHRINK_END

func update_for_layers(layers: Array[Layer]):
	for child in %LayerItems.get_children():
		child.queue_free()
	
	for layer_to_update in layers:
		var new_item := LayerItem.instantiate()
		%LayerItems.add_child(new_item)
		new_item.update_to_match(layer_to_update)

		if layer_to_update == layers[-1]:
			new_item.show_arrow(false)
		else:
			new_item.show_arrow(true)
