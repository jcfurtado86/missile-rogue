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
var special := SpecialSystem.new()
var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var spawn_timer := 0.0

var PlayerMissileScene := preload("res://entities/missiles/player_missile.tscn")
var BasicEnemyScene := preload("res://entities/missiles/basic_enemy.tscn")
var FastEnemyScene := preload("res://entities/missiles/fast_enemy.tscn")
var ClusterEnemyScene := preload("res://entities/missiles/cluster_enemy.tscn")

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
	special.update_time(delta)
	_handle_spawning(delta)
	_connect_fragments()
	_check_game_over()
	hud.update_threat(threat.get_level())
	hud.update_currencies(currency.get_amount("credits"), currency.get_amount("crystals"), currency.get_amount("void"))
	hud.update_special(special.get_charge(), special.is_ready())

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
	var threat_level = threat.get_level()
	var dist = spawner.get_spawn_distribution(threat_level)

	# Boss handled in Fase 9 — por enquanto continua spawnando normalmente
	if dist.has("boss"):
		dist = {"basic": 0.55, "fast": 0.30, "cluster": 0.15}

	# Rola tipo de inimigo por distribuicao
	var roll = randf()
	var enemy: Area2D
	var drop_currency := "credits"
	var drop_amount := 1

	if dist.has("cluster") and roll > (dist["basic"] + dist["fast"]):
		enemy = ClusterEnemyScene.instantiate()
		enemy.target_position = target_city.global_position
		drop_currency = ""
		drop_amount = 0
	elif dist.has("fast") and roll > dist["basic"]:
		enemy = FastEnemyScene.instantiate()
		enemy.target_position = target_city.global_position
		drop_currency = "crystals"
	else:
		enemy = BasicEnemyScene.instantiate()
		enemy.target_position = target_city.global_position
		enemy.speed = lerpf(150.0, 400.0, threat_level / 100.0)

	enemy.position = Vector2(randf_range(50, SCREEN_WIDTH - 50), -20)
	enemy.destroyed.connect(_on_enemy_destroyed.bind(drop_currency, drop_amount))
	add_child(enemy)

func _on_enemy_destroyed(_enemy: Area2D, drop_currency: String = "credits", drop_amount: int = 1) -> void:
	threat.register_kill()
	if drop_currency != "" and drop_amount > 0:
		var amount = int(drop_amount * credits_mult) if drop_currency == "credits" else drop_amount
		currency.add(drop_currency, amount)

func _connect_fragments() -> void:
	for frag in get_tree().get_nodes_in_group("fragment"):
		if not frag.destroyed.is_connected(_on_fragment_destroyed):
			frag.destroyed.connect(_on_fragment_destroyed)

func _on_fragment_destroyed(_frag: Area2D) -> void:
	threat.register_kill()
	currency.add("void", 1)

func activate_nova_bomb() -> void:
	if not special.activate():
		return
	call_deferred("_nova_bomb_destroy_all")

func _nova_bomb_destroy_all() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_signal("destroyed"):
			enemy.destroyed.emit(enemy)
		enemy.queue_free()
	for frag in get_tree().get_nodes_in_group("fragment"):
		if frag.has_signal("destroyed"):
			frag.destroyed.emit(frag)
		frag.queue_free()

func _check_game_over() -> void:
	if is_game_over:
		return
	for city in cities:
		if city.is_alive():
			return
	is_game_over = true
	hud.show_game_over()
	game_over.emit()
