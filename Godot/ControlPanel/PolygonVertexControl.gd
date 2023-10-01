extends WindowDialog

var scene = preload("res://ControlPanel/OnePolygonVertex.tscn")
var count: int

# Called when the node enters the scene tree for the first time.
func _ready():
	margin_top = 30
	count = 1


func _on_PolygonVertexControl_pressed():
	self.show()

func _on_PolygonVertex_added(vertex: Vector2):
	var Vertex = scene.instance()
	Vertex.get_child(0).text = String(count)
	count += 1
	Vertex.get_child(1).text = String(vertex[0])
	Vertex.get_child(2).text = String(vertex[1])
	
	self.find_node("VBoxContainer").add_child(Vertex)
	
