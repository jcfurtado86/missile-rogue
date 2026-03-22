extends Node2D

var color := Color(1.0, 0.0, 0.6)
var lifetime := 1.2
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := elapsed / lifetime
	var alpha := (1.0 - t)

	# Haste — cresce pra cima e alarga
	var stem_h := lerpf(15.0, 120.0, minf(t * 3.0, 1.0))
	var stem_w := lerpf(10.0, 5.0, t)
	var stem_color := Color(color.r, color.g, color.b, alpha * 0.7)
	draw_rect(Rect2(-stem_w, -stem_h, stem_w * 2.0, stem_h), stem_color)
	# Glow da haste
	draw_rect(Rect2(-stem_w * 3.0, -stem_h, stem_w * 6.0, stem_h), Color(color.r, color.g, color.b, alpha * 0.15))

	# Cogumelo — expande no topo
	var cap_y := -stem_h
	var cap_grow := minf(t * 4.0, 1.0)
	var cap_rx := lerpf(8.0, 55.0, cap_grow) * (1.0 - t * 0.25)
	var cap_ry := lerpf(5.0, 28.0, cap_grow) * (1.0 - t * 0.25)
	var cap_color := Color(color.r, color.g, color.b, alpha * 0.8)
	var cap_glow := Color(color.r, color.g, color.b, alpha * 0.2)
	# Glow do cogumelo
	_draw_ellipse(Vector2(0, cap_y), cap_rx * 2.5, cap_ry * 2.5, cap_glow)
	# Cogumelo solido
	_draw_ellipse(Vector2(0, cap_y), cap_rx, cap_ry, cap_color)
	# Core brilhante
	_draw_ellipse(Vector2(0, cap_y), cap_rx * 0.45, cap_ry * 0.45, Color(1.0, 1.0, 1.0, alpha * 0.5))

	# Base — anel de fumaca expandindo
	var ring_grow := minf(t * 2.5, 1.0)
	var ring_r := lerpf(5.0, 40.0, ring_grow) * (1.0 - t * 0.15)
	var ring_color := Color(color.r, color.g, color.b, alpha * 0.4)
	_draw_ellipse(Vector2(0, 0), ring_r, ring_r * 0.4, ring_color)
	# Segundo anel externo
	var ring2_r := ring_r * 1.5
	_draw_ellipse(Vector2(0, 0), ring2_r, ring2_r * 0.3, Color(color.r, color.g, color.b, alpha * 0.12))

func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx < 1.0 or ry < 1.0:
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var segments := 16
	for i in segments:
		var angle := TAU * float(i) / segments
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
		cols.append(col)
	draw_polygon(pts, cols)
