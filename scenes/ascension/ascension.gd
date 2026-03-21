extends Control

signal ascension_confirmed
signal ascension_cancelled

var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var ascension_system: AscensionSystem

@onready var eter_preview_label: Label = $MarginContainer/VBoxContainer/EterPreview
@onready var eter_total_label: Label = $MarginContainer/VBoxContainer/EterTotal
@onready var invested_label: Label = $MarginContainer/VBoxContainer/InvestedLabel
@onready var ascension_count_label: Label = $MarginContainer/VBoxContainer/AscensionCount
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/Buttons/ConfirmButton
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/Buttons/CancelButton

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm)
	cancel_button.pressed.connect(_on_cancel)
	_update_display()

func setup(p_currency: CurrencySystem, p_upgrades: UpgradeSystem, p_ascension: AscensionSystem) -> void:
	currency = p_currency
	upgrade_system = p_upgrades
	ascension_system = p_ascension

func _update_display() -> void:
	if not currency or not upgrade_system or not ascension_system:
		return
	var eter_gain = ascension_system.calculate_eter(upgrade_system)
	var total_invested = upgrade_system.get_total_invested()
	eter_preview_label.text = "ETER GANHO: +%d" % eter_gain
	eter_total_label.text = "ETER TOTAL: %d → %d" % [ascension_system.get_total_eter(), ascension_system.get_total_eter() + eter_gain]
	invested_label.text = "TOTAL INVESTIDO: %d / %d = %d ETER" % [total_invested, ascension_system.conversion_factor, eter_gain]
	ascension_count_label.text = "ASCENSOES: %d" % ascension_system.get_ascension_count()
	confirm_button.disabled = false

func _on_confirm() -> void:
	ascension_system.perform_ascension(upgrade_system, currency)
	ascension_confirmed.emit()

func _on_cancel() -> void:
	ascension_cancelled.emit()
