class_name SpecialSystem
extends RefCounted

var charge: float = 0.0
var max_charge: float = 100.0
var charge_per_second: float = 2.5  # ~40s pra recarregar do zero

func update_time(delta: float) -> void:
	charge = minf(charge + charge_per_second * delta, max_charge)

func is_ready() -> bool:
	return charge >= max_charge

func activate() -> bool:
	if not is_ready():
		return false
	charge = 0.0
	return true

func get_charge() -> float:
	return charge
