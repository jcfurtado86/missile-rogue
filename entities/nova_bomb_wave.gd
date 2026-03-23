extends Area2D

signal wave_finished

const EXPAND_SPEED := 1800.0
const MAX_RADIUS := 2800.0

const WAVE_COLORS: Array[Color] = [
	Color(0.0, 1.0, 1.0),   # cyan
	Color(1.0, 0.0, 0.6),   # hot pink
	Color(1.0, 1.0, 0.0),   # amarelo neon
	Color(0.2, 1.0, 0.1),   # verde neon
	Color(0.7, 0.0, 1.0),   # violeta
	Color(1.0, 0.4, 0.0),   # laranja neon
]

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
	var idx := int(time * 20.0) % WAVE_COLORS.size()
	var c := WAVE_COLORS[idx]
	# Anel externo grosso com glow
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 96, Color(c.r, c.g, c.b, 0.08), current_radius * 0.4, true)
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 96, Color(c.r, c.g, c.b, 0.5), 12.0, true)
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 96, Color(1.0, 1.0, 1.0, 0.3), 4.0, true)

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
