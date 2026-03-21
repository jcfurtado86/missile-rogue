class_name AscensionSystemTest
extends GdUnitTestSuite

var ascension: AscensionSystem
var upgrades: UpgradeSystem
var currency: CurrencySystem

func before_test() -> void:
	ascension = AscensionSystem.new()
	upgrades = UpgradeSystem.new()
	currency = CurrencySystem.new()

func _invest(amount: int) -> void:
	currency.add("credits", amount)
	while currency.get_amount("credits") >= upgrades.get_cost("ammo_pack"):
		upgrades.buy("ammo_pack", currency)

# 69
func test_eter_calculation_500_invested() -> void:
	# Manually set total invested
	currency.add("credits", 500)
	upgrades.buy("ammo_pack", currency)  # costs 50
	upgrades.buy("ammo_pack", currency)  # costs 120
	upgrades.buy("ammo_pack", currency)  # costs 288
	# Total invested = 50 + 120 + 288 = 458
	# With conversion factor 200: 458 / 200 = 2
	var eter = ascension.calculate_eter(upgrades)
	assert_int(eter).is_equal(upgrades.get_total_invested() / 200)

# 70
func test_eter_calculation_8000_invested() -> void:
	currency.add("credits", 100000)
	# Buy many upgrades to get total invested near 8000
	for i in 6:
		upgrades.buy("ammo_pack", currency)
	for i in 6:
		upgrades.buy("hyper_drive", currency)
	var eter = ascension.calculate_eter(upgrades)
	assert_int(eter).is_equal(upgrades.get_total_invested() / 200)

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
	# Invest enough to get >0 eter (need >200 total invested)
	currency.add("credits", 100000)
	for i in 4:
		upgrades.buy("ammo_pack", currency)
	# total invested: 50 + 120 + 288 + 691 = 1149 -> 1149/200 = 5 eter
	var first_eter = ascension.calculate_eter(upgrades)
	assert_int(first_eter).is_greater(0)
	ascension.perform_ascension(upgrades, currency)

	# Second ascension — buy again after reset
	currency.add("credits", 100000)
	for i in 4:
		upgrades.buy("ammo_pack", currency)
	ascension.perform_ascension(upgrades, currency)

	assert_int(ascension.get_total_eter()).is_greater(first_eter)

# 74
func test_tier4_survives_ascension() -> void:
	# Buy a tier 4 upgrade first
	currency.add("eter", 1000)
	upgrades.buy("ascendant_core", currency)
	var tier4_level = upgrades.get_level("ascendant_core")

	# Now do ascension with some tier 1 upgrades
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
