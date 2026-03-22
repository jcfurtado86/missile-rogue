extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 200.0

var target_position := Vector2.ZERO

const BASE_COLOR := Color(1.0, 0.0, 0.6)
const TRAIL_LENGTH := 25
const TRAIL_MIN_DIST := 18.0
const MISSILE_RADIUS := 10.0
var trail: Array[Vector2] = []

var DeathParticlesScene := preload("res://entities/missiles/death_particles.tscn")
var MushroomCloudScene := preload("res://entities/missiles/mushroom_cloud.tscn")

func _ready() -> void:
	add_to_group("enemy")
	area_entered.connect(_on_area_entered)

func _draw() -> void:
	# Trail
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
	var fill := Color(0.15, 0.0, 0.06)
	# Warhead apontando pra baixo
	var body := PackedVector2Array([
		Vector2(0, 14),     # ponta
		Vector2(-7, 0),     # esq
		Vector2(-6, -10),   # base esq
		Vector2(6, -10),    # base dir
		Vector2(7, 0),      # dir
	])
	var fin_l := PackedVector2Array([Vector2(-6, -8), Vector2(-12, -14), Vector2(-5, -12)])
	var fin_r := PackedVector2Array([Vector2(6, -8), Vector2(12, -14), Vector2(5, -12)])
	# Glow
	draw_circle(Vector2.ZERO, 16.0, Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.08))
	# Corpo
	draw_polygon(body, PackedColorArray([fill, fill, fill, fill, fill]))
	for i in body.size():
		draw_line(body[i], body[(i + 1) % body.size()], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.9), 1.5, true)
	# Aletas
	draw_polygon(fin_l, PackedColorArray([fill, fill, fill]))
	draw_polygon(fin_r, PackedColorArray([fill, fill, fill]))
	for i in 3:
		draw_line(fin_l[i], fin_l[(i + 1) % 3], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.6), 1.0, true)
		draw_line(fin_r[i], fin_r[(i + 1) % 3], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.6), 1.0, true)
	# Ponta brilhante
	draw_circle(Vector2(0, 12), 2.0, Color(1.0, 0.7, 0.9, 0.9))

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
		_spawn_mushroom_cloud()
		queue_free()

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
