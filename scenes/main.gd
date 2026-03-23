extends Node

const SAVE_PATH := "user://save.json"

var current_scene: Node = null
var currency := CurrencySystem.new()
var upgrade_system := UpgradeSystem.new()
var ascension_system := AscensionSystem.new()
var save_system := SaveSystem.new()
var ad_system := AdSystem.new()

func _ready() -> void:
	_load_game()
	_start_game()

func _start_game() -> void:
	_clear_current()
	ad_system.reset_run()
	var stats = PlayerStats.new(upgrade_system)
	var game = preload("res://scenes/game/game.tscn").instantiate()
	game.currency = currency
	game.upgrade_system = upgrade_system
	game.stats = stats
	game.ad_system = ad_system
	game.game_over.connect(_on_game_over)
	add_child(game)
	current_scene = game

func _on_game_over() -> void:
	_save_game()
	_open_shop()

func _open_shop() -> void:
	_clear_current()
	var shop = preload("res://scenes/shop/shop.tscn").instantiate()
	shop.setup(currency, upgrade_system, ad_system)
	shop.start_run.connect(_on_start_run)
	shop.ascend_requested.connect(_open_ascension)
	shop.purchase_made.connect(_save_game)
	add_child(shop)
	current_scene = shop

func _open_ascension() -> void:
	_clear_current()
	var ascension = preload("res://scenes/ascension/ascension.tscn").instantiate()
	ascension.setup(currency, upgrade_system, ascension_system)
	ascension.ascension_confirmed.connect(_on_ascension_confirmed)
	ascension.ascension_cancelled.connect(_open_shop)
	add_child(ascension)
	current_scene = ascension

func _on_ascension_confirmed() -> void:
	# Calcula eter ganho e adiciona, mas NAO reseta ainda
	# O reset acontece depois da eter shop, pra que eternal_knowledge/vault
	# comprados agora ja facam efeito
	var eter_gained = ascension_system.calculate_eter(upgrade_system)
	ascension_system.total_eter += eter_gained
	currency.add("eter", eter_gained)
	ascension_system.ascension_count += 1
	_save_game()
	_open_eter_shop()

func _open_eter_shop() -> void:
	_clear_current()
	var shop = preload("res://scenes/shop/shop.tscn").instantiate()
	shop.setup(currency, upgrade_system)
	shop.set_meta("eter_mode", true)
	shop.start_run.connect(_on_eter_shop_done)
	shop.purchase_made.connect(_save_game)
	add_child(shop)
	current_scene = shop

func _on_eter_shop_done() -> void:
	# Agora que o jogador ja comprou upgrades T4, aplica o reset
	var keep_upgrades := upgrade_system.get_effect("eternal_knowledge") > 0
	var keep_currencies := upgrade_system.get_effect("vault") > 0
	if not keep_upgrades:
		upgrade_system.reset_tiers(1, 3)
	if not keep_currencies:
		currency.reset_run_currencies()
	_save_game()
	_start_game()

func _on_start_run() -> void:
	_save_game()
	_start_game()

func _save_game() -> void:
	var data = save_system.to_dict(upgrade_system, ascension_system, currency)
	save_system.save_to_file(SAVE_PATH, data)

func _load_game() -> void:
	var data = save_system.load_from_file(SAVE_PATH)
	save_system.from_dict(data, upgrade_system, ascension_system, currency)

func _clear_current() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
