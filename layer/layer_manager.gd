extends Node2D
class_name LayerManager

@export
var player_to_track: Node2D

var layers: Array[Layer]

var result_colliders: Array[CollisionPolygon2D]

var source_collider: CollisionPolygon2D

var selected_layer: Layer:
	get: return layers[selected_layer_index]

var selected_layer_index: int = 0:
	set(value):
		if len(layers) == 0:
			selected_layer_index = 0
			return
		
		layers[selected_layer_index].selected = false

		selected_layer_index = value
		if selected_layer_index >= len(layers):
			selected_layer_index = len(layers) - 1
		if selected_layer_index < 0:
			selected_layer_index = 0
		
		layers[selected_layer_index].selected = true


func _ready() -> void:
	source_collider = %LayerResultSourceShape
	source_collider.polygon = []

	for child in get_children():
		if child is Layer:
			layers.push_back(child)
			child.player_to_track = player_to_track
	
	if len(layers) <= 0:
		layers.push_back(Layer.new())
	layers.reverse()
	layers[selected_layer_index].selected = true

	update_result()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# 1 to 9 are in sequence, these select the layers
		if not (event.keycode >= KEY_1 and event.keycode <= KEY_9):
			return
		var key_index: int = event.keycode - KEY_1
		if key_index >= len(layers):
			# Ignore attempt to set to higher layer
			return
		selected_layer_index = key_index

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("lock_toggle"):
		selected_layer.locked = not selected_layer.locked
	
	if Input.is_action_just_pressed("visible_toggle"):
		selected_layer.visible = not selected_layer.visible
	
	if Input.is_action_just_pressed("layer_next"):
		selected_layer_index += 1
	if Input.is_action_just_pressed("layer_prev"):
		selected_layer_index -= 1
	
	update_result()

func update_result() -> void:
	# Update the layer polygons
	for layer in layers:
		layer.update_shapes()

	# Calculate result polygons by combining layers
	var running_result := PolygonLayer.new()
	var idx = 0
	for layer in layers:
		if (not layer.locked) and layer.blend_operation == Geometry2D.PolyBooleanOperation.OPERATION_UNION:
			DebugValues.debug("layer[" + str(idx) + "]", "skipped")
			# TODO: Make this better
			if running_result.blend_operation != Geometry2D.PolyBooleanOperation.OPERATION_UNION:
				running_result = PolygonLayer.new()
			continue
		DebugValues.debug("layer[" + str(idx) + "]", "included")
		running_result = running_result.apply_to(layer.polygon_layer)
		idx += 1
	
	# Construct final polygons
	var polygons := running_result.shapes

	while len(result_colliders) < len(polygons):
		var new_shape: CollisionPolygon2D = source_collider.duplicate()
		new_shape.polygon = []
		result_colliders.push_back(new_shape)
		%LayerResult.add_child(new_shape)
	
	idx = 0
	for point_array in polygons:
		result_colliders[idx].polygon = point_array
		idx += 1
	while idx < len(result_colliders):
		result_colliders[idx].polygon = []
		idx += 1

func _process(_delta: float) -> void:
	%LayerHud.update_for_layers(layers)
