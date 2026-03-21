extends Node2D

@export var max_ammo := 10
@export var reload_time := 3.0

var ammo: int
var reloading := false

@onready var reload_timer: Timer = $ReloadTimer

func _ready() -> void:
	ammo = max_ammo
	queue_redraw()

func _draw() -> void:
	var color = Color(0.4, 0.8, 1.0) if ammo > 0 else Color(0.2, 0.3, 0.4)
	draw_polygon(
		[Vector2(0, -35), Vector2(-25, 25), Vector2(25, 25)],
		[color, color, color]
	)

func can_fire() -> bool:
	return ammo > 0

func fire(target: Vector2, missile_scene: PackedScene, speed_mult: float = 1.0, radius_mult: float = 1.0) -> void:
	if ammo <= 0:
		return
	ammo -= 1
	var missile = missile_scene.instantiate()
	missile.global_position = global_position
	missile.target = target
	missile.speed *= speed_mult
	missile.explosion_radius *= radius_mult
	get_tree().current_scene.add_child(missile)

	queue_redraw()
	if ammo <= 0 and not reloading:
		_start_reload()

func _start_reload() -> void:
	reloading = true
	reload_timer.start(reload_time)

func _on_reload_timer_timeout() -> void:
	ammo = max_ammo
	reloading = false
	queue_redraw()
