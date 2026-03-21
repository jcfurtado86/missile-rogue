extends Node2D

signal game_over

const SCREEN_WIDTH := 1080
const SCREEN_HEIGHT := 1920

const BATTERY_Y := 1750.0
const BATTERY_POSITIONS := [270.0, 540.0, 810.0]

const CITY_Y := 1820.0
const CITY_POSITIONS := [170.0, 540.0, 910.0]

var batteries: Array[Node2D] = []
var cities: Array[Node2D] = []
var is_game_over := false

var threat := ThreatSystem.new()
var spawner := SpawnSystem.new()
var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var spawn_timer := 0.0

var PlayerMissileScene := preload("res://entities/missiles/player_missile.tscn")
var BasicEnemyScene := preload("res://entities/missiles/basic_enemy.tscn")

var hud: CanvasLayer

# Efeitos calculados dos upgrades
var missile_speed_mult := 1.0
var explosion_radius_mult := 1.0
var credits_mult := 1.0
var base_ammo := 10

func _ready() -> void:
	_apply_upgrades()

	var hud_scene := preload("res://scenes/game/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)

	var battery_scene := preload("res://entities/battery/battery.tscn")
	for x in BATTERY_POSITIONS:
		var battery = battery_scene.instantiate()
		battery.position = Vector2(x, BATTERY_Y)
		battery.max_ammo = base_ammo
		battery.ammo = base_ammo
		add_child(battery)
		batteries.append(battery)

	var city_scene := preload("res://entities/city/city.tscn")
	for x in CITY_POSITIONS:
		var city = city_scene.instantiate()
		city.position = Vector2(x, CITY_Y)
		add_child(city)
		cities.append(city)

	# Head start credits
	if upgrade_system:
		var head_start = upgrade_system.get_effect("head_start")
		if head_start > 0:
			currency.add("credits", int(head_start))

func _apply_upgrades() -> void:
	if not upgrade_system:
		return
	missile_speed_mult = 1.0 + upgrade_system.get_effect("hyper_drive")
	explosion_radius_mult = 1.0 + upgrade_system.get_effect("warhead")
	credits_mult = 1.0 + upgrade_system.get_effect("profit_matrix")
	base_ammo = 10 + int(upgrade_system.get_effect("ammo_pack"))

func _physics_process(delta: float) -> void:
	if is_game_over:
		return

	threat.update_time(delta)
	_handle_spawning(delta)
	_check_game_over()
	hud.update_threat(threat.get_level())
	hud.update_credits(currency.get_amount("credits"))

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		return
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
		closest_battery.fire(target, PlayerMissileScene, missile_speed_mult, explosion_radius_mult)

func _handle_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = spawner.get_spawn_interval(threat.get_level())

func _spawn_enemy() -> void:
	var alive_cities: Array[Node2D] = []
	for city in cities:
		if city.is_alive():
			alive_cities.append(city)
	if alive_cities.is_empty():
		return

	var target_city = alive_cities.pick_random()

	var enemy = BasicEnemyScene.instantiate()
	enemy.position = Vector2(randf_range(50, SCREEN_WIDTH - 50), -20)
	enemy.target_position = target_city.global_position

	var threat_level = threat.get_level()
	enemy.speed = lerpf(150.0, 400.0, threat_level / 100.0)

	enemy.destroyed.connect(_on_enemy_destroyed)
	add_child(enemy)

func _on_enemy_destroyed(_enemy: Area2D) -> void:
	threat.register_kill()
	var credits = int(1 * credits_mult)
	currency.add("credits", credits)

func _check_game_over() -> void:
	if is_game_over:
		return
	for city in cities:
		if city.is_alive():
			return
	is_game_over = true
	hud.show_game_over()
	game_over.emit()
