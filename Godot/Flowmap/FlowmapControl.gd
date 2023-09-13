extends WindowDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var FlowMap
var iterations_edit

# Called when the node enters the scene tree for the first time.
func _ready():
	FlowMap = get_tree().get_nodes_in_group("FlowMap")[0]
	iterations_edit = get_tree().get_nodes_in_group("FMIterationsEdit")[0]
	margin_top = 30


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_FlowmapControlButton_pressed(): 
	self.show()



func _on_SetIteration_text_changed():
	var text = iterations_edit.text
	if text.is_valid_integer():
		FlowMap.set_iterations(int(text))



func _on_ForwardBackwardToggle_toggled(button_pressed):
	# for the shader true is forwards, false is backwards
	# here, forwards is false and backwards is true
	FlowMap.set_direction(!button_pressed)



