extends Viewport

export(NodePath) var camera

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _input(event):
	if get_visible_rect().has_point(get_mouse_position()):
		#print(event)
		get_node(camera).input(event)
