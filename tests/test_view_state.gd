extends "res://tests/base.gd"
## The view state: what the screens draw, derived from a game and a draft.

const Game = preload("res://engine/game.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const Glossary = preload("res://ui/model/glossary.gd")

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


## The rulebook's example Encounters are built the same way as the live one.
func test_encounter_model_matches_live_encounter() -> void:
	for game_seed in [3, 7, 11]:
		var g = _game(game_seed)
		var enc: Dictionary = g.encounter()
		var key: String = g.key_card()
		var key_card := {"id": key, "name": db.mage(key).name, "level": g.cards[key].level, "element": db.mage(key).element}
		var live = ViewState.build(g, Draft.new(), db).encounter
		eq(ViewState.encounter_model(db, g.region, enc.kind, enc.index, enc.hardship, key_card), live, "seed %d" % game_seed)


func test_the_encounter_just_played_stays_until_the_next_hand() -> void:
	# Journey 1 (time penalty 2) discards its own Key Card; the face keeps showing it.
	var g = Game.new(db, {"seed": 1, "dragon": "rodving"})
	g.hand = ["DOE-A03", "DOE-A13", "DOE-A11", "DOE-A07"]
	g.deck = ["DOE-A08", "DOE-A05", "DOE-A10", "DOE-A09", "DOE-A12", "DOE-A14", "DOE-A16"]
	var before: Dictionary = ViewState.build(g, Draft.new(), db).encounter
	g.play({"spell": "DOE-A03", "element": "DOE-A13", "boost": "DOE-A11"})
	eq(g.deck[0], "DOE-A10", "the Key Card was paid away")
	eq(g.phase, "upgrade", "upgrading")
	var during: Dictionary = ViewState.build(g, Draft.new(), db).encounter
	eq(during.title, before.title, "same Encounter while upgrading")
	eq(during.key_card.id, "DOE-A08", "same Key Card while upgrading")
	g.finish()
	var after: Dictionary = ViewState.build(g, Draft.new(), db).encounter
	ok(after.key_card.id != "DOE-A08", "the next Encounter once the new Hand is drawn")


func test_setup_cards_preview_the_level_they_would_start_at() -> void:
	var g = _game(3, "casual")
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	var id: String = g.setup_offer[0]
	eq(vs.cards[id].alt.level, g.setup_level, "the chosen Level")
	eq(vs.cards[id].alt.label, "If chosen", "label")


func test_card_parts_explain_themselves_on_hover() -> void:
	var CardView = load("res://ui/widgets/card_view.gd")
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	var v = CardView.new()
	v.size = Vector2(197, 275)
	v.set_model(vs.cards[g.hand[0]])
	v._fit()
	var tip: String = v.part_help(v._face.region_rect("boost").get_center())
	ok(tip.begins_with("Boost:"), "boost: " + tip)
	tip = v.part_help(v._face.region_rect("initiative").get_center())
	ok(tip.begins_with("Initiative:"), "initiative: " + tip)
	v.free()


func test_every_ether_sigil_shares_one_helper_and_the_background_has_none() -> void:
	var CardView = load("res://ui/widgets/card_view.gd")
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	var v = CardView.new()
	v.size = Vector2(197, 275)
	v.set_model(vs.cards[g.hand[0]])
	v._fit()
	for r in v._face.sigil_rects():
		eq(v.part_help(r.get_center()), CardView.ETHER_HELP, "sigil at %s" % str(r))
	var field: Rect2 = v._face.region_rect("field")
	eq(v.part_help(field.end - Vector2(20, 60)), "", "background")
	v.free()


func test_chosen_setup_cards_show_at_their_starting_level() -> void:
	var g = _game(3, "casual")
	var d = Draft.new()
	var id: String = g.setup_offer[0]
	d.picks.append(id)
	var c: Dictionary = ViewState.build(g, d, db).cards[id]
	eq(c.level, g.setup_level, "shown at the chosen Level")
	eq(c.stats, db.mage_level(id, g.setup_level), "with that Level's figures")
	eq(c.alt, null, "nothing more to preview")
	d.picks.erase(id)
	c = ViewState.build(g, d, db).cards[id]
	eq(c.level, g.cards[id].level, "back to its own Level once unchosen")
	eq(c.alt.changed, [], "the preview marks no parts")


func test_a_card_hardship_explains_itself() -> void:
	var CardView = load("res://ui/widgets/card_view.gd")
	for id in db.mage_ids():
		for level in range(1, 5):
			var lv: Dictionary = db.mage_level(id, level)
			if lv.hardship == null:
				continue
			var m: Dictionary = db.mage(id)
			var v = CardView.new()
			v.size = Vector2(197, 275)
			v.set_model({"id": id, "name": m.name, "element": m.element, "level": level, "max_level": 4, "stats": lv})
			v._fit()
			var tip: String = v.part_help(v._face.hardship_rect().get_center())
			ok(tip.begins_with(Glossary.entry(lv.hardship).name + ":"), "hardship: " + tip)
			v.free()
			return
	ok(false, "some card has a Hardship")


func test_a_previewed_hardship_explains_itself() -> void:
	# A card with no Hardship now, previewing a Level that has one.
	var CardView = load("res://ui/widgets/card_view.gd")
	for id in db.mage_ids():
		for level in range(1, 4):
			var now: Dictionary = db.mage_level(id, level)
			var then: Dictionary = db.mage_level(id, level + 1)
			if now.hardship != null or then.hardship == null:
				continue
			var m: Dictionary = db.mage(id)
			var v = CardView.new()
			v.size = Vector2(197, 275)
			v.set_model({"id": id, "name": m.name, "element": m.element, "level": level, "max_level": 4, "stats": now,
				"alt": {"trashed": false, "label": "If chosen", "level": level + 1, "stats": then, "changed": []}})
			v._fit()
			v._show_alt(true)
			var tip: String = v.part_help(v._face.hardship_rect().get_center())
			ok(tip.begins_with(Glossary.entry(then.hardship).name + ":"), "previewed hardship: " + tip)
			v.free()
			return
	ok(false, "some card gains a Hardship")


func test_action_help_names_only_the_actions_a_card_allows() -> void:
	var CardView = load("res://ui/widgets/card_view.gd")
	eq(CardView._action_help("basic", "attack"), "Basic action: the Attack this card gives as the Spell.", "attack")
	eq(CardView._action_help("enhanced", "move"), "Enhanced action: a stronger Move, if the Element supplies the Ether on its corner.", "move")
	ok(CardView._action_help("basic", "flex").contains("Attack or Move"), "either")
	ok(not CardView.hardship_help("storm").contains("Key Card"), "no Key Card preamble")


func test_card_parts_use_the_help_cursor_and_the_rest_the_hand() -> void:
	var CardView = load("res://ui/widgets/card_view.gd")
	var g = _game()
	var v = CardView.new()
	v.size = Vector2(197, 275)
	v.set_model(ViewState.build(g, Draft.new(), db).cards[g.hand[0]])
	v._fit()
	var move := InputEventMouseMotion.new()
	move.position = v._face.region_rect("boost").get_center()
	v._gui_input(move)
	eq(v.mouse_default_cursor_shape, Control.CURSOR_HELP, "over a part")
	ok(v.tooltip_text.begins_with("Boost:"), "its explanation")
	move.position = v._face.region_rect("field").end - Vector2(20, 60)
	v._gui_input(move)
	eq(v.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, "over the background")
	eq(v.tooltip_text, "", "no explanation")
	v.free()


## The lit zone follows where the player's input goes: a Hand card, or the commit
## control once everything is ready; never the rail, and never the preview, which
## only shows what the Hand choices add up to (feature 006, research D9).
func test_the_active_zone_is_the_hand_or_the_commit_control() -> void:
	var g = _game(5, "casual")
	var d = Draft.new()
	var seen := {}
	var guard := 0
	while g.phase != "won" and g.phase != "lost" and guard < 300:
		guard += 1
		var vs: Dictionary = ViewState.build(g, d, db)
		seen[vs.input_region] = true
		ok(vs.input_region in ["hand", "commit"], "%s: %s" % [g.phase, vs.input_region])
		match g.phase:
			"setup":
				g.choose_setup_cards(g.setup_offer.slice(0, g.setup_picks))
			"challenge":
				var hand: Array = g.hand.duplicate()
				d = Draft.new()
				for id in hand.slice(0, mini(3, hand.size())):
					d.tap(id)
				eq(ViewState.build(g, d, db).input_region, "commit", "ready to play: the commit control")
				g.play(d.to_action())
				d = Draft.new()
			"penalty", "poison", "final_soak":
				var ids := []
				var total := 0
				for id in g.hand:
					if total >= g.damage_due:
						break
					ids.append(id)
					total += g._soak_value(id)
				g.soak(ids)
			"upgrade":
				g.finish()
			"final_journey", "final_enemy":
				d = Draft.new()
				d.reset(2)
				for id in g.hand.slice(0, mini(6, g.hand.size())):
					d.tap(id)
				g.play_final(d.to_action())
				d = Draft.new()
			_:
				break
	ok(g.phase == "won" or g.phase == "lost", "the game ran to its end (%s after %d steps)" % [g.phase, guard])
	ok(seen.has("hand") and seen.has("commit"), "both seen over a game")
