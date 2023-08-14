extends ViewportContainer

onready var mouse_inside = false

func _ready():
	connect("mouse_entered", self, "_set_inside")
	connect("mouse_exited", self, "_set_outside")

func _input(event):
	if mouse_inside:
		$Viewport.input(event)


func _set_inside():
	print("inside")
	mouse_inside = true

func _set_outside():
	print("outiside")
	mouse_inside = false
