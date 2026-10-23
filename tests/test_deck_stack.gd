extends "res://tests/base.gd"
## The Deck on the left side (specs/012): how deep the stack shows, where the top
## card, its panels and the Key Card sit, and how far a zoom grows a panel.

const Solver = preload("res://ui/model/layout_solver.gd")
const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const DeckStack = preload("res://ui/widgets/deck_stack.gd")
const RegionCard = preload("res://ui/widgets/region_card.gd")
const DragonCard = preload("res://ui/widgets/dragon_card.gd")
const Game = preload("res://engine/game.gd")
const ViewState = preload("res://ui/model/view_state.gd")


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
	# 8% of the card's width, the design system's radius-card on its card (specs/019).
	eq(DeckStack.card_radius(190.0), 15, "a Hand card's corners")
	eq(DeckStack.card_radius(400.0), 32, "and a Region Card's, at its own width")


func test_the_face_leaves_the_edges_their_margin() -> void:
	# The face is a card of the Hand's shape, the largest that fits inside the edges'
	# margin, centred there (owner, 2026-10-22).
	eq(DeckStack.face_rect(Vector2(500, 400)), Rect2(104, 0, 268, 376), "the face")
	eq(DeckStack.card_rect(Vector2(500, 400), "face", true), Rect2(104, 0, 268, 376), "zoomed in, the top card is under the face")
	var tall := DeckStack.face_rect(Vector2(400, 900))
	ok(absf(tall.size.x / tall.size.y - T.CARD_ASPECT) < 0.01, "a tall Deck's face is a playing card's shape too")


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
	# Narrow and tall: the face is a card's shape, so the card is as tall as fits under
	# its rise on it.
	var tall := DeckStack.card_rect(Vector2(400, 900), "card", true)
	ok(tall.end.y <= DeckStack.face_rect(Vector2(400, 900)).end.y + 0.5, "a tall Deck: the card stays on the face")
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


## Zoomed in, the Encounter's panel is lifted out of the card as large as fits above
## the reading strip, the card as it is filling the face behind it (owner, 2026-10-22).
func test_the_zoom_lifts_the_panel_over_the_card() -> void:
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
					ok(face.grow(0.5).encloses(at.card) and (absf(at.card.size.x - face.size.x) < 0.5 or absf(at.card.size.y - face.size.y) < 0.5),
						"%s: the card fills the face" % where)
					ok(not at.panel.intersects(at.strip), "%s: clear of the strip" % where)
					ok(absf(at.strip.position.y - at.panel.end.y) < 0.5, "%s: the strip right under the panel" % where)
					ok(at.strip.end.y <= face.end.y + 0.5, "%s: the strip on the face" % where)
					var on_card := RegionCard.panel_rect(at.card.size, key)
					ok(absf(on_card.size.aspect() - at.panel.size.aspect()) < 0.01, "%s: the panel keeps its printed shape" % where)
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


## The Deck shuffled under the card on top (specs/016 contracts/deck-shuffle.md),
## as NextQuest riffles: the cards peel out one after another and back in.
func test_each_card_peels_out_and_back_in_turn() -> void:
	for n in [1, 2, 5]:
		var peaks := []
		for k in n:
			eq(DeckStack.peel_at(k, n, 0.0), 0.0, "%d cards, %d: under the top card at the start" % [n, k])
			ok(is_zero_approx(DeckStack.peel_at(k, n, 1.0)), "%d cards, %d: back under it at the end" % [n, k])
			var best := 0.0
			var at := 0.0
			var t := 0.0
			while t <= 1.0:
				var v := DeckStack.peel_at(k, n, t)
				ok(v >= 0.0 and v <= 1.0, "%d cards, %d at %.2f: between under and out (%.3f)" % [n, k, t, v])
				if v > best:
					best = v
					at = t
				t += 0.01
			ok(best > 0.99, "%d cards, %d: all the way out once (%.3f)" % [n, k, best])
			peaks.append(at)
		var sorted := peaks.duplicate()
		sorted.sort()
		eq(peaks, sorted, "%d cards: out one after another" % n)
	ok(DeckStack.peel_at(1, 5, 0.2) > 0.0 and DeckStack.peel_at(0, 5, 0.2) > 0.0, "the next starts before the last is home")


func test_the_peel_stays_on_the_deck_short_of_the_key_card_at_every_shape() -> void:
	for name in Solver.MATRIX:
		var region: Vector2 = _plan(name).regions.encounter.size
		var whole := Rect2(Vector2.ZERO, region)
		var cr := DeckStack.card_rect(region, "card", true)
		var cards := {"region": cr, "dragon": DeckStack.card_rect(region, "card", false),
			# Raised, as Region 1's card lies at the start until the first reveal.
			"raised": Rect2(cr.position - Vector2(0, DeckStack.rise_room(cr.size)), cr.size)}
		for what in cards:
			var card: Rect2 = cards[what]
			var lift := DeckStack.peel_lift(region, card)
			var out := Rect2(card.position + Vector2(0, lift), card.size)
			ok(whole.grow(0.5).encloses(out), "%s %s: the peeled card stays on the Deck (%s in %s)" % [name, what, out, whole])
			ok(absf(lift) <= DeckStack.peek_h(card.size) * T.SHUFFLE_PEEL + 0.01, "%s %s: out less far than a Key Card rises (%.0f)" % [name, what, lift])
			ok(absf(lift) >= T.DECK_EDGE - 0.01, "%s %s: out far enough to be seen (%.0f)" % [name, what, lift])
		ok(DeckStack.peel_lift(region, cards.region) < 0.0, "%s: out above the card, where a Key Card rises" % name)
		# Raised, out wherever there is more room, above or below.
		var raised: Rect2 = cards.raised
		var reach := DeckStack.peek_h(raised.size) * T.SHUFFLE_PEEL
		eq(absf(DeckStack.peel_lift(region, raised)), maxf(clampf(raised.position.y, 0.0, reach), clampf(region.y - raised.end.y, 0.0, reach)),
			"%s: raised, out where the room is" % name)


func test_only_a_few_cards_peel() -> void:
	eq(DeckStack.peel_count([]), 0, "none from an empty Deck")
	eq(DeckStack.peel_count(["a", "b"]), 2, "a small Deck, all of it")
	eq(DeckStack.peel_count(Array(range(16))), T.SHUFFLE_PEELS, "a full Deck, a few")


## A Deck sized as the play screen holds it, with a Region Card on top.
func _live_deck() -> DeckStack:
	var d := DeckStack.new()
	d.size = Vector2(400, 628)
	d.count = 12
	d.view = "card"
	d._show_top(ViewState.region_card_model(CardDB.new(), 1))
	d._stack_rect = DeckStack.card_rect(d.size, "card", true)
	return d


## Mage Cards face up, as the Deck holds them.
func _faces(n: int) -> Array:
	var g = Game.new(CardDB.new(), {"seed": 1, "difficulty": "normal"})
	return g.deck.slice(0, n).map(func(id): return ViewState.plain_card(g, g.db, id))


func test_finishing_a_shuffle_squares_the_deck() -> void:
	var was: bool = UI.reduced_motion
	UI.reduced_motion = false
	var d := _live_deck()
	var beats := []
	d.reveal_beat.connect(func(b): beats.append(b))
	var top_at := d.region_card.position
	d.shuffle(_faces(7), T.SHUFFLE)
	eq(d._shuffle_t, 0.0, "the shuffle is under way")
	eq(beats, ["shuffle"], "and says so once")
	eq(d._peel_n, T.SHUFFLE_PEELS, "a few cards peel")
	ok(d._peels.all(func(c): return c.get_parent() == d._riffle), "under the top card")
	ok(not d._shuffle_label.visible, "with motion, no words")
	d._shuffle_t = 0.5
	d._place_peels()
	ok(d._peels.any(func(c): return c.visible), "midway, a card is out")
	d.finish()
	eq(d._shuffle_t, -1.0, "finished, the Deck lies square")
	ok(not d._peels.any(func(c): return c.visible), "and every card is back under the top card")
	eq(d.region_card.position, top_at, "the card on top never moved")
	UI.reduced_motion = was
	d.free()


func test_reduced_motion_shuffles_still() -> void:
	var was: bool = UI.reduced_motion
	UI.reduced_motion = true
	var d := _live_deck()
	d.shuffle(_faces(7), T.SHUFFLE)
	eq(d._shuffle_t, -1.0, "nothing is moved")
	ok(not d._peels.any(func(c): return c.visible), "no card peels")
	ok(d._shuffle_label.visible, "the Deck says it was shuffled")
	var words: Label = d._shuffle_label.get_child(0)
	eq(words.text, "Deck shuffled", "in words")
	ok(words.get_theme_font_size("font_size") >= T.TEXT_MIN, "big enough to read")
	ok(Rect2(Vector2.ZERO, d.size).encloses(Rect2(d._shuffle_label.position, d._shuffle_label.size)), "on the Deck")
	d.finish()
	ok(not d._shuffle_label.visible, "finished, the words are gone")
	UI.reduced_motion = was
	d.free()
