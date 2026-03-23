class_name SpawnSystem
extends RefCounted

var base_interval: float = 2.0
var min_interval: float = 0.3

var boss_threat := 100.0  # 100 normal, 300 com omega

func get_spawn_distribution(threat: float) -> Dictionary:
	if threat >= boss_threat:
		return {"boss": true}
	if threat >= 65.0:
		return {"basic": 0.55, "fast": 0.30, "cluster": 0.15}
	if threat >= 30.0:
		return {"basic": 0.65, "fast": 0.35}
	return {"basic": 1.0}

func get_spawn_interval(threat: float) -> float:
	var t = clampf(threat / 100.0, 0.0, 1.0)
	return lerpf(base_interval, min_interval, t)

func should_spawn_boss(threat: float) -> bool:
	return threat >= boss_threat
