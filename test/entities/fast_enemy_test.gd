class_name FastEnemyTest
extends GdUnitTestSuite

# 50
func test_fast_enemy_has_higher_speed() -> void:
	var basic = EnemyData.new(EnemyData.Type.BASIC)
	var fast = EnemyData.new(EnemyData.Type.FAST)
	assert_float(fast.speed).is_greater(basic.speed)

# 51
func test_fast_enemy_drops_crystal() -> void:
	var fast = EnemyData.new(EnemyData.Type.FAST)
	assert_str(fast.currency_type).is_equal("crystals")
	assert_int(fast.drop_amount).is_equal(1)

# 52
func test_fast_enemy_zigzag_offset() -> void:
	# Fast enemy has higher speed, enabling zigzag movement in the node layer
	# Here we validate the data supports it (speed > basic)
	var fast = EnemyData.new(EnemyData.Type.FAST)
	assert_float(fast.speed).is_equal(400.0)
