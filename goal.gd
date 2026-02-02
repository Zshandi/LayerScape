extends Area2D
class_name Goal

@onready var reached_goal: AudioStreamPlayer2D = $ReachedGoal
var has_reached_goal: bool = false

var shape_rect: Rect2:
	get:
		var rect: Rect2 = %Shape.shape.get_rect()
		rect.position = global_position
		return rect

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterController and not has_reached_goal:
		has_reached_goal = true
		reached_goal.play()
