extends GameObject
class_name Goal

var shape_rect: Rect2:
	get:
		var rect: Rect2 = %Shape.shape.get_rect()
		rect.position = global_position - Vector2(rect.size.x / 2, rect.size.y)
		return rect

func get_preview_shape() -> Polygon2D:
	var shape := Polygon2D.new()
	var rect := shape_rect
	shape.polygon = \
	[ \
		rect.position, rect.position + Vector2(rect.size.x, 0), \
		rect.position + rect.size, rect.position + Vector2(0, rect.size.y) \
	]
	shape.color = Color.HOT_PINK

	return shape