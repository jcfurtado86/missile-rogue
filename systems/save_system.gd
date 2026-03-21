class_name SaveSystem
extends RefCounted

func to_dict(upgrade_system: UpgradeSystem, ascension: AscensionSystem, currency: CurrencySystem) -> Dictionary:
	var upgrade_levels := {}
	for name in upgrade_system.upgrades:
		var u = upgrade_system.upgrades[name]
		upgrade_levels[name] = u["level"]

	return {
		"credits": currency.get_amount("credits"),
		"crystals": currency.get_amount("crystals"),
		"void": currency.get_amount("void"),
		"eter": currency.get_amount("eter"),
		"upgrades": upgrade_levels,
		"total_invested": upgrade_system.get_total_invested(),
		"ascension_count": ascension.get_ascension_count(),
		"total_eter": ascension.get_total_eter(),
		"unlocked_currencies": currency.unlocked.duplicate(),
	}

func from_dict(data: Dictionary, upgrade_system: UpgradeSystem, ascension: AscensionSystem, currency: CurrencySystem) -> void:
	if not data is Dictionary or data.is_empty():
		return
	currency.add("credits", data.get("credits", 0))
	currency.add("crystals", data.get("crystals", 0))
	currency.add("void", data.get("void", 0))
	currency.add("eter", data.get("eter", 0))
	ascension.ascension_count = data.get("ascension_count", 0)
	ascension.total_eter = data.get("total_eter", 0)
	upgrade_system.total_invested = data.get("total_invested", 0)
	var saved_unlocked = data.get("unlocked_currencies", {})
	for key in saved_unlocked:
		if saved_unlocked[key]:
			currency.unlocked[key] = true
	var levels = data.get("upgrades", {})
	for name in levels:
		if upgrade_system.upgrades.has(name):
			upgrade_system.upgrades[name]["level"] = levels[name]

static func get_defaults() -> Dictionary:
	return {
		"credits": 0,
		"crystals": 0,
		"void": 0,
		"eter": 0,
		"upgrades": {},
		"total_invested": 0,
		"ascension_count": 0,
		"total_eter": 0,
	}

func save_to_file(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return get_defaults()
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return get_defaults()
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		return get_defaults()
	if json.data is Dictionary:
		return json.data
	return get_defaults()
