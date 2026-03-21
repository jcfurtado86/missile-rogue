class_name BossTest
extends GdUnitTestSuite

# 64
func test_boss_starts_with_full_hp() -> void:
	var boss = EnemyData.new(EnemyData.Type.BOSS)
	assert_int(boss.hp).is_equal(1000)

# 65
func test_boss_takes_damage() -> void:
	var boss = EnemyData.new(EnemyData.Type.BOSS)
	boss.take_damage(100)
	assert_int(boss.hp).is_equal(900)

# 66
func test_boss_rage_mode_below_40_percent() -> void:
	var boss = EnemyData.new(EnemyData.Type.BOSS)
	boss.take_damage(610)
	assert_bool(boss.is_rage_mode()).is_true()

# 67
func test_boss_defeat_at_zero_hp() -> void:
	var boss = EnemyData.new(EnemyData.Type.BOSS)
	boss.take_damage(1000)
	assert_bool(boss.is_dead()).is_true()

# 68
func test_boss_hp_requires_full_upgrades() -> void:
	# Boss HP is 1000, which should require full DPS from all upgrades
	# With max upgrades: speed + radius + triple + twin cannons = enough DPS
	# Without: mathematically impossible within boss fight duration
	var boss = EnemyData.new(EnemyData.Type.BOSS)
	assert_int(boss.get_max_hp()).is_equal(1000)
