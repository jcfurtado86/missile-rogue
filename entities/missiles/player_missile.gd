extends Area2D

@export var speed := 1200.0
@export var explosion_radius := 60.0
@export var explosion_duration := 0.4

var target := Vector2.ZERO
var arrived := false
var explosion_time := 0.0

const EXPLOSION_COLORS: Array[Color] = [
	Color(0.0, 1.0, 1.0),   # cyan
	Color(1.0, 0.0, 0.6),   # hot pink
	Color(1.0, 1.0, 0.0),   # amarelo neon
	Color(0.2, 1.0, 0.1),   # verde neon
	Color(0.7, 0.0, 1.0),   # violeta
	Color(1.0, 0.4, 0.0),   # laranja neon
]

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision.disabled = true

func _draw() -> void:
	if not arrived:
		# Neon cyan missile com glow
		draw_circle(Vector2.ZERO, 14.0, Color(0.0, 1.0, 1.0, 0.1))
		draw_circle(Vector2.ZERO, 10.0, Color(0.0, 1.0, 1.0, 0.2))
		draw_circle(Vector2.ZERO, 7.0, Color(0.0, 1.0, 1.0, 0.9))
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 1.0))
	else:
		# Explosao com cores piscando
		var idx := int(explosion_time * 20.0) % EXPLOSION_COLORS.size()
		var c := EXPLOSION_COLORS[idx]
		draw_circle(Vector2.ZERO, explosion_radius * 1.3, Color(c.r, c.g, c.b, 0.12))
		draw_circle(Vector2.ZERO, explosion_radius, Color(c.r, c.g, c.b, 0.35))
		draw_circle(Vector2.ZERO, explosion_radius * 0.6, Color(1.0, 1.0, 1.0, 0.5))

func _physics_process(delta: float) -> void:
	if arrived:
		explosion_time += delta
		queue_redraw()
		return
	var direction = global_position.direction_to(target)
	var distance = global_position.distance_to(target)
	var step = speed * delta

	if step >= distance:
		global_position = target
		_explode()
	else:
		global_position += direction * step

func _explode() -> void:
	arrived = true
	queue_redraw()
	collision.disabled = false
	var shape = collision.shape as CircleShape2D
	shape.radius = explosion_radius
	get_tree().create_timer(explosion_duration).timeout.connect(_on_explosion_end)

func _on_explosion_end() -> void:
	queue_free()
