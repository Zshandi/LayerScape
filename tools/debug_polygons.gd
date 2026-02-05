extends Node2D
class_name DebugPolygons

static var instance: DebugPolygons
func _ready() -> void:
	instance = self

const alpha := 0.6

@export
var colors: Array[Color] = \
[
	Color(Color.HOT_PINK, alpha),
	Color(Color.AQUA, alpha),
	Color(Color.YELLOW, alpha),
	Color(Color.ORANGE, alpha),
	Color(Color.GREEN, alpha),
	Color(Color.BROWN, alpha),
	Color(Color.RED, alpha),
]

@export
var toggle_color_visible: Array[bool] = \
[
	true,
	true,
	true,
	true,
	true,
	true,
	true,
]

@export
var reverse_draw_order: bool = false

static var current_color: int = 0

static func reset() -> void:
	if instance == null or not is_instance_valid(instance): return
	current_color = 0
	for child in instance.get_children():
		child.queue_free()

static func add_polygon(polygon: PackedVector2Array) -> void:
	add_polygons([polygon])

static func add_polygons(polygons: Array[PackedVector2Array]) -> void:
	if instance == null or not is_instance_valid(instance): return
	for polygon in polygons:
		_draw_polygon(polygon)
	current_color = (current_color + 1) % len(instance.colors)

static func _draw_polygon(polygon: PackedVector2Array) -> void:
	if not instance.toggle_color_visible[current_color]: return
	var poly := Polygon2D.new()
	poly.color = instance.colors[current_color]
	poly.polygon = polygon
	instance.add_child(poly)
	if instance.reverse_draw_order:
		instance.move_child(poly, 0)
