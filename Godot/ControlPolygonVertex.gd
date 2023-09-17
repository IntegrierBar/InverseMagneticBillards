extends Control
# Why do we need two nodes here? Drawing a circle cannot be undrawn later, therefore the circle
# has to be hidden with hide, a hidden object can however not be entered by a mouse, therefore
# two nodes are needed to highlight the Polygon Vertex 

var pos = Vector2(0,0)
var inside = false


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered", self.get_child(0), "_set_inside")
	connect("mouse_exited", self.get_child(0), "_set_outside")
	
	
	
	var size = Vector2(0.7,0.7)
	self.rect_position = pos - 0.5 * size
	self.rect_size = size
	
	print("parent: ")
	print(rect_global_position)

func _draw():
	var try = Vector2(-1.785065, -9.699999)
	
	# rectangle to visualise control node position 
	var rect = Rect2(try - 0.5 * Vector2(0.7,0.7), rect_size)
	# draw_rect(rect, Color(1,0,0), true, 1.0)
	# draw_circle(try, 0.3, Color(1, 1, 1))


func _process(delta):
	pass



