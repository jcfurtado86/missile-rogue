extends Area2D

signal destroyed(enemy: Area2D, auto_turret: bool)
signal boss_defeated

var data := EnemyData.new(EnemyData.Type.BOSS)

var move_speed := 120.0
var move_direction := 1.0
const MARGIN := 100.0
var boss_y := 300.0

# Rajadas em leque
var anim_time := 0.0
var burst_timer := 0.0
var burst_interval := 3.0
var burst_interval_rage := 1.5
var burst_count := 5
var burst_count_rage := 8

var BurstMissileScene := preload("res://entities/missiles/basic_enemy.tscn")
var BossExplosionScene := preload("res://entities/boss/boss_explosion.tscn")
var ground_y := 1820.0

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	area_entered.connect(_on_area_entered)
	position.y = boss_y
	queue_redraw()

func _draw_ascii() -> void:
	var font := ThemeDB.fallback_font
	var is_rage := data.is_rage_mode()
	var face_text: String
	var face_color: Color
	if is_rage:
		face_text = ">>X<<"
		face_color = Themes.c("enemy_boss_rage")
	else:
		face_text = ">=<"
		face_color = Themes.c("enemy_boss", 0.9)
	var face_size := font.get_string_size(face_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 36)
	draw_string(font, Vector2(-face_size.x / 2.0, face_size.y / 4.0), face_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 36, face_color)
	# HP bar
	var hp_ratio := get_hp_ratio()
	var bar_total := 8
	var bar_filled := int(round(hp_ratio * bar_total))
	var bar_empty := bar_total - bar_filled
	var hp_text := "[" + "|".repeat(bar_filled) + ".".repeat(bar_empty) + "]"
	var hp_size := font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
	draw_string(font, Vector2(-hp_size.x / 2.0, face_size.y / 4.0 + 30), hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 28, face_color)

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii()
		return
	var is_rage := data.is_rage_mode()
	var fill := Themes.c("fill_entity")
	var neon := Themes.c("enemy_boss", 0.9) if not is_rage else Themes.c("enemy_boss_rage")
	var neon_dim := Color(neon.r, neon.g, neon.b, 0.4)

	# --- Rage glow pulsante ---
	if is_rage:
		var pulse := (sin(anim_time * 4.0) + 1.0) * 0.5
		var rage_a := lerpf(0.12, 0.4, pulse)
		var rage_r := lerpf(170.0, 216.0, pulse)
		draw_circle(Vector2.ZERO, rage_r, Themes.glow("enemy_boss_rage", rage_a))
		draw_circle(Vector2.ZERO, 144.0, Themes.glow("enemy_boss_rage", rage_a * 0.6))
		# Raios de energia
		for i in 8:
			var ra := TAU * float(i) / 8 + anim_time * 1.5
			var rl := lerpf(108.0, 144.0, pulse)
			var re := Vector2(cos(ra) * rl, sin(ra) * rl)
			draw_line(Vector2.ZERO, re, Themes.glow("enemy_boss", 0.25 * pulse), 3.0, true)
			draw_line(Vector2.ZERO, re, Themes.glow("enemy_boss", 0.08 * pulse), 10.0, true)
	else:
		# Glow suave normal
		draw_circle(Vector2.ZERO, 153.0, Themes.glow("enemy_boss", 0.1))

	# --- Casco principal — hexagono largo (nave mae) ---
	var hull := PackedVector2Array([
		Vector2(0, -54),     # frente (topo)
		Vector2(-90, -22),   # asa esq frente
		Vector2(-108, 18),   # asa esq tras
		Vector2(-54, 45),    # base esq
		Vector2(54, 45),     # base dir
		Vector2(108, 18),    # asa dir tras
		Vector2(90, -22),    # asa dir frente
	])
	var hull_fill := PackedColorArray()
	for _i in hull.size():
		hull_fill.append(fill)
	draw_polygon(hull, hull_fill)
	for i in hull.size():
		draw_line(hull[i], hull[(i + 1) % hull.size()], neon, 3.0, true)

	# --- Paineis laterais ---
	var panel_l := PackedVector2Array([
		Vector2(-68, -14), Vector2(-99, -4), Vector2(-99, 22), Vector2(-63, 32),
	])
	var panel_r := PackedVector2Array([
		Vector2(68, -14), Vector2(99, -4), Vector2(99, 22), Vector2(63, 32),
	])
	var panel_fill := PackedColorArray()
	for _i in 4:
		panel_fill.append(Themes.c("fill_dark"))
	draw_polygon(panel_l, panel_fill)
	draw_polygon(panel_r, panel_fill)
	for i in panel_l.size():
		draw_line(panel_l[i], panel_l[(i + 1) % panel_l.size()], neon_dim, 1.5, true)
		draw_line(panel_r[i], panel_r[(i + 1) % panel_r.size()], neon_dim, 1.5, true)

	# --- Ponte de comando central ---
	var bridge := PackedVector2Array([
		Vector2(-32, -36), Vector2(0, -50), Vector2(32, -36),
		Vector2(27, -9), Vector2(-27, -9),
	])
	var bridge_fill := PackedColorArray()
	for _i in bridge.size():
		bridge_fill.append(Themes.c("fill_dark"))
	draw_polygon(bridge, bridge_fill)
	for i in bridge.size():
		draw_line(bridge[i], bridge[(i + 1) % bridge.size()], neon, 2.0, true)

	# --- Canhoes laterais ---
	# Esquerdo
	draw_rect(Rect2(-117, 4, 22, 9), fill)
	draw_rect(Rect2(-117, 4, 22, 9), neon_dim, false, 1.5)
	draw_circle(Vector2(-119, 8), 3.0, neon)
	# Direito
	draw_rect(Rect2(95, 4, 22, 9), fill)
	draw_rect(Rect2(95, 4, 22, 9), neon_dim, false, 1.5)
	draw_circle(Vector2(119, 8), 3.0, neon)

	# --- Motor traseiro (base) — 3 bocais ---
	for mx in [-27.0, 0.0, 27.0]:
		draw_rect(Rect2(mx - 7, 40, 14, 11), fill)
		draw_rect(Rect2(mx - 7, 40, 14, 11), neon_dim, false, 1.5)
		# Chama do motor
		var flame_pulse := (sin(anim_time * 8.0 + mx) + 1.0) * 0.5
		var flame_a := lerpf(0.2, 0.6, flame_pulse)
		var flame_h := lerpf(7.0, 14.0, flame_pulse)
		draw_rect(Rect2(mx - 4, 51, 8, flame_h), Color(1.0, 0.3, 0.0, flame_a))

	# --- Cockpit / olho central ---
	if is_rage:
		var eye_pulse := (sin(anim_time * 6.0) + 1.0) * 0.5
		var eye_a := lerpf(0.6, 1.0, eye_pulse)
		# Olho vermelho losango
		var eye := PackedVector2Array([
			Vector2(0, -29), Vector2(-14, -22), Vector2(0, -14), Vector2(14, -22),
		])
		draw_polygon(eye, PackedColorArray([
			Themes.c("enemy_boss_rage", eye_a), Themes.c("enemy_boss_rage", eye_a),
			Themes.c("enemy_boss_rage", eye_a), Themes.c("enemy_boss_rage", eye_a),
		]))
		draw_circle(Vector2(0, -22), 5.0, Color(1.0, 0.5, 0.3, eye_a))
	else:
		# Janela da ponte — losango amarelo
		var eye := PackedVector2Array([
			Vector2(0, -29), Vector2(-14, -22), Vector2(0, -14), Vector2(14, -22),
		])
		draw_polygon(eye, PackedColorArray([
			Color(1.0, 1.0, 0.0, 0.3), Color(1.0, 1.0, 0.0, 0.3),
			Color(1.0, 1.0, 0.0, 0.3), Color(1.0, 1.0, 0.0, 0.3),
		]))
		draw_circle(Vector2(0, -22), 5.0, Color(1.0, 1.0, 1.0, 0.8))

	# --- Linhas decorativas internas ---
	draw_line(Vector2(-54, 9), Vector2(54, 9), neon_dim, 1.5, true)
	draw_line(Vector2(-40, 27), Vector2(40, 27), Color(neon.r, neon.g, neon.b, 0.2), 1.5, true)

func _physics_process(delta: float) -> void:
	anim_time += delta
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
		missile.position = global_position + Vector2(0, 55)
		# Misseis do boss nao contam como kill nem dropam moeda
		missile.speed = 300.0 if data.is_rage_mode() else 200.0
		# Target na direcao do angulo, limitado ao chao
		var direction = Vector2.from_angle(angle)
		var far_target = global_position + direction * 2000.0
		far_target.y = minf(far_target.y, ground_y)
		missile.target_position = far_target
		missile.boss_origin = global_position
		get_parent().add_child(missile)

func _on_area_entered(area: Area2D) -> void:
	if area.collision_layer == 1:
		data.take_damage(1)
		queue_redraw()
		if data.is_dead():
			var auto: bool = area.get("is_auto_turret") == true
			_spawn_boss_explosion()
			boss_defeated.emit()
			destroyed.emit(self, auto)
			call_deferred("queue_free")

func get_hp() -> int:
	return data.hp

func get_max_hp() -> int:
	return data.get_max_hp()

func _spawn_boss_explosion() -> void:
	var explosion = BossExplosionScene.instantiate()
	explosion.position = global_position
	get_parent().add_child(explosion)

func get_hp_ratio() -> float:
	return float(data.hp) / float(data.get_max_hp())
