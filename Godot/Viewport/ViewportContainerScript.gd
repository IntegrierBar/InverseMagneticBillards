extends ViewportContainer

export(NodePath) var trajectories

# connect signals to know whether mouse is inside the space
func _ready():
	connect("mouse_entered", get_node(trajectories), "_set_inside")
	connect("mouse_exited", get_node(trajectories), "_set_outside")
