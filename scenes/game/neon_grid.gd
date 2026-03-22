extends Node2D

const GRID_SPACING := 120.0
const GRID_COLOR := Color(0.0, 0.4, 1.0, 0.06)
const HORIZON_Y := 400.0
const HORIZON_LINE_COLOR := Color(1.0, 0.0, 0.6, 0.15)

var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size
	z_index = -1

func _draw() -> void:
	# Linhas verticais
	var x := 0.0
	while x <= screen_size.x:
		draw_line(Vector2(x, 0), Vector2(x, screen_size.y), GRID_COLOR, 1.0, true)
		x += GRID_SPACING

	# Linhas horizontais
	var y := 0.0
	while y <= screen_size.y:
		draw_line(Vector2(0, y), Vector2(screen_size.x, y), GRID_COLOR, 1.0, true)
		y += GRID_SPACING

	# Linha do horizonte — neon magenta
	draw_line(Vector2(0, HORIZON_Y), Vector2(screen_size.x, HORIZON_Y), HORIZON_LINE_COLOR, 2.0, true)

	# Glow na base — gradiente sutil
	for i in range(6):
		var alpha := 0.03 * (6 - i)
		var gy := screen_size.y - (i * 30.0)
		draw_line(Vector2(0, gy), Vector2(screen_size.x, gy), Color(0.0, 1.0, 1.0, alpha), 1.5, true)
