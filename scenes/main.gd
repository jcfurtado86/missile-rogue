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
	_show_splash()

func _show_splash() -> void:
	var splash := ColorRect.new()
	splash.color = Color(0.02, 0.01, 0.08, 1.0)
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(splash)
	current_scene = splash

	var logo := TextureRect.new()
	var tex := load("res://assets/robot-logo.png")
	logo.texture = tex
	logo.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	var scr := get_viewport().get_visible_rect().size
	logo.position = Vector2((scr.x - tex.get_width()) / 2.0, (scr.y - tex.get_height()) / 2.0)
	splash.add_child(logo)

	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(_open_title)

func _open_title() -> void:
	_clear_current()
	var title = preload("res://scenes/title/title.tscn").instantiate()
	title.play_pressed.connect(_start_game)
	title.reset_pressed.connect(_on_reset_save)
	add_child(title)
	current_scene = title

func _on_reset_save() -> void:
	currency = CurrencySystem.new()
	upgrade_system = UpgradeSystem.new()
	ascension_system = AscensionSystem.new()
	_save_game()
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("save.json"):
		dir.remove("save.json")
	_open_title()

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
	var eter_gained = ascension_system.calculate_eter(upgrade_system)
	ascension_system.total_eter += eter_gained
	currency.add("eter", eter_gained)
	ascension_system.ascension_count += 1
	# Aplica resets imediatamente na confirmacao
	var keep_upgrades := upgrade_system.get_effect("eternal_knowledge") > 0
	var keep_currencies := upgrade_system.get_effect("vault") > 0
	if not keep_upgrades:
		upgrade_system.reset_tiers(1, 3)
	if not keep_currencies:
		currency.reset_run_currencies()
	upgrade_system.total_invested = 0
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
	_save_game()
	_start_game()

func _on_start_run() -> void:
	_save_game()
	_start_game()

func _save_game() -> void:
	save_system.locale_loaded = get_node("/root/Tr").locale
	var sm = get_node("/root/SoundManager")
	save_system.music_volume = sm.get_music_volume_linear()
	save_system.sfx_volume = sm.get_sfx_volume_linear()
	var data = save_system.to_dict(upgrade_system, ascension_system, currency)
	save_system.save_to_file(SAVE_PATH, data)

func _load_game() -> void:
	var data = save_system.load_from_file(SAVE_PATH)
	save_system.from_dict(data, upgrade_system, ascension_system, currency)
	var tr_node = get_node("/root/Tr")
	tr_node.set_locale(save_system.locale_loaded)
	var sm = get_node("/root/SoundManager")
	sm.set_music_volume(save_system.music_volume)
	sm.set_sfx_volume(save_system.sfx_volume)

func _clear_current() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
