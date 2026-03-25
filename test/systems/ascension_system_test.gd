class_name AscensionSystemTest
extends GdUnitTestSuite

var ascension: AscensionSystem
var upgrades: UpgradeSystem
var currency: CurrencySystem

func before_test() -> void:
	ascension = AscensionSystem.new()
	upgrades = UpgradeSystem.new()
	currency = CurrencySystem.new()

# 69
func test_eter_calculation() -> void:
	currency.add("credits", 500)
	# total_earned = 500
	var eter = ascension.calculate_eter(currency)
	assert_int(eter).is_equal(int(currency.get_total_earned() / 200.0))

# 70
func test_eter_calculation_large() -> void:
	currency.add("credits", 100000)
	# total_earned = 100000, eter = 100000 / 200 = 500
	var eter = ascension.calculate_eter(currency)
	assert_int(eter).is_equal(500)

# 71
func test_ascension_resets_tiers_1_2_3() -> void:
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	ascension.perform_ascension(upgrades, currency)
	assert_int(upgrades.get_level("ammo_pack")).is_equal(0)

# 72
func test_ascension_resets_run_currencies() -> void:
	currency.add("credits", 1000)
	currency.add("crystals", 50)
	upgrades.buy("ammo_pack", currency)
	ascension.perform_ascension(upgrades, currency)
	assert_int(currency.get_amount("credits")).is_equal(0)
	assert_int(currency.get_amount("crystals")).is_equal(0)

# 73
func test_eter_accumulates_across_ascensions() -> void:
	currency.add("credits", 100000)
	var first_eter = ascension.calculate_eter(currency)
	assert_int(first_eter).is_greater(0)
	ascension.perform_ascension(upgrades, currency)

	currency.add("credits", 100000)
	ascension.perform_ascension(upgrades, currency)

	assert_int(ascension.get_total_eter()).is_greater(first_eter)

# 74
func test_tier4_survives_ascension() -> void:
	currency.add("eter", 1000)
	upgrades.buy("ascendant_core", currency)
	var tier4_level = upgrades.get_level("ascendant_core")

	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	ascension.perform_ascension(upgrades, currency)

	assert_int(upgrades.get_level("ascendant_core")).is_equal(tier4_level)

# 75
func test_ascension_counter_increments() -> void:
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	ascension.perform_ascension(upgrades, currency)
	assert_int(ascension.get_ascension_count()).is_equal(1)
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	ascension.perform_ascension(upgrades, currency)
	assert_int(ascension.get_ascension_count()).is_equal(2)

# New: eternal_knowledge preserves upgrades
func test_eternal_knowledge_preserves_upgrades() -> void:
	currency.add("credits", 1000)
	currency.add("eter", 1000)
	upgrades.buy("ammo_pack", currency)
	upgrades.buy("eternal_knowledge", currency)
	ascension.perform_ascension(upgrades, currency)
	assert_int(upgrades.get_level("ammo_pack")).is_equal(1)

# New: vault preserves currencies
func test_vault_preserves_currencies() -> void:
	currency.add("credits", 1000)
	currency.add("crystals", 50)
	currency.add("eter", 1000)
	upgrades.buy("vault", currency)
	upgrades.buy("ammo_pack", currency)
	ascension.perform_ascension(upgrades, currency)
	assert_int(currency.get_amount("credits")).is_greater(0)
	assert_int(currency.get_amount("crystals")).is_equal(50)
