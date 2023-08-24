extends Sprite#TextureRect



#var bounding_box_color = Color.red

var trajectories_to_draw: Array = []
var trajectories_colors: Array = []
var trajectory_count = 0

var phase_space: Image
var background : ImageTexture = null
onready var sizex = 400#rect_size.x
onready var sizey = 400#rect_size.y

var traj_script 
var mouse_inside = false
var instr_label
var num_traj_in_batch

enum STATES {
	REST,
	SINGLE,
	BATCH1, 
	BATCH2
}

var current_state = STATES.REST
var batch_coord1


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
	
	#connect("mouse_entered", self, "_set_inside")
	#connect("mouse_exited", self, "_set_outside")
	

func _set_inside():
	#print("inside")
	mouse_inside = true
	
func _set_outside():
	mouse_inside = false

	
func _input(event):
	if mouse_inside:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				mouse_input()


func mouse_input():
	match current_state:
		STATES.SINGLE:
			var ps_coord = local_to_ps()
			traj_script._spawn_ps_traj_on_click(ps_coord)
			current_state = STATES.REST
		STATES.BATCH1:
			batch_coord1 = local_to_ps()
			current_state = STATES.BATCH2
		STATES.BATCH2:
			var batch_coord2 = local_to_ps()
			
			current_state = STATES.REST
			instr_label.text = " "
			var n = int(num_traj_in_batch.text)
			traj_script._spawn_ps_traj_batch(batch_coord1, batch_coord2, n)
		STATES.REST:
			pass


func reset_image():
	phase_space.fill(Color.black)
	background.set_data(phase_space)
	self.texture = background
	update()

func rescale_image(size):
	#print(size)
	sizex = size.x
	sizey = size.y
	phase_space.create(sizex, sizey, false, Image.FORMAT_RGB8)
	phase_space.fill(Color.black)	
	background = ImageTexture.new()
	background.create_from_image(phase_space)
	self.texture = background
	update()

func rescale(points: Array) -> Array:
	var rescaled_points = []
	for p in points:
		rescaled_points.append(Vector2(sizex*p.x, sizey*p.y))
		#print(rescaled_points)
	return rescaled_points

# Array is an array of arrays, each inner array corresponds to a color
func add_points_to_image(points: Array, colors: PoolColorArray):
	#print("adding points")
	phase_space.lock()
	for i in range(colors.size()):
		for point in rescale(points[i]):
			#print(point)
			phase_space.set_pixelv(point, colors[i])
	phase_space.unlock()
	# set image
	background.set_data(phase_space)
	self.texture = background
	update()
	
func add_initial_coords_to_image(points: Array, colors: PoolColorArray):
	phase_space.lock()
	points = rescale(points)
	for i in range(points.size()):
		#print(points[i])
		phase_space.set_pixelv(points[i], colors[i])
	phase_space.unlock()
	# set image
	background.set_data(phase_space)
	self.texture = background
	update()


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
	reset_image()


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
