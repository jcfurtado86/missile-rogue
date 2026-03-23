extends Area2D

signal city_destroyed

var data: CityData
var anim_time := 0.0

# Shield
var shield_active := false
var shield_cooldown := 0.0  # 0 = sem escudo
var shield_timer := 0.0     # tempo restante ate escudo voltar

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
	# Reposiciona collision shape para coincidir com o chip visual
	var center := (chip_tl + chip_tr + chip_br + chip_bl) / 4.0
	$CollisionShape2D.position = center
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	# Shield regen
	if shield_cooldown > 0.0 and not shield_active and data.is_alive():
		shield_timer -= delta
		if shield_timer <= 0.0:
			shield_active = true
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

# Centro global do chip (ponto com glow)
func get_chip_center() -> Vector2:
	return global_position + (chip_tl + chip_tr + chip_br + chip_bl) / 4.0

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

	# Pulsos de energia nas trilhas (ida e volta)
	var raw_t := fmod(anim_time * 0.25, 2.0)
	var pulse_t := raw_t if raw_t <= 1.0 else 2.0 - raw_t
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

	# Shield visual — domo 3D cobrindo o chip
	if shield_active:
		_draw_shield_dome(true)
	elif shield_cooldown > 0.0 and shield_timer > 0.0:
		_draw_shield_dome(false)


func _draw_shield_dome(active: bool) -> void:
	var center := (chip_tl + chip_tr + chip_br + chip_bl) / 4.0
	# Raios baseados no chip, com margem pra ficar maior
	var margin := 1.8
	var rx := maxf(chip_tr.x - chip_tl.x, chip_br.x - chip_bl.x) / 2.0 * margin
	# Raio vertical em perspectiva (comprimido)
	var chip_h := (chip_bl.y + chip_br.y) / 2.0 - (chip_tl.y + chip_tr.y) / 2.0
	var ry_base := chip_h / 2.0 * margin  # elipse da base
	var dome_height := rx * 0.4  # altura do domo (bem achatado)
	# Centro X com leve skew pela perspectiva
	var cx := center.x
	var base_y := center.y + ry_base * 0.3  # base um pouco abaixo do centro do chip
	var segments := 32

	if active:
		var pulse := (sin(anim_time * 2.5) + 1.0) * 0.5
		var scan_raw := fmod(anim_time * 0.5, 2.0)
		var scan := scan_raw if scan_raw <= 1.0 else 2.0 - scan_raw

		# Fatias horizontais (efeito de volume)
		var slices := 12
		for s in slices:
			var angle := PI * float(s) / slices  # 0..PI
			var slice_y := base_y - sin(angle) * dome_height
			var slice_rx := cos(angle) * rx  # negativo no topo, ok
			slice_rx = absf(slice_rx)
			if slice_rx < 2.0:
				continue
			var alpha := lerpf(0.12, 0.25, pulse) * sin(angle)
			draw_line(Vector2(cx - slice_rx, slice_y), Vector2(cx + slice_rx, slice_y),
				Color(0.0, 0.9, 1.0, alpha), 1.0, true)

		# Scan line horizontal animada
		var scan_angle := scan * PI
		var scan_y := base_y - sin(scan_angle) * dome_height
		var scan_rx := absf(cos(scan_angle)) * rx
		if scan_rx > 4.0:
			draw_line(Vector2(cx - scan_rx, scan_y), Vector2(cx + scan_rx, scan_y),
				Color(0.0, 1.0, 1.0, 0.45), 2.0, true)

		# Contorno — semicirculo (arco de PI, da direita pra esquerda passando pelo topo)
		var outline_col := Color(0.0, 1.0, 1.0, lerpf(0.7, 1.0, pulse))
		var arc_pts := PackedVector2Array()
		for i in segments + 1:
			var angle := PI * float(i) / segments  # 0..PI
			var px := cx + cos(angle) * rx
			var py := base_y - sin(angle) * dome_height
			arc_pts.append(Vector2(px, py))
		for i in arc_pts.size() - 1:
			draw_line(arc_pts[i], arc_pts[i + 1], outline_col, 2.0, true)

		# Base — elipse perspectivada (metade visivel, parte da frente)
		var base_col := Color(0.0, 1.0, 1.0, lerpf(0.5, 0.8, pulse))
		var base_pts := PackedVector2Array()
		for i in segments + 1:
			var angle := PI + PI * float(i) / segments  # PI..TAU (metade de baixo)
			var bx := cx + cos(angle) * rx
			var by := base_y + sin(angle) * ry_base
			base_pts.append(Vector2(bx, by))
		for i in base_pts.size() - 1:
			draw_line(base_pts[i], base_pts[i + 1], Color(0.0, 1.0, 1.0, 0.15), 1.0, true)
		# Metade da frente (visivel, mais forte)
		var front_pts := PackedVector2Array()
		for i in segments + 1:
			var angle := PI * float(i) / segments  # 0..PI
			var bx := cx + cos(angle) * rx
			var by := base_y + sin(angle) * ry_base
			front_pts.append(Vector2(bx, by))
		for i in front_pts.size() - 1:
			draw_line(front_pts[i], front_pts[i + 1], base_col, 2.5, true)

		# Meridianos — arcos verticais
		var meridians := 3
		for m in meridians:
			var u := float(m + 1) / (meridians + 1)
			var mx := cx - rx + u * rx * 2.0
			var dx_ratio := (mx - cx) / rx
			var merid_h := dome_height * sqrt(maxf(1.0 - dx_ratio * dx_ratio, 0.0))
			if merid_h < 3.0:
				continue
			var merid_pts := PackedVector2Array()
			@warning_ignore("integer_division")
			var half := segments / 2
			for i in half + 1:
				var t := float(i) / float(half)
				var angle := PI * t
				var py := base_y - sin(angle) * merid_h
				merid_pts.append(Vector2(mx, py))
			for i in merid_pts.size() - 1:
				draw_line(merid_pts[i], merid_pts[i + 1], Color(0.0, 1.0, 1.0, 0.15), 1.0, true)

		# Hexagono no topo
		var hex_r := rx * 0.15
		var hex_y := base_y - dome_height
		var hex_col := Color(0.0, 1.0, 1.0, lerpf(0.25, 0.5, pulse))
		for i in 6:
			var a1 := TAU * i / 6.0
			var a2 := TAU * (i + 1) / 6.0
			draw_line(
				Vector2(cx + cos(a1) * hex_r, hex_y + sin(a1) * hex_r * 0.5),
				Vector2(cx + cos(a2) * hex_r, hex_y + sin(a2) * hex_r * 0.5),
				hex_col, 1.0, true)
	else:
		# Recarregando — arco dim com progresso
		var progress := 1.0 - (shield_timer / shield_cooldown)
		var dim := Color(0.0, 0.6, 0.8, 0.15)
		var lit := Color(0.0, 1.0, 1.0, 0.4)
		var fill_segs := int(segments * progress)

		var arc_pts := PackedVector2Array()
		for i in segments + 1:
			var angle := PI * float(i) / segments
			var px := cx + cos(angle) * rx
			var py := base_y - sin(angle) * dome_height
			arc_pts.append(Vector2(px, py))
		for i in arc_pts.size() - 1:
			var col := lit if i < fill_segs else dim
			draw_line(arc_pts[i], arc_pts[i + 1], col, 1.5, true)

		# Base dim
		var base_pts := PackedVector2Array()
		for i in segments + 1:
			var angle := TAU * float(i) / segments
			var bx := cx + cos(angle) * rx
			var by := base_y + sin(angle) * ry_base
			base_pts.append(Vector2(bx, by))
		for i in base_pts.size() - 1:
			draw_line(base_pts[i], base_pts[i + 1], dim, 1.0, true)

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
	if shield_active:
		shield_active = false
		shield_timer = shield_cooldown
		queue_redraw()
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

func setup_shield(cooldown: float) -> void:
	shield_cooldown = cooldown
	if cooldown > 0.0:
		shield_active = true

func is_alive() -> bool:
	return data.is_alive()
