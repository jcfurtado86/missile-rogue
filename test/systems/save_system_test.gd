class_name SaveSystemTest
extends GdUnitTestSuite

var save: SaveSystem

func before_test() -> void:
	save = SaveSystem.new()

# 76
func test_save_and_load_roundtrip() -> void:
	var upgrades = UpgradeSystem.new()
	var ascension = AscensionSystem.new()
	var currency = CurrencySystem.new()

	currency.add("eter", 42)
	currency.add("credits", 1000)
	upgrades.buy("ascendant_core", currency)
	ascension.ascension_count = 3
	ascension.total_eter = 42

	var data = save.to_dict(upgrades, ascension, currency)

	# Load into fresh systems
	var upgrades2 = UpgradeSystem.new()
	var ascension2 = AscensionSystem.new()
	var currency2 = CurrencySystem.new()
	save.from_dict(data, upgrades2, ascension2, currency2)

	assert_int(currency2.get_amount("eter")).is_equal(5)
	assert_int(ascension2.get_ascension_count()).is_equal(3)

# 77
func test_load_missing_file_returns_defaults() -> void:
	var data = save.load_from_file("user://nonexistent_test_save.json")
	assert_int(data.get("eter", 0)).is_equal(0)
	assert_int(data.get("ascension_count", 0)).is_equal(0)

# 78
func test_corrupted_data_returns_defaults() -> void:
	var _defaults = SaveSystem.get_defaults()
	var upgrades = UpgradeSystem.new()
	var ascension = AscensionSystem.new()
	var currency = CurrencySystem.new()

	# Pass empty dict (simulates corrupted data)
	save.from_dict({}, upgrades, ascension, currency)
	assert_int(ascension.get_ascension_count()).is_equal(0)

# 79
func test_eter_persists() -> void:
	var upgrades = UpgradeSystem.new()
	var ascension = AscensionSystem.new()
	var currency = CurrencySystem.new()
	currency.add("eter", 100)
	ascension.total_eter = 100

	var data = save.to_dict(upgrades, ascension, currency)
	assert_int(data["eter"]).is_equal(100)
	assert_int(data["total_eter"]).is_equal(100)
