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

#onready var trajectory_scene = preload("res://Trajectory.tscn")

onready var phase_space = $"../CanvasLayer/PhaseSpace"

var newpos # currently needed to change direction 
			# TODO: have this handled in gdnative 


# var lines_to_draw # will be handled in gdnative

var polygon: Array
var polygon_color: Color
var polygon_closed: bool

onready var trajectories = $Trajectory

var batch: int
var max_count: int
var radius: float

enum STATES {
	ITERATE,
	SET_START,
	SET_DIRECTION,
	SET_POLYGON
}
var current_state = STATES.ITERATE

var trajectory_to_edit: int

# Called when the node enters the scene tree for the first time.
func _ready():
	batch = 100000
	trajectories.maxCount = 10
	radius = 1
	polygon_closed = false
	polygon = []
	polygon_color = Color(1, 1, 1)
	add_polygon_vertex(Vector2(0,0))
	add_polygon_vertex(Vector2(10,0))
	add_polygon_vertex(Vector2(0,-10))
	close_polygon()
	add_trajectorie(Vector2(1, 0), Vector2(0, -1), Color(0,1,0))
	trajectory_to_edit = 0 # TODO needs button to change

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
			draw_line(newpos, get_global_mouse_position(), Color.green)
		STATES.SET_POLYGON:
			draw_line(polygon.back(), get_global_mouse_position(), polygon_color)
		STATES.SET_START:
			draw_circle(snap_to_polygon(get_global_mouse_position()), 1.0, Color.green)



####################### POLYGON ####################################################################
func add_polygon_vertex(vertex: Vector2):
	if !polygon_closed:		# dont allow adding of vertices when polygon is closed
		polygon.append(vertex)
		trajectories.add_polygon_vertex(vertex)
	update()

func close_polygon():
	if polygon_closed || polygon.size() < 3:
		return
	polygon.append(polygon[0])
	trajectories.close_polygon()
	polygon_closed = true
	update()

func clear_polygon():
	print("clearing polygon")
	polygon = []
	polygon_closed = false
	trajectories.clear_polygon()
	# potentially put this some place else
	phase_space.reset_trajectories()

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
	trajectories.add_trajectory(start, dir, color)
	#phase_space.add_trajectory(color)
	


func iterate_batch():
	var phase_space_points = trajectories.iterate_batch(batch)
	phase_space.add_points_to_image(phase_space_points, trajectories.get_trajectory_colors())
#	for i in range(trajectories.size()):
#		var coordsPhasespace = trajectories[i].iterate_batch(batch)
#		#print(coordsPhasespace)
#		phase_space.add_points_to_trajectory(i, coordsPhasespace)




####################### USER INPUT #################################################################
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			mouse_input()

func mouse_input():
	match current_state:
		STATES.SET_POLYGON: 
			add_polygon_vertex(get_global_mouse_position())
		STATES.SET_START:
			newpos = snap_to_polygon(get_global_mouse_position())
			#trajectories[trajectory_to_edit].set_start(newpos)
			current_state = STATES.SET_DIRECTION
			$"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Trajectories/InstructionsTrajectoriesLabel".text = "Click to choose a new direction"
		STATES.SET_DIRECTION:
			trajectories.set_initial_values(trajectory_to_edit, newpos, get_global_mouse_position() - newpos)
			current_state = STATES.ITERATE
			$"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Trajectories/InstructionsTrajectoriesLabel".text = ""  # this can probably be done nicer

# iterate Button pressed
func _on_Button_pressed():
	update()	# used to get rid of the line indicating the direction
	iterate_batch()

# user wants to make new polygon
func _on_ButtonPolygon_pressed():
	current_state = STATES.SET_POLYGON
	clear_polygon()
	# $"../CanvasLayer/Panel/LabelInstructions".text = "Click to position at least 3 points to create an new polygon"
	$"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Polygon/LabelInstructions".text = "Click to position at least 3 points to create an new polygon"

# close polygon button pressed
func _on_ButtonClosePolygon_pressed():
	if current_state == STATES.SET_POLYGON:
		close_polygon()
		current_state = STATES.SET_START
		$"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Polygon/LabelInstructions".text = "Click to choose a new start position"

# user wants to input new start position
func _on_ButtonStartPos_pressed():
	current_state = STATES.SET_START
	phase_space.reset_image() # TODO THIS IS UGLY
	#$"../CanvasLayer/Panel/LabelInstructions".text = "Click to choose a new start position"
	$"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Trajectories/InstructionsTrajectoriesLabel".text = "Click to choose a new start position"

# radius is set
func _on_TextEdit_text_changed():
	#$"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Radius/HBoxContainer/SetRadiusTextEdit"
	if $"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Radius/HBoxContainer/SetRadiusTextEdit".text.is_valid_float():
		var newradius = $"../CanvasLayer/Panel/MarginContainer/VBoxContainer/Radius/HBoxContainer/SetRadiusTextEdit".text.to_float()
		for t in trajectories:
			t.set_radius(newradius)
