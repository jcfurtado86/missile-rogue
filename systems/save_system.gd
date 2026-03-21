class_name SaveSystem
extends RefCounted

func to_dict(upgrade_system: UpgradeSystem, ascension: AscensionSystem, currency: CurrencySystem) -> Dictionary:
	var tier4_levels := {}
	for name in upgrade_system.upgrades:
		var u = upgrade_system.upgrades[name]
		if u["tier"] == 4:
			tier4_levels[name] = u["level"]

	return {
		"eter": currency.get_amount("eter"),
		"tier4": tier4_levels,
		"ascension_count": ascension.get_ascension_count(),
		"total_eter": ascension.get_total_eter(),
	}

func from_dict(data: Dictionary, upgrade_system: UpgradeSystem, ascension: AscensionSystem, currency: CurrencySystem) -> void:
	if not data.has("eter"):
		return
	currency.add("eter", data.get("eter", 0))
	ascension.ascension_count = data.get("ascension_count", 0)
	ascension.total_eter = data.get("total_eter", 0)
	var tier4 = data.get("tier4", {})
	for name in tier4:
		if upgrade_system.upgrades.has(name):
			upgrade_system.upgrades[name]["level"] = tier4[name]

static func get_defaults() -> Dictionary:
	return {
		"eter": 0,
		"tier4": {},
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
