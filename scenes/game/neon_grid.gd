extends Node2D

var screen_size: Vector2
var horizon_y: float
const MARGIN := 200.0  # margem extra pra cobrir qualquer tela

# Cores do gradiente do ceu
const SKY_TOP := Color(0.02, 0.01, 0.08)
const SKY_MID := Color(0.08, 0.01, 0.15)
const SKY_HORIZON := Color(0.4, 0.0, 0.35)

# Cores do grid
const FLOOR_DARK := Color(0.06, 0.0, 0.1)

# Cenario
enum Scenery { CITY, MOUNTAINS }
var scenery: Scenery

# Dados cidade
var skyline_back: Array[Dictionary] = []
var skyline_front: Array[Dictionary] = []

# Dados montanhas (low-poly triangles)
var mountain_triangles: Array[Dictionary] = []

# Animacao
var anim_time := 0.0

# Flyby (OVNI ou Nyan Cat)
enum FlybyType { UFO, NYAN }
var flyby_active := false
var flyby_type: FlybyType = FlybyType.UFO
var flyby_x := 0.0
var flyby_y := 0.0
var flyby_speed := 0.0
var flyby_direction := 1.0  # 1 = direita, -1 = esquerda
var flyby_timer := 0.0
var flyby_next_time := 0.0
var nyan_anim := 0.0  # animacao das patas

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	horizon_y = screen_size.y * 0.90
	z_index = -1

	var run_seed := randi()
	scenery = Scenery.CITY if run_seed % 2 == 0 else Scenery.MOUNTAINS

	if scenery == Scenery.CITY:
		_generate_city(run_seed)
	else:
		_generate_mountains(run_seed)

	flyby_next_time = randf_range(15.0, 40.0)

# ============================================================
# GERACAO
# ============================================================

func _generate_city(run_seed: int) -> void:
	skyline_back = _gen_building_layer(run_seed, 30.0, 80.0, 60.0, 250.0, 0.0, 5.0, 0.15)
	skyline_front = _gen_building_layer(run_seed + 1000, 25.0, 70.0, 80.0, 400.0, 0.0, 3.0, 0.25)

func _gen_building_layer(seed_val: int, min_w: float, max_w: float, min_h: float, max_h: float, min_gap: float, max_gap: float, tower_chance: float) -> Array[Dictionary]:
	var buildings: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var x := -MARGIN

	while x < screen_size.x + MARGIN:
		var w := rng.randf_range(min_w, max_w)
		var h := rng.randf_range(min_h, max_h)
		var gap := rng.randf_range(min_gap, max_gap)

		if rng.randf() < tower_chance:
			h = rng.randf_range(max_h * 0.85, max_h * 1.2)
			w = rng.randf_range(min_w * 0.6, min_w * 1.2)

		var has_antenna := h > max_h * 0.7 and rng.randf() < 0.5
		var antenna_h := rng.randf_range(15.0, 40.0) if has_antenna else 0.0

		var roof_type := 0
		if w > 35 and rng.randf() < 0.35:
			roof_type = 1
		elif w < 30 and h > max_h * 0.6 and rng.randf() < 0.25:
			roof_type = 2

		var setback_w := w * rng.randf_range(0.2, 0.35) if roof_type == 1 else 0.0
		var setback_h := rng.randf_range(15.0, 35.0) if roof_type == 1 else 0.0
		var spire_h := rng.randf_range(20.0, 45.0) if roof_type == 2 else 0.0
		var num_windows := int(w / 8.0)

		buildings.append({
			"x": x, "w": w, "h": h,
			"antenna": has_antenna, "antenna_h": antenna_h,
			"roof_type": roof_type,
			"setback_w": setback_w, "setback_h": setback_h,
			"spire_h": spire_h,
			"num_windows": num_windows,
		})
		x += w + gap

	return buildings

func _generate_mountains(run_seed: int) -> void:
	mountain_triangles.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed

	# Gera pontos da crista — pico central dominante, menores nas pontas
	var num_points := 18
	var ridge_points: Array[Vector2] = []
	var center_x := screen_size.x / 2.0

	for i in range(num_points + 1):
		var t := float(i) / num_points
		var x := lerpf(-MARGIN, screen_size.x + MARGIN, t)
		# Altura baseada na distancia do centro (mais alto no centro)
		var dist_from_center := absf(x - center_x) / ((screen_size.x + MARGIN) * 0.5)
		var envelope := 1.0 - dist_from_center * 0.45
		envelope = maxf(envelope, 0.35)
		var h := rng.randf_range(96.0, 462.0) * envelope
		# Vales entre picos
		if i % 2 == 0 and i > 0 and i < num_points:
			h *= rng.randf_range(0.3, 0.55)
		var y := horizon_y - h
		ridge_points.append(Vector2(x, y))

	# Gera linha de base no horizonte
	var base_points: Array[Vector2] = []
	for i in range(num_points + 1):
		var t := float(i) / num_points
		var x := lerpf(-MARGIN, screen_size.x + MARGIN, t)
		base_points.append(Vector2(x, horizon_y))

	# Gera pontos intermedios (entre crista e base)
	var mid_points: Array[Vector2] = []
	for i in range(num_points):
		var mid_x := (ridge_points[i].x + ridge_points[i + 1].x) / 2.0 + rng.randf_range(-15.0, 15.0)
		var mid_y := lerpf(ridge_points[i].y, horizon_y, rng.randf_range(0.4, 0.7))
		mid_y += rng.randf_range(-20.0, 20.0)
		mid_points.append(Vector2(mid_x, mid_y))

	# Triangula: conecta crista -> mid -> crista -> base
	for i in range(num_points):
		var r0 := ridge_points[i]
		var r1 := ridge_points[i + 1]
		var mid := mid_points[i]
		var b0 := base_points[i]
		var b1 := base_points[i + 1]

		# Triangulo superior esquerdo: r0, mid, r1 (a face da montanha)
		var shade1 := rng.randf_range(0.02, 0.06)
		mountain_triangles.append({
			"points": PackedVector2Array([r0, mid, r1]),
			"shade": shade1,
		})

		# Triangulo inferior esquerdo: r0, b0, mid
		var shade2 := rng.randf_range(0.01, 0.04)
		mountain_triangles.append({
			"points": PackedVector2Array([r0, b0, mid]),
			"shade": shade2,
		})

		# Triangulo inferior direito: mid, b0, b1
		var shade3 := rng.randf_range(0.015, 0.045)
		mountain_triangles.append({
			"points": PackedVector2Array([mid, b0, b1]),
			"shade": shade3,
		})

		# Triangulo inferior direito 2: mid, b1, r1
		var shade4 := rng.randf_range(0.01, 0.035)
		mountain_triangles.append({
			"points": PackedVector2Array([mid, b1, r1]),
			"shade": shade4,
		})

# ============================================================
# DRAW
# ============================================================

func _process(delta: float) -> void:
	anim_time += delta
	_update_flyby(delta)
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_flyby()
	if scenery == Scenery.CITY:
		_draw_city()
	else:
		_draw_mountains()
	_draw_horizon()
	_draw_floor()
	_draw_perspective_grid()

# --- CEU ---

func _draw_sky() -> void:
	var steps := 80
	var band_h := horizon_y / steps
	for i in steps:
		var t := float(i) / steps
		var color: Color
		if t < 0.6:
			var st := t / 0.6
			color = SKY_TOP.lerp(SKY_MID, st)
		else:
			var st := (t - 0.6) / 0.4
			color = SKY_MID.lerp(SKY_HORIZON, st)
		draw_rect(Rect2(-MARGIN, i * band_h, screen_size.x + MARGIN * 2, band_h + 1), color)

# --- CIDADE ---

func _draw_city() -> void:
	_draw_building_layer(skyline_back, Color(0.04, 0.01, 0.07), Color(0.6, 0.0, 0.8, 0.15), Color(0.6, 0.0, 0.8, 0.08))
	_draw_building_layer(skyline_front, Color(0.015, 0.005, 0.025), Color(1.0, 0.0, 0.6, 0.3), Color(1.0, 0.0, 0.6, 0.12))

func _draw_building_layer(buildings: Array[Dictionary], fill_color: Color, outline_color: Color, window_color: Color) -> void:
	for b in buildings:
		var bx: float = b["x"]
		var bw: float = b["w"]
		var bh: float = b["h"]
		var top_y := horizon_y - bh
		var roof_type: int = b["roof_type"]

		draw_rect(Rect2(bx, top_y, bw, bh), fill_color)
		draw_line(Vector2(bx, top_y), Vector2(bx, horizon_y), outline_color, 1.0, true)
		draw_line(Vector2(bx + bw, top_y), Vector2(bx + bw, horizon_y), outline_color, 1.0, true)
		draw_line(Vector2(bx, top_y), Vector2(bx + bw, top_y), outline_color, 1.0, true)

		if roof_type == 1:
			var sw: float = b["setback_w"]
			var sh: float = b["setback_h"]
			draw_rect(Rect2(bx + sw, top_y - sh, bw - sw * 2, sh), fill_color)
			draw_line(Vector2(bx + sw, top_y - sh), Vector2(bx + bw - sw, top_y - sh), outline_color, 1.0, true)
			draw_line(Vector2(bx + sw, top_y - sh), Vector2(bx + sw, top_y), outline_color, 1.0, true)
			draw_line(Vector2(bx + bw - sw, top_y - sh), Vector2(bx + bw - sw, top_y), outline_color, 1.0, true)

		if roof_type == 2:
			var sh: float = b["spire_h"]
			var mid_x := bx + bw / 2.0
			var spire := PackedVector2Array([Vector2(bx, top_y), Vector2(mid_x, top_y - sh), Vector2(bx + bw, top_y)])
			var spire_colors := PackedColorArray([fill_color, fill_color, fill_color])
			draw_polygon(spire, spire_colors)
			draw_line(spire[0], spire[1], outline_color, 1.0, true)
			draw_line(spire[1], spire[2], outline_color, 1.0, true)

		if b["antenna"]:
			var mid_x := bx + bw / 2.0
			var ah: float = b["antenna_h"]
			var antenna_top := top_y - ah
			if roof_type == 1:
				antenna_top = top_y - b["setback_h"] - ah
				draw_line(Vector2(mid_x, top_y - b["setback_h"]), Vector2(mid_x, antenna_top), outline_color, 1.5, true)
			elif roof_type == 2:
				antenna_top = top_y - b["spire_h"] - ah
				draw_line(Vector2(mid_x, top_y - b["spire_h"]), Vector2(mid_x, antenna_top), outline_color, 1.5, true)
			else:
				draw_line(Vector2(mid_x, top_y), Vector2(mid_x, antenna_top), outline_color, 1.5, true)
			# Luz piscando — on/off lento com ritmo unico por antena
			var blink_period := 1.0 + fmod(absf(bx * 0.07), 2.5)
			var blink_phase := fmod(absf(bx * 0.13 + bw * 0.3), TAU)
			var blink_val := sin(anim_time / blink_period + blink_phase)
			var light_alpha := 0.9 if blink_val > 0.3 else 0.1
			draw_circle(Vector2(mid_x, antenna_top), 2.5, Color(1.0, 0.0, 0.3, light_alpha))
			draw_circle(Vector2(mid_x, antenna_top), 5.0, Color(1.0, 0.0, 0.3, light_alpha * 0.2))

		var num_win: int = b["num_windows"]
		if num_win >= 2:
			var win_margin := 4.0
			var win_area := bw - win_margin * 2.0
			var win_spacing := win_area / num_win
			for wi in range(num_win):
				var wx := bx + win_margin + wi * win_spacing + win_spacing * 0.5
				# Algumas janelas piscam lentamente
				var flicker_id := int(bx * 3 + wi * 17) % 20
				var win_alpha_mult := 1.0
				if flicker_id < 3:
					win_alpha_mult = (sin(anim_time * (0.4 + flicker_id * 0.2) + flicker_id) + 1.0) * 0.5
				var wc := Color(window_color.r, window_color.g, window_color.b, window_color.a * win_alpha_mult)
				draw_line(Vector2(wx, top_y + 6.0), Vector2(wx, horizon_y - 4.0), wc, 1.0, true)

# --- MONTANHAS ---

func _draw_mountains() -> void:
	var pulse := (sin(anim_time * 0.5) + 1.0) * 0.5
	var outline_alpha := lerpf(0.2, 0.7, pulse)
	var glow_alpha := lerpf(0.05, 0.3, pulse)
	var outline_color := Color(1.0, 0.0, 0.6, outline_alpha)
	var glow_color := Color(1.0, 0.0, 0.6, glow_alpha)

	# Desenha cada triangulo
	for tri in mountain_triangles:
		var pts: PackedVector2Array = tri["points"]
		var shade: float = tri["shade"]
		var fill := Color(shade, shade * 0.3, shade * 1.5, 1.0)
		var fill_colors := PackedColorArray([fill, fill, fill])
		draw_polygon(pts, fill_colors)

	# Outlines por cima de tudo
	for tri in mountain_triangles:
		var pts: PackedVector2Array = tri["points"]
		for edge_i in 3:
			var a := pts[edge_i]
			var b := pts[(edge_i + 1) % 3]
			# Nao desenha outlines na base (horizonte)
			if absf(a.y - horizon_y) < 3.0 and absf(b.y - horizon_y) < 3.0:
				continue
			draw_line(a, b, glow_color, 4.0, true)
			draw_line(a, b, outline_color, 1.0, true)

# --- FLYBY (OVNI / NYAN CAT) ---

func _update_flyby(delta: float) -> void:
	if flyby_active:
		flyby_x += flyby_speed * flyby_direction * delta
		nyan_anim += delta
		# Saiu da tela — desativar
		var exit_margin := 300.0 if flyby_type == FlybyType.NYAN else 50.0
		if flyby_direction > 0 and flyby_x > screen_size.x + MARGIN + exit_margin:
			flyby_active = false
			flyby_next_time = randf_range(20.0, 50.0)
			flyby_timer = 0.0
		elif flyby_direction < 0 and flyby_x < -MARGIN - exit_margin:
			flyby_active = false
			flyby_next_time = randf_range(20.0, 50.0)
			flyby_timer = 0.0
	else:
		flyby_timer += delta
		if flyby_timer >= flyby_next_time:
			_spawn_flyby()

func _spawn_flyby() -> void:
	flyby_active = true
	flyby_y = randf_range(horizon_y * 0.15, horizon_y * 0.55)
	nyan_anim = 0.0
	# Sorteia tipo
	flyby_type = FlybyType.NYAN if randf() > 0.5 else FlybyType.UFO
	if flyby_type == FlybyType.NYAN:
		flyby_speed = randf_range(80.0, 140.0)
	else:
		flyby_speed = randf_range(30.0, 80.0)
	# Direcao aleatoria
	if randf() > 0.5:
		flyby_direction = 1.0
		flyby_x = -MARGIN - 100
	else:
		flyby_direction = -1.0
		flyby_x = screen_size.x + MARGIN + 100

func _draw_flyby() -> void:
	if not flyby_active:
		return
	if flyby_type == FlybyType.UFO:
		_draw_ufo()
	else:
		_draw_nyan()

func _draw_ufo() -> void:
	var pos := Vector2(flyby_x, flyby_y)
	var neon := Color(0.5, 1.0, 0.8)
	var alpha := 0.7
	var fill := Color(0.02, 0.06, 0.05, alpha * 0.5)
	# Glow externo
	draw_circle(pos, 45.0, Color(neon.r, neon.g, neon.b, 0.04))
	# Corpo — disco achatado
	var body_rx := 35.0
	var body_ry := 10.0
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 16:
		var angle := TAU * float(i) / 16
		pts.append(pos + Vector2(cos(angle) * body_rx, sin(angle) * body_ry))
		cols.append(fill)
	draw_polygon(pts, cols)
	for i in 16:
		draw_line(pts[i], pts[(i + 1) % 16], Color(neon.r, neon.g, neon.b, alpha), 2.0, true)
	# Cupula
	var dome_pts := PackedVector2Array()
	var dome_cols := PackedColorArray()
	dome_pts.append(pos + Vector2(-16, 0))
	dome_cols.append(fill)
	for i in 9:
		var angle := PI + PI * float(i) / 8
		dome_pts.append(pos + Vector2(cos(angle) * 16, sin(angle) * 10 - 5))
		dome_cols.append(fill)
	dome_pts.append(pos + Vector2(16, 0))
	dome_cols.append(fill)
	draw_polygon(dome_pts, dome_cols)
	for i in dome_pts.size() - 1:
		draw_line(dome_pts[i], dome_pts[i + 1], Color(neon.r, neon.g, neon.b, alpha * 0.8), 1.0, true)
	# Janelas — 3 pontos
	for wi in 3:
		var wx := -8.0 + wi * 8.0
		draw_circle(pos + Vector2(wx, -6), 2.0, Color(neon.r, neon.g, neon.b, alpha * 0.7))
	# Luzes pulsantes — 3 pontos
	var light_pulse := (sin(anim_time * 2.5) + 1.0) * 0.5
	var light_a := lerpf(0.2, 0.7, light_pulse)
	for li in 3:
		var lx := -14.0 + li * 14.0
		draw_circle(pos + Vector2(lx, 8), 3.5, Color(neon.r, neon.g, neon.b, light_a))
		draw_circle(pos + Vector2(lx, 8), 7.0, Color(neon.r, neon.g, neon.b, light_a * 0.25))

func _draw_nyan() -> void:
	var pos := Vector2(flyby_x, flyby_y)
	var alpha := 0.55
	var dir := flyby_direction
	var bounce := sin(nyan_anim * 8.0) * 3.0  # bounce vertical
	pos.y += bounce

	# --- Rastro arco-iris (atras do gato) com fade ---
	var rainbow_base: Array[Color] = [
		Color(1.0, 0.0, 0.0),   # vermelho
		Color(1.0, 0.5, 0.0),   # laranja
		Color(1.0, 1.0, 0.0),   # amarelo
		Color(0.2, 1.0, 0.0),   # verde
		Color(0.0, 0.5, 1.0),   # azul
		Color(0.5, 0.0, 1.0),   # violeta
	]
	var trail_len := 200.0
	var band_h := 4.0
	var trail_start_x := pos.x - dir * 18  # atras do corpo
	var num_segments := 12
	for bi in rainbow_base.size():
		var bc := rainbow_base[bi]
		var band_y := pos.y - (rainbow_base.size() / 2.0 - bi) * band_h
		# Segmentos com fade progressivo
		for si in num_segments:
			var t0 := float(si) / num_segments
			var t1 := float(si + 1) / num_segments
			var fade0 := (1.0 - t0) * alpha * 0.6
			var fade1 := (1.0 - t1) * alpha * 0.6
			var x0 := trail_start_x - dir * trail_len * t0
			var x1 := trail_start_x - dir * trail_len * t1
			var y0 := band_y + sin(nyan_anim * 6.0 + bi * 0.5 + t0 * 3.0) * 2.0
			var y1 := band_y + sin(nyan_anim * 6.0 + bi * 0.5 + t1 * 3.0) * 2.0
			var seg_alpha := (fade0 + fade1) * 0.5
			if seg_alpha < 0.01:
				continue
			# Glow
			draw_line(Vector2(x0, y0), Vector2(x1, y1), Color(bc.r, bc.g, bc.b, seg_alpha * 0.3), band_h + 3.0, true)
			draw_line(Vector2(x0, y0), Vector2(x1, y1), Color(bc.r, bc.g, bc.b, seg_alpha), band_h, true)

	# --- Corpo do pop-tart (retangulo rosa) ---
	var body_w := 28.0
	var body_h := 22.0
	var body_x := pos.x - body_w / 2.0
	var body_y := pos.y - body_h / 2.0
	# Glacê rosa
	var tart_fill := Color(1.0, 0.6, 0.7, alpha)
	draw_rect(Rect2(body_x, body_y, body_w, body_h), tart_fill)
	draw_rect(Rect2(body_x, body_y, body_w, body_h), Color(1.0, 0.4, 0.5, alpha), false, 1.5)
	# Sprinkles (pontinhos coloridos no tart)
	var sprinkle_cols: Array[Color] = [
		Color(1.0, 0.0, 0.5, alpha), Color(1.0, 1.0, 0.0, alpha),
		Color(0.0, 1.0, 0.5, alpha), Color(0.5, 0.0, 1.0, alpha),
	]
	for si in 6:
		var sx := body_x + 4.0 + fmod(float(si) * 5.3, body_w - 8.0)
		var sy := body_y + 4.0 + fmod(float(si) * 3.7, body_h - 8.0)
		draw_circle(Vector2(sx, sy), 1.5, sprinkle_cols[si % sprinkle_cols.size()])

	# --- Cabeca do gato (lado da direcao) ---
	var head_x := pos.x + dir * 18.0
	var head_y := pos.y
	var head_col := Color(0.6, 0.6, 0.6, alpha)
	# Cabeca quadrada
	draw_rect(Rect2(head_x - 8, head_y - 9, 16, 16), head_col)
	draw_rect(Rect2(head_x - 8, head_y - 9, 16, 16), Color(0.8, 0.8, 0.8, alpha), false, 1.0)
	# Orelhas (triangulos)
	var ear_l := PackedVector2Array([
		Vector2(head_x - 6, head_y - 9),
		Vector2(head_x - 3, head_y - 16),
		Vector2(head_x + 0, head_y - 9),
	])
	var ear_r := PackedVector2Array([
		Vector2(head_x + 0, head_y - 9),
		Vector2(head_x + 3, head_y - 16),
		Vector2(head_x + 6, head_y - 9),
	])
	var ear_cols := PackedColorArray([head_col, head_col, head_col])
	draw_polygon(ear_l, ear_cols)
	draw_polygon(ear_r, ear_cols)
	# Olhos
	draw_circle(Vector2(head_x - 3, head_y - 2), 2.0, Color(0.1, 0.1, 0.1, alpha))
	draw_circle(Vector2(head_x + 3, head_y - 2), 2.0, Color(0.1, 0.1, 0.1, alpha))
	# Boca / focinho
	draw_circle(Vector2(head_x, head_y + 2), 1.5, Color(1.0, 0.5, 0.6, alpha))
	# Bigodes
	var whisker_a := alpha * 0.5
	draw_line(Vector2(head_x - 2, head_y + 1), Vector2(head_x - 12, head_y - 2), Color(0.8, 0.8, 0.8, whisker_a), 1.0, true)
	draw_line(Vector2(head_x - 2, head_y + 2), Vector2(head_x - 12, head_y + 3), Color(0.8, 0.8, 0.8, whisker_a), 1.0, true)
	draw_line(Vector2(head_x + 2, head_y + 1), Vector2(head_x + 12, head_y - 2), Color(0.8, 0.8, 0.8, whisker_a), 1.0, true)
	draw_line(Vector2(head_x + 2, head_y + 2), Vector2(head_x + 12, head_y + 3), Color(0.8, 0.8, 0.8, whisker_a), 1.0, true)

	# --- Patas (animadas) ---
	var paw_col := Color(0.6, 0.6, 0.6, alpha)
	var leg_phase := sin(nyan_anim * 10.0)
	# Patas traseiras
	var back_x := pos.x - dir * 10.0
	draw_rect(Rect2(back_x - 5, pos.y + 10 + leg_phase * 3, 4, 6), paw_col)
	draw_rect(Rect2(back_x + 2, pos.y + 10 - leg_phase * 3, 4, 6), paw_col)
	# Patas dianteiras
	var front_x := pos.x + dir * 6.0
	draw_rect(Rect2(front_x - 5, pos.y + 10 - leg_phase * 3, 4, 6), paw_col)
	draw_rect(Rect2(front_x + 2, pos.y + 10 + leg_phase * 3, 4, 6), paw_col)

	# --- Cauda ---
	var tail_x := pos.x - dir * 22.0
	var tail_wave := sin(nyan_anim * 6.0) * 4.0
	draw_line(Vector2(tail_x, pos.y), Vector2(tail_x - dir * 8, pos.y - 5 + tail_wave), paw_col, 3.0, true)

# --- HORIZONTE ---

func _draw_horizon() -> void:
	var left := -MARGIN
	var right := screen_size.x + MARGIN
	for i in range(40, 0, -1):
		var alpha := 0.02 * (1.0 - float(i) / 40.0)
		var spread := float(i) * 3.0
		draw_line(Vector2(left, horizon_y - spread), Vector2(right, horizon_y - spread), Color(1.0, 0.0, 0.5, alpha), 2.0, true)

	for i in range(20, 0, -1):
		var alpha := 0.03 * (1.0 - float(i) / 20.0)
		var spread := float(i) * 2.0
		draw_line(Vector2(left, horizon_y + spread), Vector2(right, horizon_y + spread), Color(1.0, 0.0, 0.5, alpha), 2.0, true)

	draw_line(Vector2(left, horizon_y), Vector2(right, horizon_y), Color(1.0, 0.3, 0.8, 0.9), 3.0, true)
	draw_line(Vector2(left, horizon_y), Vector2(right, horizon_y), Color(1.0, 0.8, 1.0, 0.5), 1.5, true)

# --- CHAO E GRID ---

func _draw_floor() -> void:
	draw_rect(Rect2(-MARGIN, horizon_y, screen_size.x + MARGIN * 2, screen_size.y - horizon_y + MARGIN), FLOOR_DARK)

func _draw_perspective_grid() -> void:
	var vanish := Vector2(screen_size.x / 2.0, horizon_y)
	var floor_h := screen_size.y - horizon_y
	var bottom := screen_size.y

	var num_lines := 8
	for i in range(-num_lines, num_lines + 1):
		var bottom_x := vanish.x + (float(i) / num_lines) * screen_size.x * 1.2
		var alpha := lerpf(0.7, 0.25, absf(float(i) / num_lines))
		var width := 1.5 if i == 0 else 1.0
		draw_line(vanish, Vector2(bottom_x, bottom), Color(1.0, 0.0, 0.8, alpha * 0.15), width + 4.0, true)
		draw_line(vanish, Vector2(bottom_x, bottom), Color(1.0, 0.0, 0.8, alpha), width, true)

	var num_h_lines := 10
	for i in range(1, num_h_lines + 1):
		var t := float(i) / num_h_lines
		var perspective_t := t * t
		var y := horizon_y + perspective_t * floor_h
		var alpha := lerpf(0.15, 0.6, t)
		var width := lerpf(0.5, 1.5, t)
		draw_line(Vector2(-MARGIN, y), Vector2(screen_size.x + MARGIN, y), Color(1.0, 0.0, 0.8, alpha * 0.2), width + 3.0, true)
		draw_line(Vector2(-MARGIN, y), Vector2(screen_size.x + MARGIN, y), Color(1.0, 0.0, 0.8, alpha), width, true)
