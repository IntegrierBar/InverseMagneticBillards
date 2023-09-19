extends Node2D
# Why do we need two nodes here? Drawing a circle cannot be undrawn later, therefore the circle
# has to be hidden with hide, a hidden object can however not be entered by a mouse, therefore
# two nodes are needed to highlight the Polygon Vertex 

var pos = Vector2(0,0)
var inside = false


# Called when the node enters the scene tree for the first time.
func _ready():
	position = pos

func _draw():
	if inside:
		draw_circle(Vector2.ZERO, 0.3, Color(1, 1, 1))


func _set_inside():
	print("inside")
	inside = true
	#self.show()
	update()
	
func _set_outside():
	print("outside")
	inside = false
	#self.hide()
	update()



