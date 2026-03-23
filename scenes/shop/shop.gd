extends Control

signal start_run
signal ascend_requested
signal purchase_made

var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var item_container: VBoxContainer
var credits_label: Label
var eter_mode := false

const CURRENCY_LABELS := {
	"credits": "CR",
	"crystals": "CS",
	"void": "VO",
	"eter": "ET",
}

const TIER_NAMES := {
	1: "TIER 1 — CREDITOS",
	2: "TIER 2 — CRISTAIS",
	3: "TIER 3 — VOID",
}

const TIER_CURRENCY := {
	1: "credits",
	2: "crystals",
	3: "void",
}

# Nomes legiveis dos upgrades
const UPGRADE_NAMES := {
	# Tier 1
	"extra_city": "EXTRA CITY",
	"ammo_pack": "AMMO PACK",
	"magazine": "MAGAZINE+",
	"ammo_regen": "AMMO REGEN",
	"hyper_drive": "HYPER DRIVE",
	"warhead": "WARHEAD+",
	"head_start": "HEAD START",
	"credit_boost": "CREDIT BOOST",
	"time_warp": "TIME WARP",
	"early_warning": "EARLY WARNING",
	# Tier 2
	"extra_battery": "EXTRA BATTERY",
	"city_shield": "CITY SHIELD",
	"warp_reload": "WARP RELOAD",
	"overcharge": "OVERCHARGE",
	"critical_mass": "CRITICAL MASS",
	"crystal_boost": "CRYSTAL BOOST",
	"homing": "HOMING",
	"chain_reaction": "CHAIN REACTION",
	"triple_burst": "TRIPLE BURST",
	# Tier 3
	"twin_cannons": "TWIN CANNONS",
	"temporal_freeze": "TEMPORAL FREEZE",
	"phoenix_protocol": "PHOENIX PROTOCOL",
	"singularity": "SINGULARITY",
	"auto_turret": "AUTO TURRET",
	"mirror_array": "MIRROR ARRAY",
	"void_boost": "VOID BOOST",
	# Tier 4
	"ascendant_core": "ASCENDANT CORE",
	"eternal_knowledge": "ETERNAL KNOWLEDGE",
	"vault": "VAULT",
	"omega_protocol": "OMEGA PROTOCOL",
}

const UPGRADE_DESCRIPTIONS := {
	# Tier 1
	"extra_city": "+1 cidade",
	"ammo_pack": "+1 pente por bateria",
	"magazine": "+1 tiro por pente",
	"ammo_regen": "+0.2 pentes/s regenerados",
	"hyper_drive": "+10% velocidade do missil",
	"warhead": "+10% raio de explosao",
	"head_start": "+20 creditos ao iniciar run",
	"credit_boost": "+10% creditos por abate",
	"time_warp": "+8% chance de desacelerar inimigo",
	"early_warning": "Mostra onde misseis vao cair",
	# Tier 2
	"extra_battery": "+1 bateria",
	"city_shield": "Campo de forca nas cidades",
	"warp_reload": "-12% tempo de recarga",
	"overcharge": "+15% velocidade de carga especial",
	"critical_mass": "+4% chance de explosao critica",
	"crystal_boost": "+15% cristais por abate",
	"homing": "Misseis rastreiam inimigos",
	"chain_reaction": "+5% chance de explosao em cadeia",
	"triple_burst": "+8% chance de tiro triplo",
	# Tier 3
	"twin_cannons": "+1 missil extra por tiro",
	"temporal_freeze": "+1.5s de congelamento",
	"phoenix_protocol": "+1 cidade revive automatico",
	"singularity": "Explosoes puxam inimigos",
	"auto_turret": "Baterias atiram automaticamente",
	"mirror_array": "+5% chance de refletir",
	"void_boost": "+20% void por abate",
	# Tier 4
	"ascendant_core": "+10% ganho de todas as moedas",
	"eternal_knowledge": "Mantem upgrades ao ascender",
	"vault": "Mantem moedas ao ascender",
	"omega_protocol": "+50% recompensas",
}

func _ready() -> void:
	credits_label = $MarginContainer/VBoxContainer/Header/CreditsLabel
	item_container = $MarginContainer/VBoxContainer/ScrollContainer/ItemList

	$MarginContainer/VBoxContainer/BottomButtons/PlayButton.pressed.connect(_on_play_pressed)
	$MarginContainer/VBoxContainer/BottomButtons/AscendButton.pressed.connect(_on_ascend_pressed)

	if has_meta("eter_mode"):
		eter_mode = get_meta("eter_mode")

	if eter_mode:
		$MarginContainer/VBoxContainer/Header/TitleLabel.text = "UPGRADES ETERNOS"
		$MarginContainer/VBoxContainer/BottomButtons/AscendButton.visible = false

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

	if eter_mode:
		# Modo eter: so mostra tier 4
		for key in upgrade_system.upgrades:
			var u = upgrade_system.upgrades[key]
			if u["tier"] == 4:
				var item = _create_item(key, u)
				item_container.add_child(item)
		_update_header()
		return

	# Itera por tiers 1-3, mostrando apenas os desbloqueados
	for tier in [1, 2, 3]:
		var tier_currency = TIER_CURRENCY[tier]
		if tier > 1 and not currency.is_unlocked(tier_currency):
			continue

		# Separador do tier
		var separator = _create_tier_separator(tier)
		item_container.add_child(separator)

		# Upgrades do tier
		for key in upgrade_system.upgrades:
			var u = upgrade_system.upgrades[key]
			if u["tier"] == tier:
				var item = _create_item(key, u)
				item_container.add_child(item)

	_update_header()

func _create_tier_separator(tier: int) -> Label:
	var label = Label.new()
	label.text = TIER_NAMES[tier]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	var colors := {1: Color(1.0, 1.0, 0.0), 2: Color(0.0, 1.0, 1.0), 3: Color(0.7, 0.0, 1.0)}
	label.add_theme_color_override("font_color", colors[tier])
	return label

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
	var cur_type = u["currency"]
	var cur_label = CURRENCY_LABELS.get(cur_type, cur_type)
	if u["level"] >= u["max_level"]:
		buy_button.text = "MAX"
		buy_button.disabled = true
	else:
		var cost = upgrade_system.get_cost(key)
		buy_button.text = "%d %s" % [cost, cur_label]
		buy_button.disabled = currency.get_amount(cur_type) < cost
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.pressed.connect(_on_buy_pressed.bind(key))
	buy_button.custom_minimum_size = Vector2(150, 50)
	row.add_child(buy_button)

	return row

func _on_buy_pressed(key: String) -> void:
	if upgrade_system.buy(key, currency):
		_build_shop()
		purchase_made.emit()

func _update_header() -> void:
	if not credits_label or not currency:
		return
	var parts: Array[String] = []
	for cur_type in ["eter", "void", "crystals", "credits"]:
		var amount = currency.get_amount(cur_type)
		if amount > 0 and currency.is_unlocked(cur_type):
			parts.append("%d %s" % [amount, CURRENCY_LABELS[cur_type]])
	credits_label.text = "  ".join(parts)

func _on_ascend_pressed() -> void:
	ascend_requested.emit()

func _on_play_pressed() -> void:
	start_run.emit()
