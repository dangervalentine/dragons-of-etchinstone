extends "res://tests/base.gd"
## The role rail: one compact token per role per Action Set, shaped from the view
## state. It never shows a card's name, and its taps do what the old slots did.

const Game = preload("res://engine/game.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")

const ROLES := ["spell", "element", "boost"]

var db = CardDB.new()


func _game():
	return Game.new(db, {"seed": 3, "dragon": "rodving", "difficulty": "normal"})


func _tokens(vs: Dictionary) -> Array:
	return vs.rail.filter(func(t): return t.role != "boost_to")


func _to_final(g) -> void:
	g.phase = "final_enemy"
	g.deck.append_array(g.hand)
	g.deck.append_array(g.discard)
	g.hand = []
	g.discard = []
	g._draw(7)


## The intents the old slot buttons sent for a view state, worked out the way
## slot_row.gd did: an empty slot selects itself, a filled one takes its card back.
func _slot_intents(vs: Dictionary) -> Array:
	var out := []
	for i in vs.sets.size():
		for role in ROLES:
			var id = vs.sets[i].roles.get(role)
			out.append({"type": "take_back", "id": id} if id != null else {"type": "select_slot", "set": i, "role": role})
		if vs.sets[i].show_boost_to:
			out.append({"type": "toggle_boost_to", "set": i})
	return out


func _taps(vs: Dictionary) -> Array:
	var out := []
	for t in vs.rail:
		if t.tap != null:
			out.append(t.tap)
	return out


func test_nothing_placed_shows_three_roles_with_the_next_one_marked() -> void:
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	var tokens := _tokens(vs)
	eq(tokens.map(func(t): return t.role), ROLES, "one token per role")
	eq(tokens[0].state, "next", "Spell comes next")
	eq(tokens[1].state, "empty", "Element waits")
	eq(tokens[2].state, "empty", "Boost waits")
	for t in tokens:
		eq(t.tap, {"type": "select_slot", "set": 0, "role": t.role}, "%s selects its slot" % t.role)
		eq(t.card_id, null, "%s has no card" % t.role)
		eq(t.tooltip, ViewState.ROLE_NAMES[t.role] + " 1", "%s tooltip" % t.role)


func test_a_placed_card_shows_its_contribution_not_its_name() -> void:
	var g = _game()
	var d = Draft.new()
	for id in g.hand.slice(0, 3):
		d.tap(id)
	var vs: Dictionary = ViewState.build(g, d, db)
	var tokens := _tokens(vs)
	var spell_id: String = g.hand[0]
	var lv: Dictionary = g.level_data(spell_id)
	eq(tokens[0].state, "filled", "Spell is filled")
	eq(tokens[0].card_id, spell_id, "by the first card")
	eq(tokens[0].ether, db.mage(spell_id).element, "tinted by its Ether")
	eq(tokens[0].tap, {"type": "take_back", "id": spell_id}, "tap takes it back")
	eq(tokens[0].contribution, [lv.basic.value, lv.enhanced.value, lv.enhanced.element], "Spell contribution")
	var el: Dictionary = g.level_data(g.hand[1])
	eq(tokens[1].contribution, [db.mage(g.hand[1]).element, el.initiative], "Element contribution")
	eq(tokens[2].contribution, [g.level_data(g.hand[2]).boost], "Boost contribution")
	for t in tokens:
		ok(not t.has("name"), "%s carries no name field" % t.role)
	eq(tokens[0].tooltip, "Spell 1: " + db.mage(spell_id).name, "the name lives only in the tooltip")


func test_a_boost_toggle_follows_the_sets_that_show_one() -> void:
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	var toggles: Array = vs.rail.filter(func(t): return t.role == "boost_to")
	eq(toggles.size(), 1 if vs.sets[0].show_boost_to else 0, "a toggle only against an Enemy")
	for t in toggles:
		eq(t.tap, {"type": "toggle_boost_to", "set": 0}, "toggle intent")
		eq(t.target, vs.sets[0].boost_to, "toggle shows the target")


func test_final_battle_has_six_tokens_in_two_sets() -> void:
	var g = _game()
	_to_final(g)
	var d = Draft.new()
	d.reset(2)
	var vs: Dictionary = ViewState.build(g, d, db)
	var tokens := _tokens(vs)
	eq(tokens.size(), 6, "three roles in each of two sets")
	eq(tokens.map(func(t): return t.set), [0, 0, 0, 1, 1, 1], "set numbers")
	eq(vs.rail.filter(func(t): return t.role == "boost_to").size(), 2, "a toggle for each set against the dragon")


func test_the_recap_after_a_battle_links_role_to_card() -> void:
	var g = _game()
	var d = Draft.new()
	for id in g.hand.slice(0, 3):
		d.tap(id)
	eq(g.play(d.to_action()), "", "the set plays")
	var d2 = Draft.new()
	var vs: Dictionary = ViewState.build(g, d2, db)
	ok(vs.played != null and vs.sets.is_empty(), "the recap is showing (phase %s)" % g.phase)
	var tokens: Array = vs.rail
	eq(tokens.map(func(t): return t.role), ["spell", "element", "boost", "reserve"], "roles then the Reserve")
	for t in tokens.slice(0, 3):
		eq(t.state, "played", "%s was played" % t.role)
		eq(t.tap, {"type": "inspect", "id": t.card_id}, "%s opens its card" % t.role)
		ok(not t.has("name"), "%s shows no name" % t.role)
		if vs.cards.has(t.card_id):
			eq(vs.cards[t.card_id].played_role, [0, t.role], "the Hand card says what it was played as")
	var reserve: Dictionary = tokens[3]
	eq(reserve.state, "kept" if vs.played.reserve_kept else "discarded", "the Reserve's fate")
	if reserve.card_id != null:
		eq(reserve.tap, {"type": "inspect", "id": reserve.card_id}, "the Reserve opens its card")
	else:
		eq(reserve.tap, null, "no Reserve, nothing to open")


func test_taps_match_the_old_slot_intents() -> void:
	var g = _game()
	var d = Draft.new()
	var states := [ViewState.build(g, d, db)]
	d.tap(g.hand[0])
	states.append(ViewState.build(g, d, db))
	d.select_slot(0, "boost")
	d.tap(g.hand[1])
	states.append(ViewState.build(g, d, db))
	for vs in states:
		var want := _slot_intents(vs)
		var got := _taps(vs)
		eq(got.size(), want.size(), "one tap per old intent")
		for w in want:
			ok(got.has(w), "rail can send %s" % str(w))
