extends "res://tests/base.gd"
## The landscape layout at every window size the game is checked at.

const Solver = preload("res://ui/model/layout_solver.gd")
const T = preload("res://ui/theme/tokens.gd")

const ORDER := ["header", "encounter", "preview", "slots", "hand", "actions", "commit"]
## Play sits inside the action column (Solver.PLAY_IN_COLUMN is false): the one pair
## of regions that nests rather than sitting apart.
const NESTED := [["actions", "commit"]]


func _apart(a: String, b: String) -> bool:
	return not NESTED.has([a, b]) and not NESTED.has([b, a])


func _plan(name: String, hand := 4, sets := 1) -> Dictionary:
	var m: Array = Solver.MATRIX[name]
	var k: float = Solver.stage_for_window(m[0]).size.x / T.DESIGN_MIN.x
	return Solver.solve(T.DESIGN_MIN, _safe(name), hand, sets, m[2] * k, 0.0, T.ENCOUNTER_MIN, m[0].y > m[0].x)


func _safe(name: String) -> Rect2:
	return Solver.matrix_safe(name)


func test_stage_for_window() -> void:
	eq(Solver.stage_for_window(Vector2(1280, 720)), Rect2(0, 0, 1280, 720), "16:9 fills the window")
	eq(Solver.stage_for_window(Vector2(1440, 900)), Rect2(0, 45, 1440, 810), "16:10: bars above and below")
	eq(Solver.stage_for_window(Vector2(3840, 1080)), Rect2(960, 0, 1920, 1080), "ultrawide: bars at the sides")
	eq(Solver.stage_for_window(Vector2(720, 1280)), Rect2(0, 437.5, 720, 405), "upright: a strip across the middle")
	for name in Solver.MATRIX:
		var window: Vector2 = Solver.MATRIX[name][0]
		var stage := Solver.stage_for_window(window)
		ok(absf(stage.size.x / stage.size.y - 16.0 / 9.0) < 0.01, "%s: the play area is 16:9" % name)
		ok(Rect2(Vector2.ZERO, window).grow(0.01).encloses(stage), "%s: the play area is inside the window" % name)


func test_safe_area_maps_through_the_letterbox() -> void:
	eq(Solver.matrix_safe("phone-16x9"), Rect2(Vector2.ZERO, T.DESIGN_MIN), "no insets: all of it")
	# A tall phone's side bars (226 px) are wider than its notch (141 px); only the
	# home indicator, 63 px of 1170, reaches into the play area.
	var tall := Solver.matrix_safe("phone-tall")
	eq(tall.position.x, 0.0, "the notch is in the letterbox")
	eq(tall.size.x, T.DESIGN_MIN.x, "so the width is all safe")
	ok(absf(tall.end.y - (1170.0 - 63.0) * 720.0 / 1170.0) < 0.01, "the home indicator is left out")
	var tablet := Solver.matrix_safe("tablet")
	eq(tablet, Rect2(Vector2.ZERO, T.DESIGN_MIN), "a tablet's home bar sits in the bottom letterbox")


func test_upright_is_undersized() -> void:
	var all := Rect2(Vector2.ZERO, T.DESIGN_MIN)
	ok(Solver.solve(T.DESIGN_MIN, all, 4, 1, 0.5, 0.0, T.ENCOUNTER_MIN, true).undersized, "an upright window is undersized")
	ok(not Solver.solve(T.DESIGN_MIN, all, 4, 1, 0.5, 0.0, T.ENCOUNTER_MIN, false).undersized, "a landscape one is not")


func test_the_encounter_keeps_its_height() -> void:
	for name in Solver.MATRIX:
		if name == "upright-browser":
			continue
		var view: Vector2 = T.DESIGN_MIN
		# The largest preview the solver allows, beside an Encounter and the dragon.
		for least in [T.ENCOUNTER_MIN, T.DRAGON_MIN]:
			var plan := Solver.solve(view, _safe(name), 4, 1, 0.5, 5000.0, least)
			ok(plan.regions.encounter.size.y >= least,
				"%s: face %.0f tall, at least %d" % [name, plan.regions.encounter.size.y, least])
			ok(plan.regions.preview.size.y >= T.PREVIEW_MIN, "%s: the box keeps its floor" % name)


func test_soak_and_upgrade_keep_the_same_regions() -> void:
	# Soak and Upgrade show the recap of the set just played: one row of slots, over
	# the same four-card Hand (cards leave it only when the Encounter ends).
	for name in Solver.MATRIX:
		var building := _plan(name, 4, 1)
		var recap := _plan(name, 4, 1)
		for key in ["slots", "actions", "commit"]:
			eq(recap.regions[key], building.regions[key], "%s: %s stays put in Soak and Upgrade" % [name, key])


func test_preview_takes_what_it_needs() -> void:
	var view: Vector2 = T.DESIGN_MIN
	var safe := _safe("phone-16x9")
	var at := func(needed: float) -> Dictionary:
		return Solver.solve(view, safe, 4, 1, 0.5, needed)
	eq(at.call(200.0).regions.preview.size.y, 200.0, "the preview takes the height it asks for")
	eq(at.call(10.0).regions.preview.size.y, float(T.PREVIEW_MIN), "but never less than the floor")
	var huge: Dictionary = at.call(5000.0)
	var body_h: float = huge.regions.preview.end.y - huge.regions.encounter.position.y
	ok(huge.regions.preview.size.y <= roundf(body_h * 0.5) + 1.0, "and never more than half the column")
	ok(huge.regions.encounter.size.y >= T.ENCOUNTER_MIN, "nor so much that the Encounter is cut")
	for needed in [0.0, 10.0, 200.0, 5000.0]:
		var p: Dictionary = at.call(needed)
		eq(p.regions.encounter.end.y + Solver.GAP, p.regions.preview.position.y, "the Encounter fills the rest (%d)" % needed)
