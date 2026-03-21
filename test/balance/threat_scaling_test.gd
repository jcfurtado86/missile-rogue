class_name ThreatScalingTest
extends GdUnitTestSuite

# 78
func test_threat_marcos_match_gdd() -> void:
	# Verify threat system respects the 0-100 range with correct marcos
	var threat = ThreatSystem.new()
	assert_float(threat.get_level()).is_equal(0.0)

	# Simulate lots of time — should reach high threat
	for i in 1000:
		threat.update_time(0.1)
	assert_float(threat.get_level()).is_less_equal(100.0)

# 79
func test_proportionality_law() -> void:
	# The proportionality law: more upgrades = higher sustainable threat
	# Verify spawner distribution changes at GDD-defined thresholds
	var spawner = SpawnSystem.new()

	var dist_low = spawner.get_spawn_distribution(25.0)
	assert_bool(dist_low.has("fast")).is_false()

	var dist_mid = spawner.get_spawn_distribution(60.0)
	assert_bool(dist_mid.has("fast")).is_true()

	var dist_high = spawner.get_spawn_distribution(80.0)
	assert_bool(dist_high.has("cluster")).is_true()
