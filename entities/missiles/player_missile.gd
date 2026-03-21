extends Area2D

@export var speed := 1200.0
@export var explosion_radius := 60.0
@export var explosion_duration := 0.15

var target := Vector2.ZERO
var arrived := false

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision.disabled = true

func _draw() -> void:
	if not arrived:
		draw_circle(Vector2.ZERO, 7.0, Color(1.0, 1.0, 1.0))
	else:
		draw_circle(Vector2.ZERO, explosion_radius, Color(1.0, 0.4, 0.2, 0.6))

func _physics_process(delta: float) -> void:
	if arrived:
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
