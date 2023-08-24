extends Viewport


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	if get_visible_rect().has_point(get_mouse_position()):
		print("inside")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
