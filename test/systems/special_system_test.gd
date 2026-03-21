class_name SpecialSystemTest
extends GdUnitTestSuite

var special: SpecialSystem

func before_test() -> void:
	special = SpecialSystem.new()

# 67
func test_charge_starts_at_zero() -> void:
	assert_float(special.get_charge()).is_equal(0.0)

# 68
func test_charge_increases_on_kill() -> void:
	special.add_charge(1)
	assert_float(special.get_charge()).is_greater(0.0)

# 69
func test_charge_caps_at_100() -> void:
	special.add_charge(100)
	assert_float(special.get_charge()).is_equal(100.0)

# 70
func test_activate_requires_full_charge() -> void:
	special.add_charge(5)
	var success = special.activate()
	assert_bool(success).is_false()

# 71
func test_activate_resets_charge() -> void:
	special.add_charge(20)
	special.activate()
	assert_float(special.get_charge()).is_equal(0.0)
