extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 100.0

var target_position := Vector2.ZERO
var fragment_count: int

var ClusterFragmentScene := preload("res://entities/missiles/cluster_fragment.tscn")

const BASE_COLOR := Color(0.7, 0.0, 1.0)
const TRAIL_LENGTH := 20
const TRAIL_MIN_DIST := 20.0
const MISSILE_RADIUS := 16.0
var trail: Array[Vector2] = []

var DeathParticlesScene := preload("res://entities/missiles/death_particles.tscn")

func _ready() -> void:
	add_to_group("enemy")
	fragment_count = randi_range(3, 5)
	area_entered.connect(_on_area_entered)

func _draw() -> void:
	# Trail — polyline
	if trail.size() >= 2:
		var pts := PackedVector2Array()
		var colors := PackedColorArray()
		pts.append(Vector2.ZERO)
		colors.append(Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.35))
		for i in trail.size():
			var t := 1.0 - float(i) / trail.size()
			pts.append(trail[i] - global_position)
			colors.append(Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.35 * t))
		draw_polyline_colors(pts, colors, MISSILE_RADIUS * 2.0)
		draw_polyline_colors(pts, colors, MISSILE_RADIUS * 0.5)
	# Neon violeta com glow
	draw_circle(Vector2.ZERO, 22.0, Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.15))
	draw_circle(Vector2.ZERO, MISSILE_RADIUS, Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.85))
	draw_circle(Vector2.ZERO, 8.0, Color(0.9, 0.6, 1.0))

func _physics_process(delta: float) -> void:
	# Trail — so grava se moveu distancia minima
	if trail.is_empty() or global_position.distance_to(trail[0]) >= TRAIL_MIN_DIST:
		trail.push_front(global_position)
		if trail.size() > TRAIL_LENGTH:
			trail.resize(TRAIL_LENGTH)
	queue_redraw()

	var direction = global_position.direction_to(target_position)
	global_position += direction * speed * delta

	if global_position.y >= target_position.y:
		queue_free()

func _spawn_death_particles() -> void:
	var dp = DeathParticlesScene.instantiate()
	dp.position = global_position
	dp.color = BASE_COLOR
	get_parent().add_child(dp)

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		call_deferred("_spawn_fragments")
		call_deferred("_spawn_death_particles")
		destroyed.emit(self)
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		if area.has_method("take_hit"):
			area.call_deferred("take_hit")
		call_deferred("queue_free")

func _spawn_fragments() -> void:
	var spawn_pos = global_position
	for i in fragment_count:
		var frag = ClusterFragmentScene.instantiate()
		frag.position = spawn_pos
		var angle_spread = PI * 0.7
		var base_angle = PI / 2.0
		var angle = base_angle + lerpf(-angle_spread / 2, angle_spread / 2, float(i) / max(fragment_count - 1, 1))
		frag.direction = Vector2.from_angle(angle)
		get_parent().add_child(frag)
