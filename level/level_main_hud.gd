@tool
extends CanvasLayer
class_name LevelMainHud

@export_enum("Top Right", "Top Left", "Bottom Right", "Bottom Left")
var layer_hud_position: int = 0:
	set(value):
		layer_hud_position = value
		if layer_hud != null:
			layer_hud.container_position = value

var layer_hud: LayerHud:
	get: return %LayerHud

func _ready() -> void:
	layer_hud.container_position = layer_hud_position