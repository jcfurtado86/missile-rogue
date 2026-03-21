class_name CurrencySystemTest
extends GdUnitTestSuite

var currency: CurrencySystem

func before_test() -> void:
	currency = CurrencySystem.new()

# 29
func test_wallet_starts_empty() -> void:
	assert_int(currency.get_amount("credits")).is_equal(0)
	assert_int(currency.get_amount("crystals")).is_equal(0)
	assert_int(currency.get_amount("void")).is_equal(0)
	assert_int(currency.get_amount("eter")).is_equal(0)

# 30
func test_add_credits() -> void:
	currency.add("credits", 50)
	assert_int(currency.get_amount("credits")).is_equal(50)

# 31
func test_add_crystals() -> void:
	currency.add("crystals", 10)
	assert_int(currency.get_amount("crystals")).is_equal(10)

# 32
func test_add_void() -> void:
	currency.add("void", 5)
	assert_int(currency.get_amount("void")).is_equal(5)

# 33
func test_spend_deducts() -> void:
	currency.add("credits", 100)
	var success = currency.spend("credits", 40)
	assert_bool(success).is_true()
	assert_int(currency.get_amount("credits")).is_equal(60)

# 34
func test_spend_fails_without_funds() -> void:
	var success = currency.spend("credits", 100)
	assert_bool(success).is_false()
	assert_int(currency.get_amount("credits")).is_equal(0)

# 35
func test_reset_run_currencies_keeps_eter() -> void:
	currency.add("credits", 100)
	currency.add("crystals", 50)
	currency.add("void", 25)
	currency.add("eter", 10)
	currency.reset_run_currencies()
	assert_int(currency.get_amount("credits")).is_equal(0)
	assert_int(currency.get_amount("crystals")).is_equal(0)
	assert_int(currency.get_amount("void")).is_equal(0)
	assert_int(currency.get_amount("eter")).is_equal(10)
