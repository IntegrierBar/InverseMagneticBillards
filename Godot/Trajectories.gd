
extends Node2D

var mouse_inside = false

var phase_space
var flow_map
var polygon_instr
var trajectory_instr
var radius_edit
var radius_slider
var traj_control
var single_ps_traj
var corner_count
var ngon_radius
var polygon_vertex
var grid_size
var traj_num_spawn
var rs_coords
var stop_at_corner

var newpos # currently needed to change direction 
var newdir # now also need a variable for the direction to draw 

# phasespace coordinates of the starting position of the last shown trajectory
# inistialise to value it cannot take before first use to check whether it was set
var last_shown_traj: Vector2 = Vector2(-1,-1) 

var zoom: float = 0.1 # initialse zoom to initial value from Camera2D

# for polygon with n vertices has n+1 entries, the first and last one are the same
# makes drawing all sides of the polygon easier
# IMPORTANT: all elements of polygon have inverted y-values, since that is how drawing in Godot works!!
var polygon: Array 
var polygon_color: Color
var polygon_closed: bool

onready var trajectories = $Trajectory
# handles trajectories that can be shown via the flowmap
onready var trajectory_to_show = $TrajectoryToShow

signal close_polygon(p)

var batch: int
var batch_to_show: int = 1
var radius: float
var billiard_type: int = 0

# use a state machine to hand changes of the polygon and the trajectory
enum STATES {
	ITERATE,  # base state, iterate trajectories can be called here
	SET_START,  # allows setting the starting position of one trajectory through click in normal space
	SET_DIRECTION,  # allows setting starting direction of this trajectory though click in normal space
	SET_POLYGON,  # state that allows to place vertices for a new polygon, they are connected in the 
					# order they are placed in
	TEXT_EDIT, # state for when start and direction are set via text edit fields, is left once indication line is drawn
	FILL_PS		# state to automatically fill phasespace
}
var current_state = STATES.ITERATE
var fill_ps_trajectories_to_spawn: int = 1

# index of trajectory that is to be edited
var trajectory_to_edit: int


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()	# make sure we get different random numbers every time we start
	# Nodes that have to be accessed, using groups allows to change the nodes position in the tree
	# without having to change anything here
	phase_space = get_tree().get_nodes_in_group("PhaseSpace")[0]
	flow_map = get_tree().get_nodes_in_group("FlowMap")[0]
	polygon_instr = get_tree().get_nodes_in_group("PolygonInstructions")[0]
	trajectory_instr = get_tree().get_nodes_in_group("TrajectoriesInstructions")[0]
	radius_edit = get_tree().get_nodes_in_group("RadiusEdit")[0]
	radius_slider = get_tree().get_nodes_in_group("RadiusSlider")[0]
	traj_control = get_tree().get_nodes_in_group("TrajectoriesControlPart")[0]
	single_ps_traj = get_tree().get_nodes_in_group("SinglePSTraj")[0]
	corner_count = get_tree().get_nodes_in_group("SetCornerCount")[0]
	ngon_radius = get_tree().get_nodes_in_group("SetNGonRadius")[0]
	polygon_vertex = get_tree().get_nodes_in_group("PolygonVertexControl")[0]
	grid_size = get_tree().get_nodes_in_group("GridSize")[0]
	traj_num_spawn = get_tree().get_nodes_in_group("TrajNumToSpawn")[0]
	rs_coords = get_tree().get_nodes_in_group("RegularSpaceCoordinates")[0]
	stop_at_corner = get_tree().get_nodes_in_group("StopAtCorner")[0]
	
	$"../Camera2D".connect("zoom_changed", self, "zoom_changed")
	
	# set radius
	batch = 1  # number of iterations made on one "iterate" click
	radius = 1
	trajectories.set_radius(radius)
	trajectory_to_show.set_radius(radius)
	radius_slider.value = radius
	
	trajectories.reset_trajectories()
	trajectory_to_show.reset_trajectories()
	
	# set initial polygon
	polygon_closed = false
	polygon = []
	polygon_color = Color(1, 1, 1)
	add_polygon_vertex(Vector2(0,0))
	add_polygon_vertex(Vector2(10,0))
	add_polygon_vertex(Vector2(0,-10))
	
	# polygon cannot be closed when starting the application because that leads to errors
	# close_polygon()
	current_state = STATES.SET_POLYGON 
	trajectory_to_edit = 0 
	trajectories.set_billard_type(0) ########## for inverse magnetic


func _process(_delta):
	# in the following states, the normal space has to be redrawn every frame
	match current_state:
		STATES.SET_DIRECTION:
			update()
		STATES.SET_POLYGON:
			if polygon.size() > 0:
				update()
		STATES.SET_START:
			update()
		STATES.FILL_PS:
			# find hole and add new trajecotry there
			if fill_ps_trajectories_to_spawn <= 0:
				current_state = STATES.ITERATE
				trajectories.addPointsToGrid = false
				fill_ps_trajectories_to_spawn = int(traj_num_spawn.text)
				return
			var c = Color.from_hsv(randf(), 1.0, 1.0)	# create random color to add to our hole color
			var hole: Array = trajectories.hole_in_phasespace() # index 0 is coords, index 1 is close color
			var next_start: Vector2 = hole[0]
			if next_start.is_equal_approx(Vector2.ZERO):
				current_state = STATES.ITERATE
				return
			var next_color = Color(hole[1].r - 0.3*c.r, hole[1].g - 0.3*c.g, hole[1].b - 0.3*c.g).lightened(0.3)
			if hole[1] == Color(1,1,1):
				next_color = c
			add_trajectory_ps(next_start, next_color)
			if !phase_space.drawInNormalSpace:
				trajectories.set_max_count_index(traj_control.get_child_count() - 6, -1)
			iterate_batch()
			fill_ps_trajectories_to_spawn -= 1
	
	# Shows coordinates of current mouse position in the upper right corner of the regular space field
	var mouse_pos = get_local_mouse_position()
	var string = "(%.3f, %.3f)"
	rs_coords.text = string % [mouse_pos[0], (-1) * mouse_pos[1]]


func _draw():
	# Polygon gets drawn here
	if polygon.size() > 1:
		draw_polyline(polygon, polygon_color)
	match current_state:
		STATES.SET_DIRECTION:
			# draw line between starting position and mouse position to indicate the direction
			draw_line(newpos, get_local_mouse_position(), trajectories.get_trajectory_colors()[trajectory_to_edit])
		STATES.SET_POLYGON:
			# draw line between last placed polygon vertex and mouse position
			draw_line(polygon.back(), get_local_mouse_position(), polygon_color)
		STATES.SET_START:
			# draw circle on the trajectory closest to current mouse position
			draw_circle(snap_to_polygon(get_local_mouse_position()), 10.0 * zoom, trajectories.get_trajectory_colors()[trajectory_to_edit])
		STATES.TEXT_EDIT:
			# only needed to draw indication line if start position or direction are set via text_edit
			draw_line(newpos, newdir + newpos, trajectories.get_trajectory_colors()[trajectory_to_edit])
			# go back to iterate state once indication line was drawn
			current_state = STATES.ITERATE 


####################### POLYGON ####################################################################


# Godot uses negative y-axis. Need to invert y to get correct coords
func invert_y(p: Vector2) -> Vector2:
	return Vector2(p.x, -p.y)


func add_polygon_vertex(vertex: Vector2):
	if !polygon_closed:		# dont allow adding of vertices when polygon is closed
		polygon.append(vertex)
		trajectories.add_polygon_vertex(invert_y(vertex))
		trajectory_to_show.add_polygon_vertex(invert_y(vertex))
		
		# handles the nodes necessary to make vertices moveable
		$PolygonVertexHandler.add_polygon_vertex(vertex)
		polygon_vertex._on_PolygonVertex_added(vertex)
		
	update()


func close_polygon():
	# polygon cannot be closed if it is already closed or contains less than three vertices
	if polygon_closed || polygon.size() < 3:
		return
	# append first vertex as last vertex 
	polygon.append(polygon[0])
	emit_signal("close_polygon", polygon)	# signal flow map, that polygon is closed
	trajectories.close_polygon()
	trajectory_to_show.close_polygon()
	polygon_closed = true
	trajectories.reset_trajectories()
	update()


# removes all trajectories except the first
func clear_polygon():
	polygon = []
	polygon_closed = false
	
	var trajcount = trajectories.get_trajectory_colors().size()
	
	# remove all trajectories
	for i in range(0, trajcount): 
		# Note: it looks like Godot and C++ have different ways to handle how to remove objects! Watch out with the indices!
		var container = traj_control.get_child(4 + i)	# this index has to change with the iterations despite the node at the position being removed
		container.queue_free()
		trajectories.remove_trajectory(0)	# this index has to be the same because the trajectory previously at position 2 is removed in the previous iteration
	
	trajectories.clear_polygon()
	trajectory_to_show.clear_polygon()
	$PolygonVertexHandler.clear()
	polygon_vertex.clear_polygon()
	trajectory_to_edit = 0 # need to set back to 0 because this should be the only trajectory left 
	phase_space.remove_all_trajectories()


func change_polygon_vertex(pos: Vector2, n: int):
	if n != 0:
		polygon[n] = pos
	else:
		polygon[0] = pos
		polygon[-1] = pos
	trajectories.set_polygon_vertex(n, invert_y(pos))
	trajectory_to_show.set_polygon_vertex(n, invert_y(pos))
	phase_space.reset_all_trajectories()
	emit_signal("close_polygon", polygon)
	update()
	
	var trajs_ps = trajectories.get_trajecotries_phasespace()
	
	for i in trajs_ps.size():
		write_StartPosAndDir(trajs_ps[i], i)


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


func _on_RegularNGonButton_pressed():
	var n = corner_count.text
	var r = ngon_radius.text
	if n.is_valid_integer() and r.is_valid_float():
		var rad = float(r)
		var count = int(n)
		
		clear_polygon()
		
		for i in range(count):
			var vertex = Vector2(rad * cos(2 * PI * i / count), rad * sin(2 * PI * i / count))
			add_polygon_vertex(vertex)
			
		# close polygon
		polygon.append(polygon[0])
		emit_signal("close_polygon", polygon)	# signal flow map, that polygon is closed
		trajectories.close_polygon()
		trajectory_to_show.close_polygon()
		polygon_closed = true
		
		trajectories.reset_trajectories()
		update()
		if trajectories.get_trajectory_colors().size() > 0: 
			current_state = STATES.SET_START


##################### TRAJECTORIES #################################################################


# function is currently only called to add INITIAL trajectories, that means the actual starting 
# coordinates are not known yet! 
# after this function was called, set_initial_values will / should always be called!
func add_trajectory(start: Vector2, dir: Vector2, color: Color):
	trajectories.add_trajectory(invert_y(start), invert_y(dir), color)
	phase_space.add_preliminary_trajectory(color)
	_new_trajectory_added(color)


# this function is only used, if the starting coordinates are already known! 
func add_trajectory_ps(pos: Vector2, color: Color):
	trajectories.add_trajectory_phasespace(pos, color)
	phase_space.add_trajectory(pos, color)
	_new_trajectory_added(color)
	
	var count = traj_control.get_child_count()
	var number = count - 6 # new trajectories are always added at the end
	write_StartPosAndDir(pos, number)


# spawns and connects single trajectory control 
func _new_trajectory_added(colour):
	var count = traj_control.get_child_count()
	var scene = load("res://ControlPanel/OneTrajectoryControlContainer.tscn")
	var newTrajControl = scene.instance()
	
	traj_control.add_child(newTrajControl)
	traj_control.move_child(newTrajControl, count - 1)
	
	var colourPicker = newTrajControl.get_child(1).get_child(2)
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


# write start position and direction into text edit fields for trajectories spawned vie phasespace 
# coordinates
# trajectories spawned via mouse input in regular space have there text set before set_inital_values
# is called and therefore have to handled somwhere else, see write_StartPos and write_EndPos
func write_StartPosAndDir(pscoords: Vector2, number: int):
	var rs = PSToR2(pscoords)
	var startpos = invert_y(rs[0])
	var startdir = invert_y(rs[1])
	
	# trajectory number plus 4 is the position of the current trajectory control node
	var traj = traj_control.get_child(number + 4) 
	
	var start = traj.get_child(1).get_child(0)
	start.text = String(startpos)
	
	var direction = traj.get_child(1).get_child(1)
	direction.text = String(startdir)


func iterate_batch():
	var phase_space_points = trajectories.iterate_batch(batch, stop_at_corner.pressed)	# bool is whether to stop at vertex
	phase_space.add_points_to_phasespace(phase_space_points)


func set_initial_values(index: int, start: Vector2, dir: Vector2):
	trajectories.set_initial_values(index, invert_y(start), invert_y(dir))
	var pscoord = R2ToPS(start, dir)
	phase_space.set_initial_values(index, pscoord)


####################### USER INPUT #################################################################


# used to know if mouse is inside the clickable area or not
func _set_inside():
	mouse_inside = true
	rs_coords.show()


func _set_outside():
	mouse_inside = false
	rs_coords.hide()


func _input(event):
	if mouse_inside:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				# necessary for the case that trajectories from phasespace are currently shown
				# hides this trajectory and shows the normal trajectories again
				trajectories.show()
				trajectory_to_show.hide()
				mouse_input()
	if current_state == STATES.SET_POLYGON:
		if Input.is_action_pressed("close_polygon"):
			close_polygon()
			polygon_instr.text = " "
			if trajectories.get_trajectory_colors().size() > 0: 
				current_state = STATES.SET_START
			else:
				current_state = STATES.ITERATE


func mouse_input():
	match current_state:
		STATES.SET_POLYGON: 
			add_polygon_vertex(get_local_mouse_position())
		STATES.SET_START:
			newpos = snap_to_polygon(get_local_mouse_position())
			write_StartPos()
			current_state = STATES.SET_DIRECTION
			trajectory_instr.text = "Click to choose a new direction"
		STATES.SET_DIRECTION:
			var dir = get_local_mouse_position() - newpos
			set_initial_values(trajectory_to_edit, newpos, dir)
			newdir = dir
			write_StartDir(dir)
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


# Sets maximum of how many iterations will be drawn in regular space for all trajectories
func _on_EditMaxDrawnIterations_text_changed(new_text):
	if new_text.is_valid_integer():
		var maxnum = int(new_text)
		
		trajectories.set_max_count(maxnum)


# Sets the maximum number of iterations
func _on_EditMaxIterations_text_changed(new_text):
	if new_text.is_valid_integer():
		var maxiter = int(new_text)
		trajectories.set_max_iter(maxiter)


# user wants to make new polygon
func _on_ButtonPolygon_pressed():
	current_state = STATES.SET_POLYGON
	clear_polygon()
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
# only works if current_state is ITERATE to prevent bugs
func _on_NewStartPos_pressed(id):
	if current_state == STATES.ITERATE:
		current_state = STATES.SET_START
		var node = instance_from_id(id)  
		trajectory_to_edit = node.get_index() - 4
		trajectory_instr.text = "Click to choose a new start position"


# writes start position into text edit field if the start position is changed in the regular space
# via mouse input
# was not added to add_trajectory so that the start position can be shown before the start direction
# is chosen
func write_StartPos():
	var traj = traj_control.get_child(trajectory_to_edit + 4)
	var start = traj.get_child(1).get_child(0)
	var string = String(invert_y(newpos))
	start.text = string


# writes start direction into text edit field if the start direction is changed in the regular space
# via mouse input
# was not added to add_trajectory so that the start position can be shown before the start direction
# is chosen
func write_StartDir(dir):
	var traj = traj_control.get_child(trajectory_to_edit + 4)
	var direction = traj.get_child(1).get_child(1)
	var string = String(invert_y(dir))
	direction.text = string	


func on_InitialValues_text_changed(index: int, v_pos: Vector2, v_dir: Vector2):
	current_state = STATES.TEXT_EDIT
	trajectory_to_edit = index
	var pos_on_polygon = snap_to_polygon(invert_y(v_pos))
	var traj = traj_control.get_child(trajectory_to_edit + 4)
	var start = traj.get_child(1).get_child(0)
	var string = String(invert_y(pos_on_polygon))
	start.text = string
	
	trajectories.set_initial_values(index, invert_y(pos_on_polygon), v_dir)
	var pscoord = R2ToPS(pos_on_polygon, invert_y(v_dir))
	phase_space.set_initial_values(index, pscoord)
	
	newpos = pos_on_polygon
	newdir = invert_y(v_dir)
	update()
	# have to change draw function to draw an indication of the current start position and direction


# radius is set
func _on_SetRadiusTextEdit_text_entered(new_text):
	if new_text.is_valid_float():
		var newradius = new_text.to_float()
		if newradius < radius_slider.max_value: 
			# change slider position to value in text edit field if possible
			radius_slider.value = newradius
		else: 
			# this allows to set the radius larger than 20 via the text field
			# sets slider value to largest value possible
			radius_slider.value = radius_slider.max_value
			# only need to reset if we are in inverse magnetic billiard
			if billiard_type == 0:
				phase_space.reset_all_trajectories()
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
		
		# only need to reset if we are in inverse magnetic billiard
		if billiard_type == 0:
			phase_space.reset_all_trajectories()
		trajectories.set_radius(newradius)
		trajectory_to_show.set_radius(newradius)
		flow_map.set_radius(newradius)
	else: 
		# means a value larger than the max value might have been entered into the text field
		# resetting image is done in the TextEdit_text_changed function
		pass


# change number of iterations that are computed and drawn when clicking on iterate
func _on_EditBatchSize_text_changed(new_text):
	if new_text.is_valid_integer():
		var newbatch = int(new_text)
		batch = newbatch


# starts to look for holes in phasespace by entering the fill phasespace state
func _on_StartFillPSButton_pressed():
	if current_state == STATES.ITERATE:
		if traj_num_spawn.text.is_valid_integer():
			var tns = int(traj_num_spawn.text)
			fill_ps_trajectories_to_spawn = tns
		else:	# If the user did not write valid integer, do nothing
			return
		current_state = STATES.FILL_PS
		trajectories.addPointsToGrid = true	# add points after iteration to grid
		# caluculate lower_left and upper_right
		var view_rect: Array = $"../../../../Phasespace/ViewportContainer/Viewport/Camera2D".get_view_rectangle()	# get view rectangle from camera of PS
		var scaled_view_rect: Array = phase_space.rescale_to_ps(view_rect)	# rescale to get phase space coords
		# make sure lower_left and upper right are not outside phase space
		# can alternatively do min in C++ code for width and height, but this is not slow, so I dont think there is a need for it
		var lower_left: Vector2 = Vector2(max(0, scaled_view_rect[0].x), max(0, scaled_view_rect[0].y))
		var upper_right: Vector2 = Vector2(min(1, scaled_view_rect[1].x), min(1, scaled_view_rect[1].y))
		trajectories.set_bounds(lower_left, upper_right)
		_get_GridSizeEdit()


# gets grid size for looking for holes in phasespace 
func _get_GridSizeEdit():
	if grid_size.text.is_valid_float():
		var gs = float(grid_size.text)
		trajectories.set_grid_size(gs)


####################### ADDING TRAJECTORIES ########################################################


# adds a new trajectory via the normal control 
# only works if we are in ITERATE state to prevent bugs
func _on_NewTrajectoriesButton_pressed():
	if current_state == STATES.ITERATE:
		current_state = STATES.SET_START
		
		var random_colour = Color(randf(), randf(), randf())
		
		add_trajectory(Vector2(2,0), Vector2(1,-1), random_colour)
		trajectory_to_edit = trajectories.get_trajectory_colors().size() - 1


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
			add_trajectory_ps(ps_pos, colour)
			# change colour of the colour picker so that the user does not need to change it manually
			var random_colour = Color(randf(), randf(), randf())
			single_ps_traj.get_child(0).get_child(1).set_pick_color(random_colour)


# spawns trajectory in normal and phasespace according to the click position int phasespace
func _spawn_ps_traj_on_click(ps_coord, draw):
	var colour = single_ps_traj.get_child(0).get_child(1).get_pick_color()
	add_trajectory_ps(ps_coord, colour)
	# change colour of the colour picker so that the user does not need to change it manually
	var random_colour = Color(randf(), randf(), randf())
	single_ps_traj.get_child(0).get_child(1).set_pick_color(random_colour)
	
	if !draw:
		trajectories.set_max_count_index(traj_control.get_child_count() - 6, -1)


# spawns a batch of trajectories in a rectangle between two clicks in phasespace
func _spawn_ps_traj_batch(bc1: Vector2, bc2: Vector2, n: int, draw: bool):
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
	
	for i in range(pos.size()):
		add_trajectory_ps(pos[i], colours[i])
		if !draw:
			trajectories.set_max_count_index(traj_control.get_child_count() - 6, -1)


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
	
	for i in range(x):
		for j in range(y):
			
			var pos = Vector2(i * xstep, j * ystep)
			positions.append(pos + xymin) 
			var c = Color(min(1, 2 - ((i + 1)/float(x) + j/float(y))), (i + 1)/float(x), j/float(y), 1)  
			colors.append(c) 
			# colors still not very good, different but difficult to see, not bright enough
	
	return [positions, colors]


# spawns trajectory on click in flowmap at the corresponding phasespace coordinates
func _spawn_fm_traj_on_click(ps_coord):
	var colour = Color(randf(), randf(), randf())
	add_trajectory_ps(ps_coord, colour)


# spawns trajectory that is currently shown in regular space as trajectory
func _on_SpawnShowenTrajButton_pressed():
	if trajectory_to_show.visible:
		if last_shown_traj != Vector2(-1,-1):
			var colour = Color(randf(), randf(), randf())
			add_trajectory_ps(last_shown_traj, colour)


####################### SHOW TRAJECTORIES ##########################################################


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
		trajectory_to_show.iterate_batch(batch_to_show, false)
		# removes the indication of start position and direction of the normal trajectories that 
		# have not been iterated yet
		trajectory_to_show.update()
		
		last_shown_traj = ps_coord


func _show_backwards_fm_traj_on_click(ps_coord):
	if polygon_closed:
		update()
		trajectory_to_show.clear_trajectories()
		trajectories.hide()
		trajectory_to_show.show()
		var color = Color.aqua
		color = Color.deeppink
		trajectory_to_show.add_inverse_trajectory_phasespace(ps_coord, color)
		trajectory_to_show.iterate_inverse_batch(batch_to_show)
		trajectory_to_show.update()
		
		last_shown_traj = ps_coord


####################### DELETE TRAJECTORIES ########################################################


# deletes the trajectory from normal space
# only works if we are in the iterate state. Otherwise does nothing to prevent bugs
func _on_delete_trajectory_pressed(id):
	if current_state == STATES.ITERATE:
		var node = instance_from_id(id)  
		trajectory_to_edit = node.get_index() - 4
		node.queue_free()
		phase_space.remove_trajectory(trajectory_to_edit)
		trajectories.remove_trajectory(trajectory_to_edit)
		update()


# deletes all trajectories in normal space, also resets phasespace image 
# only works if we are in the iterate state. Otherwise does nothing to prevent bugs
func _on_DeleteAllTrajectories_pressed():
	if current_state == STATES.ITERATE:
		var trajcount = trajectories.get_trajectory_colors().size()
		for i in range(trajcount): 
			var container = traj_control.get_child(4 + i)
			container.queue_free() 
			trajectories.remove_trajectory(0)
		phase_space.remove_all_trajectories()
		# Note: moving the position of the delete button means that the code for adding new trajectories
		# has to be changed as well! The new trajectories are currentlly moved to a fixed position in 
		# relation to the other children of the parent!
		update()


####################### OTHER FUNCTIONS ############################################################


# button that resets all trajectories to their start position and direction (at least in theory) 
func _on_ResetAllTrajectories_pressed():
	trajectories.reset_trajectories()
	phase_space.reset_all_trajectories()


# changes colour of a trajectory
func _on_color_changed(id):
	var node = instance_from_id(id)  
	trajectory_to_edit = node.get_index() - 4
	
	var colourPicker = node.get_child(1).get_child(2)
	var c = colourPicker.get_pick_color()
	trajectories.set_color(trajectory_to_edit, c) 
	phase_space.set_color(trajectory_to_edit, c)


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
	
	var currentDirection = normside.rotated(PI * psc[1])
	
	var start = currentPosition + 1e-6 * currentDirection
	var is_inside = Geometry.is_point_in_polygon(start, polygon)
	
	if !is_inside:
		currentDirection = normside.rotated(-PI * psc[1])
	
	return [currentPosition, currentDirection]


func is_in_iterate_state() -> bool:
	if current_state == STATES.ITERATE:
		return true
	else:
		return false


# update zoom variable whenever zooming happens in the regular space
func zoom_changed(z):
	zoom = z


func _on_BilliardTypeOptions_item_selected(index):
	billiard_type = index
	trajectories.set_billard_type(index)
	trajectory_to_show.set_billard_type(index)
	phase_space.reset_all_trajectories()
	flow_map.change_billiard_type(index)


# saves all phase space trajectory data to a file
func _on_SavePhaseSpaceData_pressed():
	var data: String = trajectories.get_phasespace_data()
	var file_name: String = "trajectories_" + Time.get_date_string_from_system()# + ".txt"
	if OS.has_feature("web"):	# If we are on web, make it as a dowload
		JavaScript.download_buffer(data.to_utf8(), file_name + ".txt")
	elif OS.has_feature("pc"):	# If on PC make saves data inside %APPDATA%\Godot\app_userdata\InverseMagneticBillard
		var number: int = 0	# used to make sure we dont override at the same day
		var file = File.new()
		while file.file_exists("user://" + file_name + "_" + str(number) + ".txt"):
			number += 1
		file.open("user://" + file_name + "_" + str(number) +  ".txt", File.WRITE)
		file.store_string(data)
		file.close()
	else:
		print("this should not be calling")


