class_name PlayerStats
extends RefCounted

# Posicoes fixas (ratios da largura da tela)
const BATTERY_RATIOS := [0.30, 0.50, 0.70]
const CITY_RATIOS := [0.167, 0.367, 0.633, 0.833]
# Ordem de desbloqueio (do centro pra fora)
const BATTERY_ORDER := [1, 0, 2]
const CITY_ORDER := [1, 2, 0, 3]

# --- Estruturais ---
var num_cities: int
var num_batteries: int

# --- Municao ---
var max_magazines: int
var magazine_size: int
var ammo_regen: float
var reload_time: float

# --- Misseis ---
var missile_speed_mult: float
var explosion_radius_mult: float
var homing_strength: float
var triple_chance: float
var critical_mass_chance: float

# --- Economia ---
var head_start_credits: int
var credits_bonus: int
var crystals_bonus: int
var void_bonus: int

# --- Especial ---
var charge_speed_mult: float

# --- Defesa ---
var shield_cooldown: float  # 0 = sem escudo
var time_warp_chance: float
var has_early_warning: bool

# --- T3 avancados ---
var freeze_seconds: float
var city_revives: int
var pull_force: float
var auto_turret_rate: float
var mirror_chance: float

# --- T4 permanentes ---
var all_currencies_mult: int  # x2, x3
var keep_upgrades: bool
var keep_currencies: bool
var reward_boost_mult: float

func _init(us: UpgradeSystem) -> void:
	# Estruturais
	num_cities = 2 + int(us.get_effect("extra_city"))
	num_batteries = 1 + int(us.get_effect("extra_battery"))

	# Municao
	max_magazines = 2 + int(us.get_effect("ammo_pack"))
	magazine_size = 3 + int(us.get_effect("magazine"))
	ammo_regen = us.get_effect("ammo_regen")
	reload_time = 3.0 * (1.0 - us.get_effect("warp_reload"))

	# Misseis
	missile_speed_mult = 1.0 + us.get_effect("hyper_drive")
	explosion_radius_mult = 1.0 + us.get_effect("warhead")
	homing_strength = us.get_effect("homing")
	triple_chance = us.get_effect("triple_burst")
	critical_mass_chance = us.get_effect("critical_mass")

	# Economia
	head_start_credits = int(us.get_effect("head_start"))
	credits_bonus = int(us.get_effect("credit_boost"))
	crystals_bonus = int(us.get_effect("crystal_boost"))
	void_bonus = int(us.get_effect("void_boost"))

	# Especial
	charge_speed_mult = 1.0 + us.get_effect("overcharge")

	# Defesa
	var shield_level := int(us.get_effect("city_shield"))
	if shield_level <= 0:
		shield_cooldown = 0.0
	elif shield_level == 1:
		shield_cooldown = 30.0
	elif shield_level == 2:
		shield_cooldown = 20.0
	else:
		shield_cooldown = 12.0
	time_warp_chance = us.get_effect("time_warp")
	has_early_warning = us.get_effect("early_warning") > 0

	# T3
	freeze_seconds = us.get_effect("temporal_freeze")
	city_revives = int(us.get_effect("phoenix_protocol"))
	pull_force = us.get_effect("singularity")
	auto_turret_rate = us.get_effect("auto_turret")
	mirror_chance = us.get_effect("mirror_array")

	# T4
	all_currencies_mult = 1 + int(us.get_effect("ascendant_core"))  # nv0=x1, nv1=x2, nv2=x3
	keep_upgrades = us.get_effect("eternal_knowledge") > 0
	keep_currencies = us.get_effect("vault") > 0
	reward_boost_mult = 1.0 + us.get_effect("omega_protocol")

func get_battery_ratios() -> Array[float]:
	var ratios: Array[float] = []
	for i in num_batteries:
		ratios.append(BATTERY_RATIOS[BATTERY_ORDER[i]])
	ratios.sort()
	return ratios

func get_city_ratios() -> Array[float]:
	var ratios: Array[float] = []
	for i in num_cities:
		ratios.append(CITY_RATIOS[CITY_ORDER[i]])
	ratios.sort()
	return ratios
