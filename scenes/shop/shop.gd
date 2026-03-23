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

const GEM_COLORS := {
	"credits": Color(1.0, 0.0, 0.6),
	"crystals": Color(0.2, 1.0, 0.1),
	"void": Color(0.7, 0.0, 1.0),
	"eter": Color(1.0, 0.5, 0.0),
}

const NODE_RADIUS := 40.0

const CURRENCY_LABELS := {
	"credits": "CR",
	"crystals": "CS",
	"void": "VO",
	"eter": "ET",
}

# Cores baseadas nos inimigos que dropam cada moeda
const TIER_COLORS := {
	1: Color(1.0, 0.0, 0.6),   # credits — basic enemy (hot pink)
	2: Color(0.2, 1.0, 0.1),   # crystals — fast enemy (neon green)
	3: Color(0.7, 0.0, 1.0),   # void — cluster enemy (purple)
	4: Color(1.0, 0.5, 0.0),   # eter — ascension (orange)
}

const UPGRADE_NAMES := {
	"extra_city": "EXTRA CITY",
	"ammo_pack": "AMMO PACK",
	"magazine": "MAGAZINE+",
	"ammo_regen": "AMMO REGEN",
	"hyper_drive": "HYPER DRIVE",
	"warhead": "WARHEAD+",
	"head_start": "HEAD START",
	"credit_boost": "CREDIT BOOST",
	"time_warp": "TIME WARP",
	"early_warning": "EARLY WARNING",
	"extra_battery": "EXTRA BATTERY",
	"city_shield": "CITY SHIELD",
	"warp_reload": "WARP RELOAD",
	"overcharge": "OVERCHARGE",
	"critical_mass": "CRITICAL MASS",
	"crystal_boost": "CRYSTAL BOOST",
	"homing": "HOMING",
	"triple_burst": "TRIPLE BURST",
	"temporal_freeze": "TEMPORAL FREEZE",
	"phoenix_protocol": "PHOENIX PROTOCOL",
	"singularity": "SINGULARITY",
	"auto_turret": "AUTO TURRET",
	"mirror_array": "MIRROR ARRAY",
	"void_boost": "VOID BOOST",
	"ascendant_core": "ASCENDANT CORE",
	"eternal_knowledge": "ETERNAL KNOWLEDGE",
	"vault": "VAULT",
	"omega_protocol": "OMEGA PROTOCOL",
}

const UPGRADE_DESCRIPTIONS := {
	"extra_city": "+1 cidade",
	"ammo_pack": "+1 pente por bateria",
	"magazine": "+1 tiro por pente",
	"ammo_regen": "+0.1 pentes/s regenerados",
	"hyper_drive": "+40% velocidade do missil",
	"warhead": "+40% raio de explosao",
	"head_start": "+20 creditos ao iniciar run",
	"credit_boost": "+1 credito por abate",
	"time_warp": "+8% chance de desacelerar inimigo",
	"early_warning": "Mostra onde misseis vao cair",
	"extra_battery": "+1 bateria",
	"city_shield": "Campo de forca nas cidades",
	"warp_reload": "-12% tempo de recarga",
	"overcharge": "+15% velocidade de carga especial",
	"critical_mass": "+4% chance de explosao critica",
	"crystal_boost": "+1 cristal por abate",
	"homing": "+15% chance de rastreamento",
	"triple_burst": "+8% chance de tiro triplo",
	"temporal_freeze": "+1.5s de congelamento",
	"phoenix_protocol": "+1 cidade revive automatico",
	"singularity": "Explosoes puxam inimigos",
	"auto_turret": "Baterias atiram automaticamente",
	"mirror_array": "+5% chance de refletir",
	"void_boost": "+1 void por abate",
	"ascendant_core": "x2/x3 ganho de todas as moedas",
	"eternal_knowledge": "Mantem upgrades ao ascender",
	"vault": "Mantem moedas ao ascender",
	"omega_protocol": "3x dificuldade, 2 bosses",
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
	"warhead": ["hyper_drive"],
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

	$MarginContainer/VBoxContainer/BottomButtons/PlayButton.pressed.connect(_on_play_pressed)
	$MarginContainer/VBoxContainer/BottomButtons/AscendButton.pressed.connect(_on_ascend_pressed)

	if has_meta("eter_mode"):
		eter_mode = get_meta("eter_mode")

	if eter_mode:
		$MarginContainer/VBoxContainer/Header/TitleLabel.text = "UPGRADES ETERNOS"
		$MarginContainer/VBoxContainer/BottomButtons/AscendButton.visible = false
		graph_viewport.visible = false
		scroll_container.visible = true
		_build_eter_list()
	else:
		graph_viewport.visible = true
		scroll_container.visible = false
		_setup_graph()

	_update_header()

func setup(p_currency: CurrencySystem, p_upgrades: UpgradeSystem, _p_ads = null) -> void:
	currency = p_currency
	upgrade_system = p_upgrades

func _process(delta: float) -> void:
	if not eter_mode and graph_canvas:
		anim_time += delta
		graph_canvas.queue_redraw()

# ============================================================
# GRAPH SETUP & LAYOUT
# ============================================================

func _setup_graph() -> void:
	graph_canvas = Control.new()
	graph_canvas.draw.connect(_draw_graph)
	graph_canvas.gui_input.connect(_on_graph_input)
	graph_viewport.add_child(graph_canvas)
	await get_tree().process_frame
	var vp := graph_viewport.size
	graph_canvas.size = vp
	graph_canvas.custom_minimum_size = vp
	_calc_positions(vp)

func _calc_positions(vp: Vector2) -> void:
	node_screen_positions.clear()
	var max_depth := _get_max_depth("ammo_pack", 0)
	var row_gap := vp.y / float(max_depth + 2)
	var y_offset := row_gap * 0.8
	var margin_x := NODE_RADIUS + 8.0
	_layout_node("ammo_pack", margin_x, vp.x - margin_x, 0, row_gap, y_offset)

func _get_max_depth(key: String, depth: int) -> int:
	if not TREE_CHILDREN.has(key):
		return depth
	var max_d := depth
	for child in TREE_CHILDREN[key]:
		max_d = maxi(max_d, _get_max_depth(child, depth + 1))
	return max_d

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
	var total_leaves := _count_leaves(key)
	var current_x := x_start
	for child in children:
		var child_leaves := _count_leaves(child)
		var child_width := (x_end - x_start) * float(child_leaves) / float(total_leaves)
		_layout_node(child, current_x, current_x + child_width, depth + 1, y_gap, y_offset)
		current_x += child_width

# ============================================================
# INPUT (TAP)
# ============================================================

func _on_graph_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_start = event.position
			drag_distance = 0.0
		else:
			if drag_distance < 12.0:
				_handle_tap(event.position)
	elif event is InputEventScreenDrag:
		drag_distance = maxf(drag_distance, (event.position - drag_start).length())
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start = event.position
				drag_distance = 0.0
			else:
				if drag_distance < 12.0:
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

func _try_buy(key: String) -> void:
	if upgrade_system.buy(key, currency):
		purchase_made.emit()
		_update_header()

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
		graph_canvas.draw_circle(badge_pos, 13.0, Color(0.1, 0.1, 0.15, 0.9))
		var font := ThemeDB.fallback_font
		graph_canvas.draw_string(font, badge_pos + Vector2(-5, 6), "%d" % level, HORIZONTAL_ALIGNMENT_CENTER, 16, 16, Color.WHITE)

	if is_maxed:
		var font := ThemeDB.fallback_font
		graph_canvas.draw_string(font, center + Vector2(-20, r + 18), "MAX", HORIZONTAL_ALIGNMENT_CENTER, 40, 18, Color(1.0, 0.85, 0.0))

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
				var y := center.y + (-10 + i * 10) * s
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

	var font := ThemeDB.fallback_font
	var tx: float = popup_pos.x + 16
	var ty: float = popup_pos.y + 32

	var name_text: String = UPGRADE_NAMES.get(key, key)
	graph_canvas.draw_string(font, Vector2(tx, ty), name_text, HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 28, tier_col)

	var desc: String = UPGRADE_DESCRIPTIONS.get(key, "")
	graph_canvas.draw_string(font, Vector2(tx, ty + 34), desc, HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 22, Color(0.7, 0.7, 0.7))

	var level_str := "Lv %d/%d" % [level, max_level] if not is_maxed else "MAX"
	graph_canvas.draw_string(font, Vector2(tx, ty + 66), level_str, HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 22, Color(0.9, 0.9, 0.9))

	if is_maxed:
		graph_canvas.draw_string(font, Vector2(tx, ty + 98), "COMPLETO", HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 22, Color(1.0, 0.85, 0.0))
	else:
		var cost: int = upgrade_system.get_cost(key)
		var cur_type: String = u["currency"]
		var can_afford: bool = currency.get_amount(cur_type) >= cost
		var cost_col := Color(0.3, 1.0, 0.5) if can_afford else Color(1.0, 0.3, 0.3)
		var cost_text := "Custo: %d" % cost
		graph_canvas.draw_string(font, Vector2(tx, ty + 98), cost_text, HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 20, cost_col)
		var cost_text_w := font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		_draw_gem_on(graph_canvas, Vector2(tx + cost_text_w + 14, ty + 88), GEM_COLORS[cur_type])
		graph_canvas.draw_string(font, Vector2(tx + cost_text_w + 30, ty + 98), "— toque para comprar", HORIZONTAL_ALIGNMENT_LEFT, popup_w - 32, 20, cost_col)

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
	_update_header()

func _create_list_item(key: String, u: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label = Label.new()
	name_label.text = "%s (Lv %d/%d)" % [UPGRADE_NAMES.get(key, key), u["level"], u["max_level"]]
	name_label.add_theme_font_size_override("font_size", 24)
	info.add_child(name_label)
	var desc_label = Label.new()
	desc_label.text = UPGRADE_DESCRIPTIONS.get(key, "")
	desc_label.add_theme_font_size_override("font_size", 18)
	info.add_child(desc_label)
	row.add_child(info)
	var buy_button = Button.new()
	var cur_type = u["currency"]
	var cur_label = CURRENCY_LABELS.get(cur_type, cur_type)
	if u["level"] >= u["max_level"]:
		buy_button.text = "MAX"
		buy_button.disabled = true
	else:
		var cost = upgrade_system.get_cost(key)
		buy_button.text = "%d %s" % [cost, cur_label]
		buy_button.disabled = currency.get_amount(cur_type) < cost
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.pressed.connect(_on_eter_buy.bind(key))
	buy_button.custom_minimum_size = Vector2(150, 50)
	row.add_child(buy_button)
	return row

func _on_eter_buy(key: String) -> void:
	if upgrade_system.buy(key, currency):
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

func _on_ascend_pressed() -> void:
	ascend_requested.emit()

func _on_play_pressed() -> void:
	start_run.emit()
