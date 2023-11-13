extends HSplitContainer#ViewportContainer

export(NodePath) var camera


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", get_node(camera), "_set_inside")
	connect("mouse_exited", get_node(camera), "_set_outside")
