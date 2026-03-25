extends BaseEnemy

var direction := Vector2.DOWN
var velocity := Vector2.ZERO
const GRAVITY := 400.0
var invuln_timer := 0.2
var ground_y := 1950.0

func _get_trail_length() -> int: return 20
func _get_trail_min_dist() -> float: return 12.0
func _get_missile_radius() -> float: return 7.0
func _get_color_key() -> String: return "enemy_cluster"
func _get_ascii_char() -> String: return "o"

func _ready() -> void:
	super()
	speed = 100.0
	add_to_group("fragment")
	area_entered.connect(_on_area_entered)
	velocity = direction * speed

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii_trail_and_char()
		return
	_draw_trail()
	var fill := Themes.c("fill_entity")
	var color := _get_base_color()
	# Estilhaco angular — losango irregular
	var shard := PackedVector2Array([
		Vector2(0, 8), Vector2(-5, 0), Vector2(-2, -7),
		Vector2(3, -6), Vector2(6, 1),
	])
	draw_circle(Vector2.ZERO, 10.0, Themes.glow("enemy_cluster", 0.06))
	draw_polygon(shard, PackedColorArray([fill, fill, fill, fill, fill]))
	for i in shard.size():
		draw_line(shard[i], shard[(i + 1) % shard.size()], Color(color.r, color.g, color.b, 0.85), 1.5, true)
	draw_circle(Vector2(0, 0), 2.0, Color(0.9, 0.6, 1.0, 0.7))

func _physics_process(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
	if _update_trail():
		queue_redraw()

	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	rotation = velocity.angle() - PI / 2.0

	if global_position.y > ground_y:
		_spawn_mushroom_cloud()
		queue_free()
	elif global_position.x < -OOB_MARGIN or global_position.x > screen_width + OOB_MARGIN:
		queue_free()

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
