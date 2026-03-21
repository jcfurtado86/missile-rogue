extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 200.0

var target_position := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemy")
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.3, 0.4))
	draw_circle(Vector2(0, -8), 3.0, Color(1.0, 0.3, 0.4, 0.5))

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(target_position)
	global_position += direction * speed * delta

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
