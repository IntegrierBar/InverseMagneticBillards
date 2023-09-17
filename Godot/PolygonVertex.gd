extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var inside = false
var pos = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.hide()
	
	self.position = pos
	print("child: ")
	print(get_global_position())


func _draw():
	
	draw_circle(pos, 0.3, Color(1, 1, 1))
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _set_inside():
	update()
	print("inside")
	inside = true
	self.show()
	
func _set_outside():
	print("outside")
	inside = false
	self.hide()
