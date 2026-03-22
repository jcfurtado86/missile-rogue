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
		_draw_armed()
	else:
		_draw_empty()

func _draw_armed() -> void:
	var neon := Color(0.0, 1.0, 1.0, 0.9)
	var fill := Color(0.0, 0.08, 0.12)

	# Glow sutil
	draw_circle(Vector2(0, 5), 35.0, Color(0.0, 1.0, 1.0, 0.04))

	# Tampa do silo — retangulo no chao, perspectiva achatada
	# Aberto: as duas metades se afastam
	var silo_w := 32.0
	var silo_h := 16.0  # achatado = chao
	var left_half := PackedVector2Array([
		Vector2(-silo_w, 20 - silo_h), Vector2(-3, 20 - silo_h),
		Vector2(-3, 20), Vector2(-silo_w, 20),
	])
	var right_half := PackedVector2Array([
		Vector2(3, 20 - silo_h), Vector2(silo_w, 20 - silo_h),
		Vector2(silo_w, 20), Vector2(3, 20),
	])
	# Abertura interna — retangulo escuro entre as tampas
	draw_rect(Rect2(-3, 20 - silo_h, 6, silo_h), Color(0.01, 0.01, 0.03))

	# Tampas
	draw_polygon(left_half, PackedColorArray([fill, fill, fill, fill]))
	for i in left_half.size():
		draw_line(left_half[i], left_half[(i + 1) % left_half.size()], neon, 1.5, true)

	draw_polygon(right_half, PackedColorArray([fill, fill, fill, fill]))
	for i in right_half.size():
		draw_line(right_half[i], right_half[(i + 1) % right_half.size()], neon, 1.5, true)

	# Detalhes nas tampas — linhas horizontais internas
	for i in 2:
		var ly := 20.0 - silo_h * 0.33 * (i + 1)
		draw_line(Vector2(-silo_w + 3, ly), Vector2(-5, ly), Color(0.0, 0.8, 1.0, 0.2), 1.0, true)
		draw_line(Vector2(5, ly), Vector2(silo_w - 3, ly), Color(0.0, 0.8, 1.0, 0.2), 1.0, true)

	# Indicador de municao — barra unica cobrindo a base inteira
	var ammo_ratio := float(ammo) / max_ammo
	var bar_y := 22.0
	var bar_h := 10.0
	var bar_x := -silo_w + 2.0
	var bar_full_w_actual := (silo_w - 2.0) * 2.0
	var bar_filled_w_actual := bar_full_w_actual * ammo_ratio
	# Glow atras da barra
	draw_rect(Rect2(bar_x - 2, bar_y - 2, bar_full_w_actual + 4, bar_h + 4), Color(0.0, 1.0, 1.0, 0.06))
	# Fundo da barra
	draw_rect(Rect2(bar_x, bar_y, bar_full_w_actual, bar_h), Color(0.0, 0.2, 0.3, 0.25))
	# Preenchimento
	draw_rect(Rect2(bar_x, bar_y, bar_filled_w_actual, bar_h), Color(0.0, 1.0, 1.0, 0.7))
	# Outline
	draw_rect(Rect2(bar_x, bar_y, bar_full_w_actual, bar_h), Color(0.0, 1.0, 1.0, 0.6), false, 2.0)

func _draw_empty() -> void:
	var dim := Color(0.0, 0.3, 0.4, 0.3)
	var fill := Color(0.02, 0.03, 0.05)

	# Tampa fechada — retangulo unico no chao
	var silo_w := 32.0
	var silo_h := 16.0
	var silo := PackedVector2Array([
		Vector2(-silo_w, 20 - silo_h), Vector2(silo_w, 20 - silo_h),
		Vector2(silo_w, 20), Vector2(-silo_w, 20),
	])
	draw_polygon(silo, PackedColorArray([fill, fill, fill, fill]))
	for i in silo.size():
		draw_line(silo[i], silo[(i + 1) % silo.size()], dim, 1.0, true)

	# Linha central — emenda das tampas
	draw_line(Vector2(0, 20 - silo_h), Vector2(0, 20), dim, 1.0, true)

	# Detalhes dim
	for i in 2:
		var ly := 20.0 - silo_h * 0.33 * (i + 1)
		draw_line(Vector2(-silo_w + 3, ly), Vector2(-2, ly), Color(0.0, 0.3, 0.4, 0.1), 1.0, true)
		draw_line(Vector2(2, ly), Vector2(silo_w - 3, ly), Color(0.0, 0.3, 0.4, 0.1), 1.0, true)

	# Barra de municao vazia
	var bar_x := -silo_w + 2.0
	var bar_full_w := (silo_w - 2.0) * 2.0
	var bar_y := 22.0
	var bar_h := 10.0
	draw_rect(Rect2(bar_x, bar_y, bar_full_w, bar_h), Color(0.0, 0.2, 0.3, 0.15))
	draw_rect(Rect2(bar_x, bar_y, bar_full_w, bar_h), Color(0.0, 0.3, 0.4, 0.25), false, 1.5)

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
