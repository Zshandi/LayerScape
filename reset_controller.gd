extends Node

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("reset_level"):
		LevelManager.reload_level()
	if Input.is_action_just_pressed("pause"):
		get_tree().quit()