extends WindowDialog

var FlowMap


func _ready():
	FlowMap = get_tree().get_nodes_in_group("FlowMap")[0]
	margin_top = 30


func _on_FlowmapControlButton_pressed(): 
	self.show()


func _on_ForwardBackwardToggle_toggled(button_pressed):
	# for the shader true is forwards, false is backwards
	# here, forwards is false and backwards is true
	FlowMap.set_direction(!button_pressed)


func _on_SetIteration_text_entered(new_text):
	if new_text.is_valid_integer():
		FlowMap.set_iterations(int(new_text))
