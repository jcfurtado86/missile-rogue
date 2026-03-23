extends CanvasLayer

@onready var threat_label: Label = $ThreatLabel
@onready var threat_bar: ProgressBar = $ThreatBar
@onready var credits_label: Label = $CreditsLabel
var currency_draw: Control
var hud_currencies: Array = []

const GEM_COLORS := {
	"credits": Color(1.0, 0.0, 0.6),
	"crystals": Color(0.2, 1.0, 0.1),
	"void": Color(0.7, 0.0, 1.0),
	"eter": Color(1.0, 0.5, 0.0),
}
const GEM_SHORT := {
	"credits": "CR",
	"crystals": "CS",
	"void": "VO",
}

@onready var special_bar: ProgressBar = $SpecialBar
@onready var nova_button: Button = $NovaButton
@onready var freeze_bar: ProgressBar = $FreezeBar
@onready var freeze_button: Button = $FreezeButton
@onready var boss_bar: ProgressBar = $BossBar
@onready var boss_label: Label = $BossLabel

var debug_threat := false

# Popup system
var dimmer: ColorRect
var current_popup: Control
var popup_icon_draw: Control
var popup_earnings_draw: Control
var popup_tween: Tween
var cached_earnings: Dictionary = {}

func _ready() -> void:
	threat_label.visible = debug_threat
	threat_bar.visible = debug_threat
	credits_label.visible = false
	boss_bar.visible = false
	boss_label.visible = false
	currency_draw = Control.new()
	currency_draw.offset_left = 20.0
	currency_draw.offset_top = 20.0
	currency_draw.offset_right = 1060.0
	currency_draw.offset_bottom = 60.0
	currency_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	currency_draw.draw.connect(_draw_currencies)
	add_child(currency_draw)
	nova_button.set_meta("no_click_sfx", true)
	freeze_button.set_meta("no_click_sfx", true)
	nova_button.pressed.connect(_on_nova_pressed)
	freeze_button.pressed.connect(_on_freeze_pressed)
	_apply_neon_style()
	_reposition_for_screen()
	# Dimmer (escurece a tela atras do popup)
	dimmer = ColorRect.new()
	dimmer.color = Color(0.0, 0.0, 0.0, 0.6)
	var scr := get_viewport().get_visible_rect().size
	dimmer.offset_right = scr.x
	dimmer.offset_bottom = scr.y
	dimmer.visible = false
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

func _apply_neon_style() -> void:
	threat_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	credits_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	boss_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.3))
	var threat_style := StyleBoxFlat.new()
	threat_style.bg_color = Color(1.0, 0.0, 0.6, 0.8)
	threat_bar.add_theme_stylebox_override("fill", threat_style)
	var threat_bg := StyleBoxFlat.new()
	threat_bg.bg_color = Color(0.1, 0.0, 0.05)
	threat_bg.border_color = Color(1.0, 0.0, 0.6, 0.3)
	threat_bg.set_border_width_all(1)
	threat_bar.add_theme_stylebox_override("background", threat_bg)
	var special_style := StyleBoxFlat.new()
	special_style.bg_color = Color(0.0, 1.0, 1.0, 0.8)
	special_bar.add_theme_stylebox_override("fill", special_style)
	var special_bg := StyleBoxFlat.new()
	special_bg.bg_color = Color(0.0, 0.05, 0.1)
	special_bg.border_color = Color(0.0, 1.0, 1.0, 0.3)
	special_bg.set_border_width_all(1)
	special_bar.add_theme_stylebox_override("background", special_bg)
	var freeze_style := StyleBoxFlat.new()
	freeze_style.bg_color = Color(0.3, 0.6, 1.0, 0.8)
	freeze_bar.add_theme_stylebox_override("fill", freeze_style)
	var freeze_bg := StyleBoxFlat.new()
	freeze_bg.bg_color = Color(0.02, 0.03, 0.1)
	freeze_bg.border_color = Color(0.3, 0.6, 1.0, 0.3)
	freeze_bg.set_border_width_all(1)
	freeze_bar.add_theme_stylebox_override("background", freeze_bg)
	var boss_style := StyleBoxFlat.new()
	boss_style.bg_color = Color(1.0, 0.0, 0.2, 0.8)
	boss_bar.add_theme_stylebox_override("fill", boss_style)
	var boss_bg := StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.1, 0.0, 0.02)
	boss_bg.border_color = Color(1.0, 0.0, 0.2, 0.3)
	boss_bg.set_border_width_all(1)
	boss_bar.add_theme_stylebox_override("background", boss_bg)
	_reposition_for_screen()

func _reposition_for_screen() -> void:
	var screen := get_viewport().get_visible_rect().size
	var screen_h := screen.y
	var screen_w := screen.x
	special_bar.offset_top = screen_h - 100.0
	special_bar.offset_bottom = screen_h - 70.0
	nova_button.offset_top = screen_h - 65.0
	nova_button.offset_bottom = screen_h - 10.0
	freeze_bar.offset_left = screen_w - 220.0
	freeze_bar.offset_right = screen_w - 20.0
	freeze_bar.offset_top = screen_h - 100.0
	freeze_bar.offset_bottom = screen_h - 70.0
	freeze_button.offset_left = screen_w - 220.0
	freeze_button.offset_right = screen_w - 20.0
	freeze_button.offset_top = screen_h - 65.0
	freeze_button.offset_bottom = screen_h - 10.0

# ============================================================
# CURRENCIES HUD
# ============================================================

func update_threat(level: float) -> void:
	if debug_threat:
		threat_label.text = "AMEACA: %d" % int(level)
		threat_bar.value = level

func update_currencies(earnings: Dictionary) -> void:
	hud_currencies.clear()
	for cur_type in ["void", "crystals", "credits"]:
		var amount = earnings.get(cur_type, 0)
		if amount > 0:
			hud_currencies.append({"type": cur_type, "amount": amount})
	currency_draw.queue_redraw()

func _draw_currencies() -> void:
	var font := ThemeDB.fallback_font
	var draw_w := currency_draw.size.x
	var entries := hud_currencies.duplicate()
	entries.reverse()
	var x := draw_w
	for entry in entries:
		var text := "%d" % entry["amount"]
		var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		x -= text_w
		currency_draw.draw_string(font, Vector2(x, 30), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		x -= 24
		_draw_gem(currency_draw, Vector2(x + 8, 20), GEM_COLORS[entry["type"]])
		x -= 20

func _draw_gem(c: Control, center: Vector2, col: Color) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -10),
		center + Vector2(8, 0),
		center + Vector2(0, 10),
		center + Vector2(-8, 0),
	])
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), 1.5, true)
	c.draw_line(pts[3], pts[0], Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), 1.5, true)
	c.draw_line(center + Vector2(-8, 0), center + Vector2(0, -3), Color(1, 1, 1, 0.3), 1.0, true)
	c.draw_line(center + Vector2(0, -3), center + Vector2(0, -10), Color(1, 1, 1, 0.3), 1.0, true)

func _draw_gem_large(c: Control, center: Vector2, col: Color, s := 1.5) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -10 * s),
		center + Vector2(8 * s, 0),
		center + Vector2(0, 10 * s),
		center + Vector2(-8 * s, 0),
	])
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), 2.0, true)
	c.draw_line(pts[3], pts[0], Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), 2.0, true)
	c.draw_line(center + Vector2(-8 * s, 0), center + Vector2(0, -3 * s), Color(1, 1, 1, 0.35), 1.5, true)
	c.draw_line(center + Vector2(0, -3 * s), center + Vector2(0, -10 * s), Color(1, 1, 1, 0.35), 1.5, true)

# ============================================================
# SPECIAL / FREEZE / BOSS
# ============================================================

func update_special(charge: float, is_ready: bool) -> void:
	special_bar.value = charge
	nova_button.disabled = not is_ready
	if is_ready:
		nova_button.modulate = Color(1.0, 1.0, 0.0)
	else:
		nova_button.modulate = Color(0.2, 0.2, 0.3)

func update_freeze(charge: float, is_ready: bool) -> void:
	freeze_bar.value = charge
	freeze_button.disabled = not is_ready
	if is_ready:
		freeze_button.modulate = Color(0.3, 0.6, 1.0)
	else:
		freeze_button.modulate = Color(0.2, 0.2, 0.3)

func set_freeze_visible(val: bool) -> void:
	freeze_bar.visible = val
	freeze_button.visible = val

func show_boss_hp(ratio: float) -> void:
	boss_bar.visible = true
	boss_label.visible = true
	boss_bar.value = ratio * 100.0

func hide_boss_hp() -> void:
	boss_bar.visible = false
	boss_label.visible = false

func _on_nova_pressed() -> void:
	var game = get_parent()
	if game.has_method("activate_nova_bomb"):
		game.activate_nova_bomb()

func _on_freeze_pressed() -> void:
	var game = get_parent()
	if game.has_method("activate_freeze"):
		game.activate_freeze()

# ============================================================
# POPUP SYSTEM
# ============================================================

func _dismiss_popup() -> void:
	if current_popup:
		current_popup.queue_free()
		current_popup = null
	popup_icon_draw = null
	popup_earnings_draw = null
	dimmer.visible = false

func _show_popup(panel: Control) -> void:
	_dismiss_popup()
	dimmer.visible = true
	current_popup = panel
	add_child(panel)
	# Animacao de entrada
	panel.scale = Vector2(0.7, 0.7)
	panel.modulate = Color(1, 1, 1, 0)
	if popup_tween:
		popup_tween.kill()
	popup_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	popup_tween.tween_property(panel, "scale", Vector2.ONE, 0.35)
	popup_tween.set_trans(Tween.TRANS_QUAD)
	popup_tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.25)

func _create_popup_panel(border_col: Color, width := 600.0, height := 500.0) -> Control:
	var scr := get_viewport().get_visible_rect().size
	var panel := Control.new()
	panel.offset_left = (scr.x - width) / 2.0
	panel.offset_top = (scr.y - height) / 2.0
	panel.offset_right = (scr.x + width) / 2.0
	panel.offset_bottom = (scr.y + height) / 2.0
	panel.pivot_offset = Vector2(width / 2.0, height / 2.0)
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.06, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)
	# Neon border via draw
	var border := Control.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.draw.connect(func():
		var s := border.size
		# Glow externo
		border.draw_rect(Rect2(-3, -3, s.x + 6, s.y + 6), Color(border_col.r, border_col.g, border_col.b, 0.15), false, 6.0)
		# Borda principal
		border.draw_rect(Rect2(0, 0, s.x, s.y), border_col, false, 2.5)
		# Borda interna sutil
		border.draw_rect(Rect2(4, 4, s.x - 8, s.y - 8), Color(border_col.r, border_col.g, border_col.b, 0.2), false, 1.0)
	)
	panel.add_child(border)
	return panel

func _style_popup_button(btn: Button, col: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(col.r * 0.1, col.g * 0.1, col.b * 0.1, 0.85)
	normal.border_color = col
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(col.r * 0.2, col.g * 0.2, col.b * 0.2, 0.9)
	hover.border_color = Color(minf(col.r * 1.3, 1.0), minf(col.g * 1.3, 1.0), minf(col.b * 1.3, 1.0))
	hover.set_border_width_all(3)
	hover.set_corner_radius_all(6)
	hover.set_content_margin_all(8)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(col.r * 0.3, col.g * 0.3, col.b * 0.3, 0.95)
	pressed.border_color = Color(1.0, 1.0, 1.0, 0.8)
	pressed.set_border_width_all(3)
	pressed.set_corner_radius_all(6)
	pressed.set_content_margin_all(8)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", Color(minf(col.r * 1.2, 1.0), minf(col.g * 1.2, 1.0), minf(col.b * 1.2, 1.0)))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))

# ============================================================
# PROCEDURAL ICONS
# ============================================================

func _draw_skull(c: Control, center: Vector2, col: Color) -> void:
	# Cranio
	c.draw_circle(center + Vector2(0, -8), 22.0, Color(col.r, col.g, col.b, 0.15))
	c.draw_arc(center + Vector2(0, -8), 20.0, -PI, 0, 24, col, 2.5, true)
	# Mandibula
	c.draw_line(center + Vector2(-20, -8), center + Vector2(-18, 12), col, 2.5, true)
	c.draw_line(center + Vector2(20, -8), center + Vector2(18, 12), col, 2.5, true)
	c.draw_line(center + Vector2(-18, 12), center + Vector2(18, 12), col, 2.5, true)
	# Olhos
	c.draw_circle(center + Vector2(-8, -10), 5.0, col)
	c.draw_circle(center + Vector2(8, -10), 5.0, col)
	c.draw_circle(center + Vector2(-8, -10), 3.0, Color(0, 0, 0))
	c.draw_circle(center + Vector2(8, -10), 3.0, Color(0, 0, 0))
	# Nariz
	c.draw_line(center + Vector2(-2, 0), center + Vector2(0, 4), col, 2.0, true)
	c.draw_line(center + Vector2(2, 0), center + Vector2(0, 4), col, 2.0, true)
	# Dentes
	for i in 5:
		var tx := center.x - 12 + i * 6
		c.draw_line(Vector2(tx, center.y + 8), Vector2(tx, center.y + 15), col, 1.5, true)

func _draw_trophy(c: Control, center: Vector2, col: Color) -> void:
	# Glow
	c.draw_circle(center, 28.0, Color(col.r, col.g, col.b, 0.1))
	# Copa
	var cup_pts := PackedVector2Array([
		center + Vector2(-18, -20),
		center + Vector2(18, -20),
		center + Vector2(14, 6),
		center + Vector2(-14, 6),
	])
	c.draw_colored_polygon(cup_pts, Color(col.r, col.g, col.b, 0.2))
	c.draw_polyline(cup_pts, col, 2.5, true)
	c.draw_line(cup_pts[3], cup_pts[0], col, 2.5, true)
	# Alcas
	c.draw_arc(center + Vector2(-18, -8), 8.0, PI * 0.5, PI * 1.5, 12, col, 2.0, true)
	c.draw_arc(center + Vector2(18, -8), 8.0, -PI * 0.5, PI * 0.5, 12, col, 2.0, true)
	# Haste
	c.draw_line(center + Vector2(0, 6), center + Vector2(0, 16), col, 2.5, true)
	# Base
	c.draw_line(center + Vector2(-10, 16), center + Vector2(10, 16), col, 2.5, true)
	c.draw_line(center + Vector2(-12, 19), center + Vector2(12, 19), col, 2.5, true)
	# Estrela no centro
	_draw_star(c, center + Vector2(0, -8), 6.0, col)

func _draw_star(c: Control, center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + i * TAU / 10.0
		var radius := r if i % 2 == 0 else r * 0.4
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	c.draw_colored_polygon(pts, col)

func _draw_heart(c: Control, center: Vector2, col: Color) -> void:
	# Glow
	c.draw_circle(center, 26.0, Color(col.r, col.g, col.b, 0.1))
	# Duas metades do coracao
	c.draw_circle(center + Vector2(-10, -6), 12.0, Color(col.r, col.g, col.b, 0.25))
	c.draw_circle(center + Vector2(10, -6), 12.0, Color(col.r, col.g, col.b, 0.25))
	c.draw_arc(center + Vector2(-10, -6), 12.0, PI, TAU, 16, col, 2.5, true)
	c.draw_arc(center + Vector2(10, -6), 12.0, PI, TAU, 16, col, 2.5, true)
	# Ponta inferior
	var heart_pts := PackedVector2Array([
		center + Vector2(-22, -6),
		center + Vector2(0, 22),
		center + Vector2(22, -6),
	])
	c.draw_colored_polygon(heart_pts, Color(col.r, col.g, col.b, 0.25))
	c.draw_line(center + Vector2(-22, -6), center + Vector2(0, 22), col, 2.5, true)
	c.draw_line(center + Vector2(22, -6), center + Vector2(0, 22), col, 2.5, true)
	# Brilho
	c.draw_line(center + Vector2(-14, -10), center + Vector2(-8, -4), Color(1, 1, 1, 0.4), 2.0, true)

# ============================================================
# EARNINGS DISPLAY
# ============================================================

func _draw_earnings(c: Control) -> void:
	var font := ThemeDB.fallback_font
	var w := c.size.x
	# Calcular largura total
	var entries: Array = []
	for cur_type in ["credits", "crystals", "void"]:
		var amount = cached_earnings.get(cur_type, 0)
		if amount > 0:
			entries.append({"type": cur_type, "amount": amount})
	if entries.is_empty():
		c.draw_string(font, Vector2(w / 2.0 - 80, 20), "Nenhum ganho", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.5, 0.5, 0.5))
		return
	var total_w := 0.0
	for entry in entries:
		total_w += font.get_string_size("%d" % entry["amount"], HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 38
	total_w -= 10  # remove last spacing
	var x := (w - total_w) / 2.0
	for entry in entries:
		_draw_gem_large(c, Vector2(x + 8, 14), GEM_COLORS[entry["type"]])
		x += 22
		var text := "%d" % entry["amount"]
		c.draw_string(font, Vector2(x, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		x += font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 16

# ============================================================
# GAME OVER POPUP
# ============================================================

func show_game_over() -> void:
	var red := Color(1.0, 0.1, 0.2)
	var panel := _create_popup_panel(red, 580.0, 420.0)
	# Icon
	popup_icon_draw = Control.new()
	popup_icon_draw.offset_left = 240.0
	popup_icon_draw.offset_top = 30.0
	popup_icon_draw.offset_right = 340.0
	popup_icon_draw.offset_bottom = 100.0
	popup_icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _icon := popup_icon_draw
	popup_icon_draw.draw.connect(func(): _draw_skull(_icon, Vector2(50, 35), red))
	panel.add_child(popup_icon_draw)
	# Title
	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", red)
	title.offset_left = 40.0
	title.offset_top = 110.0
	title.offset_right = 540.0
	title.offset_bottom = 165.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	# Separator
	var sep := Control.new()
	sep.offset_left = 60.0
	sep.offset_top = 170.0
	sep.offset_right = 520.0
	sep.offset_bottom = 172.0
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func(): sep.draw_line(Vector2.ZERO, Vector2(sep.size.x, 0), Color(red.r, red.g, red.b, 0.3), 1.5))
	panel.add_child(sep)
	# Ganhos label
	var ganhos_lbl := Label.new()
	ganhos_lbl.text = "GANHOS DA RUN"
	ganhos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ganhos_lbl.add_theme_font_size_override("font_size", 18)
	ganhos_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	ganhos_lbl.offset_left = 40.0
	ganhos_lbl.offset_top = 182.0
	ganhos_lbl.offset_right = 540.0
	ganhos_lbl.offset_bottom = 205.0
	ganhos_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ganhos_lbl)
	# Earnings draw
	popup_earnings_draw = Control.new()
	popup_earnings_draw.offset_left = 40.0
	popup_earnings_draw.offset_top = 210.0
	popup_earnings_draw.offset_right = 540.0
	popup_earnings_draw.offset_bottom = 260.0
	popup_earnings_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _earn := popup_earnings_draw
	popup_earnings_draw.draw.connect(func(): _draw_earnings(_earn))
	panel.add_child(popup_earnings_draw)
	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = 60.0
	btn_container.offset_top = 310.0
	btn_container.offset_right = 520.0
	btn_container.offset_bottom = 390.0
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 30)
	panel.add_child(btn_container)
	var game = get_parent()
	if game.ad_system and game.ad_system.can_show_shop_ad():
		var double_btn := Button.new()
		double_btn.text = "DOBRAR GANHOS (AD)"
		double_btn.custom_minimum_size = Vector2(280, 65)
		double_btn.add_theme_font_size_override("font_size", 22)
		_style_popup_button(double_btn, Color(1.0, 0.8, 0.0))
		double_btn.pressed.connect(_on_double_pressed)
		btn_container.add_child(double_btn)
		var decline_btn := Button.new()
		decline_btn.text = "NAO"
		decline_btn.custom_minimum_size = Vector2(140, 65)
		decline_btn.add_theme_font_size_override("font_size", 22)
		_style_popup_button(decline_btn, Color(0.6, 0.2, 0.2))
		decline_btn.pressed.connect(_on_double_decline_pressed)
		btn_container.add_child(decline_btn)
	else:
		var cont_btn := Button.new()
		cont_btn.text = "CONTINUAR"
		cont_btn.custom_minimum_size = Vector2(240, 65)
		cont_btn.add_theme_font_size_override("font_size", 24)
		_style_popup_button(cont_btn, red)
		cont_btn.pressed.connect(func(): _dismiss_popup(); get_parent().game_over.emit())
		btn_container.add_child(cont_btn)
	_show_popup(panel)

# ============================================================
# VICTORY POPUP
# ============================================================

func show_victory() -> void:
	var green := Color(0.2, 1.0, 0.3)
	var panel := _create_popup_panel(green, 580.0, 420.0)
	# Icon
	popup_icon_draw = Control.new()
	popup_icon_draw.offset_left = 240.0
	popup_icon_draw.offset_top = 30.0
	popup_icon_draw.offset_right = 340.0
	popup_icon_draw.offset_bottom = 100.0
	popup_icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _icon := popup_icon_draw
	popup_icon_draw.draw.connect(func(): _draw_trophy(_icon, Vector2(50, 35), green))
	panel.add_child(popup_icon_draw)
	# Title
	var title := Label.new()
	title.text = "VITORIA!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", green)
	title.offset_left = 40.0
	title.offset_top = 110.0
	title.offset_right = 540.0
	title.offset_bottom = 165.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	# Separator
	var sep := Control.new()
	sep.offset_left = 60.0
	sep.offset_top = 170.0
	sep.offset_right = 520.0
	sep.offset_bottom = 172.0
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func(): sep.draw_line(Vector2.ZERO, Vector2(sep.size.x, 0), Color(green.r, green.g, green.b, 0.3), 1.5))
	panel.add_child(sep)
	# Ganhos label
	var ganhos_lbl := Label.new()
	ganhos_lbl.text = "GANHOS DA RUN"
	ganhos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ganhos_lbl.add_theme_font_size_override("font_size", 18)
	ganhos_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	ganhos_lbl.offset_left = 40.0
	ganhos_lbl.offset_top = 182.0
	ganhos_lbl.offset_right = 540.0
	ganhos_lbl.offset_bottom = 205.0
	ganhos_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ganhos_lbl)
	# Earnings draw
	popup_earnings_draw = Control.new()
	popup_earnings_draw.offset_left = 40.0
	popup_earnings_draw.offset_top = 210.0
	popup_earnings_draw.offset_right = 540.0
	popup_earnings_draw.offset_bottom = 260.0
	popup_earnings_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _earn := popup_earnings_draw
	popup_earnings_draw.draw.connect(func(): _draw_earnings(_earn))
	panel.add_child(popup_earnings_draw)
	# Button
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = 60.0
	btn_container.offset_top = 310.0
	btn_container.offset_right = 520.0
	btn_container.offset_bottom = 390.0
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(btn_container)
	var cont_btn := Button.new()
	cont_btn.text = "CONTINUAR"
	cont_btn.custom_minimum_size = Vector2(280, 65)
	cont_btn.add_theme_font_size_override("font_size", 26)
	_style_popup_button(cont_btn, green)
	cont_btn.pressed.connect(func(): _dismiss_popup(); get_parent().game_over.emit())
	btn_container.add_child(cont_btn)
	_show_popup(panel)

# ============================================================
# REVIVE POPUP (standalone, se chamado separadamente)
# ============================================================

func show_revive_offer() -> void:
	var cyan := Color(0.0, 0.9, 1.0)
	var panel := _create_popup_panel(cyan, 520.0, 340.0)
	# Icon
	popup_icon_draw = Control.new()
	popup_icon_draw.offset_left = 210.0
	popup_icon_draw.offset_top = 25.0
	popup_icon_draw.offset_right = 310.0
	popup_icon_draw.offset_bottom = 95.0
	popup_icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _icon := popup_icon_draw
	popup_icon_draw.draw.connect(func(): _draw_heart(_icon, Vector2(50, 35), cyan))
	panel.add_child(popup_icon_draw)
	# Title
	var title := Label.new()
	title.text = "REVIVER?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", cyan)
	title.offset_left = 30.0
	title.offset_top = 105.0
	title.offset_right = 490.0
	title.offset_bottom = 150.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	# Subtitle
	var sub := Label.new()
	sub.text = "Assista um anuncio para continuar"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	sub.offset_left = 30.0
	sub.offset_top = 155.0
	sub.offset_right = 490.0
	sub.offset_bottom = 180.0
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub)
	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = 50.0
	btn_container.offset_top = 230.0
	btn_container.offset_right = 470.0
	btn_container.offset_bottom = 310.0
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 30)
	panel.add_child(btn_container)
	var revive_btn := Button.new()
	revive_btn.text = "REVIVER"
	revive_btn.custom_minimum_size = Vector2(200, 65)
	revive_btn.add_theme_font_size_override("font_size", 24)
	_style_popup_button(revive_btn, Color(0.0, 1.0, 0.5))
	revive_btn.pressed.connect(_on_revive_pressed)
	btn_container.add_child(revive_btn)
	var decline_btn := Button.new()
	decline_btn.text = "NAO"
	decline_btn.custom_minimum_size = Vector2(140, 65)
	decline_btn.add_theme_font_size_override("font_size", 24)
	_style_popup_button(decline_btn, Color(0.6, 0.2, 0.2))
	decline_btn.pressed.connect(_on_decline_pressed)
	btn_container.add_child(decline_btn)
	_show_popup(panel)

func hide_revive_offer() -> void:
	_dismiss_popup()

# ============================================================
# DOUBLE OFFER (standalone)
# ============================================================

func show_double_offer(earnings: Dictionary) -> void:
	cached_earnings = earnings
	var gold := Color(1.0, 0.8, 0.0)
	var panel := _create_popup_panel(gold, 560.0, 380.0)
	# Title
	var title := Label.new()
	title.text = "DOBRAR GANHOS?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", gold)
	title.offset_left = 30.0
	title.offset_top = 30.0
	title.offset_right = 530.0
	title.offset_bottom = 75.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	# Separator
	var sep := Control.new()
	sep.offset_left = 60.0
	sep.offset_top = 85.0
	sep.offset_right = 500.0
	sep.offset_bottom = 87.0
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func(): sep.draw_line(Vector2.ZERO, Vector2(sep.size.x, 0), Color(gold.r, gold.g, gold.b, 0.3), 1.5))
	panel.add_child(sep)
	# Earnings draw
	popup_earnings_draw = Control.new()
	popup_earnings_draw.offset_left = 30.0
	popup_earnings_draw.offset_top = 100.0
	popup_earnings_draw.offset_right = 530.0
	popup_earnings_draw.offset_bottom = 150.0
	popup_earnings_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _earn := popup_earnings_draw
	popup_earnings_draw.draw.connect(func(): _draw_earnings(_earn))
	panel.add_child(popup_earnings_draw)
	# Sub
	var sub := Label.new()
	sub.text = "Assista um anuncio para dobrar"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	sub.offset_left = 30.0
	sub.offset_top = 165.0
	sub.offset_right = 530.0
	sub.offset_bottom = 190.0
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub)
	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = 50.0
	btn_container.offset_top = 270.0
	btn_container.offset_right = 510.0
	btn_container.offset_bottom = 350.0
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 30)
	panel.add_child(btn_container)
	var double_btn := Button.new()
	double_btn.text = "DOBRAR (AD)"
	double_btn.custom_minimum_size = Vector2(240, 65)
	double_btn.add_theme_font_size_override("font_size", 22)
	_style_popup_button(double_btn, gold)
	double_btn.pressed.connect(_on_double_pressed)
	btn_container.add_child(double_btn)
	var decline_btn := Button.new()
	decline_btn.text = "NAO"
	decline_btn.custom_minimum_size = Vector2(140, 65)
	decline_btn.add_theme_font_size_override("font_size", 22)
	_style_popup_button(decline_btn, Color(0.6, 0.2, 0.2))
	decline_btn.pressed.connect(_on_double_decline_pressed)
	btn_container.add_child(decline_btn)
	_show_popup(panel)

func hide_double_offer() -> void:
	_dismiss_popup()

# ============================================================
# POPUP CALLBACKS
# ============================================================

func set_earnings(earnings: Dictionary) -> void:
	cached_earnings = earnings

func _on_revive_pressed() -> void:
	_dismiss_popup()
	var game = get_parent()
	if game.has_method("revive"):
		game.revive()

func _on_decline_pressed() -> void:
	_dismiss_popup()
	var game = get_parent()
	cached_earnings = game.run_earnings if "run_earnings" in game else {}
	if game.ad_system and game.ad_system.can_show_shop_ad():
		show_double_offer(cached_earnings)
	else:
		show_game_over_final()

func show_game_over_final() -> void:
	# Game over sem opcoes - so continuar
	var red := Color(1.0, 0.1, 0.2)
	var panel := _create_popup_panel(red, 580.0, 380.0)
	popup_icon_draw = Control.new()
	popup_icon_draw.offset_left = 240.0
	popup_icon_draw.offset_top = 25.0
	popup_icon_draw.offset_right = 340.0
	popup_icon_draw.offset_bottom = 95.0
	popup_icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _icon := popup_icon_draw
	popup_icon_draw.draw.connect(func(): _draw_skull(_icon, Vector2(50, 35), red))
	panel.add_child(popup_icon_draw)
	var title := Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", red)
	title.offset_left = 40.0
	title.offset_top = 100.0
	title.offset_right = 540.0
	title.offset_bottom = 155.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	var sep := Control.new()
	sep.offset_left = 60.0
	sep.offset_top = 160.0
	sep.offset_right = 520.0
	sep.offset_bottom = 162.0
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func(): sep.draw_line(Vector2.ZERO, Vector2(sep.size.x, 0), Color(red.r, red.g, red.b, 0.3), 1.5))
	panel.add_child(sep)
	popup_earnings_draw = Control.new()
	popup_earnings_draw.offset_left = 40.0
	popup_earnings_draw.offset_top = 175.0
	popup_earnings_draw.offset_right = 540.0
	popup_earnings_draw.offset_bottom = 225.0
	popup_earnings_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _earn := popup_earnings_draw
	popup_earnings_draw.draw.connect(func(): _draw_earnings(_earn))
	panel.add_child(popup_earnings_draw)
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = 60.0
	btn_container.offset_top = 280.0
	btn_container.offset_right = 520.0
	btn_container.offset_bottom = 355.0
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(btn_container)
	var cont_btn := Button.new()
	cont_btn.text = "CONTINUAR"
	cont_btn.custom_minimum_size = Vector2(260, 65)
	cont_btn.add_theme_font_size_override("font_size", 24)
	_style_popup_button(cont_btn, red)
	cont_btn.pressed.connect(func(): _dismiss_popup(); get_parent().game_over.emit())
	btn_container.add_child(cont_btn)
	_show_popup(panel)

func _on_double_pressed() -> void:
	_dismiss_popup()
	var game = get_parent()
	if game.has_method("double_run_earnings"):
		game.double_run_earnings()

func _on_double_decline_pressed() -> void:
	_dismiss_popup()
	var game = get_parent()
	if game.has_method("decline_double"):
		game.decline_double()
