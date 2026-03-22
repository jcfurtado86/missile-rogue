extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 400.0

var target_position := Vector2.ZERO
var city_positions: Array[Vector2] = []

# Troca de alvo aleatoria
var retarget_timer := 0.0
var retarget_interval_min := 0.5
var retarget_interval_max := 1.5
const MAX_RETARGET_Y := 1200.0

const BASE_COLOR := Color(0.2, 1.0, 0.1)
const TRAIL_LENGTH := 30
const TRAIL_MIN_DIST := 15.0
const MISSILE_RADIUS := 9.0
var trail: Array[Vector2] = []

var DeathParticlesScene := preload("res://entities/missiles/death_particles.tscn")
var MushroomCloudScene := preload("res://entities/missiles/mushroom_cloud.tscn")

func _ready() -> void:
	add_to_group("enemy")
	area_entered.connect(_on_area_entered)
	_schedule_retarget()

func _draw() -> void:
	# Trail — polyline
	if trail.size() >= 2:
		var pts := PackedVector2Array()
		var colors := PackedColorArray()
		pts.append(Vector2.ZERO)
		colors.append(Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.4))
		for i in trail.size():
			var t := 1.0 - float(i) / trail.size()
			pts.append(trail[i] - global_position)
			colors.append(Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.4 * t))
		draw_polyline_colors(pts, colors, MISSILE_RADIUS * 2.0)
		draw_polyline_colors(pts, colors, MISSILE_RADIUS * 0.5)
	# Neon verde eletrico
	draw_circle(Vector2.ZERO, 11.0, Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.2))
	draw_circle(Vector2.ZERO, MISSILE_RADIUS, Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.9))
	draw_circle(Vector2.ZERO, 4.0, Color(0.8, 1.0, 0.8))

func _physics_process(delta: float) -> void:
	# Trail — so grava se moveu distancia minima
	if trail.is_empty() or global_position.distance_to(trail[0]) >= TRAIL_MIN_DIST:
		trail.push_front(global_position)
		if trail.size() > TRAIL_LENGTH:
			trail.resize(TRAIL_LENGTH)
	queue_redraw()

	# Troca de alvo
	if global_position.y < MAX_RETARGET_Y and city_positions.size() > 1:
		retarget_timer -= delta
		if retarget_timer <= 0.0:
			_pick_new_target()
			_schedule_retarget()

	var direction = global_position.direction_to(target_position)
	global_position += direction * speed * delta

	if global_position.y >= target_position.y:
		_spawn_mushroom_cloud()
		queue_free()

func _schedule_retarget() -> void:
	retarget_timer = randf_range(retarget_interval_min, retarget_interval_max)

func _pick_new_target() -> void:
	var new_target = city_positions.pick_random()
	if city_positions.size() > 1:
		while new_target.distance_to(target_position) < 10.0:
			new_target = city_positions.pick_random()
	target_position = new_target

func _spawn_mushroom_cloud() -> void:
	var mc = MushroomCloudScene.instantiate()
	mc.position = global_position
	mc.color = BASE_COLOR
	get_parent().add_child(mc)

func _spawn_death_particles() -> void:
	var dp = DeathParticlesScene.instantiate()
	dp.position = global_position
	dp.color = BASE_COLOR
	get_parent().add_child(dp)

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		destroyed.emit(self)
		call_deferred("_spawn_death_particles")
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		if area.has_method("take_hit"):
			area.call_deferred("take_hit")
		call_deferred("_spawn_mushroom_cloud")
		call_deferred("queue_free")
