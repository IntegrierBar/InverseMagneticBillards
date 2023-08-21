extends ScrollContainer


func _ready():
	self.set_enable_h_scroll(false) 
	# allow only vertical scrolling, horizontally the text just disappears if the box is too small

