extends "res://tests/base.gd"
## The role slots: one full-size slot per role per Action Set, each showing the number
## its card gives there, taken from the engine (contracts/role-slots.md). A slot never
## shows a card's name, and its taps do what the old slots and rail did.

const Game = preload("res://engine/game.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")

const ROLES := ["spell", "element", "boost"]

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
	for s in vs.slots:
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


## The intents the old slot buttons sent: an empty slot selects itself, a filled one
## takes its card back, and against an Enemy a toggle sends the Boost.
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
	for s in vs.slots:
		for key in ["tap", "toggle_tap"]:
			if s.get(key) != null:
				out.append(s[key])
	return out


func test_nothing_placed_shows_three_roles_with_the_next_one_marked() -> void:
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	eq(vs.slots.map(func(s): return s.role), ROLES, "one slot per role")
	eq(vs.slots.map(func(s): return s.state), ["next", "empty", "empty"], "Spell comes next")
	for s in vs.slots:
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
	eq(s.tap, {"type": "take_back", "id": g.hand[0]}, "tap takes it back")
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
	eq(bo.boost_to, "attack" if enemy else null, "the target only against an Enemy")
	eq(bo.counts_to, "attack" if enemy else "move", "it counts toward its target")
	if enemy:
		eq(bo.toggle_tap, {"type": "toggle_boost_to", "set": 0}, "the target icon toggles it")
	for s in vs.slots:
		ok(not s.has("name"), "%s carries no name field" % s.role)
	eq(_slot(vs, 0, "spell").tooltip, "Spell 1: " + db.mage(g.hand[0]).name, "the name lives only in the tooltip")


func test_final_battle_has_six_slots_in_two_sets() -> void:
	var g = _game()
	_to_final(g)
	var d = Draft.new()
	d.reset(2)
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.slots.size(), 6, "three roles in each of two sets")
	eq(vs.slots.map(func(s): return s.set), [0, 0, 0, 1, 1, 1], "set numbers")
	d.tap(g.hand[0])
	d.select_slot(1, "spell")
	d.tap(g.hand[1])
	vs = ViewState.build(g, d, db)
	eq(_slot(vs, 0, "spell").number, _term(g, d, "Spell 1"), "set 1's Spell from the engine")
	eq(_slot(vs, 1, "spell").number, _term(g, d, "Spell 2"), "set 2's Spell from the engine")
	eq(_slot(vs, 1, "boost").toggle_tap, {"type": "toggle_boost_to", "set": 1}, "each set toggles its Boost")


func test_the_recap_after_a_battle_links_role_to_card() -> void:
	var g = _game()
	var d = Draft.new()
	for id in g.hand.slice(0, 3):
		d.tap(id)
	eq(g.play(d.to_action()), "", "the set plays")
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	ok(vs.played != null and vs.sets.is_empty(), "the recap is showing (phase %s)" % g.phase)
	var slots: Array = vs.slots
	eq(slots.map(func(s): return s.role), ["spell", "element", "boost", "reserve"], "roles then the Reserve")
	for s in slots.slice(0, 3):
		eq(s.state, "played", "%s was played" % s.role)
		eq(s.tap, {"type": "inspect", "id": s.card_id}, "%s opens its card" % s.role)
		ok(not s.has("name"), "%s shows no name" % s.role)
		if vs.cards.has(s.card_id):
			eq(vs.cards[s.card_id].played_role, [0, s.role], "the Hand card says what it was played as")
	var reserve: Dictionary = slots[3]
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
			ok(got.has(w), "the slots can send %s" % str(w))
