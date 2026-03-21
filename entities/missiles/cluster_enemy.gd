extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 100.0

var target_position := Vector2.ZERO
var fragment_count: int

var ClusterFragmentScene := preload("res://entities/missiles/cluster_fragment.tscn")

func _ready() -> void:
	fragment_count = randi_range(3, 5)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _draw() -> void:
	# Roxo intenso, maior, trail pulsante
	draw_circle(Vector2.ZERO, 10.0, Color(0.6, 0.1, 0.9))
	draw_circle(Vector2.ZERO, 14.0, Color(0.6, 0.1, 0.9, 0.3))

func _physics_process(delta: float) -> void:
	var direction = global_position.direction_to(target_position)
	global_position += direction * speed * delta

	if global_position.y >= target_position.y:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		_spawn_fragments()
		destroyed.emit(self)
		queue_free()
	elif area.collision_layer == 4:
		if area.has_method("take_hit"):
			area.take_hit()
		queue_free()

func _spawn_fragments() -> void:
	for i in fragment_count:
		var frag = ClusterFragmentScene.instantiate()
		frag.global_position = global_position
		var angle_spread = PI * 0.6
		var base_angle = PI / 2.0
		var angle = base_angle + lerpf(-angle_spread / 2, angle_spread / 2, float(i) / max(fragment_count - 1, 1))
		frag.direction = Vector2.from_angle(angle)
		# Adiciona ao mesmo parent (game scene)
		get_parent().add_child(frag)
