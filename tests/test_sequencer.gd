extends "res://tests/base.gd"
## The steps shown for each action say exactly what the engine did.

const Game = preload("res://engine/game.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const Sequencer = preload("res://ui/model/sequencer.gd")

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
	for st in steps:
		state = Sequencer.apply(state, st)
		total += st.duration
		kinds_seen[st.kind] = true
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
			"upgrade", "discard", "gather_shuffle", "stage_banner", "draw", "ending", "knock_out", "poison_pending"]:
		ok(kinds_seen.has(kind), "saw a %s step" % kind)


func test_a_draft_change_has_no_steps() -> void:
	var g = Game.new(db, {"seed": 1, "difficulty": "normal"})
	var s: Dictionary = ViewState.snapshot(g)
	eq(Sequencer.build(s, {"kind": "draft", "cards": []}, {}, s), [], "nothing to show")


func test_long_sequences_are_compressed_to_three_seconds() -> void:
	var g = Game.new(db, {"seed": 1, "difficulty": "normal"})
	var before: Dictionary = ViewState.snapshot(g)
	before.region = 1
	var after: Dictionary = before.duplicate(true)
	after.region = 2
	var steps: Array = Sequencer.build(before, {"kind": "start", "cards": []}, {}, after)
	var total := 0.0
	for st in steps:
		total += st.duration
	ok(total <= 3.0, "within the limit")
