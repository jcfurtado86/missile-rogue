extends Area2D

signal city_destroyed

var data: CityData

func _ready() -> void:
	data = CityData.new()
	queue_redraw()

func _draw() -> void:
	if data.is_alive():
		var fill := Color(0.02, 0.03, 0.06)
		var outline := Color(0.0, 0.8, 1.0, 0.7)
		var outline_bright := Color(0.0, 1.0, 1.0, 0.9)
		var win_col := Color(0.0, 0.8, 1.0, 0.3)
		var glow_col := Color(0.0, 0.6, 1.0, 0.06)

		# Glow base
		draw_circle(Vector2(0, -30), 100.0, glow_col)

		# --- Predio esquerdo (baixo, largo) ---
		draw_rect(Rect2(-82, -45, 50, 82), fill)
		draw_line(Vector2(-82, -45), Vector2(-82, 37), outline, 2.0, true)
		draw_line(Vector2(-32, -45), Vector2(-32, 37), outline, 2.0, true)
		draw_line(Vector2(-82, -45), Vector2(-32, -45), outline, 2.0, true)
		# Janelas
		for wi in 4:
			var wx := -76.0 + wi * 13.0
			draw_line(Vector2(wx, -38.0), Vector2(wx, 30.0), win_col, 1.5, true)

		# --- Predio central (torre alta com setback) ---
		# Base larga
		draw_rect(Rect2(-27, -38, 54, 75), fill)
		draw_line(Vector2(-27, -38), Vector2(-27, 37), outline, 2.0, true)
		draw_line(Vector2(27, -38), Vector2(27, 37), outline, 2.0, true)
		draw_line(Vector2(-27, -38), Vector2(27, -38), outline, 2.0, true)
		# Setback (torre estreita)
		draw_rect(Rect2(-16, -87, 32, 49), fill)
		draw_line(Vector2(-16, -87), Vector2(-16, -38), outline, 2.0, true)
		draw_line(Vector2(16, -87), Vector2(16, -38), outline, 2.0, true)
		draw_line(Vector2(-16, -87), Vector2(16, -87), outline_bright, 2.0, true)
		# Spire no topo
		var spire := PackedVector2Array([Vector2(-16, -87), Vector2(0, -112), Vector2(16, -87)])
		var spire_cols := PackedColorArray([fill, fill, fill])
		draw_polygon(spire, spire_cols)
		draw_line(spire[0], spire[1], outline_bright, 2.0, true)
		draw_line(spire[1], spire[2], outline_bright, 2.0, true)
		# Antena
		draw_line(Vector2(0, -112), Vector2(0, -135), outline_bright, 2.0, true)
		draw_circle(Vector2(0, -135), 4.0, Color(1.0, 0.0, 0.3, 0.9))
		draw_circle(Vector2(0, -135), 8.0, Color(1.0, 0.0, 0.3, 0.2))
		# Janelas da torre
		draw_line(Vector2(-5, -80.0), Vector2(-5, -42.0), win_col, 1.5, true)
		draw_line(Vector2(5, -80.0), Vector2(5, -42.0), win_col, 1.5, true)
		# Janelas da base
		for wi in 4:
			var wx := -18.0 + wi * 11.0
			draw_line(Vector2(wx, -30.0), Vector2(wx, 30.0), win_col, 1.5, true)

		# --- Predio direito (medio, com topo plano e setback) ---
		draw_rect(Rect2(33, -63, 48, 100), fill)
		draw_line(Vector2(33, -63), Vector2(33, 37), outline, 2.0, true)
		draw_line(Vector2(81, -63), Vector2(81, 37), outline, 2.0, true)
		draw_line(Vector2(33, -63), Vector2(81, -63), outline, 2.0, true)
		# Setback pequeno
		draw_rect(Rect2(39, -81, 33, 18), fill)
		draw_line(Vector2(39, -81), Vector2(72, -81), outline, 2.0, true)
		draw_line(Vector2(39, -81), Vector2(39, -63), outline, 2.0, true)
		draw_line(Vector2(72, -81), Vector2(72, -63), outline, 2.0, true)
		# Janelas
		for wi in 4:
			var wx := 40.0 + wi * 12.0
			draw_line(Vector2(wx, -57.0), Vector2(wx, 30.0), win_col, 1.5, true)

	else:
		# Ruinas — estrutura quebrada
		var dead := Color(0.0, 0.6, 1.0, 0.2)
		var fill := Color(0.02, 0.03, 0.06)
		# Silhueta destruida irregular
		var rubble := PackedVector2Array([
			Vector2(-82, 37), Vector2(-82, 0), Vector2(-60, -18),
			Vector2(-42, 3), Vector2(-27, -12), Vector2(-12, -27),
			Vector2(8, -9), Vector2(22, -36), Vector2(42, -18),
			Vector2(57, -27), Vector2(81, -12), Vector2(81, 37),
		])
		var cols := PackedColorArray()
		for _i in rubble.size():
			cols.append(fill)
		draw_polygon(rubble, cols)
		for i in rubble.size() - 1:
			draw_line(rubble[i], rubble[i + 1], dead, 1.5, true)
		# Fumaca residual
		draw_circle(Vector2(-12, -18), 10.0, Color(0.0, 0.5, 1.0, 0.04))
		draw_circle(Vector2(27, -27), 7.0, Color(0.0, 0.5, 1.0, 0.03))

func take_hit() -> void:
	if not data.is_alive():
		return
	data.take_hit()
	queue_redraw()
	city_destroyed.emit()
	# Desativa colisao
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)

func revive() -> void:
	data.alive = true
	queue_redraw()
	set_deferred("monitorable", true)
	set_deferred("monitoring", true)

func is_alive() -> bool:
	return data.is_alive()
