extends Sprite

#var radius: float = 1.0;
#
#func _ready():
#	var c = Color(10, 12, 13)
#	print("color")
#	print(c.r)
#	print(c.g)
#	print(c.b)
#
#	var test = []
#	var length = []
#	test.append(Vector2(0.0, 0.0))
#	length.append(0.0)
#	test.append(Vector2(10.0, 0.0))
#	length.append(10.0)
#	test.append(Vector2(0.0, 10.0))
#	length.append(10.0+sqrt(200.0))
#	test.append(Vector2(0.0, 0.0))
#	length.append(10.0+sqrt(200.0) + 10.0)
#	store_polygon_as_image(test, length)

func _ready():
	material.set_shader_param("iterations", 1)
	material.set_shader_param("forwards", true)
	material.set_shader_param("radius", 1.0)


func store_polygon_as_image(polygon: Array, polygonLength: Array):
	# pass the size to 
	#print(polygon)
	#print(polygonLength)
	material.set_shader_param("n", polygon.size())
	#material.set_shader_param("radius", radius)
	# convert array to imageTexture and send it to shader
	var img = Image.new()
	var polyLength = Image.new()
	img.create(polygon.size(), 1, false, Image.FORMAT_RGF)
	polyLength.create(polygonLength.size(), 1, false, Image.FORMAT_RGF)
	img.lock()
	polyLength.lock()
	for i in range(polygon.size()):
		var c = Color(polygon[i].x, polygon[i].y, 0)
		img.set_pixel(i, 0, c)
		var l = Color(polygonLength[i], 0, 0)
		polyLength.set_pixel(i, 0, l)
	img.unlock()
	polyLength.unlock()
	
	var texture = ImageTexture.new()
	texture.create_from_image(img, 0)
	var lengthTexture = ImageTexture.new()
	lengthTexture.create_from_image(polyLength, 0)
	material.set_shader_param("polygon", texture)
	material.set_shader_param("polygonLength", lengthTexture)

func _on_Trajectories_close_polygon(p):
	var l_array: Array = [0.0]
	for i in range(p.size()-1):
		l_array.append( l_array[i] + (p[i] - p[i+1]).length())
	store_polygon_as_image(invert_y_array(p), l_array)

func set_radius(r):
	material.set_shader_param("radius", r)

func set_iterations(iter: int):
	material.set_shader_param("iterations", iter)

func invert_y(p: Vector2) -> Vector2:
	return Vector2(p.x, -p.y)

func invert_y_array(a: Array) -> Array:
	var inverted = []
	for p in a:
		inverted.append(invert_y(p))
	return inverted
