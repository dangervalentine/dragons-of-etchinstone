extends "res://tests/base.gd"
## The steps shown for each action say exactly what the engine did.

const Game = preload("res://engine/game.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const Sequencer = preload("res://ui/model/sequencer.gd")
const T = preload("res://ui/theme/tokens.gd")
const Undo = preload("res://ui/model/upgrade_undo.gd")

var db = CardDB.new()
var kinds_seen := {}


## Plays one action, builds its steps, and checks them against the engine.
func _act(g, action: Dictionary, call: Callable) -> String:
	var before: Dictionary = ViewState.snapshot(g)
	var err: String = call.call()
	if err != "":
		return err
	var after: Dictionary = ViewState.snapshot(g)
	var steps: Array = Sequencer.build(before, action, g.result, after)
	var state := before
	var total := 0.0
	var reveal := 0.0
	for st in steps:
		state = Sequencer.apply(state, st)
		# The reveal of the next Encounter keeps its own timing (specs/012 R8).
		if Sequencer.REVEAL.has(st.kind):
			reveal += st.duration
		else:
			total += st.duration
		kinds_seen[st.kind] = true
	# The rise, the number and the panel lit, and the zoom (specs/014 FR-012).
	ok(reveal <= 3.0 + 0.001, "%s reveals its Encounter within 3 seconds (%.2f)" % [action.kind, reveal])
	for st in steps:
		if st.kind == "key_peek":
			eq(st.duration, T.KEY_PEEK, "%s: the Key Card's reveal keeps its time" % action.kind)
		if st.kind == "draw":
			# A long sequence is compressed (test_long_sequences_are_compressed...).
			ok(st.duration <= minf(T.DRAW_FLY + T.STAGGER * (st.cards.size() - 1), 1.2) + 0.001,
				"%s: each drawn card flies from the top card, one after another" % action.kind)
	_check_deck_steps(action, before, after, steps)
	for zone in ["hand", "discard", "trash"]:
		var a: Array = state[zone].duplicate()
		var b: Array = after[zone].duplicate()
		a.sort()
		b.sort()
		eq(a, b, "%s after %s in %s" % [zone, action.kind, before.phase])
	eq(state.hand, after.hand, "Hand order after %s" % action.kind)
	if action.kind != "play" and action.kind != "play_final" or before.phase == "final_journey":
		eq(state.deck, after.deck, "deck after %s in %s" % [action.kind, before.phase])
	eq(state.levels, after.levels, "Levels after %s in %s" % [action.kind, before.phase])
	ok(total <= 3.0 + 0.001, "%s fits in 3 seconds (%.2f)" % [action.kind, total])
	if after.region != before.region:
		var names: Array = steps.map(func(s): return s.kind)
		ok(names.find("gather_shuffle") < names.find("stage_banner") and names.find("stage_banner") < names.find("draw"),
			"Region change: gather, banner, draw")
	return ""


func _soak_ids(g) -> Array:
	var ids := []
	var total := 0
	for id in g.hand:
		if total < g.damage_due and not g.downgraded.has(id):
			ids.append(id)
			total += g._soak_value(id)
	return ids


func test_steps_replay_to_the_engine_state_for_whole_games() -> void:
	var games := 0
	for game_seed in 40:
		var g = Game.new(db, {"seed": game_seed, "dragon": db.dragon_ids()[game_seed % 4],
			"difficulty": ["normal", "casual", "hard", "impossible"][game_seed % 4]})
		var guard := 0
		while g.phase != "won" and g.phase != "lost" and guard < 300:
			guard += 1
			var err := ""
			match g.phase:
				"setup":
					var picks: Array = g.setup_offer.slice(0, g.setup_picks)
					err = _act(g, {"kind": "setup", "cards": picks}, func(): return g.choose_setup_cards(picks))
				"challenge":
					if g.diverts == 0 and g.deck.size() > 6 and guard % 5 == 0:
						var id: String = g.hand[3]
						err = _act(g, {"kind": "divert", "cards": [id], "id": id}, func(): return g.divert(id))
						continue
					var a := {"spell": g.hand[0]}
					if g.hand.size() > 1:
						a["element"] = g.hand[1]
					if g.hand.size() > 2:
						a["boost"] = g.hand[2]
					err = _act(g, {"kind": "play", "cards": a.values()}, func(): return g.play(a))
				"penalty", "poison", "final_soak":
					var ids := _soak_ids(g)
					err = _act(g, {"kind": "soak", "cards": ids}, func(): return g.soak(ids))
				"upgrade":
					var done := false
					for id in g.hand:
						var cost = g.level_data(id).upgrade_cost
						if not g.downgraded.has(id) and cost != null and cost <= g.xp:
							err = _act(g, {"kind": "upgrade", "cards": [id], "id": id}, func(): return g.upgrade(id))
							done = true
							break
					if not done:
						var spent: Array = g._action.cards.values()
						if g._action.fuse != null:
							spent.append(g._action.fuse.bottom)
						if g._discard_reserve and g._action.reserve != null:
							spent.append(g._action.reserve)
						err = _act(g, {"kind": "finish", "cards": spent}, func(): return g.finish())
				"final_journey", "final_enemy":
					if g.phase == "final_journey" and not g._regrouped and game_seed % 3 == 0:
						var id: String = g.hand[0]
						err = _act(g, {"kind": "regroup", "cards": [id], "id": id}, func(): return g.regroup(id))
						continue
					var sets := [{}, {}]
					var roles := ["spell", "element", "boost"]
					for i in mini(6, g.hand.size()):
						sets[i / 3][roles[i % 3]] = g.hand[i]
					var cards: Array = sets[0].values() + sets[1].values()
					err = _act(g, {"kind": "play_final", "cards": cards}, func(): return g.play_final({"sets": sets}))
			if err != "":
				errors.append("seed %d refused in %s: %s" % [game_seed, g.phase, err])
				break
		games += 1
	eq(games, 40, "games played")
	for kind in ["play_cards", "tally", "verdict", "gain_xp", "damage", "pay_time", "downgrade", "trash",
			"upgrade", "discard", "gather_shuffle", "stage_banner", "draw", "ending", "knock_out", "poison_pending",
			"zoom_out", "zoom_in", "key_peek", "turn_card"]:
		ok(kinds_seen.has(kind), "saw a %s step" % kind)


func test_a_draft_change_has_no_steps() -> void:
	var g = Game.new(db, {"seed": 1, "difficulty": "normal"})
	var s: Dictionary = ViewState.snapshot(g)
	eq(Sequencer.build(s, {"kind": "draft", "cards": []}, {}, s), [], "nothing to show")


func test_a_draw_takes_one_flight_and_the_stagger() -> void:
	for n in [1, 4, 7]:
		var ids := []
		for i in n:
			ids.append("c%d" % i)
		var steps := []
		Sequencer._draw_step(steps, ids)
		eq(steps[0].duration, minf(T.DRAW_FLY + T.STAGGER * (n - 1), 1.2), "%d cards" % n)


func test_long_sequences_are_compressed_to_three_seconds() -> void:
	var g = Game.new(db, {"seed": 1, "difficulty": "normal"})
	var before: Dictionary = ViewState.snapshot(g)
	before.region = 1
	var after: Dictionary = before.duplicate(true)
	after.region = 2
	var steps: Array = Sequencer.build(before, {"kind": "start", "cards": []}, {}, after)
	var total := 0.0
	for st in steps:
		if not Sequencer.REVEAL.has(st.kind):
			total += st.duration
	ok(total <= 3.0, "within the limit, the reveal aside")


## A game stopped in the Upgrade step with this much XP to spend.
func _upgrading(xp: int):
	var g = Game.new(db, {"seed": 3, "dragon": "rodving", "difficulty": "normal"})
	g.phase = "upgrade"
	g.xp = xp
	return g


func _upgradable(g) -> String:
	for id in g.hand:
		var cost = g.level_data(id).upgrade_cost
		if cost != null and cost <= g.xp:
			return id
	return ""


## Each Upgrade's step says how much XP it spent, for the stars that carry it to
## the card (specs/011 research R7).
func test_an_upgrade_step_carries_the_xp_spent() -> void:
	var g = _upgrading(20)
	var id := _upgradable(g)
	ok(id != "", "a card can be Upgraded")
	var cost: int = g.level_data(id).upgrade_cost
	var before: Dictionary = ViewState.snapshot(g)
	eq(g.upgrade(id), "", "the Upgrade goes through")
	var steps: Array = Sequencer.build(before, {"kind": "upgrade", "cards": [id], "id": id}, {}, ViewState.snapshot(g))
	var up: Array = steps.filter(func(s): return s.kind == "upgrade")
	eq(up.size(), 1, "one Upgrade step")
	eq(up[0].values.get("spent"), cost, "it spent the card's Upgrade cost")


## Undoing an Upgrade gives the XP back as a Downgrade step, with nothing spent.
func test_undo_is_a_downgrade_with_no_spend() -> void:
	var g = _upgrading(20)
	var id := _upgradable(g)
	var entry: Dictionary = Undo.record(g, id)
	g.upgrade(id)
	var before: Dictionary = ViewState.snapshot(g)
	Undo.undo(g, entry)
	var steps: Array = Sequencer.build(before, {"kind": "upgrade", "cards": [id], "id": id}, {}, ViewState.snapshot(g))
	eq(steps.map(func(s): return s.kind), ["downgrade"], "one Downgrade step")
	ok(not steps[0].values.has("spent"), "and no XP spent")


## XP left when the Upgrade step ends is lost, and the steps say how much.
func test_finish_with_unspent_xp_adds_xp_lost() -> void:
	var before: Dictionary = ViewState.snapshot(_upgrading(5))
	var after: Dictionary = before.duplicate(true)
	after.phase = "challenge"
	after.xp = 0
	var steps: Array = Sequencer.build(before, {"kind": "finish", "cards": []}, {}, after)
	var lost: Array = steps.filter(func(s): return s.kind == "xp_lost")
	eq(lost.size(), 1, "one step for the lost XP")
	if not lost.is_empty():
		eq(lost[0].values.amount, 5, "all 5 of it")
		eq(steps[0].kind, "xp_lost", "before anything else moves")
	before = ViewState.snapshot(_upgrading(0))
	after = before.duplicate(true)
	after.phase = "challenge"
	steps = Sequencer.build(before, {"kind": "finish", "cards": []}, {}, after)
	ok(not steps.any(func(s): return s.kind == "xp_lost"), "none when every XP was spent")


## Taking the damage first sends it to the cards chosen, in that order (specs/011
## follow-up), then they Downgrade.
func test_soaking_sends_the_damage_to_the_chosen_cards() -> void:
	for game_seed in range(1, 120):
		var g = Game.new(db, {"seed": game_seed, "dragon": "rodving", "difficulty": "normal"})
		g.phase = "penalty"
		g.damage_due = 2
		g.damage_element = ""
		var picks := []
		var total := 0
		for id in g.hand:
			if total < g.damage_due:
				picks.append(id)
				total += g._soak_value(id)
		var before: Dictionary = ViewState.snapshot(g)
		if g.soak(picks) != "":
			continue
		var steps: Array = Sequencer.build(before, {"kind": "soak", "cards": picks}, {}, ViewState.snapshot(g))
		eq(steps[0].kind, "soak_damage", "the damage moves first")
		eq(steps[0].cards, picks, "to the cards chosen, in order")
		eq(steps[0].values.due, 2, "all of it")
		ok(steps.slice(1).all(func(s): return s.kind == "downgrade" or s.kind == "trash"), "then they Downgrade")
		return
	ok(false, "no seed could Soak 2 damage")


## The Deck's steps (specs/012 contracts/reveal-sequence.md): the next Encounter is
## revealed after every draw that deals a Hand for one, the Key Card first in a
## Region; the view zooms out before the Hand is refilled or a Key Card leaves.
func _check_deck_steps(action: Dictionary, before: Dictionary, after: Dictionary, steps: Array) -> void:
	var kinds: Array = steps.map(func(st): return st.kind)
	var what: String = action.kind
	var reveals: bool = (what in ["start", "setup", "divert", "regroup"]) or (what == "finish" and not (after.phase in ["won", "lost"])) \
		or (what == "play_final" and before.phase == "final_journey" and after.phase == "final_enemy")
	if not reveals:
		ok(not kinds.has("zoom_in") and not kinds.has("key_peek") and not kinds.has("zoom_out"), "%s leaves the Deck as it is" % what)
		return
	ok(kinds.has("zoom_in"), "%s reveals the next Encounter" % what)
	var zoom: Dictionary = steps[kinds.find("zoom_in")]
	eq(zoom.values.target, ViewState.zoom_for(after), "%s zooms into what the after state shows" % what)
	var region: bool = after.phase == "challenge" or after.phase == "poison"
	if region:
		var peek: int = kinds.find("key_peek")
		ok(peek >= 0 and peek == kinds.find("zoom_in") - 1, "%s: the Key Card rises just before the zoom" % what)
		var p: Dictionary = steps[peek]
		eq(p.values.key, after.deck[0], "%s: the Key Card is the top of the Deck" % what)
		eq([p.values.kind, p.values.index, p.values.hardship], [after.encounter.kind, after.encounter.index, after.encounter.hardship],
			"%s: it names the engine's Encounter" % what)
		eq(p.values.target, zoom.values.target, "%s: the panel lit is the one zoomed into" % what)
	else:
		ok(not kinds.has("key_peek"), "%s: no Key Card in the Final Battle" % what)
	if what in ["start", "setup"]:
		ok(not kinds.has("zoom_out"), "%s starts zoomed out" % what)
	else:
		var out: int = kinds.find("zoom_out")
		var first := kinds.size()
		for k in ["discard", "gather_shuffle", "draw"]:
			if kinds.has(k):
				first = mini(first, kinds.find(k))
		ok(out >= 0 and out < first, "%s zooms out before anything leaves or is drawn" % what)
	if what == "setup":
		var turn: int = kinds.find("turn_card")
		ok(turn > kinds.find("gather_shuffle") and turn < kinds.find("stage_banner"), "setup lays the Region Card on top")
		eq(steps[turn].values, {"from": 0, "to": after.region}, "setup: Region 1's card")
	if what == "finish" and after.region != before.region or (what == "finish" and after.phase == "final_journey"):
		var turn: int = kinds.find("turn_card")
		ok(turn > kinds.find("gather_shuffle") and turn < kinds.find("stage_banner"), "a Region change turns the card")
		eq(steps[turn].values.to, "dragon" if after.phase == "final_journey" else after.region, "to the next card")
