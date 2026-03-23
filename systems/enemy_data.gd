class_name EnemyData
extends RefCounted

enum Type { BASIC, FAST, CLUSTER, FRAGMENT, BOSS }

var type: Type
var speed: float
var currency_type: String
var drop_amount: int
var hp: int
var fragment_count: int

func _init(p_type: Type = Type.BASIC) -> void:
	type = p_type
	match type:
		Type.BASIC:
			speed = 200.0
			currency_type = "credits"
			drop_amount = 1
			hp = 1
			fragment_count = 0
		Type.FAST:
			speed = 400.0
			currency_type = "crystals"
			drop_amount = 1
			hp = 1
			fragment_count = 0
		Type.CLUSTER:
			speed = 100.0
			currency_type = ""
			drop_amount = 0
			hp = 1
			fragment_count = randi_range(3, 5)
		Type.FRAGMENT:
			speed = 250.0
			currency_type = "void"
			drop_amount = 1
			hp = 1
			fragment_count = 0
		Type.BOSS:
			speed = 0.0
			currency_type = ""
			drop_amount = 0
			hp = 500
			fragment_count = 0

func move_toward_target(position: Vector2, target: Vector2, delta: float) -> Vector2:
	var direction = position.direction_to(target)
	return position + direction * speed * delta

func take_damage(amount: int) -> void:
	hp -= amount

func is_dead() -> bool:
	return hp <= 0

func is_rage_mode() -> bool:
	return type == Type.BOSS and hp < get_max_hp() * 0.4

func get_max_hp() -> int:
	if type == Type.BOSS:
		return 500
	return 1
