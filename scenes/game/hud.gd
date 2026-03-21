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

func _ready() -> void:
	game_over_label.visible = false
	victory_label.visible = false
	boss_bar.visible = false
	boss_label.visible = false
	nova_button.pressed.connect(_on_nova_pressed)

func update_threat(level: float) -> void:
	threat_label.text = "AMEACA: %d" % int(level)
	threat_bar.value = level

func update_currencies(credits: int, crystals: int, void_amount: int) -> void:
	credits_label.text = "%d CR  %d CS  %d VO" % [credits, crystals, void_amount]

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

func _on_nova_pressed() -> void:
	var game = get_parent()
	if game.has_method("activate_nova_bomb"):
		game.activate_nova_bomb()
