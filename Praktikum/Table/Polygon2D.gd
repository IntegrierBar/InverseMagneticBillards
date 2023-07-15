extends Node2D

func _draw():
	print(polygon)
	draw_polyline(polygon, Color.antiquewhite, 2.0)
	for i in range(1 , polygon.size()):
		draw_line(polygon[i-1], polygon[i], Color.antiquewhite , 2.0)
	draw_line(polygon[polygon.size() - 1] , polygon[0], Color.antiquewhite , 2.0)

func _process(delta):
	update()
