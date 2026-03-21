class_name CityTest
extends GdUnitTestSuite

# 12
func test_city_starts_alive() -> void:
	var city = CityData.new()
	assert_bool(city.is_alive()).is_true()

# 13
func test_city_dies_on_hit() -> void:
	var city = CityData.new()
	city.take_hit()
	assert_bool(city.is_alive()).is_false()

# 14
func test_destroyed_city_ignores_further_hits() -> void:
	var city = CityData.new()
	city.take_hit()
	city.take_hit()
	assert_bool(city.is_alive()).is_false()

# 15
func test_all_cities_dead_returns_true() -> void:
	var cities = [CityData.new(), CityData.new(), CityData.new()]
	for city in cities:
		city.take_hit()
	assert_bool(CityData.all_dead(cities)).is_true()
