extends Node2D

signal game_over

const BATTERY_Y_OFFSET := 170.0  # distancia do fundo
const CITY_Y_OFFSET := 100.0     # distancia do fundo

var screen_width: float
var screen_height: float

var batteries: Array[Node2D] = []
var cities: Array[Node2D] = []
var destroyed_order: Array[Node2D] = []  # ordem de destruicao das cidades
var is_game_over := false

var threat := ThreatSystem.new()
var spawner := SpawnSystem.new()
var special := SpecialSystem.new()
var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var stats: PlayerStats
var ad_system = null
var spawn_timer := 0.0
var run_earnings := {"credits": 0, "crystals": 0, "void": 0}

# Phoenix protocol
var phoenix_revives_remaining := 0

# Auto turret
var auto_turret_timer := 0.0



# Early warning
var warning_indicators: Array[Dictionary] = []

# Screen effects
var shake_intensity := 0.0
var shake_timer := 0.0
var flash_alpha := 0.0

var PlayerMissileScene := preload("res://entities/missiles/player_missile.tscn")
var BasicEnemyScene := preload("res://entities/missiles/basic_enemy.tscn")
var FastEnemyScene := preload("res://entities/missiles/fast_enemy.tscn")
var ClusterEnemyScene := preload("res://entities/missiles/cluster_enemy.tscn")
var BossScene := preload("res://entities/boss/overlord.tscn")

var hud: CanvasLayer
var warning_layer: Node2D
var boss: Area2D = null
var boss_spawned := false

func _ready() -> void:
	screen_height = get_viewport().get_visible_rect().size.y

	var hud_scene := preload("res://scenes/game/hud.tscn")
	hud = hud_scene.instantiate()
	add_child(hud)

	# Musica
	var music := AudioStreamPlayer.new()
	var ogg_file := FileAccess.open("res://assets/neon.ogg", FileAccess.READ)
	if ogg_file:
		var ogg_stream := AudioStreamOggVorbis.load_from_file("res://assets/neon.ogg")
		if ogg_stream:
			ogg_stream.loop = true
			music.stream = ogg_stream
			music.autoplay = true
			music.bus = "Master"
			add_child(music)

	screen_width = get_viewport().get_visible_rect().size.x
	var battery_y := screen_height - BATTERY_Y_OFFSET
	var battery_scene := preload("res://entities/battery/battery.tscn")
	for ratio in stats.get_battery_ratios():
		var battery = battery_scene.instantiate()
		battery.position = Vector2(ratio * screen_width, battery_y)
		battery.max_magazines = stats.max_magazines
		battery.magazine_size = stats.magazine_size
		battery.reload_time = stats.reload_time
		battery.ammo_regen_rate = stats.ammo_regen
		add_child(battery)
		batteries.append(battery)

	var city_y := screen_height - CITY_Y_OFFSET
	var city_scene := preload("res://entities/city/city.tscn")
	for ratio in stats.get_city_ratios():
		var city = city_scene.instantiate()
		city.position = Vector2(ratio * screen_width, city_y)
		city.city_destroyed.connect(_on_city_destroyed.bind(city))
		if stats.shield_cooldown > 0.0:
			city.setup_shield(stats.shield_cooldown)
		add_child(city)
		cities.append(city)

	# Warning layer — por cima de tudo
	warning_layer = WarningLayer.new()
	warning_layer.z_index = 100
	warning_layer.game = self
	add_child(warning_layer)

	if stats and stats.head_start_credits > 0:
		currency.add("credits", stats.head_start_credits)

	# Overcharge
	special.charge_speed_mult = stats.charge_speed_mult

	# Phoenix protocol
	phoenix_revives_remaining = stats.city_revives

func _physics_process(delta: float) -> void:
	# Screen effects rodam sempre
	_update_screen_effects(delta)
	if is_game_over or not currency:
		return
	threat.update_time(delta)
	special.update_time(delta)
	_handle_spawning(delta)
	_connect_fragments()
	_handle_auto_turret(delta)
	_check_game_over()
	hud.update_threat(threat.get_level())
	hud.update_currencies(run_earnings)
	hud.update_special(special.get_charge(), special.is_ready())
	if boss and is_instance_valid(boss):
		hud.show_boss_hp(boss.get_hp_ratio())

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
		# Gasta municao 1x
		closest_battery.consume_ammo()

		# Determina quantos misseis disparar
		var missile_count := 1 + stats.extra_missiles  # twin_cannons

		# Triple burst — chance de 3 misseis
		if stats.triple_chance > 0.0 and randf() < stats.triple_chance:
			missile_count = 3

		for i in missile_count:
			if i == 0:
				_spawn_player_missile(closest_battery, target)
			else:
				# Misseis extras com offset espalhado
				var offset := Vector2(randf_range(-120, 120), randf_range(-120, 120))
				_spawn_player_missile(closest_battery, target + offset)

func _spawn_player_missile(battery: Node2D, target: Vector2) -> void:
	var missile = PlayerMissileScene.instantiate()
	missile.global_position = battery.global_position
	missile.target = target
	missile.speed *= stats.missile_speed_mult
	missile.explosion_radius *= stats.explosion_radius_mult
	missile.homing_strength = stats.homing_strength
	missile.critical_mass_chance = stats.critical_mass_chance
	missile.chain_chance = stats.chain_chance
	missile.pull_force = stats.pull_force
	add_child(missile)

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

	if dist.has("boss"):
		if not boss_spawned:
			_spawn_boss()
		return

	# Rola tipo de inimigo por distribuicao
	var roll = randf()
	var enemy: Area2D
	var drop_currency := "credits"
	var drop_amount := 1

	if dist.has("cluster") and roll > (dist["basic"] + dist["fast"]):
		enemy = ClusterEnemyScene.instantiate()
		enemy.target_position = target_city.global_position
		drop_currency = "void"
		drop_amount = 1
	elif dist.has("fast") and roll > dist["basic"]:
		enemy = FastEnemyScene.instantiate()
		enemy.target_position = target_city.global_position
		var positions: Array[Vector2] = []
		for c in alive_cities:
			positions.append(c.global_position)
		enemy.city_positions = positions
		drop_currency = "crystals"
	else:
		enemy = BasicEnemyScene.instantiate()
		enemy.target_position = target_city.global_position
		enemy.speed = lerpf(150.0, 400.0, threat_level / 100.0)

	# Time warp — chance de desacelerar
	if stats.time_warp_chance > 0.0 and randf() < stats.time_warp_chance:
		enemy.speed *= 0.5

	# Mirror array — chance de refletir
	enemy.mirror_chance = stats.mirror_chance

	enemy.position = Vector2(randf_range(50, screen_width - 50), -20)
	enemy.destroyed.connect(_on_enemy_destroyed.bind(drop_currency, drop_amount))

	# Early warning — marca onde o missil vai cair
	if stats.has_early_warning:
		warning_indicators.append({
			"pos": target_city.global_position,
			"enemy": enemy,
		})

	add_child(enemy)

func _spawn_boss() -> void:
	boss_spawned = true
	boss = BossScene.instantiate()
	boss.position.x = 540.0
	boss.ground_y = screen_height - CITY_Y_OFFSET
	boss.boss_defeated.connect(_on_boss_defeated)
	add_child(boss)

func _on_boss_defeated() -> void:
	boss = null
	flash_alpha = 1.0
	shake_intensity = 15.0
	shake_timer = 1.5
	# Delay game over pra ver a explosao
	get_tree().create_timer(2.5).timeout.connect(func():
		is_game_over = true
		hud.hide_boss_hp()
		hud.show_victory()
		game_over.emit()
	)

func _on_enemy_destroyed(_enemy: Area2D, drop_currency: String = "credits", drop_amount: int = 1) -> void:
	threat.register_kill()
	if drop_currency != "" and drop_amount > 0:
		var bonus: int = stats.credits_bonus if drop_currency == "credits" else (stats.crystals_bonus if drop_currency == "crystals" else stats.void_bonus)
		var amount := drop_amount + bonus
		currency.add(drop_currency, amount)
		run_earnings[drop_currency] += amount

func _connect_fragments() -> void:
	for frag in get_tree().get_nodes_in_group("fragment"):
		if not frag.destroyed.is_connected(_on_fragment_destroyed):
			frag.destroyed.connect(_on_fragment_destroyed)

func _on_fragment_destroyed(_frag: Area2D) -> void:
	threat.register_kill()
	var void_amount: int = 1 + stats.void_bonus
	currency.add("void", void_amount)
	run_earnings["void"] += void_amount

var NovaBombWaveScene := preload("res://entities/nova_bomb_wave.tscn")

func activate_nova_bomb() -> void:
	if is_game_over:
		return
	if not special.activate():
		return

	# Temporal freeze — congela todos os inimigos
	if stats.freeze_seconds > 0.0:
		_freeze_enemies(stats.freeze_seconds)

	var wave = NovaBombWaveScene.instantiate()
	wave.position = Vector2(540.0, screen_height)
	add_child(wave)

func _freeze_enemies(duration: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and not enemy.is_in_group("boss"):
			enemy.set_physics_process(false)
			get_tree().create_timer(duration).timeout.connect(func():
				if is_instance_valid(enemy):
					enemy.set_physics_process(true)
			)
	for frag in get_tree().get_nodes_in_group("fragment"):
		if is_instance_valid(frag):
			frag.set_physics_process(false)
			get_tree().create_timer(duration).timeout.connect(func():
				if is_instance_valid(frag):
					frag.set_physics_process(true)
			)

# --- Auto turret ---

func _handle_auto_turret(delta: float) -> void:
	if stats.auto_turret_rate <= 0.0:
		return
	auto_turret_timer -= delta
	if auto_turret_timer > 0.0:
		return
	# Intervalo entre tiros: 3s no nivel 1, 1.5s no nivel 2, 1s no nivel 3
	auto_turret_timer = 3.0 / stats.auto_turret_rate

	var enemies := get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return

	# Encontra inimigo mais proximo de qualquer bateria
	var best_enemy: Area2D = null
	var best_dist := INF
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		for battery in batteries:
			var dist := battery.global_position.distance_to(enemy.global_position)
			if dist < best_dist:
				best_dist = dist
				best_enemy = enemy

	if best_enemy:
		# Auto turret nao gasta municao — dispara de bateria aleatoria
		var battery = batteries.pick_random()
		var missile = PlayerMissileScene.instantiate()
		missile.global_position = battery.global_position
		missile.target = best_enemy.global_position
		missile.speed = 400.0 * stats.missile_speed_mult
		missile.explosion_radius = 30.0 * stats.explosion_radius_mult * 0.7
		missile.homing_strength = maxf(stats.homing_strength, 0.3)  # auto turret sempre tem leve homing
		missile.pull_force = stats.pull_force
		add_child(missile)

# --- Game over & revive ---

func _check_game_over() -> void:
	if is_game_over:
		return
	for city in cities:
		if city.is_alive():
			return
	is_game_over = true
	if ad_system and ad_system.can_revive():
		hud.show_revive_offer()
	elif ad_system and ad_system.can_show_shop_ad():
		hud.show_game_over()
		hud.show_double_offer(run_earnings)
	else:
		hud.show_game_over()
		game_over.emit()

func revive() -> void:
	if not ad_system:
		return
	ad_system.show_rewarded_ad(_do_revive)

func _do_revive() -> void:
	ad_system.use_revive()
	is_game_over = false
	# Limpa todos os inimigos da tela
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_in_group("boss"):
			enemy.queue_free()
	for frag in get_tree().get_nodes_in_group("fragment"):
		frag.queue_free()
	# Recarrega pentes de todas as baterias
	for battery in batteries:
		battery.magazines = stats.max_magazines
		battery.magazine_ammo = stats.magazine_size
		battery.reloading = false
		battery.queue_redraw()
	# Revive a ultima cidade destruida
	while not destroyed_order.is_empty():
		var city = destroyed_order.pop_back()
		if not city.is_alive():
			city.revive()
			if stats.shield_cooldown > 0.0:
				city.setup_shield(stats.shield_cooldown)
			break
	hud.hide_revive_offer()

func double_run_earnings() -> void:
	if not ad_system or not ad_system.can_show_shop_ad():
		return
	ad_system.show_rewarded_ad(func():
		for key in run_earnings:
			if run_earnings[key] > 0:
				currency.add(key, run_earnings[key])
		ad_system.use_shop_ad()
		hud.hide_double_offer()
		game_over.emit()
	)

func decline_double() -> void:
	hud.hide_double_offer()
	game_over.emit()

# --- Phoenix protocol ---

func _on_city_destroyed(city: Node2D) -> void:
	destroyed_order.append(city)
	flash_alpha = 0.7
	shake_intensity = 8.0
	shake_timer = 0.3
	# Phoenix protocol — revive automatico
	if phoenix_revives_remaining > 0:
		phoenix_revives_remaining -= 1
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(city) and not city.is_alive():
				city.revive()
				if stats.shield_cooldown > 0.0:
					city.setup_shield(stats.shield_cooldown)
		)

# --- Early warning ---

func _draw() -> void:
	if flash_alpha > 0.0:
		draw_rect(Rect2(-screen_width, -screen_height, screen_width * 3, screen_height * 3), Color(1.0, 0.3, 0.2, flash_alpha))


class WarningLayer extends Node2D:
	var game: Node2D

	func _process(_delta: float) -> void:
		if not game or game.warning_indicators.is_empty():
			return
		queue_redraw()

	func _draw() -> void:
		if not game:
			return
		var to_remove: Array[int] = []
		for i in game.warning_indicators.size():
			var indicator = game.warning_indicators[i]
			var enemy = indicator["enemy"]
			if not is_instance_valid(enemy) or not enemy.is_inside_tree():
				to_remove.append(i)
				continue
			var target_pos: Vector2 = indicator["pos"]
			var local_pos := target_pos - game.global_position
			var col := Color(1.0, 0.0, 0.3, 0.6)
			draw_line(local_pos + Vector2(-50, 0), local_pos + Vector2(50, 0), col, 3.0, true)
			draw_line(local_pos + Vector2(0, -50), local_pos + Vector2(0, 50), col, 3.0, true)
			draw_arc(local_pos, 40.0, 0, TAU, 32, col, 2.5, true)
			draw_arc(local_pos, 20.0, 0, TAU, 24, Color(1.0, 0.0, 0.3, 0.3), 1.5, true)
		for i in range(to_remove.size() - 1, -1, -1):
			game.warning_indicators.remove_at(to_remove[i])

# --- Screen effects ---

func _update_screen_effects(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		var offset := Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
		)
		position = offset
		if shake_timer <= 0.0:
			position = Vector2.ZERO
			shake_intensity = 0.0
	if flash_alpha > 0.0:
		flash_alpha -= delta * 3.0
		if flash_alpha < 0.0:
			flash_alpha = 0.0
		queue_redraw()
