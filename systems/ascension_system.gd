class_name AscensionSystem
extends RefCounted

var ascension_count: int = 0
var total_eter: int = 0
var conversion_factor: int = 200

func calculate_eter(upgrade_system: UpgradeSystem) -> int:
	return upgrade_system.get_total_invested() / conversion_factor

func perform_ascension(upgrade_system: UpgradeSystem, currency: CurrencySystem) -> void:
	var eter_gained = calculate_eter(upgrade_system)
	total_eter += eter_gained
	currency.add("eter", eter_gained)
	upgrade_system.reset_tiers(1, 3)
	currency.reset_run_currencies()
	ascension_count += 1

func get_ascension_count() -> int:
	return ascension_count

func get_total_eter() -> int:
	return total_eter
