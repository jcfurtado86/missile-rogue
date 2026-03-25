extends Node2D

var lifetime := 4.0
var elapsed := 0.0

var RING_COLORS: Array[Color]:
	get: return Themes.get_explosion_colors()

# Destrocos grandes (estilhacos angulares)
var debris: Array[Dictionary] = []
# Chuva de particulas pequenas
var sparks: Array[Dictionary] = []
# Ondas de choque
var shockwaves: Array[float] = []

func _ready() -> void:
	# Destrocos grandes — 60 estilhacos
	for i in 60:
		var angle := randf() * TAU
		var spd := randf_range(80.0, 600.0)
		var sz := randf_range(4.0, 14.0)
		var col := RING_COLORS[randi() % RING_COLORS.size()]
		var rot_speed := randf_range(-6.0, 6.0)
		debris.append({
			"vel": Vector2(cos(angle) * spd, sin(angle) * spd - randf_range(50, 200)),
			"size": sz,
			"color": col,
			"rot": 0.0,
			"rot_speed": rot_speed,
		})
	# Chuva de particulas — 120 faiscas pequenas
	for i in 120:
		var angle := randf() * TAU
		var spd := randf_range(40.0, 350.0)
		var sz := randf_range(1.5, 5.0)
		var col := RING_COLORS[randi() % RING_COLORS.size()]
		# Delay escalonado pra criar efeito de chuva continua
		var delay := randf_range(0.0, 1.0)
		sparks.append({
			"vel": Vector2(cos(angle) * spd, sin(angle) * spd - randf_range(30, 250)),
			"size": sz,
			"color": col,
			"delay": delay,
		})
	# 5 ondas de choque escalonadas
	shockwaves = [0.0, 0.2, 0.5, 0.8, 1.2]

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	# Gravidade nos destrocos
	for d in debris:
		d["vel"].y += 200.0 * delta
		d["rot"] += d["rot_speed"] * delta
	# Gravidade nas faiscas
	for s in sparks:
		s["vel"].y += 300.0 * delta
	queue_redraw()

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii()
		return
	var t := elapsed / lifetime

	# Flash inicial branco — maior
	if elapsed < 0.4:
		var flash_t := elapsed / 0.4
		var flash_a := (1.0 - flash_t) * 0.9
		draw_circle(Vector2.ZERO, lerpf(30.0, 500.0, flash_t), Color(1.0, 1.0, 1.0, flash_a))

	# Ondas de choque
	for sw_start in shockwaves:
		var sw_elapsed := elapsed - sw_start
		if sw_elapsed < 0.0 or sw_elapsed > 1.2:
			continue
		var sw_t := sw_elapsed / 1.2
		var sw_radius := lerpf(15.0, 600.0, sw_t)
		var sw_alpha := (1.0 - sw_t) * 0.6
		var color_idx := int((sw_start * 10 + sw_elapsed * 8)) % RING_COLORS.size()
		var c := RING_COLORS[color_idx]
		# Anel grosso com glow
		draw_arc(Vector2.ZERO, sw_radius, 0, TAU, 64, Color(c.r, c.g, c.b, sw_alpha * 0.15), sw_radius * 0.4, true)
		draw_arc(Vector2.ZERO, sw_radius, 0, TAU, 64, Color(c.r, c.g, c.b, sw_alpha), 5.0, true)
		draw_arc(Vector2.ZERO, sw_radius, 0, TAU, 64, Color(1.0, 1.0, 1.0, sw_alpha * 0.4), 2.5, true)

	# Bola de fogo central — maior e mais duradoura
	if elapsed < 1.8:
		var fire_t := elapsed / 1.8
		var fire_r := lerpf(60.0, 130.0, fire_t) * (1.0 - fire_t * 0.4)
		var fire_a := (1.0 - fire_t) * 0.8
		var fire_idx := int(elapsed * 15.0) % RING_COLORS.size()
		var fc := RING_COLORS[fire_idx]
		draw_circle(Vector2.ZERO, fire_r * 2.0, Color(fc.r, fc.g, fc.b, fire_a * 0.15))
		draw_circle(Vector2.ZERO, fire_r * 1.3, Color(fc.r, fc.g, fc.b, fire_a * 0.3))
		draw_circle(Vector2.ZERO, fire_r, Color(fc.r, fc.g, fc.b, fire_a))
		draw_circle(Vector2.ZERO, fire_r * 0.4, Color(1.0, 1.0, 1.0, fire_a * 0.7))

	# Destrocos grandes voando
	var debris_alpha := clampf(1.0 - (t - 0.2) / 0.8, 0.0, 1.0)
	for d in debris:
		var pos: Vector2 = d["vel"] * elapsed
		var sz: float = d["size"] * (1.0 - t * 0.3)
		var col: Color = d["color"]
		var rot: float = d["rot"]
		if sz < 0.5:
			continue
		# Estilhaco angular rotacionado
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for vi in 4:
			var a := rot + TAU * float(vi) / 4
			var r := sz if vi % 2 == 0 else sz * 0.5
			pts.append(pos + Vector2(cos(a) * r, sin(a) * r))
			cols.append(Color(col.r, col.g, col.b, debris_alpha * 0.8))
		draw_polygon(pts, cols)
		for ei in pts.size():
			draw_line(pts[ei], pts[(ei + 1) % pts.size()], Color(col.r, col.g, col.b, debris_alpha), 1.0, true)

	# Chuva de faiscas — particulas pequenas brilhantes
	for s in sparks:
		var spark_elapsed := elapsed - float(s["delay"])
		if spark_elapsed < 0.0:
			continue
		var spark_life := 2.5
		if spark_elapsed > spark_life:
			continue
		var st := spark_elapsed / spark_life
		var spark_alpha := (1.0 - st) * 0.9
		var pos: Vector2 = s["vel"] * spark_elapsed
		var sz: float = s["size"] * (1.0 - st * 0.5)
		var col: Color = s["color"]
		if sz < 0.3:
			continue
		# Glow
		draw_circle(pos, sz * 3.0, Color(col.r, col.g, col.b, spark_alpha * 0.15))
		# Particula
		draw_circle(pos, sz, Color(col.r, col.g, col.b, spark_alpha))
		# Centro branco
		draw_circle(pos, sz * 0.4, Color(1.0, 1.0, 1.0, spark_alpha * 0.5))

func _draw_ascii() -> void:
	var font := ThemeDB.fallback_font
	var t := elapsed / lifetime
	# Debris as scattered "#" chars
	var debris_alpha := clampf(1.0 - (t - 0.2) / 0.8, 0.0, 1.0)
	for d in debris:
		var pos: Vector2 = d["vel"] * elapsed
		var col: Color = d["color"]
		var draw_col := Color(col.r, col.g, col.b, debris_alpha * 0.8)
		var text_size := font.get_string_size("#", HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
		draw_string(font, pos - Vector2(text_size.x / 2.0, -text_size.y / 4.0), "#", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, draw_col)
	# Sparks as scattered "*" chars
	for s in sparks:
		var spark_elapsed := elapsed - float(s["delay"])
		if spark_elapsed < 0.0:
			continue
		var spark_life := 2.5
		if spark_elapsed > spark_life:
			continue
		var st := spark_elapsed / spark_life
		var spark_alpha := (1.0 - st) * 0.9
		var pos: Vector2 = s["vel"] * spark_elapsed
		var col: Color = s["color"]
		var draw_col := Color(col.r, col.g, col.b, spark_alpha)
		var text_size := font.get_string_size("*", HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		draw_string(font, pos - Vector2(text_size.x / 2.0, -text_size.y / 4.0), "*", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, draw_col)
