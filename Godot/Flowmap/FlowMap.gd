extends TextureRect


onready var trajectories = $Trajectory

var flow_map: Image
var image : ImageTexture = null
onready var sizex = rect_size.x	# TODO be smarter about this. consider adding custom size
onready var sizey = rect_size.y

func _ready():
	flow_map = Image.new()
	flow_map.create(sizex, sizey, false, Image.FORMAT_RGB8)
	flow_map.fill(Color.black)
	
	image = ImageTexture.new()
	image.create_from_image(flow_map)
	self.texture = image

# this function gets an array of Vector2 that are the vertices of the polygon
# IMPORTANT: last vertex != first index, we close the polygon ourself
# gets called from main Trajectories node
func set_polygon(vertices: Array):
	trajectories.clear_polygon()
	for v in vertices:
		trajectories.add_polygon_vertex(v)
	trajectories.close_polygon()
	fill_flow_map()
	iterate_once()

# for now this will launch a trajectory for each pixel
# ONLY CALL AFTER POLYGON WAS CREATED AND CLOSED!
func fill_flow_map():
	trajectories.clear_trajectories()
	for i in range(sizex):
		for j in range(sizey):
			var c: Color = Color.red		# TODO dynamically change
			trajectories.add_trajectory_phasespace(Vector2(float(i)/sizex, float(j)/sizey), c)

# iterates all trajectories once
func iterate_once():
	var points = trajectories.iterate_batch(1)
	var colors = trajectories.get_trajectory_colors()
	flow_map.lock()
	for i in range(colors.size()):
		for point in rescale(points[i]):
			#print(point)
			flow_map.set_pixelv(point, colors[i])
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