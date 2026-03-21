class_name SpecialSystemTest
extends GdUnitTestSuite

var special: SpecialSystem

func before_test() -> void:
	special = SpecialSystem.new()

func test_charge_starts_at_zero() -> void:
	assert_float(special.get_charge()).is_equal(0.0)

func test_charge_increases_over_time() -> void:
	special.update_time(1.0)
	assert_float(special.get_charge()).is_greater(0.0)

func test_charge_caps_at_100() -> void:
	special.update_time(60.0)
	assert_float(special.get_charge()).is_equal(100.0)

func test_activate_requires_full_charge() -> void:
	special.update_time(10.0)
	var success = special.activate()
	assert_bool(success).is_false()

func test_activate_resets_charge() -> void:
	special.update_time(60.0)
	special.activate()
	assert_float(special.get_charge()).is_equal(0.0)
