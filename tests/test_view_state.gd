extends "res://tests/base.gd"
## The view state: what the screens draw, derived from a game and a draft.

const Game = preload("res://engine/game.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")

var db = CardDB.new()


func _game(game_seed := 3, difficulty := "normal", extra := {}):
	var opts := {"seed": game_seed, "dragon": "rodving", "difficulty": difficulty}
	opts.merge(extra)
	return Game.new(db, opts)


func _filled(g) -> Object:
	var d = Draft.new()
	for id in g.hand.slice(0, 3):
		d.tap(id)
	return d


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


func test_building_twice_gives_the_same_state() -> void:
	var g = _game()
	var d = _filled(g)
	eq(ViewState.build(g, d, db), ViewState.build(g, d, db), "deterministic")
	eq(ViewState.snapshot(g), ViewState.snapshot(g), "snapshot too")


func test_card_states_for_an_action_set() -> void:
	var g = _game()
	var d = _filled(g)
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.cards[g.hand[0]].state, "assigned", "placed card")
	eq(vs.cards[g.hand[0]].role, [0, "spell"], "its role")
	eq(vs.cards[g.hand[3]].state, "reserve", "the card left over is the Reserve")
	eq(vs.hand, g.hand, "Hand order")
	eq(vs.piles.deck, g.deck.size(), "deck count")
	eq(vs.sets.size(), 1, "one Action Set in a Region")


func test_fused_pair_and_fuse_eligibility() -> void:
	for game_seed in 40:
		var g = _game(game_seed)
		var pair := _pair_in_hand(g)
		if pair.is_empty():
			continue
		var d = Draft.new()
		d.begin_mode("fuse_pick")
		d.pick_for_fuse(pair[0], db)
		var vs: Dictionary = ViewState.build(g, d, db)
		eq(vs.cards[pair[0]].state, "selected", "first pick is marked")
		for id in g.hand:
			if db.mage(id).element != db.mage(pair[0]).element:
				ok(not vs.cards[id].eligible, "other Ethers cannot be tucked")
				eq(vs.cards[id].reason, "Other Ether", "and say why")
		eq(vs.prompt.step, "Fuse · step 2 of 3", "step is named")
		d.pick_for_fuse(pair[1], db)
		ok(ViewState.build(g, d, db).fuse_elements, "then the Ether choice")
		d.choose_fuse_element(db.mage(pair[0]).element)
		vs = ViewState.build(g, d, db)
		eq(vs.cards[pair[1]].state, "fused_bottom", "tucked card")
		eq(vs.cards[pair[0]].fuse.part, "top", "top card knows it is fused")
		return
	ok(false, "no seed had two cards of one Ether in Hand")


func test_cancel_is_offered_in_every_mode() -> void:
	var g = _game()
	var d = Draft.new()
	for m in ["divert", "fuse_pick"]:
		d.begin_mode(m)
		var ids: Array = ViewState.build(g, d, db).secondary.map(func(a): return a.id)
		ok(ids.has("cancel"), "cancel during " + m)
		ok(not ViewState.build(g, d, db).prompt.primary.enabled, "cannot play during " + m)
		d.cancel_mode()
	var ids: Array = ViewState.build(g, d, db).secondary.map(func(a): return a.id)
	ok(not ids.has("cancel"), "no cancel outside a mode")


func test_cavalier_has_no_fuse_action() -> void:
	var g = _game(3, "normal", {"cavalier": true})
	var ids: Array = ViewState.build(g, Draft.new(), db).secondary.map(func(a): return a.id)
	ok(not ids.has("fuse"), "absent, not disabled")
	ok(ids.has("divert"), "Divert is still there")


func test_incomplete_preview_names_the_empty_slots() -> void:
	var g = _game()
	var d = Draft.new()
	d.tap(g.hand[0])
	var p: Dictionary = ViewState.build(g, d, db).preview
	eq(p.status, "incomplete", "not an error")
	eq(p.missing, ["Element", "Boost"], "what is missing")


func test_encounter_model_lists_effects() -> void:
	var seen := {}
	for game_seed in 80:
		var g = _game(game_seed)
		g.region = 2 + game_seed % 3
		var e: Dictionary = ViewState.build(g, Draft.new(), db).encounter
		var enc: Dictionary = g.encounter()
		var expected := 0
		for x in [enc.hardship, enc.data.get("ability"), enc.data.get("peril")]:
			if x != null:
				expected += 1
				ok(e.effects.has(x), "effect %s listed" % x)
				seen[x] = true
		eq(e.effects.size(), expected, "no extra effects")
		eq(e.key_card.id, g.key_card(), "Key Card")
	ok(seen.size() >= 6, "saw a spread of effects (%d)" % seen.size())


func test_preview_figures_are_the_engines_and_knock_out_is_predicted() -> void:
	var compared := 0
	for game_seed in 30:
		var g = _game(game_seed, ["normal", "hard", "impossible"][game_seed % 3])
		var steps := 0
		while g.phase != "won" and g.phase != "lost" and steps < 300:
			steps += 1
			match g.phase:
				"setup":
					g.choose_setup_cards(g.setup_offer.slice(0, g.setup_picks))
				"challenge":
					var d = _filled(g)
					var r: Dictionary = g.preview(d.to_action())
					var p: Dictionary = ViewState.preview(g, d)
					if r.has("error"):
						ok(p.status != "ready", "an engine refusal is never shown as ready")
						g.phase = "lost"
						continue
					eq(p.comparisons[0].value, r.get("attack", r.get("move")), "first total")
					eq(p.verdict, r.outcome, "verdict")
					eq(p.rewards.xp, r.xp, "xp")
					var predicted: bool = p.costs.any(func(c): return c.id == "knock_out")
					g.play(d.to_action())
					eq(predicted, g.result.knocked_out, "Knock Out warning, seed %d" % game_seed)
					compared += 1
				"penalty", "poison", "final_soak":
					var ids := []
					var total := 0
					for id in g.hand:
						if total < g.damage_due and not g.downgraded.has(id):
							ids.append(id)
							total += g._soak_value(id)
					g.soak(ids)
				"upgrade":
					g.finish()
				_:
					g.phase = "lost"
	ok(compared > 100, "compared %d positions" % compared)


func test_final_battle_preview_matches_engine_and_flags_defeat() -> void:
	var fatal_seen := false
	for game_seed in 20:
		var g = _game(game_seed, "hard")
		_to_final(g)
		var d = Draft.new()
		d.reset(2)
		for id in g.hand.slice(0, 6):
			d.tap(id)
		var r: Dictionary = g.preview_final(d.to_action())
		var vs: Dictionary = ViewState.build(g, d, db)
		eq(vs.sets.size(), 2, "two Action Sets")
		eq(vs.preview.comparisons[0].value, r.move, "total Move")
		eq(vs.preview.tier, r.tier, "tier")
		eq(vs.preview.fatal, r.tier < 0, "fatal exactly when below the first tier")
		eq(vs.prompt.primary.kind, "warning" if r.tier < 0 else "primary", "the primary action warns")
		ok(vs.prompt.primary.enabled, "losing on purpose is allowed")
		fatal_seen = fatal_seen or r.tier < 0
	ok(fatal_seen, "at least one seed fell below the first tier")


func test_soak_step_marks_cards_and_covers_damage() -> void:
	var g = _game()
	g.phase = "penalty"
	g.damage_due = 2
	g.damage_element = ""
	g.downgraded = [g.hand[3]]
	var d = Draft.new()
	var vs: Dictionary = ViewState.build(g, d, db)
	ok(not vs.prompt.primary.enabled, "not covered yet")
	ok(not vs.cards[g.hand[3]].eligible, "a Downgraded card cannot Soak again")
	eq(vs.cards[g.hand[0]].note, "Soaks %d" % g._soak_value(g.hand[0]), "each card shows what it Soaks")
	for id in g.hand.slice(0, 3):
		if not ViewState.build(g, d, db).soak.covered:
			d.toggle_pick(id)
	vs = ViewState.build(g, d, db)
	ok(vs.soak.covered, "covered")
	ok(vs.prompt.primary.enabled, "can confirm exactly when covered")
	eq(vs.cards[d.picks[0]].selection_order, 0, "pick order")


func test_upgrade_step_explains_what_cannot_be_upgraded() -> void:
	var g = _game()
	g.phase = "upgrade"
	g.xp = 1
	g.downgraded = [g.hand[0]]
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	eq(vs.cards[g.hand[0]].reason, "Downgraded", "downgraded")
	for id in g.hand.slice(1):
		var cost = g.level_data(id).upgrade_cost
		eq(vs.cards[id].eligible, cost != null and cost <= 1, "affordable or not")
		if cost != null and cost > 1:
			eq(vs.cards[id].reason, "Costs %d XP" % cost, "says the cost")
	ok(vs.prompt.primary.enabled, "can always continue")


func test_ending_score_breakdown_adds_up() -> void:
	var g = _game()
	g.trash.append(g.deck.pop_back())
	g.cards[g.hand[0]].level = 4
	g.phase = "won"
	var e: Dictionary = ViewState.build(g, Draft.new(), db).ending
	eq(e.score, g.score(), "total equals the engine's score")
	var sum := 0
	for row in e.rows:
		sum += row.points
	eq(sum, e.score, "rows add up")
	eq(e.trashed, 1, "trashed cards counted")
	g.phase = "lost"
	g.result = {"move": 3, "tier": -1}
	e = ViewState.build(g, Draft.new(), db, {"lost_at": "the Final Journey"}).ending
	ok(not e.won and e.why != "" and e.where == "the Final Journey", "a loss says where and why")
