class_name DistantBattle
extends RefCounted

var missiles: Array[Dictionary] = []
var explosions: Array[Dictionary] = []
var defenses: Array[Dictionary] = []
var mushrooms: Array[Dictionary] = []
var spawn_timer := 0.0

const MAX_MISSILES := 4
const MAX_EXPLOSIONS := 6
const MAX_DEFENSES := 3

func update(delta: float, screen_size: Vector2, horizon_y: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(0.3, 1.2)
		var battle_top := horizon_y * 0.35
		if missiles.size() < MAX_MISSILES:
			var mx := randf_range(50.0, screen_size.x - 50.0)
			var target_x := mx + randf_range(-60.0, 60.0)
			var start_y := randf_range(battle_top, horizon_y - 60.0)
			missiles.append({
				"x": mx, "y": start_y, "start_y": start_y,
				"tx": target_x, "ty": horizon_y - randf_range(5.0, 20.0),
				"speed": randf_range(40.0, 90.0),
			})
		if defenses.size() < MAX_DEFENSES and randf() > 0.5 and missiles.size() > 0:
			var target_m: Dictionary = missiles[randi() % missiles.size()]
			var dx := randf_range(100.0, screen_size.x - 100.0)
			var predict_t := randf_range(0.3, 0.8)
			var m_dir := Vector2(target_m["tx"] - target_m["x"], target_m["ty"] - target_m["y"]).normalized()
			var intercept_x: float = target_m["x"] + m_dir.x * target_m["speed"] * predict_t
			var intercept_y: float = target_m["y"] + m_dir.y * target_m["speed"] * predict_t
			defenses.append({
				"x": dx, "y": horizon_y - 5.0,
				"tx": intercept_x + randf_range(-15.0, 15.0),
				"ty": intercept_y + randf_range(-10.0, 10.0),
				"speed": randf_range(80.0, 150.0),
			})

	var i := 0
	while i < missiles.size():
		var m: Dictionary = missiles[i]
		var dir := Vector2(m["tx"] - m["x"], m["ty"] - m["y"]).normalized()
		m["x"] += dir.x * m["speed"] * delta
		m["y"] += dir.y * m["speed"] * delta
		if m["y"] >= m["ty"]:
			explosions.append({
				"x": m["x"], "y": m["y"], "time": 0.0,
				"max_time": randf_range(0.4, 0.8),
				"radius": randf_range(12.0, 30.0),
				"color": Color(1.0, 0.3, 0.2),
			})
			mushrooms.append({
				"x": m["x"], "y": m["y"], "time": 0.0,
				"max_time": randf_range(1.2, 2.0),
				"height": randf_range(25.0, 45.0),
				"cap_r": randf_range(10.0, 18.0),
			})
			missiles.remove_at(i)
		else:
			i += 1

	i = 0
	while i < defenses.size():
		var d: Dictionary = defenses[i]
		var dir := Vector2(d["tx"] - d["x"], d["ty"] - d["y"]).normalized()
		d["x"] += dir.x * d["speed"] * delta
		d["y"] += dir.y * d["speed"] * delta
		if d["y"] <= d["ty"]:
			var exp_x: float = d["x"]
			var exp_y: float = d["y"]
			var exp_r := randf_range(15.0, 37.5)
			explosions.append({
				"x": exp_x, "y": exp_y, "time": 0.0,
				"max_time": randf_range(0.3, 0.6),
				"radius": exp_r,
				"color": Color(0.0, 0.8, 1.0),
			})
			var mi := 0
			while mi < missiles.size():
				var m: Dictionary = missiles[mi]
				var dist := Vector2(m["x"] - exp_x, m["y"] - exp_y).length()
				if dist < exp_r * 2.0:
					explosions.append({
						"x": m["x"], "y": m["y"], "time": 0.0,
						"max_time": randf_range(0.2, 0.4),
						"radius": randf_range(9.0, 18.0),
						"color": Color(1.0, 0.5, 0.2),
					})
					missiles.remove_at(mi)
				else:
					mi += 1
			defenses.remove_at(i)
		else:
			i += 1

	i = 0
	while i < explosions.size():
		var e: Dictionary = explosions[i]
		e["time"] += delta
		if e["time"] >= e["max_time"]:
			explosions.remove_at(i)
		else:
			i += 1

	i = 0
	while i < mushrooms.size():
		var mu: Dictionary = mushrooms[i]
		mu["time"] += delta
		if mu["time"] >= mu["max_time"]:
			mushrooms.remove_at(i)
		else:
			i += 1

func draw(c: CanvasItem) -> void:
	for m in missiles:
		var mx: float = m["x"]
		var my: float = m["y"]
		var progress := clampf((my - m["start_y"]) / (m["ty"] - m["start_y"]), 0.0, 1.0)
		var fade := clampf(progress * 3.0, 0.0, 1.0)
		var dir := Vector2(m["tx"] - mx, m["ty"] - my).normalized()
		var tail := Vector2(mx - dir.x * 45.0, my - dir.y * 45.0)
		c.draw_line(Vector2(mx, my), tail, Color(1.0, 0.2, 0.4, 0.3 * fade), 2.25, true)
		c.draw_circle(Vector2(mx, my), 3.4, Color(1.0, 0.3, 0.5, 0.5 * fade))

	for d in defenses:
		var dx: float = d["x"]
		var dy: float = d["y"]
		var dir := Vector2(d["tx"] - dx, d["ty"] - dy).normalized()
		var tail := Vector2(dx - dir.x * 33.75, dy - dir.y * 33.75)
		c.draw_line(Vector2(dx, dy), tail, Color(0.0, 0.8, 1.0, 0.25), 2.25, true)
		c.draw_circle(Vector2(dx, dy), 2.25, Color(0.0, 1.0, 1.0, 0.5))

	for e in explosions:
		var ex: float = e["x"]
		var ey: float = e["y"]
		var t: float = e["time"] / e["max_time"]
		var r: float = e["radius"] * t
		var alpha := (1.0 - t) * 0.5
		var col: Color = e["color"]
		c.draw_circle(Vector2(ex, ey), r * 1.5, Color(col.r, col.g, col.b, alpha * 0.15))
		c.draw_circle(Vector2(ex, ey), r, Color(col.r, col.g, col.b, alpha * 0.4))
		c.draw_circle(Vector2(ex, ey), r * 0.4, Color(1.0, 1.0, 1.0, alpha * 0.6))

	for mu in mushrooms:
		var mx: float = mu["x"]
		var my: float = mu["y"]
		var t: float = mu["time"] / mu["max_time"]
		var grow := clampf(t * 4.0, 0.0, 1.0)
		var alpha := (1.0 - t) * 0.4
		var h: float = mu["height"] * grow
		var cap: float = mu["cap_r"] * grow
		var stem_w := cap * 0.3
		# Stem
		c.draw_rect(Rect2(mx - stem_w, my - h, stem_w * 2.0, h), Color(1.0, 0.4, 0.15, alpha * 0.5))
		# Cap (mushroom top)
		var cap_y := my - h
		c.draw_circle(Vector2(mx, cap_y), cap, Color(1.0, 0.3, 0.1, alpha * 0.6))
		c.draw_circle(Vector2(mx, cap_y), cap * 1.4, Color(1.0, 0.2, 0.05, alpha * 0.2))
		c.draw_circle(Vector2(mx, cap_y), cap * 0.5, Color(1.0, 0.7, 0.3, alpha * 0.4))
