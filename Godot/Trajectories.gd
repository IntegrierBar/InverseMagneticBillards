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
var polygon_instr
var trajectory_instr
var radius_edit
var traj_control
var batch_edit
var single_ps_traj

var newpos # currently needed to change direction 
			# TODO: have this handled in gdnative 


# var lines_to_draw # will be handled in gdnative

var polygon: Array
var polygon_color: Color
var polygon_closed: bool

onready var trajectories = $Trajectory

signal close_polygon(p)

var batch: int
var max_count: int
var radius: float

enum STATES {
	ITERATE,
	SET_START,
	SET_DIRECTION,
	SET_POLYGON,
	ADD_TRAJECTORY
}
var current_state = STATES.ITERATE

var trajectory_to_edit: int

# Called when the node enters the scene tree for the first time.
func _ready():
	phase_space = get_tree().get_nodes_in_group("PhaseSpace")[0]
	polygon_instr = get_tree().get_nodes_in_group("PolygonInstructions")[0]
	trajectory_instr = get_tree().get_nodes_in_group("TrajectoriesInstructions")[0]
	radius_edit = get_tree().get_nodes_in_group("RadiusEdit")[0]
	traj_control = get_tree().get_nodes_in_group("TrajectoriesControlPart")[0]
	batch_edit = get_tree().get_nodes_in_group("BatchSizeEdit")[0]
	single_ps_traj = get_tree().get_nodes_in_group("SinglePSTraj")[0]
	
	batch = 1
	trajectories.maxCount = 100
	radius = 1
	trajectories.set_radius(radius)
	trajectories.reset_trajectories()
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
	
	var inst = traj_control.find_node("VBoxContainer")
	var newStartPos = inst.get_child(0).get_child(0)
	var id = inst.get_instance_id()
	newStartPos.connect("pressed", self, "_on_NewStartPos_pressed", [id])
	var deleteTraj = inst.get_child(0).get_child(1)
	deleteTraj.connect("pressed", self, "_on_delete_trajectory_pressed", [id])
	var colourPicker = inst.get_child(1).get_child(1)
	colourPicker.connect("popup_closed", self, "_on_color_changed", [id])
	
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
	update()

func close_polygon():
	trajectories.reset_trajectories()
	if polygon_closed || polygon.size() < 3:
		return
	emit_signal("close_polygon", polygon)	# signal flow map, that polygon is closed
	polygon.append(polygon[0])
	trajectories.close_polygon()
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
			var container = traj_control.get_child(1 + i)
# this index has to change with the iterations despite the node at the position being removed
			container.queue_free()
			# print(container)
			trajectories.remove_trajectory(1)
# this index has to be the same because the trajectory previously at position 2 is removed in the previous iteration
	
	trajectories.clear_polygon()
	trajectory_to_edit = 0 # need to set back to 0 because this should be the only trajectory left 
	# does not work at the moment but I am working on it
	
	
		
	# potentially put this some place else
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



####################### USER INPUT #################################################################
func _input(event):
	if mouse_inside:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
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
			

# iterate Button pressed
func _on_Button_pressed():
	if current_state == STATES.ITERATE:
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
		current_state = STATES.SET_START
		polygon_instr.text = " "
		

	# user wants to input new start position
func _on_NewStartPos_pressed(id):
	current_state = STATES.SET_START
	var node = instance_from_id(id)  
	trajectory_to_edit = node.get_index() - 1
	# print(trajectory_to_edit)  
	phase_space.reset_image() # TODO THIS IS UGLY
	trajectory_instr.text = "Click to choose a new start position"
	

# radius is set
func _on_TextEdit_text_changed(): 
	if radius_edit.text.is_valid_float():
		phase_space.reset_image()
		var newradius = radius_edit.text.to_float()
		trajectories.set_radius(newradius)



# used to know if mouse is inside the clickable area or not
func _set_inside():
	mouse_inside = true

func _set_outside():
	mouse_inside = false

# spawns and connects single trajectory control 
func _new_trajectory_added(colour):
	var count = traj_control.get_child_count()
	var scene = load("res://ControlPanel/OneTrajectoryControlContainer.tscn")
	var newTrajControl = scene.instance()
	
	
	traj_control.add_child(newTrajControl)
	traj_control.move_child(newTrajControl, count - 3)
	
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


func _on_NewTrajectoriesButton_pressed():
	current_state = STATES.SET_START
	
	var random_colour = Color(randf(), randf(), randf())
	
	add_trajectorie(Vector2(2,0), Vector2(1,-1), random_colour)
	trajectory_to_edit = trajectories.get_trajectory_colors().size() - 1
	
	_new_trajectory_added(random_colour)
	
#	var count = traj_control.get_child_count()
#	var scene = load("res://ControlPanel/OneTrajectoryControlContainer.tscn")
#	var newTrajControl = scene.instance()
#
#
#	traj_control.add_child(newTrajControl)
#	traj_control.move_child(newTrajControl, count - 2)
#
#	var colourPicker = newTrajControl.get_child(1).get_child(1)
#	colourPicker.set_pick_color(random_colour)
#
#
#	# connect the change start position button
#	var newStartPos = newTrajControl.get_child(0).get_child(0)
#	var id = newTrajControl.get_instance_id()
#	newStartPos.connect("pressed", self, "_on_NewStartPos_pressed", [id]) 
#
#	# connect color picker button
#	colourPicker.connect("popup_closed", self, "_on_color_changed", [id])
#
#	# connect the delete trajectory button
#	var deleteTraj = newTrajControl.get_child(0).get_child(1)
#	deleteTraj.connect("pressed", self, "_on_delete_trajectory_pressed", [id])
	

func _on_delete_trajectory_pressed(id):
	var node = instance_from_id(id)  
	trajectory_to_edit = node.get_index() - 1
	node.queue_free()
	trajectories.remove_trajectory(trajectory_to_edit)

	
func _on_color_changed(id):
	var node = instance_from_id(id)  
	trajectory_to_edit = node.get_index() - 1
	
	var colourPicker = node.get_child(1).get_child(1)
	var c = colourPicker.get_pick_color()
	trajectories.set_color(trajectory_to_edit, c) 
	
	
func _on_EditBatchSize_text_changed():
	if batch_edit.text.is_valid_integer():
		var newbatch = int(batch_edit.text)
		batch = newbatch


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


func _spawn_ps_traj_on_click(ps_coord):
	var colour = single_ps_traj.get_child(0).get_child(1).get_pick_color()
	add_trajectorie_ps(ps_coord, colour)
	phase_space.add_initial_coords_to_image([ps_coord], [colour])
	_new_trajectory_added(colour)
	

func _spawn_ps_traj_batch(bc1: Vector2, bc2: Vector2, n: int):
	var xmin
	var xmax
	var ymin
	var ymax
	
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
	var xymin = Vector2(xmin, ymin)
	
	var pos = traj_batch_pos(n, w, h, xymin)
	
	var colours : PoolColorArray 
	colours.resize(pos.size())
	colours.fill(Color.aqua)
	#for i in range(colours.size()):
	#	colours[i] = Color(pos[i].x, pos[i].y, 0, 1)
	
	phase_space.add_initial_coords_to_image(pos, colours)
	
	for i in range(pos.size()):
		add_trajectorie_ps(pos[i], colours[i])
		
		_new_trajectory_added(colours[i])
	
	
	
	

func traj_batch_pos(n: int, w: float, h: float, xymin: Vector2) -> Array:
	var x = int(sqrt(n))
	var y = x
	var xstep = w / (x - 1)
	var ystep = h / (y - 1)
	
	var positions : Array
	
	for i in range(x):
		for j in range(y):
			
			var pos = Vector2(i * xstep, j * ystep)
			positions.append(pos + xymin) 
	
	return positions


func _on_DeleteAllTrajectories_pressed():
	var trajcount = trajectories.get_trajectory_colors().size()
	for i in range(trajcount): 
		var container = traj_control.get_child(1 + i)
		container.queue_free()
		trajectories.remove_trajectory(0)
	
	phase_space.reset_image()
	# Note: moving the position of the delete button means that the code for adding new trajectories
	# has to be changed as well! The new trajectories are currentlly moved to a fixed position in 
	# relation to the other children of the parent!
