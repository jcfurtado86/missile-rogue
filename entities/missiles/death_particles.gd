extends Node2D

var color := Color(1.0, 0.0, 0.6)
var particles: Array[Dictionary] = []
var lifetime := 0.5
var elapsed := 0.0

func _ready() -> void:
	var num := randi_range(8, 14)
	for i in num:
		var angle := randf() * TAU
		var spd := randf_range(150.0, 450.0)
		var sz := randf_range(5.0, 12.0)
		particles.append({
			"vel": Vector2(cos(angle) * spd, sin(angle) * spd),
			"size": sz,
		})

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii()
		return
	var t := elapsed / lifetime
	var alpha := 1.0 - t
	for p in particles:
		var pos: Vector2 = p["vel"] * elapsed
		var sz: float = p["size"] * (1.0 - t * 0.5)
		# Glow
		draw_circle(pos, sz * 3.0, Color(color.r, color.g, color.b, alpha * 0.2))
		# Core
		draw_circle(pos, sz, Color(color.r, color.g, color.b, alpha))

func _draw_ascii() -> void:
	var font := ThemeDB.fallback_font
	var alpha := 1.0 - elapsed / lifetime
	var col := Color(color.r, color.g, color.b, alpha)
	for p in particles:
		var pos: Vector2 = p["vel"] * elapsed
		var text_size := font.get_string_size("*", HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		draw_string(font, pos - Vector2(text_size.x / 2.0, -text_size.y / 4.0), "*", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, col)
