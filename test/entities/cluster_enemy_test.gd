class_name ClusterEnemyTest
extends GdUnitTestSuite

# 53
func test_cluster_has_lower_speed() -> void:
	var basic = EnemyData.new(EnemyData.Type.BASIC)
	var cluster = EnemyData.new(EnemyData.Type.CLUSTER)
	assert_float(cluster.speed).is_less(basic.speed)

# 54
func test_cluster_fragments_between_3_and_5() -> void:
	# Run multiple times to verify range
	for i in 20:
		var cluster = EnemyData.new(EnemyData.Type.CLUSTER)
		assert_int(cluster.fragment_count).is_greater_equal(3)
		assert_int(cluster.fragment_count).is_less_equal(5)

# 55
func test_each_fragment_drops_void() -> void:
	var fragment = EnemyData.new(EnemyData.Type.FRAGMENT)
	assert_str(fragment.currency_type).is_equal("void")
	assert_int(fragment.drop_amount).is_equal(1)

# 56
func test_cluster_drops_nothing_directly() -> void:
	var cluster = EnemyData.new(EnemyData.Type.CLUSTER)
	assert_str(cluster.currency_type).is_equal("")
	assert_int(cluster.drop_amount).is_equal(0)
