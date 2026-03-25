extends Control

signal start_run
signal ascend_requested
signal purchase_made

var currency: CurrencySystem
var upgrade_system: UpgradeSystem
var credits_label: Label
var eter_mode := false

# Graph
var graph_viewport: Control
var graph_canvas: Control
var selected_key := ""
var anim_time := 0.0
var drag_start := Vector2.ZERO
var drag_distance := 0.0
var node_screen_positions: Dictionary = {}

# Eter mode (lista simples)
var scroll_container: ScrollContainer
var item_container: VBoxContainer
var header_draw: Control
var shop_currencies: Array = []
var battle_overlay: Control

# Batalha distante
var distant_battle := DistantBattle.new()
var buy_flash_key := ""
var buy_flash_time := 0.0
const BUY_FLASH_DURATION := 0.6
var _tapped_this_frame := false

const BASE_WIDTH := 1080.0
const BASE_HEIGHT := 1920.0
var ui_scale := 1.0

func _s(val: float) -> float:
	return val * ui_scale

func _sf(val: int) -> int:
	return int(val * ui_scale)

var GEM_COLORS: Dictionary:
	get: return {
		"credits": Themes.c("gem_credits"),
		"crystals": Themes.c("gem_crystals"),
		"void": Themes.c("gem_void"),
		"eter": Themes.c("gem_eter"),
	}

const NODE_RADIUS := 40.0

const CURRENCY_LABELS := {
	"credits": "CR",
	"crystals": "CS",
	"void": "VO",
	"eter": "ET",
}

# Cores baseadas nos inimigos que dropam cada moeda
var TIER_COLORS: Dictionary:
	get: return {
		1: Themes.c("gem_credits"),
		2: Themes.c("gem_crystals"),
		3: Themes.c("gem_void"),
		4: Themes.c("gem_eter"),
	}

# Estrutura da arvore — define filhos de cada no
const TREE_CHILDREN := {
	"ammo_pack": ["extra_city", "magazine", "warhead", "credit_boost"],
	# DEFESA: extra_city → early_warning → city_shield → mirror_array
	"extra_city": ["early_warning"],
	"early_warning": ["city_shield"],
	"city_shield": ["mirror_array"],
	# MUNICAO: magazine → ammo_regen → warp_reload → overcharge
	#                    → extra_battery → auto_turret
	"magazine": ["ammo_regen", "extra_battery"],
	"ammo_regen": ["warp_reload"],
	"warp_reload": ["overcharge"],
	"extra_battery": ["auto_turret"],
	# OFENSIVA: warhead → hyper_drive → homing → singularity
	#                                 → critical_mass → temporal_freeze
	"warhead": ["hyper_drive", "target_lock"],
	"target_lock": ["future_sight"],
	"hyper_drive": ["homing", "critical_mass"],
	"homing": ["singularity"],
	"critical_mass": ["temporal_freeze"],
	# ECONOMIA: credit_boost → head_start
	#                        → time_warp → triple_burst
	#                        → crystal_boost → void_boost
	"credit_boost": ["head_start", "time_warp", "crystal_boost"],
	"time_warp": ["triple_burst"],
	"crystal_boost": ["void_boost"],
}

func _ready() -> void:
	var real_size := DisplayServer.screen_get_size()
	ui_scale = clampf(minf(real_size.x / BASE_WIDTH, real_size.y / BASE_HEIGHT), 1.0, 1.5)
	credits_label = $MarginContainer/VBoxContainer/Header/CreditsLabel
	credits_label.visible = false
	graph_viewport = $MarginContainer/VBoxContainer/GraphViewport
	scroll_container = $MarginContainer/VBoxContainer/ScrollContainer
	item_container = $MarginContainer/VBoxContainer/ScrollContainer/ItemList

	header_draw = Control.new()
	header_draw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_draw.custom_minimum_size = Vector2(0, 40)
	header_draw.draw.connect(_draw_header_currencies)
	$MarginContainer/VBoxContainer/Header.add_child(header_draw)

	battle_overlay = Control.new()
	battle_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_overlay.draw.connect(_draw_distant_battle)
	$Background.add_sibling(battle_overlay)
	move_child(battle_overlay, 1)

	var play_btn := $MarginContainer/VBoxContainer/BottomButtons/PlayButton
	var ascend_btn := $MarginContainer/VBoxContainer/BottomButtons/AscendButton
	play_btn.pressed.connect(_on_play_pressed)
	ascend_btn.pressed.connect(_on_ascend_pressed)

	# Estilo neon nos botoes
	_style_neon_button(play_btn, Color(0.0, 1.0, 1.0))
	_style_neon_button(ascend_btn, Color(1.0, 0.5, 0.0))

	# Titulo neon
	var title_label := $MarginContainer/VBoxContainer/Header/TitleLabel
	title_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	title_label.add_theme_font_size_override("font_size", _sf(36))
	credits_label.add_theme_font_size_override("font_size", _sf(28))
	play_btn.add_theme_font_size_override("font_size", _sf(28))
	ascend_btn.add_theme_font_size_override("font_size", _sf(28))

	# Separador neon
	var sep := $MarginContainer/VBoxContainer/HSeparator
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(1.0, 0.0, 0.6, 0.5)
	sep_style.content_margin_top = 1
	sep_style.content_margin_bottom = 1
	sep.add_theme_stylebox_override("separator", sep_style)

	if has_meta("eter_mode"):
		eter_mode = get_meta("eter_mode")

	var tr_node = get_node("/root/Tr")
	title_label.text = tr_node.t("SHOP_TITLE")
	play_btn.text = tr_node.t("PLAY")
	ascend_btn.text = tr_node.t("ASCEND")

	if eter_mode:
		title_label.text = tr_node.t("ETER_SHOP_TITLE")
		ascend_btn.visible = false
		graph_viewport.visible = false
		scroll_container.visible = true
		_build_eter_list()
	else:
		graph_viewport.visible = true
		scroll_container.visible = false
		_setup_graph()
		_build_theme_selector()

	_update_header()

func setup(p_currency: CurrencySystem, p_upgrades: UpgradeSystem, _p_ads = null) -> void:
	currency = p_currency
	upgrade_system = p_upgrades

func _process(delta: float) -> void:
	_tapped_this_frame = false
	if not eter_mode and graph_canvas:
		anim_time += delta
		graph_canvas.queue_redraw()
	if buy_flash_time > 0.0:
		buy_flash_time -= delta
	_update_distant_battle(delta)
	if battle_overlay:
		battle_overlay.queue_redraw()

# ============================================================
# GRAPH SETUP & LAYOUT
# ============================================================

func _setup_graph() -> void:
	graph_canvas = Control.new()
	graph_canvas.draw.connect(_draw_graph)
	graph_canvas.gui_input.connect(_on_graph_input)
	graph_viewport.add_child(graph_canvas)
	# Esperar ate o viewport ter tamanho valido (evita layout quebrado)
	for attempt in 10:
		await get_tree().process_frame
		if graph_viewport.size.x > 1.0 and graph_viewport.size.y > 1.0:
			break
	var vp := graph_viewport.size
	if vp.x < 1.0 or vp.y < 1.0:
		# Fallback: usar tamanho da janela menos margens
		vp = get_viewport().get_visible_rect().size - Vector2(40, 160)
	graph_canvas.size = vp
	graph_canvas.custom_minimum_size = vp
	_calc_positions(vp)
	# Recalcular se o viewport mudar de tamanho depois
	if not graph_viewport.resized.is_connected(_on_graph_viewport_resized):
		graph_viewport.resized.connect(_on_graph_viewport_resized)

func _on_graph_viewport_resized() -> void:
	if not graph_canvas:
		return
	var vp := graph_viewport.size
	if vp.x < 1.0 or vp.y < 1.0:
		return
	graph_canvas.size = vp
	graph_canvas.custom_minimum_size = vp
	_calc_positions(vp)
	graph_canvas.queue_redraw()

func _calc_positions(vp: Vector2) -> void:
	node_screen_positions.clear()
	var max_depth := _get_max_depth("ammo_pack", 0)
	var row_gap := vp.y / float(max_depth + 2)
	var y_offset := row_gap * 0.8
	var margin_x := NODE_RADIUS + 8.0
	_layout_node("ammo_pack", margin_x, vp.x - margin_x, 0, row_gap, y_offset)
	# Centraliza os nós visíveis no viewport
	_center_visible_nodes(vp)

func _get_max_depth(key: String, depth: int) -> int:
	if not TREE_CHILDREN.has(key):
		return depth
	var max_d := depth
	for child in TREE_CHILDREN[key]:
		max_d = maxi(max_d, _get_max_depth(child, depth + 1))
	return max_d

func _count_visible_leaves(key: String) -> int:
	if not TREE_CHILDREN.has(key):
		# Folha: conta 1 se visivel
		return 1 if (key == "ammo_pack" or _is_visible(key)) else 0
	var total := 0
	for child in TREE_CHILDREN[key]:
		total += _count_visible_leaves(child)
	# Se nenhum filho visivel mas EU sou visivel, conto como 1
	if total == 0 and (key == "ammo_pack" or _is_visible(key)):
		return 1
	return total

func _count_leaves(key: String) -> int:
	if not TREE_CHILDREN.has(key):
		return 1
	var total := 0
	for child in TREE_CHILDREN[key]:
		total += _count_leaves(child)
	return total

func _layout_node(key: String, x_start: float, x_end: float, depth: int, y_gap: float, y_offset: float) -> void:
	var x_center := (x_start + x_end) / 2.0
	node_screen_positions[key] = Vector2(x_center, y_offset + depth * y_gap)
	if not TREE_CHILDREN.has(key):
		return
	var children: Array = TREE_CHILDREN[key]
	# Só distribui espaço pra filhos com nós visíveis
	var visible_children: Array = []
	for child in children:
		if _count_visible_leaves(child) > 0:
			visible_children.append(child)
	if visible_children.is_empty():
		return
	var total_leaves := 0
	for child in visible_children:
		total_leaves += _count_visible_leaves(child)
	var current_x := x_start
	for child in visible_children:
		var child_leaves := _count_visible_leaves(child)
		var child_width := (x_end - x_start) * float(child_leaves) / float(total_leaves)
		_layout_node(child, current_x, current_x + child_width, depth + 1, y_gap, y_offset)
		current_x += child_width

func _center_visible_nodes(vp: Vector2) -> void:
	# Coleta posições dos nós visíveis
	var visible_positions: Array[Vector2] = []
	for key in node_screen_positions:
		if key == "ammo_pack" or _is_visible(key):
			visible_positions.append(node_screen_positions[key])
	if visible_positions.is_empty():
		return
	# Bounding box dos nós visíveis
	var min_x := visible_positions[0].x
	var max_x := visible_positions[0].x
	var min_y := visible_positions[0].y
	var max_y := visible_positions[0].y
	for pos in visible_positions:
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
		min_y = minf(min_y, pos.y)
		max_y = maxf(max_y, pos.y)
	# Offset pra centralizar no viewport
	var center_x := (min_x + max_x) / 2.0
	var center_y := (min_y + max_y) / 2.0
	var offset := Vector2(vp.x / 2.0 - center_x, vp.y / 2.0 - center_y)
	# Aplica offset em TODOS os nós (visíveis e invisíveis)
	for key in node_screen_positions:
		node_screen_positions[key] += offset

# ============================================================
# INPUT (TAP)
# ============================================================

func _on_graph_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_start = event.position
			drag_distance = 0.0
		else:
			if drag_distance < 12.0 and not _tapped_this_frame:
				_tapped_this_frame = true
				_handle_tap(event.position)
	elif event is InputEventScreenDrag:
		drag_distance = maxf(drag_distance, (event.position - drag_start).length())
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start = event.position
				drag_distance = 0.0
			else:
				if drag_distance < 12.0 and not _tapped_this_frame:
					_tapped_this_frame = true
					_handle_tap(event.position)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		drag_distance = maxf(drag_distance, (event.position - drag_start).length())

func _is_visible(key: String) -> bool:
	if not upgrade_system.can_unlock(key):
		return false
	var cur_type: String = upgrade_system.upgrades[key]["currency"]
	return currency.is_unlocked(cur_type)

func _handle_tap(pos: Vector2) -> void:
	if not upgrade_system:
		return
	for key in node_screen_positions:
		if not upgrade_system.upgrades.has(key):
			continue
		if not _is_visible(key):
			continue
		var node_center: Vector2 = node_screen_positions[key]
		if pos.distance_to(node_center) <= NODE_RADIUS + 6:
			_on_node_tapped(key)
			return
	selected_key = ""

func _on_node_tapped(key: String) -> void:
	if selected_key == key:
		_try_buy(key)
	else:
		selected_key = key
		get_node("/root/SoundManager").ui_click()

func _try_buy(key: String) -> void:
	if upgrade_system.buy(key, currency):
		get_node("/root/SoundManager").purchase()
		buy_flash_key = key
		buy_flash_time = BUY_FLASH_DURATION
		purchase_made.emit()
		_update_header()
		# Recalcula posições pra mostrar novos nós desbloqueados
		if graph_canvas:
			_calc_positions(graph_viewport.size)

# ============================================================
# GRAPH DRAWING
# ============================================================

func _draw_graph() -> void:
	if not upgrade_system or not currency:
		return

	# Edges
	for key in node_screen_positions:
		if not upgrade_system.upgrades.has(key):
			continue
		if not _is_visible(key):
			continue
		var u = upgrade_system.upgrades[key]
		var req: String = u["requires"]
		if req == "" or not node_screen_positions.has(req):
			continue
		var from_pos: Vector2 = node_screen_positions[req]
		var to_pos: Vector2 = node_screen_positions[key]
		var tc: Color = TIER_COLORS[u["tier"]]
		var edge_col := Color(tc.r * 0.5, tc.g * 0.5, tc.b * 0.5, 0.5)
		_draw_tree_line(from_pos, to_pos, edge_col)

	# Nodes
	for key in node_screen_positions:
		if not upgrade_system.upgrades.has(key):
			continue
		if not _is_visible(key):
			continue
		_draw_node(key)

	# Popup
	if selected_key != "" and upgrade_system.upgrades.has(selected_key) and _is_visible(selected_key):
		_draw_popup(selected_key)

func _draw_tree_line(from_pos: Vector2, to_pos: Vector2, col: Color) -> void:
	var mid_y := (from_pos.y + to_pos.y) / 2.0
	graph_canvas.draw_line(from_pos, Vector2(from_pos.x, mid_y), col, 2.5, true)
	graph_canvas.draw_line(Vector2(from_pos.x, mid_y), Vector2(to_pos.x, mid_y), col, 2.5, true)
	graph_canvas.draw_line(Vector2(to_pos.x, mid_y), to_pos, col, 2.5, true)

func _draw_node(key: String) -> void:
	var u = upgrade_system.upgrades[key]
	var center: Vector2 = node_screen_positions[key]
	var tier: int = u["tier"]
	var level: int = u["level"]
	var max_level: int = u["max_level"]
	var is_maxed := level >= max_level
	var is_bought := level > 0
	var is_selected := key == selected_key

	var tier_col: Color = TIER_COLORS[tier]
	var r := NODE_RADIUS

	var fill_col: Color
	if is_maxed:
		fill_col = Color(tier_col.r * 0.9, tier_col.g * 0.9, tier_col.b * 0.3, 1.0)
	elif is_bought:
		fill_col = tier_col
		fill_col.a = 0.9
	else:
		fill_col = Color(tier_col.r * 0.5, tier_col.g * 0.5, tier_col.b * 0.5, 0.7)

	# Flash de compra
	var is_flashing := key == buy_flash_key and buy_flash_time > 0.0
	if is_flashing:
		var flash_t := buy_flash_time / BUY_FLASH_DURATION
		var flash_r := r + 20.0 * (1.0 - flash_t)
		var flash_alpha := flash_t * 0.6
		graph_canvas.draw_circle(center, flash_r, Color(1.0, 1.0, 1.0, flash_alpha * 0.3))
		graph_canvas.draw_arc(center, flash_r, 0, TAU, 24, Color(tier_col.r, tier_col.g, tier_col.b, flash_alpha), 3.0, true)

	if is_selected:
		graph_canvas.draw_circle(center, r + 8, Color(1.0, 1.0, 1.0, 0.25))

	graph_canvas.draw_circle(center + Vector2(2, 2), r, Color(0.0, 0.0, 0.0, 0.3))
	graph_canvas.draw_circle(center, r, fill_col)
	graph_canvas.draw_arc(center, r, 0, TAU, 32, Color(fill_col.r * 0.6, fill_col.g * 0.6, fill_col.b * 0.6, 0.8), 2.5, true)

	var icon_col := Color(0.95, 0.92, 0.85)
	if not is_bought:
		icon_col = Color(0.85, 0.82, 0.75, 0.8)
	_draw_icon(key, center, icon_col)

	if is_bought and not is_maxed:
		var badge_pos := center + Vector2(r * 0.6, r * 0.6)
		graph_canvas.draw_circle(badge_pos, 20.0, Color(0.1, 0.1, 0.15, 0.9))
		var font := ThemeDB.fallback_font
		graph_canvas.draw_string(font, badge_pos + Vector2(-16, 12), "%d" % level, HORIZONTAL_ALIGNMENT_CENTER, 32, 32, Color.WHITE)

	if is_maxed:
		var font := ThemeDB.fallback_font
		graph_canvas.draw_string(font, center + Vector2(-40, r + 24), get_node("/root/Tr").t("MAX"), HORIZONTAL_ALIGNMENT_CENTER, 80, 28, Color(1.0, 0.85, 0.0))

# ============================================================
# ICONES PROCEDURAIS (escala 1.5x)
# ============================================================

func _draw_icon(key: String, center: Vector2, col: Color) -> void:
	var c := graph_canvas
	var w := 3.0
	var s := 1.5

	match key:
		"extra_city":
			c.draw_rect(Rect2(center + Vector2(-10, -5) * s, Vector2(7, 18) * s), col, true)
			c.draw_rect(Rect2(center + Vector2(-2, -13) * s, Vector2(7, 26) * s), col, true)
			c.draw_rect(Rect2(center + Vector2(5, -3) * s, Vector2(7, 16) * s), col, true)
		"ammo_pack":
			for i in 3:
				var y := center.y + (-10 + i * 10) * s - 3 * s
				c.draw_rect(Rect2(center.x - 9 * s, y, 18 * s, 6 * s), col, true)
		"magazine":
			for i in 3:
				c.draw_circle(center + Vector2((-10 + i * 10) * s, 0), 5.0 * s, col)
		"ammo_regen":
			c.draw_arc(center, 13.0 * s, -PI * 0.3, PI * 1.3, 16, col, w, true)
			var tip := center + Vector2(cos(-PI * 0.3), sin(-PI * 0.3)) * 13 * s
			c.draw_line(tip, tip + Vector2(-6, 0) * s, col, w, true)
			c.draw_line(tip, tip + Vector2(0, 6) * s, col, w, true)
		"hyper_drive":
			c.draw_line(center + Vector2(0, 13) * s, center + Vector2(0, -13) * s, col, 3.5, true)
			c.draw_line(center + Vector2(0, -13) * s, center + Vector2(-7, -4) * s, col, w, true)
			c.draw_line(center + Vector2(0, -13) * s, center + Vector2(7, -4) * s, col, w, true)
			c.draw_line(center + Vector2(-9, 6) * s, center + Vector2(-9, 13) * s, col, 2.5, true)
			c.draw_line(center + Vector2(9, 6) * s, center + Vector2(9, 13) * s, col, 2.5, true)
		"warhead":
			for i in 8:
				var a := float(i) / 8.0 * TAU
				var r := (13.0 if i % 2 == 0 else 8.0) * s
				c.draw_line(center, center + Vector2(cos(a), sin(a)) * r, col, w, true)
		"head_start":
			c.draw_line(center + Vector2(-8, 0) * s, center + Vector2(8, 0) * s, col, 3.5, true)
			c.draw_line(center + Vector2(0, -8) * s, center + Vector2(0, 8) * s, col, 3.5, true)
			c.draw_arc(center, 13.0 * s, 0, TAU, 16, col, 2.5, true)
		"credit_boost":
			c.draw_line(center + Vector2(0, 10) * s, center + Vector2(0, -10) * s, col, 3.5, true)
			c.draw_line(center + Vector2(0, -10) * s, center + Vector2(-6, -4) * s, col, w, true)
			c.draw_line(center + Vector2(0, -10) * s, center + Vector2(6, -4) * s, col, w, true)
		"time_warp":
			c.draw_arc(center, 13.0 * s, 0, TAU, 16, col, 2.5, true)
			c.draw_line(center, center + Vector2(0, -9) * s, col, w, true)
			c.draw_line(center, center + Vector2(7, 3) * s, col, w, true)
		"early_warning":
			var pts: PackedVector2Array = []
			for i in 13:
				var t := float(i) / 12.0
				pts.append(center + Vector2(lerpf(-13, 13, t), -sin(t * PI) * 8) * s)
			for i in pts.size() - 1:
				c.draw_line(pts[i], pts[i + 1], col, w, true)
			var pts2: PackedVector2Array = []
			for i in 13:
				var t := float(i) / 12.0
				pts2.append(center + Vector2(lerpf(-13, 13, t), sin(t * PI) * 8) * s)
			for i in pts2.size() - 1:
				c.draw_line(pts2[i], pts2[i + 1], col, w, true)
			c.draw_circle(center, 4.5 * s, col)
		"extra_battery":
			c.draw_rect(Rect2(center + Vector2(-9, -6) * s, Vector2(18, 20) * s), col, false, 2.5)
			c.draw_rect(Rect2(center + Vector2(-5, -12) * s, Vector2(10, 6) * s), col, true)
		"city_shield":
			c.draw_arc(center + Vector2(0, 4) * s, 13.0 * s, PI, TAU, 12, col, 3.0, true)
			c.draw_line(center + Vector2(-13, 4) * s, center + Vector2(-13, 10) * s, col, 3.0, true)
			c.draw_line(center + Vector2(13, 4) * s, center + Vector2(13, 10) * s, col, 3.0, true)
		"warp_reload":
			c.draw_arc(center, 12.0 * s, -0.3, PI - 0.3, 10, col, w, true)
			c.draw_arc(center, 12.0 * s, PI - 0.3, TAU - 0.3, 10, col, w, true)
			var t1 := center + Vector2(cos(-0.3), sin(-0.3)) * 12 * s
			c.draw_line(t1, t1 + Vector2(-5, -4) * s, col, w, true)
			var t2 := center + Vector2(cos(PI - 0.3), sin(PI - 0.3)) * 12 * s
			c.draw_line(t2, t2 + Vector2(5, 4) * s, col, w, true)
		"overcharge":
			c.draw_line(center + Vector2(-4, -15) * s, center + Vector2(4, -4) * s, col, 3.5, true)
			c.draw_line(center + Vector2(4, -4) * s, center + Vector2(-4, -4) * s, col, 3.5, true)
			c.draw_line(center + Vector2(-4, -4) * s, center + Vector2(4, 15) * s, col, 3.5, true)
		"critical_mass":
			c.draw_circle(center, 8.0 * s, Color(col.r, col.g, col.b, col.a * 0.4))
			c.draw_arc(center, 13.0 * s, 0, TAU, 16, col, 2.5, true)
			c.draw_arc(center, 8.0 * s, 0, TAU, 12, col, 2.5, true)
		"crystal_boost":
			var d := PackedVector2Array([
				center + Vector2(0, -15) * s, center + Vector2(10, 0) * s,
				center + Vector2(0, 15) * s, center + Vector2(-10, 0) * s,
			])
			c.draw_polyline(d, col, w, true)
			c.draw_line(d[3], d[0], col, w, true)
		"homing":
			c.draw_arc(center, 13.0 * s, 0, TAU, 16, col, 2.5, true)
			c.draw_arc(center, 7.0 * s, 0, TAU, 12, col, 2.5, true)
			c.draw_circle(center, 2.5 * s, col)
		"triple_burst":
			for i in 3:
				var offset := Vector2((-10 + i * 10) * s, 0)
				c.draw_line(center + offset + Vector2(0, 9) * s, center + offset + Vector2(0, -9) * s, col, 2.5, true)
				c.draw_line(center + offset + Vector2(0, -9) * s, center + offset + Vector2(-4, -3) * s, col, 2.5, true)
				c.draw_line(center + offset + Vector2(0, -9) * s, center + offset + Vector2(4, -3) * s, col, 2.5, true)
		"temporal_freeze":
			for i in 6:
				var a := float(i) / 6.0 * TAU
				c.draw_line(center, center + Vector2(cos(a), sin(a)) * 13 * s, col, 2.5, true)
				var mid := center + Vector2(cos(a), sin(a)) * 8 * s
				var perp := Vector2(-sin(a), cos(a)) * 5 * s
				c.draw_line(mid - perp, mid + perp, col, 2.0, true)
		"phoenix_protocol":
			c.draw_line(center + Vector2(0, 8) * s, center + Vector2(0, -4) * s, col, w, true)
			c.draw_line(center + Vector2(0, -4) * s, center + Vector2(-12, -13) * s, col, w, true)
			c.draw_line(center + Vector2(0, -4) * s, center + Vector2(12, -13) * s, col, w, true)
			c.draw_line(center + Vector2(-12, -13) * s, center + Vector2(-7, -7) * s, col, 2.5, true)
			c.draw_line(center + Vector2(12, -13) * s, center + Vector2(7, -7) * s, col, 2.5, true)
		"singularity":
			c.draw_circle(center, 5.0 * s, col)
			for i in 4:
				var a := float(i) / 4.0 * TAU + 0.4
				var from := center + Vector2(cos(a), sin(a)) * 15 * s
				var to := center + Vector2(cos(a), sin(a)) * 8 * s
				c.draw_line(from, to, col, 2.5, true)
				c.draw_line(to, to + Vector2(cos(a + 0.5), sin(a + 0.5)) * 4 * s, col, 2.0, true)
				c.draw_line(to, to + Vector2(cos(a - 0.5), sin(a - 0.5)) * 4 * s, col, 2.0, true)
		"auto_turret":
			c.draw_rect(Rect2(center + Vector2(-7, 3) * s, Vector2(14, 10) * s), col, true)
			c.draw_line(center + Vector2(0, 3) * s, center + Vector2(0, -10) * s, col, 3.5, true)
			c.draw_circle(center + Vector2(0, -10) * s, 4.0 * s, col)
		"mirror_array":
			c.draw_line(center + Vector2(0, -13) * s, center + Vector2(0, 13) * s, col, 3.0, true)
			c.draw_line(center + Vector2(-13, -7) * s, center + Vector2(-1, 0) * s, col, 2.5, true)
			c.draw_line(center + Vector2(1, 0) * s, center + Vector2(13, -7) * s, col, 2.5, true)
			c.draw_line(center + Vector2(-13, -7) * s, center + Vector2(-9, -10) * s, col, 2.5, true)
			c.draw_line(center + Vector2(13, -7) * s, center + Vector2(9, -10) * s, col, 2.5, true)
		"void_boost":
			c.draw_arc(center, 13.0 * s, 0, TAU, 16, col, 2.5, true)
			c.draw_line(center + Vector2(-7, -7) * s, center + Vector2(0, 9) * s, col, 3.0, true)
			c.draw_line(center + Vector2(7, -7) * s, center + Vector2(0, 9) * s, col, 3.0, true)
		"target_lock":
			# Mira — circulo + cruz
			c.draw_arc(center, 12.0 * s, 0, TAU, 16, col, 2.5, true)
			c.draw_line(center + Vector2(0, -15) * s, center + Vector2(0, 15) * s, col, 2.0, true)
			c.draw_line(center + Vector2(-15, 0) * s, center + Vector2(15, 0) * s, col, 2.0, true)
			c.draw_circle(center, 3.0 * s, col)
		"future_sight":
			# Olho — elipse + pupila + raios de previsao
			c.draw_arc(center, 13.0 * s, -0.5, 0.5, 8, col, 2.5, true)
			c.draw_arc(center, 13.0 * s, PI - 0.5, PI + 0.5, 8, col, 2.5, true)
			# Palpebras (arcos superior e inferior)
			var eye_pts_top: PackedVector2Array = []
			var eye_pts_bot: PackedVector2Array = []
			for i in 9:
				var t := float(i) / 8.0
				var x := lerpf(-13, 13, t) * s
				var curve := sin(t * PI) * 9.0 * s
				eye_pts_top.append(center + Vector2(x, -curve))
				eye_pts_bot.append(center + Vector2(x, curve))
			for i in eye_pts_top.size() - 1:
				c.draw_line(eye_pts_top[i], eye_pts_top[i + 1], col, 2.5, true)
				c.draw_line(eye_pts_bot[i], eye_pts_bot[i + 1], col, 2.5, true)
			# Iris + pupila
			c.draw_arc(center, 6.0 * s, 0, TAU, 12, col, 2.0, true)
			c.draw_circle(center, 3.0 * s, col)
		_:
			c.draw_circle(center, 8.0 * s, col)

# ============================================================
# POPUP
# ============================================================

func _draw_popup(key: String) -> void:
	var u = upgrade_system.upgrades[key]
	var tier: int = u["tier"]
	var level: int = u["level"]
	var max_level: int = u["max_level"]
	var is_maxed := level >= max_level
	var tier_col: Color = TIER_COLORS[tier]

	var node_center: Vector2 = node_screen_positions[key]
	var popup_w := 380.0
	var popup_h := 170.0
	var popup_pos := Vector2(node_center.x - popup_w / 2.0, node_center.y + NODE_RADIUS + 14)

	if popup_pos.y + popup_h > graph_canvas.size.y - 10:
		popup_pos.y = node_center.y - NODE_RADIUS - popup_h - 14

	popup_pos.x = clampf(popup_pos.x, 4.0, graph_canvas.size.x - popup_w - 4.0)

	var popup_rect := Rect2(popup_pos, Vector2(popup_w, popup_h))
	graph_canvas.draw_rect(popup_rect, Color(0.05, 0.06, 0.12, 0.95), true)
	graph_canvas.draw_rect(popup_rect, Color(tier_col.r, tier_col.g, tier_col.b, 0.6), false, 2.0)

	var tr_node = get_node("/root/Tr")
	var font := ThemeDB.fallback_font
	var tx: float = popup_pos.x + 16
	var ty: float = popup_pos.y + 32

	var name_text: String = tr_node.t("UPG_NAME_" + key)
	graph_canvas.draw_string(font, Vector2(tx, ty), name_text, HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 28, tier_col)

	var desc: String = tr_node.t("UPG_DESC_" + key)
	graph_canvas.draw_string(font, Vector2(tx, ty + 34), desc, HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 22, Color(0.7, 0.7, 0.7))

	var level_str: String = tr_node.t("LV_FMT") % [level, max_level] if not is_maxed else tr_node.t("MAX")
	graph_canvas.draw_string(font, Vector2(tx, ty + 66), level_str, HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 22, Color(0.9, 0.9, 0.9))

	if is_maxed:
		graph_canvas.draw_string(font, Vector2(tx, ty + 98), tr_node.t("COMPLETE"), HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 22, Color(1.0, 0.85, 0.0))
	else:
		var cost: int = upgrade_system.get_cost(key)
		var cur_type: String = u["currency"]
		var can_afford: bool = currency.get_amount(cur_type) >= cost
		var cost_col := Color(0.3, 1.0, 0.5) if can_afford else Color(1.0, 0.3, 0.3)
		var cost_text: String = tr_node.t("COST_FMT") % cost
		graph_canvas.draw_string(font, Vector2(tx, ty + 98), cost_text, HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 20, cost_col)
		var cost_text_w := font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		_draw_gem_on(graph_canvas, Vector2(tx + cost_text_w + 14, ty + 88), GEM_COLORS[cur_type])
		graph_canvas.draw_string(font, Vector2(tx + cost_text_w + 30, ty + 98), tr_node.t("TAP_TO_BUY"), HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 20, cost_col)

# ============================================================
# ETER MODE (lista simples)
# ============================================================

func _build_eter_list() -> void:
	if not item_container or not currency or not upgrade_system:
		return
	for child in item_container.get_children():
		child.queue_free()
	for key in upgrade_system.upgrades:
		var u = upgrade_system.upgrades[key]
		if u["tier"] == 4:
			if key == "omega_protocol" and not upgrade_system.boss_cleared:
				continue
			var item = _create_list_item(key, u)
			item_container.add_child(item)
	# Secao de temas
	_build_theme_section()
	_update_header()

func _build_theme_section() -> void:
	var tr_node = get_node("/root/Tr")
	var eter_col := Themes.c("gem_eter")
	# Separador
	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 20
	item_container.add_child(sep)
	# Titulo da secao
	var section_label = Label.new()
	section_label.text = tr_node.t("THEMES_SECTION")
	section_label.add_theme_font_size_override("font_size", _sf(28))
	section_label.add_theme_color_override("font_color", eter_col)
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_container.add_child(section_label)
	# Temas
	for theme_id in ["neon", "gameboy", "ascii"]:
		var item = _create_theme_item(theme_id)
		item_container.add_child(item)

func _create_theme_item(theme_id: String) -> PanelContainer:
	var tr_node = get_node("/root/Tr")
	var eter_col := Themes.c("gem_eter")
	var is_current: bool = Themes.current_theme == theme_id
	var is_unlocked: bool = Themes.is_unlocked(theme_id)
	var cost := Themes.get_cost(theme_id)

	var panel = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	if is_current:
		panel_style.bg_color = Color(eter_col.r * 0.15, eter_col.g * 0.15, eter_col.b * 0.15, 0.8)
		panel_style.border_color = eter_col
	else:
		panel_style.bg_color = Color(0.05, 0.03, 0.01, 0.7)
		panel_style.border_color = Color(eter_col.r * 0.5, eter_col.g * 0.5, eter_col.b * 0.5, 0.5)
	panel_style.set_border_width_all(2 if is_current else 1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)

	var row = HBoxContainer.new()
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label = Label.new()
	name_label.text = tr_node.t("THEME_" + theme_id)
	name_label.add_theme_font_size_override("font_size", _sf(24))
	name_label.add_theme_color_override("font_color", eter_col if is_unlocked else Color(0.5, 0.5, 0.5))
	info.add_child(name_label)
	var desc_label = Label.new()
	desc_label.text = tr_node.t("THEME_DESC_" + theme_id)
	desc_label.add_theme_font_size_override("font_size", _sf(18))
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7) if is_unlocked else Color(0.4, 0.4, 0.4))
	info.add_child(desc_label)
	row.add_child(info)

	var btn = Button.new()
	btn.add_theme_font_size_override("font_size", _sf(22))
	btn.custom_minimum_size = Vector2(140, 50)

	if is_current:
		btn.text = tr_node.t("EQUIPPED")
		btn.disabled = true
		_style_neon_button(btn, eter_col)
	elif is_unlocked:
		btn.text = tr_node.t("EQUIP")
		btn.pressed.connect(_on_theme_equip.bind(theme_id))
		_style_neon_button(btn, eter_col)
	elif cost > 0:
		# Botao de compra com custo + icone gem
		btn.pressed.connect(_on_theme_buy.bind(theme_id))
		_style_neon_button(btn, eter_col)
		var btn_content = HBoxContainer.new()
		btn_content.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_content.add_theme_constant_override("separation", 4)
		btn_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_content.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		btn_content.grow_horizontal = Control.GROW_DIRECTION_BOTH
		btn_content.grow_vertical = Control.GROW_DIRECTION_BOTH
		btn.add_child(btn_content)
		var cost_lbl = Label.new()
		cost_lbl.text = "%d" % cost
		cost_lbl.add_theme_font_size_override("font_size", _sf(22))
		cost_lbl.add_theme_color_override("font_color", eter_col)
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_content.add_child(cost_lbl)
		var gem_icon = Control.new()
		gem_icon.custom_minimum_size = Vector2(18, 22)
		gem_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gem_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gem_icon.draw.connect(_draw_gem_on.bind(gem_icon, Vector2(9, 11), eter_col))
		btn_content.add_child(gem_icon)
		btn.disabled = currency.get_amount("eter") < cost
	else:
		btn.text = tr_node.t("EQUIP")
		btn.pressed.connect(_on_theme_equip.bind(theme_id))
		_style_neon_button(btn, eter_col)

	row.add_child(btn)
	panel.add_child(row)
	return panel

func _on_theme_buy(theme_id: String) -> void:
	var cost := Themes.get_cost(theme_id)
	if currency.get_amount("eter") < cost:
		return
	currency.spend("eter", cost)
	Themes.unlock(theme_id)
	Themes.set_theme_id(theme_id)
	get_node("/root/SoundManager").purchase()
	_build_eter_list()
	purchase_made.emit()

func _on_theme_equip(theme_id: String) -> void:
	Themes.set_theme_id(theme_id)
	if eter_mode:
		_build_eter_list()
	else:
		_rebuild_theme_selector()

# --- Seletor de tema na lateral esquerda (shop normal) ---

var _theme_buttons: VBoxContainer

func _build_theme_selector() -> void:
	_theme_buttons = VBoxContainer.new()
	_theme_buttons.add_theme_constant_override("separation", _sf(8))
	_theme_buttons.offset_left = _s(10.0)
	_theme_buttons.offset_top = _s(400.0)
	_theme_buttons.offset_right = _s(80.0)
	_theme_buttons.offset_bottom = _s(900.0)
	add_child(_theme_buttons)
	_populate_theme_buttons()

func _rebuild_theme_selector() -> void:
	if not _theme_buttons:
		return
	_populate_theme_buttons()

func _populate_theme_buttons() -> void:
	for child in _theme_buttons.get_children():
		child.queue_free()
	var tr_node = get_node("/root/Tr")
	for theme_id in ["neon", "gameboy", "ascii"]:
		if not Themes.is_unlocked(theme_id):
			continue
		var is_current: bool = Themes.current_theme == theme_id
		var btn := Button.new()
		btn.text = tr_node.t("THEME_" + theme_id)
		btn.add_theme_font_size_override("font_size", _sf(16))
		btn.custom_minimum_size = Vector2(_s(70), _s(50))
		var col := Themes.c("primary") if is_current else Color(0.5, 0.5, 0.5)
		_style_neon_button(btn, col)
		if is_current:
			btn.disabled = true
		else:
			btn.pressed.connect(_on_theme_equip.bind(theme_id))
		_theme_buttons.add_child(btn)

func _create_list_item(key: String, u: Dictionary) -> PanelContainer:
	var tr_node = get_node("/root/Tr")
	var eter_col := Color(1.0, 0.5, 0.0)
	var panel = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.03, 0.01, 0.7)
	panel_style.border_color = Color(eter_col.r * 0.5, eter_col.g * 0.5, eter_col.b * 0.5, 0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)

	var row = HBoxContainer.new()
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label = Label.new()
	name_label.text = "%s (%s)" % [tr_node.t("UPG_NAME_" + key), tr_node.t("LV_FMT") % [u["level"], u["max_level"]]]
	name_label.add_theme_font_size_override("font_size", _sf(24))
	name_label.add_theme_color_override("font_color", eter_col)
	info.add_child(name_label)
	var desc_label = Label.new()
	desc_label.text = tr_node.t("UPG_DESC_" + key)
	desc_label.add_theme_font_size_override("font_size", _sf(18))
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(desc_label)
	row.add_child(info)
	var cur_type = u["currency"]
	var gem_col: Color = GEM_COLORS.get(cur_type, eter_col)
	var buy_button = Button.new()
	buy_button.add_theme_font_size_override("font_size", _sf(22))
	buy_button.pressed.connect(_on_eter_buy.bind(key))
	buy_button.custom_minimum_size = Vector2(120, 50)
	_style_neon_button(buy_button, eter_col)
	var btn_content = HBoxContainer.new()
	btn_content.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_content.add_theme_constant_override("separation", 4)
	btn_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_content.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	btn_content.grow_horizontal = Control.GROW_DIRECTION_BOTH
	btn_content.grow_vertical = Control.GROW_DIRECTION_BOTH
	buy_button.add_child(btn_content)
	if u["level"] >= u["max_level"]:
		var max_lbl = Label.new()
		max_lbl.text = tr_node.t("MAX")
		max_lbl.add_theme_font_size_override("font_size", _sf(22))
		max_lbl.add_theme_color_override("font_color", eter_col)
		max_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_content.add_child(max_lbl)
		buy_button.disabled = true
	else:
		var cost = upgrade_system.get_cost(key)
		var cost_lbl = Label.new()
		cost_lbl.text = "%d" % cost
		cost_lbl.add_theme_font_size_override("font_size", _sf(22))
		cost_lbl.add_theme_color_override("font_color", eter_col)
		cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn_content.add_child(cost_lbl)
		var gem_icon = Control.new()
		gem_icon.custom_minimum_size = Vector2(18, 22)
		gem_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gem_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gem_icon.draw.connect(_draw_gem_on.bind(gem_icon, Vector2(9, 11), gem_col))
		btn_content.add_child(gem_icon)
		buy_button.disabled = currency.get_amount(cur_type) < cost
	row.add_child(buy_button)
	panel.add_child(row)
	return panel

func _on_eter_buy(key: String) -> void:
	if upgrade_system.buy(key, currency):
		get_node("/root/SoundManager").purchase()
		_build_eter_list()
		purchase_made.emit()

# ============================================================
# HEADER & SIGNALS
# ============================================================

func _update_header() -> void:
	if not currency:
		return
	shop_currencies.clear()
	for cur_type in ["eter", "void", "crystals", "credits"]:
		var amount = currency.get_amount(cur_type)
		if amount > 0 and currency.is_unlocked(cur_type):
			shop_currencies.append({"type": cur_type, "amount": amount})
	if header_draw:
		header_draw.queue_redraw()

func _draw_header_currencies() -> void:
	var font := ThemeDB.fallback_font
	var draw_w := header_draw.size.x
	var entries := shop_currencies.duplicate()
	entries.reverse()
	var x := draw_w
	for entry in entries:
		var text := "%d" % entry["amount"]
		var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		x -= text_w
		header_draw.draw_string(font, Vector2(x, 30), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		x -= 24
		_draw_gem_on(header_draw, Vector2(x + 8, 20), GEM_COLORS[entry["type"]])
		x -= 20

func _draw_gem_on(c: Control, center: Vector2, col: Color) -> void:
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

func _style_neon_button(btn: Button, col: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(col.r * 0.1, col.g * 0.1, col.b * 0.1, 0.8)
	normal.border_color = col
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(col.r * 0.2, col.g * 0.2, col.b * 0.2, 0.9)
	hover.border_color = Color(col.r, col.g, col.b, 1.0)
	hover.set_border_width_all(3)
	hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(col.r * 0.3, col.g * 0.3, col.b * 0.3, 1.0)
	pressed.border_color = Color(minf(col.r * 1.3, 1.0), minf(col.g * 1.3, 1.0), minf(col.b * 1.3, 1.0))
	pressed.set_border_width_all(3)
	pressed.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed)
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.05, 0.05, 0.08, 0.6)
	disabled.border_color = Color(0.3, 0.3, 0.3, 0.4)
	disabled.set_border_width_all(1)
	disabled.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", Color(minf(col.r * 1.3, 1.0), minf(col.g * 1.3, 1.0), minf(col.b * 1.3, 1.0)))
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))

func _on_ascend_pressed() -> void:
	ascend_requested.emit()

func _on_play_pressed() -> void:
	start_run.emit()

# ============================================================
# BATALHA DISTANTE (background)
# ============================================================

func _update_distant_battle(delta: float) -> void:
	var scr := get_viewport().get_visible_rect().size
	distant_battle.update(delta, scr, scr.y * 0.55)

func _draw_distant_battle() -> void:
	distant_battle.draw(battle_overlay)
