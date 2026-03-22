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
	if ammo > 0:
		var neon := Color(0.0, 1.0, 1.0, 0.9)
		var fill := Color(0.0, 0.08, 0.12)
		# Glow da base
		draw_circle(Vector2(0, 5), 30.0, Color(0.0, 1.0, 1.0, 0.05))
		# Base — trapezio
		var base := PackedVector2Array([
			Vector2(-28, 25), Vector2(-20, 10), Vector2(20, 10), Vector2(28, 25),
		])
		draw_polygon(base, PackedColorArray([fill, fill, fill, fill]))
		for i in base.size():
			draw_line(base[i], base[(i + 1) % base.size()], neon, 1.5, true)
		# Torreta — hexagono
		var turret := PackedVector2Array([
			Vector2(-14, 10), Vector2(-16, 0), Vector2(-10, -8),
			Vector2(10, -8), Vector2(16, 0), Vector2(14, 10),
		])
		draw_polygon(turret, PackedColorArray([fill, fill, fill, fill, fill, fill]))
		for i in turret.size():
			draw_line(turret[i], turret[(i + 1) % turret.size()], neon, 2.0, true)
		# Cano — retangulo fino pra cima
		draw_rect(Rect2(-3, -30, 6, 22), fill)
		draw_rect(Rect2(-3, -30, 6, 22), neon, false, 1.5)
		# Ponta do cano
		draw_circle(Vector2(0, -30), 2.0, Color(0.0, 1.0, 1.0, 0.7))
		# Indicador de municao — linhas internas
		var ammo_ratio := float(ammo) / max_ammo
		var bar_h := 10.0 * ammo_ratio
		draw_rect(Rect2(-5, 4 - bar_h, 10, bar_h), Color(0.0, 1.0, 1.0, 0.25))
	else:
		var dim := Color(0.0, 0.3, 0.4, 0.3)
		var fill := Color(0.02, 0.03, 0.05)
		# Base dim
		var base := PackedVector2Array([
			Vector2(-28, 25), Vector2(-20, 10), Vector2(20, 10), Vector2(28, 25),
		])
		draw_polygon(base, PackedColorArray([fill, fill, fill, fill]))
		for i in base.size():
			draw_line(base[i], base[(i + 1) % base.size()], dim, 1.0, true)
		# Torreta dim
		var turret := PackedVector2Array([
			Vector2(-14, 10), Vector2(-16, 0), Vector2(-10, -8),
			Vector2(10, -8), Vector2(16, 0), Vector2(14, 10),
		])
		draw_polygon(turret, PackedColorArray([fill, fill, fill, fill, fill, fill]))
		for i in turret.size():
			draw_line(turret[i], turret[(i + 1) % turret.size()], dim, 1.5, true)
		# Cano dim
		draw_rect(Rect2(-3, -30, 6, 22), fill)
		draw_rect(Rect2(-3, -30, 6, 22), dim, false, 1.0)

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
