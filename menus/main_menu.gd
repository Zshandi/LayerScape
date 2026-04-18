extends CanvasLayer

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_start_button_pressed() -> void:
	LevelManager.load_level(0)
