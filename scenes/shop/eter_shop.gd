extends Control

signal start_run
signal purchase_made

var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var item_container: VBoxContainer
var eter_label: Label

const UPGRADE_NAMES := {
	"ascendant_core": "ASCENDANT CORE",
	"void_resonance": "VOID RESONANCE",
	"eternal_city": "ETERNAL CITY",
	"omega_protocol": "OMEGA PROTOCOL",
}

const UPGRADE_DESCRIPTIONS := {
	"ascendant_core": "+5% boost de void por nivel",
	"void_resonance": "+1 void ao usar especial",
	"eternal_city": "1 cidade indestrutivel",
	"omega_protocol": "+50% recompensas",
}

func _ready() -> void:
	eter_label = $MarginContainer/VBoxContainer/Header/EterLabel
	item_container = $MarginContainer/VBoxContainer/ScrollContainer/ItemList

	$MarginContainer/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)

	_build_shop()

func setup(p_currency: CurrencySystem, p_upgrades: UpgradeSystem) -> void:
	currency = p_currency
	upgrade_system = p_upgrades

func _build_shop() -> void:
	if not item_container or not currency or not upgrade_system:
		return

	for child in item_container.get_children():
		child.queue_free()

	for key in upgrade_system.upgrades:
		var u = upgrade_system.upgrades[key]
		if u["tier"] == 4:
			var item = _create_item(key, u)
			item_container.add_child(item)

	_update_eter()

func _create_item(key: String, u: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.set_meta("upgrade_key", key)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = "%s (Lv %d/%d)" % [UPGRADE_NAMES.get(key, key), u["level"], u["max_level"]]
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 24)
	info.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = UPGRADE_DESCRIPTIONS.get(key, "")
	desc_label.add_theme_font_size_override("font_size", 18)
	info.add_child(desc_label)

	row.add_child(info)

	var buy_button = Button.new()
	buy_button.name = "BuyButton"
	if u["level"] >= u["max_level"]:
		buy_button.text = "MAX"
		buy_button.disabled = true
	else:
		var cost = upgrade_system.get_cost(key)
		buy_button.text = "%d ET" % cost
		buy_button.disabled = currency.get_amount("eter") < cost
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.pressed.connect(_on_buy_pressed.bind(key))
	buy_button.custom_minimum_size = Vector2(150, 50)
	row.add_child(buy_button)

	return row

func _on_buy_pressed(key: String) -> void:
	if upgrade_system.buy(key, currency):
		_build_shop()
		purchase_made.emit()

func _update_eter() -> void:
	if eter_label and currency:
		eter_label.text = "%d ET" % currency.get_amount("eter")

func _on_play_pressed() -> void:
	start_run.emit()
