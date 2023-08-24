extends MarginContainer



# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	connect("mouse_entered",$PhaseSpace , "_set_inside")
	connect("mouse_exited",$PhaseSpace, "_set_outside")
