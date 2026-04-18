extends CanvasLayer

func _ready() -> void:
	hide()

func toggle_pause():
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	if visible:
		# Note that if we want any animations etc. in pause menu,
		#  then we need to use global uniform instead (not ideal)
		Engine.time_scale = 0.0
	else:
		Engine.time_scale = 1.0
	# TODO: close options menu if open

func _input(_event: InputEvent) -> void:
	if not visible and get_tree().paused:
		# This indicates the scene was paused for some other purpose,
		#  so we shouldn't pause
		return
	
	if Input.is_action_just_pressed("pause"):
		toggle_pause()


func _on_exit_button_pressed() -> void:
	MusicPlayer.stop_music()
	toggle_pause()
	LevelManager.load_main_menu()

func _on_restart_button_pressed() -> void:
	toggle_pause()
	LevelManager.reload_level()

func _on_resume_button_pressed() -> void:
	toggle_pause()
