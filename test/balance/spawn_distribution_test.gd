class_name SpawnDistributionTest
extends GdUnitTestSuite

var spawner: SpawnSystem

func before_test() -> void:
	spawner = SpawnSystem.new()

# 80
func test_distribution_0_29_matches_gdd() -> void:
	var dist = spawner.get_spawn_distribution(0.0)
	assert_float(dist["basic"]).is_equal(1.0)

	dist = spawner.get_spawn_distribution(29.0)
	assert_float(dist["basic"]).is_equal(1.0)
	assert_bool(dist.has("fast")).is_false()
	assert_bool(dist.has("cluster")).is_false()

# 81
func test_distribution_65_99_matches_gdd() -> void:
	var dist = spawner.get_spawn_distribution(85.0)
	assert_float(dist["basic"]).is_equal(0.55)
	assert_float(dist["fast"]).is_equal(0.30)
	assert_float(dist["cluster"]).is_equal(0.15)
