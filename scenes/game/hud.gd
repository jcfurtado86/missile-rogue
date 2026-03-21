extends CanvasLayer

@onready var threat_label: Label = $ThreatLabel
@onready var threat_bar: ProgressBar = $ThreatBar
@onready var credits_label: Label = $CreditsLabel
@onready var game_over_label: Label = $GameOverLabel
@onready var special_bar: ProgressBar = $SpecialBar
@onready var nova_button: Button = $NovaButton
@onready var boss_bar: ProgressBar = $BossBar
@onready var boss_label: Label = $BossLabel
@onready var victory_label: Label = $VictoryLabel
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
	revive_button.pressed.connect(_on_revive_pressed)
	decline_button.pressed.connect(_on_decline_pressed)
	double_button.pressed.connect(_on_double_pressed)
	double_decline_button.pressed.connect(_on_double_decline_pressed)

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
		nova_button.modulate = Color(1.0, 0.8, 0.2)
	else:
		nova_button.modulate = Color(0.5, 0.5, 0.5)

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

func show_revive_offer() -> void:
	revive_container.visible = true

func hide_revive_offer() -> void:
	revive_container.visible = false

func _on_nova_pressed() -> void:
	var game = get_parent()
	if game.has_method("activate_nova_bomb"):
		game.activate_nova_bomb()

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
