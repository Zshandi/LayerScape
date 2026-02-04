extends Node2D

func _process(_delta: float) -> void:
	var polygons = PolygonUtil.get_child_node_polygons(%Source)
	polygons = PolygonUtil.offset_polygons(polygons, -60, Geometry2D.JOIN_ROUND)
	polygons = PolygonUtil.offset_polygons(polygons, 90, Geometry2D.JOIN_ROUND)
	var dest_poly = %DestPoly.duplicate()
	dest_poly.show()
	PolygonUtil.replace_polygon_nodes(%Dest, polygons, dest_poly, true)