@tool
extends Resource
class_name LevelData

@export
var scene: PackedScene:
	set(value):
		scene = value
		if scene != null:
			resource_name = scene.resource_path.get_file().get_basename()
