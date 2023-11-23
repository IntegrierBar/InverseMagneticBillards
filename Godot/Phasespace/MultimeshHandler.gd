extends Node2D

var shader_code = preload("res://Phasespace/point_size.tres")

# saves all color data
var color_array: Array = []

# each trajectory data is a subarray of this 2d Array
var trajectory_data: Array = []

var current_multimesh
var instance_count = 100000	# most systems should be able to handle 1 mil, but keep it lower to prevent crashes

var point_size: float = 1.0	# point size of the phase space points

func _ready():
	add_multimesh()


# adds a new multimesh to be used
# and sets it as current multimesh
func add_multimesh():
	var new_multimesh = MultiMeshInstance2D.new()
	new_multimesh.multimesh = MultiMesh.new()
	new_multimesh.multimesh.mesh = PointMesh.new()
	new_multimesh.multimesh.transform_format = MultiMesh.TRANSFORM_2D
	new_multimesh.multimesh.color_format = MultiMesh.COLOR_FLOAT
	new_multimesh.multimesh.instance_count = instance_count
	new_multimesh.multimesh.visible_instance_count = 0
	
	### add shader so that we can modify point_size ###
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader_code
	new_multimesh.material = shader_mat
	new_multimesh.material.set_shader_param("point_size", point_size)
	
	add_child(new_multimesh)
	current_multimesh = new_multimesh


# add a new trajectory
# pos is an Array with exactly one Vector2 inside
func add_trajectory(pos: Array, color: Color):
	color_array.append(color)
	trajectory_data.append(pos)
	# If we have reached maximum instance count, create a new multimesh and use it
	if current_multimesh.multimesh.visible_instance_count + 1 >= instance_count:
		add_multimesh()
	current_multimesh.multimesh.set_instance_color(current_multimesh.multimesh.visible_instance_count, color)
	current_multimesh.multimesh.set_instance_transform_2d(current_multimesh.multimesh.visible_instance_count, Transform2D(0, pos[0]))
	current_multimesh.multimesh.visible_instance_count += 1


func add_preliminary_trajectory(color: Color):
	color_array.append(color)
	trajectory_data.append([])


# pos is an Array with exactly one Vector2 inside
func set_initial_values(index: int, pos: Array):
	trajectory_data[index] = pos
	redraw()


func set_color(index: int, color: Color):
	color_array[index] = color
	redraw()


# points is 2D array of all phase space points
func add_points(points: Array):
	for i in range(points.size()):
		trajectory_data[i].append_array(points[i])
		if current_multimesh.multimesh.visible_instance_count + points[i].size() >= instance_count:
			add_multimesh()
		for j in range(points[i].size()):
			current_multimesh.multimesh.set_instance_color(current_multimesh.multimesh.visible_instance_count, color_array[i])
			current_multimesh.multimesh.set_instance_transform_2d(current_multimesh.multimesh.visible_instance_count, Transform2D(0, points[i][j]))
			current_multimesh.multimesh.visible_instance_count += 1


# delete a single trajectory
func remove_trajectory(index: int):
	color_array.remove(index)
	trajectory_data.remove(index)
	redraw()


# redraws all points
func redraw():
	# first remove all multimeshes
	for child in get_children():
		child.queue_free()
	# add a new child
	add_multimesh()
	for i in range(trajectory_data.size()):		
		for j in range(trajectory_data[i].size()):
			# this has to be inside the inner loop to allow more iterations then "instance_count"
			if current_multimesh.multimesh.visible_instance_count + 1 >= instance_count:
				add_multimesh()
			current_multimesh.multimesh.set_instance_color(current_multimesh.multimesh.visible_instance_count, color_array[i])
			current_multimesh.multimesh.set_instance_transform_2d(current_multimesh.multimesh.visible_instance_count, Transform2D(0, trajectory_data[i][j]))
			current_multimesh.multimesh.visible_instance_count += 1


# resets all trajectories
func reset():
	for i in range(trajectory_data.size()):
		trajectory_data[i] = [trajectory_data[i][0]]
	redraw()


func remove_all():
	color_array = []
	trajectory_data = []
	# remove all multimeshes
	for child in get_children():
		child.queue_free()
	# add a new child
	add_multimesh()


# allows the user to set the instance count since the maximum is hardware dependent
func set_instance_count(count: int):
	instance_count = count
	redraw()


func clear():
	# remove all multimeshes
	for child in get_children():
		child.queue_free()
	# add a new child
	add_multimesh()


func _on_PSPointsInMultimeshTextEdit_text_entered(new_text):
	if new_text.is_valid_integer():
		var number = int(new_text)
		set_instance_count(number) 


func _on_PSPointSizeEdit_text_entered(new_text):
	if new_text.is_valid_float():
		point_size = float(new_text)
		# set shader_param for all multimeshes
		for child in get_children():
			child.material.set_shader_param("point_size", point_size)

