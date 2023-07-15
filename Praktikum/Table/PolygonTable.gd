extends Table

onready var polygon = $Polygon

var center = Vector2.ZERO
var eps : float = 1e-0

func _ready():
	#print(polygon.polygon)
	pass
	
func _draw():
	draw_circle(center, radius, Color.brown)

# intersection with circle
func intersect_outer(start_point:Vector2, direction:Vector2) -> Array:
	center = circle_center(start_point, direction)
	update()
	var n : int = polygon.polygon.size()
	# use Geometry class for fast computation if polygon side intersects circle
	# Problem: this only returns one intersections, but we could have two if cricle is small
	# so save how often we intersect, and if we only intersect ones, do manual calculation
	var intersection_index : Array = []
	for i in range(n):
		var intersect = Geometry.segment_intersects_circle(polygon.polygon[i], polygon.polygon[(i+1)%n], center, radius)
		if intersect == -1:
			#print(i)
			continue
		intersection_index.append(i)
		var intersection_point = polygon.polygon[i] + intersect*(polygon.polygon[(i+1)%n]-polygon.polygon[i])
		if (intersection_point - start_point).length_squared() > eps:
			#print("trivial found")
			return [intersection_point, (center - intersection_point).rotated(PI/2), center]
	
	if intersection_index.size() != 1:
		print("error")
		print(intersection_index)
		return [Vector2.ZERO, Vector2.LEFT]
		# todo Error auswerfen
	
	var intersection_point = line_circle_intersection(polygon.polygon[intersection_index[0]], polygon.polygon[(intersection_index[0] + 1)%n], center, start_point)
	
	return [intersection_point, (center - intersection_point).rotated(PI/2), center]
	
# intersection with line
func intersect_inner(start_point:Vector2, direction:Vector2) -> Array:
#	print("start = " + str(start_point))
#	print("direction = " + str(direction))
	var line = PoolVector2Array([start_point, start_point + 1000*direction])
	var intersection = Geometry.intersect_polyline_with_polygon_2d(line, polygon.polygon)
	if intersection.size() == 0:
		print("error")
		print("start = " + str(start_point))
		print("direction = " + str(direction))
	if (intersection[0][0] - start_point).length_squared() > eps:
		return [intersection[0], direction]
	return [intersection[0][1], direction]

# calculation from https://mathworld.wolfram.com/Circle-LineIntersection.html
func line_circle_intersection(a:Vector2, b: Vector2, center: Vector2, start_point: Vector2) -> Vector2:
#	print("line intersection by hand")
	var d : Vector2 = b-a
	var d_r_squared : float = d.length_squared()
	var D : float = (a-center).cross(b-center)
	var intersection : Vector2 = Vector2(D*d.y + sign(d.y)*d.x*sqrt(radius*radius*d_r_squared - D*D), -D*d.x + abs(d.y)*sqrt(radius*radius*d_r_squared - D*D))/d_r_squared + center
	if (intersection - start_point).length_squared() > eps:
		return intersection
	return Vector2(D*d.y - sign(d.y)*d.x*sqrt(radius*radius*d_r_squared - D*D), -D*d.x - abs(d.y)*sqrt(radius*radius*d_r_squared - D*D))/d_r_squared + center

