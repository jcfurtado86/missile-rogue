extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 250.0

var direction := Vector2.DOWN
var invuln_timer := 0.2  # Invulneravel por 0.2s pra nao morrer na mesma explosao do cluster

func _ready() -> void:
	add_to_group("fragment")
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _draw() -> void:
	# Roxo menor
	draw_circle(Vector2.ZERO, 4.0, Color(0.7, 0.2, 1.0))

func _physics_process(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
	global_position += direction * speed * delta

	# Sai da tela
	if global_position.y > 1950 or global_position.x < -50 or global_position.x > 1130:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if invuln_timer > 0.0:
		return
	if area.collision_layer == 1:
		destroyed.emit(self)
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		if area.has_method("take_hit"):
			area.call_deferred("take_hit")
		call_deferred("queue_free")
