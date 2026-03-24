class_name CurrencySystem
extends RefCounted

var wallet: Dictionary = {
	"credits": 99999,
	"crystals": 99999,
	"void": 99999,
	"eter": 99999,
}

var unlocked: Dictionary = {
	"credits": true,
	"crystals": true,
	"void": true,
	"eter": true,
}

func add(type: String, amount: int) -> void:
	wallet[type] += amount
	if amount > 0 and not unlocked.get(type, false):
		unlocked[type] = true

func is_unlocked(type: String) -> bool:
	return unlocked.get(type, false)

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
