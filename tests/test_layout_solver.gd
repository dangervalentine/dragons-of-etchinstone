extends "res://tests/base.gd"
## The landscape layout at every window size the game is checked at.

const Solver = preload("res://ui/model/layout_solver.gd")
const T = preload("res://ui/theme/tokens.gd")

func _plan(name: String, hand := 4, places := 4, final := false) -> Dictionary:
	var m: Array = Solver.MATRIX[name]
	var view := Solver.matrix_view(name)
	var k: float = Solver.stage_for_window(m[0], view).size.x / view.x
	return Solver.solve(view, _safe(name), hand, places, m[2] * k, 0.0, T.ENCOUNTER_MIN, m[0].y > m[0].x, final)


func _safe(name: String) -> Rect2:
	return Solver.matrix_safe(name)


func test_stage_for_window() -> void:
	eq(Solver.stage_for_window(Vector2(1280, 720)), Rect2(0, 0, 1280, 720), "16:9 fills the window")
	eq(Solver.stage_for_window(Vector2(1440, 900)), Rect2(0, 45, 1440, 810), "16:10: bars above and below")
	eq(Solver.stage_for_window(Vector2(3840, 1080)), Rect2(960, 0, 1920, 1080), "ultrawide: bars at the sides")
	eq(Solver.stage_for_window(Vector2(720, 1280)), Rect2(0, 437.5, 720, 405), "upright: a strip across the middle")
	for name in Solver.MATRIX:
		var window: Vector2 = Solver.MATRIX[name][0]
		var view := Solver.matrix_view(name)
		var stage := Solver.stage_for_window(window, view)
		ok(Rect2(Vector2.ZERO, window).grow(0.01).encloses(stage), "%s: the play area is inside the window" % name)
		if Solver.MATRIX[name][3]:
			ok(stage.grow(0.5).encloses(Rect2(Vector2.ZERO, window)), "%s: the play area fills the screen" % name)
		else:
			ok(absf(stage.size.x / stage.size.y - 16.0 / 9.0) < 0.01, "%s: the play area is 16:9" % name)


func test_view_for_window() -> void:
	for window in [Vector2(1440, 900), Vector2(3840, 1080), Vector2(2532, 1170), Vector2(720, 1280)]:
		eq(Solver.view_for_window(window, false), T.DESIGN_MIN, "locked at %s: the design size" % str(window))
	eq(Solver.view_for_window(Vector2(1280, 720), true), T.DESIGN_MIN, "a 16:9 phone: the design size")
	eq(Solver.view_for_window(Vector2(2532, 1170), true), Vector2(1558, 720), "a tall phone grows wider")
	eq(Solver.view_for_window(Vector2(2048, 1536), true), Vector2(1280, 960), "a tablet grows taller")
	for name in Solver.MATRIX:
		var view := Solver.matrix_view(name)
		ok(view.x >= T.DESIGN_MIN.x and view.y >= T.DESIGN_MIN.y, "%s: at least the design size" % name)


func test_safe_area_maps_through_the_letterbox() -> void:
	eq(Solver.matrix_safe("phone-16x9"), Rect2(Vector2.ZERO, T.DESIGN_MIN), "no insets: all of it")
	# Locked, as the web build is in a phone's browser: the tall phone's side bars
	# (226 px) are wider than its notch (141 px); only the home indicator, 63 px of
	# 1170, reaches into the play area.
	var tall_px := Rect2(141, 0, 2532 - 282, 1170 - 63)
	var tall := Solver.safe_in_view(Vector2(2532, 1170), tall_px)
	eq(tall.position.x, 0.0, "the notch is in the letterbox")
	eq(tall.size.x, T.DESIGN_MIN.x, "so the width is all safe")
	ok(absf(tall.end.y - (1170.0 - 63.0) * 720.0 / 1170.0) < 0.01, "the home indicator is left out")
	var tablet := Solver.safe_in_view(Vector2(2048, 1536), Rect2(0, 0, 2048, 1536 - 40))
	eq(tablet, Rect2(Vector2.ZERO, T.DESIGN_MIN), "a tablet's home bar sits in the bottom letterbox")


func test_safe_area_of_a_screen_the_view_fills() -> void:
	# The app on the same phone: no letterbox, so the notch and home indicator are
	# in the view and the safe area keeps clear of them, on whichever side.
	var k := 1170.0 / 720.0
	var tall := Solver.matrix_safe("phone-tall")
	ok(absf(tall.position.x - 141.0 / k) < 0.5, "clear of the notch on the left, got %s" % str(tall))
	ok(absf(tall.end.x - (Solver.matrix_view("phone-tall").x - 141.0 / k)) < 0.5, "and of the other side")
	ok(absf(tall.end.y - (1170.0 - 63.0) / k) < 0.5, "and of the home indicator")
	var flipped := Solver.matrix_safe("phone-tall", true)
	eq(flipped.size, tall.size, "turned over, the same size")
	var tablet := Solver.matrix_safe("tablet")
	eq(tablet.size.x, 1280.0, "a tablet keeps its width")
	ok(absf(tablet.end.y - (1536.0 - 40.0) / 1.6) < 0.5, "and keeps clear of its home bar")


## The same device's layout under the 16:9 lock, as the web build gives it.
func _locked(name: String) -> Dictionary:
	var m: Array = Solver.MATRIX[name]
	var inset: Array = m[1]
	var px := Rect2(Vector2(inset[0], inset[1]), m[0] - Vector2(inset[0] + inset[2], inset[1] + inset[3]))
	return Solver.solve(T.DESIGN_MIN, Solver.safe_in_view(m[0], px))


func test_screens_that_fill_use_the_room() -> void:
	var tall := _plan("phone-tall")
	ok(tall.content.size.x > _locked("phone-tall").content.size.x, "a tall phone's layout is wider than locked")
	var tablet := _plan("tablet")
	ok(tablet.content.size.y > _locked("tablet").content.size.y, "a tablet's layout is taller than locked")
	ok(tablet.card_size.x > _locked("tablet").card_size.x, "with bigger cards")
	for name in Solver.MATRIX:
		ok(_plan(name).card_size.x >= _locked(name).card_size.x, "%s: cards no smaller than locked" % name)
	for name in Solver.MATRIX:
		var p := _plan(name)
		for key in ["header", "encounter", "preview", "slots", "hand", "actions", "commit"]:
			ok(_safe(name).grow(0.5).encloses(p.regions[key]),
				"%s: %s inside the safe area" % [name, key])


func test_the_layout_stops_growing_at_the_maximum() -> void:
	# A phone longer than 22:9: the content stays at its widest and sits in the middle.
	var view := Solver.view_for_window(Vector2(3200, 1080), true)
	var p := Solver.solve(view, Rect2(Vector2.ZERO, view))
	eq(p.content.size.x, T.DESIGN_MAX.x, "no wider than the maximum")
	ok(absf(p.content.get_center().x - view.x / 2.0) <= 1.0, "centred")


func test_upright_is_undersized() -> void:
	var all := Rect2(Vector2.ZERO, T.DESIGN_MIN)
	ok(Solver.solve(T.DESIGN_MIN, all, 4, 1, 0.5, 0.0, T.ENCOUNTER_MIN, true).undersized, "an upright window is undersized")
	ok(not Solver.solve(T.DESIGN_MIN, all, 4, 1, 0.5, 0.0, T.ENCOUNTER_MIN, false).undersized, "a landscape one is not")


func test_the_encounter_keeps_its_height() -> void:
	for name in Solver.MATRIX:
		if name == "upright-browser":
			continue
		var view := Solver.matrix_view(name)
		# The largest preview the solver allows, beside an Encounter and the dragon.
		for least in [T.ENCOUNTER_MIN, T.DRAGON_MIN]:
			var plan := Solver.solve(view, _safe(name), 4, 1, 0.5, 5000.0, least)
			ok(plan.regions.encounter.size.y >= least,
				"%s: face %.0f tall, at least %d" % [name, plan.regions.encounter.size.y, least])
			ok(plan.regions.preview.size.y >= T.PREVIEW_MIN, "%s: the box keeps its floor" % name)


func test_soak_and_upgrade_keep_the_same_regions() -> void:
	# Soak and Upgrade show the recap of the set just played in the same four places,
	# over the same four-card Hand (cards leave it only when the Encounter ends).
	for name in Solver.MATRIX:
		var building := _plan(name, 4, 4)
		var recap := _plan(name, 4, 4)
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
	ok(huge.regions.preview.size.y <= roundf(body_h * 0.56) + 1.0, "and never much more than half the column")
	ok(huge.regions.encounter.size.y >= T.ENCOUNTER_MIN, "nor so much that the Encounter is cut")
	for needed in [0.0, 10.0, 200.0, 5000.0]:
		var p: Dictionary = at.call(needed)
		eq(p.regions.encounter.end.y + Solver.GAP, p.regions.preview.position.y, "the Encounter fills the rest (%d)" % needed)


# Feature 009: the card side is the role strip, the band of cards and the action row.

func test_the_card_side_runs_strip_cards_actions() -> void:
	var p := _plan("phone-16x9")
	var r: Dictionary = p.regions
	var c: Rect2 = p.content
	for key in ["slots", "hand", "actions"]:
		eq(r[key].position.x, r.slots.position.x, key + " starts at the card side's left")
		eq(r[key].end.x, c.end.x, key + " runs to the right edge")
	eq(r.slots.size.y, 88.0, "the strip is one tap target tall")
	ok(r.slots.size.y <= 184.0 / 2.0, "at most half the old slot band (FR-018)")
	eq(r.slots.position.y, p.body.position.y, "the strip is at the top")
	ok(r.slots.end.y < r.hand.position.y, "the cards are under the strip")
	ok(r.hand.end.y < r.actions.position.y, "the actions are under the cards")
	eq(r.actions.size.y, 88.0, "the action row is one tap target tall")
	eq(r.actions.end.y, c.end.y, "at the foot of the screen")
	ok(r.encounter.end.x < r.slots.position.x, "the left side is apart")


func test_the_action_row_is_quarter_quarter_half() -> void:
	for name in Solver.MATRIX:
		var r: Dictionary = _plan(name).regions
		var w: float = r.actions.size.x - 2 * T.S
		for i in 2:
			ok(absf(r.secondary[i].size.x - w / 4.0) <= w * 0.02, "%s: cell %d is a quarter" % [name, i])
			eq(r.secondary[i].size.y, r.actions.size.y, "%s: cell %d fills the row's height" % [name, i])
		ok(absf(r.commit.size.x - w / 2.0) <= w * 0.02, "%s: Play is a half" % name)
		eq(r.commit.end.x, r.actions.end.x, "%s: Play is on the right" % name)
		ok(r.secondary[0].end.x < r.secondary[1].position.x and r.secondary[1].end.x < r.commit.position.x,
			"%s: the cells sit apart, in order" % name)


func test_setup_and_soak_have_no_strip() -> void:
	var p := _plan("phone-16x9", 5, 0)
	eq(p.regions.slots.size.y, 0.0, "no strip")
	eq(p.place_rects, [], "no places")
	eq(p.regions.hand.position.y, p.body.position.y, "the cards take the room")


func test_a_region_card_size() -> void:
	var p := _plan("phone-16x9")
	ok(absf(p.card_size.x - 148.0) <= 3.0, "about 148 wide, got %s" % str(p.card_size))
	eq(p.left_w, 400.0, "the left side as before")


## Every stage of placing: k cards in places, the rest floating. All inside the
## content, none overlapping, the outlines above the floating cards.
func _check_stages(where: String, p: Dictionary, hand: int, places: int) -> void:
	var c: Rect2 = p.content
	for k in range(0, mini(places, hand) + 1):
		var rects: Array = []
		for i in k:
			rects.append(p.place_rects[i])
		var floating: Array = Solver.floating_rects(p, hand - k)
		rects.append_array(floating)
		if k == 0 and places > 0:
			var h := Solver.outline_height(p, hand)
			ok(h >= Solver.PLACE_EMPTY_H, "%s: outlines keep their least height" % where)
		for i in rects.size():
			ok(c.grow(0.5).encloses(rects[i]), "%s k=%d: card %d inside, got %s" % [where, k, i, str(rects[i])])
			ok(p.regions.hand.grow(0.5).encloses(rects[i]), "%s k=%d: card %d in the band of cards" % [where, k, i])
			for j in range(i + 1, rects.size()):
				ok(not rects[i].grow(-1).intersects(rects[j].grow(-1)), "%s k=%d: cards %d and %d apart" % [where, k, i, j])


func test_every_stage_fits_in_a_region() -> void:
	for name in Solver.MATRIX:
		if name == "upright-browser":
			continue
		for hand in [1, 2, 3, 4]:
			_check_stages("%s %d cards" % [name, hand], _plan(name, hand, 4), hand, 4)


func test_the_final_battle_narrows_the_left_and_fits_every_card() -> void:
	for name in Solver.MATRIX:
		if name == "upright-browser":
			continue
		for case in [[7, 7], [8, 6], [9, 6], [6, 6]]:
			var p := _plan(name, case[0], case[1], true)
			eq(p.left_w, Solver.FINAL_LEFT_W, "%s: the left side narrows" % name)
			_check_stages("%s final %s" % [name, str(case)], p, case[0], case[1])
	var journey := _plan("phone-16x9", 7, 7, true)
	ok(absf(journey.card_size.x - 112.0) <= 3.0, "Final Journey cards about 112 wide, got %s" % str(journey.card_size))
	var eight := _plan("phone-16x9", 8, 6, true)
	ok(absf(eight.card_size.x - 112.0) <= 3.0, "8-card Final Enemy about 112, got %s" % str(eight.card_size))
	var nine := _plan("phone-16x9", 9, 6, true)
	ok(absf(nine.card_size.x - 96.0) <= 3.0, "9-card Final Enemy about 96, got %s" % str(nine.card_size))
