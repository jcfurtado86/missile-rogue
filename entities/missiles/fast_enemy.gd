extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 400.0

var target_position := Vector2.ZERO
var zigzag_time := 0.0
var zigzag_amplitude := 80.0
var zigzag_frequency := 4.0

func _ready() -> void:
	add_to_group("enemy")
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _draw() -> void:
	# Ciano brilhante, trail longo
	draw_circle(Vector2.ZERO, 5.0, Color(0.0, 0.9, 1.0))
	draw_circle(Vector2(0, -6), 3.0, Color(0.0, 0.9, 1.0, 0.6))
	draw_circle(Vector2(0, -12), 2.0, Color(0.0, 0.9, 1.0, 0.3))

func _physics_process(delta: float) -> void:
	zigzag_time += delta
	var direction = global_position.direction_to(target_position)
	var perpendicular = Vector2(-direction.y, direction.x)
	var zigzag_offset = sin(zigzag_time * zigzag_frequency * TAU) * zigzag_amplitude * delta
	global_position += direction * speed * delta + perpendicular * zigzag_offset

	if global_position.y >= target_position.y:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		destroyed.emit(self)
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		if area.has_method("take_hit"):
			area.call_deferred("take_hit")
		call_deferred("queue_free")
