extends Node2D

@export var max_magazines := 2
@export var magazine_size := 3
@export var reload_time := 3.0
@export var ammo_regen_rate := 0.0  # pentes/s regenerados

var magazines: int
var magazine_ammo: int
var reloading := false
var regen_accumulator := 0.0
var empty_pulse_time := 0.0

@onready var reload_timer: Timer = $ReloadTimer

# Silo dimensoes flat
const SILO_W := 32.0
const SILO_H := 16.0
const SILO_CY := 12.0  # centro vertical do silo

# Perspectiva leve
var vanish_lx := 0.0  # vanish point em coords locais
var persp_ratio := 1.0  # ratio topo/base

func _process(delta: float) -> void:
	if reloading:
		queue_redraw()
	# Pulso visual quando vazio
	if magazine_ammo <= 0 and magazines <= 0 and not reloading:
		empty_pulse_time += delta
		queue_redraw()
	else:
		empty_pulse_time = 0.0
	# Ammo regen passivo — regenera tiros no pente atual
	if ammo_regen_rate > 0.0 and magazine_ammo < magazine_size and not reloading:
		regen_accumulator += ammo_regen_rate * delta
		if regen_accumulator >= 1.0:
			regen_accumulator -= 1.0
			magazine_ammo += 1
			queue_redraw()

func _ready() -> void:
	magazines = max_magazines - 1  # 1 pente ja esta carregado na arma
	magazine_ammo = magazine_size
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
	var capped_vanish := clampf(vanish_lx, -110.0, 110.0)
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
	if magazine_ammo > 0 or magazines > 0 or reloading:
		_draw_armed()
	else:
		_draw_empty()

func _draw_ascii_armed() -> void:
	var font := ThemeDB.fallback_font
	var color := Themes.c("battery_neon")
	var text := "[=]"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
	draw_string(font, Vector2(-text_size.x / 2.0, 12), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, color)
	var dots := ".".repeat(magazine_ammo)
	var dots_size := font.get_string_size(dots, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	draw_string(font, Vector2(-dots_size.x / 2.0, 12 + 22), dots, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, color)

func _draw_ascii_empty() -> void:
	var font := ThemeDB.fallback_font
	var color := Themes.c("battery_neon", 0.3)
	var text := "[x]"
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
	draw_string(font, Vector2(-text_size.x / 2.0, 12), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, color)

func _draw_armed() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_armed()
		return
	var neon := Themes.c("battery_neon", 0.9)
	var fill := Themes.c("battery_fill")
	var top_y := SILO_CY - SILO_H / 2.0
	var bot_y := SILO_CY + SILO_H / 2.0

	# Glow sutil
	draw_circle(_persp(Vector2(0, SILO_CY)), 35.0, Themes.glow("battery_neon", 0.04))

	# Abertura central
	var gap := 3.0
	var open_quad := PackedVector2Array([
		_persp(Vector2(-gap, top_y)), _persp(Vector2(gap, top_y)),
		_persp(Vector2(gap, bot_y)), _persp(Vector2(-gap, bot_y)),
	])
	var open_fill := Themes.c("fill_entity")
	draw_polygon(open_quad, PackedColorArray([open_fill, open_fill, open_fill, open_fill]))

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
		draw_line(_persp(Vector2(-SILO_W + 3, ly)), _persp(Vector2(-gap - 2, ly)), Themes.c("battery_neon", 0.2), 1.0, true)
		draw_line(_persp(Vector2(gap + 2, ly)), _persp(Vector2(SILO_W - 3, ly)), Themes.c("battery_neon", 0.2), 1.0, true)

	# Barra de municao (pente atual)
	var bar_y := bot_y + 6.0
	var bar_h := 10.0
	var bar_tl := _persp(Vector2(-SILO_W + 2, bar_y))
	var bar_tr := _persp(Vector2(SILO_W - 2, bar_y))
	var bar_bl := _persp(Vector2(-SILO_W + 2, bar_y + bar_h))
	var bar_br := _persp(Vector2(SILO_W - 2, bar_y + bar_h))
	# Glow
	draw_polygon(PackedVector2Array([bar_tl + Vector2(-2, -2), bar_tr + Vector2(2, -2), bar_br + Vector2(2, 2), bar_bl + Vector2(-2, 2)]),
		PackedColorArray([Themes.glow("battery_neon", 0.06), Themes.glow("battery_neon", 0.06), Themes.glow("battery_neon", 0.06), Themes.glow("battery_neon", 0.06)]))
	# Fundo
	draw_polygon(PackedVector2Array([bar_tl, bar_tr, bar_br, bar_bl]),
		PackedColorArray([Themes.c("battery_neon", 0.25), Themes.c("battery_neon", 0.25), Themes.c("battery_neon", 0.25), Themes.c("battery_neon", 0.25)]))

	if reloading:
		# Progresso de recarga — barra laranja enchendo
		var reload_progress := 1.0 - (reload_timer.time_left / reload_time)
		var reload_col := Color(1.0, 0.6, 0.0, 0.6)
		var reload_tr := bar_tl.lerp(bar_tr, reload_progress)
		var reload_br := bar_bl.lerp(bar_br, reload_progress)
		draw_polygon(PackedVector2Array([bar_tl, reload_tr, reload_br, bar_bl]),
			PackedColorArray([reload_col, reload_col, reload_col, reload_col]))
	else:
		# Preenchimento — cor varia de vermelho > amarelo > verde
		var ammo_ratio := float(magazine_ammo) / magazine_size
		var bar_color: Color
		if ammo_ratio < 0.5:
			var t := ammo_ratio * 2.0
			bar_color = Color(1.0, t * 0.9, 0.0, 0.8)
		else:
			var t := (ammo_ratio - 0.5) * 2.0
			bar_color = Color(1.0 - t, 0.9 + t * 0.1, 0.0, 0.8)
		var filled_tr := bar_tl.lerp(bar_tr, ammo_ratio)
		var filled_br := bar_bl.lerp(bar_br, ammo_ratio)
		draw_polygon(PackedVector2Array([bar_tl, filled_tr, filled_br, bar_bl]),
			PackedColorArray([bar_color, bar_color, bar_color, bar_color]))

	# Outline
	_draw_quad_outline(PackedVector2Array([bar_tl, bar_tr, bar_br, bar_bl]), Themes.c("battery_neon", 0.6), 2.0)

	# Indicador de pentes restantes
	var mag_y := bar_y + bar_h + 4.0
	var mag_w := (SILO_W * 2.0 - 4.0) / max_magazines
	for mi in max_magazines:
		var mx := -SILO_W + 2.0 + mi * mag_w + 1.0
		var mw := mag_w - 2.0
		var mtl := _persp(Vector2(mx, mag_y))
		var mtr := _persp(Vector2(mx + mw, mag_y))
		var mbl := _persp(Vector2(mx, mag_y + 4.0))
		var mbr := _persp(Vector2(mx + mw, mag_y + 4.0))
		var mag_col: Color
		# Total de pentes disponiveis = reserva + pente ativo (se tem municao ou esta recarregando)
		var active_mags := magazines + (1 if (magazine_ammo > 0 or reloading) else 0)
		if mi < active_mags:
			mag_col = Themes.c("battery_neon", 0.5)
		else:
			mag_col = Themes.c("battery_neon", 0.2)
		draw_polygon(PackedVector2Array([mtl, mtr, mbr, mbl]),
			PackedColorArray([mag_col, mag_col, mag_col, mag_col]))

func _draw_empty() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_empty()
		return
	var dim := Themes.c("battery_neon", 0.3)
	var fill := Themes.c("fill_entity")
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
		draw_line(_persp(Vector2(-SILO_W + 3, ly)), _persp(Vector2(-2, ly)), Themes.c("battery_neon", 0.1), 1.0, true)
		draw_line(_persp(Vector2(2, ly)), _persp(Vector2(SILO_W - 3, ly)), Themes.c("battery_neon", 0.1), 1.0, true)

	# Barra vazia
	var bar_y := bot_y + 6.0
	var bar_h := 10.0
	var bar_tl := _persp(Vector2(-SILO_W + 2, bar_y))
	var bar_tr := _persp(Vector2(SILO_W - 2, bar_y))
	var bar_bl := _persp(Vector2(-SILO_W + 2, bar_y + bar_h))
	var bar_br := _persp(Vector2(SILO_W - 2, bar_y + bar_h))
	draw_polygon(PackedVector2Array([bar_tl, bar_tr, bar_br, bar_bl]),
		PackedColorArray([Themes.c("battery_neon", 0.15), Themes.c("battery_neon", 0.15), Themes.c("battery_neon", 0.15), Themes.c("battery_neon", 0.15)]))
	_draw_quad_outline(PackedVector2Array([bar_tl, bar_tr, bar_br, bar_bl]), Themes.c("battery_neon", 0.25), 1.5)

	# Indicador de pentes (todos vazios)
	var mag_y := bar_y + bar_h + 4.0
	var mag_w := (SILO_W * 2.0 - 4.0) / max_magazines
	for mi in max_magazines:
		var mx := -SILO_W + 2.0 + mi * mag_w + 1.0
		var mw := mag_w - 2.0
		var mtl := _persp(Vector2(mx, mag_y))
		var mtr := _persp(Vector2(mx + mw, mag_y))
		var mbl := _persp(Vector2(mx, mag_y + 4.0))
		var mbr := _persp(Vector2(mx + mw, mag_y + 4.0))
		draw_polygon(PackedVector2Array([mtl, mtr, mbr, mbl]),
			PackedColorArray([Themes.c("battery_neon", 0.2), Themes.c("battery_neon", 0.2), Themes.c("battery_neon", 0.2), Themes.c("battery_neon", 0.2)]))

	# Texto "EMPTY" pulsando
	var pulse_alpha: float = 0.3 + 0.5 * abs(sin(empty_pulse_time * 2.5))
	var empty_text: String = get_node("/root/Tr").t("EMPTY")
	var font := ThemeDB.fallback_font
	var font_size := 32
	var text_size := font.get_string_size(empty_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := _persp(Vector2(-text_size.x / 2.0, SILO_CY + 2.0))
	draw_string(font, text_pos, empty_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Themes.c("text_warning", pulse_alpha))

# ============================================================
# INTERFACE PUBLICA
# ============================================================

func can_fire() -> bool:
	return magazine_ammo > 0

func consume_ammo() -> void:
	if magazine_ammo <= 0:
		return
	magazine_ammo -= 1
	queue_redraw()
	if magazine_ammo <= 0 and not reloading:
		_start_reload()

func _start_reload() -> void:
	if magazines <= 0:
		return
	magazines -= 1
	reloading = true
	reload_timer.start(reload_time)

func _on_reload_timer_timeout() -> void:
	magazine_ammo = magazine_size
	reloading = false
	queue_redraw()
