class_name BatterySelector
extends RefCounted

func find_closest(batteries: Array, positions: Array, target: Vector2) -> int:
	var closest_index := -1
	var closest_dist := INF
	for i in batteries.size():
		var battery: BatteryData = batteries[i]
		if not battery.can_fire():
			continue
		var dist = positions[i].distance_to(target)
		if dist < closest_dist:
			closest_dist = dist
			closest_index = i
	return closest_index
