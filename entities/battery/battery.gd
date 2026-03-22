extends Node2D

@export var max_ammo := 10
@export var reload_time := 3.0

var ammo: int
var reloading := false

@onready var reload_timer: Timer = $ReloadTimer

# Silo dimensoes flat
const SILO_W := 32.0
const SILO_H := 16.0
const SILO_CY := 12.0  # centro vertical do silo

# Perspectiva leve
var vanish_lx := 0.0  # vanish point em coords locais
var persp_ratio := 1.0  # ratio topo/base

func _ready() -> void:
	ammo = max_ammo
	var screen := get_viewport().get_visible_rect().size
	var vanish_x := screen.x / 2.0
	var horizon_y := screen.y * 0.9
	vanish_lx = vanish_x - position.x
	# Calcula ratio de perspectiva entre topo e base do silo
	var bot_y := position.y + SILO_CY + SILO_H / 2.0
	var top_y := position.y + SILO_CY - SILO_H / 2.0
	var bot_dist := bot_y - horizon_y
	var top_dist := top_y - horizon_y
	if bot_dist > 0:
		persp_ratio = top_dist / bot_dist
	queue_redraw()

# Transforma ponto local com perspectiva
func _persp(p: Vector2) -> Vector2:
	var t := (p.y - (SILO_CY - SILO_H / 2.0)) / SILO_H
	t = clampf(t, 0.0, 1.0)
	var r := lerpf(persp_ratio, 1.0, t)
	var capped_vanish := clampf(vanish_lx, -100.0, 100.0)
	var px := capped_vanish + (p.x - capped_vanish) * r
	return Vector2(px, p.y)

func _silo_quad() -> PackedVector2Array:
	var top_y := SILO_CY - SILO_H / 2.0
	var bot_y := SILO_CY + SILO_H / 2.0
	return PackedVector2Array([
		_persp(Vector2(-SILO_W, top_y)),
		_persp(Vector2(SILO_W, top_y)),
		_persp(Vector2(SILO_W, bot_y)),
		_persp(Vector2(-SILO_W, bot_y)),
	])

func _draw_quad_outline(quad: PackedVector2Array, color: Color, width: float) -> void:
	for i in quad.size():
		draw_line(quad[i], quad[(i + 1) % quad.size()], color, width, true)

func _draw() -> void:
	if ammo > 0:
		_draw_armed()
	else:
		_draw_empty()

func _draw_armed() -> void:
	var neon := Color(0.0, 1.0, 1.0, 0.9)
	var fill := Color(0.0, 0.08, 0.12)
	var top_y := SILO_CY - SILO_H / 2.0
	var bot_y := SILO_CY + SILO_H / 2.0

	# Glow sutil
	draw_circle(_persp(Vector2(0, SILO_CY)), 35.0, Color(0.0, 1.0, 1.0, 0.04))

	# Abertura central
	var gap := 3.0
	var open_quad := PackedVector2Array([
		_persp(Vector2(-gap, top_y)), _persp(Vector2(gap, top_y)),
		_persp(Vector2(gap, bot_y)), _persp(Vector2(-gap, bot_y)),
	])
	draw_polygon(open_quad, PackedColorArray([Color(0.01, 0.01, 0.03), Color(0.01, 0.01, 0.03), Color(0.01, 0.01, 0.03), Color(0.01, 0.01, 0.03)]))

	# Tampa esquerda
	var left_quad := PackedVector2Array([
		_persp(Vector2(-SILO_W, top_y)), _persp(Vector2(-gap, top_y)),
		_persp(Vector2(-gap, bot_y)), _persp(Vector2(-SILO_W, bot_y)),
	])
	draw_polygon(left_quad, PackedColorArray([fill, fill, fill, fill]))
	_draw_quad_outline(left_quad, neon, 1.5)

	# Tampa direita
	var right_quad := PackedVector2Array([
		_persp(Vector2(gap, top_y)), _persp(Vector2(SILO_W, top_y)),
		_persp(Vector2(SILO_W, bot_y)), _persp(Vector2(gap, bot_y)),
	])
	draw_polygon(right_quad, PackedColorArray([fill, fill, fill, fill]))
	_draw_quad_outline(right_quad, neon, 1.5)

	# Detalhes internos
	for i in 2:
		var ly := lerpf(top_y, bot_y, 0.33 * (i + 1))
		draw_line(_persp(Vector2(-SILO_W + 3, ly)), _persp(Vector2(-gap - 2, ly)), Color(0.0, 0.8, 1.0, 0.2), 1.0, true)
		draw_line(_persp(Vector2(gap + 2, ly)), _persp(Vector2(SILO_W - 3, ly)), Color(0.0, 0.8, 1.0, 0.2), 1.0, true)

	# Barra de municao
	var ammo_ratio := float(ammo) / max_ammo
	var bar_y := bot_y + 2.0
	var bar_h := 10.0
	var bar_tl := _persp(Vector2(-SILO_W + 2, bar_y))
	var bar_tr := _persp(Vector2(SILO_W - 2, bar_y))
	var bar_bl := _persp(Vector2(-SILO_W + 2, bar_y + bar_h))
	var bar_br := _persp(Vector2(SILO_W - 2, bar_y + bar_h))
	# Glow
	draw_polygon(PackedVector2Array([bar_tl + Vector2(-2, -2), bar_tr + Vector2(2, -2), bar_br + Vector2(2, 2), bar_bl + Vector2(-2, 2)]),
		PackedColorArray([Color(0.0, 1.0, 1.0, 0.06), Color(0.0, 1.0, 1.0, 0.06), Color(0.0, 1.0, 1.0, 0.06), Color(0.0, 1.0, 1.0, 0.06)]))
	# Fundo
	draw_polygon(PackedVector2Array([bar_tl, bar_tr, bar_br, bar_bl]),
		PackedColorArray([Color(0.0, 0.2, 0.3, 0.25), Color(0.0, 0.2, 0.3, 0.25), Color(0.0, 0.2, 0.3, 0.25), Color(0.0, 0.2, 0.3, 0.25)]))
	# Preenchimento
	var filled_tr := bar_tl.lerp(bar_tr, ammo_ratio)
	var filled_br := bar_bl.lerp(bar_br, ammo_ratio)
	draw_polygon(PackedVector2Array([bar_tl, filled_tr, filled_br, bar_bl]),
		PackedColorArray([Color(0.0, 1.0, 1.0, 0.7), Color(0.0, 1.0, 1.0, 0.7), Color(0.0, 1.0, 1.0, 0.7), Color(0.0, 1.0, 1.0, 0.7)]))
	# Outline
	_draw_quad_outline(PackedVector2Array([bar_tl, bar_tr, bar_br, bar_bl]), Color(0.0, 1.0, 1.0, 0.6), 2.0)

func _draw_empty() -> void:
	var dim := Color(0.0, 0.3, 0.4, 0.3)
	var fill := Color(0.02, 0.03, 0.05)
	var top_y := SILO_CY - SILO_H / 2.0
	var bot_y := SILO_CY + SILO_H / 2.0

	# Tampa fechada
	var quad := _silo_quad()
	draw_polygon(quad, PackedColorArray([fill, fill, fill, fill]))
	_draw_quad_outline(quad, dim, 1.0)

	# Linha central
	draw_line(_persp(Vector2(0, top_y)), _persp(Vector2(0, bot_y)), dim, 1.0, true)

	# Detalhes dim
	for i in 2:
		var ly := lerpf(top_y, bot_y, 0.33 * (i + 1))
		draw_line(_persp(Vector2(-SILO_W + 3, ly)), _persp(Vector2(-2, ly)), Color(0.0, 0.3, 0.4, 0.1), 1.0, true)
		draw_line(_persp(Vector2(2, ly)), _persp(Vector2(SILO_W - 3, ly)), Color(0.0, 0.3, 0.4, 0.1), 1.0, true)

	# Barra vazia
	var bar_y := bot_y + 2.0
	var bar_h := 10.0
	var bar_tl := _persp(Vector2(-SILO_W + 2, bar_y))
	var bar_tr := _persp(Vector2(SILO_W - 2, bar_y))
	var bar_bl := _persp(Vector2(-SILO_W + 2, bar_y + bar_h))
	var bar_br := _persp(Vector2(SILO_W - 2, bar_y + bar_h))
	draw_polygon(PackedVector2Array([bar_tl, bar_tr, bar_br, bar_bl]),
		PackedColorArray([Color(0.0, 0.2, 0.3, 0.15), Color(0.0, 0.2, 0.3, 0.15), Color(0.0, 0.2, 0.3, 0.15), Color(0.0, 0.2, 0.3, 0.15)]))
	_draw_quad_outline(PackedVector2Array([bar_tl, bar_tr, bar_br, bar_bl]), Color(0.0, 0.3, 0.4, 0.25), 1.5)

# ============================================================
# INTERFACE PUBLICA
# ============================================================

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
