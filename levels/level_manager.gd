extends Node

const level_complete_sfx = preload("res://assets/sfx/success.wav")

@export
var levels: Array[LevelData]

var level_node: Level:
	set(value):
		if level_node != null:
			level_node.level_complete.disconnect(_on_level_complete)
		level_node = value
		if level_node != null:
			level_node.level_complete.connect(_on_level_complete)

var current_level: int = -1

func _ready() -> void:
	# When we load, just load the first level
	# TODO: Move this to the main menu button
	if current_level == -1:
		if not (get_tree().current_scene is Level):
			load_level(0)
		else:
			level_node = get_tree().current_scene
			var level_scene_path := get_tree().current_scene.scene_file_path
			var idx = 0
			for level_data in levels:
				if level_data.scene.resource_path == level_scene_path:
					current_level = idx
				idx += 1

func _unhandled_key_input(_event: InputEvent) -> void:
	if %EndScreenLayer.visible:
		%EndScreenLayer.hide()
		load_level(0)
	

func load_level(idx: int) -> void:
	current_level = idx
	if current_level >= len(levels):
		# TODO: Go to end menu
		%EndScreenLayer.show()
		level_node = null
		return
		

	level_node = levels[current_level].scene.instantiate()
	get_tree().change_scene_to_node(level_node)
	
func reload_level() -> void:
	level_node = null
	get_tree().reload_current_scene()
	await get_tree().create_timer(0.1).timeout
	level_node = get_tree().current_scene

func _on_level_complete() -> void:
	# TODO: Show win screen with option to go to next level
	if current_level == -1:
		reload_level()
	else:
		load_level(current_level + 1)
