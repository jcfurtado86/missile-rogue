extends Area2D

var data: CityData

func _ready() -> void:
	data = CityData.new()
	queue_redraw()

func _draw() -> void:
	if data.is_alive():
		# Cidade viva: retangulo azul
		draw_rect(Rect2(-20, -10, 40, 20), Color(0.2, 0.5, 1.0))
		# Telhado
		draw_polygon(
			[Vector2(-22, -10), Vector2(0, -25), Vector2(22, -10)],
			[Color(0.3, 0.6, 1.0), Color(0.3, 0.6, 1.0), Color(0.3, 0.6, 1.0)]
		)
	else:
		# Cidade destruida: cinza escuro
		draw_rect(Rect2(-20, -5, 40, 15), Color(0.15, 0.15, 0.15))

func take_hit() -> void:
	if not data.is_alive():
		return
	data.take_hit()
	queue_redraw()
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
