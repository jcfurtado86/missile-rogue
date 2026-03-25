extends BaseEnemy

var city_positions: Array[Vector2] = []       # todas (incluindo destruidas)
var active_city_positions: Array[Vector2] = [] # so as vivas

# Troca de alvo aleatoria
var retarget_timer := 0.0
var retarget_interval_min := 0.5
var retarget_interval_max := 1.5
const MAX_RETARGET_Y := 1200.0

func _get_trail_length() -> int: return 30
func _get_trail_min_dist() -> float: return 15.0
func _get_missile_radius() -> float: return 9.0
func _get_color_key() -> String: return "enemy_fast"
func _get_ascii_char() -> String: return "v"

func _ready() -> void:
	super()
	speed = 400.0
	add_to_group("enemy")
	area_entered.connect(_on_area_entered)
	_schedule_retarget()

func _reflect() -> void:
	super()
	city_positions.clear()

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_trail_and_char()
		return
	_draw_trail()
	var fill := Themes.c("fill_entity")
	var color := _get_base_color()
	# Flecha fina e aerodinamica apontando pra baixo
	var body := PackedVector2Array([
		Vector2(0, 16), Vector2(-5, 2), Vector2(-4, -12),
		Vector2(4, -12), Vector2(5, 2),
	])
	var wing_l := PackedVector2Array([Vector2(-4, -4), Vector2(-14, -10), Vector2(-4, -8)])
	var wing_r := PackedVector2Array([Vector2(4, -4), Vector2(14, -10), Vector2(4, -8)])
	# Glow
	draw_circle(Vector2.ZERO, 14.0, Themes.glow("enemy_fast", 0.08))
	# Corpo
	draw_polygon(body, PackedColorArray([fill, fill, fill, fill, fill]))
	for i in body.size():
		draw_line(body[i], body[(i + 1) % body.size()], Color(color.r, color.g, color.b, 0.9), 1.5, true)
	# Asas
	draw_polygon(wing_l, PackedColorArray([fill, fill, fill]))
	draw_polygon(wing_r, PackedColorArray([fill, fill, fill]))
	for i in 3:
		draw_line(wing_l[i], wing_l[(i + 1) % 3], Color(color.r, color.g, color.b, 0.7), 1.0, true)
		draw_line(wing_r[i], wing_r[(i + 1) % 3], Color(color.r, color.g, color.b, 0.7), 1.0, true)
	# Ponta
	draw_circle(Vector2(0, 14), 1.5, Color(0.8, 1.0, 0.8, 0.9))

func _physics_process(delta: float) -> void:
	if _update_trail():
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
		if _is_reflected_oob():
			queue_free()
			return
	elif global_position.y >= target_position.y:
		_spawn_mushroom_cloud()
		queue_free()
	elif global_position.y < -OOB_MARGIN:
		queue_free()

func _schedule_retarget() -> void:
	retarget_timer = randf_range(retarget_interval_min, retarget_interval_max)

func _pick_new_target() -> void:
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
	trail.clear()

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		var auto: bool = area.get("is_auto_turret") == true
		destroyed.emit(self, auto)
		call_deferred("_spawn_death_particles")
		call_deferred("queue_free")
	elif area.collision_layer == 4:
		_handle_city_collision(area)
