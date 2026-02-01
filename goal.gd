extends Area2D
class_name Goal

var shape_rect: Rect2:
	get:
		var rect: Rect2 = %Shape.shape.get_rect()
		rect.position = global_position
		return rect