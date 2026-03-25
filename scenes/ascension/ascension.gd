extends Control

signal ascension_confirmed
signal ascension_cancelled

var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var ascension_system: AscensionSystem

var distant_battle := DistantBattle.new()
var battle_overlay: Control
var panel: Control
var icon_draw: Control
var eter_draw: Control
var eter_gain := 0
var eter_old := 0
var total_earned := 0

const ETER_COL := Color(1.0, 0.5, 0.0)
const GEM_COL := Color(1.0, 0.5, 0.0)

const BASE_WIDTH := 1080.0
const BASE_HEIGHT := 1920.0
var ui_scale := 1.0

func _sf(val: int) -> int:
	return int(val * ui_scale)

func _ready() -> void:
	var real_size := DisplayServer.screen_get_size()
	ui_scale = clampf(minf(real_size.x / BASE_WIDTH, real_size.y / BASE_HEIGHT), 1.0, 1.5)
	# Batalha distante
	battle_overlay = Control.new()
	battle_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_overlay.draw.connect(_draw_battle)
	add_child(battle_overlay)

	_build_panel()

func setup(p_currency: CurrencySystem, p_upgrades: UpgradeSystem, p_ascension: AscensionSystem) -> void:
	currency = p_currency
	upgrade_system = p_upgrades
	ascension_system = p_ascension

func _process(delta: float) -> void:
	var scr := get_viewport().get_visible_rect().size
	distant_battle.update(delta, scr, scr.y * 0.5)
	battle_overlay.queue_redraw()

func _draw_battle() -> void:
	distant_battle.draw(battle_overlay)

func _build_panel() -> void:
	var tr_node = get_node("/root/Tr")
	var scr := get_viewport().get_visible_rect().size
	var pw := 620.0
	var ph := 780.0

	panel = Control.new()
	panel.offset_left = (scr.x - pw) / 2.0
	panel.offset_top = (scr.y - ph) / 2.0
	panel.offset_right = (scr.x + pw) / 2.0
	panel.offset_bottom = (scr.y + ph) / 2.0
	panel.pivot_offset = Vector2(pw / 2.0, ph / 2.0)
	add_child(panel)

	# Panel background
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.05, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# Neon border
	var border := Control.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.draw.connect(func():
		var s := border.size
		border.draw_rect(Rect2(-3, -3, s.x + 6, s.y + 6), Color(ETER_COL.r, ETER_COL.g, ETER_COL.b, 0.15), false, 6.0)
		border.draw_rect(Rect2(0, 0, s.x, s.y), ETER_COL, false, 2.5)
		border.draw_rect(Rect2(4, 4, s.x - 8, s.y - 8), Color(ETER_COL.r, ETER_COL.g, ETER_COL.b, 0.2), false, 1.0)
	)
	panel.add_child(border)

	# Ascension icon
	icon_draw = Control.new()
	icon_draw.offset_left = pw / 2.0 - 50.0
	icon_draw.offset_top = 25.0
	icon_draw.offset_right = pw / 2.0 + 50.0
	icon_draw.offset_bottom = 115.0
	icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _ic := icon_draw
	icon_draw.draw.connect(func(): _draw_ascension_icon(_ic, Vector2(50, 45)))
	panel.add_child(icon_draw)

	# Title
	var title := Label.new()
	title.text = tr_node.t("ASC_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _sf(40))
	title.add_theme_color_override("font_color", ETER_COL)
	title.offset_left = 30.0
	title.offset_top = 120.0
	title.offset_right = pw - 30.0
	title.offset_bottom = 170.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)

	# Separator
	var sep1 := Control.new()
	sep1.offset_left = 40.0
	sep1.offset_top = 178.0
	sep1.offset_right = pw - 40.0
	sep1.offset_bottom = 180.0
	sep1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep1.draw.connect(func(): sep1.draw_line(Vector2.ZERO, Vector2(sep1.size.x, 0), Color(ETER_COL.r, ETER_COL.g, ETER_COL.b, 0.3), 1.5))
	panel.add_child(sep1)

	# Eter info drawn procedurally (with gems)
	eter_draw = Control.new()
	eter_draw.offset_left = 30.0
	eter_draw.offset_top = 195.0
	eter_draw.offset_right = pw - 30.0
	eter_draw.offset_bottom = 400.0
	eter_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _ed := eter_draw
	eter_draw.draw.connect(func(): _draw_eter_info(_ed))
	panel.add_child(eter_draw)

	# Warning box
	var warn_bg := ColorRect.new()
	warn_bg.color = Color(0.15, 0.02, 0.02, 0.7)
	warn_bg.offset_left = 30.0
	warn_bg.offset_top = 410.0
	warn_bg.offset_right = pw - 30.0
	warn_bg.offset_bottom = 590.0
	warn_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(warn_bg)

	var warn_border := Control.new()
	warn_border.offset_left = 30.0
	warn_border.offset_top = 410.0
	warn_border.offset_right = pw - 30.0
	warn_border.offset_bottom = 590.0
	warn_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warn_border.draw.connect(func():
		var s := warn_border.size
		warn_border.draw_rect(Rect2(0, 0, s.x, s.y), Color(1.0, 0.2, 0.2, 0.5), false, 1.5)
	)
	panel.add_child(warn_border)

	# Warning icon centered
	var warn_icon := Control.new()
	warn_icon.offset_left = pw / 2.0 - 20.0
	warn_icon.offset_top = 420.0
	warn_icon.offset_right = pw / 2.0 + 20.0
	warn_icon.offset_bottom = 460.0
	warn_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warn_icon.draw.connect(func(): _draw_warning_icon(warn_icon, Vector2(20, 20)))
	panel.add_child(warn_icon)

	var warn_title := Label.new()
	warn_title.text = tr_node.t("WARNING_TITLE")
	warn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_title.add_theme_font_size_override("font_size", _sf(28))
	warn_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	warn_title.offset_left = 30.0
	warn_title.offset_top = 462.0
	warn_title.offset_right = pw - 30.0
	warn_title.offset_bottom = 500.0
	warn_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(warn_title)

	var warn_text := Label.new()
	warn_text.text = tr_node.t("WARNING_TEXT")
	warn_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_text.add_theme_font_size_override("font_size", _sf(22))
	warn_text.add_theme_color_override("font_color", Color(0.8, 0.45, 0.45))
	warn_text.offset_left = 35.0
	warn_text.offset_top = 505.0
	warn_text.offset_right = pw - 35.0
	warn_text.offset_bottom = 575.0
	warn_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(warn_text)

	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = 40.0
	btn_container.offset_top = 610.0
	btn_container.offset_right = pw - 40.0
	btn_container.offset_bottom = 700.0
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 30)
	panel.add_child(btn_container)

	var cancel_btn := Button.new()
	cancel_btn.text = tr_node.t("BACK")
	cancel_btn.custom_minimum_size = Vector2(220, 70)
	cancel_btn.add_theme_font_size_override("font_size", _sf(26))
	_style_neon_button(cancel_btn, Color(0.5, 0.5, 0.5))
	cancel_btn.pressed.connect(_on_cancel)
	btn_container.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = tr_node.t("ASC_CONFIRM")
	confirm_btn.custom_minimum_size = Vector2(240, 70)
	confirm_btn.add_theme_font_size_override("font_size", _sf(26))
	_style_neon_button(confirm_btn, ETER_COL)
	confirm_btn.pressed.connect(_on_confirm)
	btn_container.add_child(confirm_btn)

	# Animate in
	panel.scale = Vector2(0.7, 0.7)
	panel.modulate = Color(1, 1, 1, 0)
	var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.4)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)

func _draw_ascension_icon(c: Control, center: Vector2) -> void:
	# Seta pra cima com glow
	var col := ETER_COL
	# Glow
	c.draw_circle(center, 35.0, Color(col.r, col.g, col.b, 0.08))
	c.draw_circle(center, 25.0, Color(col.r, col.g, col.b, 0.12))
	# Seta principal
	var arrow_pts := PackedVector2Array([
		center + Vector2(0, -30),    # topo
		center + Vector2(-20, -5),   # esquerda
		center + Vector2(-8, -5),    # encaixe esq
		center + Vector2(-8, 25),    # base esq
		center + Vector2(8, 25),     # base dir
		center + Vector2(8, -5),     # encaixe dir
		center + Vector2(20, -5),    # direita
	])
	c.draw_colored_polygon(arrow_pts, Color(col.r, col.g, col.b, 0.25))
	c.draw_polyline(arrow_pts, col, 2.5, true)
	c.draw_line(arrow_pts[6], arrow_pts[0], col, 2.5, true)
	# Linhas de energia saindo
	for i in 3:
		var y := center.y + 30 + i * 8
		var w := 12.0 - i * 3.0
		var alpha := 0.4 - i * 0.1
		c.draw_line(Vector2(center.x - w, y), Vector2(center.x + w, y), Color(col.r, col.g, col.b, alpha), 1.5, true)

func _draw_eter_info(c: Control) -> void:
	if not ascension_system or not upgrade_system:
		return
	var tr_node = get_node("/root/Tr")
	var font := ThemeDB.fallback_font
	var w := c.size.x
	var y := 10.0

	eter_gain = ascension_system.calculate_eter(currency)
	eter_old = ascension_system.get_total_eter()
	total_earned = currency.get_total_earned()

	# Eter ganho
	var gain_text = tr_node.t("ETER_GAINED")
	var gain_w := font.get_string_size(gain_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	c.draw_string(font, Vector2((w - gain_w) / 2.0, y + 15), gain_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.6, 0.6, 0.6))
	y += 30

	# Big number with gem
	var big_text := "+%d" % eter_gain
	var big_size := 44
	var big_w := font.get_string_size(big_text, HORIZONTAL_ALIGNMENT_LEFT, -1, big_size).x
	var gem_w := 24.0
	var total_bw := big_w + gem_w + 8
	var bx := (w - total_bw) / 2.0
	_draw_gem(c, Vector2(bx + 10, y + 22), GEM_COL, 1.8)
	c.draw_string(font, Vector2(bx + gem_w + 8, y + 35), big_text, HORIZONTAL_ALIGNMENT_LEFT, -1, big_size, ETER_COL)
	y += 55

	# Separator line
	c.draw_line(Vector2(40, y), Vector2(w - 40, y), Color(ETER_COL.r, ETER_COL.g, ETER_COL.b, 0.15), 1.0)
	y += 15

	# Eter total
	var total_text = tr_node.t("ETER_TOTAL_FMT") % [eter_old, eter_old + eter_gain]
	var total_tw := font.get_string_size(total_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	c.draw_string(font, Vector2((w - total_tw) / 2.0, y + 18), total_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.7, 0.4))
	y += 32

	# Invested
	var inv_text = tr_node.t("EARNED_FMT") % [total_earned, ascension_system.conversion_factor]
	var inv_tw := font.get_string_size(inv_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	c.draw_string(font, Vector2((w - inv_tw) / 2.0, y + 15), inv_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.5, 0.5, 0.5))
	y += 28

	# Ascension count
	var asc_text = tr_node.t("ASC_COUNT_FMT") % ascension_system.get_ascension_count()
	var asc_tw := font.get_string_size(asc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	c.draw_string(font, Vector2((w - asc_tw) / 2.0, y + 15), asc_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.5, 0.5, 0.5))

func _draw_gem(c: Control, center: Vector2, col: Color, s := 1.0) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -10 * s),
		center + Vector2(8 * s, 0),
		center + Vector2(0, 10 * s),
		center + Vector2(-8 * s, 0),
	])
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), 1.5 * s, true)
	c.draw_line(pts[3], pts[0], Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), 1.5 * s, true)
	c.draw_line(center + Vector2(-8 * s, 0), center + Vector2(0, -3 * s), Color(1, 1, 1, 0.3), 1.0 * s, true)
	c.draw_line(center + Vector2(0, -3 * s), center + Vector2(0, -10 * s), Color(1, 1, 1, 0.3), 1.0 * s, true)

func _draw_warning_icon(c: Control, center: Vector2) -> void:
	var col := Color(1.0, 0.3, 0.3)
	# Triangulo
	var pts := PackedVector2Array([
		center + Vector2(0, -16),
		center + Vector2(16, 14),
		center + Vector2(-16, 14),
	])
	c.draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.2))
	c.draw_polyline(pts, col, 2.0, true)
	c.draw_line(pts[2], pts[0], col, 2.0, true)
	# Exclamacao
	c.draw_line(center + Vector2(0, -8), center + Vector2(0, 4), col, 2.5, true)
	c.draw_circle(center + Vector2(0, 9), 2.0, col)

func _style_neon_button(btn: Button, col: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(col.r * 0.08, col.g * 0.08, col.b * 0.08, 0.85)
	normal.border_color = col
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(col.r * 0.15, col.g * 0.15, col.b * 0.15, 0.9)
	hover.border_color = Color(minf(col.r * 1.3, 1.0), minf(col.g * 1.3, 1.0), minf(col.b * 1.3, 1.0))
	hover.set_border_width_all(3)
	hover.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 0.95)
	pressed.border_color = Color(1.0, 1.0, 1.0, 0.8)
	pressed.set_border_width_all(3)
	pressed.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", Color(minf(col.r * 1.2, 1.0), minf(col.g * 1.2, 1.0), minf(col.b * 1.2, 1.0)))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))

func _on_confirm() -> void:
	ascension_confirmed.emit()

func _on_cancel() -> void:
	ascension_cancelled.emit()
