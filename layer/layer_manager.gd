extends Node2D
class_name LayerManager

@onready var lock_layer: AudioStreamPlayer2D = %LockLayerSound
@onready var unlock_layer: AudioStreamPlayer2D = %UnlockLayerSound

@onready var result_source_render: Polygon2D = %LayerResultSourceRender.duplicate()

@export
var player_to_track: Character

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
	for child in get_children():
		if child is Layer:
			layers.push_back(child)
			child.player_to_track = player_to_track
	
	if len(layers) <= 0:
		layers.push_back(Layer.new())
	layers.reverse()
	layers[selected_layer_index].selected = true

	#update_result(get_physics_process_delta_time())

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

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("lock_toggle"):
		selected_layer.locked = not selected_layer.locked
		if selected_layer.locked:
			lock_layer.play()
		else:
			unlock_layer.play()
	
	if Input.is_action_just_pressed("visible_toggle"):
		selected_layer.visible = not selected_layer.visible
	
	if Input.is_action_just_pressed("layer_next"):
		selected_layer_index += 1
	if Input.is_action_just_pressed("layer_prev"):
		selected_layer_index -= 1
	
	update_result(delta)

func update_result(delta: float) -> void:
	player_to_track.get_next_velocity(delta)

	# Update the layer polygons
	for layer in layers:
		layer.update_shapes()

	# Calculate result polygons by combining layers
	var render_result := PolygonLayer.new()
	for layer in layers:
		render_result = render_result.apply_to(layer.polygon_layer)

	# Do the same again but offset to account for player velocity when unlocked
	var collision_result := PolygonLayer.new()
	for layer in layers:
		collision_result = collision_result.apply_to(layer.get_polygon_layer_velocity_shifted(delta))
	
	# Construct final collision
	PolygonUtil.replace_polygon_nodes(%LayerResult, collision_result.shapes, CollisionPolygon2D.new(), true)

	# Construct final render (Polygon2Ds)
	PolygonUtil.replace_polygon_nodes(%LayerResultRenders, render_result.shapes, result_source_render)
	

func _process(_delta: float) -> void:
	%LayerHud.update_for_layers(layers)
