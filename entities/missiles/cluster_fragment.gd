extends Area2D

signal destroyed(enemy: Area2D, auto_turret: bool)

@export var speed := 100.0

var direction := Vector2.DOWN
var velocity := Vector2.ZERO
const GRAVITY := 400.0
var invuln_timer := 0.2
var ground_y := 1950.0

var BASE_COLOR: Color:
	get: return Themes.c("enemy_cluster")
const TRAIL_LENGTH := 20
const TRAIL_MIN_DIST := 12.0
const MISSILE_RADIUS := 7.0
var trail: Array[Vector2] = []

var DeathParticlesScene := preload("res://entities/missiles/death_particles.tscn")
var MushroomCloudScene := preload("res://entities/missiles/mushroom_cloud.tscn")

func _ready() -> void:
	add_to_group("fragment")
	area_entered.connect(_on_area_entered)
	velocity = direction * speed

func _draw_ascii() -> void:
	var font := ThemeDB.fallback_font
	var color := Themes.c("enemy_cluster")
	# Trail
	var inv := global_transform.affine_inverse()
	for i in trail.size():
		var t := 1.0 - float(i) / trail.size()
		var local_pos: Vector2 = inv * trail[i]
		var c := Color(color.r, color.g, color.b, 0.4 * t)
		draw_string(font, local_pos - Vector2(4, -4), ".", HORIZONTAL_ALIGNMENT_CENTER, -1, 28, c)
	# Fragment character
	draw_string(font, Vector2(-7, 10), "o", HORIZONTAL_ALIGNMENT_CENTER, -1, 28, color)

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii()
		return
	# Trail
	if trail.size() >= 2:
		var pts := PackedVector2Array()
		var colors := PackedColorArray()
		pts.append(Vector2.ZERO)
		colors.append(Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.4))
		var inv_transform := global_transform.affine_inverse()
		for i in trail.size():
			var t := 1.0 - float(i) / trail.size()
			pts.append(inv_transform * trail[i])
			colors.append(Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.4 * t))
		draw_polyline_colors(pts, colors, MISSILE_RADIUS * 2.0)
		draw_polyline_colors(pts, colors, MISSILE_RADIUS * 0.5)
	var fill := Themes.c("fill_entity")
	# Estilhaco angular — losango irregular
	var shard := PackedVector2Array([
		Vector2(0, 8),
		Vector2(-5, 0),
		Vector2(-2, -7),
		Vector2(3, -6),
		Vector2(6, 1),
	])
	draw_circle(Vector2.ZERO, 10.0, Themes.glow("enemy_cluster", 0.06))
	draw_polygon(shard, PackedColorArray([fill, fill, fill, fill, fill]))
	for i in shard.size():
		draw_line(shard[i], shard[(i + 1) % shard.size()], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.85), 1.5, true)
	draw_circle(Vector2(0, 0), 2.0, Color(0.9, 0.6, 1.0, 0.7))

func _physics_process(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
	# Trail — so grava se moveu distancia minima
	if trail.is_empty() or global_position.distance_to(trail[0]) >= TRAIL_MIN_DIST:
		trail.push_front(global_position)
		if trail.size() > TRAIL_LENGTH:
			trail.resize(TRAIL_LENGTH)
	queue_redraw()

	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	rotation = velocity.angle() - PI / 2.0

	if global_position.y > ground_y:
		_spawn_mushroom_cloud()
		queue_free()
	elif global_position.x < -50 or global_position.x > 1130:
		queue_free()

func _spawn_mushroom_cloud() -> void:
	get_node("/root/SoundManager").ground_hit()
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
	if invuln_timer > 0.0:
		return
	if area.collision_layer == 1:
		var auto: bool = area.get("is_auto_turret") == true
		destroyed.emit(self, auto)
		call_deferred("_spawn_death_particles")
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		if area.has_method("take_hit"):
			area.call_deferred("take_hit")
		call_deferred("_spawn_mushroom_cloud")
		call_deferred("queue_free")
