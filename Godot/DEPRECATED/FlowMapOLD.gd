extends TextureRect


onready var trajectories = $Trajectory

var flow_map: Image
var image : ImageTexture = null
onready var sizex = rect_size.x	# TODO be smarter about this. consider adding custom size
onready var sizey = rect_size.y

func _ready():
	trajectories.hide()
	flow_map = Image.new()
	flow_map.create(sizex, sizey, false, Image.FORMAT_RGB8)
	flow_map.fill(Color.black)
	
	image = ImageTexture.new()
	image.create_from_image(flow_map)
	self.texture = image

# Godot uses negative y-axis. Nedd to invert y to get correct coords
func invert_y(p: Vector2) -> Vector2:
	return Vector2(p.x, -p.y)

func invert_y_array(a: Array) -> Array:
	var inverted = []
	for p in a:
		inverted.append(invert_y(p))
	return inverted

func set_polygon_map(vertices: Array):
	var l_array: Array = [0.0]
	for i in range(vertices.size()-1):
		l_array.append( l_array[i] + (vertices[i] - vertices[i+1]).length())
	$"../../FlowMap".store_polygon_as_image(invert_y_array(vertices), l_array)

# this function gets an array of Vector2 that are the vertices of the polygon
# IMPORTANT: last vertex != first index, we close the polygon ourself
# gets called from main Trajectories node
func set_polygon(vertices: Array):
	#print("get called")
	trajectories.clear_trajectories()
	trajectories.clear_polygon()
	#print("clearing works")
	for v in vertices:
		#print(v)
		trajectories.add_polygon_vertex(invert_y(v))
	trajectories.close_polygon()
	
	#print("adding poly works")
	fill_flow_map()
	#print(trajectories.get_trajectories())
	iterate_once()
	vertices.append(vertices[0])
	set_polygon_map(vertices)

# for now this will launch a trajectory for each pixel
# ONLY CALL AFTER POLYGON WAS CREATED AND CLOSED!
func fill_flow_map():
	for i in range(1, sizex):
		for j in range(1, sizey):
			var x_pos = float(i)/sizex
			#print(x_pos)
			var c: Color = Color(x_pos, 1-x_pos, 0)		# TODO dynamically change
			trajectories.add_trajectory_phasespace(Vector2(float(i)/sizex, float(j)/sizey), c)

# iterates all trajectories once
func iterate_once():
	var colors = trajectories.get_trajectory_colors()
	#print(colors)
	#print(trajectories.get_trajectories())
	var points = trajectories.iterate_batch(1)	# TODO ERROR HERE probably
	flow_map.fill(Color.black)
	flow_map.lock()
	for i in range(colors.size()):
		for point in rescale(points[i]):
			#print(point)
			flow_map.set_pixelv(point, colors[i])
		pass
	flow_map.unlock()
	# set image
	image.set_data(flow_map)
	self.texture = image
	update()

func rescale(points: Array) -> Array:
	var rescaled_points = []
	for p in points:
		rescaled_points.append(Vector2(sizex*p.x, sizey*p.y))
		#print(rescaled_points)
	return rescaled_points


func _on_Trajectories_close_polygon(p):
	p.append(p[0])
	set_polygon_map(p)
	#set_polygon(p)
