extends VBoxContainer

var traj_script


# Called when the node enters the scene tree for the first time.
func _ready():
	traj_script = get_tree().get_nodes_in_group("Trajectories")[0]


# delete trajectory button only works if we are in the iterate state. Otherwise does nothing
func _on_DeleteTrajButton_pressed():
	if traj_script.current_state == traj_script.STATES.ITERATE:
		queue_free()


func _on_StartPos_text_entered(new_text):
	text_changed()


func _on_StartDir_text_entered(new_text):
	text_changed()


func text_changed():
	var traj_num = get_index() - 4
	var pos = get_child(1).get_child(0) 
	var text_pos = pos.text
	var dir = get_child(1).get_child(1) 
	var text_dir = dir.text
	
	var regex = RegEx.new()
	regex.compile("^\\s*\\(\\s*(?<digit1>[-+]?([0-9])+\\.?([0-9])*)\\s*,\\s*(?<digit2>[-+]?([0-9])+\\.?([0-9])*)\\s*\\)\\s*$")
	
	var result_pos = regex.search(text_pos)
	var result_dir = regex.search(text_dir)
	
	if result_pos and result_dir:
		var vp1 = float(result_pos.get_string("digit1"))
		var vp2 = float(result_pos.get_string("digit2"))
		var v_pos = Vector2(vp1, vp2)
		var vd1 = float(result_dir.get_string("digit1"))
		var vd2 = float(result_dir.get_string("digit2"))
		var v_dir = Vector2(vd1, vd2)
		
		traj_script.on_InitialValues_text_changed(traj_num, v_pos, v_dir)


