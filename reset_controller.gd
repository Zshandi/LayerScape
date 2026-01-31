extends Node

func _input(event: InputEvent) -> void:
	if event.is_action("reset_level"):
		get_tree().reload_current_scene()
	if event.is_action("pause"):
		get_tree().quit()