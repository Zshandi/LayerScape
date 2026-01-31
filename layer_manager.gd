extends Node2D
class_name LayerManager

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
	
	if len(layers) <= 0:
		layers.push_back(Layer.new())
	layers[selected_layer_index].selected = true

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

func _process(_delta: float) -> void:
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
	var running_result := layers[0].polygon_layer
	for idx in range(1, len(layers)):
		var layer := layers[idx]
		running_result = running_result.apply_to(layer.polygon_layer)
	
	var polygons := running_result.shapes

	while len(result_colliders) < len(polygons):
		var new_shape: CollisionPolygon2D = source_collider.duplicate()
		new_shape.polygon = []
		result_colliders.push_back(new_shape)
		%LayerResult.add_child(new_shape)
	
	var idx = 0
	for point_array in polygons:
		%LayerResult.get_child(idx).polygon = point_array
		idx += 1