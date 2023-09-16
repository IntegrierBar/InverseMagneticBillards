# TODOs
# Camera movable with right mouse button or arrow keys/wasd
# good initial camera zoom
# UI:
#	dragable
#	look pretty
#	dynamicly adding trajectories
#	more functionalyity (batch, color, add_trajectory ...)
# Disable some buttons when polygon not closed
# SHADERS
# BUG WITH initial point. might think it is outside and couse interseciton with side we are on!!!
# 	would be fixed by transitioning to a paramtetrization



# Fix Bugs:
# - Add update to delete trajectory and set_color in C++ code!
# - Under some circumstances, the local coordinates in the normal coordinate space with the polygon are shifted,
#   meaning that the position of the mouse is further left than the indicated position of the mouse when drawing 
#   a new polygon or choosing a direction, it seems to appear if the left part is made bigger



extends Node2D

var mouse_inside = false

#onready var trajectory_scene = preload("res://Trajectory.tscn")
var phase_space# = $"../../../../Phasespace/ViewportContainer/Viewport/MarginContainer/PhaseSpace"
var flow_map
var polygon_instr
var trajectory_instr
var radius_edit
var radius_slider
var traj_control
var batch_edit
var single_ps_traj
var corner_count

var newpos # currently needed to change direction 
			# TODO: have this handled in gdnative 


# var lines_to_draw # will be handled in gdnative

var polygon: Array
var polygon_color: Color
var polygon_closed: bool

onready var trajectories = $Trajectory
onready var trajectory_to_show = $TrajectoryToShow

signal close_polygon(p)

var batch: int
var batch_to_show: int = 1
var max_count: int
var radius: float

enum STATES {
	ITERATE,
	SET_START,
	SET_DIRECTION,
	SET_POLYGON,
	ADD_TRAJECTORY, 
}
var current_state = STATES.ITERATE
var last_state

var trajectory_to_edit: int

# Called when the node enters the scene tree for the first time.
func _ready():
	# Nodes that have to be accessed, using groups allows to change the nodes position in the tree
	# without having to change anything here
	phase_space = get_tree().get_nodes_in_group("PhaseSpace")[0]
	flow_map = get_tree().get_nodes_in_group("FlowMap")[0]
	polygon_instr = get_tree().get_nodes_in_group("PolygonInstructions")[0]
	trajectory_instr = get_tree().get_nodes_in_group("TrajectoriesInstructions")[0]
	radius_edit = get_tree().get_nodes_in_group("RadiusEdit")[0]
	radius_slider = get_tree().get_nodes_in_group("RadiusSlider")[0]
	traj_control = get_tree().get_nodes_in_group("TrajectoriesControlPart")[0]
	batch_edit = get_tree().get_nodes_in_group("BatchSizeEdit")[0]
	single_ps_traj = get_tree().get_nodes_in_group("SinglePSTraj")[0]
	corner_count = get_tree().get_nodes_in_group("SetCornerCount")[0]
	
	batch = 1
	trajectories.maxCount = 100
	radius = 1
	trajectories.set_radius(radius)
	trajectory_to_show.set_radius(radius)
	radius_slider.value = radius
	trajectories.reset_trajectories()
	trajectory_to_show.reset_trajectories()
	polygon_closed = false
	polygon = []
	polygon_color = Color(1, 1, 1)
	add_polygon_vertex(Vector2(0,0))
	add_polygon_vertex(Vector2(10,0))
	add_polygon_vertex(Vector2(0,-10))
	#close_polygon()
	current_state = STATES.SET_POLYGON
	add_trajectorie(Vector2(1, 0), Vector2(0, -1), Color(0,1,0))
	trajectory_to_edit = 0 # TODO needs button to change
	
	# connect buttons of already existing trajectory 
	var inst = traj_control.find_node("VBoxContainer")
	var newStartPos = inst.get_child(0).get_child(0)
	var id = inst.get_instance_id()
	newStartPos.connect("pressed", self, "_on_NewStartPos_pressed", [id])
	var deleteTraj = inst.get_child(0).get_child(1)
	deleteTraj.connect("pressed", self, "_on_delete_trajectory_pressed", [id])
	var colourPicker = inst.get_child(1).get_child(1)
	colourPicker.connect("popup_closed", self, "_on_color_changed", [id])
	
	#trajectory_to_show.add_trajectory
	# inst.connect("change_start_position", self, "_on_NewStartPos_pressed")

func _process(_delta):
	match current_state:
		STATES.SET_DIRECTION:
			update()
		STATES.SET_POLYGON:
			if polygon.size() > 0:
				update()
		STATES.SET_START:
			update()

			

func _draw():
	if polygon.size() > 1:
		draw_polyline(polygon, polygon_color)
	match current_state:
		STATES.SET_DIRECTION:
			draw_line(newpos, get_local_mouse_position(), trajectories.get_trajectory_colors()[trajectory_to_edit])
			# It does what I want it to do but is this really the correct way or is there a more elegant solution?
		STATES.SET_POLYGON:
			draw_line(polygon.back(), get_local_mouse_position(), polygon_color)
		STATES.SET_START:
			draw_circle(snap_to_polygon(get_local_mouse_position()), 1.0, trajectories.get_trajectory_colors()[trajectory_to_edit])



####################### POLYGON ####################################################################
# Godot uses negative y-axis. Nedd to invert y to get correct coords
func invert_y(p: Vector2) -> Vector2:
	return Vector2(p.x, -p.y)


func add_polygon_vertex(vertex: Vector2):
	if !polygon_closed:		# dont allow adding of vertices when polygon is closed
		polygon.append(vertex)
		trajectories.add_polygon_vertex(invert_y(vertex))
		trajectory_to_show.add_polygon_vertex(invert_y(vertex))
	update()

func close_polygon():
	if polygon_closed || polygon.size() < 3:
		return
	polygon.append(polygon[0])
	emit_signal("close_polygon", polygon)	# signal flow map, that polygon is closed
	trajectories.close_polygon()
	trajectory_to_show.close_polygon()
	polygon_closed = true
	trajectories.reset_trajectories()
	update()

func clear_polygon():
	polygon = []
	polygon_closed = false
	
	var trajcount = trajectories.get_trajectory_colors().size()
	# print(trajcount)
	if trajcount > 1:
		for i in range(1, trajcount): 
# Note: it looks like Godot and C++ have different ways to handle how to remove objects! Watch out with the indices!
			# print(i)
			var container = traj_control.get_child(4 + i)
# this index has to change with the iterations despite the node at the position being removed
			container.queue_free()
			# print(container)
			trajectories.remove_trajectory(1)
# this index has to be the same because the trajectory previously at position 2 is removed in the previous iteration
	
	trajectories.clear_polygon()
	trajectory_to_show.clear_polygon()
	trajectory_to_edit = 0 # need to set back to 0 because this should be the only trajectory left 
	#phase_space.reset_trajectories()

# prejects the point onto all sides of the polygon and returns the closest
func snap_to_polygon(point: Vector2) -> Vector2:
	var best_point_projected: Vector2 = Vector2(0,0)
	var min_distance: float = INF
	for i in range(polygon.size()-1):	# -1 since polygon is closed
		var point_projected = Geometry.get_closest_point_to_segment_2d(point, polygon[i], polygon[i+1])
		var distance = point.distance_squared_to(point_projected)
		if min_distance > distance:
			best_point_projected = point_projected
			min_distance = distance
	return best_point_projected


# TODO: things have to happen here, the function from the c++ code is currently not connected
func _on_RegularNGonButton_pressed():
	var n = corner_count.text
	if n.is_valid_integer():
		pass
		# trajectories.make_regular_ngon(n)
		# trajectory_to_show.make_regular_ngon(n)
		# corners have to be added to polygon somehow as well
		# polygon is already closed 
		
		# trajectories.reset_trajectories()
		# update()
		# if trajectories.get_trajectory_colors().size() > 0: 
		# 	current_state = SET_START
		



##################### TRAJECTORIES #################################################################
func add_trajectorie(start: Vector2, dir: Vector2, color: Color):
	trajectories.add_trajectory(invert_y(start), invert_y(dir), color)
	#phase_space.add_trajectory(color)

func add_trajectorie_ps(pos: Vector2, color: Color):
	trajectories.add_trajectory_phasespace(pos, color)

func iterate_batch():
	var phase_space_points = trajectories.iterate_batch(batch)
	phase_space.add_points_to_image(phase_space_points, trajectories.get_trajectory_colors())
#	for i in range(trajectories.size()):
#		var coordsPhasespace = trajectories[i].iterate_batch(batch)
#		#print(coordsPhasespace)
#		phase_space.add_points_to_trajectory(i, coordsPhasespace)


func set_initial_values(index: int, start: Vector2, dir: Vector2):
	trajectories.set_initial_values(index, invert_y(start), invert_y(dir))
	var pscoord = R2ToPS(start, dir)
	phase_space.add_initial_coords_to_image([pscoord], [trajectories.get_trajectory_colors()[index]])




####################### USER INPUT #################################################################
# used to know if mouse is inside the clickable area or not
func _set_inside():
	mouse_inside = true

func _set_outside():
	mouse_inside = false


func _input(event):
	if mouse_inside:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				# necessary for the case that trajectories from phasespace are currently shown
				# hides this trajectory and shows the normal trajectories again
				trajectories.show()
				trajectory_to_show.hide()
				mouse_input()
		

func mouse_input():
	match current_state:
		STATES.SET_POLYGON: 
			add_polygon_vertex(get_local_mouse_position())
		STATES.SET_START:
			newpos = snap_to_polygon(get_local_mouse_position())
			#trajectories[trajectory_to_edit].set_start(newpos)
			current_state = STATES.SET_DIRECTION
			trajectory_instr.text = "Click to choose a new direction"
		STATES.SET_DIRECTION:
			set_initial_values(trajectory_to_edit, newpos, get_local_mouse_position() - newpos)
			current_state = STATES.ITERATE
			trajectory_instr.text = ""
			

# iterate Button pressed, iterates trajectory if the system is in the correct state
func _on_Button_pressed():
	if current_state == STATES.ITERATE:
		# necessary for the case that trajectories from phasespace are currently shown
		# hides this trajectory and shows the normal trajectories again
		trajectories.show()
		trajectory_to_show.hide()
		update()	# used to get rid of the line indicating the direction
		iterate_batch()

# user wants to make new polygon
func _on_ButtonPolygon_pressed():
	current_state = STATES.SET_POLYGON
	clear_polygon()
	phase_space.reset_image()
	polygon_instr.text = "Click to position at least 3 points to create an new polygon"
	

# close polygon button pressed
func _on_ButtonClosePolygon_pressed():
	if current_state == STATES.SET_POLYGON:
		close_polygon()
		polygon_instr.text = " "
		if trajectories.get_trajectory_colors().size() > 0: 
			current_state = STATES.SET_START
		else:
			current_state = STATES.ITERATE
		
		

# user wants to input new start position
func _on_NewStartPos_pressed(id):
	current_state = STATES.SET_START
	var node = instance_from_id(id)  
	trajectory_to_edit = node.get_index() - 4
	# print(trajectory_to_edit)  
	phase_space.reset_image() # TODO THIS IS UGLY
	trajectory_instr.text = "Click to choose a new start position"
	

# radius is set
func _on_TextEdit_text_changed(): 
	if radius_edit.text.is_valid_float():
		var newradius = radius_edit.text.to_float()
		if newradius <= radius_slider.max_value: 
			# change slider position to value in text edit field if possible
			radius_slider.value = newradius
		else: 
			# this allows to set the radius larger than 20 via the text field
			# sets slider value to largest value possible
			radius_slider.value = radius_slider.max_value
			phase_space.reset_image()
			trajectories.set_radius(newradius)
			trajectory_to_show.set_radius(newradius)
			flow_map.set_radius(newradius)


# radius is changed via the slider
func _on_RadiusSlider_value_changed(newradius):
	# slider receives update even when it is updated via script
	# slider can be used up to 19.99, for larger values the text field is needed
	
	if newradius != radius_slider.max_value:
		# necessary to avoid the cursor in the text edit field to jump back to the front,
		# making entering twodigit numbers a pain
		if radius_edit.text != String(newradius): 
			radius_edit.text = String(newradius) 
		
		phase_space.reset_image()
		trajectories.set_radius(newradius)
		trajectory_to_show.set_radius(newradius)
		flow_map.set_radius(newradius)
	else: 
		# means a value larger than the max value might have been entered into the text field
		# resetting image is done in the TextEdit_text_changed function
		pass

# change number of iterations that are computed and drawn when clicking on iterate
func _on_EditBatchSize_text_changed():
	if batch_edit.text.is_valid_integer():
		var newbatch = int(batch_edit.text)
		batch = newbatch


####################### ADDING TRAJECTORIES ########################################################

# spawns and connects single trajectory control 
func _new_trajectory_added(colour):
	var count = traj_control.get_child_count()
	var scene = load("res://ControlPanel/OneTrajectoryControlContainer.tscn")
	var newTrajControl = scene.instance()
	
	
	traj_control.add_child(newTrajControl)
	traj_control.move_child(newTrajControl, count - 1)
	
	var colourPicker = newTrajControl.get_child(1).get_child(1)
	colourPicker.set_pick_color(colour)
	
	# connect the change start position button
	var newStartPos = newTrajControl.get_child(0).get_child(0)
	var id = newTrajControl.get_instance_id()
	newStartPos.connect("pressed", self, "_on_NewStartPos_pressed", [id]) 
	
	# connect color picker button
	colourPicker.connect("popup_closed", self, "_on_color_changed", [id])
	
	# connect the delete trajectory button
	var deleteTraj = newTrajControl.get_child(0).get_child(1)
	deleteTraj.connect("pressed", self, "_on_delete_trajectory_pressed", [id])


# adds a new trajectory via the normal control 
func _on_NewTrajectoriesButton_pressed():
	current_state = STATES.SET_START
	
	var random_colour = Color(randf(), randf(), randf())
	
	add_trajectorie(Vector2(2,0), Vector2(1,-1), random_colour)
	trajectory_to_edit = trajectories.get_trajectory_colors().size() - 1
	
	_new_trajectory_added(random_colour)
	

# spawns trajectory in normal and phasespace based on entered phasespace coordinates 
func _on_SpawnPSTrajOnCoords_pressed():
	var coord1 = single_ps_traj.get_child(4).get_child(0).text
	var coord2 = single_ps_traj.get_child(4).get_child(1).text
	
	var colour = single_ps_traj.get_child(0).get_child(1).get_pick_color()
	
	if coord1.is_valid_float() and coord2.is_valid_float():
		var c1 = coord1.to_float()
		var c2 = coord2.to_float()
		if c1 > 0 and c1 < 1 and c2 > 0 and c2 < 1:
			var ps_pos = Vector2(c1, c2)
			add_trajectorie_ps(ps_pos, colour)
			phase_space.add_initial_coords_to_image([ps_pos], [colour])
			_new_trajectory_added(colour)

# spawns trajectory in normal and phasespace according to the click position int phasespace
func _spawn_ps_traj_on_click(ps_coord):
	var colour = single_ps_traj.get_child(0).get_child(1).get_pick_color()
	add_trajectorie_ps(ps_coord, colour)
	phase_space.add_initial_coords_to_image([ps_coord], [colour])
	_new_trajectory_added(colour)
	

# spawns a batch of trajectories in a rectangle between two clicks in phasespace
func _spawn_ps_traj_batch(bc1: Vector2, bc2: Vector2, n: int):
	var xmin
	var xmax
	var ymin
	var ymax
	
	# determine min and max in x and y direction
	if bc1[0] > bc2[0]:
		xmin = bc2[0]
		xmax = bc1[0]
	else:
		xmin = bc1[0]
		xmax = bc2[0]
		
	if bc1[1] > bc2[1]:
		ymin = bc2[1]
		ymax = bc1[1]
	else:
		ymin = bc1[1]
		ymax = bc2[1]
	
	var w = xmax - xmin
	var h = ymax - ymin
	# min in x and y direction is needed as an offset to spawn the trajectories
	var xymin = Vector2(xmin, ymin)
	
	# calculate the positions and colours of the trajectories in the batch
	var res = traj_batch_pos(n, w, h, xymin)
	
	var pos = res[0]
	
	var colours = res[1]
	#colours.resize(pos.size())
	#colours.fill(Color.aqua)
	#for i in range(colours.size()):
	#	colours[i] = Color(pos[i].x, pos[i].y, 0, 1)
	
	# add start positions to phase space
	phase_space.add_initial_coords_to_image(pos, colours)
	
	for i in range(pos.size()):
		add_trajectorie_ps(pos[i], colours[i])
		
		_new_trajectory_added(colours[i])
	

# used when spawning trajectory batches from phasespace
# uses height, width and minimal coordinates to calculate the positions of the trajectories
# Note: this function does not spawn n trajectories but x ** 2 trajectories where x is floor(sqrt(n))
func traj_batch_pos(n: int, w: float, h: float, xymin: Vector2) -> Array:
	var x = int(sqrt(n))
	var y = x
	var xstep = w / (x - 1)
	var ystep = h / (y - 1)
	
	var positions : Array = []
	var colors : PoolColorArray = []
	
	print(x)
	print(y)
	
	for i in range(x):
		for j in range(y):
			
			var pos = Vector2(i * xstep, j * ystep)
			positions.append(pos + xymin) 
			var c = Color(min(1, 2 - ((i + 1)/float(x) + j/float(y))), (i + 1)/float(x), j/float(y), 1)  
			# TODO: I should probably find out how to apply barycentric coords to this ...
			print(c)
			colors.append(c) 
			# colors still not very good, different but difficult to see, not bright enough
	
	return [positions, colors]

# spawns trajectory on click in flowmap at the corresponding phasespace coordinates
func _spawn_fm_traj_on_click(ps_coord):
	var coord = PSToR2(ps_coord)
	var colour = Color(randf(), randf(), randf())
	add_trajectorie(coord[0], coord[1], colour)
	phase_space.add_initial_coords_to_image([ps_coord], [colour])
	_new_trajectory_added(colour)

# shows trajectory in normal space that corresponds to the mouse position in the flowmap
# uses a second trajectory node that contains the shown trajectory, this node always has only one 
# trajectory active, which gets removed before the next one is added
# clicking the iterate button or left clicking into the normal space hides the shown trajectories 
# and shows the normal trajectories again
func _show_fm_traj_on_click(ps_coord):
	if polygon_closed:
		update()
		trajectory_to_show.clear_trajectories()
		# hide normal trajectories
		trajectories.hide()
		trajectory_to_show.show()
		var color = Color.deeppink
		
		# trajectory does not get added to the phasespace, only phasespace coordinates are used to
		# add the trajectory to the node
		trajectory_to_show.add_trajectory_phasespace(ps_coord, color)
		var output = trajectory_to_show.iterate_batch(batch_to_show)
		# removes the indication of start position and direction of the normal trajectories that 
		# have not been iterated yet
		trajectory_to_show.update()


####################### DELETE TRAJECTORIES ########################################################


# deletes the trajectory from normal space, currently does not delete trajectory from phasespace image! 
func _on_delete_trajectory_pressed(id):
	var node = instance_from_id(id)  
	trajectory_to_edit = node.get_index() - 4
	node.queue_free()
	trajectories.remove_trajectory(trajectory_to_edit)

# deletes all trajectories in normal space, also resets phasespace image 
func _on_DeleteAllTrajectories_pressed():
	var trajcount = trajectories.get_trajectory_colors().size()
	for i in range(trajcount): 
		var container = traj_control.get_child(4 + i)
		container.queue_free()
		trajectories.remove_trajectory(0)
	
	phase_space.reset_image()
	# Note: moving the position of the delete button means that the code for adding new trajectories
	# has to be changed as well! The new trajectories are currentlly moved to a fixed position in 
	# relation to the other children of the parent!


####################### OTHER FUNCTIONS ############################################################

# button that resets all trajectories to their start position and direction (at least in theory) 
func _on_ResetAllTrajectories_pressed():
	trajectories.reset_trajectories()
	# BUG: Maintaines start position but changes directions continuously when resetting to bigger angles 
	# for a ca 10 resets the starting direction is parallel to the polygon side and an iteration is 
	# no longer possible
	# Where does this come from???


# changes colour of a trajectory, change only affects normal space, not phasespace (at the moment) 
func _on_color_changed(id):
	var node = instance_from_id(id)  
	trajectory_to_edit = node.get_index() - 4
	
	var colourPicker = node.get_child(1).get_child(1)
	var c = colourPicker.get_pick_color()
	trajectories.set_color(trajectory_to_edit, c) 

# calculates length of the polygon up to index n, used PSToR2
func calcPolygonLength(n: int) -> float:
	var length = 0.0
	for i in range(n):
		length += (polygon[i] - polygon[i + 1]).length()
	return length

# converts normal coordinates to phase space coordinates
func R2ToPS(start: Vector2, dir: Vector2) -> Vector2: 
	var index: int = 0
	var min_distance: float = INF
	for i in range(polygon.size()-1):	# -1 since polygon is closed
		var point_projected = Geometry.get_closest_point_to_segment_2d(start, polygon[i], polygon[i+1])
		var distance = start.distance_squared_to(point_projected)
		if min_distance > distance:
			index = i
			min_distance = distance
	
	var angle = abs((polygon[index + 1] - polygon[index]).angle_to(dir))
	
	# could calculate polylength with calcPolyLength, but can also just leave it like this
	var polylength = 0
	var pos = 0
	for j in range(polygon.size() - 1):
		polylength += (polygon[j] - polygon[j + 1]).length()
		if j == index - 1:
			pos = polylength
	pos += (polygon[index] - start).length()
	
	var pscoords = Vector2(pos / polylength, angle / PI)
	return pscoords

# converts phasespace coordinates to normal coordinates 
func PSToR2(psc: Vector2) -> Array:
	var distance_left = psc[0] * calcPolygonLength(polygon.size() - 1)
	var currentIndexOnPolygon = 0
	while (distance_left - calcPolygonLength(currentIndexOnPolygon + 1) > 0.0):
		currentIndexOnPolygon += 1
	
	
	var currentlength = calcPolygonLength(currentIndexOnPolygon) 
	var normside = (polygon[currentIndexOnPolygon + 1] - polygon[currentIndexOnPolygon]).normalized()
	var currentPosition = polygon[currentIndexOnPolygon] + (distance_left - currentlength) * normside
	
	#var rotator = [Vector2( cos(PI * psc[1]), sin(PI * psc[1]) ), Vector2 (-sin(PI * psc[1]), cos(PI * psc[1]))]
	var currentDirection = normside.rotated(PI * psc[1])
	
	# var dir = currentDirection
	var start = currentPosition + 1e-6 * currentDirection
	var is_inside = Geometry.is_point_in_polygon(start, polygon)
	
	if !is_inside:
		currentDirection = normside.rotated(-PI * psc[1])
		
	
	return [currentPosition, currentDirection]
	


