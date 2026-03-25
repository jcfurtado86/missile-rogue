extends CanvasLayer

@onready var threat_label: Label = $ThreatLabel
@onready var threat_bar: ProgressBar = $ThreatBar
@onready var credits_label: Label = $CreditsLabel
var currency_draw: Control
var hud_currencies: Array = []

var GEM_COLORS: Dictionary:
	get: return {
		"credits": Themes.ui("gem_credits"),
		"crystals": Themes.ui("gem_crystals"),
		"void": Themes.ui("gem_void"),
		"eter": Themes.ui("gem_eter"),
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

signal quit_to_menu

const BASE_WIDTH := 1080.0
const BASE_HEIGHT := 1920.0
var ui_scale := 1.0

var pause_button: Button
var combo_label: Label
var combo_tween: Tween
var combo_value := 0
var combo_time := 0.0
var combo_base_top := 0.0
var _combo_breaking := false

# Popup system
var dimmer: ColorRect
var current_popup: Control
var popup_icon_draw: Control
var popup_earnings_draw: Control
var popup_tween: Tween
var cached_earnings: Dictionary = {}

func _s(val: float) -> float:
	return val * ui_scale

func _sf(val: int) -> int:
	return int(val * ui_scale)

func _ready() -> void:
	var real_size := DisplayServer.screen_get_size()
	ui_scale = clampf(minf(real_size.x / BASE_WIDTH, real_size.y / BASE_HEIGHT), 1.0, 1.5)
	threat_label.visible = false
	threat_bar.visible = false
	credits_label.visible = false
	boss_bar.visible = false
	boss_label.visible = false
	currency_draw = Control.new()
	currency_draw.offset_left = _s(20.0)
	currency_draw.offset_top = _s(20.0)
	currency_draw.offset_right = _s(1060.0)
	currency_draw.offset_bottom = _s(60.0)
	currency_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	currency_draw.draw.connect(_draw_currencies)
	add_child(currency_draw)
	nova_button.set_meta("no_click_sfx", true)
	freeze_button.set_meta("no_click_sfx", true)
	nova_button.pressed.connect(_on_nova_pressed)
	freeze_button.pressed.connect(_on_freeze_pressed)
	_setup_pause_button()
	_apply_neon_style()
	_reposition_for_screen()
	# Combo label — centro-topo
	combo_label = Label.new()
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", _sf(96))
	combo_label.add_theme_color_override("font_color", Themes.ui("hud_combo"))
	combo_label.add_theme_color_override("font_outline_color", Themes.ui("hud_combo", 0.4))
	combo_label.add_theme_constant_override("outline_size", _sf(4))
	var scr_combo := get_viewport().get_visible_rect().size
	combo_label.offset_left = 0
	combo_label.offset_right = scr_combo.x
	combo_label.offset_top = _s(70)
	combo_base_top = _s(70)
	combo_label.visible = false
	combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combo_label)
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
	threat_label.add_theme_font_size_override("font_size", _sf(32))
	credits_label.add_theme_font_size_override("font_size", _sf(28))
	boss_label.add_theme_font_size_override("font_size", _sf(28))
	nova_button.add_theme_font_size_override("font_size", _sf(24))
	freeze_button.add_theme_font_size_override("font_size", _sf(24))
	threat_label.add_theme_color_override("font_color", Themes.ui("hud_threat"))
	credits_label.add_theme_color_override("font_color", Themes.ui("primary"))
	boss_label.add_theme_color_override("font_color", Themes.ui("hud_boss"))
	var threat_style := StyleBoxFlat.new()
	threat_style.bg_color = Themes.ui("hud_threat", 0.8)
	threat_bar.add_theme_stylebox_override("fill", threat_style)
	var threat_bg := StyleBoxFlat.new()
	threat_bg.bg_color = Themes.ui("fill_dark")
	threat_bg.border_color = Themes.ui("hud_threat", 0.3)
	threat_bg.set_border_width_all(1)
	threat_bar.add_theme_stylebox_override("background", threat_bg)
	var special_style := StyleBoxFlat.new()
	special_style.bg_color = Themes.ui("hud_special", 0.8)
	special_bar.add_theme_stylebox_override("fill", special_style)
	var special_bg := StyleBoxFlat.new()
	special_bg.bg_color = Themes.ui("fill_dark")
	special_bg.border_color = Themes.ui("hud_special", 0.3)
	special_bg.set_border_width_all(1)
	special_bar.add_theme_stylebox_override("background", special_bg)
	var freeze_style := StyleBoxFlat.new()
	freeze_style.bg_color = Themes.ui("hud_freeze", 0.8)
	freeze_bar.add_theme_stylebox_override("fill", freeze_style)
	var freeze_bg := StyleBoxFlat.new()
	freeze_bg.bg_color = Themes.ui("fill_dark")
	freeze_bg.border_color = Themes.ui("hud_freeze", 0.3)
	freeze_bg.set_border_width_all(1)
	freeze_bar.add_theme_stylebox_override("background", freeze_bg)
	var boss_style := StyleBoxFlat.new()
	boss_style.bg_color = Themes.ui("hud_boss", 0.8)
	boss_bar.add_theme_stylebox_override("fill", boss_style)
	var boss_bg := StyleBoxFlat.new()
	boss_bg.bg_color = Themes.ui("fill_dark")
	boss_bg.border_color = Themes.ui("hud_boss", 0.3)
	boss_bg.set_border_width_all(1)
	boss_bar.add_theme_stylebox_override("background", boss_bg)
	_reposition_for_screen()

func _setup_pause_button() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button = Button.new()
	pause_button.text = "ll"
	pause_button.add_theme_font_size_override("font_size", _sf(34))
	pause_button.offset_left = _s(15.0)
	pause_button.offset_top = _s(15.0)
	pause_button.offset_right = _s(95.0)
	pause_button.offset_bottom = _s(80.0)
	_style_popup_button(pause_button, Themes.ui("hud_threat"))
	pause_button.pressed.connect(_on_pause_pressed)
	add_child(pause_button)

func _on_pause_pressed() -> void:
	get_tree().paused = true
	var panel := _create_popup_panel(Color(0.5, 0.5, 0.5), 500.0, 700.0)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	# Layout vertical principal
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.offset_left = _s(60.0)
	vbox.offset_top = _s(30.0)
	vbox.offset_right = _s(440.0)
	vbox.offset_bottom = _s(670.0)
	vbox.add_theme_constant_override("separation", _sf(20))
	panel.add_child(vbox)

	# Titulo
	var title := Label.new()
	title.text = get_node("/root/Tr").t("PAUSED")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _sf(40))
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(title)

	# Music
	var sm = get_node("/root/SoundManager")
	var music_label := Label.new()
	music_label.text = get_node("/root/Tr").t("MUSIC")
	music_label.add_theme_font_size_override("font_size", _sf(22))
	music_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(music_label)
	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.value = sm.get_music_volume_linear()
	music_slider.custom_minimum_size = Vector2(0, _s(40))
	music_slider.value_changed.connect(func(val): sm.set_music_volume(val))
	vbox.add_child(music_slider)

	# SFX
	var sfx_label := Label.new()
	sfx_label.text = get_node("/root/Tr").t("SFX")
	sfx_label.add_theme_font_size_override("font_size", _sf(22))
	sfx_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(sfx_label)
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01
	sfx_slider.value = sm.get_sfx_volume_linear()
	sfx_slider.custom_minimum_size = Vector2(0, _s(40))
	sfx_slider.value_changed.connect(func(val): sm.set_sfx_volume(val))
	vbox.add_child(sfx_slider)

	# Scanlines
	var scanline_row := HBoxContainer.new()
	scanline_row.alignment = BoxContainer.ALIGNMENT_CENTER
	scanline_row.add_theme_constant_override("separation", _sf(12))
	vbox.add_child(scanline_row)
	var scanline_label := Label.new()
	scanline_label.text = get_node("/root/Tr").t("SCANLINES")
	scanline_label.add_theme_font_size_override("font_size", _sf(22))
	scanline_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	scanline_row.add_child(scanline_label)
	var scanline_toggle := CheckButton.new()
	var main_node = get_node("/root/Main")
	scanline_toggle.button_pressed = main_node.save_system.scanlines_enabled
	scanline_toggle.toggled.connect(func(on: bool): main_node.set_scanlines(on))
	var toggle_wrap := Control.new()
	var sc := 2.5
	toggle_wrap.custom_minimum_size = Vector2(_s(60) * sc, _s(30) * sc)
	scanline_toggle.scale = Vector2(sc, sc)
	toggle_wrap.add_child(scanline_toggle)
	scanline_row.add_child(toggle_wrap)

	# Tema (so mostra se tiver mais de 1 desbloqueado)
	var unlocked_themes: Array[String] = []
	for tid in ["neon", "gameboy", "ascii"]:
		if Themes.is_unlocked(tid):
			unlocked_themes.append(tid)
	if unlocked_themes.size() > 1:
		var theme_row := HBoxContainer.new()
		theme_row.alignment = BoxContainer.ALIGNMENT_CENTER
		theme_row.add_theme_constant_override("separation", _sf(12))
		vbox.add_child(theme_row)
		var theme_label := Label.new()
		theme_label.text = get_node("/root/Tr").t("THEMES_SECTION")
		theme_label.add_theme_font_size_override("font_size", _sf(22))
		theme_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		theme_row.add_child(theme_label)
		var theme_dropdown := OptionButton.new()
		theme_dropdown.add_theme_font_size_override("font_size", _sf(26))
		theme_dropdown.custom_minimum_size = Vector2(_s(220), _s(50))
		var tr_node = get_node("/root/Tr")
		var selected_idx := 0
		var idx := 0
		for theme_id in unlocked_themes:
			theme_dropdown.add_item(tr_node.t("THEME_" + theme_id), idx)
			theme_dropdown.set_item_metadata(idx, theme_id)
			if Themes.current_theme == theme_id:
				selected_idx = idx
			idx += 1
		theme_dropdown.selected = selected_idx
		theme_dropdown.item_selected.connect(func(index: int):
			var sel_tid: String = theme_dropdown.get_item_metadata(index)
			Themes.set_theme_id(sel_tid)
			_force_redraw_all()
			get_node("/root/Main")._save_game()
		)
		var popup: PopupMenu = theme_dropdown.get_popup()
		popup.add_theme_font_size_override("font_size", _sf(28))
		popup.add_theme_constant_override("v_separation", _sf(10))
		theme_row.add_child(theme_dropdown)

	# Botoes
	var btn_box := VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", _sf(20))
	vbox.add_child(btn_box)

	var resume_btn := Button.new()
	resume_btn.text = get_node("/root/Tr").t("RESUME")
	resume_btn.custom_minimum_size = Vector2(_s(300), _s(65))
	resume_btn.add_theme_font_size_override("font_size", _sf(28))
	_style_popup_button(resume_btn, Themes.ui("primary"))
	resume_btn.pressed.connect(func():
		get_tree().paused = false
		_dismiss_popup()
	)
	btn_box.add_child(resume_btn)

	var quit_btn := Button.new()
	quit_btn.text = get_node("/root/Tr").t("GIVE_UP")
	quit_btn.custom_minimum_size = Vector2(_s(300), _s(65))
	quit_btn.add_theme_font_size_override("font_size", _sf(28))
	_style_popup_button(quit_btn, Themes.ui("text_warning"))
	quit_btn.pressed.connect(func():
		get_tree().paused = false
		_dismiss_popup()
		quit_to_menu.emit()
	)
	btn_box.add_child(quit_btn)

	_show_popup(panel)

func _force_redraw_all() -> void:
	var game = get_parent()
	if not game:
		return
	for node in game.get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(node):
			node.queue_redraw()
	for node in game.get_tree().get_nodes_in_group("fragment"):
		if is_instance_valid(node):
			node.queue_redraw()
	# Neon grid
	for child in game.get_children():
		if child.has_method("queue_redraw"):
			child.queue_redraw()


func _reposition_for_screen() -> void:
	var screen := get_viewport().get_visible_rect().size
	var screen_w := screen.x
	var center_y := screen.y * 0.55
	# Esconde barras e botoes originais do .tscn — usamos custom draw
	special_bar.visible = false
	nova_button.visible = false
	freeze_bar.visible = false
	freeze_button.visible = false
	# Botoes circulares colados nas bordas laterais
	var radius := _s(90.0)
	var margin := radius + _s(5.0)
	_create_circle_button("nova", Vector2(margin, center_y),
		Themes.ui("hud_special"), _on_nova_pressed)
	_create_circle_button("freeze", Vector2(screen_w - margin, center_y),
		Themes.ui("hud_freeze"), _on_freeze_pressed)

var nova_circle: Control
var freeze_circle: Control
var nova_charge := 0.0
var nova_ready := false
var freeze_charge_val := 0.0
var freeze_ready_val := false

func _create_circle_button(id: String, pos: Vector2, color: Color, callback: Callable) -> void:
	var radius := _s(55.0)
	var btn := Button.new()
	btn.set_meta("no_click_sfx", true)
	btn.offset_left = pos.x - radius
	btn.offset_top = pos.y - radius
	btn.offset_right = pos.x + radius
	btn.offset_bottom = pos.y + radius
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.disabled = true
	btn.focus_mode = Control.FOCUS_NONE
	var empty_style := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("disabled", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.pressed.connect(callback)
	add_child(btn)
	var draw_ctrl := Control.new()
	draw_ctrl.offset_left = pos.x - radius - _s(5.0)
	draw_ctrl.offset_top = pos.y - radius - _s(5.0)
	draw_ctrl.offset_right = pos.x + radius + _s(5.0)
	draw_ctrl.offset_bottom = pos.y + radius + _s(5.0)
	draw_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := Vector2(radius + _s(5.0), radius + _s(5.0))
	var _color := color
	var _id := id
	var _self := self
	draw_ctrl.draw.connect(func():
		if not is_instance_valid(_self): return
		var charge := _self.nova_charge if _id == "nova" else _self.freeze_charge_val
		var is_ready := _self.nova_ready if _id == "nova" else _self.freeze_ready_val
		var alpha := 0.6 if is_ready else 0.25
		# Fundo circular
		draw_ctrl.draw_circle(center, radius, Color(_color.r, _color.g, _color.b, alpha * 0.3))
		# Borda
		draw_ctrl.draw_arc(center, radius, 0, TAU, 64, Color(_color.r, _color.g, _color.b, alpha * 0.5), _self._s(2.0), true)
		# Arco de carga
		if charge > 0.0:
			var arc_angle := TAU * (charge / 100.0)
			var arc_color := Color(1.0, 1.0, 0.0, 0.9) if is_ready else Color(_color.r, _color.g, _color.b, 0.7)
			draw_ctrl.draw_arc(center, radius - _self._s(4.0), -PI / 2.0, -PI / 2.0 + arc_angle, 64, arc_color, _self._s(5.0), true)
		# Icone
		var icon_color := Color(1.0, 1.0, 1.0, 0.9) if is_ready else Color(0.6, 0.6, 0.6, 0.5)
		if _id == "nova":
			_self._draw_nova_icon(draw_ctrl, center, icon_color)
		else:
			_self._draw_freeze_icon(draw_ctrl, center, icon_color)
	)
	add_child(draw_ctrl)
	if id == "nova":
		nova_circle = draw_ctrl
		nova_circle.set_meta("btn", btn)
	else:
		freeze_circle = draw_ctrl
		freeze_circle.set_meta("btn", btn)
		freeze_circle.visible = false
		btn.visible = false

func _draw_nova_icon(ctrl: Control, center: Vector2, color: Color) -> void:
	# Estrela de explosao — 8 pontas
	var spikes := 8
	var outer := _s(28.0)
	var inner := _s(12.0)
	for i in spikes:
		var angle := TAU * i / spikes - PI / 2.0
		var next_angle := TAU * (i + 0.5) / spikes - PI / 2.0
		var p1 := center + Vector2.from_angle(angle) * outer
		var p2 := center + Vector2.from_angle(next_angle) * inner
		ctrl.draw_line(center, p1, color, _s(3.0), true)
		ctrl.draw_line(p1, p2, color, _s(2.0), true)
	ctrl.draw_circle(center, _s(6.0), color)

func _draw_freeze_icon(ctrl: Control, center: Vector2, color: Color) -> void:
	# Floco de neve — 6 bracos com ramificacoes
	var arms := 6
	var arm_len := _s(26.0)
	var branch_len := _s(12.0)
	for i in arms:
		var angle := TAU * i / arms - PI / 2.0
		var tip := center + Vector2.from_angle(angle) * arm_len
		ctrl.draw_line(center, tip, color, _s(3.0), true)
		# Ramificacoes
		var mid := center + Vector2.from_angle(angle) * arm_len * 0.55
		var b1 := mid + Vector2.from_angle(angle + 0.7) * branch_len
		var b2 := mid + Vector2.from_angle(angle - 0.7) * branch_len
		ctrl.draw_line(mid, b1, color, _s(2.0), true)
		ctrl.draw_line(mid, b2, color, _s(2.0), true)
	ctrl.draw_circle(center, _s(4.0), color)

# ============================================================
# CURRENCIES HUD
# ============================================================

func _process(delta: float) -> void:
	if not combo_label.visible:
		return
	combo_time += delta
	# Intensidade baseada no combo (0.0 a 1.0, satura em ~30)
	var intensity := clampf(float(combo_value - 2) / 28.0, 0.0, 1.0)
	# Wiggle — angulo e velocidade crescem com combo
	var wiggle_speed := 5.0 + intensity * 15.0
	var wiggle_angle := (2.0 + intensity * 5.0) * sin(combo_time * wiggle_speed)
	combo_label.rotation = deg_to_rad(wiggle_angle)
	# Shake — offset aleatorio proporcional a intensidade
	var shake := intensity * 4.0
	combo_label.offset_top = combo_base_top + randf_range(-shake, shake)
	# Cor — ciano → amarelo → rosa/vermelho (adapta ao tema)
	var col: Color
	var c_primary: Color = Themes.ui("hud_combo")
	var c_mid: Color = Themes.ui("gem_eter")  # laranja/amarelo
	var c_hot: Color = Themes.ui("enemy_basic")  # rosa/vermelho
	if combo_value < 6:
		col = c_primary
	elif combo_value < 12:
		var t := float(combo_value - 6) / 6.0
		col = c_primary.lerp(c_mid, t)
	elif combo_value < 18:
		var t := float(combo_value - 12) / 6.0
		col = c_mid.lerp(c_hot, t)
	else:
		var flash := 0.5 + 0.5 * sin(combo_time * 12.0)
		col = c_hot.lerp(Themes.ui("text_primary"), flash * 0.4)
	combo_label.add_theme_color_override("font_color", col)
	combo_label.add_theme_color_override("font_outline_color", Color(col.r * 0.3, col.g * 0.3, col.b * 0.3))

func break_combo() -> void:
	if combo_value < 2:
		return
	_combo_breaking = true
	get_node("/root/SoundManager").combo_break()
	if combo_tween and combo_tween.is_valid():
		combo_tween.kill()
	# Pega posicao e texto antes de esconder
	var text := combo_label.text
	var scr := get_viewport().get_visible_rect().size
	var font := combo_label.get_theme_font("font")
	var font_size := _sf(96)
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var base_x := (scr.x - text_w) / 2.0
	var base_y := combo_base_top + _s(10.0)
	var red: Color = Themes.ui("text_warning")
	combo_label.visible = false
	# Cria um fragmento pra cada caractere
	var char_x := base_x
	for i in text.length():
		var ch := text[i]
		var ch_w := font.get_char_size(ch.unicode_at(0), font_size).x
		var shard := Label.new()
		shard.text = ch
		shard.add_theme_font_size_override("font_size", font_size)
		shard.add_theme_color_override("font_color", red)
		shard.add_theme_color_override("font_outline_color", Color(red.r, red.g, red.b, 0.4))
		shard.add_theme_constant_override("outline_size", _sf(4))
		shard.position = Vector2(char_x, base_y)
		shard.pivot_offset = Vector2(ch_w / 2.0, _s(48.0))
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shard)
		# Cada pedaco voa em direcao aleatoria
		var angle := randf_range(-PI * 0.8, PI * 0.8)
		var dist := randf_range(_s(80.0), _s(200.0))
		var target_pos := shard.position + Vector2(cos(angle), sin(angle)) * dist
		var rot := randf_range(-1.5, 1.5)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(shard, "position", target_pos, 0.5).set_ease(Tween.EASE_OUT)
		tw.tween_property(shard, "rotation", rot, 0.5)
		tw.tween_property(shard, "modulate:a", 0.0, 0.5).set_delay(0.1)
		tw.chain().tween_callback(shard.queue_free)
		char_x += ch_w
	# Reseta estado depois da animacao
	combo_tween = create_tween()
	combo_tween.tween_interval(0.6)
	combo_tween.tween_callback(func():
		combo_label.add_theme_color_override("font_color", Themes.ui("hud_combo"))
		_combo_breaking = false
	)

func update_combo(value: int) -> void:
	combo_value = value
	if value < 2:
		if not _combo_breaking:
			combo_label.visible = false
			combo_label.rotation = 0.0
			combo_label.offset_top = combo_base_top
		return
	combo_label.text = "x%d" % value
	combo_label.visible = true
	# Scale punch animation
	if combo_tween and combo_tween.is_valid():
		combo_tween.kill()
	combo_label.pivot_offset = Vector2(combo_label.size.x / 2.0, combo_label.size.y / 2.0)
	combo_label.scale = Vector2(1.3, 1.3)
	combo_tween = create_tween()
	combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func update_threat(level: float) -> void:
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
		var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _sf(28)).x
		x -= text_w
		currency_draw.draw_string(font, Vector2(x, _s(30)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _sf(28), Color.WHITE)
		x -= _s(24)
		_draw_gem(currency_draw, Vector2(x + _s(8), _s(20)), GEM_COLORS[entry["type"]])
		x -= _s(20)

func _draw_gem(c: Control, center: Vector2, col: Color) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, _s(-10)),
		center + Vector2(_s(8), 0),
		center + Vector2(0, _s(10)),
		center + Vector2(_s(-8), 0),
	])
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), _s(1.5), true)
	c.draw_line(pts[3], pts[0], Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), _s(1.5), true)
	c.draw_line(center + Vector2(_s(-8), 0), center + Vector2(0, _s(-3)), Color(1, 1, 1, 0.3), _s(1.0), true)
	c.draw_line(center + Vector2(0, _s(-3)), center + Vector2(0, _s(-10)), Color(1, 1, 1, 0.3), _s(1.0), true)

func _draw_gem_large(c: Control, center: Vector2, col: Color, s := 1.5) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, _s(-10) * s),
		center + Vector2(_s(8) * s, 0),
		center + Vector2(0, _s(10) * s),
		center + Vector2(_s(-8) * s, 0),
	])
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), _s(2.0), true)
	c.draw_line(pts[3], pts[0], Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.8), _s(2.0), true)
	c.draw_line(center + Vector2(_s(-8) * s, 0), center + Vector2(0, _s(-3) * s), Color(1, 1, 1, 0.35), _s(1.5), true)
	c.draw_line(center + Vector2(0, _s(-3) * s), center + Vector2(0, _s(-10) * s), Color(1, 1, 1, 0.35), _s(1.5), true)

# ============================================================
# SPECIAL / FREEZE / BOSS
# ============================================================

func update_special(charge: float, is_ready: bool) -> void:
	nova_charge = charge
	nova_ready = is_ready
	if nova_circle:
		nova_circle.get_meta("btn").disabled = not is_ready
		nova_circle.queue_redraw()

func update_freeze(charge: float, is_ready: bool) -> void:
	freeze_charge_val = charge
	freeze_ready_val = is_ready
	if freeze_circle:
		freeze_circle.get_meta("btn").disabled = not is_ready
		freeze_circle.queue_redraw()

func set_freeze_visible(val: bool) -> void:
	if freeze_circle:
		freeze_circle.visible = val
		freeze_circle.get_meta("btn").visible = val

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
	var w := _s(width)
	var h := _s(height)
	var scr := get_viewport().get_visible_rect().size
	var panel := Control.new()
	panel.offset_left = (scr.x - w) / 2.0
	panel.offset_top = (scr.y - h) / 2.0
	panel.offset_right = (scr.x + w) / 2.0
	panel.offset_bottom = (scr.y + h) / 2.0
	panel.pivot_offset = Vector2(w / 2.0, h / 2.0)
	# Background
	var bg := ColorRect.new()
	bg.color = Themes.ui("fill_entity", 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)
	# Neon border via draw
	var border := Control.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.draw.connect(func():
		if not is_instance_valid(border): return
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
	c.draw_circle(center + Vector2(0, _s(-8)), _s(22.0), Color(col.r, col.g, col.b, 0.15))
	c.draw_arc(center + Vector2(0, _s(-8)), _s(20.0), -PI, 0, 24, col, _s(2.5), true)
	# Mandibula
	c.draw_line(center + Vector2(_s(-20), _s(-8)), center + Vector2(_s(-18), _s(12)), col, _s(2.5), true)
	c.draw_line(center + Vector2(_s(20), _s(-8)), center + Vector2(_s(18), _s(12)), col, _s(2.5), true)
	c.draw_line(center + Vector2(_s(-18), _s(12)), center + Vector2(_s(18), _s(12)), col, _s(2.5), true)
	# Olhos
	c.draw_circle(center + Vector2(_s(-8), _s(-10)), _s(5.0), col)
	c.draw_circle(center + Vector2(_s(8), _s(-10)), _s(5.0), col)
	c.draw_circle(center + Vector2(_s(-8), _s(-10)), _s(3.0), Color(0, 0, 0))
	c.draw_circle(center + Vector2(_s(8), _s(-10)), _s(3.0), Color(0, 0, 0))
	# Nariz
	c.draw_line(center + Vector2(_s(-2), 0), center + Vector2(0, _s(4)), col, _s(2.0), true)
	c.draw_line(center + Vector2(_s(2), 0), center + Vector2(0, _s(4)), col, _s(2.0), true)
	# Dentes
	for i in 5:
		var tx := center.x - _s(12) + i * _s(6)
		c.draw_line(Vector2(tx, center.y + _s(8)), Vector2(tx, center.y + _s(15)), col, _s(1.5), true)

func _draw_trophy(c: Control, center: Vector2, col: Color) -> void:
	# Glow
	c.draw_circle(center, _s(28.0), Color(col.r, col.g, col.b, 0.1))
	# Copa
	var cup_pts := PackedVector2Array([
		center + Vector2(_s(-18), _s(-20)),
		center + Vector2(_s(18), _s(-20)),
		center + Vector2(_s(14), _s(6)),
		center + Vector2(_s(-14), _s(6)),
	])
	c.draw_colored_polygon(cup_pts, Color(col.r, col.g, col.b, 0.2))
	c.draw_polyline(cup_pts, col, _s(2.5), true)
	c.draw_line(cup_pts[3], cup_pts[0], col, _s(2.5), true)
	# Alcas
	c.draw_arc(center + Vector2(_s(-18), _s(-8)), _s(8.0), PI * 0.5, PI * 1.5, 12, col, _s(2.0), true)
	c.draw_arc(center + Vector2(_s(18), _s(-8)), _s(8.0), -PI * 0.5, PI * 0.5, 12, col, _s(2.0), true)
	# Haste
	c.draw_line(center + Vector2(0, _s(6)), center + Vector2(0, _s(16)), col, _s(2.5), true)
	# Base
	c.draw_line(center + Vector2(_s(-10), _s(16)), center + Vector2(_s(10), _s(16)), col, _s(2.5), true)
	c.draw_line(center + Vector2(_s(-12), _s(19)), center + Vector2(_s(12), _s(19)), col, _s(2.5), true)
	# Estrela no centro
	_draw_star(c, center + Vector2(0, _s(-8)), _s(6.0), col)

func _draw_star(c: Control, center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + i * TAU / 10.0
		var radius := r if i % 2 == 0 else r * 0.4
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	c.draw_colored_polygon(pts, col)

func _draw_heart(c: Control, center: Vector2, col: Color) -> void:
	# Glow
	c.draw_circle(center, _s(26.0), Color(col.r, col.g, col.b, 0.1))
	# Duas metades do coracao
	c.draw_circle(center + Vector2(_s(-10), _s(-6)), _s(12.0), Color(col.r, col.g, col.b, 0.25))
	c.draw_circle(center + Vector2(_s(10), _s(-6)), _s(12.0), Color(col.r, col.g, col.b, 0.25))
	c.draw_arc(center + Vector2(_s(-10), _s(-6)), _s(12.0), PI, TAU, 16, col, _s(2.5), true)
	c.draw_arc(center + Vector2(_s(10), _s(-6)), _s(12.0), PI, TAU, 16, col, _s(2.5), true)
	# Ponta inferior
	var heart_pts := PackedVector2Array([
		center + Vector2(_s(-22), _s(-6)),
		center + Vector2(0, _s(22)),
		center + Vector2(_s(22), _s(-6)),
	])
	c.draw_colored_polygon(heart_pts, Color(col.r, col.g, col.b, 0.25))
	c.draw_line(center + Vector2(_s(-22), _s(-6)), center + Vector2(0, _s(22)), col, _s(2.5), true)
	c.draw_line(center + Vector2(_s(22), _s(-6)), center + Vector2(0, _s(22)), col, _s(2.5), true)
	# Brilho
	c.draw_line(center + Vector2(_s(-14), _s(-10)), center + Vector2(_s(-8), _s(-4)), Color(1, 1, 1, 0.4), _s(2.0), true)

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
		c.draw_string(font, Vector2(w / 2.0 - _s(80), _s(20)), get_node("/root/Tr").t("NO_EARNINGS"), HORIZONTAL_ALIGNMENT_LEFT, -1, _sf(22), Color(0.5, 0.5, 0.5))
		return
	var total_w := 0.0
	for entry in entries:
		total_w += font.get_string_size("%d" % entry["amount"], HORIZONTAL_ALIGNMENT_LEFT, -1, _sf(24)).x + _s(38)
	total_w -= _s(10)  # remove last spacing
	var x := (w - total_w) / 2.0
	for entry in entries:
		_draw_gem_large(c, Vector2(x + _s(8), _s(14)), GEM_COLORS[entry["type"]])
		x += _s(22)
		var text := "%d" % entry["amount"]
		c.draw_string(font, Vector2(x, _s(22)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, _sf(24), Color.WHITE)
		x += font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _sf(24)).x + _s(16)

# ============================================================
# GAME OVER POPUP
# ============================================================

func show_game_over() -> void:
	var red := Color(1.0, 0.1, 0.2)
	var panel := _create_popup_panel(red, 580.0, 420.0)
	# Icon
	popup_icon_draw = Control.new()
	popup_icon_draw.offset_left = _s(240.0)
	popup_icon_draw.offset_top = _s(30.0)
	popup_icon_draw.offset_right = _s(340.0)
	popup_icon_draw.offset_bottom = _s(100.0)
	popup_icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _icon := popup_icon_draw
	popup_icon_draw.draw.connect(func():
		if not is_instance_valid(_icon): return
		_draw_skull(_icon, Vector2(_s(50), _s(35)), red))
	panel.add_child(popup_icon_draw)
	# Title
	var title := Label.new()
	title.text = get_node("/root/Tr").t("GAME_OVER")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _sf(42))
	title.add_theme_color_override("font_color", red)
	title.offset_left = _s(40.0)
	title.offset_top = _s(110.0)
	title.offset_right = _s(540.0)
	title.offset_bottom = _s(165.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	# Separator
	var sep := Control.new()
	sep.offset_left = _s(60.0)
	sep.offset_top = _s(170.0)
	sep.offset_right = _s(520.0)
	sep.offset_bottom = _s(172.0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func():
		if not is_instance_valid(sep): return
		sep.draw_line(Vector2.ZERO, Vector2(sep.size.x, 0), Color(red.r, red.g, red.b, 0.3), _s(1.5)))
	panel.add_child(sep)
	# Ganhos label
	var ganhos_lbl := Label.new()
	ganhos_lbl.text = get_node("/root/Tr").t("RUN_EARNINGS")
	ganhos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ganhos_lbl.add_theme_font_size_override("font_size", _sf(18))
	ganhos_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	ganhos_lbl.offset_left = _s(40.0)
	ganhos_lbl.offset_top = _s(182.0)
	ganhos_lbl.offset_right = _s(540.0)
	ganhos_lbl.offset_bottom = _s(205.0)
	ganhos_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ganhos_lbl)
	# Earnings draw
	popup_earnings_draw = Control.new()
	popup_earnings_draw.offset_left = _s(40.0)
	popup_earnings_draw.offset_top = _s(210.0)
	popup_earnings_draw.offset_right = _s(540.0)
	popup_earnings_draw.offset_bottom = _s(260.0)
	popup_earnings_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _earn := popup_earnings_draw
	popup_earnings_draw.draw.connect(func():
		if not is_instance_valid(_earn): return
		_draw_earnings(_earn))
	panel.add_child(popup_earnings_draw)
	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = _s(60.0)
	btn_container.offset_top = _s(310.0)
	btn_container.offset_right = _s(520.0)
	btn_container.offset_bottom = _s(390.0)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", _sf(30))
	panel.add_child(btn_container)
	var game = get_parent()
	if game.ad_system and game.ad_system.can_show_shop_ad():
		var double_btn := Button.new()
		double_btn.text = get_node("/root/Tr").t("DOUBLE_EARNINGS_AD")
		double_btn.custom_minimum_size = Vector2(_s(280), _s(65))
		double_btn.add_theme_font_size_override("font_size", _sf(22))
		_style_popup_button(double_btn, Color(1.0, 0.8, 0.0))
		double_btn.pressed.connect(_on_double_pressed)
		btn_container.add_child(double_btn)
		var decline_btn := Button.new()
		decline_btn.text = get_node("/root/Tr").t("NO")
		decline_btn.custom_minimum_size = Vector2(_s(140), _s(65))
		decline_btn.add_theme_font_size_override("font_size", _sf(22))
		_style_popup_button(decline_btn, Color(0.6, 0.2, 0.2))
		decline_btn.pressed.connect(_on_double_decline_pressed)
		btn_container.add_child(decline_btn)
	else:
		var cont_btn := Button.new()
		cont_btn.text = get_node("/root/Tr").t("CONTINUE")
		cont_btn.custom_minimum_size = Vector2(_s(240), _s(65))
		cont_btn.add_theme_font_size_override("font_size", _sf(24))
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
	popup_icon_draw.offset_left = _s(240.0)
	popup_icon_draw.offset_top = _s(30.0)
	popup_icon_draw.offset_right = _s(340.0)
	popup_icon_draw.offset_bottom = _s(100.0)
	popup_icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _icon := popup_icon_draw
	popup_icon_draw.draw.connect(func():
		if not is_instance_valid(_icon): return
		_draw_trophy(_icon, Vector2(_s(50), _s(35)), green))
	panel.add_child(popup_icon_draw)
	# Title
	var title := Label.new()
	title.text = get_node("/root/Tr").t("VICTORY")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _sf(42))
	title.add_theme_color_override("font_color", green)
	title.offset_left = _s(40.0)
	title.offset_top = _s(110.0)
	title.offset_right = _s(540.0)
	title.offset_bottom = _s(165.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	# Separator
	var sep := Control.new()
	sep.offset_left = _s(60.0)
	sep.offset_top = _s(170.0)
	sep.offset_right = _s(520.0)
	sep.offset_bottom = _s(172.0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func():
		if not is_instance_valid(sep): return
		sep.draw_line(Vector2.ZERO, Vector2(sep.size.x, 0), Color(green.r, green.g, green.b, 0.3), _s(1.5)))
	panel.add_child(sep)
	# Ganhos label
	var ganhos_lbl := Label.new()
	ganhos_lbl.text = get_node("/root/Tr").t("RUN_EARNINGS")
	ganhos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ganhos_lbl.add_theme_font_size_override("font_size", _sf(18))
	ganhos_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	ganhos_lbl.offset_left = _s(40.0)
	ganhos_lbl.offset_top = _s(182.0)
	ganhos_lbl.offset_right = _s(540.0)
	ganhos_lbl.offset_bottom = _s(205.0)
	ganhos_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ganhos_lbl)
	# Earnings draw
	popup_earnings_draw = Control.new()
	popup_earnings_draw.offset_left = _s(40.0)
	popup_earnings_draw.offset_top = _s(210.0)
	popup_earnings_draw.offset_right = _s(540.0)
	popup_earnings_draw.offset_bottom = _s(260.0)
	popup_earnings_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _earn := popup_earnings_draw
	popup_earnings_draw.draw.connect(func():
		if not is_instance_valid(_earn): return
		_draw_earnings(_earn))
	panel.add_child(popup_earnings_draw)
	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = _s(60.0)
	btn_container.offset_top = _s(310.0)
	btn_container.offset_right = _s(520.0)
	btn_container.offset_bottom = _s(390.0)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", _sf(30))
	panel.add_child(btn_container)
	var game = get_parent()
	if game.ad_system and game.ad_system.can_show_shop_ad():
		var double_btn := Button.new()
		double_btn.text = get_node("/root/Tr").t("DOUBLE_EARNINGS_AD")
		double_btn.custom_minimum_size = Vector2(_s(280), _s(65))
		double_btn.add_theme_font_size_override("font_size", _sf(22))
		_style_popup_button(double_btn, Color(1.0, 0.8, 0.0))
		double_btn.pressed.connect(_on_double_pressed)
		btn_container.add_child(double_btn)
		var decline_btn := Button.new()
		decline_btn.text = get_node("/root/Tr").t("NO")
		decline_btn.custom_minimum_size = Vector2(_s(140), _s(65))
		decline_btn.add_theme_font_size_override("font_size", _sf(22))
		_style_popup_button(decline_btn, Color(0.5, 0.5, 0.5))
		decline_btn.pressed.connect(_on_double_decline_pressed)
		btn_container.add_child(decline_btn)
	else:
		var cont_btn := Button.new()
		cont_btn.text = get_node("/root/Tr").t("CONTINUE")
		cont_btn.custom_minimum_size = Vector2(_s(280), _s(65))
		cont_btn.add_theme_font_size_override("font_size", _sf(26))
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
	popup_icon_draw.offset_left = _s(210.0)
	popup_icon_draw.offset_top = _s(25.0)
	popup_icon_draw.offset_right = _s(310.0)
	popup_icon_draw.offset_bottom = _s(95.0)
	popup_icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _icon := popup_icon_draw
	popup_icon_draw.draw.connect(func():
		if not is_instance_valid(_icon): return
		_draw_heart(_icon, Vector2(_s(50), _s(35)), cyan))
	panel.add_child(popup_icon_draw)
	# Title
	var title := Label.new()
	title.text = get_node("/root/Tr").t("REVIVE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _sf(36))
	title.add_theme_color_override("font_color", cyan)
	title.offset_left = _s(30.0)
	title.offset_top = _s(105.0)
	title.offset_right = _s(490.0)
	title.offset_bottom = _s(150.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	# Subtitle
	var sub := Label.new()
	sub.text = get_node("/root/Tr").t("REVIVE_SUBTITLE")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", _sf(18))
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	sub.offset_left = _s(30.0)
	sub.offset_top = _s(155.0)
	sub.offset_right = _s(490.0)
	sub.offset_bottom = _s(180.0)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub)
	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = _s(50.0)
	btn_container.offset_top = _s(230.0)
	btn_container.offset_right = _s(470.0)
	btn_container.offset_bottom = _s(310.0)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", _sf(30))
	panel.add_child(btn_container)
	var revive_btn := Button.new()
	revive_btn.text = get_node("/root/Tr").t("REVIVE")
	revive_btn.custom_minimum_size = Vector2(_s(200), _s(65))
	revive_btn.add_theme_font_size_override("font_size", _sf(24))
	_style_popup_button(revive_btn, Color(0.0, 1.0, 0.5))
	revive_btn.pressed.connect(_on_revive_pressed)
	btn_container.add_child(revive_btn)
	var decline_btn := Button.new()
	decline_btn.text = get_node("/root/Tr").t("NO")
	decline_btn.custom_minimum_size = Vector2(_s(140), _s(65))
	decline_btn.add_theme_font_size_override("font_size", _sf(24))
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
	title.text = get_node("/root/Tr").t("DOUBLE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _sf(32))
	title.add_theme_color_override("font_color", gold)
	title.offset_left = _s(30.0)
	title.offset_top = _s(30.0)
	title.offset_right = _s(530.0)
	title.offset_bottom = _s(75.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	# Separator
	var sep := Control.new()
	sep.offset_left = _s(60.0)
	sep.offset_top = _s(85.0)
	sep.offset_right = _s(500.0)
	sep.offset_bottom = _s(87.0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func():
		if not is_instance_valid(sep): return
		sep.draw_line(Vector2.ZERO, Vector2(sep.size.x, 0), Color(gold.r, gold.g, gold.b, 0.3), _s(1.5)))
	panel.add_child(sep)
	# Earnings draw
	popup_earnings_draw = Control.new()
	popup_earnings_draw.offset_left = _s(30.0)
	popup_earnings_draw.offset_top = _s(100.0)
	popup_earnings_draw.offset_right = _s(530.0)
	popup_earnings_draw.offset_bottom = _s(150.0)
	popup_earnings_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _earn := popup_earnings_draw
	popup_earnings_draw.draw.connect(func():
		if not is_instance_valid(_earn): return
		_draw_earnings(_earn))
	panel.add_child(popup_earnings_draw)
	# Sub
	var sub := Label.new()
	sub.text = get_node("/root/Tr").t("DOUBLE_SUBTITLE")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", _sf(18))
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	sub.offset_left = _s(30.0)
	sub.offset_top = _s(165.0)
	sub.offset_right = _s(530.0)
	sub.offset_bottom = _s(190.0)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sub)
	# Buttons
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = _s(50.0)
	btn_container.offset_top = _s(270.0)
	btn_container.offset_right = _s(510.0)
	btn_container.offset_bottom = _s(350.0)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", _sf(30))
	panel.add_child(btn_container)
	var double_btn := Button.new()
	double_btn.text = get_node("/root/Tr").t("DOUBLE_BTN")
	double_btn.custom_minimum_size = Vector2(_s(240), _s(65))
	double_btn.add_theme_font_size_override("font_size", _sf(22))
	_style_popup_button(double_btn, gold)
	double_btn.pressed.connect(_on_double_pressed)
	btn_container.add_child(double_btn)
	var decline_btn := Button.new()
	decline_btn.text = get_node("/root/Tr").t("NO")
	decline_btn.custom_minimum_size = Vector2(_s(140), _s(65))
	decline_btn.add_theme_font_size_override("font_size", _sf(22))
	_style_popup_button(decline_btn, Color(0.6, 0.2, 0.2))
	decline_btn.pressed.connect(_on_double_decline_pressed)
	btn_container.add_child(decline_btn)
	_show_popup(panel)

func hide_double_offer() -> void:
	_dismiss_popup()

func show_ad_unavailable() -> void:
	if not current_popup:
		return
	var popup_w := current_popup.offset_right - current_popup.offset_left
	var red := Color(1.0, 0.3, 0.2)
	var label := Label.new()
	label.text = get_node("/root/Tr").t("AD_UNAVAILABLE")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _sf(20))
	label.add_theme_color_override("font_color", red)
	label.offset_left = _s(30.0)
	label.offset_right = popup_w - _s(30.0)
	label.offset_top = _s(190.0)
	label.offset_bottom = _s(220.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_popup.add_child(label)

# ============================================================
# POPUP CALLBACKS
# ============================================================

func set_earnings(earnings: Dictionary) -> void:
	cached_earnings = earnings

func _on_revive_pressed() -> void:
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
	popup_icon_draw.offset_left = _s(240.0)
	popup_icon_draw.offset_top = _s(25.0)
	popup_icon_draw.offset_right = _s(340.0)
	popup_icon_draw.offset_bottom = _s(95.0)
	popup_icon_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _icon := popup_icon_draw
	popup_icon_draw.draw.connect(func():
		if not is_instance_valid(_icon): return
		_draw_skull(_icon, Vector2(_s(50), _s(35)), red))
	panel.add_child(popup_icon_draw)
	var title := Label.new()
	title.text = get_node("/root/Tr").t("GAME_OVER")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", _sf(42))
	title.add_theme_color_override("font_color", red)
	title.offset_left = _s(40.0)
	title.offset_top = _s(100.0)
	title.offset_right = _s(540.0)
	title.offset_bottom = _s(155.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)
	var sep := Control.new()
	sep.offset_left = _s(60.0)
	sep.offset_top = _s(160.0)
	sep.offset_right = _s(520.0)
	sep.offset_bottom = _s(162.0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.draw.connect(func():
		if not is_instance_valid(sep): return
		sep.draw_line(Vector2.ZERO, Vector2(sep.size.x, 0), Color(red.r, red.g, red.b, 0.3), _s(1.5)))
	panel.add_child(sep)
	popup_earnings_draw = Control.new()
	popup_earnings_draw.offset_left = _s(40.0)
	popup_earnings_draw.offset_top = _s(175.0)
	popup_earnings_draw.offset_right = _s(540.0)
	popup_earnings_draw.offset_bottom = _s(225.0)
	popup_earnings_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _earn := popup_earnings_draw
	popup_earnings_draw.draw.connect(func():
		if not is_instance_valid(_earn): return
		_draw_earnings(_earn))
	panel.add_child(popup_earnings_draw)
	var btn_container := HBoxContainer.new()
	btn_container.offset_left = _s(60.0)
	btn_container.offset_top = _s(280.0)
	btn_container.offset_right = _s(520.0)
	btn_container.offset_bottom = _s(355.0)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(btn_container)
	var cont_btn := Button.new()
	cont_btn.text = get_node("/root/Tr").t("CONTINUE")
	cont_btn.custom_minimum_size = Vector2(_s(260), _s(65))
	cont_btn.add_theme_font_size_override("font_size", _sf(24))
	_style_popup_button(cont_btn, red)
	cont_btn.pressed.connect(func(): _dismiss_popup(); get_parent().game_over.emit())
	btn_container.add_child(cont_btn)
	_show_popup(panel)

func _on_double_pressed() -> void:
	var game = get_parent()
	if game.has_method("double_run_earnings"):
		game.double_run_earnings()

func _on_double_decline_pressed() -> void:
	_dismiss_popup()
	var game = get_parent()
	if game.has_method("decline_double"):
		game.decline_double()
