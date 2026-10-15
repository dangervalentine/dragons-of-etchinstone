extends "res://tests/base.gd"
## Step emphasis: which parts of each card matter in each step, checked against the
## step table in specs/005-playfield-polish/contracts/step-emphasis.md and, where
## the rules decide it, against the engine itself.

const Game = preload("res://engine/game.gd")
const Rules = preload("res://engine/rules.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")

var db = CardDB.new()


func _game(game_seed := 3, difficulty := "normal", extra := {}):
	var opts := {"seed": game_seed, "dragon": "rodving", "difficulty": difficulty}
	opts.merge(extra)
	return Game.new(db, opts)


func _to_final(g) -> void:
	g.phase = "final_journey"
	g.deck.append_array(g.hand)
	g.deck.append_array(g.discard)
	g.hand = []
	g.discard = []
	g._draw(7)


func _pair_in_hand(g) -> Array:
	for a in g.hand:
		for b in g.hand:
			if a != b and db.mage(a).element == db.mage(b).element:
				return [a, b]
	return []


## Every ordered choice of three Hand cards for Spell, Element and Boost.
func _triples(hand: Array) -> Array:
	var out := []
	for a in hand:
		for b in hand:
			for c in hand:
				if a != b and b != c and a != c:
					out.append([a, b, c])
	return out


func _regions(vs: Dictionary, id: String) -> Array:
	return vs.cards[id].focus.regions


func test_focus_is_pure() -> void:
	var g = _game()
	var d = Draft.new()
	d.tap(g.hand[0])
	var a: Dictionary = ViewState.build(g, d, db)
	var b: Dictionary = ViewState.build(g, d, db)
	for id in g.hand:
		eq(a.cards[id].focus, b.cards[id].focus, "same focus for " + id)


func test_setup_has_no_focus() -> void:
	var g = _game()
	g.phase = "setup"
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	for id in vs.hand:
		eq(vs.cards[id].focus.regions, [], "no focus while choosing starting cards")
	eq(vs.next_role, "", "no slot is being filled")


func test_next_slot_drives_hand_focus() -> void:
	var g = _game()
	var d = Draft.new()
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.next_role, "spell", "Spell first")
	for id in g.hand:
		eq(_regions(vs, id), ["basic", "enhanced"], "Spell slot next: actions")
	d.tap(g.hand[0])
	vs = ViewState.build(g, d, db)
	eq(vs.next_role, "element", "then Element")
	for id in g.hand.slice(1):
		eq(_regions(vs, id), ["ether", "initiative"], "Element slot next: Ether and Initiative")
	d.tap(g.hand[1])
	vs = ViewState.build(g, d, db)
	eq(vs.next_role, "boost", "then Boost")
	for id in g.hand.slice(2):
		eq(_regions(vs, id), ["boost"], "Boost slot next: Boost")
	d.tap(g.hand[2])
	vs = ViewState.build(g, d, db)
	eq(vs.next_role, "", "all slots full")


func test_placed_cards_focus_on_their_role() -> void:
	var g = _game()
	var d = Draft.new()
	for id in g.hand.slice(0, 3):
		d.tap(id)
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(_regions(vs, g.hand[1]), ["ether", "initiative"], "the Element")
	eq(_regions(vs, g.hand[2]), ["boost"], "the Boost")


func test_placed_spell_shows_the_action_in_effect() -> void:
	var checked := 0
	for game_seed in range(1, 25):
		var g = _game(game_seed)
		if g.phase != "challenge":
			continue
		for t in _triples(g.hand):
			var d = Draft.new()
			for id in t:
				d.tap(id)
			var r: Dictionary = g.preview(d.to_action())
			if r.has("error"):
				continue
			var vs: Dictionary = ViewState.build(g, d, db)
			eq(_regions(vs, t[0]), ["enhanced"] if r.enhanced else ["basic"],
				"seed %d: the Spell's plate in effect agrees with the engine" % game_seed)
			checked += 1
	ok(checked > 100, "enough sets checked (%d)" % checked)
	var g = _game()
	var d = Draft.new()
	d.tap(g.hand[0])
	eq(_regions(ViewState.build(g, d, db), g.hand[0]), ["basic", "enhanced"], "both plates while no Element is placed")


func test_reserve_boost_only_when_it_counts() -> void:
	var counted := 0
	var not_counted := 0
	for game_seed in range(1, 80):
		var g = _game(game_seed)
		if g.phase != "challenge" or g.encounter().kind != "journey":
			continue
		var enc: Dictionary = g.encounter()
		for t in _triples(g.hand):
			var d = Draft.new()
			for id in t:
				d.tap(id)
			var action: Dictionary = d.to_action()
			var with: Dictionary = g.preview(action)
			if with.has("error"):
				continue
			var s: Dictionary = g._set_stats(action, null)
			s["reserve_boost"] = 0
			var without: Dictionary = Rules.resolve_journey(enc.data, enc.hardship, s)
			var counts: bool = with.move != without.move
			var reserve = g._reserve([action], null)
			var vs: Dictionary = ViewState.build(g, d, db)
			eq(_regions(vs, reserve).has("boost"), counts, "seed %d: the Reserve's Boost lights up exactly when it counts" % game_seed)
			if counts:
				counted += 1
			else:
				not_counted += 1
	ok(counted > 0 and not_counted > 0, "both cases seen (%d counted, %d not)" % [counted, not_counted])


func test_fuse_and_divert() -> void:
	for game_seed in 40:
		var g = _game(game_seed)
		var pair := _pair_in_hand(g)
		if pair.is_empty():
			continue
		var d = Draft.new()
		d.begin_mode("fuse_pick")
		var vs: Dictionary = ViewState.build(g, d, db)
		for id in g.hand:
			eq(_regions(vs, id), ["ether"], "choosing a Fuse: Ether")
		d.pick_for_fuse(pair[0], db)
		d.pick_for_fuse(pair[1], db)
		vs = ViewState.build(g, d, db)
		eq(_regions(vs, pair[0]), ["ether"], "choosing the fused Ether: Ether")
		d.cancel_mode()
		d.begin_mode("divert")
		vs = ViewState.build(g, d, db)
		for id in g.hand:
			eq(_regions(vs, id), [], "Divert: nothing in particular")
		return
	ok(false, "no seed had two cards of one Ether in Hand")


func test_soak_focus_and_mark() -> void:
	for element in ["", "fire", "water", "lightning", "shadow"]:
		var g = _game()
		g.phase = "penalty"
		g.damage_due = 2
		g.damage_element = element
		var vs: Dictionary = ViewState.build(g, Draft.new(), db)
		for id in g.hand:
			var c: Dictionary = vs.cards[id]
			eq(c.focus.regions, ["armor"], "Soak: Armor")
			eq(c.focus.mark == "soaks_more", c.match, "the ×2 mark exactly on matching Armor")
			eq(c.focus.get("damage_element", ""), element, "the damage's Ether travels with it")


func test_upgrade_marks_agree_with_eligibility() -> void:
	var g = _game()
	g.phase = "upgrade"
	g.xp = 2
	g.downgraded = [g.hand[0]]
	var top: String = g.hand[1]
	g.cards[top].level = db.mage(top).levels.size()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	eq(vs.cards[g.hand[0]].focus.regions, [], "a Downgraded card has no focus")
	eq(vs.cards[top].focus.mark, "max_level", "at its highest Level")
	eq(vs.cards[top].focus.regions, ["cost"], "and only the cost is in focus")
	for id in g.hand.slice(2):
		var c: Dictionary = vs.cards[id]
		ok(c.focus.regions.has("cost"), "the cost is in focus")
		if c.eligible:
			eq(c.focus.mark, "affordable", "affordable")
			var mapped := {"upgrade_cost": "cost", "encounter": "key", "hardship": "key"}
			for key in c.alt.changed:
				ok(c.focus.regions.has(mapped.get(key, key)), "what an Upgrade changes is in focus: " + key)
		else:
			eq(c.reason, "Costs %d XP" % g.level_data(id).upgrade_cost, "too dear")
			eq(c.focus.mark, "unaffordable", "and marked so")
			eq(c.focus.regions, ["cost"], "only the cost")


func test_two_action_sets_follow_the_active_slot() -> void:
	var g = _game()
	_to_final(g)
	var d = Draft.new()
	d.reset(2)
	d.select_slot(1, "boost")
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.next_role, "boost", "the slot chosen in the second set")
	for id in g.hand:
		eq(_regions(vs, id), ["boost"], "Hand follows it")


func test_input_region() -> void:
	var g = _game()
	var d = Draft.new()
	eq(ViewState.build(g, d, db).input_region, "hand", "choosing cards")
	for id in g.hand.slice(0, 3):
		d.tap(id)
	var vs: Dictionary = ViewState.build(g, d, db)
	if vs.preview.status == "ready":
		eq(vs.input_region, "commit", "ready to play")
	g = _game()
	g.phase = "penalty"
	g.damage_due = 1
	g.damage_element = ""
	d = Draft.new()
	eq(ViewState.build(g, d, db).input_region, "hand", "choosing what to Soak")
	for id in g.hand:
		if not ViewState.build(g, d, db).soak.covered:
			d.toggle_pick(id)
	eq(ViewState.build(g, d, db).input_region, "commit", "covered")
