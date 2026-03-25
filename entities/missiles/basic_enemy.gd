extends BaseEnemy

var boss_origin: Vector2 = Vector2.ZERO  # se != ZERO, invulneravel dentro do glow
const BOSS_GLOW_RADIUS := 160.0

func _get_trail_length() -> int: return 25
func _get_trail_min_dist() -> float: return 18.0
func _get_missile_radius() -> float: return 10.0
func _get_color_key() -> String: return "enemy_basic"
func _get_ascii_char() -> String: return "V"

func _ready() -> void:
	super()
	speed = 200.0
	add_to_group("enemy")
	area_entered.connect(_on_area_entered)

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_trail_and_char()
		return
	_draw_trail()
	var fill := Themes.c("fill_entity")
	var color := _get_base_color()
	# Warhead apontando pra baixo
	var body := PackedVector2Array([
		Vector2(0, 14), Vector2(-7, 0), Vector2(-6, -10),
		Vector2(6, -10), Vector2(7, 0),
	])
	var fin_l := PackedVector2Array([Vector2(-6, -8), Vector2(-12, -14), Vector2(-5, -12)])
	var fin_r := PackedVector2Array([Vector2(6, -8), Vector2(12, -14), Vector2(5, -12)])
	# Glow
	draw_circle(Vector2.ZERO, 16.0, Themes.glow("enemy_basic", 0.08))
	# Corpo
	draw_polygon(body, PackedColorArray([fill, fill, fill, fill, fill]))
	for i in body.size():
		draw_line(body[i], body[(i + 1) % body.size()], Color(color.r, color.g, color.b, 0.9), 1.5, true)
	# Aletas
	draw_polygon(fin_l, PackedColorArray([fill, fill, fill]))
	draw_polygon(fin_r, PackedColorArray([fill, fill, fill]))
	for i in 3:
		draw_line(fin_l[i], fin_l[(i + 1) % 3], Color(color.r, color.g, color.b, 0.6), 1.0, true)
		draw_line(fin_r[i], fin_r[(i + 1) % 3], Color(color.r, color.g, color.b, 0.6), 1.0, true)
	# Ponta brilhante
	draw_circle(Vector2(0, 12), 2.0, Color(1.0, 0.7, 0.9, 0.9))

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
		# Misseis do boss sao invulneraveis dentro do glow
		if boss_origin != Vector2.ZERO and global_position.distance_to(boss_origin) < BOSS_GLOW_RADIUS:
			return
		var auto: bool = area.get("is_auto_turret") == true
		destroyed.emit(self, auto)
		call_deferred("_spawn_death_particles")
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		_handle_city_collision(area)
