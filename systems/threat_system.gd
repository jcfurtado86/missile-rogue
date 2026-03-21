class_name ThreatSystem
extends RefCounted

var level: float = 0.0
var time_rate: float = 0.5
var kill_rate: float = 2.0

func update_time(delta: float) -> void:
	level = minf(level + time_rate * delta, 100.0)

func register_kill() -> void:
	level = minf(level + kill_rate, 100.0)

func get_level() -> float:
	return level
