extends Node2D

const SCREEN_WIDTH := 1080
const SCREEN_HEIGHT := 1920

const BATTERY_Y := 1750.0
const BATTERY_POSITIONS := [270.0, 540.0, 810.0]

var batteries: Array[Node2D] = []

var PlayerMissileScene := preload("res://entities/missiles/player_missile.tscn")

func _ready() -> void:
	var battery_scene := preload("res://entities/battery/battery.tscn")
	for x in BATTERY_POSITIONS:
		var battery = battery_scene.instantiate()
		battery.position = Vector2(x, BATTERY_Y)
		add_child(battery)
		batteries.append(battery)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_fire_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_fire_at(event.position)

func _fire_at(target: Vector2) -> void:
	var closest_battery: Node2D = null
	var closest_dist := INF

	for battery in batteries:
		if not battery.can_fire():
			continue
		var dist = battery.global_position.distance_to(target)
		if dist < closest_dist:
			closest_dist = dist
			closest_battery = battery

	if closest_battery:
		closest_battery.fire(target, PlayerMissileScene)
