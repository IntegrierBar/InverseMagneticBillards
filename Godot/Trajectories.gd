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




extends Node2D

var mouse_inside = false

#onready var trajectory_scene = preload("res://Trajectory.tscn")
var phase_space# = $"../../../../Phasespace/ViewportContainer/Viewport/MarginContainer/PhaseSpace"
var polygon_instr
var trajectory_instr
var radius_edit
var traj_control

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
	inst.connect("change_start_position", self, "_on_ButtonStartPos_pressed")

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
			draw_line(newpos, get_local_mouse_position(), Color.green)
		STATES.SET_POLYGON:
			draw_line(polygon.back(), get_local_mouse_position(), polygon_color)
		STATES.SET_START:
			draw_circle(snap_to_polygon(get_local_mouse_position()), 1.0, Color.green)



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
	trajectories.clear_polygon()
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
			#print("test")
			if event.button_index == BUTTON_LEFT and event.pressed:
				mouse_input()

func mouse_input():
	#print("hi")
	match current_state:
		STATES.SET_POLYGON: 
			add_polygon_vertex(get_local_mouse_position())
		STATES.SET_START:
			newpos = snap_to_polygon(get_local_mouse_position())
			#trajectories[trajectory_to_edit].set_start(newpos)
			current_state = STATES.SET_DIRECTION
			trajectory_instr.text = "Click to choose a new direction"
			# $"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Trajectories/InstructionsTrajectoriesLabel".text = "Click to choose a new direction"
		STATES.SET_DIRECTION:
			set_initial_values(trajectory_to_edit, newpos, get_local_mouse_position() - newpos)
			#trajectories.set_initial_values(trajectory_to_edit, newpos, get_local_mouse_position() - newpos) DEPRECATED SINCE INVERSION OF Y
			current_state = STATES.ITERATE
			trajectory_instr.text = ""
			#$"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Trajectories/InstructionsTrajectoriesLabel".text = ""  # this can probably be done nicer

# iterate Button pressed
func _on_Button_pressed():
	if current_state == STATES.ITERATE:
		update()	# used to get rid of the line indicating the direction
		iterate_batch()

# user wants to make new polygon
func _on_ButtonPolygon_pressed():
	current_state = STATES.SET_POLYGON
	clear_polygon()
	polygon_instr.text = "Click to position at least 3 points to create an new polygon"
	#$"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Polygon/LabelInstructions".text = "Click to position at least 3 points to create an new polygon"

# close polygon button pressed
func _on_ButtonClosePolygon_pressed():
	if current_state == STATES.SET_POLYGON:
		close_polygon()
		current_state = STATES.SET_START
		polygon_instr.text = "Click to choose a new start position"
		#$"../CanvasLayer/DockableContainer/ControlPanel/ScrollContainer/VBoxContainer/Polygon/LabelInstructions".text = "Click to choose a new start position"

# user wants to input new start position
func _on_ButtonStartPos_pressed(id):
	current_state = STATES.SET_START
	var node = instance_from_id(id)  #not sure if this is needed
	trajectory_to_edit = node.get_index()   # same here
	phase_space.reset_image() # TODO THIS IS UGLY
	trajectory_instr.text = "Click to choose a new start position"
	# $"../CanvasLayer/DockableContainer/ControlPanel/ScrollContainer/VBoxContainer/Trajectories/TrajectoriesLabel".text = "Click to choose a new start position"

# radius is set
func _on_TextEdit_text_changed():
	if radius_edit.text.is_valid_float():
		var newradius = radius_edit.text.to_float()
		for t in trajectories:
			t.set_radius(newradius)



# used to know if mouse is inside the clickable area or not
func _set_inside():
	mouse_inside = true

func _set_outside():
	mouse_inside = false



func _on_NewTrajectoriesButton_pressed():
	current_state = STATES.SET_START
	
	var random_colour = Color(randf(), randf(), randf())
	
	add_trajectorie(Vector2(2,0), Vector2(1,-1), random_colour)
	trajectory_to_edit = trajectories.get_trajectory_colors().size() - 1
	
	var count = traj_control.get_child_count()
	var scene = load("res://ControlPanel/OneTrajectoryControlContainer.tscn")
	var newTrajControl = scene.instance()
	
	traj_control.add_child(newTrajControl)
	traj_control.move_child(newTrajControl, count - 2)
	
	var colourPicker = newTrajControl.get_child(1).get_child(1)
	colourPicker.set_pick_color(random_colour)
	
	# traj_control.add_child()
