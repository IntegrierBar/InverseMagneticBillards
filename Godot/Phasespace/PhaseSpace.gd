extends Sprite#TextureRect

const multimesh_scene = preload("res://Phasespace/MultiMesh.tscn")

var phase_space: Image
var background : ImageTexture = null
var sizex = 400#rect_size.x
var sizey = 400#rect_size.y

var traj_script 
var instr_label
var num_traj_in_batch
var ps_coords

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

func add_points_to_phasespace(points: Array):
	if points.size() != get_child_count():
		print("houston we got a problem")
		print(points)
		print(get_child_count())
		return
	var meshes = get_children()
	for i in range(points.size()):
		meshes[i].add_trajectory_points(rescale(points[i]))

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
	var trajectory = multimesh_scene.instance()
	trajectory.color = color
	add_child(trajectory)



func add_trajectory(pos: Vector2, color: Color):
	var trajectory = multimesh_scene.instance()
	trajectory.color = color
	add_child(trajectory)
	trajectory.add_trajectory_points(rescale([pos]))

func remove_trajectory(index: int):
	get_child(index).queue_free()

func remove_all_trajectories():
	for child in get_children():
		child.queue_free()

func reset_all_trajectories():
	for mesh in get_children():
		mesh.reset()

func set_initial_values(index: int, pos: Vector2):
	#print("setting inital values of" + str(index))
	if index >= get_child_count():
		print("trying to acces child that does not exist")
	var mesh = get_children()[index]
	# this removes poiints of all trajectories from phasespace
	mesh.clear()
	mesh.add_trajectory_points(rescale([pos]))

func set_color(index: int, color: Color):
	get_child(index).set_color(color)


func local_to_ps() -> Vector2:
	var locpos = get_local_mouse_position()
	locpos = locpos + Vector2(sizex/2, sizey/2)
	#print(locpos)
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
	for mesh in get_children():
		mesh.clear()



func _on_DrawnInNormalSpace_toggled(button_pressed):
	drawInNormalSpace = button_pressed

# Array is an array of arrays, each inner array corresponds to a color
#func add_points_to_image(points: Array, colors: PoolColorArray):
#	#print("adding points")
#	#phase_space.lock()
#	for i in range(colors.size()):
##		for point in rescale(points[i]):
##			#print(point)
##		#	phase_space.set_pixelv(point, colors[i])
##			pass
#		$"../MultiMeshInstance2D".add_trajectory_points(rescale(points[i]))
#	#phase_space.unlock()
#	# set image
#	#background.set_data(phase_space)
#	#self.texture = background
#	#update()

#func reset_image():
#	phase_space.fill(Color.white)
#	background.set_data(phase_space)
#	self.texture = background
#	update()

#func rescale_image(size):
#	#print(size)
#	sizex = size.x
#	sizey = size.y
#	phase_space.create(sizex, sizey, false, Image.FORMAT_RGB8)
#	phase_space.fill(Color.white)	
#	background = ImageTexture.new()
#	background.create_from_image(phase_space)
#	self.texture = background
#	update()

#func add_initial_coords_to_image(points: Array, colors: PoolColorArray):
#	phase_space.lock()
#	points = rescale(points)
#	for i in range(points.size()):
#		#print(points[i])
#		phase_space.set_pixelv(points[i], colors[i])
#	phase_space.unlock()
#	# set image
#	background.set_data(phase_space)
#	self.texture = background
#	update()

#func _draw():
	# draw bounding box of image FOR NOW SKIP THIS
	#draw_rect(Rect2(rect_position, rect_size), bounding_box_color, false)
	
	# CONSIDER DOING EVERYTHING WITH TEXTURES might be faster in the long run
	#print("draw3ing")
#	for i in range(trajectory_count):
#		var color: Color = trajectories_colors[i]
#		#draw_polyline(trajectories_to_draw[i], color)
#		for point in trajectories_to_draw[i]:
#			#print(trajectories_to_draw)
#			#print(point)
#			#draw_circle(point, 10, color)
#			draw_primitive(PoolVector2Array([point]), PoolColorArray([color]), PoolVector2Array())

#func add_trajectory(color: Color):
##	if trajectory_count < 1:
##		trajectories_to_draw = [[]]
##		trajectories_colors = [color]
##	else:
#	trajectories_to_draw.append([])
#	trajectories_colors.append(color)
#	trajectory_count += 1

#func add_points_to_trajectory(index: int, points: Array):
#	if index >= trajectory_count:
#		print("wrong index")
#		return
#	# TODO RESCALING!!!!!!!!!!!!
#	trajectories_to_draw[index].append_array(rescale(points))
#	#print(trajectories_to_draw[index])
#	update()

#func reset_trajectories():
#	trajectories_to_draw = []
#	for i in range(trajectory_count):
#		trajectories_to_draw.append([])
#	update()



