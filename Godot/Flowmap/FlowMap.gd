extends Sprite

var mouse_inside = false

var sizex: float
var sizey: float

enum STATES{
	SHOW,
	SPAWN
}

var fmstate = STATES.SHOW
var forwards = true

var traj_script 
var fm_coords

var billiard_type: int = 0   	# 0 = inverse magnetic, 1 = symplectic 
var showFTLE: bool = false   	# tracks if FTLE or flowmap are shown 

var iterationcount = 1
var hold_mouse = false # used to check whether the left mouse button is held, 
						# needed to show trajectories 



func _ready():
	# initialise parameters for flowmap shader
	material.set_shader_param("iterations", 1)
	material.set_shader_param("forwards", true)
	material.set_shader_param("radius", 1.0)
	material.set_shader_param("showAngle", true)
	material.set_shader_param("showPosition", true)
	# initialise parameters for FTLE shader
	$"../FTLE".material.set_shader_param("iterations", 1)
	$"../FTLE".material.set_shader_param("forwards", true)
	$"../FTLE".material.set_shader_param("radius", 1.0)
	$"../FTLE".material.set_shader_param("zoom", 0.1)
	$"../FTLE".material.set_shader_param("step_size_modifier", 0.01)
	# initialise parameters for symplectic flowmap shader
	$"../FMSymplectic".material.set_shader_param("iterations", 1)
	$"../FMSymplectic".material.set_shader_param("forwards", true)
	$"../FMSymplectic".material.set_shader_param("radius", 1.0)
	$"../FMSymplectic".material.set_shader_param("showAngle", true)
	$"../FMSymplectic".material.set_shader_param("showPosition", true)
	# initialise parameters for symplectic FTLE shader
	$"../FTLESymplectic".material.set_shader_param("iterations", 1)
	$"../FTLESymplectic".material.set_shader_param("forwards", true)
	$"../FTLESymplectic".material.set_shader_param("radius", 1.0)
	$"../FTLESymplectic".material.set_shader_param("zoom", 0.1)
	$"../FTLESymplectic".material.set_shader_param("step_size_modifier", 0.01)
	# initialise parameters for regular flowmap shader
	$"../FMRegular".material.set_shader_param("iterations", 1)
	$"../FMRegular".material.set_shader_param("forwards", true)
	$"../FMRegular".material.set_shader_param("radius", 1.0)
	$"../FMRegular".material.set_shader_param("showAngle", true)
	$"../FMRegular".material.set_shader_param("showPosition", true)
	# initialise parameters for regular FTLE shader
	$"../FTLERegular".material.set_shader_param("iterations", 1)
	$"../FTLERegular".material.set_shader_param("forwards", true)
	$"../FTLERegular".material.set_shader_param("radius", 1.0)
	$"../FTLERegular".material.set_shader_param("zoom", 0.1)
	$"../FTLERegular".material.set_shader_param("step_size_modifier", 0.01)
	
	
	sizey = texture.get_height()
	sizex = texture.get_width()
	traj_script = get_tree().get_nodes_in_group("Trajectories")[0]
	fm_coords = get_tree().get_nodes_in_group("FlowmapCoordinates")[0]


# checks if mouse is inside or outside flowmap
func _set_inside():
	# print("inside")
	mouse_inside = true
	fm_coords.show()


func _set_outside():
	mouse_inside = false
	fm_coords.hide()


func _input(event):
	if mouse_inside:
		match fmstate: 
			STATES.SPAWN:
				# spawn is triggered by left mouse click
				if event is InputEventMouseButton:
					if event.button_index == BUTTON_LEFT and event.pressed:
						# rest of spawn trajectory is in mouse_input 
						mouse_input()
			STATES.SHOW:
				# show is continually executed as long as the left mouse button is pressed
				# this state is saved in the hold_mouse button, the actual show part is in _process
				if event.is_action_pressed("MouseLeftButton"):
					hold_mouse = true
				if event.is_action_released("MouseLeftButton"):
					hold_mouse = false


# called for spawning a trajectory from the flowmap
func mouse_input():
	# check whether local coords are between 0 and 1
	var pos = local_to_ps()
	var valid_coord = pos[0] >= 0 and pos[0] <=1 and pos[1] >= 0 and pos[1] <= 1
	if valid_coord:
		# adding trajectories is handled in trajectories
		traj_script._spawn_fm_traj_on_click(pos)


# currently only used for showing (but not adding) trajectories from the flowmap
# shown trajectory is updated as long as the left mouse button is held
func _process(_delta):
	var pos = local_to_ps()
	
	# check whether local coords are between 0 and 1
	# var pos = local_to_ps()
	var valid_coord = pos[0] >= 0 and pos[0] <=1 and pos[1] >= 0 and pos[1] <= 1

	if valid_coord:
		var string = "(%.3f, %.3f)"
		fm_coords.text = string % [pos[0], pos[1]]
		
		if hold_mouse:
			if forwards: 
				traj_script._show_fm_traj_on_click(pos)
			else:
				traj_script._show_backwards_fm_traj_on_click(pos)
	
	else: # if the coordiantes are not valid, set label to empty
		fm_coords.text = ""


func _on_ShowSpawnButton_toggled(button_pressed):
	if button_pressed:
		fmstate = STATES.SPAWN
	else:
		fmstate = STATES.SHOW


# Sends the polygon data to the shaders as a sampler2D image
func store_polygon_as_image(polygon: Array, polygonLength: Array):
	# pass the size to shader
	material.set_shader_param("n", polygon.size())
	$"../FTLE".material.set_shader_param("n", polygon.size())
	$"../FMSymplectic".material.set_shader_param("n", polygon.size())
	$"../FTLESymplectic".material.set_shader_param("n", polygon.size())
	$"../FMRegular".material.set_shader_param("n", polygon.size())
	$"../FTLERegular".material.set_shader_param("n", polygon.size())
	
	# convert array to imageTexture and send it to shader
	var img = Image.new()
	var polyLength = Image.new()
	img.create(polygon.size(), 1, false, Image.FORMAT_RGF)
	polyLength.create(polygonLength.size(), 1, false, Image.FORMAT_RGF)
	img.lock()
	polyLength.lock()
	for i in range(polygon.size()):
		var c = Color(polygon[i].x, polygon[i].y, 0)
		img.set_pixel(i, 0, c)
		var l = Color(polygonLength[i], 0, 0)
		polyLength.set_pixel(i, 0, l)
	img.unlock()
	polyLength.unlock()
	
	var texture = ImageTexture.new()
	texture.create_from_image(img, 0)
	var lengthTexture = ImageTexture.new()
	lengthTexture.create_from_image(polyLength, 0)
	material.set_shader_param("polygon", texture)
	material.set_shader_param("polygonLength", lengthTexture)
	$"../FTLE".material.set_shader_param("polygon", texture)
	$"../FTLE".material.set_shader_param("polygonLength", lengthTexture)
	$"../FMSymplectic".material.set_shader_param("polygon", texture)
	$"../FMSymplectic".material.set_shader_param("polygonLength", lengthTexture)
	$"../FTLESymplectic".material.set_shader_param("polygon", texture)
	$"../FTLESymplectic".material.set_shader_param("polygonLength", lengthTexture)
	$"../FMRegular".material.set_shader_param("polygon", texture)
	$"../FMRegular".material.set_shader_param("polygonLength", lengthTexture)
	$"../FTLERegular".material.set_shader_param("polygon", texture)
	$"../FTLERegular".material.set_shader_param("polygonLength", lengthTexture)


func _on_Trajectories_close_polygon(p):
	var l_array: Array = [0.0]
	for i in range(p.size()-1):
		l_array.append( l_array[i] + (p[i] - p[i+1]).length())
	store_polygon_as_image(invert_y_array(p), l_array)


func set_radius(r):
	material.set_shader_param("radius", r)
	$"../FTLE".material.set_shader_param("radius", r)
	$"../FMSymplectic".material.set_shader_param("radius", r)
	$"../FTLESymplectic".material.set_shader_param("radius", r)
	$"../FMRegular".material.set_shader_param("radius", r)
	$"../FTLERegular".material.set_shader_param("radius", r)


# sets number of iterations also for the trajectories copy that is needed to show trajectories from the flow map
func set_iterations(iter: int):
	traj_script.batch_to_show = iter
	material.set_shader_param("iterations", iter)
	$"../FTLE".material.set_shader_param("iterations", iter)
	$"../FMSymplectic".material.set_shader_param("iterations", iter)
	$"../FTLESymplectic".material.set_shader_param("iterations", iter)
	$"../FMRegular".material.set_shader_param("iterations", iter)
	$"../FTLERegular".material.set_shader_param("iterations", iter)


func set_direction(b: bool): # forwards is true
	material.set_shader_param("forwards", b)
	$"../FTLE".material.set_shader_param("forwards", b)
	$"../FMSymplectic".material.set_shader_param("forwards", b)
	$"../FTLESymplectic".material.set_shader_param("forwards", b)
	$"../FMRegular".material.set_shader_param("forwards", b)
	$"../FTLERegular".material.set_shader_param("forwards", b)
	# needed for show trajectory to determine whether a forwards or backwards iteration is supposed 
	# to be shown
	forwards = b


func invert_y(p: Vector2) -> Vector2:
	return Vector2(p.x, -p.y)


func invert_y_array(a: Array) -> Array:
	var inverted = []
	for p in a:
		inverted.append(invert_y(p))
	return inverted


# changes visiblity of flowmap and FTLE map
func _on_FTLEButton_toggled(button_pressed):
	showFTLE = button_pressed
	self.visible = !button_pressed and (billiard_type == 0)
	$"../FTLE".visible = button_pressed and (billiard_type == 0)
	$"../FMSymplectic".visible = !button_pressed and (billiard_type == 1)
	$"../FTLESymplectic".visible = button_pressed and (billiard_type == 1)
	$"../FMRegular".visible = !button_pressed and (billiard_type == 2)
	$"../FTLERegular".visible = button_pressed and (billiard_type == 2)


# If toggled on the position in phasespace is colour coded in the flowmap
func _on_FMPositionCheck_toggled(button_pressed):
	material.set_shader_param("showPosition", button_pressed)
	$"../FMSymplectic".material.set_shader_param("showPosition", button_pressed)
	$"../FMRegular".material.set_shader_param("showPosition", button_pressed)


# If toggled on the anngle in phasespace is colour coded in the flowmap
func _on_FMAngleCheck_toggled(button_pressed):
	material.set_shader_param("showAngle", button_pressed)
	$"../FMSymplectic".material.set_shader_param("showAngle", button_pressed)
	$"../FMRegular".material.set_shader_param("showAngle", button_pressed)
	

func local_to_ps() -> Vector2:
	var locpos = get_local_mouse_position() 
	locpos = locpos + Vector2(sizex/2, sizey/2)
	#print(locpos)
	var x = locpos[0] / sizex
	var y = locpos[1] / sizey
	return Vector2(x, y)


# called when the camera zooms. Sets the zoom variable in the shader
func _on_Camera2D_zoom_changed(z):
	$"../FTLE".material.set_shader_param("zoom", z)
	$"../FTLESymplectic".material.set_shader_param("zoom", z)
	$"../FTLERegular".material.set_shader_param("zoom", z)


func change_billiard_type(type: int):
	billiard_type = type
	self.visible = (type==0) and !showFTLE
	$"../FTLE".visible = (type==0) and showFTLE
	$"../FMSymplectic".visible = (type==1) and !showFTLE
	$"../FTLESymplectic".visible = (type==1) and showFTLE
	$"../FMRegular".visible = (type==2) and !showFTLE
	$"../FTLERegular".visible = (type==2) and showFTLE


func _on_FTLEStepsizeEdit_text_entered(new_text):
	if new_text.is_valid_float():
		var stepsize = float(new_text)
		$"../FTLE".material.set_shader_param("step_size_modifier", stepsize)
		$"../FTLESymplectic".material.set_shader_param("step_size_modifier", stepsize)
		$"../FTLERegular".material.set_shader_param("step_size_modifier", stepsize)
