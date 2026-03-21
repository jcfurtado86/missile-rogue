extends Node

const SAVE_PATH := "user://save.json"

var current_scene: Node = null
var currency := CurrencySystem.new()
var upgrade_system := UpgradeSystem.new()
var ascension_system := AscensionSystem.new()
var save_system := SaveSystem.new()
var ad_system = null

func _ready() -> void:
	var AdSystemClass = load("res://systems/ad_system.gd")
	ad_system = AdSystemClass.new()
	_load_game()
	_start_game()

func _start_game() -> void:
	_clear_current()
	ad_system.reset_run()
	var game = preload("res://scenes/game/game.tscn").instantiate()
	game.currency = currency
	game.upgrade_system = upgrade_system
	game.ad_system = ad_system
	game.game_over.connect(_on_game_over)
	add_child(game)
	current_scene = game

func _on_game_over() -> void:
	_save_game()
	get_tree().create_timer(2.0).timeout.connect(_open_shop)

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
	_save_game()
	_open_shop()

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
