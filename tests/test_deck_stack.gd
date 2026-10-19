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


## The pile seen from the side (specs/014 contracts/deck-pile.md): as many edges as
## the count says, each the top card's size, stepped and a little off true, the same
## every time, and from nothing but the count.
func test_the_pile_is_drawn_from_its_count_alone() -> void:
	var stack := Rect2(10, 20, 300, 420)
	for n in [0, 1, 2, 5, 16, 40]:
		var rects := DeckStack.edge_rects(stack, n)
		eq(rects.size(), DeckStack.edges(n), "%d cards: %d edges" % [n, DeckStack.edges(n)])
		eq(DeckStack.edge_rects(stack, n), rects, "%d cards: the same each time" % n)
		for j in rects.size():
			var i: int = rects.size() - j
			var r: Rect2 = rects[j]
			eq(r.size, stack.size, "%d cards, edge %d: a whole card" % [n, i])
			var off: Vector2 = r.position - (stack.position + Vector2.ONE * DeckStack.EDGE_STEP * i)
			ok(absf(off.x) <= 1.0 and off.y >= 0.0 and off.y <= 1.0, "%d cards, edge %d: a little off true (%s)" % [n, i, off])
			ok(r.end.x <= stack.end.x + T.DECK_EDGE and r.end.y <= stack.end.y + T.DECK_EDGE, "%d cards, edge %d: within the margin" % [n, i])
	eq(DeckStack.edge_rects(stack, 0), [], "an empty Deck shows no edges")


func test_every_card_has_the_mage_cards_corners() -> void:
	eq(DeckStack.card_radius(190.0), 14, "a Hand card's corners")
	eq(DeckStack.card_radius(400.0), 30, "and a Region Card's, at its own width")


func test_the_face_leaves_the_edges_their_margin() -> void:
	eq(DeckStack.face_rect(Vector2(500, 400)), Rect2(0, 0, 476, 376), "the face")
	eq(DeckStack.card_rect(Vector2(500, 400), "face", true), Rect2(0, 0, 476, 376), "zoomed in, the top card is under the face")


func test_the_key_card_rises_by_its_band_and_strip() -> void:
	var s := Vector2(190, 266)
	eq(DeckStack.peek_h(s), roundf(266 * 0.155) + roundf(266 * 0.09), "card_face's band and strip")


## The room above the Region Card is the Key Card's rise less the Deck's dip, the
## Key Card being the Region Card's own size (specs/014 research R2).
func _room_ok(cr: Rect2, label: String) -> void:
	var ph := DeckStack.peek_h(cr.size)
	ok(cr.position.y >= ph - DeckStack.dip(ph) - 0.5, "%s: room for the Key Card's rise" % label)


func test_the_card_leaves_room_for_a_key_card_of_its_own_size() -> void:
	# Wide and short: the card is as tall as fits under its rise, both ways of the dip.
	for deck in [Vector2(600, 500), Vector2(300, 160), Vector2(500, 300)]:
		var f := DeckStack.face_rect(deck)
		var cr := DeckStack.card_rect(deck, "card", true)
		_room_ok(cr, "%s" % deck)
		ok(cr.end.y <= f.size.y + 0.5, "%s: and the card stays on the face" % deck)
		var ph := DeckStack.peek_h(cr.size)
		ok(cr.position.y - (ph - DeckStack.dip(ph)) < 2.5, "%s: no more room than that" % deck)
		ok(absf(_aspect(cr) - RegionCard.ASPECT) < 0.01, "%s: printed 5 by 7" % deck)
	# Narrow and tall: as wide as the face, as before.
	var tall := DeckStack.card_rect(Vector2(400, 900), "card", true)
	eq(tall.size.x, DeckStack.face_rect(Vector2(400, 900)).size.x, "a tall Deck: the card is as wide as the face")
	_room_ok(tall, "tall")
	# The Dragon Card has nothing rising from under it.
	var dragon := DeckStack.card_rect(Vector2(600, 500), "card", false)
	eq(dragon.size.y, DeckStack.face_rect(Vector2(600, 500)).size.y, "the Dragon Card fills the face's height")


func test_the_key_card_is_the_region_cards_size_and_lines_up_with_it() -> void:
	for deck in [Vector2(600, 500), Vector2(400, 900), Vector2(300, 160)]:
		var cr := DeckStack.card_rect(deck, "card", true)
		var rest := DeckStack.key_rect(deck, false)
		var up := DeckStack.key_rect(deck, true)
		eq(rest.size, cr.size, "%s: as big as the Region Card" % deck)
		eq(rest.position, cr.position, "%s: at rest, under it exactly" % deck)
		eq(up.position.x, cr.position.x, "%s: raised, its sides on the Region Card's" % deck)
		var ph := DeckStack.peek_h(cr.size)
		ok(absf(up.position.y - (cr.position.y + DeckStack.dip(ph) - ph)) < 0.01, "%s: raised by its band and strip, less the dip" % deck)
		ok(up.position.y >= -0.5, "%s: and still inside the Deck" % deck)


func test_every_shape_has_room_for_the_printed_card_and_the_key_card() -> void:
	for name in Solver.MATRIX:
		var p := _plan(name)
		var region: Vector2 = p.regions.encounter.size
		var f := DeckStack.face_rect(region)
		var cr := DeckStack.card_rect(region, "card", true)
		var ph := DeckStack.peek_h(cr.size)
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
		var cr := DeckStack.card_rect(p.regions.encounter.size, "card", false)
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
					ok(absf(at.strip.position.y - at.panel.end.y) < 0.5, "%s: the strip right under the panel" % where)
					ok(at.strip.end.y <= face.end.y + 0.5, "%s: the strip on the face" % where)
					var on_card := RegionCard.panel_rect(at.card.size, key)
					ok(on_card.position.distance_to(at.panel.position - at.card.position) < 0.5 and on_card.size.distance_to(at.panel.size) < 0.5,
						"%s: the panel is the card's own, grown" % where)
					ok(is_equal_approx(at.panel.size.x, face.size.x) or is_equal_approx(at.panel.size.y, face.size.y - at.strip.size.y),
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
