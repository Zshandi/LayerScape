extends Node2D
class_name Layer

@export
var blend_operation: Geometry2D.PolyBooleanOperation

var polygon_layer: PolygonLayer = PolygonLayer.new()

var default_modulate := Color.WHITE
var selected_modulate := Color(0.7, 0.7, 0.7, 1.0)

var player_to_track: Node2D
var layer_tracker: LayerMovementTracker

var locked: bool = true:
	set(value):
		locked = value
		update_color()
		if locked and layer_tracker != null:
			layer_tracker = null
		if not locked and player_to_track != null and layer_tracker == null:
			layer_tracker = LayerMovementTracker.new(self , player_to_track)

var selected: bool = false:
	set(value):
		selected = value
		update_color()

func update_color():
	if selected:
		modulate = selected_modulate
	else:
		modulate = default_modulate
	if locked:
		modulate.a = 0.5

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _global_polygon(polygon: Polygon2D) -> PackedVector2Array:
	var points: PackedVector2Array = []
	
	for point in polygon.polygon:
		points.push_back(polygon.to_global(point))
	
	return points

func update_shapes() -> void:
	if layer_tracker != null:
		layer_tracker.move_to_target()

	polygon_layer.blend_operation = blend_operation
	polygon_layer.shapes.clear()
	for child in get_children():
		if child is Polygon2D:
			polygon_layer.shapes.push_back(_global_polygon(child))


func _on_visibility_changed() -> void:
	pass