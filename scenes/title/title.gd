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
	if has_node("ConfirmPopup"):
		return
	var scr := get_viewport().get_visible_rect().size

	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.name = "ConfirmPopup"
	dimmer.color = Color(0, 0, 0, 0.7)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	# Panel
	var pw := 500.0
	var ph := 280.0
	var panel := Control.new()
	panel.offset_left = (scr.x - pw) / 2.0
	panel.offset_top = (scr.y - ph) / 2.0
	panel.offset_right = (scr.x + pw) / 2.0
	panel.offset_bottom = (scr.y + ph) / 2.0
	dimmer.add_child(panel)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.02, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var border := Control.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := Color(1.0, 0.2, 0.2)
	border.draw.connect(func():
		var s := border.size
		border.draw_rect(Rect2(0, 0, s.x, s.y), col, false, 2.0)
	)
	panel.add_child(border)

	var title := Label.new()
	title.text = "APAGAR DADOS?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", col)
	title.offset_left = 20.0
	title.offset_top = 30.0
	title.offset_right = pw - 20.0
	title.offset_bottom = 75.0
	panel.add_child(title)

	var desc := Label.new()
	desc.text = "Todo progresso sera perdido.\nEssa acao nao pode ser desfeita."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 22)
	desc.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))
	desc.offset_left = 20.0
	desc.offset_top = 85.0
	desc.offset_right = pw - 20.0
	desc.offset_bottom = 155.0
	panel.add_child(desc)

	var btn_box := HBoxContainer.new()
	btn_box.offset_left = 40.0
	btn_box.offset_top = 175.0
	btn_box.offset_right = pw - 40.0
	btn_box.offset_bottom = 250.0
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 30)
	panel.add_child(btn_box)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCELAR"
	cancel_btn.custom_minimum_size = Vector2(180, 60)
	cancel_btn.add_theme_font_size_override("font_size", 24)
	_style_neon_button(cancel_btn, Color(0.5, 0.5, 0.5))
	cancel_btn.pressed.connect(func(): dimmer.queue_free())
	btn_box.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "APAGAR"
	confirm_btn.custom_minimum_size = Vector2(180, 60)
	confirm_btn.add_theme_font_size_override("font_size", 24)
	_style_neon_button(confirm_btn, col)
	confirm_btn.pressed.connect(func():
		dimmer.queue_free()
		reset_pressed.emit()
	)
	btn_box.add_child(confirm_btn)
