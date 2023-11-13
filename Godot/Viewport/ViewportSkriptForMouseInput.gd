extends Viewport

export(NodePath) var camera


# forward Input to camera, so that camera does not need to know if mouse is inside space
# (this works differently from the _input for the space scripts because there was a reason for it.
# Could however streamline now)
func _input(event):
	if get_visible_rect().has_point(get_mouse_position()):
		get_node(camera).input(event)
