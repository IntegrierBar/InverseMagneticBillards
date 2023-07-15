extends Camera2D


# Lower cap for the `_zoom_level`.
export var min_zoom := 0.00005
# Upper cap for the `_zoom_level`.
export var max_zoom := 1000.0
# Controls how much we increase or decrease the `_zoom_level` on every turn of the scroll wheel.
export var zoom_speed := 0.1
# Duration of the zoom's tween animation.
export var zoom_duration := 0.2

export var zoom_factor : float = 1.5

var _zoom_level : float = 1.0



func _set_zoom_level(value: float) -> void:
	_zoom_level = clamp(value, min_zoom, max_zoom)
	var tween = create_tween()
	tween.tween_property(self, "zoom", Vector2(_zoom_level, _zoom_level), zoom_duration)


func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		_set_zoom_level(_zoom_level/zoom_factor)
	if event.is_action_pressed("zoom_out"):
		_set_zoom_level(_zoom_level*zoom_factor)
		
