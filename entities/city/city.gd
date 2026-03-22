extends Area2D

signal city_destroyed

var data: CityData
var anim_time := 0.0

# Dados procedurais
var traces: Array[Array] = []
var pin_positions: PackedVector2Array

# Grid do chao — mesmos parametros do neon_grid.gd
const NUM_V_LINES := 6
const NUM_H_LINES := 6
const GRID_SPREAD_MULT := 1.2
const CHIP_DEPTH := 10.0

# Quad do chip calculado a partir do grid (coords locais)
var chip_tl := Vector2.ZERO
var chip_tr := Vector2.ZERO
var chip_br := Vector2.ZERO
var chip_bl := Vector2.ZERO

# Pins por lado
const PINS_H := 8
const PINS_V := 5
const PIN_LEN_H := 14.0
const PIN_LEN_V := 8.0

func _ready() -> void:
	data = CityData.new()
	_compute_grid_cell()
	_generate()
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

# Calcula o quadrilatero do grid onde a cidade esta
func _compute_grid_cell() -> void:
	var screen := get_viewport().get_visible_rect().size
	var vanish_x := screen.x / 2.0
	var horizon_y := screen.y * 0.9
	var floor_h := screen.y - horizon_y
	var spread := screen.x * GRID_SPREAD_MULT

	# Posicao X de uma linha vertical i em um dado y global
	# line_x(i, y) = vanish_x + (i / NUM_V_LINES) * spread * (y - horizon_y) / floor_h

	# Celula centrada na cidade (nao snappa ao grid, mantem espacamento uniforme)
	var v_ratio := (position.y - horizon_y) / floor_h
	var cell_w_at_city := spread * v_ratio / NUM_V_LINES
	var center_i := (position.x - vanish_x) / cell_w_at_city
	var left_i := center_i - 0.5
	var right_i := center_i + 0.5

	# Acha qual celula horizontal a cidade esta
	# y = horizon_y + (t^2) * floor_h, onde t = i / NUM_H_LINES
	# t = sqrt((y - horizon_y) / floor_h) = sqrt(v_ratio)
	var t_at_city := sqrt(v_ratio)
	var float_hi := t_at_city * NUM_H_LINES
	var top_hi := floori(float_hi)
	var bot_hi := top_hi + 1

	# Y global das linhas horizontais
	var top_t := float(top_hi) / NUM_H_LINES
	var bot_t := float(bot_hi) / NUM_H_LINES
	var top_y_global := horizon_y + top_t * top_t * floor_h
	var bot_y_global := horizon_y + bot_t * bot_t * floor_h

	# X das linhas verticais no top_y e bot_y
	var top_vr := (top_y_global - horizon_y) / floor_h
	var bot_vr := (bot_y_global - horizon_y) / floor_h

	var tl_x := vanish_x + float(left_i) / NUM_V_LINES * spread * top_vr
	var tr_x := vanish_x + float(right_i) / NUM_V_LINES * spread * top_vr
	var bl_x := vanish_x + float(left_i) / NUM_V_LINES * spread * bot_vr
	var br_x := vanish_x + float(right_i) / NUM_V_LINES * spread * bot_vr

	# Encolhe chips laterais no eixo vertical
	var dist_ratio := absf(position.x - vanish_x) / vanish_x  # 0=centro, ~0.75=lateral
	var v_shrink := 1.0 - dist_ratio * 0.25  # ate 25% mais baixos nas laterais
	var mid_y := (top_y_global + bot_y_global) / 2.0
	top_y_global = mid_y + (top_y_global - mid_y) * v_shrink
	bot_y_global = mid_y + (bot_y_global - mid_y) * v_shrink
	# Recalcula X nas novas alturas
	var top_vr2 := (top_y_global - horizon_y) / floor_h
	var bot_vr2 := (bot_y_global - horizon_y) / floor_h
	tl_x = vanish_x + left_i / NUM_V_LINES * spread * top_vr2
	tr_x = vanish_x + right_i / NUM_V_LINES * spread * top_vr2
	bl_x = vanish_x + left_i / NUM_V_LINES * spread * bot_vr2
	br_x = vanish_x + right_i / NUM_V_LINES * spread * bot_vr2

	# Converte para coordenadas locais
	chip_tl = Vector2(tl_x - position.x, top_y_global - position.y)
	chip_tr = Vector2(tr_x - position.x, top_y_global - position.y)
	chip_br = Vector2(br_x - position.x, bot_y_global - position.y)
	chip_bl = Vector2(bl_x - position.x, bot_y_global - position.y)

# Retorna o quad do chip (TL, TR, BR, BL)
func _chip_quad() -> PackedVector2Array:
	return PackedVector2Array([chip_tl, chip_tr, chip_br, chip_bl])

# Quad interno com margem proporcional
func _die_quad(margin_ratio: float) -> PackedVector2Array:
	var center := (chip_tl + chip_tr + chip_br + chip_bl) / 4.0
	return PackedVector2Array([
		center + (chip_tl - center) * (1.0 - margin_ratio),
		center + (chip_tr - center) * (1.0 - margin_ratio),
		center + (chip_br - center) * (1.0 - margin_ratio),
		center + (chip_bl - center) * (1.0 - margin_ratio),
	])

func _draw_quad_outline(quad: PackedVector2Array, color: Color, width: float) -> void:
	for i in quad.size():
		draw_line(quad[i], quad[(i + 1) % quad.size()], color, width, true)

# Interpola um ponto dentro do quad (u=0..1 horizontal, v=0..1 vertical)
func _quad_lerp(u: float, v: float) -> Vector2:
	var top := chip_tl.lerp(chip_tr, u)
	var bot := chip_bl.lerp(chip_br, u)
	return top.lerp(bot, v)

# Interpola ponto na borda do quad (side=0 esq, 1 dir, 2 cima, 3 baixo)
func _edge_lerp(side: int, t: float) -> Vector2:
	match side:
		0: return chip_tl.lerp(chip_bl, t)
		1: return chip_tr.lerp(chip_br, t)
		2: return chip_tl.lerp(chip_tr, t)
		3: return chip_bl.lerp(chip_br, t)
	return Vector2.ZERO

# ============================================================
# GERACAO
# ============================================================

func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x) * 7 + 31

	pin_positions = PackedVector2Array()
	traces.clear()

	# Gera pins nos 4 lados com posicoes relativas ao quad
	for side in 4:
		var pins_count := PINS_H if side <= 1 else PINS_V
		var pin_len := PIN_LEN_H if side <= 1 else PIN_LEN_V
		for pi in pins_count:
			var t := (pi + 1.0) / (pins_count + 1.0)
			var pin_base := _edge_lerp(side, t)
			var pin_end := Vector2.ZERO
			var trace_dir := Vector2.ZERO

			match side:
				0:  # esquerda — pin sai pra esquerda
					var edge_dir := (chip_bl - chip_tl).normalized()
					var outward := Vector2(-edge_dir.y, edge_dir.x)  # perpendicular pra fora
					pin_end = pin_base + outward * pin_len
					trace_dir = outward
				1:  # direita — pin sai pra direita
					var edge_dir := (chip_br - chip_tr).normalized()
					var outward := Vector2(edge_dir.y, -edge_dir.x)
					pin_end = pin_base + outward * pin_len
					trace_dir = outward
				2:  # cima — pin sai pra cima
					pin_end = pin_base + Vector2(0, -pin_len)
					trace_dir = Vector2(0, -1)
				3:  # baixo — pin sai pra baixo
					pin_end = pin_base + Vector2(0, pin_len)
					trace_dir = Vector2(0, 1)

			pin_positions.append(pin_base)
			pin_positions.append(pin_end)

			# Trilha saindo do pin — ~25% dos pins tem trilha
			if rng.randf() > 0.25:
				continue
			var num_segs := rng.randi_range(2, 3)
			var pts: Array[Vector2] = [pin_end]
			var cur := pin_end
			var going_main := true

			for _si in num_segs:
				var seg_len := rng.randf_range(12.0, 50.0)
				if going_main:
					var move := trace_dir * seg_len
					if absf(trace_dir.y) > 0.5:
						move.y *= 0.45
					cur = cur + move
				else:
					var perp := Vector2(trace_dir.y, -trace_dir.x)
					var move := perp * rng.randf_range(-seg_len, seg_len)
					if absf(perp.y) > 0.5:
						move.y *= 0.45
					cur = cur + move
				pts.append(cur)
				going_main = not going_main

			traces.append(pts)

# ============================================================
# DRAW
# ============================================================

func _draw() -> void:
	if data.is_alive():
		_draw_alive()
	else:
		_draw_dead()

func _draw_alive() -> void:
	var fill := Color(0.02, 0.03, 0.06)
	var line_pulse := (sin(anim_time * 1.2) + 1.0) * 0.5
	var neon_alpha := lerpf(0.5, 0.9, line_pulse)
	var neon := Color(0.0, 0.8, 1.0, neon_alpha)
	var neon_glow_w := lerpf(2.0, 4.0, line_pulse)
	var trace_col := Color(0.0, 0.8, 1.0, lerpf(0.15, 0.35, line_pulse))
	var pin_col := Color(0.0, 1.0, 1.0, lerpf(0.35, 0.7, line_pulse))

	# Trilhas (atras de tudo)
	for tpts in traces:
		var pts: Array[Vector2] = tpts
		if pts.size() < 2:
			continue
		for i in pts.size() - 1:
			draw_line(pts[i], pts[i + 1], trace_col, 1.5, true)
		draw_circle(pts[-1], 2.5, Color(0.0, 1.0, 1.0, 0.3))

	# Pins
	for i in range(0, pin_positions.size(), 2):
		draw_line(pin_positions[i], pin_positions[i + 1], pin_col, 2.0, true)

	# Face lateral do chip (espessura/volume)
	var chip := _chip_quad()
	var side_fill := Color(0.01, 0.015, 0.03)
	var side_neon := Color(0.0, 0.6, 0.8, 0.5)
	var front_face := PackedVector2Array([
		chip[3], chip[2],
		Vector2(chip[2].x, chip[2].y + CHIP_DEPTH),
		Vector2(chip[3].x, chip[3].y + CHIP_DEPTH),
	])
	draw_polygon(front_face, PackedColorArray([side_fill, side_fill, side_fill, side_fill]))
	draw_line(front_face[0], front_face[1], side_neon, 1.5, true)
	draw_line(front_face[1], front_face[2], side_neon, 1.5, true)
	draw_line(front_face[2], front_face[3], side_neon, 1.5, true)
	draw_line(front_face[3], front_face[0], side_neon, 1.5, true)
	var right_face := PackedVector2Array([
		chip[1], chip[2],
		Vector2(chip[2].x, chip[2].y + CHIP_DEPTH),
		Vector2(chip[1].x, chip[1].y + CHIP_DEPTH * 0.4),
	])
	draw_polygon(right_face, PackedColorArray([side_fill, side_fill, side_fill, side_fill]))
	draw_line(right_face[1], right_face[2], side_neon, 1.5, true)
	draw_line(right_face[2], right_face[3], side_neon, 1.0, true)
	draw_line(right_face[3], right_face[0], side_neon, 1.0, true)
	var left_face := PackedVector2Array([
		chip[0], chip[3],
		Vector2(chip[3].x, chip[3].y + CHIP_DEPTH),
		Vector2(chip[0].x, chip[0].y + CHIP_DEPTH * 0.4),
	])
	draw_polygon(left_face, PackedColorArray([side_fill, side_fill, side_fill, side_fill]))
	draw_line(left_face[0], left_face[1], side_neon, 1.0, true)
	draw_line(left_face[1], left_face[2], side_neon, 1.5, true)
	draw_line(left_face[2], left_face[3], side_neon, 1.0, true)

	# Face superior do chip
	var fill4 := PackedColorArray([fill, fill, fill, fill])
	draw_polygon(chip, fill4)
	_draw_quad_outline(chip, neon, neon_glow_w)

	# Marca de orientacao — canto superior esquerdo
	var notch := chip[0]
	var notch_u := 0.12
	var notch_v := 0.2
	var notch_h := _quad_lerp(0, notch_v)
	var notch_r := _quad_lerp(notch_u, 0)
	draw_line(notch, notch_h, neon, 1.5, true)
	draw_line(notch, notch_r, neon, 1.5, true)

	# Die interno
	var die := _die_quad(0.25)
	draw_polygon(die, PackedColorArray([Color(0.0, 0.8, 1.0, 0.08), Color(0.0, 0.8, 1.0, 0.08), Color(0.0, 0.8, 1.0, 0.08), Color(0.0, 0.8, 1.0, 0.08)]))
	_draw_quad_outline(die, Color(0.0, 0.8, 1.0, 0.4), 1.0)

	# Linhas internas do die
	var die_cx := (die[0].x + die[1].x + die[2].x + die[3].x) / 4.0
	var die_cy := (die[0].y + die[1].y + die[2].y + die[3].y) / 4.0
	var die_top_mid := (die[0] + die[1]) / 2.0
	var die_bot_mid := (die[2] + die[3]) / 2.0
	var die_left_mid := (die[0] + die[3]) / 2.0
	var die_right_mid := (die[1] + die[2]) / 2.0
	draw_line(die_top_mid, die_bot_mid, Color(0.0, 0.8, 1.0, 0.15), 1.0, true)
	draw_line(die_left_mid, die_right_mid, Color(0.0, 0.8, 1.0, 0.15), 1.0, true)

	# Core pulsante
	var pulse := (sin(anim_time * 2.5) + 1.0) * 0.5
	var core_alpha := lerpf(0.5, 1.0, pulse)
	var core_pos := Vector2(die_cx, die_cy)
	draw_circle(core_pos, 14.0, Color(0.0, 1.0, 1.0, core_alpha * 0.1))
	draw_circle(core_pos, 8.0, Color(0.0, 1.0, 1.0, core_alpha * 0.4))
	draw_circle(core_pos, 4.0, Color(0.0, 1.0, 1.0, core_alpha))
	draw_circle(core_pos, 2.0, Color(0.8, 1.0, 1.0, core_alpha))

	# Pulsos de energia nas trilhas
	var pulse_t := fmod(anim_time * 0.25, 1.0)
	for tpts in traces:
		var pts: Array[Vector2] = tpts
		if pts.size() < 2:
			continue
		var total_len := 0.0
		for i in pts.size() - 1:
			total_len += pts[i].distance_to(pts[i + 1])
		if total_len <= 0:
			continue
		var target_len := pulse_t * total_len
		var accum := 0.0
		for i in pts.size() - 1:
			var seg_len := pts[i].distance_to(pts[i + 1])
			if accum + seg_len >= target_len and seg_len > 0:
				var seg_t := (target_len - accum) / seg_len
				var pulse_pos := pts[i].lerp(pts[i + 1], seg_t)
				draw_circle(pulse_pos, 3.0, Color(0.0, 1.0, 1.0, 0.6))
				draw_circle(pulse_pos, 6.0, Color(0.0, 1.0, 1.0, 0.15))
				break
			accum += seg_len


func _draw_dead() -> void:
	var dead := Color(0.0, 0.6, 1.0, 0.2)
	var dead_dim := Color(0.0, 0.4, 0.6, 0.1)
	var fill := Color(0.02, 0.03, 0.06)

	# Trilhas mortas
	for tpts in traces:
		var pts: Array[Vector2] = tpts
		if pts.size() < 2:
			continue
		for i in pts.size() - 1:
			draw_line(pts[i], pts[i + 1], dead_dim, 1.0, true)

	# Pins dim
	for i in range(0, pin_positions.size(), 2):
		draw_line(pin_positions[i], pin_positions[i + 1], Color(0.0, 0.3, 0.4, 0.2), 1.5, true)

	# Chip quebrado — com volume
	var chip := _chip_quad()
	var side_dead := Color(0.0, 0.4, 0.6, 0.12)
	var front_face := PackedVector2Array([
		chip[3], chip[2],
		Vector2(chip[2].x, chip[2].y + CHIP_DEPTH),
		Vector2(chip[3].x, chip[3].y + CHIP_DEPTH),
	])
	draw_polygon(front_face, PackedColorArray([fill, fill, fill, fill]))
	draw_line(front_face[2], front_face[3], side_dead, 1.0, true)
	draw_line(front_face[1], front_face[2], side_dead, 1.0, true)
	draw_polygon(chip, PackedColorArray([fill, fill, fill, fill]))
	# Outline parcial (quebrado)
	var mid_top := (chip[0] + chip[1]) / 2.0
	draw_line(chip[0], mid_top + (chip[0] - mid_top) * 0.3, dead, 1.5, true)
	draw_line(chip[3], chip[0], dead, 1.0, true)
	draw_line(chip[2], chip[3], dead, 1.0, true)
	var mid_right := (chip[1] + chip[2]) / 2.0
	draw_line(mid_right, chip[2], dead, 1.0, true)

	# Rachadura
	var center := (chip[0] + chip[1] + chip[2] + chip[3]) / 4.0
	var crack_start := chip[0] * 0.7 + chip[1] * 0.3
	var crack_end := chip[2] * 0.3 + chip[3] * 0.7
	draw_line(crack_start, center + Vector2(3, 0), dead, 1.5, true)
	draw_line(center + Vector2(3, 0), crack_end, dead, 1.5, true)

	# Fumaca continua subindo
	var chip_center := center
	var chip_top_y := minf(chip[0].y, chip[1].y)
	for si in 12:
		var phase := float(si) * 0.7
		var t := fmod(anim_time * 0.5 + phase, 3.5)
		var sx := chip_center.x + sin(phase * 2.3) * 30.0 + sin(anim_time * 0.2 + phase) * 12.0
		var sy := chip_top_y - t * 50.0
		var sr := lerpf(8.0, 28.0, t / 3.5)
		var sa := lerpf(0.5, 0.0, t / 3.5)
		draw_circle(Vector2(sx, sy), sr, Color(0.3, 0.32, 0.4, sa))

# ============================================================
# INTERFACE PUBLICA
# ============================================================

func take_hit() -> void:
	if not data.is_alive():
		return
	data.take_hit()
	queue_redraw()
	city_destroyed.emit()
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)

func revive() -> void:
	data.alive = true
	queue_redraw()
	set_deferred("monitorable", true)
	set_deferred("monitoring", true)

func is_alive() -> bool:
	return data.is_alive()
