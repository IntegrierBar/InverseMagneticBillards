# DEPRECATED USES MULTIMESHHANDLER INSTEAD
# use one multimesh for all trajectories.
# then have to save all data in one massive array

extends MultiMeshInstance2D

# saves all color data
var color_array: Array = []

# each trajectory data is a subarray of this 2d Array
var trajectory_data: Array = []

func _ready():
	multimesh = MultiMesh.new()
	multimesh.mesh = PointMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.color_format = MultiMesh.COLOR_FLOAT
	multimesh.instance_count = 100000	# could consider higher
	multimesh.visible_instance_count = 0

# add a new trajectory
# pos is an Array with exactly one Vector2 inside
func add_trajectory(pos: Array, color: Color):
	color_array.append(color)
	trajectory_data.append(pos)
	# make initial values visible
	multimesh.set_instance_color(multimesh.visible_instance_count, color)
	multimesh.set_instance_transform_2d(multimesh.visible_instance_count, Transform2D(0, pos[0]))
	multimesh.visible_instance_count += 1

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
#	if points.size() != trajectory_data.size():
#		print("this should not happen")
#		print(points)
#		print(trajectory_data)
#		print(points.size())
#		print(trajectory_data.size())
#		return
	for i in range(points.size()):
		trajectory_data[i].append_array(points[i])
		for j in range(points[i].size()):
			multimesh.set_instance_color(multimesh.visible_instance_count, color_array[i])
			multimesh.set_instance_transform_2d(multimesh.visible_instance_count, Transform2D(0, points[i][j]))
			multimesh.visible_instance_count += 1

# delete a single trajectory
func remove_trajectory(index: int):
	color_array.remove(index)
	trajectory_data.remove(index)
	redraw()

# redraws all points
func redraw():
	multimesh.visible_instance_count = 0
	for i in range(trajectory_data.size()):
		for j in range(trajectory_data[i].size()):
			multimesh.set_instance_color(multimesh.visible_instance_count, color_array[i])
			multimesh.set_instance_transform_2d(multimesh.visible_instance_count, Transform2D(0, trajectory_data[i][j]))
			multimesh.visible_instance_count += 1

# resets all trajectories
func reset():
	for i in range(trajectory_data.size()):
		trajectory_data[i] = [trajectory_data[i][0]]
	redraw()

func remove_all():
	color_array = []
	trajectory_data = []
	multimesh.visible_instance_count = 0

# allows the user to set the instance count sinze the maximum is hardware dependent
func set_instance_count(count: int):
	multimesh.instance_count = count
	redraw()

func clear():
	multimesh.visible_instance_count = 0
