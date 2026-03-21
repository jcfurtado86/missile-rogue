class_name SpawnDistributionTest
extends GdUnitTestSuite

var spawner: SpawnSystem

func before_test() -> void:
	spawner = SpawnSystem.new()

# 80
func test_distribution_0_49_matches_gdd() -> void:
	# GDD: 0-49 = 100% basic
	var dist = spawner.get_spawn_distribution(0.0)
	assert_float(dist["basic"]).is_equal(1.0)

	dist = spawner.get_spawn_distribution(49.0)
	assert_float(dist["basic"]).is_equal(1.0)
	assert_bool(dist.has("fast")).is_false()
	assert_bool(dist.has("cluster")).is_false()

# 81
func test_distribution_75_99_matches_gdd() -> void:
	# GDD: 75-99 = 55% basic, 30% fast, 15% cluster
	var dist = spawner.get_spawn_distribution(85.0)
	assert_float(dist["basic"]).is_equal(0.55)
	assert_float(dist["fast"]).is_equal(0.30)
	assert_float(dist["cluster"]).is_equal(0.15)
