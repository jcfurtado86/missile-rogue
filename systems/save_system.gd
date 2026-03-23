class_name SaveSystem
extends RefCounted

const SAVE_KEY := "m1ss1l3-r0gu3-s4lt-k3y-2024"

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
		"ascension_count": ascension.get_ascension_count(),
		"total_eter": ascension.get_total_eter(),
		"unlocked_currencies": currency.unlocked.duplicate(),
		"boss_cleared": upgrade_system.boss_cleared,
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
	var saved_unlocked = data.get("unlocked_currencies", {})
	for key in saved_unlocked:
		if saved_unlocked[key]:
			currency.unlocked[key] = true
	upgrade_system.boss_cleared = data.get("boss_cleared", false)
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
		"ascension_count": 0,
		"total_eter": 0,
	}

func _compute_hash(json_str: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update((SAVE_KEY + json_str + SAVE_KEY).to_utf8_buffer())
	return ctx.finish().hex_encode()

func save_to_file(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_str := JSON.stringify(data)
		var checksum := _compute_hash(json_str)
		file.store_string(json_str + "\n" + checksum)

func load_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return get_defaults()
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return get_defaults()
	var content := file.get_as_text()
	var parts := content.rsplit("\n", true, 1)
	if parts.size() != 2:
		return get_defaults()
	var json_str := parts[0]
	var saved_hash := parts[1]
	if _compute_hash(json_str) != saved_hash:
		return get_defaults()
	var json = JSON.new()
	var error = json.parse(json_str)
	if error != OK:
		return get_defaults()
	if json.data is Dictionary:
		return json.data
	return get_defaults()
