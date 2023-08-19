extends VBoxContainer

signal change_start_position

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_DeleteTrajButton_pressed():
	queue_free()


func _on_ButtonStartPos1_pressed():
	var id = get_instance_id()
	# print(id) 
	emit_signal("change_start_position", id)
	# Seems to only connect the first button, all other start position buttons are not connected
	# I think the problem is, that connected the signal in the trajectories script properly
	# do I perhaps have to do it when also instnaciating the newly created buttons?
