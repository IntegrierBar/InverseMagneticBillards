extends WindowDialog

var scene = preload("res://ControlPanel/OnePolygonVertex.tscn")
onready var count: int # have to do it like this, otherwise it refuses the conversion
# to string in the polygonvertex_added function


# Called when the node enters the scene tree for the first time.
func _ready():
	margin_top = 30
	count = 1
	# for some reason the count does not work for the first triangle
	# it looks like count is only set to 1 after the first triangle is drawn
	# but why does count start by 0 before?


func _on_PolygonVertexControl_pressed():
	self.show()


func _on_PolygonVertex_added(vertex: Vector2):
	#print(count)
	var Vertex = scene.instance()
	Vertex.get_child(0).text = String(count)
	count += 1
	Vertex.get_child(1).text = String(vertex[0])
	Vertex.get_child(2).text = String(vertex[1])
	
	self.find_node("VBoxContainer").add_child(Vertex)


func clear_polygon():
	var box = self.find_node("VBoxContainer")
	var j = box.get_child_count()
	for i in range(2,j):
		box.get_child(i).queue_free()
	count = 1


# changes the entry in the text edit field if one of the vertices was moved with 
# the mouse
func vertex_moved(pos: Vector2, index: int):
	var box = self.find_node("VBoxContainer")
	var vertex = box.get_child(index + 2) 
	vertex.get_child(1).text = String(pos[0])
	vertex.get_child(2).text = String(pos[1])
	
