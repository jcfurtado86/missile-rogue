extends Area2D

signal city_destroyed

var data: CityData

func _ready() -> void:
	data = CityData.new()
	queue_redraw()

func _draw() -> void:
	if data.is_alive():
		var neon := Color(0.0, 0.6, 1.0, 0.9)
		var fill := Color(0.0, 0.05, 0.1)
		var win_on := Color(0.0, 1.0, 1.0, 0.45)
		var win_off := Color(0.0, 0.3, 0.4, 0.15)
		# Glow da base
		draw_rect(Rect2(-42, -35, 84, 55), Color(0.0, 0.5, 1.0, 0.06))
		# Bloco principal
		draw_rect(Rect2(-32, -18, 64, 36), fill)
		draw_rect(Rect2(-32, -18, 64, 36), neon, false, 2.0)
		# Torre central (mais alta)
		draw_rect(Rect2(-12, -38, 24, 20), fill)
		draw_rect(Rect2(-12, -38, 24, 20), neon, false, 1.5)
		# Antena
		draw_line(Vector2(0, -38), Vector2(0, -48), neon, 1.5, true)
		draw_circle(Vector2(0, -48), 2.0, Color(1.0, 0.0, 0.3, 0.8))
		draw_circle(Vector2(0, -48), 4.0, Color(1.0, 0.0, 0.3, 0.15))
		# Setback esquerdo
		draw_rect(Rect2(-32, -26, 16, 8), fill)
		draw_rect(Rect2(-32, -26, 16, 8), Color(neon.r, neon.g, neon.b, 0.5), false, 1.0)
		# Setback direito
		draw_rect(Rect2(16, -24, 16, 6), fill)
		draw_rect(Rect2(16, -24, 16, 6), Color(neon.r, neon.g, neon.b, 0.5), false, 1.0)
		# Janelas — grade no bloco principal
		for row in 3:
			for col in 6:
				var wx := -28.0 + col * 10.0
				var wy := -14.0 + row * 10.0
				var wc := win_on if (row + col) % 3 != 0 else win_off
				draw_rect(Rect2(wx, wy, 6, 6), wc)
		# Janelas da torre
		for row in 2:
			for col in 2:
				var wx := -8.0 + col * 10.0
				var wy := -34.0 + row * 9.0
				draw_rect(Rect2(wx, wy, 6, 5), win_on)
		# Linha decorativa horizontal
		draw_line(Vector2(-32, -1), Vector2(32, -1), Color(neon.r, neon.g, neon.b, 0.25), 1.0, true)
	else:
		# Ruinas — estrutura quebrada
		var dead := Color(1.0, 0.0, 0.3, 0.2)
		var fill := Color(0.04, 0.01, 0.03)
		# Bloco destruido irregular
		var rubble := PackedVector2Array([
			Vector2(-30, 18), Vector2(-32, -4), Vector2(-20, -10),
			Vector2(-8, -2), Vector2(5, -14), Vector2(18, -6),
			Vector2(28, -8), Vector2(30, 18),
		])
		var cols := PackedColorArray()
		for _i in rubble.size():
			cols.append(fill)
		draw_polygon(rubble, cols)
		for i in rubble.size() - 1:
			draw_line(rubble[i], rubble[i + 1], dead, 1.5, true)
		# Fumaca residual
		draw_circle(Vector2(-5, -8), 5.0, Color(1.0, 0.0, 0.3, 0.05))
		draw_circle(Vector2(10, -10), 3.0, Color(1.0, 0.0, 0.3, 0.03))

func take_hit() -> void:
	return  # TEMP: imortal para teste
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
