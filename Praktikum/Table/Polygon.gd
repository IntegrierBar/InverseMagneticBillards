extends Node2D

onready var polygon : PoolVector2Array = []
var closed : bool = false
var color : Color = Color.white

func _ready():
	#polygon.append_array([Vector2(0, 100), Vector2(-100, 0), Vector2(0, -100), Vector2(100,0)])
	polygon.append_array([Vector2(100, 0), Vector2(0, -100), Vector2(-100, 0), Vector2(0, 100)])
	#close_polygon()

func _draw():
	var poly = polygon
	poly.append(polygon[0])
	draw_polyline(poly, color, 0.5)
#	for i in range(1 , polygon.size()):
#		draw_line(polygon[i-1], polygon[i], Color.antiquewhite , 2.0)
#	draw_line(polygon[polygon.size() - 1] , polygon[0], Color.antiquewhite , 2.0)

func close_polygon():
	polygon.append(polygon[0])
	closed = true
