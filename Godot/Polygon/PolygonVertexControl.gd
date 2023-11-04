extends Control

var size: Vector2 = Vector2(7.0,7.0)

var camera2d

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", get_parent(), "_set_inside")
	connect("mouse_exited", get_parent(), "_set_outside")
	
	var initial_size = Vector2(0.7,0.7)
	self.rect_position = - 0.5 * initial_size
	self.rect_size = initial_size


# when the zoom factor changes, change the size of the control node
func zoom_level_changed(z):
	self.rect_position = - 0.5 * size * z
	self.rect_size = size * z
