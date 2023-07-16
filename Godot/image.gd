extends Sprite


func _ready():
	var c = Color(10, 12, 13)
	print("color")
	print(c.r)
	print(c.g)
	print(c.b)
	
	var test = []
	test.append(Vector2(0, 0.0))
	test.append(Vector2(0.1, 0.1))
	test.append(Vector2(0, 10))
	store_polygon_as_image(test)


func store_polygon_as_image(polygon: Array):
	# pass the size to shader
	material.set_shader_param("n", polygon.size())
	# convert array to imageTexture and send it to shader
	var img = Image.new()
	img.create(polygon.size(), 1, false, Image.FORMAT_RGF)
	img.lock()
	for i in range(polygon.size()):
		var c = Color(polygon[i].x, polygon[i].y, 0)
		img.set_pixel(i, 0, c)
	img.unlock()
	
	var texture = ImageTexture.new()
	texture.create_from_image(img, 0)
	material.set_shader_param("polygon", texture)
	
