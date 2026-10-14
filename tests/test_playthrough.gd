extends "res://tests/base.gd"
## Plays whole games with a simple bot to check the flow never sticks or loses a card.

const Game = preload("res://engine/game.gd")

var db = CardDB.new()


func _greedy_soak(g) -> Array:
	var ids := []
	var total := 0
	for id in g.hand:
		if total >= g.damage_due:
			break
		if not g.downgraded.has(id):
			ids.append(id)
			total += g._soak_value(id)
	return ids


func _sets(g) -> Array:
	var a := {}
	var b := {}
	var roles := ["spell", "element", "boost"]
	for i in mini(6, g.hand.size()):
		(a if i < 3 else b)[roles[i % 3]] = g.hand[i]
	return [a, b]


func _step(g) -> String:
	match g.phase:
		"setup":
			return g.choose_setup_cards(g.setup_offer.slice(0, g.setup_picks))
		"challenge":
			if g.diverts == 0 and g.deck.size() > 6 and g.encounter().hardship == "ambush":
				return g.divert(g.hand[3])
			var a := {"spell": g.hand[0]}
			if g.hand.size() > 1:
				a["element"] = g.hand[1]
			if g.hand.size() > 2:
				a["boost"] = g.hand[2]
			return g.play(a)
		"penalty", "poison", "final_soak":
			return g.soak(_greedy_soak(g))
		"upgrade":
			for id in g.hand:
				if g.upgrade(id) == "":
					return ""
			return g.finish()
		"final_journey", "final_enemy":
			return g.play_final({"sets": _sets(g)})
	return "unknown phase " + g.phase


func _all_cards(g) -> Array:
	var all: Array = g.hand + g.deck + g.discard + g.trash
	all.sort()
	return all


func test_bot_games_always_finish_with_every_card_accounted_for() -> void:
	var expected: Array = db.mage_ids()
	expected.sort()
	var endings := {}
	for game_seed in 60:
		var levels: Array = ["normal", "casual", "hard", "dont_even_try"]
		var g = Game.new(db, {"seed": game_seed, "dragon": db.dragon_ids()[game_seed % 4],
			"difficulty": levels[game_seed % 4]})
		var steps := 0
		while g.phase != "won" and g.phase != "lost" and steps < 400:
			var err := _step(g)
			if err != "":
				errors.append("seed %d refused in %s: %s" % [game_seed, g.phase, err])
				break
			if _all_cards(g) != expected:
				errors.append("seed %d lost or duplicated a card in %s" % [game_seed, g.phase])
				break
			steps += 1
		ok(g.phase == "won" or g.phase == "lost", "seed %d ended in %s" % [game_seed, g.phase])
		endings[g.phase] = endings.get(g.phase, 0) + 1
	print("    bot endings: ", endings)
