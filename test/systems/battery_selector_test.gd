class_name BatterySelectorTest
extends GdUnitTestSuite

var selector: BatterySelector

func before_test() -> void:
	selector = BatterySelector.new()

# 9
func test_selects_closest_battery() -> void:
	var batteries = [BatteryData.new(), BatteryData.new(), BatteryData.new()]
	var positions = [Vector2(100, 500), Vector2(300, 500), Vector2(500, 500)]
	var target = Vector2(280, 200)
	var index = selector.find_closest(batteries, positions, target)
	assert_int(index).is_equal(1)

# 10
func test_skips_empty_battery() -> void:
	var batteries = [BatteryData.new(), BatteryData.new(), BatteryData.new()]
	var positions = [Vector2(100, 500), Vector2(300, 500), Vector2(500, 500)]
	# Esvazia a bateria mais proxima
	for i in 10:
		batteries[1].consume_ammo()
	var target = Vector2(280, 200)
	var index = selector.find_closest(batteries, positions, target)
	assert_int(index).is_not_equal(1)

# 11
func test_returns_neg_one_when_all_empty() -> void:
	var batteries = [BatteryData.new(), BatteryData.new(), BatteryData.new()]
	var positions = [Vector2(100, 500), Vector2(300, 500), Vector2(500, 500)]
	for b in batteries:
		for i in 10:
			b.consume_ammo()
	var index = selector.find_closest(batteries, positions, Vector2(200, 200))
	assert_int(index).is_equal(-1)
