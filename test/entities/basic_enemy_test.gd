class_name BasicEnemyTest
extends GdUnitTestSuite

# 16
func test_basic_enemy_moves_toward_target() -> void:
	var enemy = EnemyData.new(EnemyData.Type.BASIC)
	var pos = Vector2(500, 0)
	var target = Vector2(500, 1800)
	var new_pos = enemy.move_toward_target(pos, target, 0.016)
	assert_float(new_pos.y).is_greater(0.0)

# 17
func test_basic_enemy_speed_configurable() -> void:
	var enemy = EnemyData.new(EnemyData.Type.BASIC)
	assert_float(enemy.speed).is_equal(200.0)
	enemy.speed = 400.0
	assert_float(enemy.speed).is_equal(400.0)

# 18
func test_basic_enemy_drops_credit() -> void:
	var enemy = EnemyData.new(EnemyData.Type.BASIC)
	assert_str(enemy.currency_type).is_equal("credits")
	assert_int(enemy.drop_amount).is_equal(1)
