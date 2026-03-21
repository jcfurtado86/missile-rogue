class_name SpawnSystemTest
extends GdUnitTestSuite

var spawner: SpawnSystem

func before_test() -> void:
	spawner = SpawnSystem.new()

# 24
func test_only_basic_below_30() -> void:
	var dist = spawner.get_spawn_distribution(20.0)
	assert_bool(dist.has("basic")).is_true()
	assert_float(dist["basic"]).is_equal(1.0)
	assert_bool(dist.has("fast")).is_false()

# 25
func test_fast_appears_at_30() -> void:
	var dist = spawner.get_spawn_distribution(30.0)
	assert_bool(dist.has("fast")).is_true()
	assert_float(dist["fast"]).is_equal(0.35)

# 26
func test_cluster_appears_at_65() -> void:
	var dist = spawner.get_spawn_distribution(65.0)
	assert_bool(dist.has("cluster")).is_true()
	assert_float(dist["cluster"]).is_equal(0.15)

# 27
func test_boss_at_100() -> void:
	assert_bool(spawner.should_spawn_boss(100.0)).is_true()
	var dist = spawner.get_spawn_distribution(100.0)
	assert_bool(dist.has("boss")).is_true()

# 28
func test_spawn_interval_decreases_with_threat() -> void:
	var interval_low = spawner.get_spawn_interval(10.0)
	var interval_high = spawner.get_spawn_interval(80.0)
	assert_float(interval_high).is_less(interval_low)
