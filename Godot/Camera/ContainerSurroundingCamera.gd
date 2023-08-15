extends HSplitContainer

export(NodePath) var camera

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", get_node(camera), "_set_inside")
	connect("mouse_exited", get_node(camera), "_set_outside")
