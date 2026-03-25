class_name CurrencySystem
extends RefCounted

var wallet: Dictionary = {
	"credits": 0,
	"crystals": 0,
	"void": 0,
	"eter": 0,
}

var unlocked: Dictionary = {
	"credits": true,
	"crystals": false,
	"void": false,
	"eter": false,
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
