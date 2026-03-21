class_name BatteryData
extends RefCounted

var max_ammo: int
var ammo: int
var reload_time: float

func _init(p_max_ammo: int = 10, p_reload_time: float = 3.0) -> void:
	max_ammo = p_max_ammo
	ammo = p_max_ammo
	reload_time = p_reload_time

func can_fire() -> bool:
	return ammo > 0

func consume_ammo() -> bool:
	if ammo <= 0:
		return false
	ammo -= 1
	return true

func reload() -> void:
	ammo = max_ammo

func is_empty() -> bool:
	return ammo <= 0
