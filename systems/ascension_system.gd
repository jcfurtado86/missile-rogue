class_name AscensionSystem
extends RefCounted

var ascension_count: int = 0
var total_eter: int = 0
var conversion_factor: int = 200

func calculate_eter(currency: CurrencySystem) -> int:
	@warning_ignore("integer_division")
	return currency.get_total_earned() / conversion_factor

func perform_ascension(upgrade_system: UpgradeSystem, currency: CurrencySystem) -> void:
	var eter_gained = calculate_eter(currency)
	total_eter += eter_gained
	currency.add("eter", eter_gained)
	var keep_upgrades := upgrade_system.get_effect("eternal_knowledge") > 0
	var keep_currencies := upgrade_system.get_effect("vault") > 0
	if not keep_upgrades:
		upgrade_system.reset_tiers(1, 3)
	if not keep_currencies:
		currency.reset_run_currencies()
	currency.total_earned = 0
	ascension_count += 1

func get_ascension_count() -> int:
	return ascension_count

func get_total_eter() -> int:
	return total_eter
