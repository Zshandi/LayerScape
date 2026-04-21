extends CanvasLayer

func _ready() -> void:
	%StartButton.grab_focus()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_start_button_pressed() -> void:
	LevelManager.load_level(0)

func _on_options_button_pressed() -> void:
	%MainMenu.hide()
	%OptionsMenu.show()

func _on_options_menu_closed() -> void:
	%OptionsMenu.hide()
	%MainMenu.show()
	%OptionsButton.grab_focus()