extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 400.0

var target_position := Vector2.ZERO
var city_positions: Array[Vector2] = []

# Troca de alvo aleatoria
var retarget_timer := 0.0
var retarget_interval_min := 0.5
var retarget_interval_max := 1.5
const MAX_RETARGET_Y := 1200.0  # So muda de alvo acima dessa altura

func _ready() -> void:
	add_to_group("enemy")
	area_entered.connect(_on_area_entered)
	_schedule_retarget()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(0.0, 0.9, 1.0))
	draw_circle(Vector2(0, -11), 5.0, Color(0.0, 0.9, 1.0, 0.6))
	draw_circle(Vector2(0, -20), 3.0, Color(0.0, 0.9, 1.0, 0.3))

func _physics_process(delta: float) -> void:
	# Troca de alvo
	if global_position.y < MAX_RETARGET_Y and city_positions.size() > 1:
		retarget_timer -= delta
		if retarget_timer <= 0.0:
			_pick_new_target()
			_schedule_retarget()

	var direction = global_position.direction_to(target_position)
	global_position += direction * speed * delta

	if global_position.y >= target_position.y:
		queue_free()

func _schedule_retarget() -> void:
	retarget_timer = randf_range(retarget_interval_min, retarget_interval_max)

func _pick_new_target() -> void:
	var new_target = city_positions.pick_random()
	# Tenta pegar uma cidade diferente da atual
	if city_positions.size() > 1:
		while new_target.distance_to(target_position) < 10.0:
			new_target = city_positions.pick_random()
	target_position = new_target

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		destroyed.emit(self)
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		if area.has_method("take_hit"):
			area.call_deferred("take_hit")
		call_deferred("queue_free")
