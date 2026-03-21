class_name PlayerMissileTest
extends GdUnitTestSuite

var missile: MissileData

func before_test() -> void:
	missile = MissileData.new(1200.0, 60.0, 0.15)

# 6
func test_calculate_step_moves_toward_target() -> void:
	var pos = Vector2(0, 0)
	var target = Vector2(100, 0)
	var new_pos = missile.calculate_step(pos, target, 0.016)
	assert_float(new_pos.x).is_greater(0.0)
	assert_float(new_pos.y).is_equal_approx(0.0, 0.01)

# 7
func test_has_arrived_when_close_enough() -> void:
	var pos = Vector2(99, 0)
	var target = Vector2(100, 0)
	assert_bool(missile.has_arrived(pos, target, 5.0)).is_true()

# 8
func test_has_arrived_false_when_far() -> void:
	var pos = Vector2(0, 0)
	var target = Vector2(100, 0)
	assert_bool(missile.has_arrived(pos, target, 5.0)).is_false()
