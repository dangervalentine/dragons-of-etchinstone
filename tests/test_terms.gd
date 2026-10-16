extends "res://tests/base.gd"
## The engine's terms: the lines behind each result add up to its totals, and adding
## them changes nothing else (FR-010, SC-002).

const Game = preload("res://engine/game.gd")
const Rules = preload("res://engine/rules.gd")

const TOTALS := {"attack": "attack", "initiative": "initiative", "move": "move",
	"target": "mp", "damage": "damage", "time": "time_penalty"}

var db = CardDB.new()
var _seen := {}


## A game whose Key Card is `key` at `level`, in `region`, with `hand` as the Hand.
func _game(game_seed: int, region: int, key: String, level: int, hand: Array):
	var g = Game.new(db, {"seed": game_seed, "dragon": "rodving"})
	g.region = region
	g.hand = hand.duplicate()
	g.deck = [key]
	for id in db.mage_ids():
		if id != key and not hand.has(id):
			g.deck.append(id)
	g.discard = []
	g.cards[key].level = level
	g.phase = "challenge"
	return g


## Every Action Set the Hand allows: each Spell with each Element and each Boost,
## both Boost targets against an Enemy, and the Ranged dodge where it applies.
func _sets(g) -> Array:
	var out := []
	var enemy: bool = g.encounter().kind == "enemy"
	var ranged: bool = enemy and g.encounter().data.ability == "ranged"
	for sp in g.hand:
		for el in g.hand:
			for bo in g.hand:
				if sp == el or sp == bo or el == bo:
					continue
				for to in (["attack", "initiative"] if enemy else ["attack"]):
					var a := {"spell": sp, "element": el, "boost": bo, "boost_to": to}
					out.append(a)
					if ranged:
						var b := a.duplicate()
						b["ranged_discard"] = true
						out.append(b)
	return out


## Check one explanation against its preview; `what` names the case.
func _check(r: Dictionary, p: Dictionary, what: String, final := false) -> void:
	var sums := {}
	for t in r.terms:
		ok(t.has_all(["sum", "label", "source", "value", "card", "note"]), what + ": term keys")
		ok(t.value != 0, what + ": no zero term (%s)" % t.label)
		sums[t.sum] = sums.get(t.sum, 0) + t.value
		_seen[t.label] = true
		if "Ranged" in t.note:
			_seen["ranged_note"] = true
		if "fused" in t.note:
			_seen["fused_note"] = true
	for s in sums:
		eq(sums[s], int(r[TOTALS[s]]), "%s: %s adds up" % [what, s])
	for s in TOTALS:
		var key: String = TOTALS[s]
		if s == "target" or not r.has(key) or int(r[key]) == 0:
			continue
		ok(sums.has(s), "%s: non-zero %s has its terms" % [what, s])
	for k in p:
		if not ["terms"].has(k):
			eq(r.get(k), p[k], "%s: %s unchanged" % [what, k])
	eq(r.complete, true, what + ": complete")
	if r.get("poison", 0) > 0:
		_seen["poison"] = true


func test_terms_add_up_for_every_encounter_and_set() -> void:
	var ids: Array = db.mage_ids()
	ids.sort()
	for game_seed in range(1, 4):
		var rng := RandomNumberGenerator.new()
		rng.seed = game_seed
		for region in range(1, 5):
			for key in ids:
				for level in range(1, 5):
					var pool := ids.duplicate()
					pool.erase(key)
					var hand := []
					for i in 4:
						hand.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
					var g = _game(game_seed, region, key, level, hand)
					for id in hand:
						g.cards[id].level = rng.randi_range(1, 4)
					for a in _sets(g):
						var p: Dictionary = g.preview(a)
						if p.has("error"):
							continue
						var what := "seed %d r%d %s L%d %s" % [game_seed, region, key, level, str(a)]
						_check(g.explain(a), p, what)
						if p.has("mp") and p.mp != g.encounter().data.mp.value:
							_seen["Steep"] = true
	for label in ["Armor", "Night Travel", "Reserve", "Ambush", "Early damage"]:
		ok(_seen.has(label), "a %s term was reached" % label)
	ok(_seen.has("Storm") or _seen.has("Hazards"), "a Storm or Hazards term was reached")
	ok(_seen.has("Steep"), "a Steep target was reached")
	ok(_seen.has("ranged_note"), "a Ranged early hit was reached")
	ok(_seen.has("poison"), "a Poison result was reached")


func test_steep_target_is_a_sum() -> void:
	var g = _game(1, 1, "DOE-A08", 2, ["DOE-A03", "DOE-A13", "DOE-A11", "DOE-A07"])
	var journey := {"mp": {"value": 10, "element": "fire"}, "time_penalty": 2, "peril": "steep", "xp": 3}
	var s := {"spell": g.level_data("DOE-A03"), "element": "fire", "initiative": 3, "boost": 2,
		"reserve_boost": 3}
	var r := Rules.resolve_journey(journey, null, s)
	var target := 0
	var labels := []
	for t in r.terms:
		if t.sum == "target":
			target += t.value
			labels.append(t.label)
	eq(target, r.mp, "target adds up to the MP")
	ok(labels.has("Steep"), "Steep is a line of the target")


func test_an_incomplete_set_explains_the_terms_so_far() -> void:
	var g = _game(1, 1, "DOE-A15", 2, ["DOE-A03", "DOE-A13", "DOE-A11", "DOE-A07"])
	var a := {"spell": "DOE-A03"}
	ok(g.preview(a).has("error"), "preview refuses a lone Spell")
	var r: Dictionary = g.explain(a)
	eq(r.complete, false, "incomplete")
	var spell := 0
	var attack := 0
	for t in r.terms:
		if t.source == "spell":
			spell += t.value
		if t.sum == "attack":
			attack += t.value
	ok(spell > 0, "the Spell term is there")
	eq(attack, r.attack, "the attack sum is the Spell so far")
	eq(r.attack, spell, "Attack is the Spell alone")


func test_a_fused_element_is_noted() -> void:
	# Find a Hand with a same-Ether pair and a Spell enhanced by that Ether.
	var ids: Array = db.mage_ids()
	ids.sort()
	var found := false
	for key in ids:
		if found:
			break
		for sp in ids:
			if found or sp == key:
				continue
			var enh: String = db.mage_level(sp, 2).enhanced.element
			var pair := []
			for id in ids:
				if id != key and id != sp and db.mage(id).element != enh and pair.size() < 2:
					if pair.is_empty() or db.mage(id).element == db.mage(pair[0]).element:
						pair.append(id)
			if pair.size() < 2:
				continue
			var boost := ""
			for id in ids:
				if not [key, sp, pair[0], pair[1]].has(id):
					boost = id
					break
			var g = _game(1, 1, key, 2, [sp, pair[0], pair[1], boost])
			var a := {"spell": sp, "element": pair[0], "boost": boost,
				"fuse": {"top": pair[0], "bottom": pair[1], "element": enh}}
			var p: Dictionary = g.preview(a)
			if p.has("error") or not p.enhanced:
				continue
			found = true
			var r: Dictionary = g.explain(a)
			_check(r, p, "fused")
			ok(_seen.has("fused_note"), "the fused card's term says it was fused")
	ok(found, "a fused case was built")


func test_final_battle_terms_add_up() -> void:
	for game_seed in range(1, 4):
		var g = Game.new(db, {"seed": game_seed, "dragon": "rodving"})
		g.deck.append_array(g.hand)
		g.hand = []
		g._draw(7)
		for phase in ["final_journey", "final_enemy"]:
			g.phase = phase
			var h: Array = g.hand
			var cases := 0
			for i in range(0, h.size() - 5):
				for to in ["attack", "initiative"]:
					var sets := [
						{"spell": h[i], "element": h[i + 1], "boost": h[i + 2], "boost_to": to},
						{"spell": h[i + 3], "element": h[i + 4], "boost": h[i + 5], "boost_to": "attack"},
					]
					var a := {"sets": sets}
					var p: Dictionary = g.preview_final(a)
					if p.has("error"):
						continue
					cases += 1
					_check(g.explain_final(a), p, "final %s seed %d" % [phase, game_seed], true)
			ok(cases > 0, "final cases ran")
		# Incomplete: only the first set's Spell.
		var r: Dictionary = g.explain_final({"sets": [{"spell": g.hand[0]}, {}]})
		eq(r.complete, false, "final incomplete")
		var attack := 0
		for t in r.terms:
			if t.sum == "attack":
				attack += t.value
		eq(attack, r.attack, "final incomplete attack adds up")
