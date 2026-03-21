extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 200.0

var target_position := Vector2.ZERO

func _ready() -> void:
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
		# Atingido por explosao do jogador
		destroyed.emit(self)
		queue_free()
	elif area.collision_layer == 4:
		# Atingiu uma cidade
		if area.has_method("take_hit"):
			area.take_hit()
		queue_free()
