@tool
extends Node2D
class_name PolygonRenderer

static func instantiate() -> PolygonRenderer:
	var renderer_scene = preload("./polygon_renderer.tscn")
	return renderer_scene.instantiate()

static func add_renderer(parent: Node) -> PolygonRenderer:
	var renderer = instantiate()
	parent.add_child(renderer)
	return renderer

@export
var render_material: Material:
	get:
		return %RenderTexture.material
	set(value):
		%RenderTexture.material = value

@onready
var result_source_render = %ResultSourceRender.duplicate()

func render_polygons(polygons: Array[PackedVector2Array]) -> void:
	PolygonUtil.replace_polygon_nodes(%ResultRenders, polygons, result_source_render)