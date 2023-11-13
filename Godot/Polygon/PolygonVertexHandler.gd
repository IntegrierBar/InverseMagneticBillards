extends Node2D

const scene = preload("res://Polygon/PolygonVertex.tscn")


func add_polygon_vertex(v: Vector2):
	var Vertex = scene.instance()
	Vertex.pos = v
	add_child(Vertex)


func clear():
	for c in get_children():
		c.queue_free()


# function to change vertex position if vertex position was changed via the text edit
# fields in polygon vertex control
func coord_text_changed(pos: Vector2, index: int):
	get_child(index).position = pos
