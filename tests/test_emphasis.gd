extends "res://tests/base.gd"
## Step emphasis: which parts of each card matter in each step, checked against the
## step table in specs/005-playfield-polish/contracts/step-emphasis.md and, where
## the rules decide it, against the engine itself.

const Game = preload("res://engine/game.gd")
const Rules = preload("res://engine/rules.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const Emphasis = preload("res://ui/model/emphasis.gd")

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
	var g = _game_facing("enemy")
	var d = Draft.new()
	for id in g.hand.slice(0, 3):
		d.tap(id)
	var vs: Dictionary = ViewState.build(g, d, db)
	eq(_regions(vs, g.hand[1]), ["ether", "initiative"] if g.level_data(g.hand[1]).initiative > 0 else ["ether"], "the Element against an Enemy")
	eq(_regions(vs, g.hand[2]), ["boost"] if g.level_data(g.hand[2]).boost > 0 else [], "the Boost")
	var j = _game_facing("journey")
	var dj = Draft.new()
	for id in j.hand.slice(0, 3):
		dj.tap(id)
	eq(_regions(ViewState.build(j, dj, db), j.hand[1]), ["ether"], "on a Journey the Element's Initiative adds nothing")


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
			eq(_regions(vs, t[0]), _spell_counts(g, t[0], t[1]),
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
			eq(vs.cards[reserve].reserve_boosts, counts, "seed %d: the Reserve is marked as adding its Boost exactly when it counts" % game_seed)
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
			eq(c.reason, "Costs %d XP" % g.level_data(id).upgrade_cost, "too costly")
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


## A seeded game whose first Encounter is of this kind ("enemy" or "journey").
func _game_facing(kind: String, from := 1):
	for game_seed in range(from, 200):
		var g = _game(game_seed)
		if g.phase == "challenge" and g.encounter().kind == kind:
			return g
	return null


func _aim(vs: Dictionary, id) -> Variant:
	return vs.cards[id].focus.aim


## Against an Enemy the Boost card carries its own aim (specs/011 research R4).
func test_boost_card_carries_its_aim() -> void:
	var g = _game_facing("enemy")
	var d = Draft.new()
	d.deal(g.hand)
	var boost = d.sets[0].boost
	eq(_aim(ViewState.build(g, d, db), boost), {"to": null}, "unaimed at first")
	d.cycle_boost_to(0)
	eq(_aim(ViewState.build(g, d, db), boost), {"to": "attack"}, "then Attack")
	for id in g.hand:
		if id != boost:
			eq(_aim(ViewState.build(g, d, db), id), null, "no other card carries an aim")
	d.begin_mode("fuse_pick")
	eq(_aim(ViewState.build(g, d, db), boost), null, "none during a Fuse")

	var j = _game_facing("journey")
	var dj = Draft.new()
	dj.deal(j.hand)
	eq(_aim(ViewState.build(j, dj, db), dj.sets[0].boost), null, "a Journey's Boost has no aim")

	var f = _game()
	_to_final(f)
	var df = Draft.new()
	df.reset(2, true)
	df.deal(f.hand)
	eq(_aim(ViewState.build(f, df, db), df.sets[0].boost), null, "nor the Final Journey's")
	f.phase = "final_enemy"
	df.reset(2, false)
	df.deal(f.hand)
	df.cycle_boost_to(1)
	var vs: Dictionary = ViewState.build(f, df, db)
	eq(_aim(vs, df.sets[0].boost), {"to": null}, "the Final Enemy's first Boost, unaimed")
	eq(_aim(vs, df.sets[1].boost), {"to": "attack"}, "its second, aimed on its own")


## The Encounter's kinds of action, as the engine reads them.
func _kinds(g) -> Array:
	var enc: Dictionary = g.encounter()
	if enc.kind == "journey":
		return ["move"]
	return ["attack", "move"] if enc.data.ability == "slow" else ["attack"]


## The Spell's plate the rules count with this Element: the enhanced action, the
## basic one, or none when no action fits and the Spell counts as 1.
func _spell_counts(g, spell: String, element: String) -> Array:
	var lv: Dictionary = g.level_data(spell)
	var act := Rules.action(lv, db.mage(element).element, _kinds(g))
	if act.enhanced:
		return ["enhanced"]
	if not Rules._fits(lv.basic.type, _kinds(g)):
		return []
	return ["basic"]


## Every placed card lifts exactly what the engine counts (specs/011 contracts/card-marks.md
## "Lift"): Enemies (Slow ones too) with the Boost aimed both ways, Journeys with and
## without the Reserve adding, and both Final Battles.
func test_lift_matches_the_engine_terms() -> void:
	var seen := {"enhanced": 0, "basic": 0, "none": 0, "initiative": 0, "reserve": 0, "aim": 0}
	for game_seed in range(1, 60):
		var g = _game(game_seed)
		if g.phase != "challenge":
			continue
		var enemy: bool = g.encounter().kind == "enemy"
		for t in _triples(g.hand):
			for aim in (["attack", "initiative"] if enemy else [null]):
				var d = Draft.new()
				d.deal(g.hand)
				d.swap(d.sets[0].spell, t[0], g.hand)
				d.swap(d.sets[0].element, t[1], g.hand)
				d.swap(d.sets[0].boost, t[2], g.hand)
				if aim != null:
					d.set_boost_to(0, aim)
				var e: Dictionary = g.explain(d.to_action())
				if e.has("error"):
					continue
				var vs: Dictionary = ViewState.build(g, d, db)
				var spell := _spell_counts(g, t[0], t[1])
				eq(_regions(vs, t[0]), spell, "seed %d: the Spell" % game_seed)
				seen[spell[0] if not spell.is_empty() else "none"] += 1
				var element := ["ether"]
				if enemy and g.level_data(t[1]).initiative > 0:
					element.append("initiative")
					seen.initiative += 1
				eq(_regions(vs, t[1]), element, "seed %d: the Element" % game_seed)
				eq(_regions(vs, t[2]), ["boost"] if g.level_data(t[2]).boost > 0 else [], "seed %d: the Boost, aimed %s" % [game_seed, aim])
				if aim == "initiative":
					seen.aim += 1
				var reserve = d.reserve_card(g.hand)
				if reserve != null:
					var adds: bool = e.terms.any(func(x): return x.source == "reserve")
					eq(_regions(vs, reserve), ["boost"] if adds else [], "seed %d: the Reserve" % game_seed)
					if adds:
						seen.reserve += 1
	for k in seen:
		ok(seen[k] > 0, "the case '%s' was seen (%s)" % [k, str(seen)])
	# The Final Battle: each set's cards by the same rules, labelled per set.
	var f = _game()
	_to_final(f)
	for stage in ["final_journey", "final_enemy"]:
		f.phase = stage
		var d = Draft.new()
		d.reset(2, stage == "final_journey")
		d.deal(f.hand)
		d.set_boost_to(0, "attack")
		d.set_boost_to(1, "initiative")
		var e: Dictionary = f.explain_final(d.to_action())
		if e.has("error"):
			ok(false, "%s: the dealt sets resolve (%s)" % [stage, e.error])
			continue
		var vs: Dictionary = ViewState.build(f, d, db)
		for i in 2:
			var b = d.sets[i].boost
			eq(_regions(vs, b), ["boost"] if f.level_data(b).boost > 0 else [], "%s: Boost %d" % [stage, i + 1])
			var el = d.sets[i].element
			var adds_initiative: bool = stage == "final_enemy" and f.level_data(el).initiative > 0
			eq(_regions(vs, el), ["ether", "initiative"] if adds_initiative else ["ether"], "%s: Element %d" % [stage, i + 1])


## The marks beside each card's figures for these Encounter effects, by card id.
func _impacts(g, d, effects: Array) -> Dictionary:
	var vs: Dictionary = ViewState.build(g, d, db)
	var ctx := Emphasis.context(g, d, vs.explain, effects)
	var out := {}
	for id in vs.hand:
		out[id] = Emphasis.focus(vs.cards[id], g.level_data(id), ctx).impacts
	return out


## Each effect that works against a card's figure marks it beside that figure, and
## only there (specs/011 contracts/card-marks.md "Impact marks").
func test_impacts_match_the_contract() -> void:
	var g = _game_facing("enemy")
	var d = Draft.new()
	d.deal(g.hand)
	var reserve = d.reserve_card(g.hand)
	var s: Dictionary = d.sets[0]
	ok(reserve != null, "a four-card Hand keeps a Reserve")
	var m := _impacts(g, d, ["night_travel"])
	eq(m[s.boost], [{"region": "boost", "icon": "night_travel"}], "Night Travel: the Boost")
	eq(m[s.element], [{"region": "initiative", "icon": "night_travel"}], "Night Travel: the Element's Initiative")
	eq(m[s.spell], [], "not the Spell")
	eq(m[reserve], [], "nor the Reserve")
	for effect in ["steep", "ranged", "freeze"]:
		m = _impacts(g, d, [effect])
		eq(m[reserve], [{"region": "boost", "icon": effect}], "%s: the Reserve, beside its Boost" % effect)
		for id in [s.spell, s.element, s.boost]:
			eq(m[id], [], "%s: no other card" % effect)
	d.give_up_reserve = true
	eq(_impacts(g, d, ["ranged"])[reserve], [], "Ranged leaves the Reserve once it is given up")
	d.give_up_reserve = false
	for effect in ["poison", "slow", "ambush", "hazards", "storm", "treacherous"]:
		m = _impacts(g, d, [effect])
		for id in m:
			eq(m[id], [], "%s works on no card's figure" % effect)
	# After a swap the marks are the new Boost's.
	d.swap(s.boost, reserve, g.hand)
	m = _impacts(g, d, ["night_travel"])
	eq(m[reserve], [{"region": "boost", "icon": "night_travel"}], "the card swapped into the Boost takes its mark")
	# A Hand of three has no Reserve to mark.
	var three = Draft.new()
	three.deal(g.hand.slice(0, 3))
	for id in g.hand.slice(0, 3):
		eq(_impacts(g, three, ["freeze"]).get(id, []), [], "no Reserve, no Freeze mark")
	# The Final Battle: each set's Boost and Element.
	var f = _game()
	_to_final(f)
	var df = Draft.new()
	df.reset(2, true)
	df.deal(f.hand)
	m = _impacts(f, df, ["night_travel"])
	for i in 2:
		eq(m[df.sets[i].boost], [{"region": "boost", "icon": "night_travel"}], "Final Battle: Boost %d" % (i + 1))


## Armor marks the Spell's enhanced action exactly when the engine takes Armor off it.
func test_armor_marks_the_enhanced_attack_it_reduces() -> void:
	var marked := 0
	var unmarked := 0
	for game_seed in range(1, 120):
		var g = _game(game_seed)
		if g.phase != "challenge" or g.encounter().kind != "enemy":
			continue
		for t in _triples(g.hand):
			var d = Draft.new()
			for id in t:
				d.tap(id)
			d.set_boost_to(0, "attack")
			var e: Dictionary = g.explain(d.to_action())
			if e.has("error"):
				continue
			var armored: bool = e.terms.any(func(x): return x.label == "Armor")
			var m := _impacts(g, d, [])
			eq(m[t[0]], [{"region": "enhanced", "icon": "armor"}] if armored else [], "seed %d: Armor on the Spell" % game_seed)
			if armored:
				marked += 1
			else:
				unmarked += 1
		if marked > 0 and unmarked > 0:
			break
	ok(marked > 0 and unmarked > 0, "both cases seen (%d marked, %d not)" % [marked, unmarked])


## On a placed card every figure of the stat column is lit, marked, or stepped back:
## exactly one of them (owner, specs/011). Unplaced cards and other steps step none.
func test_unused_figures_step_back() -> void:
	var g = _game_facing("enemy")
	var d = Draft.new()
	d.deal(g.hand)
	var vs: Dictionary = ViewState.build(g, d, db)
	for id in g.hand:
		var f: Dictionary = vs.cards[id].focus
		var marked: Array = f.impacts.map(func(m): return m.region)
		for r in Emphasis.STAT_REGIONS:
			var n := int(f.regions.has(r)) + int(marked.has(r)) + int(f.quiet.has(r))
			ok(n >= 1, "%s: %s is lit, marked or stepped back" % [id, r])
			ok(not (f.quiet.has(r) and (f.regions.has(r) or marked.has(r))), "%s: %s is not stepped back while it counts" % [id, r])
		ok(f.quiet.has("armor"), "%s: Armor plays no part while building" % id)
	d.begin_mode("divert")
	vs = ViewState.build(g, d, db)
	for id in g.hand:
		eq(vs.cards[id].focus.quiet, [], "nothing steps back during a Divert")
