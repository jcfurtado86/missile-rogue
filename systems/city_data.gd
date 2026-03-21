class_name CityData
extends RefCounted

var alive: bool = true

func take_hit() -> void:
	alive = false

func is_alive() -> bool:
	return alive

static func all_dead(cities: Array) -> bool:
	for city in cities:
		if city.is_alive():
			return false
	return true
