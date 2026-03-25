extends Node2D

var screen_size: Vector2
var horizon_y: float
const MARGIN := 200.0  # margem extra pra cobrir qualquer tela

# Cores do gradiente do ceu (via tema)
var SKY_TOP: Color:
	get: return Themes.c("sky_top")
var SKY_MID: Color:
	get: return Themes.c("sky_mid")
var SKY_HORIZON: Color:
	get: return Themes.c("sky_horizon")

# Cores do grid (via tema)
var FLOOR_DARK: Color:
	get: return Themes.c("floor_dark")

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
enum FlybyType { UFO, NYAN, SANTA, INVADER, DOGFIGHT }
var flyby_active := false
var flyby_type: FlybyType = FlybyType.UFO
var flyby_x := 0.0
var flyby_y := 0.0
var flyby_speed := 0.0
var flyby_direction := 1.0  # 1 = direita, -1 = esquerda
var flyby_timer := 0.0
var flyby_next_time := 0.0
var nyan_anim := 0.0  # animacao das patas
var invader_color := Color(0.0, 1.0, 0.0)  # cor neon aleatoria do invader

# Dogfight (caca vs disco voador)
enum DogfightPhase { CHASE1, OFFSCREEN, CHASE2, SHOOT, FALLING, DONE }
var dogfight_phase: DogfightPhase = DogfightPhase.CHASE1
var dogfight_timer := 0.0
var dogfight_jet_x := 0.0  # posicao do caca (atras do ufo)
var dogfight_ufo_vy := 0.0  # velocidade vertical do ufo caindo
var dogfight_ufo_y := 0.0   # y do ufo durante queda
var dogfight_ufo_scale := 1.0  # escala diminuindo na queda
var dogfight_explosion_timer := 0.0

# Batalha distante no horizonte
var distant_battle := DistantBattle.new()

# Code rain (Hacker theme)
var _rain_columns: Array[Dictionary] = []
const RAIN_CHARS := "01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"

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

	_generate_rain_columns()
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
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_sky()
		return
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
	if Themes.mode == ThemeSystem.Mode.HACKER:
		_draw_code_rain()

# --- CIDADE ---

func _draw_city() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_city()
		return
	_draw_building_layer(skyline_back, Themes.c("building_back_fill"), Themes.c("building_back_outline"), Themes.c("building_back_window"))
	_draw_building_layer(skyline_front, Themes.c("building_front_fill"), Themes.c("building_front_outline"), Themes.c("building_front_window"))

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
			draw_circle(Vector2(mid_x, antenna_top), 8.0, Themes.glow("warning", light_alpha * 0.12))
			draw_circle(Vector2(mid_x, antenna_top), 4.0, Themes.c("warning", light_alpha * 0.5))
			draw_circle(Vector2(mid_x, antenna_top), 2.0, Themes.c("warning", light_alpha))

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
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_mountains()
		return
	var pulse := (sin(anim_time * 0.5) + 1.0) * 0.5

	# Camada de fundo — picos altos, roxo distante
	var back_outline_alpha := lerpf(0.2, 0.5, pulse)
	var back_glow_alpha := lerpf(0.05, 0.2, pulse)
	_draw_mountain_ridge(mountains_back, Themes.c("mountain_back"), back_outline_alpha, back_glow_alpha, 0.6)

	# Camada da frente — picos menores, magenta proxima
	var front_outline_alpha := lerpf(0.3, 0.8, pulse)
	var front_glow_alpha := lerpf(0.08, 0.35, pulse)
	_draw_mountain_ridge(mountains_front, Themes.c("mountain_front"), front_outline_alpha, front_glow_alpha, 1.0)

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
		nyan_anim += delta
		if flyby_type == FlybyType.DOGFIGHT:
			_update_dogfight(delta)
			return
		flyby_x += flyby_speed * flyby_direction * delta
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

func _update_dogfight(delta: float) -> void:
	dogfight_timer += delta
	var d := flyby_direction
	match dogfight_phase:
		DogfightPhase.CHASE1:
			# Primeira passada — UFO foge, caca persegue vindo de fora da tela
			flyby_x += flyby_speed * d * delta
			# Caca um pouco mais rapido pra ir se aproximando
			dogfight_jet_x += flyby_speed * 1.15 * d * delta
			var exit_x := screen_size.x + MARGIN + 100
			if (d > 0 and flyby_x > exit_x) or (d < 0 and flyby_x < -MARGIN - 100):
				dogfight_phase = DogfightPhase.OFFSCREEN
				dogfight_timer = 0.0
		DogfightPhase.OFFSCREEN:
			# Breve pausa fora da tela, inverte direcao
			if dogfight_timer > 0.8:
				flyby_direction = -d
				var new_d := flyby_direction
				# UFO na frente, caca bem atras (~150px = 3-4 cacas de distancia)
				flyby_x = (screen_size.x + MARGIN + 80) if new_d < 0 else (-MARGIN - 80)
				dogfight_jet_x = flyby_x - 150.0 * new_d  # caca 150px atras do UFO
				dogfight_phase = DogfightPhase.CHASE2
				dogfight_timer = 0.0
		DogfightPhase.CHASE2:
			# Segunda passada — voltam mantendo distancia
			var new_d := flyby_direction
			flyby_x += flyby_speed * new_d * delta
			# Caca acompanha na mesma velocidade (mantem distancia ~150px)
			dogfight_jet_x += flyby_speed * new_d * delta
			# Quando UFO chega no meio da tela, dispara
			var mid := screen_size.x * 0.5
			if (new_d > 0 and flyby_x > mid) or (new_d < 0 and flyby_x < mid):
				dogfight_phase = DogfightPhase.SHOOT
				dogfight_timer = 0.0
				dogfight_ufo_y = flyby_y
				dogfight_ufo_vy = 0.0
				dogfight_ufo_scale = 1.0
				dogfight_explosion_timer = 0.4
		DogfightPhase.SHOOT:
			# Flash de explosão + UFO começa a cair, caca acelera
			var new_d := flyby_direction
			# Caca mantem velocidade normal ate explosao acabar, depois acelera
			var jet_mult := 1.0 if dogfight_explosion_timer > 0.0 else 1.6
			dogfight_jet_x += flyby_speed * jet_mult * new_d * delta
			dogfight_explosion_timer -= delta
			dogfight_ufo_vy += 60.0 * delta  # gravidade
			dogfight_ufo_y += dogfight_ufo_vy * delta
			# Deriva lateral na direcao que estava indo
			flyby_x += flyby_speed * 0.6 * new_d * delta
			dogfight_ufo_scale = maxf(dogfight_ufo_scale - 0.08 * delta, 0.15)
			# Quando o ufo passa do horizonte
			if dogfight_ufo_y > horizon_y:
				dogfight_phase = DogfightPhase.FALLING
				dogfight_timer = 0.0
		DogfightPhase.FALLING:
			# Caca acelera pra sair da tela, UFO sumiu
			var new_d := flyby_direction
			dogfight_jet_x += flyby_speed * 2.5 * new_d * delta
			var exit_x := screen_size.x + MARGIN + 100
			if (new_d > 0 and dogfight_jet_x > exit_x) or (new_d < 0 and dogfight_jet_x < -MARGIN - 100):
				dogfight_phase = DogfightPhase.DONE
				flyby_active = false
				flyby_next_time = randf_range(20.0, 50.0)
				flyby_timer = 0.0
		DogfightPhase.DONE:
			flyby_active = false

func _spawn_flyby() -> void:
	flyby_active = true
	flyby_y = randf_range(horizon_y * 0.15, horizon_y * 0.55)
	nyan_anim = 0.0
	# Probabilidades: 5% cada especial, 80% UFO
	var roll := randf() * 100.0
	if roll < 5.0:
		flyby_type = FlybyType.NYAN
	elif roll < 10.0:
		flyby_type = FlybyType.SANTA
	elif roll < 15.0:
		flyby_type = FlybyType.INVADER
	elif roll < 20.0:
		flyby_type = FlybyType.DOGFIGHT
	else:
		flyby_type = FlybyType.UFO
	flyby_speed = randf_range(80.0, 120.0)
	if flyby_type == FlybyType.INVADER:
		flyby_speed = randf_range(40.0, 90.0)
		var neon_colors := [Color(1,0,0.3), Color(0,1,0.3), Color(0.3,0.5,1), Color(1,1,0), Color(1,0,1), Color(0,1,1)]
		invader_color = neon_colors[randi() % neon_colors.size()]
	if flyby_type == FlybyType.DOGFIGHT:
		dogfight_phase = DogfightPhase.CHASE1
		dogfight_timer = 0.0
		dogfight_explosion_timer = 0.0
	# Direcao aleatoria
	if randf() > 0.5:
		flyby_direction = 1.0
		flyby_x = -MARGIN - 100
	else:
		flyby_direction = -1.0
		flyby_x = screen_size.x + MARGIN + 100
	if flyby_type == FlybyType.DOGFIGHT:
		# Caca comeca ~350px atras — entra na tela visivelmente depois do UFO
		dogfight_jet_x = flyby_x - 350.0 * flyby_direction

func _draw_flyby() -> void:
	if not flyby_active:
		return
	if flyby_type == FlybyType.UFO:
		_draw_ufo()
	elif flyby_type == FlybyType.NYAN:
		_draw_nyan()
	elif flyby_type == FlybyType.SANTA:
		_draw_santa()
	elif flyby_type == FlybyType.INVADER:
		_draw_invader()
	elif flyby_type == FlybyType.DOGFIGHT:
		_draw_dogfight()

func _draw_ufo() -> void:
	_draw_ufo_at(Vector2(flyby_x, flyby_y), 0.7, 1.0)

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

func _draw_invader() -> void:
	var pos := Vector2(flyby_x, flyby_y)
	var d := flyby_direction
	var bounce := sin(nyan_anim * 3.0) * 5.0
	pos.y += bounce
	var alpha := clampf(1.0 - abs(flyby_x - screen_size.x * 0.5) / (screen_size.x * 0.8), 0.2, 1.0)
	var col := Color(invader_color.r, invader_color.g, invader_color.b, alpha)
	var col_dim := Color(invader_color.r, invader_color.g, invader_color.b, alpha * 0.3)
	var s := 4.0  # pixel scale
	# Dois frames alternando (patas abertas/fechadas)
	var frame := int(nyan_anim * 2.0) % 2
	# Grid 11x8 — 1 = pixel preenchido
	var frame0 := [
		[0,0,1,0,0,0,0,0,1,0,0],
		[0,0,0,1,0,0,0,1,0,0,0],
		[0,0,1,1,1,1,1,1,1,0,0],
		[0,1,1,0,1,1,1,0,1,1,0],
		[1,1,1,1,1,1,1,1,1,1,1],
		[1,0,1,1,1,1,1,1,1,0,1],
		[1,0,1,0,0,0,0,0,1,0,1],
		[0,0,0,1,1,0,1,1,0,0,0],
	]
	var frame1 := [
		[0,0,1,0,0,0,0,0,1,0,0],
		[1,0,0,1,0,0,0,1,0,0,1],
		[1,0,1,1,1,1,1,1,1,0,1],
		[1,1,1,0,1,1,1,0,1,1,1],
		[1,1,1,1,1,1,1,1,1,1,1],
		[0,1,1,1,1,1,1,1,1,1,0],
		[0,0,1,0,0,0,0,0,1,0,0],
		[0,1,0,0,0,0,0,0,0,1,0],
	]
	var grid: Array = frame0 if frame == 0 else frame1
	var offset_x := -5.5 * s  # centrar horizontalmente
	var offset_y := -4.0 * s  # centrar verticalmente
	# Glow
	draw_circle(pos, 30.0, Color(invader_color.r, invader_color.g, invader_color.b, alpha * 0.06))
	for row in 8:
		for col_idx in 11:
			if grid[row][col_idx] == 1:
				var px := pos.x + (col_idx * d) * s + offset_x * d
				var py := pos.y + row * s + offset_y
				draw_rect(Rect2(px, py, s * d, s), col, true)
	# Outline sutil
	for row in 8:
		for col_idx in 11:
			if grid[row][col_idx] == 1:
				var px := pos.x + (col_idx * d) * s + offset_x * d
				var py := pos.y + row * s + offset_y
				draw_rect(Rect2(px - 0.5, py - 0.5, s * d + 1.0, s + 1.0), col_dim, false, 1.0)

func _draw_jet(jpos: Vector2, d: float, alpha: float) -> void:
	var s := 0.8  # escala do aviao
	var neon := Color(0.3, 0.6, 1.0, alpha)
	var neon_dim := Color(0.3, 0.6, 1.0, alpha * 0.4)
	var fill := Color(0.02, 0.04, 0.1, alpha * 0.6)
	var hot := Color(1.0, 0.5, 0.1, alpha * 0.6)
	# Fuselagem lateral — perfil de caca F-16 style
	var body := PackedVector2Array([
		jpos + Vector2(28.0 * s * d, -1.0 * s),
		jpos + Vector2(18.0 * s * d, -4.0 * s),
		jpos + Vector2(4.0 * s * d, -5.0 * s),
		jpos + Vector2(-6.0 * s * d, -4.0 * s),
		jpos + Vector2(-22.0 * s * d, -5.0 * s),
		jpos + Vector2(-26.0 * s * d, -4.0 * s),
		jpos + Vector2(-26.0 * s * d, 3.0 * s),
		jpos + Vector2(-14.0 * s * d, 4.0 * s),
		jpos + Vector2(10.0 * s * d, 3.0 * s),
		jpos + Vector2(22.0 * s * d, 1.0 * s),
	])
	draw_polygon(body, PackedColorArray([fill, fill, fill, fill, fill, fill, fill, fill, fill, fill]))
	for i in body.size():
		draw_line(body[i], body[(i + 1) % body.size()], neon, 1.5, true)
	# Cockpit (bolha de vidro)
	var cockpit := PackedVector2Array([
		jpos + Vector2(10.0 * s * d, -5.0 * s),
		jpos + Vector2(4.0 * s * d, -9.0 * s),
		jpos + Vector2(-4.0 * s * d, -8.0 * s),
		jpos + Vector2(-6.0 * s * d, -4.0 * s),
	])
	draw_polygon(cockpit, PackedColorArray([
		Color(0.1, 0.3, 0.5, alpha * 0.4), Color(0.1, 0.3, 0.5, alpha * 0.4),
		Color(0.1, 0.3, 0.5, alpha * 0.4), Color(0.1, 0.3, 0.5, alpha * 0.4)]))
	for i in cockpit.size():
		draw_line(cockpit[i], cockpit[(i + 1) % cockpit.size()], Color(0.5, 0.8, 1.0, alpha * 0.7), 1.0, true)
	# Asa delta (vista lateral = triangulo fino abaixo da fuselagem)
	var wing := PackedVector2Array([
		jpos + Vector2(2.0 * s * d, 4.0 * s),
		jpos + Vector2(-16.0 * s * d, 12.0 * s),
		jpos + Vector2(-18.0 * s * d, 4.0 * s),
	])
	draw_polygon(wing, PackedColorArray([fill, fill, fill]))
	for i in wing.size():
		draw_line(wing[i], wing[(i + 1) % wing.size()], neon_dim, 1.0, true)
	# Estabilizador vertical (cauda)
	var stab := PackedVector2Array([
		jpos + Vector2(-22.0 * s * d, -5.0 * s),
		jpos + Vector2(-24.0 * s * d, -16.0 * s),
		jpos + Vector2(-28.0 * s * d, -14.0 * s),
		jpos + Vector2(-26.0 * s * d, -4.0 * s),
	])
	draw_polygon(stab, PackedColorArray([fill, fill, fill, fill]))
	for i in stab.size():
		draw_line(stab[i], stab[(i + 1) % stab.size()], neon, 1.0, true)
	# Exaustão — glow laranja/azul atras
	var exhaust := jpos + Vector2(-27.0 * s * d, 0.0)
	var pulse := 0.5 + 0.5 * sin(nyan_anim * 15.0)
	var flame_len := (8.0 + pulse * 6.0) * s
	var flame_tip := exhaust + Vector2(-flame_len * d, 0.0)
	draw_line(exhaust, flame_tip, Color(0.3, 0.6, 1.0, alpha * 0.5), 3.0, true)
	draw_line(exhaust, flame_tip, hot, 5.0, true)
	draw_circle(exhaust, 3.0 * s, Color(1.0, 0.8, 0.3, alpha * 0.6))

func _draw_dogfight() -> void:
	var d := flyby_direction
	var alpha := 0.7
	# Desenha UFO (exceto quando ja caiu)
	if dogfight_phase != DogfightPhase.FALLING and dogfight_phase != DogfightPhase.DONE:
		var ufo_pos := Vector2(flyby_x, flyby_y)
		if dogfight_phase == DogfightPhase.SHOOT:
			ufo_pos.y = dogfight_ufo_y
			# UFO diminuindo — simular com offset e alpha
			var sc := dogfight_ufo_scale
			var ufo_alpha := alpha * sc
			# Fumaca/explosao
			if dogfight_explosion_timer > 0.0:
				var flash_a := dogfight_explosion_timer * 2.0
				draw_circle(ufo_pos, 30.0, Color(1.0, 0.6, 0.1, flash_a * 0.4))
				draw_circle(ufo_pos, 15.0, Color(1.0, 0.9, 0.5, flash_a * 0.6))
			# Trail de fumaca — sobe pra tras do UFO
			for si in 8:
				var st := fmod(nyan_anim * 1.5 + float(si) * 0.4, 3.0)
				var sx := ufo_pos.x - st * 12.0 * d + sin(nyan_anim * 2.0 + float(si)) * 4.0
				var sy := ufo_pos.y - st * 20.0
				var sa := (1.0 - st / 3.0) * ufo_alpha * 0.5
				var sr := 3.0 + st * 3.0  # fumaca expande conforme sobe
				if sa > 0.02:
					draw_circle(Vector2(sx, sy), sr, Color(0.4, 0.4, 0.4, sa))
					draw_circle(Vector2(sx, sy), sr * 0.5, Color(0.6, 0.3, 0.1, sa * 0.3))
			# UFO menor (simulado desenhando o UFO normal com escala visual reduzida)
			_draw_ufo_at(ufo_pos, ufo_alpha, sc)
		else:
			_draw_ufo_at(ufo_pos, alpha, 1.0)
	# Desenha caca
	var jet_pos := Vector2(dogfight_jet_x, flyby_y)
	var jet_alpha := alpha
	if dogfight_phase == DogfightPhase.SHOOT and dogfight_explosion_timer > 0.1:
		# Laser/traco do tiro
		var shot_start := jet_pos + Vector2(22.0 * d, 0.0)
		var shot_end := Vector2(flyby_x, dogfight_ufo_y)
		draw_line(shot_start, shot_end, Color(1.0, 0.3, 0.1, 0.8), 2.0, true)
		draw_line(shot_start, shot_end, Color(1.0, 0.8, 0.3, 0.3), 4.0, true)
	_draw_jet(jet_pos, d, jet_alpha)

func _draw_ufo_at(pos: Vector2, alpha: float, sc: float) -> void:
	var neon := Color(0.5, 1.0, 0.8)
	var fill := Color(0.02, 0.06, 0.05, alpha * 0.5)
	# Glow externo
	draw_circle(pos, 45.0 * sc, Color(neon.r, neon.g, neon.b, 0.04 * alpha))
	# Corpo — disco achatado
	var body_rx := 35.0 * sc
	var body_ry := 10.0 * sc
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 16:
		var angle := TAU * float(i) / 16
		pts.append(pos + Vector2(cos(angle) * body_rx, sin(angle) * body_ry))
		cols.append(fill)
	draw_polygon(pts, cols)
	for i in 16:
		draw_line(pts[i], pts[(i + 1) % 16], Color(neon.r, neon.g, neon.b, alpha), 2.0 * sc, true)
	# Cupula
	var dome_pts := PackedVector2Array()
	var dome_cols := PackedColorArray()
	dome_pts.append(pos + Vector2(-16 * sc, 0))
	dome_cols.append(fill)
	for i in 9:
		var angle := PI + PI * float(i) / 8
		dome_pts.append(pos + Vector2(cos(angle) * 16 * sc, sin(angle) * 10 * sc - 5 * sc))
		dome_cols.append(fill)
	dome_pts.append(pos + Vector2(16 * sc, 0))
	dome_cols.append(fill)
	draw_polygon(dome_pts, dome_cols)
	for i in dome_pts.size() - 1:
		draw_line(dome_pts[i], dome_pts[i + 1], Color(neon.r, neon.g, neon.b, alpha * 0.8), 1.0 * sc, true)
	# Janelas
	for wi in 3:
		var wx := -8.0 + wi * 8.0
		draw_circle(pos + Vector2(wx * sc, -6 * sc), 2.0 * sc, Color(neon.r, neon.g, neon.b, alpha * 0.7))
	# Luzes pulsantes
	var light_pulse := (sin(anim_time * 2.5) + 1.0) * 0.5
	var light_a := lerpf(0.2, 0.7, light_pulse) * alpha
	for li in 3:
		var lx := -14.0 + li * 14.0
		draw_circle(pos + Vector2(lx * sc, 8 * sc), 3.5 * sc, Color(neon.r, neon.g, neon.b, light_a))

# --- HORIZONTE ---

func _draw_horizon() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_horizon()
		return
	var left := -MARGIN
	var right := screen_size.x + MARGIN
	var h_col := Themes.c("horizon_line")
	for i in range(40, 0, -1):
		var alpha := 0.02 * (1.0 - float(i) / 40.0)
		var spread := float(i) * 3.0
		draw_line(Vector2(left, horizon_y - spread), Vector2(right, horizon_y - spread), Color(h_col.r, h_col.g, h_col.b, alpha), 2.0, true)

	for i in range(20, 0, -1):
		var alpha := 0.03 * (1.0 - float(i) / 20.0)
		var spread := float(i) * 2.0
		draw_line(Vector2(left, horizon_y + spread), Vector2(right, horizon_y + spread), Color(h_col.r, h_col.g, h_col.b, alpha), 2.0, true)

	draw_line(Vector2(left, horizon_y), Vector2(right, horizon_y), Color(h_col.r, h_col.g, h_col.b, 0.9), 3.0, true)
	draw_line(Vector2(left, horizon_y), Vector2(right, horizon_y), Color(minf(h_col.r + 0.3, 1.0), minf(h_col.g + 0.3, 1.0), minf(h_col.b + 0.3, 1.0), 0.5), 1.5, true)

# --- CHAO E GRID ---

func _draw_floor() -> void:
	draw_rect(Rect2(-MARGIN, horizon_y, screen_size.x + MARGIN * 2, screen_size.y - horizon_y + MARGIN), FLOOR_DARK)

func _draw_perspective_grid() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_grid()
		return
	var vanish := Vector2(screen_size.x / 2.0, horizon_y)
	var floor_h := screen_size.y - horizon_y
	var bottom := screen_size.y

	var g_col := Themes.c("horizon_line")
	var num_lines := 6
	var extra_lines := 4  # linhas extras fora da tela pra cobrir todo o chao
	for i in range(-num_lines - extra_lines, num_lines + extra_lines + 1):
		var bottom_x := vanish.x + (float(i) / num_lines) * screen_size.x * 1.2
		var alpha := lerpf(0.7, 0.15, clampf(absf(float(i) / num_lines), 0.0, 1.0))
		var width := 1.5 if i == 0 else 1.0
		draw_line(vanish, Vector2(bottom_x, bottom), Color(g_col.r, g_col.g, g_col.b, alpha * 0.15), width + 4.0, true)
		draw_line(vanish, Vector2(bottom_x, bottom), Color(g_col.r, g_col.g, g_col.b, alpha), width, true)

	var num_h_lines := 6
	for i in range(1, num_h_lines + 1):
		var t := float(i) / num_h_lines
		var perspective_t := t * t
		var y := horizon_y + perspective_t * floor_h
		var alpha := lerpf(0.15, 0.6, t)
		var width := lerpf(0.5, 1.5, t)
		draw_line(Vector2(-MARGIN, y), Vector2(screen_size.x + MARGIN, y), Color(g_col.r, g_col.g, g_col.b, alpha * 0.2), width + 3.0, true)
		draw_line(Vector2(-MARGIN, y), Vector2(screen_size.x + MARGIN, y), Color(g_col.r, g_col.g, g_col.b, alpha), width, true)

# ============================================================
# ASCII DRAWING MODES
# ============================================================

func _draw_ascii_sky() -> void:
	var font := ThemeDB.fallback_font
	# Fill sky with solid color
	draw_rect(Rect2(-MARGIN, 0, screen_size.x + MARGIN * 2, horizon_y), Themes.c("sky_top"))
	# Scattered "." as stars using anim_time seeded positions
	var star_col := Themes.c("primary", 0.1)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(anim_time * 0.1) * 1000 + 42
	var num_stars := 60
	for i in num_stars:
		var sx := rng.randf_range(0.0, screen_size.x)
		var sy := rng.randf_range(20.0, horizon_y - 20.0)
		draw_string(font, Vector2(sx, sy), ".", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, star_col)

func _draw_ascii_city() -> void:
	var font := ThemeDB.fallback_font
	var col := Themes.c("building_front_outline")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	var x := 0.0
	while x < screen_size.x:
		var bw := rng.randf_range(30.0, 70.0)
		var bh := rng.randf_range(3, 8)
		var gap := rng.randf_range(5.0, 15.0)
		# Draw building as stacked "#" columns
		for row in bh:
			var y := horizon_y - float(row) * 16.0
			var num_chars := int(bw / 14.0)
			for c_i in num_chars:
				draw_string(font, Vector2(x + float(c_i) * 14.0, y), "#", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
		x += bw + gap

func _draw_ascii_mountains() -> void:
	var font := ThemeDB.fallback_font
	var col := Themes.c("mountain_front")
	var rng := RandomNumberGenerator.new()
	rng.seed = 8888
	var x := 0.0
	while x < screen_size.x:
		var peak_w := rng.randf_range(60.0, 140.0)
		var peak_h := rng.randf_range(3, 7)
		var center_x := x + peak_w / 2.0
		# Draw /\ mountain shape
		for row in peak_h:
			var y := horizon_y - float(peak_h - row) * 16.0
			var half := row + 1
			# Left slope "/"
			draw_string(font, Vector2(center_x - float(half) * 10.0, y), "/", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
			# Right slope "\"
			draw_string(font, Vector2(center_x + float(half) * 10.0 - 10.0, y), "\\", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
		x += peak_w

func _draw_ascii_horizon() -> void:
	var font := ThemeDB.fallback_font
	var col := Themes.c("horizon_line")
	var char_w := font.get_string_size("=", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var x := -MARGIN
	while x < screen_size.x + MARGIN:
		draw_string(font, Vector2(x, horizon_y + 4.0), "=", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
		x += char_w

func _draw_ascii_grid() -> void:
	var font := ThemeDB.fallback_font
	var col := Themes.c("horizon_line", 0.2)
	var floor_h := screen_size.y - horizon_y
	var rng := RandomNumberGenerator.new()
	rng.seed = 9999
	var num_dots := 40
	for i in num_dots:
		var dx := rng.randf_range(0.0, screen_size.x)
		var dy := horizon_y + rng.randf_range(10.0, floor_h - 10.0)
		draw_string(font, Vector2(dx, dy), ".", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)

# ============================================================
# CODE RAIN (Hacker theme)
# ============================================================

func _generate_rain_columns() -> void:
	_rain_columns.clear()
	var col_w := 24.0
	var num_cols := int(screen_size.x / col_w) + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in num_cols:
		var num_streams := rng.randi_range(2, 3)
		for s in num_streams:
			_rain_columns.append({
				"x": float(i) * col_w,
				"speed": rng.randf_range(50.0, 150.0),
				"length": rng.randi_range(8, 16),
				"offset": rng.randf_range(0.0, 2000.0),
				"char_seed": rng.randi(),
			})

func _draw_code_rain() -> void:
	var font := ThemeDB.fallback_font
	var fs := 14
	var char_h := 16.0
	var max_y := horizon_y
	var green := Color(0.0, 1.0, 0.0)
	var wrap_h: float = max_y + 500.0
	# Pre-compute chars per column to avoid RNG per char
	var rng := RandomNumberGenerator.new()
	for col in _rain_columns:
		var head_y: float = fmod(col["offset"] + anim_time * col["speed"], wrap_h) - 300.0
		# Skip entire stream if fully off-screen
		var tail_y: float = head_y + col["length"] * char_h
		if tail_y < 0.0 or head_y > max_y:
			continue
		rng.seed = col["char_seed"] + int(head_y * 0.08)
		var stream_len: int = col["length"]
		# Clamp draw range to visible area
		var j_start := maxi(0, int((-head_y) / char_h))
		var j_end := mini(stream_len, int((max_y - head_y) / char_h) + 1)
		# Advance RNG to j_start
		for _skip in j_start:
			rng.randi()
		for j in range(j_start, j_end):
			var cy: float = head_y + j * char_h
			var t := float(j) / float(stream_len)
			var alpha := lerpf(0.8, 0.03, t)
			var ch := RAIN_CHARS[rng.randi() % RAIN_CHARS.length()]
			var c := Color(0.7, 1.0, 0.7, 0.95) if j == 0 else Color(green.r, green.g, green.b, alpha)
			draw_string(font, Vector2(col["x"], cy), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
