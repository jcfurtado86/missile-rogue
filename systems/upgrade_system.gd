class_name UpgradeSystem
extends RefCounted

var upgrades: Dictionary = {}
var total_invested: int = 0

func _init() -> void:
	_register_tier1()
	_register_tier2()
	_register_tier3()
	_register_tier4()

func _register_tier1() -> void:
	_add("extra_city", 1, "credits", 80, 3.0, 2, 1.0, "flat_extra_city")
	_add("ammo_pack", 1, "credits", 30, 2.0, 8, 1.0, "flat_magazines")
	_add("magazine", 1, "credits", 40, 2.2, 4, 1.0, "flat_magazine_size")
	_add("ammo_regen", 1, "credits", 60, 2.4, 5, 0.1, "flat_ammo_regen")
	_add("hyper_drive", 1, "credits", 50, 2.4, 5, 0.40, "percent_speed")
	_add("warhead", 1, "credits", 50, 2.4, 5, 0.40, "percent_radius")
	_add("head_start", 1, "credits", 40, 2.0, 5, 20.0, "flat_credits_start")
	_add("credit_boost", 1, "credits", 50, 2.4, 5, 1.0, "flat_credits")
	_add("time_warp", 1, "credits", 60, 2.5, 3, 0.08, "percent_slow_chance")
	_add("early_warning", 1, "credits", 100, 1.0, 1, 1.0, "bool_warning")

func _register_tier2() -> void:
	_add("extra_battery", 2, "crystals", 40, 3.0, 2, 1.0, "flat_extra_battery")
	_add("city_shield", 2, "crystals", 50, 2.5, 3, 1.0, "flat_shield_level")
	_add("warp_reload", 2, "crystals", 30, 2.5, 4, 0.12, "percent_reload")
	_add("overcharge", 2, "crystals", 40, 2.5, 5, 0.15, "percent_charge_speed")
	_add("critical_mass", 2, "crystals", 50, 2.5, 3, 0.04, "percent_critical")
	_add("crystal_boost", 2, "crystals", 30, 2.5, 4, 1.0, "flat_crystals")
	_add("homing", 2, "crystals", 60, 2.5, 3, 0.15, "percent_homing")
	_add("chain_reaction", 2, "crystals", 50, 2.5, 3, 0.05, "percent_chain_chance")
	_add("triple_burst", 2, "crystals", 50, 2.5, 3, 0.08, "percent_triple_chance")

func _register_tier3() -> void:
	_add("twin_cannons", 3, "void", 20, 2.5, 2, 1.0, "flat_extra_missile")
	_add("temporal_freeze", 3, "void", 20, 2.5, 3, 1.5, "flat_freeze_seconds")
	_add("phoenix_protocol", 3, "void", 25, 2.5, 2, 1.0, "flat_city_revive")
	_add("singularity", 3, "void", 20, 2.5, 3, 0.15, "percent_pull_force")
	_add("auto_turret", 3, "void", 30, 2.5, 3, 1.0, "flat_auto_turret")
	_add("mirror_array", 3, "void", 25, 2.5, 3, 0.05, "percent_reflect_chance")
	_add("void_boost", 3, "void", 20, 2.5, 3, 1.0, "flat_void")

func _register_tier4() -> void:
	_add("ascendant_core", 4, "eter", 50, 2.0, 3, 0.10, "percent_all_currencies")
	_add("eternal_knowledge", 4, "eter", 200, 1.0, 1, 1.0, "bool_keep_upgrades")
	_add("vault", 4, "eter", 150, 1.0, 1, 1.0, "bool_keep_currencies")
	_add("omega_protocol", 4, "eter", 100, 1.0, 1, 0.50, "percent_reward_boost")

func _add(name: String, tier: int, currency: String, base_cost: int, multiplier: float, max_level: int, effect_per_level: float, effect_type: String) -> void:
	upgrades[name] = {
		"tier": tier,
		"currency": currency,
		"base_cost": base_cost,
		"multiplier": multiplier,
		"max_level": max_level,
		"level": 0,
		"effect_per_level": effect_per_level,
		"effect_type": effect_type,
	}

func get_cost(name: String) -> int:
	var u = upgrades[name]
	return int(u["base_cost"] * pow(u["multiplier"], u["level"]))

func buy(name: String, currency: CurrencySystem) -> bool:
	var u = upgrades[name]
	if u["level"] >= u["max_level"]:
		return false
	var cost = get_cost(name)
	if not currency.spend(u["currency"], cost):
		return false
	total_invested += cost
	u["level"] += 1
	return true

func get_effect(name: String) -> float:
	var u = upgrades[name]
	return u["effect_per_level"] * u["level"]

func get_level(name: String) -> int:
	return upgrades[name]["level"]

func get_total_invested() -> int:
	return total_invested

func reset_tiers(from_tier: int, to_tier: int) -> void:
	for name in upgrades:
		var u = upgrades[name]
		if u["tier"] >= from_tier and u["tier"] <= to_tier:
			u["level"] = 0
	total_invested = 0
