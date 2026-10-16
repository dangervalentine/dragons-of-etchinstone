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
					if not _apart(ORDER[i], ORDER[j]):
						continue
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


func test_the_safe_area_keeps_clear_of_rounded_corners() -> void:
	# A Pixel 9 Pro held sideways: 118-pixel corners, the camera on the left.
	var window := Vector2(2142, 960)
	var r := 118.0
	var safe := Solver.clear_corners(Rect2(153, 0, 1989, 960), window, [r, r, r, r])
	eq(safe.position.x, 153.0, "the camera already clears the left corners")
	for p in [Vector2(safe.position.x, safe.position.y), Vector2(safe.end.x, safe.position.y), safe.end, Vector2(safe.position.x, safe.end.y)]:
		var centre := Vector2(clampf(p.x, r, window.x - r), clampf(p.y, r, window.y - r))
		ok(p.distance_to(centre) <= r * (1.0 - Solver.CORNER_CLEARANCE) + 0.01, "corner %s is clear of the curve" % str(p))
	eq(Solver.clear_corners(Rect2(40, 40, 920, 520), Vector2(1000, 600), [0, 0, 0, 0]), Rect2(40, 40, 920, 520), "square corners change nothing")


func test_seven_cards_use_two_rows_and_four_use_one() -> void:
	eq(_plan("phone-16x9", 4, 1).hand_rows, 1, "four in a row")
	eq(_plan("phone-16x9", 7, 2).hand_rows, 2, "seven in two rows")


func test_controls_are_big_enough_to_tap() -> void:
	for name in Solver.MATRIX:
		var plan := _plan(name, 7, 2)
		ok(plan.regions.commit.size.y >= T.TAP_MIN and plan.regions.commit.size.x >= T.TAP_MIN, name + " commit")
		ok(plan.regions.actions.size.y >= T.TAP_MIN, name + " actions")
		ok(plan.regions.slots.size.y >= T.TAP_MIN, name + " slots")


func test_play_is_the_bottom_right_of_the_action_column() -> void:
	for name in Solver.MATRIX:
		for sets in [0, 1, 2]:
			var plan := _plan(name, 7 if sets == 2 else 4, sets)
			var a: Rect2 = plan.regions.actions
			var c: Rect2 = plan.regions.commit
			ok(a.encloses(c), "%s %d sets: Play is inside the action column" % [name, sets])
			eq(c.end, a.end, "%s %d sets: in its bottom-right corner" % [name, sets])
			eq(a.end.x, plan.content.end.x, "%s %d sets: the column is at the right edge" % [name, sets])
			ok(c.size.x >= T.TAP_MIN and c.size.y >= T.TAP_MIN, "%s %d sets: Play is a tap target" % [name, sets])


func test_region_order_is_the_same_for_every_step() -> void:
	var a := _plan("desktop", 4, 1)
	var b := _plan("desktop", 7, 2)
	for key in ["header", "encounter", "preview"]:
		eq(a.regions[key], b.regions[key], key + " does not move between steps")
	for plan in [a, b]:
		eq(plan.regions.slots.end.y + Solver.GAP, plan.regions.hand.position.y, "the Hand starts just under the slots")
		eq(plan.regions.slots.position.y, plan.regions.encounter.position.y, "the slots are at the top of the body")
		eq(plan.regions.commit.end, plan.regions.actions.end, "Play keeps its corner of the action column")


func test_larger_screens_are_used_not_left_empty() -> void:
	for name in ["phone-16x9", "phone-tall", "phone-small", "tablet", "desktop"]:
		var plan := _plan(name)
		var used := 0.0
		for key in ORDER:
			if key != "commit":
				used += plan.regions[key].get_area()
		var safe := _safe(name)
		# Hand cards are bound by width, so on taller screens some height has no use
		# but margin under the Hand.
		ok(used >= safe.get_area() * 0.75, "%s: regions cover %d%% of the safe area" % [name, int(100 * used / safe.get_area())])
	ok(_plan("tablet").card_size.x >= _plan("phone-16x9").card_size.x, "cards are no smaller on a tablet")
	var wide := _plan("desktop-ultrawide")
	ok(wide.content.size.x <= T.DESIGN_MAX.x, "content is capped on an ultrawide window")
	ok(absf(wide.content.get_center().x - wide.view.x / 2.0) <= 1.0, "and centred")


## Hand card widths from the layout before feature 005, which gave the field more
## room: cards must never come out smaller than these. Keys are "cards/sets".
const BASELINE_CARD_W := {
	"desktop": {"4/1": 197, "5/1": 160, "7/1": 160, "7/2": 166},
	"desktop-ultrawide": {"4/1": 250, "5/1": 226, "7/1": 159, "7/2": 159},
	"phone-16x9": {"4/1": 197, "5/1": 156, "7/1": 132, "7/2": 137},
	"phone-small": {"4/1": 197, "5/1": 156, "7/1": 132, "7/2": 137},
	"phone-tall": {"4/1": 220, "5/1": 174, "7/1": 123, "7/2": 129},
	"phone-tall-flipped": {"4/1": 220, "5/1": 174, "7/1": 123, "7/2": 129},
	"tablet": {"4/1": 197, "5/1": 214, "7/1": 197, "7/2": 197},
}


func test_hand_cards_are_no_smaller_than_before() -> void:
	for name in BASELINE_CARD_W:
		for key in BASELINE_CARD_W[name]:
			var shape: PackedStringArray = key.split("/")
			var plan := _plan(name, int(shape[0]), int(shape[1]))
			ok(plan.card_size.x >= BASELINE_CARD_W[name][key],
				"%s %s: card width %d, at least %d" % [name, key, plan.card_size.x, BASELINE_CARD_W[name][key]])


## The gap between two rectangles that do not overlap: how far apart their nearest edges are.
func _gap(a: Rect2, b: Rect2) -> float:
	var dx := maxf(b.position.x - a.end.x, a.position.x - b.end.x)
	var dy := maxf(b.position.y - a.end.y, a.position.y - b.end.y)
	return maxf(dx, dy)


func test_regions_have_air() -> void:
	for name in Solver.MATRIX:
		for shape in [[4, 1], [7, 2]]:
			var plan := _plan(name, shape[0], shape[1])
			for i in ORDER.size():
				for j in range(i + 1, ORDER.size()):
					if not _apart(ORDER[i], ORDER[j]):
						continue
					var g := _gap(plan.regions[ORDER[i]], plan.regions[ORDER[j]])
					ok(g >= 12.0, "%s: %s and %s are %.0f apart, at least 12" % [name, ORDER[i], ORDER[j], g])


func test_hand_cards_have_air() -> void:
	for name in Solver.MATRIX:
		for shape in [[4, 1], [5, 1], [7, 2]]:
			var rects: Array = _plan(name, shape[0], shape[1]).card_rects
			for i in rects.size() - 1:
				var a: Rect2 = rects[i]
				var b: Rect2 = rects[i + 1]
				if is_equal_approx(a.position.y, b.position.y):
					var least := 12.0 if shape[0] <= 4 else 10.0
					ok(b.position.x - a.end.x >= least, "%s %s: cards %.0f apart, at least %d" % [name, str(shape), b.position.x - a.end.x, least])


func test_extra_space_goes_to_content() -> void:
	var base := _plan("phone-16x9")
	for name in Solver.MATRIX:
		if name == "upright-browser":
			continue
		var plan := _plan(name)
		ok(plan.card_size.x >= base.card_size.x, name + ": cards no smaller than on a 16:9 phone")
		# A notch or home bar can leave less height than a 16:9 phone has at all.
		if _safe(name).size.y < _safe("phone-16x9").size.y:
			continue
		ok(plan.regions.encounter.size.y >= base.regions.encounter.size.y, name + ": Encounter no shorter than on a 16:9 phone")


func test_no_sets_give_the_band_to_the_hand() -> void:
	eq(Solver.slot_rows({"sets": [{}, {}], "played": null}), 2, "a row per Action Set")
	eq(Solver.slot_rows({"sets": [], "played": {}}), 1, "the recap after a battle")
	eq(Solver.slot_rows({"sets": [], "played": null}), 0, "nothing to show while Soaking the Final Battle")
	for name in Solver.MATRIX:
		var with_row := _plan(name, 8, 1)
		var without := _plan(name, 8, 0)
		eq(without.regions.slots.size.y, 0.0, "%s: no slots" % name)
		eq(without.regions.actions.size.y, float(T.TAP_MIN), "%s: the actions keep one row" % name)
		ok(without.card_size.x >= with_row.card_size.x, "%s: cards are no smaller" % name)


func test_slot_band_and_action_column() -> void:
	for name in Solver.MATRIX:
		for sets in [1, 2]:
			var plan := _plan(name, 4 if sets == 1 else 7, sets)
			var slots: Rect2 = plan.regions.slots
			var actions: Rect2 = plan.regions.actions
			var what := "%s with %d sets" % [name, sets]
			ok(slots.size.y >= Solver.SLOT_BAND_H and slots.size.y <= Solver.SLOT_BAND_MAX, what + ": the band's height")
			if sets == 2:
				eq(slots.size.y, float(Solver.SLOT_BAND_H), what + ": two sets keep the base band")
			eq(actions.size.y, slots.size.y, what + ": the actions are as tall as the slots")
			eq(actions.position.y, slots.position.y, what + ": side by side")
			eq(actions.position.x - slots.end.x, float(Solver.GAP), what + ": a gap between")
			eq(slots.position.x, plan.regions.hand.position.x, what + ": the band starts with the Hand")
			eq(actions.end.x, plan.regions.hand.end.x, what + ": and ends with it")
			var slot_w: float = (slots.size.x - (3 * sets - 1) * T.S) / (3 * sets)
			ok(slot_w >= T.TAP_MIN, "%s: each slot %.0f wide, at least %d" % [what, slot_w, T.TAP_MIN])


func test_no_button_row_under_the_hand() -> void:
	for name in Solver.MATRIX:
		for shape in [[4, 1], [7, 2], [5, 1]]:
			var plan := _plan(name, shape[0], shape[1])
			eq(plan.regions.hand.end.y, plan.content.end.y, "%s %s: the Hand reaches the bottom" % [name, str(shape)])


func test_the_encounter_keeps_its_height() -> void:
	for name in Solver.MATRIX:
		if name == "upright-browser":
			continue
		var m: Array = Solver.MATRIX[name]
		var view: Vector2 = Solver.view_for_window(m[0])
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
	var m: Array = Solver.MATRIX["phone-16x9"]
	var view: Vector2 = Solver.view_for_window(m[0])
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
