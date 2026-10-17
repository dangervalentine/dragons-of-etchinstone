extends "res://tests/base.gd"
## The places of the Hand, in rulebook order (the Reserve, then each set's Element,
## Spell and Boost), each showing the number its card gives there, taken from the
## engine (specs/009 contracts/board-layout.md). A place never shows a card's name.

const Game = preload("res://engine/game.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")

const ROLES := ["element", "spell", "boost"]

var db = CardDB.new()


func _game(game_seed := 3):
	return Game.new(db, {"seed": game_seed, "dragon": "rodving", "difficulty": "normal"})


func _to_final(g) -> void:
	g.phase = "final_enemy"
	g.deck.append_array(g.hand)
	g.deck.append_array(g.discard)
	g.hand = []
	g.discard = []
	g._draw(7)


func _slot(vs: Dictionary, set_index: int, role: String) -> Dictionary:
	for s in vs.places:
		if s.set == set_index and s.role == role:
			return s
	return {}


## The value of the engine's term `label` for the draft as it stands.
func _term(g, d, label: String):
	var e: Dictionary = g.explain_final(d.to_action()) if d.set_count > 1 else g.explain(d.to_action())
	for t in e.get("terms", []):
		if t.label == label:
			return t.value
	return null


func test_nothing_placed_shows_the_four_places_in_rulebook_order() -> void:
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	eq(vs.places.map(func(s): return s.role), ["reserve", "element", "spell", "boost"], "Reserve, Element, Spell, Boost")
	eq(vs.places.map(func(s): return s.state), ["empty", "empty", "next", "empty"], "Spell is the hint")
	eq(vs.floating, g.hand, "every card floats")
	eq(vs.places[0].tap, null, "an empty Reserve waits for a held card")
	for s in vs.places.slice(1):
		eq(s.tap, {"type": "select_slot", "set": 0, "role": s.role}, "%s selects its slot" % s.role)
		eq(s.card_id, null, "%s has no card" % s.role)
		eq(s.number, null, "%s has no number" % s.role)
		eq(s.tooltip, ViewState.ROLE_NAMES[s.role] + " 1", "%s tooltip" % s.role)


func test_a_placed_spell_shows_the_engines_number() -> void:
	var g = _game()
	var d = Draft.new()
	d.tap(g.hand[0])
	var vs: Dictionary = ViewState.build(g, d, db)
	var s := _slot(vs, 0, "spell")
	var enemy: bool = g.encounter().kind == "enemy"
	eq(s.state, "filled", "Spell is filled")
	eq(s.number, _term(g, d, "Spell"), "the number is the engine's Spell term")
	eq(s.counts_to, "attack" if enemy else "move", "it counts toward the Encounter's stat")
	eq(s.tap, {"type": "pick", "id": g.hand[0]}, "tap picks it up")
	eq(s.ether, db.mage(g.hand[0]).element, "edged in its Ether")


func test_the_spell_number_changes_when_the_element_matches() -> void:
	# Find a Hand where a Spell's enhanced Ether is on another card and its
	# enhanced action fits this Encounter.
	var found := false
	for game_seed in range(1, 60):
		var g = _game(game_seed)
		for sp in g.hand:
			for el in g.hand:
				if found or sp == el:
					continue
				var d = Draft.new()
				d.tap(sp)
				var before = _term(g, d, "Spell")
				d.tap(el)
				var after = _term(g, d, "Spell")
				if before == after:
					continue
				found = true
				var d1 = Draft.new()
				d1.tap(sp)
				eq(_slot(ViewState.build(g, d1, db), 0, "spell").number, before, "the basic value first")
				eq(_slot(ViewState.build(g, d, db), 0, "spell").number, after, "then the enhanced value")
	ok(found, "a matching Element was found")


func test_element_and_boost_numbers() -> void:
	var g = _game()
	var d = Draft.new()
	for id in g.hand.slice(0, 3):
		d.tap(id)
	var vs: Dictionary = ViewState.build(g, d, db)
	var el := _slot(vs, 0, "element")
	eq(el.number, g.level_data(g.hand[1]).initiative, "Element shows its Initiative")
	eq(el.ether, db.mage(g.hand[1]).element, "and its Ether")
	eq(el.counts_to, "initiative", "toward Initiative")
	var bo := _slot(vs, 0, "boost")
	eq(bo.number, g.level_data(g.hand[2]).boost, "Boost shows its bonus")
	var enemy: bool = g.encounter().kind == "enemy"
	eq(bo.boost_to, null, "no target chosen yet")
	eq(bo.counts_to, "" if enemy else "move", "it counts toward nothing until a target is chosen")
	if enemy:
		eq(bo.choices.map(func(c): return c.tap), [{"type": "set_boost_to", "set": 0, "to": "attack"},
			{"type": "set_boost_to", "set": 0, "to": "initiative"}], "the two targets to choose from")
	for s in vs.places:
		ok(not s.has("name"), "%s carries no name field" % s.role)
	eq(_slot(vs, 0, "spell").tooltip, "Spell 1: " + db.mage(g.hand[0]).name, "the name lives only in the tooltip")


func test_final_battle_has_six_slots_in_two_sets() -> void:
	var g = _game()
	_to_final(g)
	var d = Draft.new()
	d.reset(2, false)
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.places.size(), 6, "three roles in each of two sets, and no Reserve")
	eq(vs.places.map(func(s): return s.set), [0, 0, 0, 1, 1, 1], "set numbers")
	eq(vs.places.map(func(s): return s.set_start), [false, false, false, true, false, false], "Set 2 starts at its Element")
	d.tap(g.hand[0])
	d.select_slot(1, "spell")
	d.tap(g.hand[1])
	vs = ViewState.build(g, d, db)
	eq(_slot(vs, 0, "spell").number, _term(g, d, "Spell 1"), "set 1's Spell from the engine")
	eq(_slot(vs, 1, "spell").number, _term(g, d, "Spell 2"), "set 2's Spell from the engine")
	eq(_slot(vs, 1, "boost").choices[1].tap, {"type": "set_boost_to", "set": 1, "to": "initiative"}, "each set chooses its own")


func test_the_recap_after_a_battle_links_role_to_card() -> void:
	var g = _game()
	var d = Draft.new()
	for id in g.hand.slice(0, 3):
		d.tap(id)
	eq(g.play(d.to_action()), "", "the set plays")
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	ok(vs.played != null and vs.sets.is_empty(), "the recap is showing (phase %s)" % g.phase)
	var slots: Array = vs.places
	eq(slots.map(func(s): return s.role), ["reserve", "element", "spell", "boost"], "the same order as building")
	for s in slots.slice(1, 4):
		eq(s.state, "played", "%s was played" % s.role)
		eq(s.tap, {"type": "inspect", "id": s.card_id}, "%s opens its card" % s.role)
		ok(not s.has("name"), "%s shows no name" % s.role)
		if vs.cards.has(s.card_id):
			eq(vs.cards[s.card_id].played_role, [0, s.role], "the Hand card says what it was played as")
	var reserve: Dictionary = slots[0]
	eq(reserve.state, "kept" if vs.played.reserve_kept else "discarded", "the Reserve's fate")
	if reserve.card_id != null:
		eq(reserve.tap, {"type": "inspect", "id": reserve.card_id}, "the Reserve opens its card")
	else:
		eq(reserve.tap, null, "no Reserve, nothing to open")


func test_holding_a_card_makes_every_place_a_target() -> void:
	var g = _game()
	var d = Draft.new()
	d.pick(g.hand[0])
	d.put([0, "spell"], g.hand)
	d.pick(g.hand[1])
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.held, g.hand[1], "the held card")
	eq(vs.cards[g.hand[1]].state, "held", "the card says so")
	for s in vs.places:
		eq(s.state, "target", "%s can take it" % s.role)
		var target = "reserve" if s.role == "reserve" else [0, s.role]
		eq(s.tap, {"type": "put", "target": target}, "%s puts it there" % s.role)
	eq(vs.cards[g.hand[0]].place, "0/spell", "the placed card knows its place")


func test_the_last_card_shows_in_the_reserve_place() -> void:
	var g = _game()
	var d = Draft.new()
	for pair in [[0, "element"], [1, "spell"], [2, "boost"]]:
		d.pick(g.hand[pair[0]])
		d.put([0, pair[1]], g.hand)
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.places[0].card_id, g.hand[3], "the fourth card is the Reserve")
	eq(vs.places[0].state, "filled", "filled")
	eq(vs.floating, [], "nothing floats")
	eq(vs.cards[g.hand[3]].place, "reserve", "the card knows it")
	ok(vs.preview.missing.all(func(m): return m.begins_with("Boost target")), "every Role is filled")


func test_nothing_placed_shows_no_outcome() -> void:
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	eq(vs.preview.status, "incomplete", "no outcome until a card is placed")


func test_the_final_journey_has_a_reserve_then_two_sets() -> void:
	var g = _game()
	_to_final(g)
	g.phase = "final_journey"
	var d = Draft.new()
	d.reset(2)
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.places.map(func(s): return s.key), ["reserve", "0/element", "0/spell", "0/boost", "1/element", "1/spell", "1/boost"],
		"the Reserve, then Set 1, then Set 2")
