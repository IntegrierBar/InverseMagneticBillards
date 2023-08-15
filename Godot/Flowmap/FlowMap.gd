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
