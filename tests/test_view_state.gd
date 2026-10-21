extends "res://tests/base.gd"
## The view state: what the screens draw, derived from a game and a draft.

const Game = preload("res://engine/game.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const CardViewScript = preload("res://ui/widgets/card_view.gd")
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
	d.set_boost_to(0, "attack")
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
		var ids: Array = _ids(ViewState.build(g, d, db))
		ok(ids.has("cancel"), "cancel during " + m)
		ok(not ids.has("divert" if m == "divert" else "fuse"), "in place of the action that started " + m)
		ok(not ViewState.build(g, d, db).prompt.primary.enabled, "cannot play during " + m)
		d.cancel_mode()
	var ids: Array = _ids(ViewState.build(g, d, db))
	ok(not ids.has("cancel"), "no cancel outside a mode")


func _ids(vs: Dictionary) -> Array:
	return vs.secondary.map(func(a): return a.id if a != null else null)


func test_cavalier_has_no_fuse_action() -> void:
	var g = _game(3, "normal", {"cavalier": true})
	var ids: Array = _ids(ViewState.build(g, Draft.new(), db))
	eq(ids, [null, "divert"], "Fuse's cell is blank, so Divert keeps its own")


func test_each_action_keeps_its_cell() -> void:
	var g = _game()
	eq(_ids(ViewState.build(g, Draft.new(), db)), ["fuse", "divert"], "Fuse, then Divert")
	var d = Draft.new()
	d.begin_mode("divert")
	eq(_ids(ViewState.build(g, d, db)), ["fuse", "cancel"], "Cancel in Divert's cell")


func test_giving_up_the_reserve_joins_the_action_row() -> void:
	for game_seed in range(1, 400):
		var g = _game(game_seed)
		g.region = 2  # Region 2's first Enemy is Ranged
		var enc: Dictionary = g.encounter()
		if enc.kind != "enemy" or enc.data.ability != "ranged":
			continue
		var d = Draft.new()
		d.deal(g.hand)
		var vs: Dictionary = ViewState.build(g, d, db)
		eq(_ids(vs), ["fuse", "divert", "give_up_reserve"], "a third action after Fuse and Divert")
		eq(vs.action_cells, 4, "so the row has four cells")
		d.give_up_reserve = true
		vs = ViewState.build(g, d, db)
		eq(vs.places[0].state, "given_up", "the Reserve shows as given up")
		ok(vs.secondary[2].active, "and the switch as on")
		eq(d.to_action().ranged_discard, true, "sent to the engine as before")
		var gone: String = g.hand[1]
		g.hand.erase(gone)
		d.drop(gone)
		d.settle(g.hand)
		vs = ViewState.build(g, d, db)
		ok(not _ids(vs).has("give_up_reserve"), "with no Reserve left, the switch goes")
		return
	ok(false, "no seed opened on a Ranged enemy")


func test_a_plain_encounter_keeps_three_cells() -> void:
	var g = _game()
	var d = Draft.new()
	d.deal(g.hand)
	var vs: Dictionary = ViewState.build(g, d, db)
	ok(not _ids(vs).has("give_up_reserve"), "no Give up Reserve")
	eq(vs.action_cells, 3, "Play keeps its half")


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
		eq(vs.prompt.primary.kind, "primary", "Play never warns of the outcome (specs/011 FR-002)")
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


## An Upgrade chosen but not confirmed turns its card to the next Level and takes
## its cost from the XP left; the rest are judged on what is left.
func test_upgrades_chosen_take_from_the_xp_left_until_confirmed() -> void:
	var g = _game()
	g.phase = "upgrade"
	g.xp = 20
	var d = Draft.new()
	var id: String = g.hand[0]
	var cost: int = g.level_data(id).upgrade_cost
	var vs: Dictionary = ViewState.build(g, d, db)
	ok(not vs.cards[id].turned, "not turned before it is chosen")
	eq(vs.prompt.primary.label, "Continue", "nothing chosen: Continue")
	d.toggle_pick(id)
	vs = ViewState.build(g, d, db)
	ok(vs.cards[id].turned, "chosen, it shows its next Level")
	eq(vs.cards[id].state, "selected", "and is marked chosen")
	ok(vs.cards[id].eligible, "and can be tapped again")
	eq(CardViewScript.shown_level(vs.cards[id]), g.cards[id].level + 1, "the next Level")
	eq(vs.xp, 20 - cost, "its cost is taken from the XP left")
	eq(g.xp, 20, "but not spent")
	eq(vs.prompt.primary.label, "Confirm", "Confirm")
	g.xp = cost
	vs = ViewState.build(g, d, db)
	for other in g.hand.slice(1):
		if g.level_data(other).upgrade_cost != null and not vs.cards[other].reason == "Downgraded":
			ok(not vs.cards[other].eligible, "nothing left for another")
	d.toggle_pick(id)
	vs = ViewState.build(g, d, db)
	ok(not vs.cards[id].turned, "chosen again, it turns back")
	eq(vs.xp, cost, "and its XP is given back")


## Tapped again while the XP allows, a card climbs another Level; once it can climb
## no higher, each tap takes a Level back down to where it began, then it climbs again.
func test_upgrade_taps_climb_then_come_back_down() -> void:
	var g = _game()
	g.phase = "upgrade"
	var id = null
	for other in g.hand:
		g.cards[other].level = 1
		if g.level_data(other).upgrade_cost != null and db.mage_level(other, 2).upgrade_cost != null:
			id = other
			break
	ok(id != null, "a card that can rise two Levels from Level 1")
	var first: int = g.level_data(id).upgrade_cost
	var second: int = db.mage_level(id, 2).upgrade_cost
	# Enough for two Levels, not a third.
	var third = db.mage_level(id, 3).upgrade_cost
	g.xp = first + second + (third - 1 if third != null and third > 0 else 0)
	var d = Draft.new()
	var levels := []
	for i in 5:
		var vs: Dictionary = ViewState.build(g, d, db)
		d.step_upgrade(id, vs.cards[id].can_raise)
		vs = ViewState.build(g, d, db)
		levels.append(CardViewScript.shown_level(vs.cards[id]))
	eq(levels, [2, 3, 2, 1, 2], "up while it can, back down to its own Level, then up again")
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.xp, g.xp - first, "one Level's cost taken")
	d.step_upgrade(id, true)
	vs = ViewState.build(g, d, db)
	eq(vs.xp, g.xp - first - second, "two Levels' cost taken")
	eq(vs.cards[id].note, "%d XP" % (first + second), "the card says what both cost")


## A card chosen to Soak shows the Level it will be Downgraded to, or 0 if Trashed.
func test_soak_picks_show_the_level_they_fall_to() -> void:
	var g = _game()
	g.phase = "penalty"
	g.damage_due = 99
	var d = Draft.new()
	var id: String = g.hand[0]
	d.toggle_pick(id)
	var c: Dictionary = ViewState.build(g, d, db).cards[id]
	ok(c.turned, "turned")
	eq(CardViewScript.shown_level(c), g.cards[id].level - 1, "one Level lower, 0 if Trashed")


## A Level 1 card chosen to Soak turns to the shared Trashed back: no face, no
## figures, no tags.
func test_a_card_to_be_trashed_shows_the_trashed_back() -> void:
	var g = _game()
	g.phase = "penalty"
	g.damage_due = 99
	var id: String = g.hand[0]
	g.cards[id].level = 1
	var d = Draft.new()
	d.toggle_pick(id)
	var v = CardViewScript.new()
	v.size = Vector2(197, 275)
	v.set_model(ViewState.build(g, d, db).cards[id])
	v._fit()
	ok(v._back.visible, "the Trashed back")
	ok(not v._face.visible, "and not the face")
	d.toggle_pick(id)
	v.set_model(ViewState.build(g, d, db).cards[id])
	ok(v._face.visible and not v._back.visible, "chosen again, the face")
	v.free()


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


func test_every_ether_sigil_explains_its_own_ether_and_the_background_has_none() -> void:
	var CardView = load("res://ui/widgets/card_view.gd")
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	var v = CardView.new()
	v.size = Vector2(197, 275)
	v.set_model(vs.cards[g.hand[0]])
	v._fit()
	var HelpTip = load("res://ui/widgets/help_tip.gd")
	var ethers: Array = v._face.sigil_ethers()
	var rects: Array = v._face.sigil_rects()
	eq(ethers.size(), rects.size(), "an Ether for every sigil")
	for i in rects.size():
		eq(v.part_help(rects[i].get_center()), HelpTip.text(str(ethers[i])), "sigil at %s" % str(rects[i]))
		eq(v.part_icon(rects[i].get_center()), str(ethers[i]), "sigil icon at %s" % str(rects[i]))
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
				"turned": true, "alt": {"trashed": false, "label": "If Upgraded", "level": level + 1, "stats": then, "changed": []}})
			v._fit()
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
				d.set_boost_to(0, "attack")
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


func _sum(vs: Dictionary, id: String) -> Dictionary:
	for s in vs.math.sums:
		if s.id == id:
			return s
	return {}


func test_the_boost_is_aimed_on_its_card() -> void:
	for game_seed in range(1, 40):
		var g = _game(game_seed)
		if g.encounter().kind != "enemy":
			continue
		var d = Draft.new()
		d.deal(g.hand)
		var vs: Dictionary = ViewState.build(g, d, db)
		eq(d.boost_to[0], null, "neither Attack nor Initiative is chosen")
		eq(vs.preview.missing, ["Boost target"], "it is what is missing")
		ok(not vs.prompt.primary.enabled, "Play waits for it")
		eq(vs.prompt.primary.reason, "Choose whether the Boost adds to Attack or to Initiative.", "and says why")
		eq(vs.prompt.text, "", "no tip while the set is built (specs/013 FR-006)")
		eq(vs.note, null, "and nothing lies on the Deck in the card's place")
		for s in vs.math.sums:
			ok(not s.has("aim"), "the math box aims nothing (specs/011 FR-006)")
		d.cycle_boost_to(0)
		vs = ViewState.build(g, d, db)
		ok(vs.prompt.primary.enabled or vs.preview.status != "incomplete", "once aimed, nothing is missing")
		eq(vs.prompt.text, "", "nor once it is aimed")
		return
	ok(false, "no seed opened on an Enemy")


func test_a_journey_has_no_tip() -> void:
	for game_seed in range(1, 40):
		var g = _game(game_seed)
		if g.encounter().kind != "journey":
			continue
		var d = Draft.new()
		d.deal(g.hand)
		var vs: Dictionary = ViewState.build(g, d, db)
		eq(vs.prompt.text, "", "no tip while the set is built (specs/013 FR-006)")
		for s in vs.math.sums:
			ok(not s.has("aim"), "the Move row aims nothing")
		return
	ok(false, "no seed opened on a Journey")


## Play's look never gives the outcome away (specs/011 FR-002): not for a set that
## Knocks Out the dragon, nor for one below the Final Enemy's first tier.
func test_play_never_warns() -> void:
	for game_seed in range(1, 60):
		var g = _game(game_seed)
		if g.phase != "challenge":
			continue
		var vs: Dictionary = ViewState.build(g, _filled(g), db)
		eq(vs.prompt.primary.kind, "primary", "seed %d: Play looks the same whatever the outcome" % game_seed)


func test_the_math_box_sums_come_from_the_engine() -> void:
	# An Enemy and a Journey: the first seeds that deal each.
	var seen := {}
	for game_seed in range(1, 40):
		var g = _game(game_seed)
		var kind: String = g.encounter().kind
		if seen.has(kind):
			continue
		seen[kind] = true
		var vs: Dictionary = ViewState.build(g, _filled(g), db)
		var e: Dictionary = vs.explain
		var ids: Array = vs.math.sums.map(func(s): return s.id)
		eq(ids, ["attack", "initiative"] if kind == "enemy" else ["move"], kind + ": the sums in order")
		for s in vs.math.sums:
			eq(s.terms, e.terms.filter(func(t): return t.sum == s.id), "%s %s: the engine's terms, in order" % [kind, s.id])
			eq(s.total, e[s.id], "%s %s: the engine's total" % [kind, s.id])
		var enc: Dictionary = g.encounter().data
		if kind == "enemy":
			eq(_sum(vs, "attack").target.value, enc.hp, "Attack is set against the HP")
			eq(_sum(vs, "initiative").target.value, enc.initiative, "Initiative against the Enemy's")
		else:
			var t: Dictionary = _sum(vs, "move").target
			eq(t.value, e.mp, "Move is set against the MP")
			var own: Array = e.terms.filter(func(x): return x.sum == "target")
			eq(t.terms, own if own.size() > 1 else [], "the target's own terms only when Steep makes it a sum")
	ok(seen.has("enemy") and seen.has("journey"), "both kinds were checked")

	# An incomplete set: no total, and the roles still needed.
	var g = _game()
	var d = Draft.new()
	d.tap(g.hand[0])
	var vs: Dictionary = ViewState.build(g, d, db)
	var first: Dictionary = vs.math.sums[0]
	eq(first.total, null, "no total while a role is empty")
	eq(first.missing, ["Element", "Boost"], "the roles still needed")
	ok(first.terms.size() >= 1, "the Spell's term is shown")
	eq(first.result, "", "no verdict yet")

	# The Final Battle: the tier reached.
	_to_final(g)
	var fd = Draft.new()
	fd.reset(2)
	for id in g.hand.slice(0, 6):
		fd.tap(id)
	vs = ViewState.build(g, fd, db)
	var move: Dictionary = _sum(vs, "move")
	eq(move.total, vs.explain.move, "the Final Journey's Move is the engine's")
	ok(move.tier != null and move.tier.index == vs.explain.tier, "the tier reached is shown")


# ---------------------------------------------------------------- the Deck (specs/012)

func test_the_deck_zooms_into_the_encounter_the_key_card_names() -> void:
	var g = _game()
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	var enc: Dictionary = g.encounter()
	eq(g.phase, "challenge", "a normal game starts at the first Encounter")
	eq(vs.zoom, "%s:%d" % [enc.kind, enc.index], "the zoom is the Key Card's Encounter")
	eq(vs.key_face.id, g.deck[0], "the Key Card is the top of the Deck")
	eq(vs.top_card.kind, "region", "a Region Card is on top")
	eq(vs.top_card.region, 1, "turned to Region 1")


func test_through_upgrade_the_deck_keeps_the_encounter_just_played() -> void:
	var g = _game()
	var key: String = g.key_card()
	var enc: Dictionary = g.encounter()
	g.faced = {"key": key, "level": g.cards[key].level, "encounter": enc}
	g.phase = "upgrade"
	# The next card down is a different Key Card, but the table still shows the old one.
	g.deck.push_front(g.deck.pop_back())
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	eq(vs.zoom, "%s:%d" % [enc.kind, enc.index], "the faced Encounter")
	eq(vs.key_face.id, key, "the card that named it")


func test_after_the_cleanup_draw_poison_lifts_the_new_key_card() -> void:
	var g = _game()
	g.faced = {}
	g.phase = "poison"
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	var enc: Dictionary = g.encounter()
	eq(vs.key_face.id, g.deck[0], "the new top card")
	eq(vs.zoom, "%s:%d" % [enc.kind, enc.index], "its Encounter")


func test_the_final_battle_zooms_into_the_dragon_card() -> void:
	var g = _game()
	_to_final(g)
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	eq(vs.top_card.kind, "dragon", "the Dragon Card is on top")
	eq(vs.zoom, "mp", "the Final Journey is its MP Tiers")
	eq(vs.key_face, null, "no Key Card in the Final Battle")
	g.phase = "final_enemy"
	eq(ViewState.build(g, Draft.new(), db).zoom, "hp", "the Final Enemy is its HP Tiers")
	g.phase = "won"
	eq(ViewState.build(g, Draft.new(), db).zoom, "hp", "a won game ended on the HP Tiers")
	g.phase = "lost"
	eq(ViewState.build(g, Draft.new(), db, {"lost_at": "the Final Journey"}).zoom, "mp", "lost on the Final Journey")
	eq(ViewState.build(g, Draft.new(), db, {"lost_at": "the Final Enemy"}).zoom, "hp", "lost to the Final Enemy")


func test_the_deck_has_no_top_card_while_it_is_prepared() -> void:
	var g = _game(3, "hard")
	eq(g.phase, "setup", "hard has a setup step")
	var vs: Dictionary = ViewState.build(g, Draft.new(), db)
	eq(vs.top_card, null, "no Region Card yet")
	eq(vs.zoom, "", "nothing to zoom into")


## What lies on the Deck in the card's place (specs/013 data-model.md).
func test_the_note_follows_the_step() -> void:
	var g = _game(1)
	var d = Draft.new()
	d.deal(g.hand)
	eq(ViewState.build(g, d, db).note, null, "building: the card, no note")
	d.mode = "divert"
	eq(ViewState.build(g, d, db).note, {"kind": "mode"}, "a Divert's step")
	d.mode = "fuse_pick"
	eq(ViewState.build(g, d, db).note, {"kind": "mode"}, "a Fuse's step")
	eq(ViewState.note_for({"mode": "none"}, {"phase": "upgrade", "soak": null}), {"kind": "upgrade"}, "the XP to spend")
	eq(ViewState.note_for({"mode": "none"}, {"phase": "final_soak", "soak": {"due": 3}}), {"kind": "soak"}, "the Soak")
	eq(ViewState.note_for({"mode": "none"}, {"phase": "setup", "soak": null}), {"kind": "setup"}, "the Deck being prepared")
	eq(ViewState.note_for({"mode": "regroup"}, {"phase": "final_soak", "soak": {"due": 3}}), {"kind": "mode"}, "a step comes first")


## A Divert waits for its confirmation (specs/015): a tapped card is only chosen,
## the primary action becomes Divert once one is, and the step says how many
## Diverts are left.
func test_a_divert_is_confirmed_before_it_is_taken() -> void:
	var g = _game()
	var d = Draft.new()
	d.deal(g.hand)
	d.begin_mode("divert")
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(vs.prompt.primary.label, "Divert", "the primary action is the Divert")
	ok(not vs.prompt.primary.enabled, "with no card chosen it waits")
	eq(vs.prompt.count, "%d Diverts left" % (Game.MAX_DIVERTS - g.diverts), "the step says how many are left")
	var id: String = g.hand[0]
	d.choose_for_mode(id)
	vs = ViewState.build(g, d, db)
	ok(vs.prompt.primary.enabled, "a card chosen: Divert can be confirmed")
	eq(vs.cards[id].state, "selected", "the chosen card shows it")
	eq(vs.cards[id].note, "Discard", "and says it will be discarded")
	ok(vs.prompt.text.contains(vs.cards[id].name), "and the step names it")
	d.choose_for_mode(id)
	ok(ViewState.build(g, d, db).prompt.primary.enabled == false, "chosen again, it is put back")


## A refused Play's card is titled with what was refused (specs/015).
func test_a_refused_boost_is_titled() -> void:
	for game_seed in range(1, 60):
		var g = _game(game_seed)
		if g.phase != "challenge" or g.encounter().kind != "enemy":
			continue
		var d = Draft.new()
		d.deal(g.hand)
		var vs: Dictionary = ViewState.build(g, d, db)
		if vs.preview.status == "incomplete" and vs.preview.missing.all(func(m): return m.begins_with("Boost target")):
			eq(vs.prompt.primary.title, "Boost Assignment", "the Boost's aim missing")
			return
	ok(false, "an Enemy set missing only the Boost's aim")
