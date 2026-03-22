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
var MushroomCloudScene := preload("res://entities/missiles/mushroom_cloud.tscn")

func _ready() -> void:
	add_to_group("enemy")
	fragment_count = randi_range(3, 5)
	area_entered.connect(_on_area_entered)

func _draw() -> void:
	# Trail
	if trail.size() >= 2:
		var pts := PackedVector2Array()
		var colors := PackedColorArray()
		pts.append(Vector2.ZERO)
		colors.append(Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.35))
		var inv_transform := global_transform.affine_inverse()
		for i in trail.size():
			var t := 1.0 - float(i) / trail.size()
			pts.append(inv_transform * trail[i])
			colors.append(Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.35 * t))
		draw_polyline_colors(pts, colors, MISSILE_RADIUS * 2.0)
		draw_polyline_colors(pts, colors, MISSILE_RADIUS * 0.5)
	var fill := Color(0.08, 0.0, 0.12)
	# Bomba grande — hexagonal arredondada apontando pra baixo
	var body := PackedVector2Array([
		Vector2(0, 18),      # ponta
		Vector2(-10, 8),     # esq baixo
		Vector2(-12, -4),    # esq meio
		Vector2(-8, -14),    # esq topo
		Vector2(8, -14),     # dir topo
		Vector2(12, -4),     # dir meio
		Vector2(10, 8),      # dir baixo
	])
	# Estabilizadores traseiros
	var stab_l := PackedVector2Array([Vector2(-8, -10), Vector2(-18, -18), Vector2(-6, -14)])
	var stab_r := PackedVector2Array([Vector2(8, -10), Vector2(18, -18), Vector2(6, -14)])
	# Glow grande
	draw_circle(Vector2.ZERO, 24.0, Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.1))
	# Corpo
	draw_polygon(body, PackedColorArray([fill, fill, fill, fill, fill, fill, fill]))
	for i in body.size():
		draw_line(body[i], body[(i + 1) % body.size()], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.85), 2.0, true)
	# Estabilizadores
	draw_polygon(stab_l, PackedColorArray([fill, fill, fill]))
	draw_polygon(stab_r, PackedColorArray([fill, fill, fill]))
	for i in 3:
		draw_line(stab_l[i], stab_l[(i + 1) % 3], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.6), 1.0, true)
		draw_line(stab_r[i], stab_r[(i + 1) % 3], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.6), 1.0, true)
	# Indicador de payload — linhas internas
	draw_line(Vector2(-6, -2), Vector2(6, -2), Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.3), 1.0, true)
	draw_line(Vector2(-5, 4), Vector2(5, 4), Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.2), 1.0, true)
	# Core
	draw_circle(Vector2(0, -2), 3.0, Color(0.9, 0.6, 1.0, 0.6))

func _physics_process(delta: float) -> void:
	# Trail — so grava se moveu distancia minima
	if trail.is_empty() or global_position.distance_to(trail[0]) >= TRAIL_MIN_DIST:
		trail.push_front(global_position)
		if trail.size() > TRAIL_LENGTH:
			trail.resize(TRAIL_LENGTH)
	queue_redraw()

	var direction = global_position.direction_to(target_position)
	global_position += direction * speed * delta
	rotation = direction.angle() - PI / 2.0

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
		call_deferred("_spawn_fragments")
		call_deferred("_spawn_death_particles")
		destroyed.emit(self)
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		if area.has_method("take_hit"):
			area.call_deferred("take_hit")
		call_deferred("_spawn_mushroom_cloud")
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
		frag.ground_y = target_position.y
		get_parent().add_child(frag)
