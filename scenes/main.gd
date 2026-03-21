extends Node

var current_scene: Node = null
var currency := CurrencySystem.new()
var upgrade_system := UpgradeSystem.new()
var ascension_system := AscensionSystem.new()

func _ready() -> void:
	_start_game()

func _start_game() -> void:
	_clear_current()
	var game = preload("res://scenes/game/game.tscn").instantiate()
	game.currency = currency
	game.upgrade_system = upgrade_system
	game.game_over.connect(_on_game_over)
	add_child(game)
	current_scene = game

func _on_game_over() -> void:
	get_tree().create_timer(2.0).timeout.connect(_open_shop)

func _open_shop() -> void:
	_clear_current()
	var shop = preload("res://scenes/shop/shop.tscn").instantiate()
	shop.setup(currency, upgrade_system)
	shop.start_run.connect(_on_start_run)
	shop.ascend_requested.connect(_open_ascension)
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
	_open_shop()

func _on_start_run() -> void:
	_start_game()

func _clear_current() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
