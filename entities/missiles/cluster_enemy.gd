extends BaseEnemy

var fragment_count: int

const CLUSTER_FRAGMENT_SCENE = preload("res://entities/missiles/cluster_fragment.tscn")

func _get_trail_length() -> int: return 20
func _get_trail_min_dist() -> float: return 20.0
func _get_missile_radius() -> float: return 16.0
func _get_color_key() -> String: return "enemy_cluster"
func _get_ascii_char() -> String: return "@"
func _get_trail_alpha() -> float: return 0.35

func _ready() -> void:
	super()
	speed = 100.0
	add_to_group("enemy")
	fragment_count = randi_range(3, 5)
	area_entered.connect(_on_area_entered)

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_trail_and_char()
		return
	_draw_trail()
	var fill := Themes.c("fill_entity")
	var color := _get_base_color()
	# Bomba grande — hexagonal arredondada apontando pra baixo
	var body := PackedVector2Array([
		Vector2(0, 18), Vector2(-10, 8), Vector2(-12, -4),
		Vector2(-8, -14), Vector2(8, -14), Vector2(12, -4), Vector2(10, 8),
	])
	var stab_l := PackedVector2Array([Vector2(-8, -10), Vector2(-18, -18), Vector2(-6, -14)])
	var stab_r := PackedVector2Array([Vector2(8, -10), Vector2(18, -18), Vector2(6, -14)])
	# Glow grande
	draw_circle(Vector2.ZERO, 24.0, Themes.glow("enemy_cluster", 0.1))
	# Corpo
	draw_polygon(body, PackedColorArray([fill, fill, fill, fill, fill, fill, fill]))
	for i in body.size():
		draw_line(body[i], body[(i + 1) % body.size()], Color(color.r, color.g, color.b, 0.85), 2.0, true)
	# Estabilizadores
	draw_polygon(stab_l, PackedColorArray([fill, fill, fill]))
	draw_polygon(stab_r, PackedColorArray([fill, fill, fill]))
	for i in 3:
		draw_line(stab_l[i], stab_l[(i + 1) % 3], Color(color.r, color.g, color.b, 0.6), 1.0, true)
		draw_line(stab_r[i], stab_r[(i + 1) % 3], Color(color.r, color.g, color.b, 0.6), 1.0, true)
	# Indicador de payload
	draw_line(Vector2(-6, -2), Vector2(6, -2), Color(color.r, color.g, color.b, 0.3), 1.0, true)
	draw_line(Vector2(-5, 4), Vector2(5, 4), Color(color.r, color.g, color.b, 0.2), 1.0, true)
	# Core
	draw_circle(Vector2(0, -2), 3.0, Color(0.9, 0.6, 1.0, 0.6))

func _physics_process(delta: float) -> void:
	if _update_trail():
		queue_redraw()

	var direction = global_position.direction_to(target_position)
	global_position += direction * speed * delta
	rotation = direction.angle() - PI / 2.0

	if reflected:
		if _is_reflected_oob():
			queue_free()
			return
	elif global_position.y >= target_position.y:
		_spawn_mushroom_cloud()
		queue_free()
	elif global_position.y < -OOB_MARGIN:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		var auto: bool = area.get("is_auto_turret") == true
		call_deferred("_spawn_fragments")
		call_deferred("_spawn_death_particles")
		destroyed.emit(self, auto)
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		_handle_city_collision(area)

func _spawn_fragments() -> void:
	var spawn_pos = global_position
	for i in fragment_count:
		var frag = CLUSTER_FRAGMENT_SCENE.instantiate()
		frag.position = spawn_pos
		var angle_spread = PI * 0.7
		var base_angle = PI / 2.0
		var angle = base_angle + lerpf(-angle_spread / 2, angle_spread / 2, float(i) / max(fragment_count - 1, 1))
		frag.direction = Vector2.from_angle(angle)
		frag.ground_y = target_position.y
		get_parent().add_child(frag)
