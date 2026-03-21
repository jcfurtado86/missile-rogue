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
	_add("ammo_pack", 1, "credits", 50, 2.4, 6, 8.0, "flat_ammo")
	_add("hyper_drive", 1, "credits", 50, 2.4, 6, 0.08, "percent_speed")
	_add("warhead", 1, "credits", 50, 2.4, 6, 0.08, "percent_radius")
	_add("profit_matrix", 1, "credits", 50, 2.4, 6, 0.08, "percent_credits")
	_add("overcharge", 1, "credits", 50, 2.4, 5, 0.10, "percent_charge_speed")
	_add("head_start", 1, "credits", 50, 2.4, 5, 15.0, "flat_credits_start")
	_add("time_warp", 1, "credits", 50, 2.4, 4, 0.05, "percent_slow_chance")
	_add("chain_reaction", 1, "credits", 50, 2.4, 4, 0.05, "percent_chain_chance")
	_add("triple_burst", 1, "credits", 50, 2.4, 4, 0.08, "percent_triple_chance")
	_add("overdrive", 1, "credits", 50, 2.4, 4, 1.0, "flat_combo_reduction")
	_add("early_warning", 1, "credits", 50, 2.4, 2, 1.0, "bool_warning")
	_add("city_shield", 1, "credits", 50, 2.4, 3, 1.0, "flat_extra_city")

func _register_tier2() -> void:
	_add("nova_core", 2, "crystals", 30, 2.5, 5, 0.15, "percent_special_radius")
	_add("critical_mass", 2, "crystals", 30, 2.5, 5, 0.02, "percent_double_explosion")
	_add("aura_field", 2, "crystals", 30, 2.5, 4, 0.10, "percent_repel_radius")
	_add("overlord_bane", 2, "crystals", 30, 2.5, 4, 0.08, "percent_boss_hp_reduction")
	_add("crystal_lens", 2, "crystals", 30, 2.5, 4, 0.20, "percent_all_currencies")
	_add("temporal_rift", 2, "crystals", 30, 2.5, 5, 0.08, "percent_threat_slow")
	_add("warp_reload", 2, "crystals", 30, 2.5, 4, 0.15, "percent_reload_ammo")
	_add("iron_dome", 2, "crystals", 30, 2.5, 2, 1.0, "flat_bonus_city")

func _register_tier3() -> void:
	_add("twin_cannons", 3, "void", 20, 2.5, 3, 1.0, "flat_extra_missile")
	_add("temporal_freeze", 3, "void", 20, 2.5, 3, 1.0, "flat_freeze_seconds")
	_add("phoenix_protocol", 3, "void", 20, 2.5, 2, 1.0, "flat_city_revive")
	_add("singularity", 3, "void", 20, 2.5, 3, 0.15, "percent_pull_force")
	_add("mirror_array", 3, "void", 20, 2.5, 4, 0.03, "percent_reflect_chance")
	_add("overclock", 3, "void", 20, 2.5, 3, 2.0, "flat_double_cadence_seconds")

func _register_tier4() -> void:
	_add("ascendant_core", 4, "eter", 50, 2.0, 3, 0.05, "percent_void_boost")
	_add("void_resonance", 4, "eter", 50, 2.0, 2, 1.0, "flat_void_on_special")
	_add("eternal_city", 4, "eter", 100, 1.0, 1, 1.0, "bool_indestructible_city")
	_add("omega_protocol", 4, "eter", 150, 1.0, 1, 0.50, "percent_reward_boost")

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
