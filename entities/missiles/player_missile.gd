extends Area2D

@export var speed := 1200.0
@export var explosion_radius := 60.0
@export var explosion_duration := 0.4

var target := Vector2.ZERO
var arrived := false
var explosion_time := 0.0

const EXPLOSION_COLORS: Array[Color] = [
	Color(0.0, 1.0, 1.0),   # cyan
	Color(1.0, 0.0, 0.6),   # hot pink
	Color(1.0, 1.0, 0.0),   # amarelo neon
	Color(0.2, 1.0, 0.1),   # verde neon
	Color(0.7, 0.0, 1.0),   # violeta
	Color(1.0, 0.4, 0.0),   # laranja neon
]

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision.disabled = true

func _draw() -> void:
	if not arrived:
		var neon := Color(0.0, 1.0, 1.0)
		var fill := Color(0.0, 0.1, 0.15)
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
		draw_circle(Vector2(0, 0), 16.0, Color(neon.r, neon.g, neon.b, 0.08))
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

func _physics_process(delta: float) -> void:
	if arrived:
		explosion_time += delta
		queue_redraw()
		return
	var direction = global_position.direction_to(target)
	var distance = global_position.distance_to(target)
	var step = speed * delta

	if step >= distance:
		global_position = target
		_explode()
	else:
		global_position += direction * step
		rotation = direction.angle() + PI / 2.0

func _explode() -> void:
	arrived = true
	queue_redraw()
	collision.disabled = false
	var shape = collision.shape as CircleShape2D
	shape.radius = explosion_radius
	get_tree().create_timer(explosion_duration).timeout.connect(_on_explosion_end)

func _on_explosion_end() -> void:
	queue_free()
