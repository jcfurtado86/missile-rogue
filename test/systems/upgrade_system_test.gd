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
func test_cost_base_ammo_pack() -> void:
	var cost = upgrades.get_cost("ammo_pack")
	assert_int(cost).is_equal(30)

# 38
func test_cost_exponential_level_5() -> void:
	currency.add("credits", 100000)
	for i in 5:
		upgrades.buy("ammo_pack", currency)
	var cost = upgrades.get_cost("ammo_pack")
	# 30 * 2.0^5 = 960
	assert_int(cost).is_equal(960)

# 39
func test_buy_increments_level() -> void:
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	assert_int(upgrades.get_level("ammo_pack")).is_equal(1)

# 40
func test_buy_deducts_currency() -> void:
	currency.add("credits", 100)
	upgrades.buy("ammo_pack", currency)
	assert_int(currency.get_amount("credits")).is_equal(70)

# 41
func test_buy_fails_without_funds() -> void:
	var success = upgrades.buy("ammo_pack", currency)
	assert_bool(success).is_false()
	assert_int(upgrades.get_level("ammo_pack")).is_equal(0)

# 42
func test_buy_fails_at_max_level() -> void:
	currency.add("credits", 1000000)
	for i in 8:
		upgrades.buy("ammo_pack", currency)
	var level_before = upgrades.get_level("ammo_pack")
	var success = upgrades.buy("ammo_pack", currency)
	assert_bool(success).is_false()
	assert_int(upgrades.get_level("ammo_pack")).is_equal(level_before)

# 43
func test_ammo_pack_effect() -> void:
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	assert_float(upgrades.get_effect("ammo_pack")).is_equal(1.0)

# 44
func test_hyper_drive_effect() -> void:
	currency.add("credits", 1000)
	upgrades.buy("hyper_drive", currency)
	assert_float(upgrades.get_effect("hyper_drive")).is_equal_approx(0.40, 0.001)

# 45
func test_warhead_effect() -> void:
	currency.add("credits", 1000)
	upgrades.buy("warhead", currency)
	assert_float(upgrades.get_effect("warhead")).is_equal_approx(0.40, 0.001)

# 46
func test_credit_boost_effect() -> void:
	currency.add("credits", 1000)
	upgrades.buy("credit_boost", currency)
	assert_float(upgrades.get_effect("credit_boost")).is_equal_approx(0.10, 0.001)

# 47
func test_get_total_invested() -> void:
	currency.add("credits", 1000)
	upgrades.buy("ammo_pack", currency)
	assert_int(upgrades.get_total_invested()).is_equal(30)
