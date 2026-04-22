extends CenterContainer

signal closed

@export
var show_erase_save_data_button := true:
	set(value):
		show_erase_save_data_button = value
		%EraseSaveDataContainer.visible = value

@onready
var toggle_full_screen_btn: Button = %FullScreenButton
@onready
var music_volume_slider: Slider = %MusicVolumeSlider
@onready
var sound_volume_slider: Slider = %SoundVolumeSlider

var music_volume_tween: Tween

func _on_full_screen_button_toggled(toggled_on: bool) -> void:
	print_debug("_on_full_screen_button_toggled: ", toggled_on)
	Options.is_full_screen = toggled_on
	# Need to wait a moment for full screen on Web to update
	print_debug("before get_tree().create_timer(0.1).timeout")
	await get_tree().create_timer(0.1).timeout
	print_debug("get_tree().create_timer(0.1).timeout")
	update_button_texts()

func _on_music_volume_slider_value_changed(value: float) -> void:
	Options.music_volume = value
	if not %Music.playing:
		%Music.play()
	
	if music_volume_tween != null:
		music_volume_tween.kill()
		%Music.volume_linear = 1.0
	music_volume_tween = create_tween()
	music_volume_tween.tween_interval(4)
	music_volume_tween.tween_property(%Music, "volume_linear", 0, 2)
	music_volume_tween.tween_callback(
		func():
			music_volume_tween=null
			%Music.volume_linear=1.0
			%Music.stop()
	)

func _on_sound_volume_slider_value_changed(value: float) -> void:
	Options.sound_volume = value
	%Sound.pitch_scale = randf_range(0.8, 1.1)
	%Sound.play()

func update_button_texts() -> void:
	print_debug("update_button_texts")
	if Options.is_full_screen:
		print_debug("setting full screen button text: Exit Full Screen")
		toggle_full_screen_btn.text = "Exit Full Screen"
	else:
		print_debug("setting full screen button text: Enter Full Screen")
		toggle_full_screen_btn.text = "Enter Full Screen"

func _on_back_button_pressed() -> void:
	self.visible = false

func _on_visibility_changed() -> void:
	if not visible:
		close_erase_save_confirmation()

		if music_volume_tween != null:
			music_volume_tween.kill()
			music_volume_tween = null
		%Music.stop()
		%Music.volume_linear = 1.0

		Options.write_options()
		closed.emit()
	else:
		reload_options()
		%BackButton.grab_focus()

func _ready() -> void:
	reload_options()

func reload_options() -> void:
	if is_node_ready():
		toggle_full_screen_btn.set_pressed_no_signal(Options.is_full_screen)
		music_volume_slider.set_value_no_signal(Options.music_volume)
		sound_volume_slider.set_value_no_signal(Options.sound_volume)
		update_button_texts()


func open_erase_save_confirmation() -> void:
	if !is_inside_tree():
		return
	%EraseBaseContainer.hide()
	%EraseConfirmContainer.show()
	%EraseCancelButton.grab_focus()

func close_erase_save_confirmation() -> void:
	if !is_inside_tree():
		return
	%EraseConfirmContainer.hide()
	%EraseBaseContainer.show()
	%EraseSaveDataButton.grab_focus()

func _on_erase_save_data_button_pressed() -> void:
	open_erase_save_confirmation()

func _on_erase_cancel_button_pressed() -> void:
	close_erase_save_confirmation()

func _on_erase_confirm_button_pressed() -> void:
	close_erase_save_confirmation()
	# TODO: Actually erase save data once we have save data
	print_debug("ERASE ASVE CONFIRMED")
