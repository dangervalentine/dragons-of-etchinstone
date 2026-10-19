extends "res://tests/base.gd"
## The Deck on the left side (specs/012): how deep the stack shows, where the top
## card, its panels and the Key Card sit, and how far a zoom grows a panel.

const Solver = preload("res://ui/model/layout_solver.gd")
const T = preload("res://ui/theme/tokens.gd")
const DeckStack = preload("res://ui/widgets/deck_stack.gd")
const RegionCard = preload("res://ui/widgets/region_card.gd")
const DragonCard = preload("res://ui/widgets/dragon_card.gd")


func _plan(name: String, final := false) -> Dictionary:
	var m: Array = Solver.MATRIX[name]
	var view := Solver.matrix_view(name)
	var k: float = Solver.stage_for_window(m[0], view).size.x / view.x
	return Solver.solve(view, Solver.matrix_safe(name), 7 if final else 4, 6 if final else 4, m[2] * k,
		m[0].y > m[0].x, final)


func _aspect(r: Rect2) -> float:
	return r.size.x / r.size.y


func test_the_stack_shows_more_edges_for_more_cards() -> void:
	for pair in [[0, 0], [1, 1], [2, 1], [3, 2], [5, 3], [15, 8], [16, 8]]:
		eq(DeckStack.edges(pair[0]), pair[1], "%d cards" % pair[0])
	ok(DeckStack.EDGE_STEP * DeckStack.EDGES_MAX <= T.DECK_EDGE, "the deepest stack fits its margin")


func test_the_face_leaves_the_edges_their_margin() -> void:
	eq(DeckStack.face_rect(Vector2(500, 400)), Rect2(0, 0, 476, 376), "the face")
	eq(DeckStack.card_rect(Vector2(500, 400), "face", 50.0), Rect2(0, 0, 476, 376), "zoomed in, the top card is under the face")


func test_the_key_card_rises_by_its_band_and_strip() -> void:
	var s := Vector2(190, 266)
	eq(DeckStack.peek_h(s), roundf(266 * 0.155) + roundf(266 * 0.09), "card_face's band and strip")


func test_every_shape_has_room_for_the_printed_card_and_the_key_card() -> void:
	for name in Solver.MATRIX:
		var p := _plan(name)
		var region: Vector2 = p.regions.encounter.size
		var card: Vector2 = p.positions[0].card.size
		var ph := DeckStack.peek_h(card)
		var f := DeckStack.face_rect(region)
		var cr := DeckStack.card_rect(region, "card", ph)
		ok(Rect2(Vector2.ZERO, region).encloses(cr), "%s: the zoomed-out card is inside the Deck" % name)
		# The Key Card rises into the room above the card while the Deck dips by the rest.
		var dip := DeckStack.dip(ph)
		ok(cr.position.y + dip >= ph - 0.5, "%s: the Key Card's band and strip show" % name)
		ok(cr.end.y + dip <= region.y + 0.5, "%s: dipping, the card stays on the Deck" % name)
		ok(absf(_aspect(cr) - RegionCard.ASPECT) < 0.01, "%s: zoomed out, the card is printed 5 by 7" % name)
		for kind in ["enemy", "journey"]:
			for i in range(1, 5):
				var key := "%s:%d" % [kind, i]
				var tile := RegionCard.panel_rect(cr.size, key)
				ok(Rect2(Vector2.ZERO, cr.size).encloses(tile), "%s %s: the panel is on the card" % [name, key])
				var k := DeckStack.zoom_scale(f, tile)
				var grown := tile.size * k
				ok(grown.x <= f.size.x + 0.5 and grown.y <= f.size.y + 0.5, "%s %s: zoomed in, it fits the face" % [name, key])
				ok(is_equal_approx(grown.x, f.size.x) or is_equal_approx(grown.y, f.size.y), "%s %s: and fills it one way" % [name, key])


func test_the_dragon_card_zooms_into_its_two_ladders() -> void:
	for name in Solver.MATRIX:
		var p := _plan(name, true)
		var cr := DeckStack.card_rect(p.regions.encounter.size, "card", 0.0)
		ok(absf(_aspect(cr) - RegionCard.ASPECT) < 0.01, "%s: the Dragon Card is printed 5 by 7 too" % name)
		ok(Rect2(Vector2.ZERO, p.regions.encounter.size).encloses(cr), "%s: on the Deck" % name)
		var mp := DragonCard.target_rect(cr.size, "mp")
		var hp := DragonCard.target_rect(cr.size, "hp")
		var card := Rect2(Vector2.ZERO, cr.size)
		ok(card.encloses(mp) and card.encloses(hp), "%s: both on the card" % name)
		ok(not mp.intersects(hp), "%s: they do not overlap" % name)
		ok(mp.end.x <= cr.size.x * 0.35 and hp.position.x >= cr.size.x * 0.65, "%s: MP Tiers down the left, HP Tiers down the right" % name)
		ok(mp.position.y >= cr.size.y * 0.21, "%s: under the row of figures" % name)


## Zoomed in, the Deck rests on the card grown round the Encounter's panel (specs/013
## research R3): the panel as large as fits above the reading strip, the card where
## that puts it, covering the face.
func test_the_zoom_rests_on_the_card_grown_round_its_panel() -> void:
	for name in Solver.MATRIX:
		var f := DeckStack.face_rect(_plan(name).regions.encounter.size)
		var face := Rect2(Vector2.ZERO, f.size)
		for kind in ["enemy", "journey"]:
			for i in range(1, 5):
				var key := "%s:%d" % [kind, i]
				for lines in [1, 3]:
					var at := DeckStack.landing(face, key, lines)
					var where := "%s %s, %d lines" % [name, key, lines]
					ok(face.grow(0.5).encloses(at.panel), "%s: the panel is on the face" % where)
					ok(at.card.grow(0.5).encloses(Rect2(face.position, Vector2(face.size.x, at.strip.position.y))) or at.card.size.x < face.size.x or at.card.size.y < at.strip.position.y,
						"%s: no bare face round the card" % where)
					ok(not at.panel.intersects(at.strip), "%s: clear of the strip" % where)
					ok(is_equal_approx(at.strip.end.y, face.end.y), "%s: the strip along the foot" % where)
					var on_card := RegionCard.panel_rect(at.card.size, key)
					ok(on_card.position.distance_to(at.panel.position - at.card.position) < 0.5 and on_card.size.distance_to(at.panel.size) < 0.5,
						"%s: the panel is the card's own, grown" % where)
					ok(is_equal_approx(at.panel.size.x, face.size.x) or absf(at.panel.end.y - at.strip.position.y) < 0.5 or is_equal_approx(at.panel.size.y, face.size.y - at.strip.size.y),
						"%s: as large as fits" % where)
		var three := DeckStack.landing(face, "journey:1", 3)
		var one := DeckStack.landing(face, "journey:1", 1)
		ok(one.panel.size.y >= three.panel.size.y, "%s: fewer lines, a panel no smaller" % name)


## What lies on the Deck in the card's place (data-model.md "Note").
func test_the_note_sets_out_the_result_with_the_step() -> void:
	eq(DeckStack.note_kinds(null, false), [], "nothing: the card")
	eq(DeckStack.note_kinds({"kind": "mode"}, false), ["mode"], "a step")
	eq(DeckStack.note_kinds(null, true), ["result"], "a result")
	eq(DeckStack.note_kinds({"kind": "soak"}, true), ["result", "soak"], "the result over the Soak")
	eq(DeckStack.note_kinds({"kind": "upgrade"}, true), ["result", "upgrade"], "the result over the XP")


func test_the_hardship_is_the_effect_that_is_not_the_encounters_own() -> void:
	eq(DeckStack.hardship_of({"effects": ["ambush", "ranged"]}, {"effect": "ranged"}), "ambush", "Ambush on a Ranged Enemy")
	eq(DeckStack.hardship_of({"effects": ["ranged"]}, {"effect": "ranged"}), null, "no Hardship")
	eq(DeckStack.hardship_of({"effects": ["night_travel"]}, {"effect": null}), "night_travel", "a Journey's Hardship")
