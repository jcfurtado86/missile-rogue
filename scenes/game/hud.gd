extends CanvasLayer

@onready var threat_label: Label = $ThreatLabel
@onready var threat_bar: ProgressBar = $ThreatBar
@onready var credits_label: Label = $CreditsLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var special_bar: ProgressBar = $SpecialBar
@onready var nova_button: Button = $NovaButton
@onready var freeze_bar: ProgressBar = $FreezeBar
@onready var freeze_button: Button = $FreezeButton
@onready var boss_bar: ProgressBar = $BossBar
@onready var boss_label: Label = $BossLabel
@onready var victory_label: Label = $VictoryLabel
@onready var victory_button: Button = $VictoryButton
@onready var revive_container: HBoxContainer = $ReviveContainer
@onready var revive_button: Button = $ReviveContainer/ReviveButton
@onready var decline_button: Button = $ReviveContainer/DeclineButton
@onready var double_container: VBoxContainer = $DoubleContainer
@onready var earnings_label: Label = $DoubleContainer/EarningsLabel
@onready var double_button: Button = $DoubleContainer/DoubleButtons/DoubleButton
@onready var double_decline_button: Button = $DoubleContainer/DoubleButtons/DoubleDeclineButton

func _ready() -> void:
	game_over_label.visible = false
	victory_label.visible = false
	boss_bar.visible = false
	boss_label.visible = false
	revive_container.visible = false
	double_container.visible = false
	nova_button.pressed.connect(_on_nova_pressed)
	freeze_button.pressed.connect(_on_freeze_pressed)
	victory_button.pressed.connect(_on_victory_pressed)
	revive_button.pressed.connect(_on_revive_pressed)
	decline_button.pressed.connect(_on_decline_pressed)
	double_button.pressed.connect(_on_double_pressed)
	double_decline_button.pressed.connect(_on_double_decline_pressed)
	_apply_neon_style()
	_reposition_for_screen()

func _apply_neon_style() -> void:
	# Labels neon
	threat_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	credits_label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	game_over_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.3))
	victory_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.1))
	boss_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.3))
	# Threat bar — magenta
	var threat_style := StyleBoxFlat.new()
	threat_style.bg_color = Color(1.0, 0.0, 0.6, 0.8)
	threat_bar.add_theme_stylebox_override("fill", threat_style)
	var threat_bg := StyleBoxFlat.new()
	threat_bg.bg_color = Color(0.1, 0.0, 0.05)
	threat_bg.border_color = Color(1.0, 0.0, 0.6, 0.3)
	threat_bg.border_width_bottom = 1
	threat_bg.border_width_top = 1
	threat_bg.border_width_left = 1
	threat_bg.border_width_right = 1
	threat_bar.add_theme_stylebox_override("background", threat_bg)
	# Special bar — cyan
	var special_style := StyleBoxFlat.new()
	special_style.bg_color = Color(0.0, 1.0, 1.0, 0.8)
	special_bar.add_theme_stylebox_override("fill", special_style)
	var special_bg := StyleBoxFlat.new()
	special_bg.bg_color = Color(0.0, 0.05, 0.1)
	special_bg.border_color = Color(0.0, 1.0, 1.0, 0.3)
	special_bg.border_width_bottom = 1
	special_bg.border_width_top = 1
	special_bg.border_width_left = 1
	special_bg.border_width_right = 1
	special_bar.add_theme_stylebox_override("background", special_bg)
	# Freeze bar — azul gelado
	var freeze_style := StyleBoxFlat.new()
	freeze_style.bg_color = Color(0.3, 0.6, 1.0, 0.8)
	freeze_bar.add_theme_stylebox_override("fill", freeze_style)
	var freeze_bg := StyleBoxFlat.new()
	freeze_bg.bg_color = Color(0.02, 0.03, 0.1)
	freeze_bg.border_color = Color(0.3, 0.6, 1.0, 0.3)
	freeze_bg.border_width_bottom = 1
	freeze_bg.border_width_top = 1
	freeze_bg.border_width_left = 1
	freeze_bg.border_width_right = 1
	freeze_bar.add_theme_stylebox_override("background", freeze_bg)
	# Boss bar — vermelho neon
	var boss_style := StyleBoxFlat.new()
	boss_style.bg_color = Color(1.0, 0.0, 0.2, 0.8)
	boss_bar.add_theme_stylebox_override("fill", boss_style)
	var boss_bg := StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.1, 0.0, 0.02)
	boss_bg.border_color = Color(1.0, 0.0, 0.2, 0.3)
	boss_bg.border_width_bottom = 1
	boss_bg.border_width_top = 1
	boss_bg.border_width_left = 1
	boss_bg.border_width_right = 1
	boss_bar.add_theme_stylebox_override("background", boss_bg)
	_reposition_for_screen()

func _reposition_for_screen() -> void:
	var screen := get_viewport().get_visible_rect().size
	var screen_h := screen.y
	var screen_w := screen.x
	# Barra especial e botao nova bomb — base esquerda
	special_bar.offset_top = screen_h - 100.0
	special_bar.offset_bottom = screen_h - 70.0
	nova_button.offset_top = screen_h - 65.0
	nova_button.offset_bottom = screen_h - 10.0
	# Barra freeze — base direita
	freeze_bar.offset_left = screen_w - 220.0
	freeze_bar.offset_right = screen_w - 20.0
	freeze_bar.offset_top = screen_h - 100.0
	freeze_bar.offset_bottom = screen_h - 70.0
	freeze_button.offset_left = screen_w - 220.0
	freeze_button.offset_right = screen_w - 20.0
	freeze_button.offset_top = screen_h - 65.0
	freeze_button.offset_bottom = screen_h - 10.0
	# Game over e vitoria — centro vertical
	var center_y := screen_h * 0.42
	game_over_label.offset_top = center_y
	game_over_label.offset_bottom = center_y + 100.0
	victory_label.offset_top = center_y
	victory_label.offset_bottom = center_y + 100.0
	# Containers de revive/double — logo abaixo do centro
	revive_container.offset_top = center_y + 100.0
	revive_container.offset_bottom = center_y + 170.0
	double_container.offset_top = center_y + 100.0
	double_container.offset_bottom = center_y + 260.0

func update_threat(level: float) -> void:
	threat_label.text = "AMEACA: %d" % int(level)
	threat_bar.value = level

func update_currencies(earnings: Dictionary) -> void:
	var parts: Array[String] = []
	if earnings.get("void", 0) > 0:
		parts.append("%d VO" % earnings["void"])
	if earnings.get("crystals", 0) > 0:
		parts.append("%d CS" % earnings["crystals"])
	if earnings.get("credits", 0) > 0:
		parts.append("%d CR" % earnings["credits"])
	credits_label.text = "  ".join(parts)

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

func show_game_over() -> void:
	game_over_label.visible = true

func show_victory() -> void:
	victory_label.visible = true
	victory_button.visible = true

func show_revive_offer() -> void:
	revive_container.visible = true

func hide_revive_offer() -> void:
	revive_container.visible = false

func _on_nova_pressed() -> void:
	var game = get_parent()
	if game.has_method("activate_nova_bomb"):
		game.activate_nova_bomb()

func _on_freeze_pressed() -> void:
	var game = get_parent()
	if game.has_method("activate_freeze"):
		game.activate_freeze()

func _on_victory_pressed() -> void:
	var game = get_parent()
	game.game_over.emit()

func _on_revive_pressed() -> void:
	var game = get_parent()
	if game.has_method("revive"):
		game.revive()

func _on_decline_pressed() -> void:
	hide_revive_offer()
	show_game_over()
	var game = get_parent()
	if game.ad_system and game.ad_system.can_show_shop_ad():
		show_double_offer(game.run_earnings)
	else:
		game.game_over.emit()

func show_double_offer(earnings: Dictionary) -> void:
	var parts: Array[String] = []
	if earnings.get("credits", 0) > 0:
		parts.append("%d CR" % earnings["credits"])
	if earnings.get("crystals", 0) > 0:
		parts.append("%d CS" % earnings["crystals"])
	if earnings.get("void", 0) > 0:
		parts.append("%d VO" % earnings["void"])
	if parts.is_empty():
		earnings_label.text = "Nenhum ganho nesta run"
	else:
		earnings_label.text = "Ganhos: " + "  ".join(parts)
	double_container.visible = true

func hide_double_offer() -> void:
	double_container.visible = false

func _on_double_pressed() -> void:
	var game = get_parent()
	if game.has_method("double_run_earnings"):
		game.double_run_earnings()

func _on_double_decline_pressed() -> void:
	var game = get_parent()
	if game.has_method("decline_double"):
		game.decline_double()
