extends Node

var music_volume_name := "music_volume"
var music_volume_default := 1.0
var music_volume: float:
	get:
		var index = AudioServer.get_bus_index(&"Music")
		return db_to_linear(AudioServer.get_bus_volume_db(index))
	set(value):
		var index = AudioServer.get_bus_index(&"Music")
		AudioServer.set_bus_volume_db(index, linear_to_db(value))

var sound_volume_name := "sound_volume"
var sound_volume_default := 1.0
var sound_volume: float:
	get:
		var index = AudioServer.get_bus_index(&"Sound")
		return db_to_linear(AudioServer.get_bus_volume_db(index))
	set(value):
		var index = AudioServer.get_bus_index(&"Sound")
		AudioServer.set_bus_volume_db(index, linear_to_db(value))

var last_windowed_mode := DisplayServer.WINDOW_MODE_WINDOWED

var is_full_screen_name := "is_full_screen"
var is_full_screen_default := false
var is_full_screen: bool:
	get:
		return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	set(value):
		if value == is_full_screen: return
		if (value):
			last_windowed_mode = DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(last_windowed_mode)

func _ready() -> void:
	reset_to_defaults()
	read_options()

func write_options() -> void:
	if not is_node_ready(): return
	var option_data = \
	{
		is_full_screen_name: is_full_screen,
		music_volume_name: music_volume,
		sound_volume_name: sound_volume,
	}

	print_debug("Saving options: ", option_data)

	var save_file := FileAccess.open("user://settings", FileAccess.WRITE)
	save_file.store_var(option_data)

func read_options() -> void:
	if !FileAccess.file_exists("user://settings"):
		return
	
	var save_file := FileAccess.open("user://settings", FileAccess.READ)
	var data = save_file.get_var()
	
	print_debug("loading options: ", data)

	is_full_screen = _get_option(data, is_full_screen_name, is_full_screen_default)
	music_volume = _get_option(data, music_volume_name, music_volume_default)
	sound_volume = _get_option(data, sound_volume_name, sound_volume_default)

func reset_to_defaults() -> void:
	music_volume = music_volume_default
	sound_volume = sound_volume_default
	is_full_screen = is_full_screen_default

func _get_option(data: Dictionary, option_name: String, default: Variant) -> Variant:
	if option_name in data:
		print_debug("got value ", option_name, " = ", data[option_name])
		return data[option_name]
	else:
		print_debug("default value ", option_name, " = ", default)
		return default