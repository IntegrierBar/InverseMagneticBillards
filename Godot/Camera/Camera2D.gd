extends Camera2D

signal zoom_changed(z)

var mouse_inside: bool = false
export(NodePath) var ViewPort


# Lower cap for the `_zoom_level`.
export var min_zoom := 0.00005
# Upper cap for the `_zoom_level`.
export var max_zoom := 1000.0
# Controls how much we increase or decrease the `_zoom_level` on every turn of the scroll wheel.
export var zoom_speed := 0.1
# Duration of the zoom's tween animation.
export var zoom_duration := 0.2
export var zoom_factor : float = 1.5
export var _zoom_level : float = 0.1 # initial zoom
export var camera_speed: float = 10.0


func _ready():
	zoom = Vector2(_zoom_level, _zoom_level)

func _process(delta):
	# move camera with keyboard
	if mouse_inside:
		var direction = Input.get_vector("move_camera_left", "move_camera_right", "move_camera_up", "move_camera_down")
		position += camera_speed*delta*direction

# use a tween to alter the zoom level smoothly
func _set_zoom_level(value: float) -> void:
	_zoom_level = clamp(value, min_zoom, max_zoom)
	var tween = create_tween()
	tween.tween_property(self, "zoom", Vector2(_zoom_level, _zoom_level), zoom_duration)
	emit_signal("zoom_changed", _zoom_level)


func input(event):
	if event.is_action_pressed("zoom_in"):
		_set_zoom_level(_zoom_level/zoom_factor)
	if event.is_action_pressed("zoom_out"):
		_set_zoom_level(_zoom_level*zoom_factor)
	# make camera dragable
	if event is InputEventMouseMotion:
		if event.button_mask == BUTTON_MASK_RIGHT:
			position -= event.relative * zoom

# I dont know why this formula works, but it does. So I will not touch it.
# https://ask.godotengine.org/13740/get-camera-extents-rect-2d
func get_view_rectangle() -> Array:
	var ctrans = get_canvas_transform()
	var min_pos = -ctrans.get_origin() / ctrans.get_scale()
	var view_size = get_viewport_rect().size / ctrans.get_scale()
	var max_pos = min_pos + view_size
	return [min_pos, max_pos]
