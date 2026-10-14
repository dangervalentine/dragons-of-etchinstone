extends "res://tests/base.gd"
## The landscape layout at every window size the game is checked at.

const Solver = preload("res://ui/model/layout_solver.gd")
const T = preload("res://ui/theme/tokens.gd")

const ORDER := ["header", "encounter", "preview", "slots", "hand", "actions", "commit"]


func _plan(name: String, hand := 4, sets := 1) -> Dictionary:
	var m: Array = Solver.MATRIX[name]
	var view: Vector2 = Solver.view_for_window(m[0])
	var s: float = view.x / m[0].x
	var inset: Array = m[1]
	var safe := Rect2(inset[0] * s, inset[1] * s, view.x - (inset[0] + inset[2]) * s, view.y - (inset[1] + inset[3]) * s)
	return Solver.solve(view, safe, hand, sets, m[2] / s)


func _safe(name: String) -> Rect2:
	var m: Array = Solver.MATRIX[name]
	var view: Vector2 = Solver.view_for_window(m[0])
	var s: float = view.x / m[0].x
	var inset: Array = m[1]
	return Rect2(inset[0] * s, inset[1] * s, view.x - (inset[0] + inset[2]) * s, view.y - (inset[1] + inset[3]) * s)


func test_design_sizes() -> void:
	eq(Solver.view_for_window(Vector2(1280, 720)), Vector2(1280, 720), "16:9 phone")
	eq(Solver.view_for_window(Vector2(2048, 1536)), Vector2(1280, 960), "tablet")
	eq(Solver.view_for_window(Vector2(1440, 900)), Vector2(1280, 800), "desktop")
	ok(Solver.view_for_window(Vector2(2532, 1170)).x > 1500, "a tall phone is wider")


func test_only_the_upright_window_is_undersized() -> void:
	for name in Solver.MATRIX:
		eq(_plan(name).undersized, name == "upright-browser", name)


func test_regions_stay_inside_the_safe_area_and_do_not_overlap() -> void:
	for name in Solver.MATRIX:
		for shape in [[4, 1], [7, 2], [5, 1]]:
			var plan := _plan(name, shape[0], shape[1])
			var safe := _safe(name)
			for key in ORDER:
				var r: Rect2 = plan.regions[key]
				ok(safe.encloses(r), "%s %s inside the safe area" % [name, key])
				ok(r.size.x > 0 and r.size.y > 0, "%s %s has a size" % [name, key])
			for i in ORDER.size():
				for j in range(i + 1, ORDER.size()):
					ok(not plan.regions[ORDER[i]].intersects(plan.regions[ORDER[j]]),
						"%s: %s and %s do not overlap" % [name, ORDER[i], ORDER[j]])


func test_cards_fit_the_hand_region_and_stay_legible() -> void:
	for name in Solver.MATRIX:
		if name == "upright-browser":
			continue
		for shape in [[4, 1], [7, 2], [5, 1], [3, 1], [6, 2]]:
			var plan := _plan(name, shape[0], shape[1])
			eq(plan.card_rects.size(), shape[0], "%s: a place for every card" % name)
			ok(plan.card_size.x >= 120 and plan.card_size.y >= 168,
				"%s %s: cards at least 120 x 168, got %s" % [name, str(shape), str(plan.card_size)])
			for r in plan.card_rects:
				ok(plan.regions.hand.grow(0.5).encloses(r), "%s %s: card inside the Hand region" % [name, str(shape)])
			for i in plan.card_rects.size():
				for j in range(i + 1, plan.card_rects.size()):
					ok(not plan.card_rects[i].intersects(plan.card_rects[j]), "%s: cards do not overlap" % name)


func test_seven_cards_use_two_rows_and_four_use_one() -> void:
	eq(_plan("phone-16x9", 4, 1).hand_rows, 1, "four in a row")
	eq(_plan("phone-16x9", 7, 2).hand_rows, 2, "seven in two rows")


func test_controls_are_big_enough_to_tap() -> void:
	for name in Solver.MATRIX:
		var plan := _plan(name, 7, 2)
		ok(plan.regions.commit.size.y >= T.TAP_MIN and plan.regions.commit.size.x >= T.TAP_MIN, name + " commit")
		ok(plan.regions.actions.size.y >= T.TAP_MIN, name + " actions")
		ok(plan.regions.slots.size.y >= T.TAP_MIN, name + " slots")


func test_commit_is_in_the_bottom_right_corner() -> void:
	for name in Solver.MATRIX:
		var plan := _plan(name)
		eq(plan.regions.commit.end, plan.content.end, name)


func test_region_order_is_the_same_for_every_step() -> void:
	var a := _plan("desktop", 4, 1)
	var b := _plan("desktop", 7, 2)
	for key in ["header", "encounter", "preview", "actions", "commit"]:
		eq(a.regions[key], b.regions[key], key + " does not move between steps")
	eq(a.regions.slots.position, b.regions.slots.position, "slots start in the same place")


func test_larger_screens_are_used_not_left_empty() -> void:
	for name in ["phone-16x9", "phone-tall", "phone-small", "tablet", "desktop"]:
		var plan := _plan(name)
		var used := 0.0
		for key in ORDER:
			used += plan.regions[key].get_area()
		var safe := _safe(name)
		ok(used >= safe.get_area() * 0.8, "%s: regions cover %d%% of the safe area" % [name, int(100 * used / safe.get_area())])
	ok(_plan("tablet").card_size.x >= _plan("phone-16x9").card_size.x, "cards are no smaller on a tablet")
	ok(_plan("tablet").regions.slots.size.y > _plan("phone-16x9").regions.slots.size.y, "spare height goes to the slots")
	var wide := _plan("desktop-ultrawide")
	ok(wide.content.size.x <= T.DESIGN_MAX.x, "content is capped on an ultrawide window")
	ok(absf(wide.content.get_center().x - wide.view.x / 2.0) <= 1.0, "and centred")
