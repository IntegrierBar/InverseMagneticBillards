class_name Table extends Node2D

export(float) var field_strength = 1.0

var radius

func _ready():
	radius = 1.0/field_strength

# intersection with circle
func intersect_outer(start_point:Vector2, direction:Vector2) -> Array:
	return [Vector2.ZERO, Vector2.LEFT]

# intersection with line
func intersect_inner(start_point:Vector2, direction:Vector2) -> Array:
	return [Vector2.ZERO, Vector2.LEFT]

func circle_center(start_point:Vector2, direction:Vector2) -> Vector2:
	return start_point + radius*direction.rotated(-PI/2.0)
