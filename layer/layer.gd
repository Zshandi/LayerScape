extends Node2D
class_name Layer

const player_velocity_tolerance: float = 3

@export
var blend_operation: Geometry2D.PolyBooleanOperation = Geometry2D.OPERATION_UNION

@export
var permanent_lock: bool = false

# This is whether the shape adds to takes away from
#  the layer it blends with when expanded in size
func get_contribution_sign() -> int:
	match blend_operation:
		Geometry2D.OPERATION_UNION:
			return 1
		Geometry2D.OPERATION_INTERSECTION:
			return 1
		Geometry2D.OPERATION_DIFFERENCE:
			return -1
	return 1

var overall_contribution_sign: int = get_contribution_sign()

var polygon_renderer: PolygonRenderer

var polygon_layer: PolygonLayer = PolygonLayer.new()
var polygon_layer_result: PolygonLayer = PolygonLayer.new()

var default_modulate := Color.WHITE
var selected_modulate := Color(0.7, 0.7, 0.7, 1.0)

var player_to_track: Character
var layer_tracker: LayerMovementTracker

var locked: bool = true:
	set(value):
		locked = value
		update_color()
		if locked and layer_tracker != null:
			layer_tracker = null
		if not locked and player_to_track != null and layer_tracker == null:
			layer_tracker = LayerMovementTracker.new(self , player_to_track)
		queue_redraw()

var selected: bool = false:
	set(value):
		selected = value
		update_color()
		queue_redraw()

func get_polygon_layer_velocity_shifted(delta: float) -> PolygonLayer:
	if locked:
		return polygon_layer
	else:
		var velocity_offset := player_to_track.next_velocity * delta * player_velocity_tolerance
		var size_offset := velocity_offset.length()
		# Offset half by reducing the size
		var offset_layer := polygon_layer.offset(size_offset / 2 * -overall_contribution_sign, Geometry2D.JOIN_MITER)
		# And half by shifting in players direction
		return offset_layer.shifted(velocity_offset / 2)

func set_shapes_modulate(color: Color) -> void:
	for child in get_children():
		if child is Polygon2D:
			child.modulate = color

func update_color():
	var modulate_to_set: Color = default_modulate
	if not locked:
		modulate_to_set.a = 0.5
	set_shapes_modulate(modulate_to_set)

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	update_color()
	queue_redraw()
	# Setup alternate rendering
	polygon_renderer = PolygonRenderer.add_renderer(self )
	for child in get_children():
		if child is Polygon2D:
			child.hide()

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
	
	# Layer rendering
	polygon_renderer.render_polygons(polygon_layer.shapes)
	polygon_renderer.global_position = Vector2.ZERO

func get_game_objects() -> Array[GameObject]:
	var result: Array[GameObject] = []
	for child in get_children():
		if child is GameObject:
			result.push_back(child)
	return result

func _on_visibility_changed() -> void:
	pass

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var line_color := Color.WHITE
	var line_width = 1.0

	if selected:
		line_width = 5.0
	
	for polygon_points in polygon_layer.shapes:
		polygon_points.push_back(polygon_points[0])
		var new_polygon: PackedVector2Array = []
		for point in polygon_points:
			new_polygon.push_back(point - global_position)
		draw_polyline(new_polygon, line_color, line_width, true)