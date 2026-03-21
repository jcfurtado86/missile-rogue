class_name MissileData
extends RefCounted

var speed: float
var explosion_radius: float
var explosion_duration: float

func _init(p_speed: float = 1200.0, p_radius: float = 60.0, p_duration: float = 0.15) -> void:
	speed = p_speed
	explosion_radius = p_radius
	explosion_duration = p_duration

func calculate_step(position: Vector2, target: Vector2, delta: float) -> Vector2:
	var direction = position.direction_to(target)
	var step_size = speed * delta
	var distance = position.distance_to(target)
	if step_size >= distance:
		return target
	return position + direction * step_size

func has_arrived(position: Vector2, target: Vector2, step_size: float) -> bool:
	return position.distance_to(target) <= step_size
