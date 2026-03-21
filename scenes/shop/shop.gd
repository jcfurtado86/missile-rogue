extends Control

signal start_run
signal ascend_requested
signal purchase_made

var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var item_container: VBoxContainer
var credits_label: Label

# Nomes legiveis dos upgrades
const UPGRADE_NAMES := {
	"ammo_pack": "AMMO PACK",
	"hyper_drive": "HYPER DRIVE",
	"warhead": "WARHEAD+",
	"profit_matrix": "PROFIT MATRIX",
	"overcharge": "OVERCHARGE",
	"head_start": "HEAD START",
	"time_warp": "TIME WARP",
	"chain_reaction": "CHAIN REACTION",
	"triple_burst": "TRIPLE BURST",
	"overdrive": "OVERDRIVE",
	"early_warning": "EARLY WARNING",
	"city_shield": "CITY SHIELD",
}

const UPGRADE_DESCRIPTIONS := {
	"ammo_pack": "+8 municao por bateria",
	"hyper_drive": "+8% velocidade do missil",
	"warhead": "+8% raio de explosao",
	"profit_matrix": "+8% creditos por abate",
	"overcharge": "+10% velocidade de carga especial",
	"head_start": "+15 creditos ao iniciar run",
	"time_warp": "+5% chance de desacelerar inimigo",
	"chain_reaction": "+5% chance de explosao em cadeia",
	"triple_burst": "+8% chance de tiro triplo",
	"overdrive": "-1 abate necessario pra combo",
	"early_warning": "Misseis rapidos piscam antes",
	"city_shield": "+1 cidade inicial",
}

func _ready() -> void:
	credits_label = $MarginContainer/VBoxContainer/Header/CreditsLabel
	item_container = $MarginContainer/VBoxContainer/ScrollContainer/ItemList

	$MarginContainer/VBoxContainer/BottomButtons/PlayButton.pressed.connect(_on_play_pressed)
	$MarginContainer/VBoxContainer/BottomButtons/AscendButton.pressed.connect(_on_ascend_pressed)

	_build_shop()

func setup(p_currency: CurrencySystem, p_upgrades: UpgradeSystem, _p_ads = null) -> void:
	currency = p_currency
	upgrade_system = p_upgrades

func _build_shop() -> void:
	if not item_container or not currency or not upgrade_system:
		return

	# Limpa itens anteriores
	for child in item_container.get_children():
		child.queue_free()

	# So mostra Tier 1 por enquanto
	var tier1_keys := []
	for key in upgrade_system.upgrades:
		if upgrade_system.upgrades[key]["tier"] == 1:
			tier1_keys.append(key)

	for key in tier1_keys:
		var u = upgrade_system.upgrades[key]
		var item = _create_item(key, u)
		item_container.add_child(item)

	_update_credits()

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
		buy_button.text = "%d CR" % cost
		buy_button.disabled = currency.get_amount("credits") < cost
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.pressed.connect(_on_buy_pressed.bind(key))
	buy_button.custom_minimum_size = Vector2(150, 50)
	row.add_child(buy_button)

	return row

func _on_buy_pressed(key: String) -> void:
	if upgrade_system.buy(key, currency):
		_build_shop()
		purchase_made.emit()

func _update_credits() -> void:
	if credits_label and currency:
		credits_label.text = "%d CR" % currency.get_amount("credits")


func _on_ascend_pressed() -> void:
	ascend_requested.emit()

func _on_play_pressed() -> void:
	start_run.emit()
