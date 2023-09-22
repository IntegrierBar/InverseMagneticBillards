# each trajectory gets drawn in phase space with one multimesh

extends MultiMeshInstance2D


var color: Color = Color.red


func add_trajectory_points(points: Array):
	for i in range(points.size()):
		multimesh.set_instance_color(multimesh.visible_instance_count + i, color)
		multimesh.set_instance_transform_2d(multimesh.visible_instance_count + i, Transform2D(0, points[i]))
	multimesh.visible_instance_count += points.size()

func reset():
	multimesh.visible_instance_count = 1

func clear():
	multimesh.visible_instance_count = 0
