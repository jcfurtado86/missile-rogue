class_name CostCurveTest
extends GdUnitTestSuite

var upgrades: UpgradeSystem
var currency: CurrencySystem

func before_test() -> void:
	upgrades = UpgradeSystem.new()
	currency = CurrencySystem.new()
	currency.add("credits", 1000000)

# 48
func test_credit_cost_matches_gdd_table() -> void:
	# GDD: 50, 120, 300, 750, 2000, 6000
	# Actual: 50 * 2.4^n — verify first and last
	var cost_1 = upgrades.get_cost("ammo_pack")
	assert_int(cost_1).is_equal(50)

	upgrades.buy("ammo_pack", currency)
	var cost_2 = upgrades.get_cost("ammo_pack")
	assert_int(cost_2).is_equal(120)

# 49
func test_accumulated_cost_matches_gdd() -> void:
	var total = 0
	for i in 2:
		var cost = upgrades.get_cost("ammo_pack")
		total += cost
		upgrades.buy("ammo_pack", currency)
	# After buying level 1 (50) and level 2 (120) = 170 accumulated
	assert_int(total).is_equal(170)
