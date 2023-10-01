extends Node2D
# Why do we need two nodes here? Drawing a circle cannot be undrawn later, therefore the circle
# has to be hidden with hide, a hidden object can however not be entered by a mouse, therefore
# two nodes are needed to highlight the Polygon Vertex 

var pos = Vector2(0,0)
var inside = false
var hold_mouse = false

var traj_script 
var polygon_vertex

# Called when the node enters the scene tree for the first time.
func _ready():
	traj_script = get_tree().get_nodes_in_group("Trajectories")[0]
	polygon_vertex = get_tree().get_nodes_in_group("PolygonVertexControl")[0]
	position = pos

func _draw():
	if inside:
		draw_circle(Vector2.ZERO, 0.3, Color(1, 1, 1))


func _set_inside():
	inside = true
	#self.show()
	update()
	
func _set_outside():
	inside = false
	#self.hide()
	update()


func _input(event):
	if inside:
		# spawn is triggered by left mouse click
		if event is InputEventMouseMotion:
			if event.button_mask == BUTTON_MASK_LEFT:
				if traj_script.is_in_iterate_state():
					position = get_parent().get_local_mouse_position()
					var index = get_index()
					traj_script.change_polygon_vertex(position, index)
					# write the new position into the text edit fields in 
					# polygon vertex control
					polygon_vertex.vertex_moved(position, index)
#			if event.is_action_pressed("MouseLeftButton"):
#				hold_mouse = true
#			if event.is_action_released("MouseLeftButton"):
#				hold_mouse = false


func _process(_delta):
	if hold_mouse: 
		var mouse_pos = get_local_mouse_position()
		traj_script.change_polygon_vertex(mouse_pos, get_index())
		position = mouse_pos
		update()


