extends Node

var current_scene: Node = null
var currency := CurrencySystem.new()
var upgrade_system := UpgradeSystem.new()

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
	# Delay pra jogador ver o GAME OVER
	get_tree().create_timer(2.0).timeout.connect(_open_shop)

func _open_shop() -> void:
	_clear_current()
	var shop = preload("res://scenes/shop/shop.tscn").instantiate()
	shop.setup(currency, upgrade_system)
	shop.start_run.connect(_on_start_run)
	add_child(shop)
	current_scene = shop

func _on_start_run() -> void:
	_start_game()

func _clear_current() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
