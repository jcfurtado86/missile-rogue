class_name UpgradeSystemTest
extends GdUnitTestSuite

var upgrades: UpgradeSystem
var currency: CurrencySystem

func before_test() -> void:
	upgrades = UpgradeSystem.new()
	currency = CurrencySystem.new()

# 36
func test_upgrade_starts_at_level_zero() -> void:
	assert_int(upgrades.get_level("ammo_pack")).is_equal(0)

# 37
func test_cost_exponential_level_1() -> void:
	var cost = upgrades.get_cost("ammo_pack")
	assert_int(cost).is_equal(50)

# 38
func test_cost_exponential_level_6() -> void:
	# Simula compras ate nivel 5 pra checar custo do nivel 6
	currency.add("credits", 100000)
	for i in 5:
		upgrades.buy("ammo_pack", currency)
	var cost = upgrades.get_cost("ammo_pack")
	# 50 * 2.4^5 = 50 * 79.62 = ~3981
	assert_int(cost).is_greater(3000)

# 39
func test_buy_increments_level() -> void:
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	assert_int(upgrades.get_level("ammo_pack")).is_equal(1)

# 40
func test_buy_deducts_currency() -> void:
	currency.add("credits", 100)
	upgrades.buy("ammo_pack", currency)
	assert_int(currency.get_amount("credits")).is_equal(50)

# 41
func test_buy_fails_without_funds() -> void:
	var success = upgrades.buy("ammo_pack", currency)
	assert_bool(success).is_false()
	assert_int(upgrades.get_level("ammo_pack")).is_equal(0)

# 42
func test_buy_fails_at_max_level() -> void:
	currency.add("credits", 1000000)
	for i in 6:
		upgrades.buy("ammo_pack", currency)
	var level_before = upgrades.get_level("ammo_pack")
	var success = upgrades.buy("ammo_pack", currency)
	assert_bool(success).is_false()
	assert_int(upgrades.get_level("ammo_pack")).is_equal(level_before)

# 43
func test_ammo_pack_effect() -> void:
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	assert_float(upgrades.get_effect("ammo_pack")).is_equal(8.0)

# 44
func test_hyper_drive_effect() -> void:
	currency.add("credits", 1000)
	upgrades.buy("hyper_drive", currency)
	assert_float(upgrades.get_effect("hyper_drive")).is_equal_approx(0.08, 0.001)

# 45
func test_warhead_effect() -> void:
	currency.add("credits", 1000)
	upgrades.buy("warhead", currency)
	assert_float(upgrades.get_effect("warhead")).is_equal_approx(0.08, 0.001)

# 46
func test_profit_matrix_effect() -> void:
	currency.add("credits", 1000)
	upgrades.buy("profit_matrix", currency)
	assert_float(upgrades.get_effect("profit_matrix")).is_equal_approx(0.08, 0.001)

# 47
func test_get_total_invested() -> void:
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	assert_int(upgrades.get_total_invested()).is_equal(50)
