class_name ThemeSystem
extends Node

signal theme_changed

enum Mode { NEON, GAMEBOY, ASCII }

var current_theme := "neon"
var _selected_mode: Mode = Mode.NEON
var mode: Mode:
	get: return _selected_mode if in_run else Mode.NEON
var palette: Dictionary = {}
var unlocked_themes: Dictionary = {"neon": true, "gameboy": false, "ascii": false}
var in_run := false  # tema so aplica durante a run

const THEME_COSTS := {"gameboy": 50, "ascii": 75}

# --- Paletas ---

const PALETTE_NEON := {
	# Geral
	"glow_alpha_mult": 1.0,
	"outline_width_mult": 1.0,
	# Fundos
	"sky_top": Color(0.02, 0.01, 0.08),
	"sky_mid": Color(0.08, 0.01, 0.15),
	"sky_horizon": Color(0.4, 0.0, 0.35),
	"floor_dark": Color(0.06, 0.0, 0.1),
	"fill_dark": Color(0.0, 0.08, 0.12),
	"fill_entity": Color(0.02, 0.03, 0.06),
	# Player
	"primary": Color(0.0, 1.0, 1.0),
	# Inimigos
	"enemy_basic": Color(1.0, 0.0, 0.6),
	"enemy_fast": Color(0.2, 1.0, 0.1),
	"enemy_cluster": Color(0.7, 0.0, 1.0),
	"enemy_boss": Color(1.0, 0.0, 0.3),
	"enemy_boss_rage": Color(1.0, 0.0, 0.1),
	# Explosoes
	"explosion_0": Color(0.0, 1.0, 1.0),
	"explosion_1": Color(1.0, 0.0, 0.6),
	"explosion_2": Color(1.0, 1.0, 0.0),
	"explosion_3": Color(0.2, 1.0, 0.1),
	"explosion_4": Color(0.7, 0.0, 1.0),
	"explosion_5": Color(1.0, 0.4, 0.0),
	# HUD
	"hud_threat": Color(1.0, 0.0, 0.6),
	"hud_special": Color(0.0, 1.0, 1.0),
	"hud_freeze": Color(0.3, 0.6, 1.0),
	"hud_boss": Color(1.0, 0.0, 0.2),
	"hud_combo": Color(0.0, 1.0, 1.0),
	# Moedas
	"gem_credits": Color(1.0, 0.0, 0.6),
	"gem_crystals": Color(0.2, 1.0, 0.1),
	"gem_void": Color(0.7, 0.0, 1.0),
	"gem_eter": Color(1.0, 0.5, 0.0),
	# UI
	"text_primary": Color(1.0, 1.0, 1.0),
	"text_warning": Color(1.0, 0.3, 0.2),
	"warning": Color(1.0, 0.0, 0.3),
	"target_lock": Color(1.0, 0.2, 0.2),
	"intercept_valid": Color(0.2, 1.0, 0.2),
	"intercept_invalid": Color(1.0, 0.8, 0.0),
	# Predios/montanhas
	"building_back_fill": Color(0.04, 0.01, 0.07),
	"building_back_outline": Color(0.6, 0.0, 0.8, 0.15),
	"building_back_window": Color(0.6, 0.0, 0.8, 0.08),
	"building_front_fill": Color(0.015, 0.005, 0.025),
	"building_front_outline": Color(1.0, 0.0, 0.6, 0.3),
	"building_front_window": Color(1.0, 0.0, 0.6, 0.12),
	"mountain_back": Color(0.6, 0.0, 0.8),
	"mountain_front": Color(1.0, 0.0, 0.6),
	"grid_line": Color(1.0, 0.0, 0.6, 0.15),
	"grid_line_bright": Color(1.0, 0.0, 0.6, 0.3),
	"horizon_line": Color(1.0, 0.0, 0.6),
	# Cidade
	"city_neon": Color(0.0, 0.8, 1.0),
	"city_fill": Color(0.02, 0.03, 0.06),
	"city_dead": Color(0.0, 0.6, 1.0, 0.2),
	"shield": Color(0.0, 1.0, 1.0),
	# Battery
	"battery_neon": Color(0.0, 0.8, 1.0),
	"battery_fill": Color(0.02, 0.04, 0.08),
}

const PALETTE_GAMEBOY := {
	"glow_alpha_mult": 0.0,
	"outline_width_mult": 1.5,
	"sky_top": Color(0.06, 0.22, 0.06),
	"sky_mid": Color(0.06, 0.22, 0.06),
	"sky_horizon": Color(0.06, 0.22, 0.06),
	"floor_dark": Color(0.06, 0.22, 0.06),
	"fill_dark": Color(0.06, 0.22, 0.06),
	"fill_entity": Color(0.06, 0.22, 0.06),
	"primary": Color(0.61, 0.74, 0.06),
	"enemy_basic": Color(0.61, 0.74, 0.06),
	"enemy_fast": Color(0.53, 0.67, 0.19),
	"enemy_cluster": Color(0.61, 0.74, 0.06),
	"enemy_boss": Color(0.61, 0.74, 0.06),
	"enemy_boss_rage": Color(0.61, 0.74, 0.06),
	"explosion_0": Color(0.61, 0.74, 0.06),
	"explosion_1": Color(0.53, 0.67, 0.19),
	"explosion_2": Color(0.61, 0.74, 0.06),
	"explosion_3": Color(0.53, 0.67, 0.19),
	"explosion_4": Color(0.61, 0.74, 0.06),
	"explosion_5": Color(0.53, 0.67, 0.19),
	"hud_threat": Color(0.61, 0.74, 0.06),
	"hud_special": Color(0.53, 0.67, 0.19),
	"hud_freeze": Color(0.53, 0.67, 0.19),
	"hud_boss": Color(0.61, 0.74, 0.06),
	"hud_combo": Color(0.61, 0.74, 0.06),
	"gem_credits": Color(0.61, 0.74, 0.06),
	"gem_crystals": Color(0.53, 0.67, 0.19),
	"gem_void": Color(0.53, 0.67, 0.19),
	"gem_eter": Color(0.61, 0.74, 0.06),
	"text_primary": Color(0.61, 0.74, 0.06),
	"text_warning": Color(0.61, 0.74, 0.06),
	"warning": Color(0.61, 0.74, 0.06),
	"target_lock": Color(0.61, 0.74, 0.06),
	"intercept_valid": Color(0.53, 0.67, 0.19),
	"intercept_invalid": Color(0.61, 0.74, 0.06),
	"building_back_fill": Color(0.06, 0.22, 0.06),
	"building_back_outline": Color(0.19, 0.38, 0.19, 0.4),
	"building_back_window": Color(0.19, 0.38, 0.19, 0.15),
	"building_front_fill": Color(0.06, 0.22, 0.06),
	"building_front_outline": Color(0.53, 0.67, 0.19, 0.6),
	"building_front_window": Color(0.53, 0.67, 0.19, 0.2),
	"mountain_back": Color(0.19, 0.38, 0.19),
	"mountain_front": Color(0.53, 0.67, 0.19),
	"grid_line": Color(0.19, 0.38, 0.19, 0.3),
	"grid_line_bright": Color(0.53, 0.67, 0.19, 0.5),
	"horizon_line": Color(0.53, 0.67, 0.19),
	"city_neon": Color(0.53, 0.67, 0.19),
	"city_fill": Color(0.06, 0.22, 0.06),
	"city_dead": Color(0.19, 0.38, 0.19, 0.3),
	"shield": Color(0.53, 0.67, 0.19),
	"battery_neon": Color(0.53, 0.67, 0.19),
	"battery_fill": Color(0.06, 0.22, 0.06),
}

const PALETTE_ASCII := {
	"glow_alpha_mult": 0.0,
	"outline_width_mult": 1.0,
	"sky_top": Color(0.0, 0.0, 0.0),
	"sky_mid": Color(0.0, 0.0, 0.0),
	"sky_horizon": Color(0.0, 0.05, 0.0),
	"floor_dark": Color(0.0, 0.0, 0.0),
	"fill_dark": Color(0.0, 0.0, 0.0),
	"fill_entity": Color(0.0, 0.0, 0.0),
	"primary": Color(0.0, 1.0, 0.0),
	"enemy_basic": Color(1.0, 0.3, 0.3),
	"enemy_fast": Color(1.0, 1.0, 0.0),
	"enemy_cluster": Color(1.0, 0.0, 1.0),
	"enemy_boss": Color(1.0, 0.0, 0.0),
	"enemy_boss_rage": Color(1.0, 0.2, 0.2),
	"explosion_0": Color(1.0, 1.0, 1.0),
	"explosion_1": Color(1.0, 0.5, 0.0),
	"explosion_2": Color(1.0, 1.0, 0.0),
	"explosion_3": Color(0.0, 1.0, 0.0),
	"explosion_4": Color(1.0, 0.0, 1.0),
	"explosion_5": Color(0.0, 1.0, 1.0),
	"hud_threat": Color(1.0, 0.3, 0.3),
	"hud_special": Color(0.0, 1.0, 0.0),
	"hud_freeze": Color(0.3, 0.6, 1.0),
	"hud_boss": Color(1.0, 0.0, 0.0),
	"hud_combo": Color(0.0, 1.0, 0.0),
	"gem_credits": Color(1.0, 0.3, 0.3),
	"gem_crystals": Color(0.0, 1.0, 0.0),
	"gem_void": Color(1.0, 0.0, 1.0),
	"gem_eter": Color(1.0, 0.5, 0.0),
	"text_primary": Color(0.0, 1.0, 0.0),
	"text_warning": Color(1.0, 0.0, 0.0),
	"warning": Color(1.0, 0.0, 0.0),
	"target_lock": Color(0.0, 1.0, 0.0),
	"intercept_valid": Color(0.0, 1.0, 0.0),
	"intercept_invalid": Color(1.0, 1.0, 0.0),
	"building_back_fill": Color(0.0, 0.0, 0.0),
	"building_back_outline": Color(0.0, 0.3, 0.0, 0.3),
	"building_back_window": Color(0.0, 0.3, 0.0, 0.1),
	"building_front_fill": Color(0.0, 0.0, 0.0),
	"building_front_outline": Color(0.0, 0.6, 0.0, 0.5),
	"building_front_window": Color(0.0, 0.6, 0.0, 0.15),
	"mountain_back": Color(0.0, 0.3, 0.0),
	"mountain_front": Color(0.0, 0.6, 0.0),
	"grid_line": Color(0.0, 0.3, 0.0, 0.2),
	"grid_line_bright": Color(0.0, 0.5, 0.0, 0.4),
	"horizon_line": Color(0.0, 0.6, 0.0),
	"city_neon": Color(0.0, 1.0, 0.0),
	"city_fill": Color(0.0, 0.0, 0.0),
	"city_dead": Color(0.0, 0.4, 0.0, 0.3),
	"shield": Color(0.0, 1.0, 0.0),
	"battery_neon": Color(0.0, 1.0, 0.0),
	"battery_fill": Color(0.0, 0.0, 0.0),
}

const PALETTES := {
	"neon": PALETTE_NEON,
	"gameboy": PALETTE_GAMEBOY,
	"ascii": PALETTE_ASCII,
}

const MODES := {
	"neon": Mode.NEON,
	"gameboy": Mode.GAMEBOY,
	"ascii": Mode.ASCII,
}

# Post-process overlay
var _post_layer: CanvasLayer
var _post_rect: ColorRect
var _gameboy_shader := preload("res://shaders/gameboy.gdshader")

func _ready() -> void:
	_setup_post_process()
	_apply_theme("neon")

func _setup_post_process() -> void:
	_post_layer = CanvasLayer.new()
	_post_layer.layer = 0  # abaixo do HUD (layer 1) para nao afetar botoes/popups
	_post_rect = ColorRect.new()
	_post_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_post_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = _gameboy_shader
	_post_rect.material = mat
	_post_layer.add_child(_post_rect)
	add_child(_post_layer)
	_post_layer.visible = false

func _apply_theme(theme_id: String) -> void:
	current_theme = theme_id
	_selected_mode = MODES.get(theme_id, Mode.NEON)
	palette = PALETTES.get(theme_id, PALETTE_NEON)
	_update_post_process()

func set_theme_id(theme_id: String) -> void:
	if theme_id == current_theme:
		return
	_apply_theme(theme_id)
	theme_changed.emit()

func _active_palette() -> Dictionary:
	return palette if in_run else PALETTE_NEON

func _active_mode() -> Mode:
	return mode if in_run else Mode.NEON

func c(key: String, alpha_override := -1.0) -> Color:
	var p := _active_palette()
	var col: Color = p.get(key, Color.MAGENTA)
	if alpha_override >= 0.0:
		col.a = alpha_override
	return col

func ui(key: String, alpha_override := -1.0) -> Color:
	var col: Color = PALETTE_NEON.get(key, Color.MAGENTA)
	if alpha_override >= 0.0:
		col.a = alpha_override
	return col

func glow(key: String, base_alpha: float) -> Color:
	var p := _active_palette()
	var col: Color = p.get(key, Color.MAGENTA)
	col.a = base_alpha * p.get("glow_alpha_mult", 1.0)
	return col

func get_glow_mult() -> float:
	return _active_palette().get("glow_alpha_mult", 1.0)

func get_outline_mult() -> float:
	return _active_palette().get("outline_width_mult", 1.0)

func get_explosion_colors() -> Array[Color]:
	var p := _active_palette()
	return [
		p.get("explosion_0", Color.WHITE),
		p.get("explosion_1", Color.WHITE),
		p.get("explosion_2", Color.WHITE),
		p.get("explosion_3", Color.WHITE),
		p.get("explosion_4", Color.WHITE),
		p.get("explosion_5", Color.WHITE),
	]

func is_unlocked(theme_id: String) -> bool:
	return unlocked_themes.get(theme_id, false)

func unlock(theme_id: String) -> void:
	unlocked_themes[theme_id] = true

func get_cost(theme_id: String) -> int:
	return THEME_COSTS.get(theme_id, 0)

func _update_post_process() -> void:
	if not is_instance_valid(_post_layer):
		return
	_post_layer.visible = in_run and (mode == Mode.GAMEBOY)

func enter_run() -> void:
	in_run = true
	_update_post_process()

func exit_run() -> void:
	in_run = false
	_update_post_process()
