@tool
extends CollisionPolygon2D
class_name CollisionShapeRender

var render_shape: Polygon2D

func _ready() -> void:
	for child in get_children():
		if child is Polygon2D:
			render_shape = child
			break
	if render_shape == null:
		render_shape = Polygon2D.new()
		add_child(render_shape)

func _process(_delta: float) -> void:
	render_shape.polygon = polygon
