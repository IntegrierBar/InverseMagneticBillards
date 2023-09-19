extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", get_parent(), "_set_inside")
	connect("mouse_exited", get_parent(), "_set_outside")
	var size = Vector2(0.7,0.7)
	self.rect_position = - 0.5 * size
	self.rect_size = size


func _draw():
	pass
	#draw_circle(Vector2.ZERO, 0.2, Color(1, 0, 0))
	

func _process(delta):
	pass
	# update()
