class_name UpgradeSystem
extends RefCounted

var upgrades: Dictionary = {}
var total_invested: int = 0
var boss_cleared := false

func _init() -> void:
	_register_tier1()
	_register_tier2()
	_register_tier3()
	_register_tier4()

func _register_tier1() -> void:
	_add("ammo_pack", 1, "credits", 11, 2.0, 8, 1.0, "flat_magazines")
	_add("extra_city", 1, "credits", 30, 3.0, 2, 1.0, "flat_extra_city", "ammo_pack")
	_add("magazine", 1, "credits", 15, 2.2, 4, 1.0, "flat_magazine_size", "ammo_pack")
	_add("ammo_regen", 1, "credits", 22, 2.4, 5, 0.1, "flat_ammo_regen", "magazine")
	_add("hyper_drive", 1, "credits", 19, 2.4, 5, 0.40, "percent_speed", "warhead")
	_add("warhead", 1, "credits", 19, 2.4, 5, 0.40, "percent_radius", "ammo_pack")
	_add("head_start", 1, "credits", 15, 2.0, 5, 20.0, "flat_credits_start", "credit_boost")
	_add("credit_boost", 1, "credits", 19, 2.4, 5, 1.0, "flat_credits", "ammo_pack")
	_add("time_warp", 1, "credits", 22, 2.5, 3, 0.08, "percent_slow_chance", "credit_boost")
	_add("early_warning", 1, "credits", 37, 1.0, 1, 1.0, "bool_warning", "extra_city")
	_add("target_lock", 1, "credits", 50, 1.0, 1, 1.0, "bool_target_lock", "warhead")

func _register_tier2() -> void:
	_add("extra_battery", 2, "crystals", 30, 3.0, 2, 1.0, "flat_extra_battery", "magazine")
	_add("city_shield", 2, "crystals", 37, 2.5, 3, 1.0, "flat_shield_level", "early_warning")
	_add("warp_reload", 2, "crystals", 22, 2.5, 4, 0.12, "percent_reload", "ammo_regen")
	_add("overcharge", 2, "crystals", 30, 2.5, 5, 0.15, "percent_charge_speed", "warp_reload")
	_add("critical_mass", 2, "crystals", 37, 2.5, 3, 0.04, "percent_critical", "hyper_drive")
	_add("crystal_boost", 2, "crystals", 22, 2.5, 4, 1.0, "flat_crystals", "credit_boost")
	_add("homing", 2, "crystals", 45, 2.5, 3, 0.15, "percent_homing", "hyper_drive")
	_add("triple_burst", 2, "crystals", 37, 2.5, 3, 0.08, "percent_triple_chance", "time_warp")
	_add("future_sight", 2, "crystals", 50, 1.0, 1, 1.0, "bool_future_sight", "target_lock")

func _register_tier3() -> void:
	_add("temporal_freeze", 3, "void", 15, 2.5, 3, 1.5, "flat_freeze_seconds", "critical_mass")
	_add("singularity", 3, "void", 15, 2.5, 3, 0.1875, "percent_pull_force", "homing")
	_add("auto_turret", 3, "void", 22, 2.5, 3, 1.0, "flat_auto_turret", "extra_battery")
	_add("mirror_array", 3, "void", 19, 2.5, 3, 0.05, "percent_reflect_chance", "city_shield")
	_add("void_boost", 3, "void", 15, 2.5, 3, 1.0, "flat_void", "crystal_boost")

func _register_tier4() -> void:
	_add("ascendant_core", 4, "eter", 37, 2.0, 2, 1.0, "flat_all_currencies_mult")
	_add("eternal_knowledge", 4, "eter", 150, 1.0, 1, 1.0, "bool_keep_upgrades")
	_add("vault", 4, "eter", 112, 1.0, 1, 1.0, "bool_keep_currencies")
	_add("omega_protocol", 4, "eter", 75, 1.0, 1, 0.50, "percent_reward_boost")
	_add("phoenix_protocol", 4, "eter", 56, 2.5, 2, 1.0, "flat_city_revive")

func _add(name: String, tier: int, currency: String, base_cost: int, multiplier: float, max_level: int, effect_per_level: float, effect_type: String, requires := "") -> void:
	upgrades[name] = {
		"tier": tier,
		"currency": currency,
		"base_cost": base_cost,
		"multiplier": multiplier,
		"max_level": max_level,
		"level": 0,
		"effect_per_level": effect_per_level,
		"effect_type": effect_type,
		"requires": requires,
	}

func get_cost(name: String) -> int:
	var u = upgrades[name]
	return int(u["base_cost"] * pow(u["multiplier"], u["level"]))

func can_unlock(name: String) -> bool:
	var req: String = upgrades[name]["requires"]
	if req == "":
		return true
	return upgrades[req]["level"] >= 1

func buy(name: String, currency: CurrencySystem) -> bool:
	var u = upgrades[name]
	if u["level"] >= u["max_level"]:
		return false
	if not can_unlock(name):
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
