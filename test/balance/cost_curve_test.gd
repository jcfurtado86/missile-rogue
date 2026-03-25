class_name CostCurveTest
extends GdUnitTestSuite

var upgrades: UpgradeSystem
var currency: CurrencySystem

func before_test() -> void:
	upgrades = UpgradeSystem.new()
	currency = CurrencySystem.new()
	currency.add("credits", 1000000)

# 48
func test_credit_cost_matches_ammo_pack() -> void:
	# ammo_pack: base 11, mult 2.0
	var cost_1 = upgrades.get_cost("ammo_pack")
	assert_int(cost_1).is_equal(11)

	upgrades.buy("ammo_pack", currency)
	var cost_2 = upgrades.get_cost("ammo_pack")
	assert_int(cost_2).is_equal(22)

# 49
func test_accumulated_cost() -> void:
	var total = 0
	for i in 2:
		var cost = upgrades.get_cost("ammo_pack")
		total += cost
		upgrades.buy("ammo_pack", currency)
	# 11 + 22 = 33 accumulated
	assert_int(total).is_equal(33)
