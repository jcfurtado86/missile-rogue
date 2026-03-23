extends Control

signal play_pressed
signal reset_pressed

var distant_battle := DistantBattle.new()
var battle_overlay: Control
var title_draw: Control
var title_pulse := 0.0

func _ready() -> void:
	# Background shader ja vem do .tscn

	# Batalha distante
	battle_overlay = Control.new()
	battle_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_overlay.draw.connect(_draw_distant_battle)
	$Background.add_sibling(battle_overlay)
	move_child(battle_overlay, 1)

	# Titulo desenhado proceduralmente
	title_draw = Control.new()
	title_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_draw.draw.connect(_draw_title)
	add_child(title_draw)
	move_child(title_draw, 2)

	# Estilo neon nos botoes
	var neon_pink := Color(1.0, 0.0, 0.6)
	var neon_red := Color(1.0, 0.2, 0.2)
	var neon_dim := Color(0.5, 0.5, 0.5)
	_style_neon_button($Buttons/PlayButton, neon_pink)
	_style_neon_button($Buttons/ResetButton, neon_red)
	_style_neon_button($Buttons/QuitButton, neon_dim)

	$Buttons/PlayButton.pressed.connect(func(): play_pressed.emit())
	$Buttons/ResetButton.pressed.connect(_on_reset)
	$Buttons/QuitButton.pressed.connect(func(): get_tree().quit())

func _process(delta: float) -> void:
	title_pulse += delta
	var scr := get_viewport().get_visible_rect().size
	distant_battle.update(delta, scr, scr.y * 0.55)
	battle_overlay.queue_redraw()
	title_draw.queue_redraw()

func _draw_distant_battle() -> void:
	distant_battle.draw(battle_overlay)

func _draw_title() -> void:
	var font := ThemeDB.fallback_font
	var scr := title_draw.size
	var cx := scr.x / 2.0

	# MISSILE
	var missile_size := 128
	var missile_text := "MISSILE"
	var missile_w := font.get_string_size(missile_text, HORIZONTAL_ALIGNMENT_LEFT, -1, missile_size).x
	var missile_y := scr.y * 0.22

	# Glow pulsante (multiplas camadas com offsets maiores)
	var pulse := sin(title_pulse * 2.5) * 0.5 + 0.5  # 0..1
	var glow_spread := 4.0 + pulse * 4.0
	var glow_alpha := 0.08 + pulse * 0.12
	var glow_col := Color(1.0, 0.0, 0.6, glow_alpha)
	for layer in 3:
		var s := glow_spread * (layer + 1) * 0.6
		for offset in [Vector2(-s, -s), Vector2(s, -s), Vector2(-s, s), Vector2(s, s), Vector2(0, -s), Vector2(0, s), Vector2(-s, 0), Vector2(s, 0)]:
			title_draw.draw_string(font, Vector2(cx - missile_w / 2.0 + offset.x, missile_y + offset.y), missile_text, HORIZONTAL_ALIGNMENT_LEFT, -1, missile_size, Color(glow_col.r, glow_col.g, glow_col.b, glow_alpha * (0.4 / (layer + 1))))

	# Texto principal
	var main_col := Color(1.0, 0.0, 0.6)
	title_draw.draw_string(font, Vector2(cx - missile_w / 2.0, missile_y), missile_text, HORIZONTAL_ALIGNMENT_LEFT, -1, missile_size, main_col)

	# ROGUE
	var rogue_size := 96
	var rogue_text := "ROGUE"
	var rogue_w := font.get_string_size(rogue_text, HORIZONTAL_ALIGNMENT_LEFT, -1, rogue_size).x
	var rogue_y := missile_y + 100

	var rogue_glow := Color(0.0, 1.0, 1.0, glow_alpha)
	for layer in 3:
		var s := glow_spread * (layer + 1) * 0.6
		for offset in [Vector2(-s, -s), Vector2(s, -s), Vector2(-s, s), Vector2(s, s), Vector2(0, -s), Vector2(0, s), Vector2(-s, 0), Vector2(s, 0)]:
			title_draw.draw_string(font, Vector2(cx - rogue_w / 2.0 + offset.x, rogue_y + offset.y), rogue_text, HORIZONTAL_ALIGNMENT_LEFT, -1, rogue_size, Color(rogue_glow.r, rogue_glow.g, rogue_glow.b, glow_alpha * (0.4 / (layer + 1))))

	title_draw.draw_string(font, Vector2(cx - rogue_w / 2.0, rogue_y), rogue_text, HORIZONTAL_ALIGNMENT_LEFT, -1, rogue_size, Color(0.0, 1.0, 1.0))

	# Linha separadora neon
	var line_y := rogue_y + 40
	var line_w := maxf(missile_w, rogue_w) * 0.8
	var line_alpha := 0.3 + sin(title_pulse * 1.5) * 0.15
	title_draw.draw_line(Vector2(cx - line_w / 2.0, line_y), Vector2(cx + line_w / 2.0, line_y), Color(1.0, 0.0, 0.6, line_alpha), 2.5, true)

func _style_neon_button(btn: Button, col: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(col.r * 0.08, col.g * 0.08, col.b * 0.08, 0.85)
	normal.border_color = col
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(col.r * 0.15, col.g * 0.15, col.b * 0.15, 0.9)
	hover.border_color = Color(col.r, col.g, col.b, 1.0)
	hover.set_border_width_all(3)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 0.95)
	pressed.border_color = Color(minf(col.r * 1.3, 1.0), minf(col.g * 1.3, 1.0), minf(col.b * 1.3, 1.0))
	pressed.set_border_width_all(3)
	pressed.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", Color(minf(col.r * 1.2, 1.0), minf(col.g * 1.2, 1.0), minf(col.b * 1.2, 1.0)))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))

func _on_reset() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("save.json"):
		dir.remove("save.json")
	reset_pressed.emit()
