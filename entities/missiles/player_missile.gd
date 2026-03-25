extends Area2D

signal exploded(hits: int)

@export var speed := 400.0
@export var explosion_radius := 30.0
@export var explosion_duration := 0.4

var target := Vector2.ZERO
var arrived := false
var explosion_time := 0.0
var hit_count := 0

# Upgrade effects
var homing_strength := 0.0
var critical_mass_chance := 0.0
var pull_force := 0.0
var is_auto_turret := false

var EXPLOSION_COLORS: Array[Color]:
	get: return Themes.get_explosion_colors()

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision.disabled = true
	area_entered.connect(_on_area_hit)

func _on_area_hit(area: Area2D) -> void:
	if area.is_in_group("enemy") or area.is_in_group("fragment"):
		hit_count += 1

func _draw() -> void:
	if Themes.mode == ThemeSystem.Mode.ASCII:
		_draw_ascii()
		return
	if not arrived:
		var neon := Themes.c("primary")
		var fill := Themes.c("fill_entity")
		# Forma de flecha/diamante apontando pra cima
		var body := PackedVector2Array([
			Vector2(0, -14),   # ponta
			Vector2(6, 0),     # direita
			Vector2(4, 10),    # base dir
			Vector2(-4, 10),   # base esq
			Vector2(-6, 0),    # esquerda
		])
		# Aletas traseiras
		var fin_l := PackedVector2Array([Vector2(-4, 8), Vector2(-10, 14), Vector2(-3, 12)])
		var fin_r := PackedVector2Array([Vector2(4, 8), Vector2(10, 14), Vector2(3, 12)])
		# Glow
		draw_circle(Vector2(0, 0), 16.0, Themes.glow("primary", 0.08))
		# Corpo
		draw_polygon(body, PackedColorArray([fill, fill, fill, fill, fill]))
		for i in body.size():
			draw_line(body[i], body[(i + 1) % body.size()], Color(neon.r, neon.g, neon.b, 0.9), 1.5, true)
		# Aletas
		draw_polygon(fin_l, PackedColorArray([fill, fill, fill]))
		draw_polygon(fin_r, PackedColorArray([fill, fill, fill]))
		for i in 3:
			draw_line(fin_l[i], fin_l[(i + 1) % 3], Color(neon.r, neon.g, neon.b, 0.6), 1.0, true)
			draw_line(fin_r[i], fin_r[(i + 1) % 3], Color(neon.r, neon.g, neon.b, 0.6), 1.0, true)
		# Ponta brilhante
		draw_circle(Vector2(0, -12), 2.5, Color(1.0, 1.0, 1.0, 0.9))
	else:
		# Explosao com cores piscando
		var idx := int(explosion_time * 20.0) % EXPLOSION_COLORS.size()
		var c := EXPLOSION_COLORS[idx]
		draw_circle(Vector2.ZERO, explosion_radius * 1.3, Color(c.r, c.g, c.b, 0.12))
		draw_circle(Vector2.ZERO, explosion_radius, Color(c.r, c.g, c.b, 0.35))
		draw_circle(Vector2.ZERO, explosion_radius * 0.6, Color(1.0, 1.0, 1.0, 0.5))

func _draw_ascii() -> void:
	var font := ThemeDB.fallback_font
	var fs := 32
	var char_w := font.get_string_size("^", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var offset_x := -char_w / 2.0
	if not arrived:
		var c := Themes.c("primary")
		font.draw_string(get_canvas_item(), Vector2(offset_x, fs / 4.0), "^", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
	else:
		var colors := Themes.get_explosion_colors()
		var progress := explosion_time / explosion_duration
		var count := int(lerp(3.0, 8.0, progress))
		var star_w := font.get_string_size("*", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var star_offset_x := -star_w / 2.0
		for i in count:
			var angle := float(i) / count * TAU + explosion_time * 5.0
			var dist := explosion_radius * progress * (0.5 + 0.5 * sin(float(i) * 1.7))
			var pos := Vector2(cos(angle), sin(angle)) * dist
			var idx := (i + int(explosion_time * 20.0)) % colors.size()
			var c := colors[idx]
			font.draw_string(get_canvas_item(), pos + Vector2(star_offset_x, fs / 4.0), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)

func _physics_process(delta: float) -> void:
	if arrived:
		explosion_time += delta
		# Singularity — puxa inimigos durante explosao
		if pull_force > 0.0:
			_apply_pull(delta)
		queue_redraw()
		return

	# Homing — curva em direcao ao inimigo mais proximo
	if homing_strength > 0.0:
		var closest_enemy := _find_closest_enemy()
		if closest_enemy:
			target = target.lerp(closest_enemy.global_position, homing_strength * delta * 3.0)

	var direction = global_position.direction_to(target)
	var distance = global_position.distance_to(target)
	var step = speed * delta

	if step >= distance:
		global_position = target
		_explode()
	else:
		global_position += direction * step
		rotation = direction.angle() + PI / 2.0

func _find_closest_enemy() -> Area2D:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var closest: Area2D = null
	var closest_dist := 300.0  # raio maximo de busca
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	# Tambem busca fragmentos
	for frag in get_tree().get_nodes_in_group("fragment"):
		if not is_instance_valid(frag):
			continue
		var dist := global_position.distance_to(frag.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = frag
	return closest

func _apply_pull(delta: float) -> void:
	var pull_radius := explosion_radius * 3.0
	var pull_strength := pull_force * 500.0 * delta
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		# Misseis do boss sao imunes ao pull dentro do glow
		if enemy.has_meta("boss_origin") or ("boss_origin" in enemy and enemy.boss_origin != Vector2.ZERO):
			var boss_nodes := get_tree().get_nodes_in_group("boss")
			if not boss_nodes.is_empty():
				var boss = boss_nodes[0]
				if enemy.global_position.distance_to(boss.global_position) < 160.0:
					continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < pull_radius and dist > 5.0:
			var pull_dir: Vector2 = global_position - enemy.global_position
			var pull_vec := pull_dir.normalized() * pull_strength * (1.0 - dist / pull_radius)
			if enemy.is_in_group("boss"):
				pull_vec.y = 0.0
			enemy.global_position += pull_vec
	for frag in get_tree().get_nodes_in_group("fragment"):
		if not is_instance_valid(frag):
			continue
		var dist := global_position.distance_to(frag.global_position)
		if dist < pull_radius and dist > 5.0:
			var pull_dir: Vector2 = global_position - frag.global_position
			frag.global_position += pull_dir.normalized() * pull_strength * (1.0 - dist / pull_radius)

func _explode() -> void:
	arrived = true
	queue_redraw()
	SoundManager.explosion()

	# Critical mass — chance de explosao 2x maior
	if critical_mass_chance > 0.0 and randf() < critical_mass_chance:
		explosion_radius *= 2.0

	collision.disabled = false
	var shape = collision.shape as CircleShape2D
	shape.radius = explosion_radius

	get_tree().create_timer(explosion_duration).timeout.connect(_on_explosion_end)

func _on_explosion_end() -> void:
	exploded.emit(hit_count)
	queue_free()
