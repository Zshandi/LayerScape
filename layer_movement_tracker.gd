extends RefCounted
class_name LayerMovementTracker

var layer_to_move: Layer
var track_to_object: Node2D

var global_layer_offset: Vector2

func _init(layer: Layer, track_to: Node2D) -> void:
	layer_to_move = layer
	track_to_object = track_to

	global_layer_offset = layer_to_move.global_position - track_to_object.global_position

func move_to_target() -> void:
	layer_to_move.global_position = track_to_object.global_position + global_layer_offset
