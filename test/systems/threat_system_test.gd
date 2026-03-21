class_name ThreatSystemTest
extends GdUnitTestSuite

var threat: ThreatSystem

func before_test() -> void:
	threat = ThreatSystem.new()

# 19
func test_threat_starts_at_zero() -> void:
	assert_float(threat.get_level()).is_equal(0.0)

# 20
func test_threat_increases_over_time() -> void:
	threat.update_time(1.0)
	assert_float(threat.get_level()).is_greater(0.0)

# 21
func test_kill_does_not_increase_threat() -> void:
	threat.register_kill()
	assert_float(threat.get_level()).is_equal(0.0)

# 22
func test_threat_caps_at_100() -> void:
	threat.update_time(300.0)
	assert_float(threat.get_level()).is_equal(100.0)

# 23
func test_threat_rate_is_consistent() -> void:
	threat.update_time(10.0)
	assert_float(threat.get_level()).is_equal(5.0)
