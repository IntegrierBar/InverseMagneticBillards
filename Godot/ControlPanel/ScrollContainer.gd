extends ScrollContainer


var traj_control


# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_enable_h_scroll(false) # Replace with function body.
	traj_control = get_tree().get_nodes_in_group("TrajectoriesControlPart")[0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_NewTrajectoriesButton_pressed():
	var count = traj_control.get_child_count()
	var scene = load("res://ControlPanel/OneTrajectoryControlContainer.tscn")
	var newTrajControl = scene.instance()
	traj_control.add_child(newTrajControl)
	traj_control.move_child(newTrajControl, count - 2)
	pass # Replace with function body.
