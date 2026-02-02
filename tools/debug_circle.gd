extends Node2D
class_name DebugCircle

@export
var attached_to: Node2D

func _ready() -> void:
	update_position()

func _process(_delta: float) -> void:
	update_position()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 10, Color.HOT_PINK)

func attach_circle_to(other: Node2D) -> void:
	attached_to = other
	update_position()

func update_position() -> void:
	if attached_to != null:
		global_position = attached_to.global_position
	queue_redraw()
