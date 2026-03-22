extends Area2D

signal city_destroyed

var data: CityData

func _ready() -> void:
	data = CityData.new()
	queue_redraw()

func _draw() -> void:
	if data.is_alive():
		var neon := Color(0.0, 0.6, 1.0, 0.9)
		var fill := Color(0.0, 0.08, 0.15)
		# Glow
		draw_rect(Rect2(-40, -22, 80, 44), Color(0.0, 0.5, 1.0, 0.08))
		# Corpo — outline neon
		draw_rect(Rect2(-35, -18, 70, 36), fill)
		draw_rect(Rect2(-35, -18, 70, 36), neon, false, 2.0)
		# Telhado — outline neon
		var roof := PackedVector2Array([Vector2(-38, -18), Vector2(0, -42), Vector2(38, -18)])
		draw_polygon(roof, [fill, fill, fill])
		draw_line(roof[0], roof[1], neon, 2.0, true)
		draw_line(roof[1], roof[2], neon, 2.0, true)
		# Janela neon
		draw_rect(Rect2(-8, -10, 16, 16), Color(0.0, 1.0, 1.0, 0.5))
	else:
		# Ruinas — neon vermelho escuro
		var dead_color := Color(1.0, 0.0, 0.3, 0.25)
		draw_rect(Rect2(-35, -8, 70, 26), Color(0.05, 0.02, 0.03))
		draw_rect(Rect2(-35, -8, 70, 26), dead_color, false, 1.5)

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
