extends TextureRect


#var bounding_box_color = Color.red

var trajectories_to_draw: Array = []
var trajectories_colors: Array = []
var trajectory_count = 0

func _ready():
	
	var black_background = Image.new()
	black_background.create(rect_size.x, rect_size.y, false, Image.FORMAT_RGB8)
	black_background.fill(Color.black)
	
	var background = ImageTexture.new()
	background.create_from_image(black_background)
	self.texture = background


func _draw():
	# draw bounding box of image FOR NOW SKIP THIS
	#draw_rect(Rect2(rect_position, rect_size), bounding_box_color, false)
	
	# CONSIDER DOING EVERYTHING WITH TEXTURES might be faster in the long run
	#print("draw3ing")
	for i in range(trajectory_count):
		var color: Color = trajectories_colors[i]
		#draw_polyline(trajectories_to_draw[i], color)
		for point in trajectories_to_draw[i]:
			#print(trajectories_to_draw)
			#print(point)
			#draw_circle(point, 10, color)
			draw_primitive(PoolVector2Array([point]), PoolColorArray([color]), PoolVector2Array())

func add_trajectory(color: Color):
#	if trajectory_count < 1:
#		trajectories_to_draw = [[]]
#		trajectories_colors = [color]
#	else:
	trajectories_to_draw.append([])
	trajectories_colors.append(color)
	trajectory_count += 1

func add_points_to_trajectory(index: int, points: Array):
	if index >= trajectory_count:
		print("wrong index")
		return
	# TODO RESCALING!!!!!!!!!!!!
	trajectories_to_draw[index].append_array(rescale(points))
	#print(trajectories_to_draw[index])
	update()

func rescale(points: Array) -> Array:
	var rescaled_points = []
	for p in points:
		rescaled_points.append(Vector2(rect_size.x*p.x, rect_size.y*p.y))
		#print(rescaled_points)
	return rescaled_points
