extends CanvasLayer

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion or event is InputEventJoypadMotion):
		LevelManager.load_main_menu()