extends Area2D

signal destroyed(enemy: Area2D)
signal boss_defeated

var data := EnemyData.new(EnemyData.Type.BOSS)

var move_speed := 120.0
var move_direction := 1.0
const MARGIN := 100.0
const BOSS_Y := 200.0

# Rajadas em leque
var burst_timer := 0.0
var burst_interval := 3.0
var burst_interval_rage := 1.5
var burst_count := 5
var burst_count_rage := 8

var BurstMissileScene := preload("res://entities/missiles/basic_enemy.tscn")

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	area_entered.connect(_on_area_entered)
	position.y = BOSS_Y
	queue_redraw()

func _draw() -> void:
	var is_rage := data.is_rage_mode()
	# Glow externo massivo
	var glow_color := Color(1.0, 0.0, 0.2, 0.15) if not is_rage else Color(1.0, 0.0, 0.0, 0.25)
	draw_circle(Vector2.ZERO, 80.0, glow_color)
	# Aura neon
	var aura_color := Color(1.0, 0.0, 0.3, 0.2) if not is_rage else Color(1.0, 0.0, 0.0, 0.4)
	draw_circle(Vector2.ZERO, 60.0, aura_color)
	# Corpo — outline neon vermelho
	draw_circle(Vector2.ZERO, 45.0, Color(0.1, 0.0, 0.02))
	draw_arc(Vector2.ZERO, 45.0, 0, TAU, 64, Color(1.0, 0.0, 0.3, 0.9), 3.0, true)
	# Anel interno
	draw_arc(Vector2.ZERO, 30.0, 0, TAU, 48, Color(1.0, 0.0, 0.3, 0.3), 1.5, true)
	# Olho neon amarelo
	draw_circle(Vector2.ZERO, 14.0, Color(1.0, 1.0, 0.0, 0.2))
	draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.95, 0.0, 0.9))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 1.0, 1.0))

func _physics_process(delta: float) -> void:
	# Movimento horizontal
	position.x += move_direction * _current_speed() * delta
	if position.x > 1080.0 - MARGIN:
		move_direction = -1.0
	elif position.x < MARGIN:
		move_direction = 1.0

	# Rajadas
	burst_timer -= delta
	if burst_timer <= 0.0:
		_fire_burst()
		burst_timer = _current_burst_interval()

	queue_redraw()

func _current_speed() -> float:
	return move_speed * (1.5 if data.is_rage_mode() else 1.0)

func _current_burst_interval() -> float:
	return burst_interval_rage if data.is_rage_mode() else burst_interval

func _current_burst_count() -> int:
	return burst_count_rage if data.is_rage_mode() else burst_count

func _fire_burst() -> void:
	var count = _current_burst_count()
	var spread = PI * 0.4
	var base_angle = PI / 2.0  # Aponta pra baixo

	for i in count:
		var angle = base_angle + lerpf(-spread / 2, spread / 2, float(i) / max(count - 1, 1))
		var missile = BurstMissileScene.instantiate()
		missile.position = global_position + Vector2(0, 45)
		# Misseis do boss nao contam como kill nem dropam moeda
		missile.speed = 300.0 if data.is_rage_mode() else 200.0
		# Setar target bem longe na direcao do angulo pra ele ir reto
		var direction = Vector2.from_angle(angle)
		missile.target_position = global_position + direction * 2000.0
		get_parent().add_child(missile)

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		data.take_damage(1)
		queue_redraw()
		if data.is_dead():
			boss_defeated.emit()
			destroyed.emit(self)
			call_deferred("queue_free")

func get_hp() -> int:
	return data.hp

func get_max_hp() -> int:
	return data.get_max_hp()

func get_hp_ratio() -> float:
	return float(data.hp) / float(data.get_max_hp())
