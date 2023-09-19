extends Node2D
# Why do we need two nodes here? Drawing a circle cannot be undrawn later, therefore the circle
# has to be hidden with hide, a hidden object can however not be entered by a mouse, therefore
# two nodes are needed to highlight the Polygon Vertex 

var pos = Vector2(0,0)
var inside = false
var hold_mouse = false


# Called when the node enters the scene tree for the first time.
func _ready():
	position = pos

func _draw():
	if inside:
		draw_circle(Vector2.ZERO, 0.3, Color(1, 1, 1))


func _set_inside():
	inside = true
	#self.show()
	update()
	
func _set_outside():
	inside = false
	#self.hide()
	update()


func _input(event):
	if inside:
		# spawn is triggered by left mouse click
		if event is InputEventMouseButton:
			if event.is_action_pressed("MouseLeftButton"):
				hold_mouse = true
			if event.is_action_released("MouseLeftButton"):
				hold_mouse = false


func _process(delta):
	if hold_mouse: 
		var mouse_pos = get_local_mouse_position()
