extends Panel



func _process(delta):
	$Label.text = str(get_global_mouse_position())
	

