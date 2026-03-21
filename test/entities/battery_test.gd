class_name BatteryTest
extends GdUnitTestSuite

var battery: BatteryData

func before_test() -> void:
	battery = BatteryData.new(10, 3.0)

# 1
func test_initial_ammo_equals_max() -> void:
	assert_int(battery.ammo).is_equal(10)

# 2
func test_can_fire_when_has_ammo() -> void:
	assert_bool(battery.can_fire()).is_true()

# 3
func test_cannot_fire_when_empty() -> void:
	for i in 10:
		battery.consume_ammo()
	assert_bool(battery.can_fire()).is_false()

# 4
func test_consume_ammo_decrements() -> void:
	battery.consume_ammo()
	assert_int(battery.ammo).is_equal(9)

# 5
func test_reload_restores_ammo() -> void:
	for i in 10:
		battery.consume_ammo()
	battery.reload()
	assert_int(battery.ammo).is_equal(10)
