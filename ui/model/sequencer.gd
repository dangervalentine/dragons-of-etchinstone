extends RefCounted
## Turns one change to the game into the ordered steps the screen plays to show it.
## Works from snapshots taken before and after the engine call (see
## view_state.snapshot), the action that was taken, and the engine's result.
## Pure: tests replay the steps on the before snapshot and expect the after one.
##
## A step is {kind, cards, from, to, values, anchor, duration}.

const T = preload("res://ui/theme/tokens.gd")
const ViewState = preload("res://ui/model/view_state.gd")

const DURATION := {
	"play_cards": 0.35, "tally": 0.6, "verdict": 0.4, "gain_xp": 0.35, "damage": T.DAMAGE,
	"pay_time": 0.2, "poison_pending": 0.3, "knock_out": 0.45, "downgrade": T.TURN, "trash": 0.3,
	"upgrade": T.TURN, "discard": 0.35, "gather_shuffle": 0.45, "stage_banner": 1.2, "draw": 0.35,
	"ending": 0.4, "xp_lost": 0.9,
	"zoom_out": T.ZOOM, "zoom_in": T.ZOOM, "turn_card": T.TURN, "key_peek": T.KEY_PEEK,
}
## The steps that reveal the next Encounter on the Deck (specs/012 research R8):
## they keep their own timing, so a long sequence never hurries the Key Card.
const REVEAL := ["key_peek", "zoom_in"]
## The steps a long sequence never hurries: the reveal, and what is to be seen
## going: a Time Penalty's cards leaving the Deck, damage, and XP won, spent or lost.
const OWN_TIME := REVEAL + ["pay_time", "damage", "gain_xp", "upgrade", "xp_lost"]


## action: {kind, cards (the cards played or chosen), id (one card)}. kind is one of
## start, setup, play, play_final, soak, upgrade, finish, divert, regroup.
static func build(before: Dictionary, action: Dictionary, result: Dictionary, after: Dictionary) -> Array:
	var steps := []
	match action.kind:
		"start":
			steps.append(_step("stage_banner", [], {"region": after.region, "phase": after.phase}, "screen"))
			_draw_step(steps, after.hand)
			_reveal(steps, after)
		"setup":
			_level_steps(steps, before, after, before.offer)
			# The offer goes back to the Deck as a Hand is drawn, in reverse: the last
			# card first, each growing into the Region Card's place.
			var back := _step("gather_shuffle", before.offer.duplicate(), {"deck": after.hand + after.deck, "undraw": true}, "deck")
			back.duration = minf(T.DRAW_FLY + T.STAGGER * (before.offer.size() - 1), 1.2)
			steps.append(back)
			# The Region Card is laid on top of the Deck (rulebook Setup, step 4).
			steps.append(_step("turn_card", [], {"from": 0, "to": after.region}, "deck"))
			steps.append(_step("stage_banner", [], {"region": after.region, "phase": after.phase}, "screen"))
			_draw_step(steps, after.hand)
			_reveal(steps, after)
		"play":
			_strike(steps, action, result)
			if result.damage > 0:
				steps.append(_step("damage", [], {"amount": result.damage, "early": result.get("early_damage", 0),
					"element": result.get("damage_element", "")}, "hand"))
			_pay_time(steps, before, after)
			if result.get("poison", 0) > 0:
				steps.append(_step("poison_pending", [], {"amount": result.poison}, "deck"))
			if result.get("knocked_out", false):
				steps.append(_step("knock_out", before.hand.duplicate(), {}, "hand"))
			_level_steps(steps, before, after, before.hand)
		"play_final":
			_strike(steps, action, result)
			if before.phase == "final_journey" and after.phase == "final_enemy":
				steps.append(_step("zoom_out", [], {}, "deck"))
				steps.append(_step("discard", before.hand.duplicate(), {"from": "hand"}, "discard"))
				_pay_time(steps, before, after, before.hand)
				steps.append(_step("stage_banner", [], {"region": after.region, "phase": after.phase}, "screen"))
				_draw_step(steps, after.hand)
				_reveal(steps, after)
			elif after.phase == "final_soak":
				steps.append(_step("damage", [], {"amount": after.damage_due, "early": 0, "element": ""}, "hand"))
		"soak":
			# The cards chosen Downgrade; nothing flies to them (specs/015).
			_level_steps(steps, before, after, before.hand)
		"upgrade":
			_level_steps(steps, before, after, before.hand)
		"finish":
			# XP not spent by the end of the Upgrade step is lost (rulebook): say so first.
			if before.phase == "upgrade" and before.get("xp", 0) > 0:
				steps.append(_step("xp_lost", [], {"amount": before.xp}, "xp"))
			# Back out to the whole Region Card before the Hand is refilled from under it.
			steps.append(_step("zoom_out", [], {}, "deck"))
			var spent := []
			for id in before.hand:
				if not after.hand.has(id) or after.region != before.region or after.phase == "final_journey":
					if not before.discard.has(id) and (after.discard.has(id) or _gathered(before, after)) and action.cards.has(id):
						spent.append(id)
			if not spent.is_empty():
				steps.append(_step("discard", spent, {"from": "hand"}, "discard"))
			if _gathered(before, after):
				var all: Array = before.hand.filter(func(id): return not spent.has(id)) + spent + before.discard
				steps.append(_step("gather_shuffle", all, {"deck": _deck_before_draw(after, [])}, "deck"))
				# The next Region's side of the card, the other card, or the dragon's.
				steps.append(_step("turn_card", [], {"from": before.region,
					"to": "dragon" if after.phase == "final_journey" else after.region}, "deck"))
				steps.append(_step("stage_banner", [], {"region": after.region, "phase": after.phase}, "screen"))
				_draw_step(steps, after.hand)
				_reveal(steps, after)
			else:
				var kept: Array = before.hand.filter(func(id): return not spent.has(id))
				_draw_step(steps, after.hand.filter(func(id): return not kept.has(id)))
				if after.phase == "poison":
					# The new Encounter shows first; then the poison lands on the new Hand.
					_reveal(steps, after)
					steps.append(_step("damage", [], {"amount": after.damage_due, "early": 0, "element": "", "poison": true}, "hand"))
				elif _levels_fell(before, after):
					steps.append(_step("damage", [], {"amount": 0, "early": 0, "element": "", "poison": true}, "hand"))
					_pay_time(steps, before, after, spent)
					steps.append(_step("knock_out", after.hand.duplicate(), {}, "hand"))
					_level_steps(steps, before, after, after.hand + after.trash)
					# Knocked Out, time was paid from the top of the Deck: the Key Card is
					# the one left there after it.
					_reveal(steps, after)
				else:
					_reveal(steps, after)
		"divert":
			var key: String = before.deck[0]
			steps.append(_step("zoom_out", [], {}, "deck"))
			steps.append(_step("discard", [key], {"from": "deck"}, "discard"))
			steps.append(_step("discard", [action.id], {"from": "hand"}, "discard"))
			_reveal(steps, after)
		"regroup":
			steps.append(_step("zoom_out", [], {}, "deck"))
			steps.append(_step("discard", [action.id], {"from": "hand"}, "discard"))
			var rest: Array = before.hand.filter(func(id): return id != action.id)
			steps.append(_step("gather_shuffle", rest, {"deck": _deck_before_draw(after, []), "keep_discard": true}, "deck"))
			_draw_step(steps, after.hand)
			_reveal(steps, after)
	if after.phase == "won" or after.phase == "lost":
		steps.append(_step("ending", [], {"won": after.phase == "won"}, "screen"))
	_fit_time(steps)
	return steps


## Replay one step on a snapshot. Used by the tests to prove the steps say exactly
## what happened.
static func apply(state: Dictionary, step: Dictionary) -> Dictionary:
	var s := state.duplicate(true)
	match step.kind:
		"pay_time":
			for id in step.cards:
				s.deck.erase(id)
				s.discard.append(id)
		"discard":
			for id in step.cards:
				s[step.values.from].erase(id)
				s.discard.append(id)
		"trash":
			for id in step.cards:
				s.hand.erase(id)
				s.trash.append(id)
		"downgrade", "upgrade":
			for id in step.cards:
				s.levels[id] = step.values.level
		"gather_shuffle":
			s.hand = []
			if not step.values.get("keep_discard", false):
				s.discard = []
			s.offer = []
			s.deck = step.values.deck.duplicate()
		"draw":
			for id in step.cards:
				s.deck.erase(id)
				s.hand.append(id)
	return s


static func _step(kind: String, cards: Array, values: Dictionary, anchor: String) -> Dictionary:
	return {"kind": kind, "cards": cards, "values": values, "anchor": anchor, "duration": DURATION[kind]}


## The cards strike the Encounter, the totals count up, the verdict lands, XP is won.
static func _strike(steps: Array, action: Dictionary, result: Dictionary) -> void:
	steps.append(_step("play_cards", action.cards.duplicate(), {}, "encounter"))
	steps.append(_step("tally", [], {}, "preview"))
	steps.append(_step("verdict", [], {"outcome": result.get("outcome", ""), "tier": result.get("tier", -1)}, "preview"))
	if result.get("xp", 0) > 0:
		var st := _step("gain_xp", [], {"amount": result.xp}, "xp")
		st.duration = paced(mini(result.xp, T.XP_STARS))
		steps.append(st)


## Cards that went straight from the deck to the discard: a Time Penalty.
static func _pay_time(steps: Array, before: Dictionary, after: Dictionary, also_discarded := []) -> void:
	var paid := []
	for id in after.discard:
		if before.deck.has(id) and not also_discarded.has(id):
			paid.append(id)
	if not paid.is_empty():
		var st := _step("pay_time", paid, {"count": paid.size()}, "deck")
		# They leave the Deck one after another as a Hand is drawn, but slower.
		st.duration = minf(T.PAY_FLY + T.PAY_STAGGER * (paid.size() - 1), T.PAY_MAX)
		steps.append(st)


## Level changes, in Hand order: Downgrades, cards Trashed from Level 1, Upgrades.
static func _level_steps(steps: Array, before: Dictionary, after: Dictionary, ids: Array) -> void:
	for id in ids:
		var was: int = before.levels[id]
		var now: int = after.levels[id]
		if after.trash.has(id) and not before.trash.has(id):
			steps.append(_step("trash", [id], {}, "trash"))
		elif now < was:
			steps.append(_step("downgrade", [id], {"level": now, "from": was}, "hand"))
		elif now > was:
			var st := _step("upgrade", [id], {"level": now, "from": was}, "hand")
			# The XP it cost, which flies from the purse to the card (specs/011 R7): its
			# own cost, though other cards were Upgraded with it.
			if before.get("xp", 0) > after.get("xp", 0) and before.get("costs", {}).has(id):
				st.values["spent"] = before.costs[id]
				st.duration = maxf(T.TURN, paced(st.values.spent))
			steps.append(st)


## The next Encounter revealed on the Deck: in a Region the Key Card rises to show
## what it names, then the view zooms into that tile; in the Final Battle it zooms
## into the Dragon Card's MP or HP Tiers.
static func _reveal(steps: Array, after: Dictionary) -> void:
	var target := ViewState.zoom_for(after)
	if target == "" or after.phase == "won" or after.phase == "lost":
		return
	var enc = after.get("encounter")
	if enc != null and not after.deck.is_empty():
		steps.append(_step("key_peek", [after.deck[0]], {"key": after.deck[0], "kind": enc.kind, "index": enc.index, "target": target,
			"hardship": enc.hardship}, "deck"))
	steps.append(_step("zoom_in", [], {"target": target}, "deck"))


## How long `n` damage marks or XP stars take, flying one after another.
static func paced(n: int) -> float:
	return minf(T.MOTE_FLY + T.MOTE_STAGGER * maxi(0, n - 1), T.MOTE_MAX)


static func _draw_step(steps: Array, ids: Array) -> void:
	if ids.is_empty():
		return
	var st := _step("draw", ids.duplicate(), {}, "hand")
	st.duration = minf(T.DRAW_FLY + T.STAGGER * (ids.size() - 1), 1.2)
	steps.append(st)


static func _gathered(before: Dictionary, after: Dictionary) -> bool:
	return after.region != before.region or (after.phase == "final_journey" and before.phase != "final_journey")


static func _levels_fell(before: Dictionary, after: Dictionary) -> bool:
	for id in after.levels:
		if after.levels[id] < before.levels[id]:
			return true
	return false


## The deck as it stood just before the new Hand was drawn from its top.
static func _deck_before_draw(after: Dictionary, _unused: Array) -> Array:
	return after.hand + after.deck


## Keep a whole sequence within the time limit by shortening every step alike, all
## but the reveal of the next Encounter and a Time Penalty, which keep their own timing.
static func _fit_time(steps: Array) -> void:
	var total := 0.0
	for st in steps:
		if not OWN_TIME.has(st.kind):
			total += st.duration
	if total > T.SEQUENCE_MAX:
		var k: float = T.SEQUENCE_MAX / total
		for st in steps:
			if not OWN_TIME.has(st.kind):
				st.duration *= k
