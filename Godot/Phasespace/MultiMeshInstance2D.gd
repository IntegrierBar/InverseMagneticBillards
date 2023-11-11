# each trajectory gets drawn in phase space with one multimesh

extends MultiMeshInstance2D

onready var point_shader: Shader = preload("res://Phasespace/Point_shader.gdshader")

var color: Color = Color.red

func _ready():
	multimesh = MultiMesh.new()
	multimesh.mesh = PointMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.color_format = MultiMesh.COLOR_FLOAT
	multimesh.instance_count = 10000	# could consider higher
	multimesh.visible_instance_count = 0
#	var material = ShaderMaterial.new()
#	material.shader = point_shader
#	material.set_shader_param("point_size", 100123)
#	var material = SpatialMaterial.new()
#	material.flags_use_point_size = true
#	material.params_point_size = 10.0
#
#	multimesh.mesh.surface_set_material(0, material)
	#multimesh.mesh.material = material
	#print(multimesh.mesh.material.params_point_size)
	#set_point_size(100000)

func add_trajectory_points(points: Array):
	for i in range(points.size()):
		multimesh.set_instance_color(multimesh.visible_instance_count + i, color)
		multimesh.set_instance_transform_2d(multimesh.visible_instance_count + i, Transform2D(0, points[i]))
	multimesh.visible_instance_count += points.size()

func reset():
	multimesh.visible_instance_count = 1

func clear():
	multimesh.visible_instance_count = 0

func set_color(c: Color):
	self.color = c
	for i in range(multimesh.visible_instance_count):
		multimesh.set_instance_color(i, color)


#func set_point_size(new_point_size: float):
#	var mat = multimesh.mesh.surface_get_material(0)
#	mat.set_shader_param("point_size", new_point_size)
