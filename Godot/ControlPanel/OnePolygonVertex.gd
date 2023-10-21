extends HBoxContainer


var traj_script


# Called when the node enters the scene tree for the first time.
func _ready():
	traj_script = get_tree().get_nodes_in_group("Trajectories")[0]


func _on_xCoord_text_changed():
	coord_changed()


func _on_yCoord_text_changed():
	coord_changed()


# handles changed coords if text edit is changed since both fields are always 
# needed to change the position
func coord_changed():
	var x_text = get_child(1).text
	var y_text = get_child(2).text
	
	if x_text.is_valid_float() and y_text.is_valid_float():
		var x = float(x_text)
		var y = -float(y_text)
		var index = get_index() - 2
		var v = Vector2(x,y)
		traj_script.change_polygon_vertex(v, index)
		# change position of vertex object via function in PolygonVertexHandler
		traj_script.get_child(2).coord_text_changed(v, index) 
		


