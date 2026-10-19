extends "res://tests/base.gd"
## The landscape layout at every window size the game is checked at.

const Solver = preload("res://ui/model/layout_solver.gd")
const T = preload("res://ui/theme/tokens.gd")

## The card sizes of the 009 layout, measured before feature 010 replaced it: no
## card may be smaller now (FR-013).
const SIZE_009 := {
	"phone-16x9": {"region": Vector2(149, 208), "final_journey": Vector2(112, 156), "final_enemy": Vector2(96, 134)},
	"phone-tall": {"region": Vector2(140, 196), "final_journey": Vector2(131, 183), "final_enemy": Vector2(113, 158)},
	"phone-tall-flipped": {"region": Vector2(140, 196), "final_journey": Vector2(131, 183), "final_enemy": Vector2(113, 158)},
	"phone-small": {"region": Vector2(149, 208), "final_journey": Vector2(112, 156), "final_enemy": Vector2(96, 134)},
	"tablet": {"region": Vector2(197, 275), "final_journey": Vector2(112, 156), "final_enemy": Vector2(132, 184)},
	"desktop": {"region": Vector2(149, 208), "final_journey": Vector2(112, 156), "final_enemy": Vector2(96, 134)},
	"desktop-ultrawide": {"region": Vector2(149, 208), "final_journey": Vector2(112, 156), "final_enemy": Vector2(96, 134)},
	"upright-browser": {"region": Vector2(149, 208), "final_journey": Vector2(112, 156), "final_enemy": Vector2(96, 134)},
}

func _plan(name: String, hand := 4, places := 4, final := false, cells := 3) -> Dictionary:
	var m: Array = Solver.MATRIX[name]
	var view := Solver.matrix_view(name)
	var k: float = Solver.stage_for_window(m[0], view).size.x / view.x
	return Solver.solve(view, _safe(name), hand, places, m[2] * k, m[0].y > m[0].x, final, cells)


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
	# Since feature 010 a Region's cards are as wide as the card side allows, so a
	# taller screen gives them no more room; they are never smaller.
	ok(tablet.card_size.x >= _locked("tablet").card_size.x, "with cards no smaller")
	for name in Solver.MATRIX:
		ok(_plan(name).card_size.x >= _locked(name).card_size.x, "%s: cards no smaller than locked" % name)
	for name in Solver.MATRIX:
		var p := _plan(name)
		for key in ["header", "encounter", "hand", "actions", "commit"]:
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
	ok(Solver.solve(T.DESIGN_MIN, all, 4, 1, 0.5, true).undersized, "an upright window is undersized")
	ok(not Solver.solve(T.DESIGN_MIN, all, 4, 1, 0.5, false).undersized, "a landscape one is not")


func test_the_left_column_is_the_deck_alone() -> void:
	# Feature 013: no box under the Deck; it takes the column's whole height.
	for name in Solver.MATRIX:
		for final in [false, true]:
			var p := _plan(name, 7 if final else 4, 6 if final else 4, final)
			var r: Dictionary = p.regions
			ok(not r.has("preview"), "%s: no box under the Deck" % name)
			eq(r.encounter.position.y, r.hand.position.y, "%s: the Deck starts level with the Hand" % name)
			eq(r.encounter.end.y, r.actions.end.y, "%s: and runs to the foot of the action row" % name)
			eq(r.encounter.position.x, p.content.position.x, "%s: at the left edge" % name)
			if not final:
				ok(r.encounter.size.x >= T.LEFT_MIN_W, "%s: no narrower than %d" % [name, T.LEFT_MIN_W])


func test_soak_and_upgrade_keep_the_same_regions() -> void:
	# Soak and Upgrade show the recap of the set just played in the same four places,
	# over the same four-card Hand (cards leave it only when the Encounter ends).
	for name in Solver.MATRIX:
		var building := _plan(name, 4, 4)
		var recap := _plan(name, 4, 4)
		for key in ["hand", "actions", "commit"]:
			eq(recap.regions[key], building.regions[key], "%s: %s stays put in Soak and Upgrade" % [name, key])


# Feature 010: the card side is the Hand, one labelled place per card, over the
# action row, whose cells share its width by how many there are.

func test_the_card_side_runs_hand_then_actions() -> void:
	var p := _plan("phone-16x9")
	var r: Dictionary = p.regions
	var c: Rect2 = p.content
	ok(not r.has("slots"), "no role strip")
	for key in ["hand", "actions"]:
		eq(r[key].end.x, c.end.x, key + " runs to the right edge")
	eq(r.hand.position.x, r.actions.position.x, "the Hand and the actions share the card side")
	eq(r.hand.position.y, p.body.position.y, "the Hand starts at the top")
	eq(r.hand.end.y + Solver.GAP, r.actions.position.y, "the actions are just under it")
	eq(r.actions.size.y, 88.0, "the action row is one tap target tall")
	eq(r.actions.end.y, c.end.y, "at the foot of the screen")
	ok(r.encounter.end.x < r.hand.position.x, "the left side is apart")


func test_every_place_is_a_label_over_a_card() -> void:
	for name in Solver.MATRIX:
		var p := _plan(name)
		eq(p.positions.size(), 4, "%s: four places" % name)
		for i in p.positions.size():
			var pos: Dictionary = p.positions[i]
			eq(pos.label.size.y, Solver.LABEL_H, "%s: label %d is 36 tall" % [name, i])
			eq(pos.label.end.y, pos.card.position.y, "%s: label %d sits on its card" % [name, i])
			eq(pos.card.size, p.card_size, "%s: card %d the Hand's size" % [name, i])
			ok(p.regions.hand.grow_individual(0.5, -Solver.HAND_PAD + 0.5, 0.5, -Solver.HAND_PAD + 0.5).encloses(pos.label.merge(pos.card)), "%s: place %d inside the Hand's well" % [name, i])
			if i == 0:
				eq(pos.label.position.y, p.regions.hand.position.y + Solver.HAND_PAD, "%s: the well's top is level with the left side" % name)
			if i > 0:
				ok(p.positions[i - 1].card.end.x < pos.card.position.x, "%s: places %d and %d apart, in order" % [name, i - 1, i])
				eq(p.positions[i - 1].card.position.y, pos.card.position.y, "%s: one row" % name)


func test_region_cards_are_larger_than_before() -> void:
	# A Region's one row gives up a little width to the Boost's column, so its cards
	# are smaller than 010 made them (SC-001's 294 on phone-tall, FR-013's 009
	# sizes): still larger than 009's, and than the Final Battle's, everywhere but
	# the tablet.
	var tall := _plan("phone-tall")
	eq(tall.card_size, Vector2(198, 277), "phone-tall: 198 x 277")
	ok(tall.card_size.y >= 1.4 * SIZE_009["phone-tall"].region.y, "two fifths again as tall as 009's")
	eq(_plan("phone-16x9").card_size, Vector2(175, 245), "baseline: 175 x 245")
	for name in Solver.MATRIX:
		var cases := {"region": _plan(name), "final_journey": _plan(name, 7, 7, true), "final_enemy": _plan(name, 9, 6, true)}
		for stage in cases:
			var size: Vector2 = cases[stage].card_size
			if stage == "region":
				# The tablet's tall Hand fits both Final rows at full width, so only there
				# are a Region's cards the smaller.
				if name != "tablet":
					ok(size.x > cases.final_journey.card_size.x, "%s: a Region's cards are larger than the Final Battle's" % name)
					ok(size.x >= SIZE_009[name][stage].x, "%s region: %s no smaller than 009's %s" % [name, str(size), str(SIZE_009[name][stage])])
			else:
				ok(size.x >= SIZE_009[name][stage].x, "%s %s: %s no smaller than 009's %s (FR-013)" % [name, stage, str(size), str(SIZE_009[name][stage])])


func test_setup_and_soak_have_no_labels() -> void:
	var p := _plan("phone-16x9", 5, 0)
	eq(p.label_h, 0.0, "no labels")
	eq(p.positions.size(), 5, "a place for each card")
	for pos in p.positions:
		eq(pos.label.size.y, 0.0, "the card is its whole place")


func test_the_final_journey_breaks_between_the_sets() -> void:
	var p := _plan("phone-16x9", 7, 7, true)
	eq(p.left_w, Solver.FINAL_LEFT_W, "the left side narrows")
	var tops := {}
	for pos in p.positions:
		tops[pos.card.position.y] = tops.get(pos.card.position.y, 0) + 1
	eq(tops.values(), [4, 3], "two rows: the Reserve and Set 1, then Set 2")


func test_the_final_battle_fits_every_card() -> void:
	for name in Solver.MATRIX:
		if name == "upright-browser":
			continue
		for case in [[7, 7], [8, 6], [9, 6], [6, 6]]:
			var p := _plan(name, case[0], case[1], true)
			eq(p.positions.size(), case[0], "%s %s: a place per card" % [name, str(case)])
			for i in p.positions.size():
				var a: Dictionary = p.positions[i]
				ok(p.content.grow(0.5).encloses(a.label.merge(a.card)), "%s %s: place %d on screen" % [name, str(case), i])
				for j in range(i + 1, p.positions.size()):
					var b: Dictionary = p.positions[j]
					ok(not a.label.merge(a.card).grow(-1).intersects(b.label.merge(b.card).grow(-1)),
						"%s %s: places %d and %d apart" % [name, str(case), i, j])


func test_the_action_row_shares_its_width_by_cell_count() -> void:
	for name in Solver.MATRIX:
		for case in [[3, 2, 0.5], [4, 3, 0.25], [5, 4, 0.2]]:
			var r: Dictionary = _plan(name, 4, 4, false, case[0]).regions
			var w: float = r.actions.size.x
			var each: float = 0.25 if case[0] <= 4 else 0.2
			eq(r.secondary.size(), case[1], "%s, %d cells: %d secondary" % [name, case[0], case[1]])
			for i in r.secondary.size():
				ok(absf(r.secondary[i].size.x - w * each) <= w * 0.02, "%s, %d cells: cell %d is %.2f of the row" % [name, case[0], i, each])
				eq(r.secondary[i].size.y, r.actions.size.y, "%s: cell %d fills the row's height" % [name, i])
			ok(absf(r.commit.size.x - w * case[2]) <= w * 0.02, "%s, %d cells: Play is %.2f of the row" % [name, case[0], case[2]])
			eq(r.commit.end.x, r.actions.end.x, "%s: Play is on the right" % name)
			ok(r.secondary[-1].end.x < r.commit.position.x, "%s: Play comes last" % name)


func test_the_final_battle_shares_one_row_of_labels() -> void:
	for case in [[7, 7, 1], [6, 6, 0], [9, 6, 0]]:
		var p := _plan("phone-16x9", case[0], case[1], true)
		ok(p.set_rows, "%s: the sets are rows" % str(case))
		var lead: int = case[2]
		for c in 3:
			var top: Dictionary = p.positions[lead + c]
			var under: Dictionary = p.positions[lead + 3 + c]
			eq(top.card.position.x, under.card.position.x, "%s: Set 2's place %d is under Set 1's" % [str(case), c])
			eq(top.label.size.y, Solver.LABEL_H, "%s: Set 1's place %d is labelled" % [str(case), c])
			eq(under.label.size.y, 0.0, "%s: Set 2's place %d shares that label" % [str(case), c])
			ok(under.card.position.y > top.card.end.y, "%s: Set 2 is below" % str(case))
	var journey := _plan("phone-16x9", 7, 7, true)
	ok(journey.card_size.x >= 160.0, "Final Journey cards larger than with a label per row, got %s" % str(journey.card_size))


## A Boost card's aim zone is one tap target tall along its bottom edge (specs/011
## research R4); on every shape it stays within half the card, so the rest still
## picks the card up.
func test_the_aim_zone_leaves_half_the_card() -> void:
	for name in Solver.MATRIX:
		for c in [_plan(name), _plan(name, 9, 6, true)]:
			ok(T.TAP_MIN <= c.card_size.y * 0.5, "%s: an aim zone of %d on a %s card" % [name, T.TAP_MIN, str(c.card_size)])


func test_the_final_enemys_extras_are_not_counted_as_places() -> void:
	# One card over the two sets: seven places in the view, but only six with a Role,
	# so the grid keeps no Reserve column and Set 2 stays under Set 1.
	var places := []
	for i in 2:
		for role in ["element", "spell", "boost"]:
			places.append({"role": role})
	places.append({"role": "extra"})
	eq(Solver.place_count({"places": places}), 6, "the extra has no place of its own")
	places.push_front({"role": "reserve"})
	eq(Solver.place_count({"places": places}), 7, "the Reserve does")


func test_each_set_has_a_boost_aim_beside_its_row() -> void:
	for name in Solver.MATRIX:
		for case in [[4, 4, false, 1], [7, 7, true, 2], [8, 6, true, 2]]:
			var p := _plan(name, case[0], case[1], case[2])
			var aims: Array = p.boost_aims
			eq(aims.size(), case[3], "%s %s: an aim per set" % [name, str(case)])
			var right := 0.0
			for pos in p.positions:
				right = maxf(right, pos.card.end.x)
			for r in aims:
				ok(r.size.x >= T.TAP_MIN and r.size.y >= 2 * T.TAP_MIN + T.S, "%s %s: room for two tap targets, %s" % [name, str(case), str(r.size)])
				ok(p.regions.hand.encloses(r), "%s %s: inside the Hand" % [name, str(case)])
				ok(r.position.x >= right + Solver.CARD_GAP_MIN - 0.5, "%s %s: after the cards" % [name, str(case)])
	eq(_plan("phone-16x9", 5, 0).boost_aims, [], "setup and Soak have no aim")
