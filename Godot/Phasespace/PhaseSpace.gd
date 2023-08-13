extends TextureRect


#var bounding_box_color = Color.red

var trajectories_to_draw: Array = []
var trajectories_colors: Array = []
var trajectory_count = 0

var phase_space: Image
var sizex = rect_size.x
var sizey = rect_size.y

func _ready():
	
	phase_space = Image.new()
	phase_space.create(sizex, sizey, false, Image.FORMAT_RGB8)
	phase_space.fill(Color.black)
	
	var background = ImageTexture.new()
	background.create_from_image(phase_space)
	self.texture = background

func reset_image():
	phase_space.fill(Color.black)
	update()

func rescale(points: Array) -> Array:
	var rescaled_points = []
	for p in points:
		rescaled_points.append(Vector2(sizex*p.x, sizey*p.y))
		#print(rescaled_points)
	return rescaled_points

# Array is an array of arrays, each inner array corresponds to a color
func add_points_to_image(points: Array, colors: PoolColorArray):
	phase_space.lock()
	for i in range(colors.size()):
		for point in rescale(points[i]):
			phase_space.set_pixelv(point, colors[i])
	phase_space.unlock()
	# set image
	var background = ImageTexture.new()
	background.create_from_image(phase_space)
	self.texture = background
	update()


#func _draw():
	# draw bounding box of image FOR NOW SKIP THIS
	#draw_rect(Rect2(rect_position, rect_size), bounding_box_color, false)
	
	# CONSIDER DOING EVERYTHING WITH TEXTURES might be faster in the long run
	#print("draw3ing")
#	for i in range(trajectory_count):
#		var color: Color = trajectories_colors[i]
#		#draw_polyline(trajectories_to_draw[i], color)
#		for point in trajectories_to_draw[i]:
#			#print(trajectories_to_draw)
#			#print(point)
#			#draw_circle(point, 10, color)
#			draw_primitive(PoolVector2Array([point]), PoolColorArray([color]), PoolVector2Array())

#func add_trajectory(color: Color):
##	if trajectory_count < 1:
##		trajectories_to_draw = [[]]
##		trajectories_colors = [color]
##	else:
#	trajectories_to_draw.append([])
#	trajectories_colors.append(color)
#	trajectory_count += 1

#func add_points_to_trajectory(index: int, points: Array):
#	if index >= trajectory_count:
#		print("wrong index")
#		return
#	# TODO RESCALING!!!!!!!!!!!!
#	trajectories_to_draw[index].append_array(rescale(points))
#	#print(trajectories_to_draw[index])
#	update()

#func reset_trajectories():
#	trajectories_to_draw = []
#	for i in range(trajectory_count):
#		trajectories_to_draw.append([])
#	update()

