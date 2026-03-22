extends Node2D

@export var max_ammo := 10
@export var reload_time := 3.0

var ammo: int
var reloading := false

@onready var reload_timer: Timer = $ReloadTimer

func _ready() -> void:
	ammo = max_ammo
	queue_redraw()

func _draw() -> void:
	var points := PackedVector2Array([Vector2(0, -35), Vector2(-25, 25), Vector2(25, 25)])
	if ammo > 0:
		# Glow exterior
		var glow_points := PackedVector2Array([Vector2(0, -42), Vector2(-30, 30), Vector2(30, 30)])
		var glow_color := Color(0.0, 1.0, 1.0, 0.1)
		draw_polygon(glow_points, [glow_color, glow_color, glow_color])
		# Corpo neon cyan
		var fill := Color(0.0, 0.15, 0.2)
		draw_polygon(points, [fill, fill, fill])
		# Outline neon
		var neon := Color(0.0, 1.0, 1.0, 0.9)
		draw_line(points[0], points[1], neon, 2.0, true)
		draw_line(points[1], points[2], neon, 2.0, true)
		draw_line(points[2], points[0], neon, 2.0, true)
	else:
		# Descarregada — outline escuro
		var dim := Color(0.0, 0.3, 0.4, 0.4)
		var fill := Color(0.02, 0.05, 0.08)
		draw_polygon(points, [fill, fill, fill])
		draw_line(points[0], points[1], dim, 1.5, true)
		draw_line(points[1], points[2], dim, 1.5, true)
		draw_line(points[2], points[0], dim, 1.5, true)

func can_fire() -> bool:
	return ammo > 0

func fire(target: Vector2, missile_scene: PackedScene, speed_mult: float = 1.0, radius_mult: float = 1.0) -> void:
	if ammo <= 0:
		return
	ammo -= 1
	var missile = missile_scene.instantiate()
	missile.global_position = global_position
	missile.target = target
	missile.speed *= speed_mult
	missile.explosion_radius *= radius_mult
	get_tree().current_scene.add_child(missile)

	queue_redraw()
	if ammo <= 0 and not reloading:
		_start_reload()

func _start_reload() -> void:
	reloading = true
	reload_timer.start(reload_time)

func _on_reload_timer_timeout() -> void:
	ammo = max_ammo
	reloading = false
	queue_redraw()
