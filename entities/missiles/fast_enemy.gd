extends Area2D

signal destroyed(enemy: Area2D)

@export var speed := 400.0

var target_position := Vector2.ZERO
var city_positions: Array[Vector2] = []       # todas (incluindo destruidas)
var active_city_positions: Array[Vector2] = [] # so as vivas
var mirror_chance := 0.0
var reflected := false

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

func _reflect() -> void:
	var angle := randf_range(-PI * 0.8, -PI * 0.2)
	target_position = global_position + Vector2.from_angle(angle) * 800.0
	city_positions.clear()
	speed *= 1.5
	remove_from_group("enemy")
	add_to_group("reflected")
	reflected = true
	trail.clear()

func _draw() -> void:
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
	var fill := Color(0.02, 0.1, 0.02)
	# Flecha fina e aerodinamica apontando pra baixo
	var body := PackedVector2Array([
		Vector2(0, 16),     # ponta aguda
		Vector2(-5, 2),     # esq
		Vector2(-4, -12),   # base esq
		Vector2(4, -12),    # base dir
		Vector2(5, 2),      # dir
	])
	# Asas angulares
	var wing_l := PackedVector2Array([Vector2(-4, -4), Vector2(-14, -10), Vector2(-4, -8)])
	var wing_r := PackedVector2Array([Vector2(4, -4), Vector2(14, -10), Vector2(4, -8)])
	# Glow
	draw_circle(Vector2.ZERO, 14.0, Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.08))
	# Corpo
	draw_polygon(body, PackedColorArray([fill, fill, fill, fill, fill]))
	for i in body.size():
		draw_line(body[i], body[(i + 1) % body.size()], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.9), 1.5, true)
	# Asas
	draw_polygon(wing_l, PackedColorArray([fill, fill, fill]))
	draw_polygon(wing_r, PackedColorArray([fill, fill, fill]))
	for i in 3:
		draw_line(wing_l[i], wing_l[(i + 1) % 3], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.7), 1.0, true)
		draw_line(wing_r[i], wing_r[(i + 1) % 3], Color(BASE_COLOR.r, BASE_COLOR.g, BASE_COLOR.b, 0.7), 1.0, true)
	# Ponta
	draw_circle(Vector2(0, 14), 1.5, Color(0.8, 1.0, 0.8, 0.9))

func _physics_process(delta: float) -> void:
	# Trail — so grava se moveu distancia minima
	if trail.is_empty() or global_position.distance_to(trail[0]) >= TRAIL_MIN_DIST:
		trail.push_front(global_position)
		if trail.size() > TRAIL_LENGTH:
			trail.resize(TRAIL_LENGTH)
	queue_redraw()

	# Troca de alvo (nao troca se refletido)
	if not reflected and global_position.y < MAX_RETARGET_Y and city_positions.size() > 1:
		retarget_timer -= delta
		if retarget_timer <= 0.0:
			_pick_new_target()
			_schedule_retarget()

	var direction = global_position.direction_to(target_position)
	global_position += direction * speed * delta
	rotation = direction.angle() - PI / 2.0

	if reflected:
		if global_position.distance_to(target_position) < 10.0 or global_position.y < -50 or global_position.x < -50 or global_position.x > 1130:
			queue_free()
			return
	elif global_position.y >= target_position.y:
		_spawn_mushroom_cloud()
		queue_free()
	elif global_position.y < -50:
		queue_free()

func _schedule_retarget() -> void:
	retarget_timer = randf_range(retarget_interval_min, retarget_interval_max)

func _pick_new_target() -> void:
	# Perto do chao — ultima mudanca vai pra uma cidade ativa
	var pool: Array[Vector2]
	if global_position.y > MAX_RETARGET_Y * 0.7 and not active_city_positions.is_empty():
		pool = active_city_positions
	elif not city_positions.is_empty():
		pool = city_positions
	else:
		return
	var new_target = pool.pick_random()
	if pool.size() > 1:
		while new_target.distance_to(target_position) < 10.0:
			new_target = pool.pick_random()
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
		if is_in_group("enemy") and mirror_chance > 0.0 and randf() < mirror_chance:
			_reflect()
			return
		if area.has_method("take_hit"):
			area.call_deferred("take_hit")
		call_deferred("_spawn_mushroom_cloud")
		call_deferred("queue_free")
