extends VBoxContainer

var traj_script


# Called when the node enters the scene tree for the first time.
func _ready():
	traj_script = get_tree().get_nodes_in_group("Trajectories")[0]



func _on_DeleteTrajButton_pressed():
	queue_free()


func _on_StartPos_text_changed():
	var traj_num = get_index() - 4
	var n = get_child(1).get_child(0)
	var text = n.text
	var regex = RegEx.new()
	regex.compile("\\(([-+]?([0-9])+\\.?([0-9])*)\\s?,\\s?([-+]?([0-9])+\\.?([0-9])*)\\)")
	var result = regex.search(text)
	if result:
		print(result.get_string())
	# traj_script.on_StartPosText_changed(traj_num, text)


