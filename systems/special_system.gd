class_name SpecialSystem
extends RefCounted

var charge: float = 0.0
var max_charge: float = 100.0
var charge_per_kill: float = 5.0

func add_charge(kills: int = 1) -> void:
	charge = minf(charge + charge_per_kill * kills, max_charge)

func is_ready() -> bool:
	return charge >= max_charge

func activate() -> bool:
	if not is_ready():
		return false
	charge = 0.0
	return true

func get_charge() -> float:
	return charge
