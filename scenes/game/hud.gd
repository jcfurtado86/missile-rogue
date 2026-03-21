extends CanvasLayer

@onready var threat_label: Label = $ThreatLabel
@onready var threat_bar: ProgressBar = $ThreatBar
@onready var credits_label: Label = $CreditsLabel
@onready var game_over_label: Label = $GameOverLabel

func _ready() -> void:
	game_over_label.visible = false

func update_threat(level: float) -> void:
	threat_label.text = "AMEACA: %d" % int(level)
	threat_bar.value = level

func update_currencies(credits: int, crystals: int, void_amount: int) -> void:
	credits_label.text = "%d CR  %d CS  %d VO" % [credits, crystals, void_amount]

func show_game_over() -> void:
	game_over_label.visible = true
