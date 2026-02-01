extends Node2D
class_name Level

signal level_complete

func _on_character_reached_goal() -> void:
	print_debug("goal reached")
	level_complete.emit()
