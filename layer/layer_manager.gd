extends Node
class_name LayerManager

@onready var lock_layer: AudioStreamPlayer = %LockLayerSound
@onready var unlock_layer: AudioStreamPlayer = %UnlockLayerSound
@onready var cant_unlock_layer: AudioStreamPlayer = %CantUnlockSound

@export
var player_to_track: Character

@export
var main_hud: LevelMainHud

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

	# TODO: Allow overriding this...
	MusicPlayer.play_mysterious_cave()

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
		if not selected_layer.permanent_lock:
			selected_layer.locked = not selected_layer.locked
			if selected_layer.locked:
				lock_layer.play()
			else:
				unlock_layer.play()
		else:
			cant_unlock_layer.play()
	
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
		layer.polygon_layer_result = render_result.duplicate()

	# Strategy for ensuring the player appropriately passes through layers when unlocked:
	#  1. For each layer, determine if it adds to or takes away from the final level shape
	#  2. If it adds to overall shape, reduce the size of its polygons when unlocked
	#  2. If it takes away from overall shape, increase the size of its polygons when unlocked
	#  3. Shift the polygons in the direction of the players velocity
	#  4. Still render the polygons as if the size weren't changed
	# 
	# This ensures the player will fall as appropriate whether it's due to stand on the thing their unlocking,
	#  or standing in a subtract that they've just unlocked. It still has the issue of if the player is near
	#  an edge it can cause them to fall off, but this would be too difficult to fix. It's a literal edge case.

	# Update the layer contribution sign
	# This is for determining whether to shrink or expand the layer polygons
	var total_contribution_sign := 1
	# Need to traverse from the last layer for the contribution to be known
	for idx in range(len(layers) - 1, -1, -1):
		var layer := layers[idx]
		total_contribution_sign *= layer.get_contribution_sign()
		layer.overall_contribution_sign = total_contribution_sign

	# Do the same again but offset to account for player velocity when unlocked
	var collision_result := PolygonLayer.new()
	for layer in layers:
		collision_result = collision_result.apply_to(layer.get_polygon_layer_velocity_shifted(delta))
	
	# Construct final collision
	PolygonUtil.replace_polygon_nodes(%LayerResult, collision_result.shapes, CollisionPolygon2D.new(), true)

	# Construct final render (Polygon2Ds)
	%LayerResultRenderer.render_polygons(render_result.shapes)
	

func _process(_delta: float) -> void:
	main_hud.layer_hud.update_for_layers(layers)
