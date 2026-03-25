extends Area2D

signal wave_finished

const EXPAND_SPEED := 1800.0
const MAX_RADIUS := 2800.0

var WAVE_COLORS: Array[Color]:
	get: return Themes.get_explosion_colors()

var current_radius := 0.0
var time := 0.0
var hit_enemies: Dictionary = {}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 1.0
	collision_shape.shape = shape
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	time += delta
	current_radius += EXPAND_SPEED * delta

	if current_radius >= MAX_RADIUS:
		wave_finished.emit()
		queue_free()
		return

	collision_shape.shape.radius = current_radius
	queue_redraw()

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii()
		return
	var idx := int(time * 20.0) % WAVE_COLORS.size()
	var c := WAVE_COLORS[idx]
	# Anel externo grosso com glow
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 96, Color(c.r, c.g, c.b, 0.08), current_radius * 0.4, true)
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 96, Color(c.r, c.g, c.b, 0.5), 12.0, true)
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 96, Color(1.0, 1.0, 1.0, 0.3), 4.0, true)

func _draw_ascii() -> void:
	var font := ThemeDB.fallback_font
	var idx := int(time * 20.0) % WAVE_COLORS.size()
	var c := WAVE_COLORS[idx]
	var num_chars := 16
	for i in num_chars:
		var angle := TAU * float(i) / num_chars
		var pos := Vector2(cos(angle) * current_radius, sin(angle) * current_radius)
		var text_size := font.get_string_size("*", HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		draw_string(font, pos - Vector2(text_size.x / 2.0, -text_size.y / 4.0), "*", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, c)

func _on_area_entered(area: Area2D) -> void:
	var id := area.get_instance_id()
	if hit_enemies.has(id):
		return
	hit_enemies[id] = true

	if area.is_in_group("boss"):
		area.data.take_damage(50)
		if area.data.is_dead():
			if area.has_method("_spawn_boss_explosion"):
				area._spawn_boss_explosion()
			area.boss_defeated.emit()
			area.destroyed.emit(area)
			area.call_deferred("queue_free")
	elif area.is_in_group("enemy") or area.is_in_group("fragment"):
		if area.has_signal("destroyed"):
			area.destroyed.emit(area)
		area.queue_free()
