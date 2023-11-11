# each trajectory gets drawn in phase space with one multimesh

extends MultiMeshInstance2D

onready var point_shader: Shader = preload("res://Phasespace/Point_shader.gdshader")

var color: Color = Color.red

# saves the entire phase space trajectory of the trajectory
var data: Array = []

func _ready():
	multimesh = MultiMesh.new()
	multimesh.mesh = PointMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.color_format = MultiMesh.COLOR_FLOAT
	multimesh.instance_count = 100000	# could consider higher
	multimesh.visible_instance_count = 0

func add_trajectory_points(points: Array):
	data.append_array(points)
	for i in range(points.size()):
		multimesh.set_instance_color(multimesh.visible_instance_count + i, color)
		multimesh.set_instance_transform_2d(multimesh.visible_instance_count + i, Transform2D(0, points[i]))
	multimesh.visible_instance_count += points.size()

func reset():
	multimesh.visible_instance_count = 1
	data = [data[0]]

func clear():
	multimesh.visible_instance_count = 0
	data = []

func set_color(c: Color):
	self.color = c
	for i in range(multimesh.visible_instance_count):
		multimesh.set_instance_color(i, color)

func set_instance_count(count: int):
	multimesh.instance_count = max(count, data.size())
	# after changing the instance count, we need to refill the data
	for i in range(data.size()):
		multimesh.set_instance_color(i, color)
		multimesh.set_instance_transform_2d(i, Transform2D(0, data[i]))
	multimesh.visible_instance_count = data.size()

#func set_point_size(new_point_size: float):
#	var mat = multimesh.mesh.surface_get_material(0)
#	mat.set_shader_param("point_size", new_point_size)
