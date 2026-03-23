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

# Dados montanhas (low-poly triangles) — duas camadas
var mountains_back: Array[Dictionary] = []
var mountains_front: Array[Dictionary] = []

# Animacao
var anim_time := 0.0

# Flyby (OVNI, Nyan Cat ou Papai Noel)
enum FlybyType { UFO, NYAN, SANTA }
var flyby_active := false
var flyby_type: FlybyType = FlybyType.UFO
var flyby_x := 0.0
var flyby_y := 0.0
var flyby_speed := 0.0
var flyby_direction := 1.0  # 1 = direita, -1 = esquerda
var flyby_timer := 0.0
var flyby_next_time := 0.0
var nyan_anim := 0.0  # animacao das patas

# Batalha distante no horizonte
var distant_battle := DistantBattle.new()

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
	mountains_back.clear()
	mountains_front.clear()
	# Camada de fundo — picos mais altos, mais distante
	mountains_back = _gen_mountain_ridge(run_seed, 100.0, 320.0, 0.3, 24)
	# Camada da frente — picos um pouco menores, mais proxima
	mountains_front = _gen_mountain_ridge(run_seed + 500, 80.0, 240.0, 0.4, 20)

# Gera uma ridge continua com facetas de relevo
func _gen_mountain_ridge(seed_val: int, min_h: float, max_h: float, envelope_strength: float, num_peaks: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var center_x := screen_size.x / 2.0

	# Gera pontos da ridge (picos alternados com vales)
	var ridge: PackedVector2Array = []
	for i in range(num_peaks + 1):
		var t := float(i) / num_peaks
		var x := lerpf(-MARGIN * 2, screen_size.x + MARGIN * 2, t)
		var dist_from_center := absf(x - center_x) / ((screen_size.x + MARGIN) * 0.5)
		var envelope := 1.0 - dist_from_center * envelope_strength
		envelope = maxf(envelope, 0.3)
		var h := rng.randf_range(min_h, max_h) * envelope
		# Variacao organica: alguns picos altos, planaltos, vales suaves
		var role := rng.randf()
		if role < 0.25:
			# Vale suave
			h *= rng.randf_range(0.15, 0.4)
		elif role < 0.5:
			# Planalto medio
			h *= rng.randf_range(0.5, 0.7)
		elif role < 0.8:
			# Pico normal
			h *= rng.randf_range(0.7, 0.95)
		# else: pico alto (sem reducao)
		var y := horizon_y - h
		ridge.append(Vector2(x, y))

	# Gera camadas de pontos intermediarios entre ridge e horizonte
	# Cada camada e uma sub-ridge com perturbacao, criando malha de facetas
	var num_layers := 4
	var layers: Array[PackedVector2Array] = []
	layers.append(ridge)  # camada 0 = topo
	for li in range(1, num_layers):
		var layer_t := float(li) / num_layers  # 0=topo, 1=base
		var layer: PackedVector2Array = []
		for pi in ridge.size():
			var top_pt := ridge[pi]
			var base_x := top_pt.x + rng.randf_range(-20.0, 20.0)
			var base_y := lerpf(top_pt.y, horizon_y, layer_t)
			base_y += rng.randf_range(-15.0, 15.0)
			base_y = minf(base_y, horizon_y - 2.0)
			base_y = maxf(base_y, top_pt.y)
			layer.append(Vector2(base_x, base_y))
		layers.append(layer)
	# Camada final = horizonte
	var base_layer: PackedVector2Array = []
	for pi in ridge.size():
		base_layer.append(Vector2(ridge[pi].x, horizon_y))
	layers.append(base_layer)

	# Triangula entre camadas adjacentes — cada par de pontos forma 2 triangulos
	var facets: Array[Dictionary] = []  # {"pts": PackedVector2Array, "shade": float}
	for li in layers.size() - 1:
		var upper := layers[li]
		var lower := layers[li + 1]
		for pi in upper.size() - 1:
			var u0 := upper[pi]
			var u1 := upper[pi + 1]
			var l0 := lower[pi]
			var l1 := lower[pi + 1]
			# Triangulo superior
			var shade1 := rng.randf_range(0.01, 0.07)
			facets.append({"pts": PackedVector2Array([u0, u1, l0]), "shade": shade1})
			# Triangulo inferior
			var shade2 := rng.randf_range(0.01, 0.07)
			facets.append({"pts": PackedVector2Array([u1, l1, l0]), "shade": shade2})

	# Pontos de luz espalhados
	var lights: PackedVector2Array = []
	var num_lights := rng.randi_range(4, 10)
	for _li in num_lights:
		var ri := rng.randi_range(0, ridge.size() - 2)
		var a := ridge[ri]
		var b := ridge[ri + 1]
		var lt := rng.randf()
		var lx := lerpf(a.x, b.x, lt)
		var top_at_x := lerpf(a.y, b.y, lt)
		if top_at_x >= horizon_y - 10:
			continue
		var ly := rng.randf_range(top_at_x + 5.0, horizon_y - 5.0)
		lights.append(Vector2(lx, ly))

	# Torres no skyline (Space Needle, antenas, domos)
	var tower_list: Array[Dictionary] = []
	var num_towers := rng.randi_range(3, 6)
	for _ti in num_towers:
		var ri := rng.randi_range(1, ridge.size() - 2)
		var base_pt := ridge[ri]
		if base_pt.y >= horizon_y - 15.0:
			continue
		var tower_h := rng.randf_range(15.0, 50.0)
		var tower_type := rng.randi_range(0, 2)
		tower_list.append({"pos": base_pt, "height": tower_h, "type": tower_type})

	result.append({
		"ridge": ridge,
		"facets": facets,
		"lights": lights,
		"towers": tower_list,
	})
	return result

# ============================================================
# DRAW
# ============================================================

func _process(delta: float) -> void:
	anim_time += delta
	_update_flyby(delta)
	_update_distant_battle(delta)
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_draw_flyby()
	_draw_distant_battle()
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
			var light_alpha := 1.0 if blink_val > 0.3 else 0.15
			draw_circle(Vector2(mid_x, antenna_top), 8.0, Color(1.0, 0.0, 0.3, light_alpha * 0.12))
			draw_circle(Vector2(mid_x, antenna_top), 4.0, Color(1.0, 0.0, 0.3, light_alpha * 0.5))
			draw_circle(Vector2(mid_x, antenna_top), 2.0, Color(1.0, 0.3, 0.5, light_alpha))

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
				var wc := Color(window_color.r, window_color.g, window_color.b, window_color.a * win_alpha_mult * 2.0)
				draw_line(Vector2(wx, top_y + 6.0), Vector2(wx, horizon_y - 4.0), wc, 1.5, true)

# --- MONTANHAS ---

func _draw_mountains() -> void:
	var pulse := (sin(anim_time * 0.5) + 1.0) * 0.5

	# Camada de fundo — picos altos, roxo distante
	var back_outline_alpha := lerpf(0.2, 0.5, pulse)
	var back_glow_alpha := lerpf(0.05, 0.2, pulse)
	_draw_mountain_ridge(mountains_back, Color(0.6, 0.0, 0.8), back_outline_alpha, back_glow_alpha, 0.6)

	# Camada da frente — picos menores, magenta proxima
	var front_outline_alpha := lerpf(0.3, 0.8, pulse)
	var front_glow_alpha := lerpf(0.08, 0.35, pulse)
	_draw_mountain_ridge(mountains_front, Color(1.0, 0.0, 0.6), front_outline_alpha, front_glow_alpha, 1.0)

func _draw_mountain_ridge(layer: Array[Dictionary], base_color: Color, outline_alpha: float, glow_alpha: float, shade_mult: float) -> void:
	for entry in layer:
		var ridge: PackedVector2Array = entry["ridge"]
		var facets: Array = entry["facets"]
		var lights: PackedVector2Array = entry["lights"]

		var edge_col := Color(base_color.r, base_color.g, base_color.b, outline_alpha * 0.2)

		# Facetas — triangulos com shades variados criando relevo
		for facet in facets:
			var pts: PackedVector2Array = facet["pts"]
			var shade: float = facet["shade"] * shade_mult
			var fill := Color(shade, shade * 0.3, shade * 1.5, 1.0)
			draw_polygon(pts, PackedColorArray([fill, fill, fill]))
			# Arestas internas — wireframe sutil
			for ei in 3:
				var a := pts[ei]
				var b := pts[(ei + 1) % 3]
				# Nao desenha aresta na base (horizonte)
				if absf(a.y - horizon_y) < 3.0 and absf(b.y - horizon_y) < 3.0:
					continue
				draw_line(a, b, edge_col, 1.0, true)

		# Pontos de luz — piscam lentamente
		for li in lights.size():
			var lp := lights[li]
			var blink_phase := fmod(float(li) * 2.7, TAU)
			var blink_val := sin(anim_time * 0.6 + blink_phase)
			var light_alpha := 0.6 if blink_val > 0.2 else 0.1
			draw_circle(lp, 4.0, Color(base_color.r, base_color.g, base_color.b, light_alpha * 0.15))
			draw_circle(lp, 2.0, Color(base_color.r, base_color.g, base_color.b, light_alpha * 0.5))
			draw_circle(lp, 1.0, Color(1.0, 0.8, 0.9, light_alpha))

		# Torres no skyline
		var tower_col := Color(base_color.r, base_color.g, base_color.b, outline_alpha * 0.7)
		var tower_glow := Color(base_color.r, base_color.g, base_color.b, glow_alpha * 0.5)
		var tower_list: Array = entry.get("towers", [])
		for tw in tower_list:
			var pos: Vector2 = tw["pos"]
			var th: float = tw["height"]
			var tt: int = tw["type"]
			var top := pos + Vector2(0, -th)
			match tt:
				0:  # Space Needle — haste fina + disco + antena
					draw_line(pos, top, tower_col, 1.5, true)
					var dw := th * 0.3
					draw_line(top + Vector2(-dw, 0), top + Vector2(dw, 0), tower_col, 1.5, true)
					draw_line(top + Vector2(-dw, 0), top + Vector2(-dw * 0.6, 3), tower_col, 1.0, true)
					draw_line(top + Vector2(dw, 0), top + Vector2(dw * 0.6, 3), tower_col, 1.0, true)
					draw_line(top, top + Vector2(0, -th * 0.2), tower_col, 1.0, true)
					draw_circle(top + Vector2(0, -th * 0.2), 1.5, tower_glow)
				1:  # Torre com domo
					draw_line(pos, top + Vector2(0, 4), tower_col, 2.0, true)
					var dr := th * 0.15
					var dome_pts: PackedVector2Array = []
					for di in 7:
						var angle := PI + float(di) / 6.0 * PI
						dome_pts.append(top + Vector2(cos(angle) * dr, sin(angle) * dr + 4))
					for di in dome_pts.size() - 1:
						draw_line(dome_pts[di], dome_pts[di + 1], tower_col, 1.0, true)
				2:  # Antena com travessas
					draw_line(pos, top, tower_col, 1.0, true)
					for bi in 3:
						var bt := 0.3 + float(bi) * 0.2
						var bp := pos.lerp(top, bt)
						var bw := lerpf(th * 0.15, th * 0.06, bt)
						draw_line(bp + Vector2(-bw, 0), bp + Vector2(bw, 0), tower_col, 1.0, true)
					draw_circle(top, 1.5, tower_glow)

		# Outline neon na ridge (silhueta superior — por cima de tudo)
		var glow_col := Color(base_color.r, base_color.g, base_color.b, glow_alpha)
		var outline_col := Color(base_color.r, base_color.g, base_color.b, outline_alpha)
		for i in ridge.size() - 1:
			draw_line(ridge[i], ridge[i + 1], glow_col, 5.0, true)
			draw_line(ridge[i], ridge[i + 1], outline_col, 1.5, true)

# --- BATALHA DISTANTE ---

func _update_distant_battle(delta: float) -> void:
	distant_battle.update(delta, screen_size, horizon_y)

func _draw_distant_battle() -> void:
	distant_battle.draw(self)

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
	# Sorteia tipo (80% UFO, 10% Nyan, 10% Santa)
	var roll := randf()
	if roll < 0.8:
		flyby_type = FlybyType.UFO
		flyby_speed = randf_range(30.0, 80.0)
	elif roll < 0.9:
		flyby_type = FlybyType.NYAN
		flyby_speed = randf_range(80.0, 140.0)
	else:
		flyby_type = FlybyType.SANTA
		flyby_speed = randf_range(60.0, 110.0)
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
	elif flyby_type == FlybyType.NYAN:
		_draw_nyan()
	else:
		_draw_santa()

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

func _draw_santa() -> void:
	var pos := Vector2(flyby_x, flyby_y)
	var alpha := 0.55
	var dir := flyby_direction
	var bounce := sin(nyan_anim * 5.0) * 2.0
	pos.y += bounce

	# --- Renas (2, na frente do treno) ---
	var leg_phase := sin(nyan_anim * 10.0)
	for ri in 2:
		var rx := pos.x + dir * (60.0 + ri * 35.0)
		var ry := pos.y - 2.0 + sin(nyan_anim * 5.0 + ri * 1.5) * 2.0
		var body_col := Color(0.55, 0.3, 0.15, alpha)
		# Corpo
		draw_rect(Rect2(rx - 10, ry - 5, 20, 10), body_col)
		# Cabeca
		var head_x := rx + dir * 12.0
		draw_rect(Rect2(head_x - 4, ry - 8, 8, 8), body_col)
		# Chifres
		var antler_col := Color(0.7, 0.5, 0.2, alpha * 0.8)
		draw_line(Vector2(head_x - 2, ry - 8), Vector2(head_x - 5, ry - 16), antler_col, 1.5, true)
		draw_line(Vector2(head_x - 5, ry - 16), Vector2(head_x - 8, ry - 13), antler_col, 1.5, true)
		draw_line(Vector2(head_x + 2, ry - 8), Vector2(head_x + 5, ry - 16), antler_col, 1.5, true)
		draw_line(Vector2(head_x + 5, ry - 16), Vector2(head_x + 8, ry - 13), antler_col, 1.5, true)
		# Nariz vermelho (Rudolph na primeira rena)
		if ri == 1:
			draw_circle(Vector2(head_x + dir * 5, ry - 5), 2.5, Color(1.0, 0.0, 0.0, alpha))
			draw_circle(Vector2(head_x + dir * 5, ry - 5), 5.0, Color(1.0, 0.0, 0.0, alpha * 0.2))
		# Patas
		var lp := leg_phase if ri % 2 == 0 else -leg_phase
		draw_line(Vector2(rx - 5, ry + 5), Vector2(rx - 5, ry + 12 + lp * 3), body_col, 1.5, true)
		draw_line(Vector2(rx + 5, ry + 5), Vector2(rx + 5, ry + 12 - lp * 3), body_col, 1.5, true)
		# Corda ligando ao treno
		if ri == 0:
			draw_line(Vector2(rx - dir * 10, ry), Vector2(pos.x + dir * 22, pos.y), Color(0.6, 0.5, 0.3, alpha * 0.5), 1.0, true)

	# --- Treno ---
	var sled_col := Color(0.8, 0.0, 0.0, alpha)
	var sled_dark := Color(0.5, 0.0, 0.0, alpha)
	# Base do treno (curvada)
	var sled_pts := PackedVector2Array([
		pos + Vector2(-dir * 25, 8),
		pos + Vector2(-dir * 22, 12),
		pos + Vector2(dir * 22, 12),
		pos + Vector2(dir * 25, 8),
		pos + Vector2(dir * 25, 5),
		pos + Vector2(-dir * 22, 5),
	])
	var sled_cols := PackedColorArray()
	for _i in sled_pts.size():
		sled_cols.append(sled_dark)
	draw_polygon(sled_pts, sled_cols)
	for i in sled_pts.size():
		draw_line(sled_pts[i], sled_pts[(i + 1) % sled_pts.size()], sled_col, 1.5, true)
	# Patins
	draw_line(pos + Vector2(-dir * 24, 13), pos + Vector2(-dir * 28, 15), Color(0.7, 0.7, 0.7, alpha), 2.0, true)
	draw_line(pos + Vector2(-dir * 28, 15), pos + Vector2(dir * 20, 15), Color(0.7, 0.7, 0.7, alpha), 2.0, true)

	# --- Papai Noel ---
	var santa_x := pos.x - dir * 5.0
	var santa_y := pos.y
	# Corpo (casaco vermelho)
	draw_rect(Rect2(santa_x - 8, santa_y - 12, 16, 17), Color(0.9, 0.0, 0.0, alpha))
	# Cinto
	draw_rect(Rect2(santa_x - 8, santa_y + 0, 16, 3), Color(0.1, 0.1, 0.1, alpha))
	draw_rect(Rect2(santa_x - 2, santa_y - 1, 4, 5), Color(1.0, 0.85, 0.0, alpha))
	# Cabeca
	draw_circle(Vector2(santa_x, santa_y - 16), 7.0, Color(0.95, 0.75, 0.6, alpha))
	# Barba branca
	var beard_pts := PackedVector2Array([
		Vector2(santa_x - 6, santa_y - 13),
		Vector2(santa_x, santa_y - 7),
		Vector2(santa_x + 6, santa_y - 13),
	])
	var beard_cols := PackedColorArray([
		Color(1.0, 1.0, 1.0, alpha), Color(1.0, 1.0, 1.0, alpha), Color(1.0, 1.0, 1.0, alpha),
	])
	draw_polygon(beard_pts, beard_cols)
	# Gorro
	var hat_pts := PackedVector2Array([
		Vector2(santa_x - 7, santa_y - 19),
		Vector2(santa_x + dir * 10, santa_y - 30),
		Vector2(santa_x + 7, santa_y - 19),
	])
	var hat_cols := PackedColorArray([
		Color(0.9, 0.0, 0.0, alpha), Color(0.9, 0.0, 0.0, alpha), Color(0.9, 0.0, 0.0, alpha),
	])
	draw_polygon(hat_pts, hat_cols)
	# Pompom
	draw_circle(Vector2(santa_x + dir * 10, santa_y - 30), 3.0, Color(1.0, 1.0, 1.0, alpha))
	# Borda do gorro
	draw_line(Vector2(santa_x - 8, santa_y - 19), Vector2(santa_x + 8, santa_y - 19), Color(1.0, 1.0, 1.0, alpha), 3.0, true)
	# Olhos
	draw_circle(Vector2(santa_x - 3, santa_y - 17), 1.0, Color(0.1, 0.1, 0.1, alpha))
	draw_circle(Vector2(santa_x + 3, santa_y - 17), 1.0, Color(0.1, 0.1, 0.1, alpha))

	# --- Saco de presentes ---
	var bag_x := pos.x - dir * 16.0
	var bag_col := Color(0.5, 0.2, 0.0, alpha)
	draw_circle(Vector2(bag_x, santa_y - 10), 10.0, bag_col)
	draw_circle(Vector2(bag_x, santa_y - 10), 10.0, Color(0.6, 0.3, 0.1, alpha * 0.5))
	# Amarro do saco
	draw_line(Vector2(bag_x - 2, santa_y - 19), Vector2(bag_x + 2, santa_y - 22), Color(0.6, 0.5, 0.2, alpha), 1.5, true)

	# --- Estrelinhas caindo (presentes?) ---
	var sparkle_cols: Array[Color] = [
		Color(1.0, 1.0, 0.0, alpha * 0.5),
		Color(1.0, 0.0, 0.0, alpha * 0.4),
		Color(0.0, 1.0, 0.3, alpha * 0.4),
	]
	for si in 5:
		var st := fmod(nyan_anim * 1.5 + float(si) * 1.3, 3.0)
		var sx := pos.x - dir * (10.0 + si * 15.0)
		var sy := pos.y + 18.0 + st * 20.0
		var sa := (1.0 - st / 3.0) * alpha * 0.6
		if sa < 0.02:
			continue
		var sc := sparkle_cols[si % sparkle_cols.size()]
		draw_circle(Vector2(sx, sy), 2.0, Color(sc.r, sc.g, sc.b, sa))
		draw_circle(Vector2(sx, sy), 4.0, Color(sc.r, sc.g, sc.b, sa * 0.3))

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

	var num_lines := 6
	var extra_lines := 4  # linhas extras fora da tela pra cobrir todo o chao
	for i in range(-num_lines - extra_lines, num_lines + extra_lines + 1):
		var bottom_x := vanish.x + (float(i) / num_lines) * screen_size.x * 1.2
		var alpha := lerpf(0.7, 0.15, clampf(absf(float(i) / num_lines), 0.0, 1.0))
		var width := 1.5 if i == 0 else 1.0
		draw_line(vanish, Vector2(bottom_x, bottom), Color(1.0, 0.0, 0.8, alpha * 0.15), width + 4.0, true)
		draw_line(vanish, Vector2(bottom_x, bottom), Color(1.0, 0.0, 0.8, alpha), width, true)

	var num_h_lines := 6
	for i in range(1, num_h_lines + 1):
		var t := float(i) / num_h_lines
		var perspective_t := t * t
		var y := horizon_y + perspective_t * floor_h
		var alpha := lerpf(0.15, 0.6, t)
		var width := lerpf(0.5, 1.5, t)
		draw_line(Vector2(-MARGIN, y), Vector2(screen_size.x + MARGIN, y), Color(1.0, 0.0, 0.8, alpha * 0.2), width + 3.0, true)
		draw_line(Vector2(-MARGIN, y), Vector2(screen_size.x + MARGIN, y), Color(1.0, 0.0, 0.8, alpha), width, true)
