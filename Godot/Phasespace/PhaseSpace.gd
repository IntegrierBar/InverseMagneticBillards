extends Sprite#TextureRect

#const multimesh_scene = preload("res://Phasespace/MultiMesh.tscn")

var phase_space: Image
var background : ImageTexture = null
var sizex = 400#rect_size.x
var sizey = 400#rect_size.y

var traj_script 
var instr_label
var num_traj_in_batch
var ps_coords
#onready var multimesh = $"../PSPoints"	# this is where all the points are drawn
onready var multimesh_handler = $"../MultimeshHandler"

var mouse_inside = false
var drawInNormalSpace = true

# use state machine to handle spawning single trajectories and trajectory batches 
enum STATES {
	REST, # base state, nothing happens here
	SINGLE,  # spawns a single trajectory on click in phasespace
	BATCH1,  # first click for spawning a batch of trajectories from phase space
	BATCH2  # second click for spawning a batch of trajectories from phase space
}

var current_state = STATES.REST
var batch_coord1 # saves the first click for spawning a batch of trajectories


func _ready():
	phase_space = Image.new()
	phase_space.create(sizex, sizey, false, Image.FORMAT_RGB8)
	phase_space.fill(Color.black)
	
	background = ImageTexture.new()
	background.create_from_image(phase_space)
	self.texture = background
	
	traj_script = get_tree().get_nodes_in_group("Trajectories")[0]
	instr_label = get_tree().get_nodes_in_group("TrajBatchInstr")[0]
	num_traj_in_batch = get_tree().get_nodes_in_group("NumberTrajInBatch")[0]
	ps_coords = get_tree().get_nodes_in_group("PhasespaceCoordinates")[0]


func _set_inside():
	mouse_inside = true
	ps_coords.show()
	
func _set_outside():
	mouse_inside = false
	ps_coords.hide()


func _process(delta):
	if mouse_inside:
		var ps_coord = local_to_ps()
		var valid_coord = ps_coord[0] >= 0 and ps_coord[0] <=1 and ps_coord[1] >= 0 and ps_coord[1] <= 1
		if valid_coord:
			var string = "(%.3f, %.3f)"
			ps_coords.text = string % [ps_coord[0], ps_coord[1]]
		else:
			ps_coords.text = ""


func _input(event):
	if mouse_inside:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				mouse_input()


func mouse_input():
	# check that the given coordinates are valid, that means are between 0 and 1 before matching states
	var ps_coord = local_to_ps()
	var valid_coord = ps_coord[0] >= 0 and ps_coord[0] <=1 and ps_coord[1] >= 0 and ps_coord[1] <= 1
	if valid_coord:
		match current_state:
			STATES.SINGLE:
				# var ps_coord = local_to_ps()
				traj_script._spawn_ps_traj_on_click(ps_coord, drawInNormalSpace)
				current_state = STATES.REST
			STATES.BATCH1:
				# belongs together with state batch2, both are needed to spawn a trajectory batch
				batch_coord1 = ps_coord
				current_state = STATES.BATCH2
			STATES.BATCH2:
				current_state = STATES.REST
				instr_label.text = " "
				var n = int(num_traj_in_batch.text)
				traj_script._spawn_ps_traj_batch(batch_coord1, ps_coord, n, drawInNormalSpace)
			STATES.REST:
				pass


# called everytime an iteration was done
func add_points_to_phasespace(points: Array):
	var rescaled_points = []
	for i in range(points.size()):
		rescaled_points.append(rescale(points[i]))
	multimesh_handler.add_points(rescaled_points)


# from phase space coords, to world coords
func rescale(points: Array) -> Array:
	var rescaled_points = []
	for p in points:
		rescaled_points.append(Vector2(sizex*p.x, sizey*p.y) - Vector2(sizex/2, sizey/2))
	return rescaled_points


# from world coords to phase space coords
func rescale_to_ps(points: Array) -> Array:
	var rescaled_points: Array = []
	for p in points:
		rescaled_points.append(Vector2(p.x/sizex + 0.5, p.y/sizey + 0.5))
	return rescaled_points


func add_preliminary_trajectory(color: Color):
	multimesh_handler.add_preliminary_trajectory(color)


func add_trajectory(pos: Vector2, color: Color):
	multimesh_handler.add_trajectory(rescale([pos]), color)


func remove_trajectory(index: int):
	multimesh_handler.remove_trajectory(index)


func remove_all_trajectories():
	multimesh_handler.remove_all()


func reset_all_trajectories():
	multimesh_handler.reset()


func set_initial_values(index: int, pos: Vector2):
	multimesh_handler.set_initial_values(index, rescale([pos]))


func set_color(index: int, color: Color):
	multimesh_handler.set_color(index, color)


# calculates the phase space coords of the current mouse position
func local_to_ps() -> Vector2:
	var locpos = get_local_mouse_position()
	locpos = locpos + Vector2(sizex/2, sizey/2)
	var x = locpos[0] / sizex
	var y = locpos[1] / sizey
	return Vector2(x, y)


func _on_SpawnTrajOnClickButton_pressed():
	current_state = STATES.SINGLE


func _on_SpawnTrajBatch_pressed():
	if num_traj_in_batch.text.is_valid_integer():
		current_state = STATES.BATCH1
		instr_label.text = "Click twice to select two phasespace coordinates"
	else: 
		instr_label.text = "Number of trajectories in the batch needed"


func _on_ClearPSTrajectories_pressed():
	multimesh_handler.clear()


func _on_DrawnInNormalSpace_toggled(button_pressed):
	drawInNormalSpace = button_pressed
