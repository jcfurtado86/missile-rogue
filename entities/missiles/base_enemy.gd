class_name BaseEnemy
extends Area2D

@warning_ignore("unused_signal")
signal destroyed(enemy: Area2D, auto_turret: bool)

@export var speed := 200.0

var target_position := Vector2.ZERO
var mirror_chance := 0.0
var reflected := false

const OOB_MARGIN := 50.0
var screen_width: float

var trail: Array[Vector2] = []

const DEATH_PARTICLES_SCENE = preload("res://entities/missiles/death_particles.tscn")
const MUSHROOM_CLOUD_SCENE = preload("res://entities/missiles/mushroom_cloud.tscn")

# Subclasses devem sobrescrever esses metodos
func _get_trail_length() -> int: return 25
func _get_trail_min_dist() -> float: return 18.0
func _get_missile_radius() -> float: return 10.0
func _get_color_key() -> String: return "enemy_basic"
func _get_ascii_char() -> String: return "V"
func _get_trail_alpha() -> float: return 0.4

func _get_base_color() -> Color:
	return Themes.c(_get_color_key())

func _ready() -> void:
	screen_width = get_viewport().get_visible_rect().size.x

# --- Trail ---

func _update_trail() -> bool:
	var min_dist := _get_trail_min_dist()
	var max_len := _get_trail_length()
	if trail.is_empty() or global_position.distance_to(trail[0]) >= min_dist:
		trail.push_front(global_position)
		if trail.size() > max_len:
			trail.resize(max_len)
		return true
	return false

func _draw_trail() -> void:
	if trail.size() < 2:
		return
	var color := _get_base_color()
	var alpha := _get_trail_alpha()
	var radius := _get_missile_radius()
	var pts := PackedVector2Array()
	var colors := PackedColorArray()
	pts.append(Vector2.ZERO)
	colors.append(Color(color.r, color.g, color.b, alpha))
	var inv_transform := global_transform.affine_inverse()
	for i in trail.size():
		var t := 1.0 - float(i) / trail.size()
		pts.append(inv_transform * trail[i])
		colors.append(Color(color.r, color.g, color.b, alpha * t))
	draw_polyline_colors(pts, colors, radius * 2.0)
	draw_polyline_colors(pts, colors, radius * 0.5)

func _draw_ascii_trail_and_char() -> void:
	var font := ThemeDB.fallback_font
	var color := _get_base_color()
	var inv := global_transform.affine_inverse()
	for i in trail.size():
		var t := 1.0 - float(i) / trail.size()
		var local_pos: Vector2 = inv * trail[i]
		var c := Color(color.r, color.g, color.b, 0.4 * t)
		draw_string(font, local_pos - Vector2(4, -4), ".", HORIZONTAL_ALIGNMENT_CENTER, -1, 28, c)
	draw_string(font, Vector2(-7, 10), _get_ascii_char(), HORIZONTAL_ALIGNMENT_CENTER, -1, 28, color)

# --- Particles ---

func _spawn_death_particles() -> void:
	var dp = DEATH_PARTICLES_SCENE.instantiate()
	dp.position = global_position
	dp.color = _get_base_color()
	get_parent().add_child(dp)

func _spawn_mushroom_cloud() -> void:
	SoundManager.ground_hit()
	var mc = MUSHROOM_CLOUD_SCENE.instantiate()
	mc.position = global_position
	mc.color = _get_base_color()
	get_parent().add_child(mc)

# --- Reflect ---

func _reflect() -> void:
	var angle := randf_range(-PI * 0.8, -PI * 0.2)
	target_position = global_position + Vector2.from_angle(angle) * 800.0
	speed *= 1.5
	remove_from_group("enemy")
	add_to_group("reflected")
	reflected = true
	trail.clear()

# --- Bounds ---

func _is_oob() -> bool:
	return global_position.y < -OOB_MARGIN or global_position.x < -OOB_MARGIN or global_position.x > screen_width + OOB_MARGIN

func _is_reflected_oob() -> bool:
	return global_position.distance_to(target_position) < 10.0 or _is_oob()

# --- Collision ---

func _handle_city_collision(area: Area2D) -> void:
	if is_in_group("enemy") and mirror_chance > 0.0 and randf() < mirror_chance:
		_reflect()
		return
	if area.has_method("take_hit"):
		area.call_deferred("take_hit")
	call_deferred("_spawn_mushroom_cloud")
	call_deferred("queue_free")
