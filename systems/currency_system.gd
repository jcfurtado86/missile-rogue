class_name CurrencySystem
extends RefCounted

var wallet: Dictionary = {
	"credits": 0,
	"crystals": 0,
	"void": 0,
	"eter": 0,
}

func add(type: String, amount: int) -> void:
	wallet[type] += amount

func spend(type: String, amount: int) -> bool:
	if wallet[type] < amount:
		return false
	wallet[type] -= amount
	return true

func get_amount(type: String) -> int:
	return wallet[type]

func reset_run_currencies() -> void:
	wallet["credits"] = 0
	wallet["crystals"] = 0
	wallet["void"] = 0
