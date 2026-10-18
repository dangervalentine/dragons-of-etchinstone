extends "res://tests/base.gd"
## The places of the Hand, in rulebook order (the Reserve, then each set's Element,
## Spell and Boost, then any extras), every card in one from the deal, each labelled
## with its Role and state but never a number (specs/010 contracts/board-layout.md).

const Game = preload("res://engine/game.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const PlaceLabels = preload("res://ui/widgets/place_labels.gd")

var db = CardDB.new()


func _game(game_seed := 3):
	return Game.new(db, {"seed": game_seed, "dragon": "rodving", "difficulty": "normal"})


func _dealt(g, sets := 1, reserve := true):
	var d = Draft.new()
	d.reset(sets, reserve)
	d.deal(g.hand)
	return d


func _to_final(g, phase: String, count: int) -> void:
	g.phase = phase
	g.deck.append_array(g.hand)
	g.deck.append_array(g.discard)
	g.hand = []
	g.discard = []
	g._draw(count)


func _slot(vs: Dictionary, set_index: int, role: String) -> Dictionary:
	for s in vs.places:
		if s.set == set_index and s.role == role:
			return s
	return {}


func test_a_dealt_hand_fills_the_four_places_in_draw_order() -> void:
	var g = _game()
	var vs: Dictionary = ViewState.build(g, _dealt(g), db)
	eq(vs.places.map(func(s): return s.role), ["reserve", "element", "spell", "boost"], "Reserve, Element, Spell, Boost")
	eq(vs.places.map(func(s): return s.card_id), g.hand, "the cards in the order drawn")
	eq(vs.places.map(func(s): return s.index), [0, 1, 2, 3], "each place knows its position")
	eq(vs.unplaced, [], "every card has a place")
	for s in vs.places:
		eq(s.state, "filled", "%s is filled" % s.role)
		eq(s.tap, {"type": "pick", "id": s.card_id}, "%s picks its card up" % s.role)
		for gone in ["number", "counts_to", "choices", "toggle_tap", "boost_to", "ether", "name"]:
			ok(not s.has(gone), "%s carries no %s" % [s.role, gone])
		eq(vs.cards[s.card_id].place, s.key, "the card knows its place")
	eq(_slot(vs, 0, "spell").tooltip, "Spell 1: " + db.mage(g.hand[2]).name, "the name lives only in the tooltip")


func test_a_dealt_hand_shows_an_outcome_at_once() -> void:
	var g = _game()
	var vs: Dictionary = ViewState.build(g, _dealt(g), db)
	if g.encounter().kind == "enemy":
		eq(vs.preview.status, "incomplete", "against an Enemy the Boost still needs aiming")
		ok(vs.preview.missing.all(func(m): return m.begins_with("Boost target")), "and nothing else")
	else:
		eq(vs.preview.status, "ready", "on a Journey the outcome shows at once")


func test_holding_a_card_makes_every_other_place_a_target() -> void:
	var g = _game()
	var d = _dealt(g)
	d.pick(g.hand[1])
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.held, g.hand[1], "the held card")
	for s in vs.places:
		if s.card_id == g.hand[1]:
			eq(s.state, "filled", "its own place stays filled")
			eq(s.tap, {"type": "put_down"}, "and puts it down")
		else:
			eq(s.state, "target", "%s can take it" % s.role)
			eq(s.tap, {"type": "put", "target": {"card": s.card_id}}, "%s trades with it" % s.role)


func test_an_empty_place_takes_a_card() -> void:
	var g = _game()
	var d = _dealt(g)
	d.drop(g.hand[2])
	var vs: Dictionary = ViewState.build(g, d, db)
	var spell := _slot(vs, 0, "spell")
	eq(spell.card_id, null, "the Spell is empty")
	eq(spell.state, "empty", "and says so")
	eq(spell.tap, null, "nothing to pick up")
	d.pick(g.hand[0])
	vs = ViewState.build(g, d, db)
	eq(_slot(vs, 0, "spell").tap, {"type": "put", "target": [0, "spell"]}, "a held card can go there")


func test_the_final_battle_has_two_sets_and_extras() -> void:
	var g = _game()
	_to_final(g, "final_enemy", 8)
	var vs: Dictionary = ViewState.build(g, _dealt(g, 2, false), db)
	eq(vs.places.map(func(s): return s.role), ["element", "spell", "boost", "element", "spell", "boost", "extra", "extra"],
		"no Reserve; two sets, then the extras")
	eq(vs.places.map(func(s): return s.set_start), [false, false, false, true, false, false, false, false], "Set 2 starts at its Element")
	eq(vs.places.map(func(s): return s.card_id), g.hand, "dealt in draw order")
	_to_final(g, "final_journey", 7)
	vs = ViewState.build(g, _dealt(g, 2, true), db)
	eq(vs.places.map(func(s): return s.key), ["reserve", "0/element", "0/spell", "0/boost", "1/element", "1/spell", "1/boost"],
		"the Reserve, then Set 1, then Set 2")


func test_the_recap_after_a_battle_links_role_to_card() -> void:
	var g = _game()
	eq(g.play(_dealt(g).to_action()), "", "the set plays")
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	ok(vs.played != null and vs.sets.is_empty(), "the recap is showing (phase %s)" % g.phase)
	var slots: Array = vs.places
	eq(slots.map(func(s): return s.role), ["reserve", "element", "spell", "boost"], "the same order as building")
	for s in slots.slice(1, 4):
		eq(s.state, "played", "%s was played" % s.role)
		eq(s.tap, {"type": "inspect", "id": s.card_id}, "%s opens its card" % s.role)
	var reserve: Dictionary = slots[0]
	eq(reserve.state, "kept" if vs.played.reserve_kept else "discarded", "the Reserve's fate")


func test_labels_name_the_role_and_never_a_number() -> void:
	var g = _game()
	_to_final(g, "final_enemy", 7)
	var vs: Dictionary = ViewState.build(g, _dealt(g, 2, false), db)
	var positions := []
	for i in vs.places.size():
		positions.append({"label": Rect2(i * 140, 0, 130, 36), "card": Rect2(i * 140, 36, 130, 182)})
	var labels := PlaceLabels.new()
	labels.render(vs, {"positions": positions, "label_h": 36.0})
	var texts := []
	for l in labels.find_children("*", "Label", true, false):
		texts.append(l.text)
	eq(texts, ["ELEMENT 1", "SPELL 1", "BOOST 1", "ELEMENT 2", "SPELL 2", "BOOST 2"], "the Roles, by set; the extra has no name")
	for t in texts:
		ok(not t.is_valid_int(), "no number")
	eq(labels._dividers.size(), 1, "one rule between the sets")
	labels.free()


func test_the_final_battle_grid_names_each_column_once() -> void:
	var g = _game()
	_to_final(g, "final_enemy", 6)
	var vs: Dictionary = ViewState.build(g, _dealt(g, 2, false), db)
	var positions := []
	for i in 6:
		var row := i / 3
		positions.append({"label": Rect2((i % 3) * 140, 0 if row == 0 else 254, 130, 36 if row == 0 else 0),
			"card": Rect2((i % 3) * 140, 36 + row * 218, 130, 182)})
	var labels := PlaceLabels.new()
	labels.render(vs, {"positions": positions, "label_h": 36.0, "set_rows": true})
	var texts := []
	for l in labels.find_children("*", "Label", true, false):
		texts.append(l.text)
	eq(texts, ["ELEMENT", "SPELL", "BOOST"], "one label per column, no set number")
	eq(labels._rules.size(), 1, "a rule between the sets' rows")
	labels.free()
