extends Node2D

var lifetime := 2.5
var elapsed := 0.0

const RING_COLORS: Array[Color] = [
	Color(1.0, 0.0, 0.3),
	Color(1.0, 0.4, 0.0),
	Color(1.0, 1.0, 0.0),
	Color(1.0, 0.0, 0.6),
	Color(0.7, 0.0, 1.0),
]

# Particulas de destrocos
var debris: Array[Dictionary] = []
# Ondas de choque
var shockwaves: Array[float] = []

func _ready() -> void:
	# Destrocos
	for i in 30:
		var angle := randf() * TAU
		var spd := randf_range(100.0, 500.0)
		var sz := randf_range(3.0, 10.0)
		var col := RING_COLORS[randi() % RING_COLORS.size()]
		var rot_speed := randf_range(-5.0, 5.0)
		debris.append({
			"vel": Vector2(cos(angle) * spd, sin(angle) * spd - randf_range(50, 150)),
			"size": sz,
			"color": col,
			"rot": 0.0,
			"rot_speed": rot_speed,
		})
	# 3 ondas de choque escalonadas
	shockwaves = [0.0, 0.3, 0.7]

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	# Gravidade nos destrocos
	for d in debris:
		d["vel"].y += 200.0 * delta
		d["rot"] += d["rot_speed"] * delta
	queue_redraw()

func _draw() -> void:
	var t := elapsed / lifetime

	# Flash inicial branco
	if elapsed < 0.3:
		var flash_t := elapsed / 0.3
		var flash_a := (1.0 - flash_t) * 0.8
		draw_circle(Vector2.ZERO, lerpf(20.0, 300.0, flash_t), Color(1.0, 1.0, 1.0, flash_a))

	# Ondas de choque
	for sw_start in shockwaves:
		var sw_elapsed := elapsed - sw_start
		if sw_elapsed < 0.0 or sw_elapsed > 1.0:
			continue
		var sw_t := sw_elapsed / 1.0
		var sw_radius := lerpf(10.0, 400.0, sw_t)
		var sw_alpha := (1.0 - sw_t) * 0.6
		var color_idx := int((sw_start * 10 + sw_elapsed * 8)) % RING_COLORS.size()
		var c := RING_COLORS[color_idx]
		# Anel grosso com glow
		draw_arc(Vector2.ZERO, sw_radius, 0, TAU, 64, Color(c.r, c.g, c.b, sw_alpha * 0.15), sw_radius * 0.3, true)
		draw_arc(Vector2.ZERO, sw_radius, 0, TAU, 64, Color(c.r, c.g, c.b, sw_alpha), 4.0, true)
		draw_arc(Vector2.ZERO, sw_radius, 0, TAU, 64, Color(1.0, 1.0, 1.0, sw_alpha * 0.4), 2.0, true)

	# Bola de fogo central
	if elapsed < 1.2:
		var fire_t := elapsed / 1.2
		var fire_r := lerpf(40.0, 80.0, fire_t) * (1.0 - fire_t * 0.5)
		var fire_a := (1.0 - fire_t) * 0.7
		var fire_idx := int(elapsed * 15.0) % RING_COLORS.size()
		var fc := RING_COLORS[fire_idx]
		draw_circle(Vector2.ZERO, fire_r * 1.5, Color(fc.r, fc.g, fc.b, fire_a * 0.2))
		draw_circle(Vector2.ZERO, fire_r, Color(fc.r, fc.g, fc.b, fire_a))
		draw_circle(Vector2.ZERO, fire_r * 0.4, Color(1.0, 1.0, 1.0, fire_a * 0.6))

	# Destrocos voando
	var debris_alpha := clampf(1.0 - (t - 0.3) / 0.7, 0.0, 1.0)
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
		# Outline
		for ei in pts.size():
			draw_line(pts[ei], pts[(ei + 1) % pts.size()], Color(col.r, col.g, col.b, debris_alpha), 1.0, true)
