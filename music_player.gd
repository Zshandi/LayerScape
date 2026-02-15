extends Node

var mysterious_cave: AudioStream = preload("res://assets/music/mysterious_cave.wav")

var music_player: AudioStreamPlayer
func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_music_player_finished)


func play_music(music: AudioStream) -> void:
	if music_player.stream != music:
		music_player.stop()
		music_player.stream = music
		music_player.play()

func stop_music() -> void:
	music_player.stop()

func pause_music() -> void:
	music_player.stream_paused = true

func resume_music() -> void:
	music_player.stream_paused = false
	if not music_player.playing:
		music_player.play()

# Specific music methods

func play_mysterious_cave() -> void:
	play_music(mysterious_cave)

func _music_player_finished() -> void:
	music_player.play()