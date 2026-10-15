extends RefCounted
## Turns a game and the player's draft into everything a screen needs to draw.
## Pure: the same game and draft always give the same result, and nothing is changed.
## This is the only UI file that reads the engine's internals.

const Game = preload("res://engine/game.gd")
const Rules = preload("res://engine/rules.gd")
const Art = preload("res://ui/model/art.gd")
const Emphasis = preload("res://ui/model/emphasis.gd")

const ROLE_NAMES := {"spell": "Spell", "element": "Element", "boost": "Boost"}
const DIFFICULTY_NAMES := {
	"casual": "Casual", "easy": "Easy", "normal": "Normal", "hard": "Hard",
	"impossible": "Impossible", "dont_even_try": "Don't Even Try It",
}
const SOAK_PHASES := ["penalty", "poison", "final_soak"]
const INCOMPLETE_ERRORS := [
	"An Action Set needs a Spell.",
	"Assign a Spell, an Element and a Boost.",
	"Assign a Spell, an Element and a Boost in both Action Sets.",
	"Build two Action Sets.",
]


## Just the parts of the game that cards move between, for working out what an action did.
static func snapshot(game) -> Dictionary:
	var levels := {}
	for id in game.cards:
		levels[id] = game.cards[id].level
	return {
		"phase": game.phase, "region": game.region, "xp": game.xp, "damage_due": game.damage_due,
		"deck": game.deck.duplicate(), "hand": game.hand.duplicate(),
		"discard": game.discard.duplicate(), "trash": game.trash.duplicate(),
		"levels": levels, "offer": game.setup_offer.duplicate() if game.phase == "setup" else [],
	}


## extra: message (a refusal to show), previous_preview, lost_at (where the game was lost).
static func build(game, draft, db, extra := {}) -> Dictionary:
	var phase: String = game.phase
	var playing: bool = phase == "challenge" or phase == "final_journey" or phase == "final_enemy"
	var vs := {
		"phase": phase,
		"mode": draft.mode,
		"stage": _stage(game, db),
		"piles": {"deck": game.deck.size(), "discard": game.discard.size(), "trash": game.trash.size()},
		"progress": {"deck": game.deck.size(), "total": game.cards.size() - game.trash.size()},
		"hand": game.setup_offer.duplicate() if phase == "setup" else game.hand.duplicate(),
		"cards": {},
		"encounter": _encounter(game, db),
		"preview": null,
		"sets": [],
		"active_slot": draft.active.duplicate(),
		"soak": null,
		"xp": game.xp,
		"recap": _recap(game),
		"ending": _ending(game, extra.get("lost_at", "")),
		"message": extra.get("message", ""),
		"fuse_elements": draft.mode == "fuse_element",
		"fuse_pick": draft.fuse_pick.duplicate(),
		"played": _played(game),
		"undo": extra.get("undo", 0),
	}
	if playing:
		vs.preview = preview(game, draft, extra.get("previous_preview"))
		vs.sets = _sets(game, draft)
	if SOAK_PHASES.has(phase):
		var total := 0
		for id in draft.picks:
			total += game._soak_value(id)
		vs.soak = {"due": game.damage_due, "element": game.damage_element, "total": total,
			"covered": total >= game.damage_due, "poison": phase == "poison"}
	var ctx := Emphasis.context(game, draft)
	vs["next_role"] = ctx.next_role
	for id in vs.hand:
		vs.cards[id] = _card(game, draft, db, id, vs)
		vs.cards[id]["focus"] = Emphasis.focus(vs.cards[id], game.level_data(id), ctx)
		# The Reserve's Boost is adding to the Move, so the card is playing a part too.
		vs.cards[id]["reserve_boosts"] = vs.cards[id].reserve and vs.cards[id].focus.regions.has("boost")
	vs["prompt"] = _prompt(game, draft, vs)
	vs["secondary"] = _secondary(game, draft, vs)
	vs["input_region"] = _input_region(game, draft, vs)
	return vs


## The part of the play screen waiting on the player: the Hand while a card is
## still to be chosen, the commit control once everything is ready.
static func _input_region(game, draft, vs: Dictionary) -> String:
	if not vs.prompt.primary.enabled:
		return "hand"
	match game.phase:
		"challenge", "final_journey", "final_enemy":
			return "commit" if draft.mode == "none" and vs.preview.status == "ready" else "hand"
		"upgrade":
			for id in vs.hand:
				if vs.cards[id].eligible:
					return "hand"
	return "commit"


## The predicted result of committing the draft, shaped for display. Every figure
## is the engine's own; this only arranges them.
static func preview(game, draft, previous = null) -> Dictionary:
	var action: Dictionary = draft.to_action()
	var final: bool = game.phase != "challenge"
	var r: Dictionary = game.preview_final(action) if final else game.preview(action)
	var out := {"status": "ready", "missing": [], "reason": "", "comparisons": [], "verdict": "",
		"verdict_text": "", "rewards": {"xp": 0}, "costs": [], "fatal": false, "tier": -1,
		"figures": {}, "changed": []}
	if r.has("error"):
		if INCOMPLETE_ERRORS.has(r.error) and not draft.empty_slots().is_empty():
			out.status = "incomplete"
			for slot in draft.empty_slots():
				var name: String = ROLE_NAMES[slot[1]]
				out.missing.append(name + (" %d" % (slot[0] + 1) if draft.set_count > 1 else ""))
		else:
			out.status = "blocked"
			out.reason = r.error
		return out
	match game.phase:
		"challenge":
			_preview_region(game, draft, r, out)
		"final_journey":
			_preview_final_journey(game, r, out)
		"final_enemy":
			_preview_final_enemy(game, r, out)
	for i in out.comparisons.size():
		out.figures["value%d" % i] = out.comparisons[i].value
		out.figures["result%d" % i] = out.comparisons[i].result
	out.figures["verdict"] = out.verdict_text
	out.figures["xp"] = out.rewards.xp
	for c in out.costs:
		out.figures[c.id] = c.value
	if previous != null and previous.get("status", "") == "ready":
		for key in out.figures:
			if previous.figures.get(key) != out.figures[key]:
				out.changed.append(key)
	return out


static func _preview_region(game, draft, r: Dictionary, out: Dictionary) -> void:
	var enc: Dictionary = game.encounter()
	out.verdict = r.outcome
	out.verdict_text = {"complete": "Complete victory", "narrow": "Narrow victory", "loss": "Loss"}[r.outcome]
	out.rewards.xp = r.xp
	if enc.kind == "enemy":
		out.comparisons.append({"label": "Attack", "icon": "attack", "value": r.attack,
			"target": enc.data.hp, "target_icon": "hp", "result": r.outcome, "note": ""})
		out.comparisons.append({"label": "Initiative", "icon": "initiative", "value": r.initiative,
			"target": enc.data.initiative, "target_icon": "initiative",
			"result": "loss" if r.early else "complete",
			"note": ("Struck first: %d early damage" % r.early_damage) if r.early else "You strike first"})
	else:
		out.comparisons.append({"label": "Move", "icon": "move", "value": r.move,
			"target": r.mp, "target_icon": "mp", "result": r.outcome, "note": ""})
	if r.damage > 0:
		out.costs.append({"id": "damage", "icon": "hp", "value": r.damage,
			"element": r.damage_element, "text": "Damage"})
	if r.time_penalty > 0:
		out.costs.append({"id": "time", "icon": "time", "value": r.time_penalty, "element": "", "text": "Time penalty"})
	if r.get("poison", 0) > 0:
		out.costs.append({"id": "poison", "icon": "poison", "value": r.poison, "element": "", "text": "Poison next Hand"})
	if r.get("discard_reserve", false):
		out.costs.append({"id": "reserve", "icon": "reserve", "value": 0, "element": "", "text": "Reserve discarded"})
	if _would_knock_out(game, draft, r):
		out.costs.append({"id": "knock_out", "icon": "down_arrow", "value": 0, "element": "", "text": "Knocked Out"})


## Mirrors the engine's damage bookkeeping in play() to warn of a Knock Out.
## Checked against the engine in tests/test_view_state.gd.
static func _would_knock_out(game, draft, r: Dictionary) -> bool:
	var damage: int = r.damage + maxi(0, r.time_penalty - game.deck.size())
	var poison: int = r.get("poison", 0)
	if poison > 0:
		var action: Dictionary = draft.to_action()
		var reserve = game._reserve([action], action.get("fuse"))
		var kept := 1 if reserve != null and not r.get("discard_reserve", false) else 0
		if kept + game.deck.size() < Game.HAND_SIZE + 1:
			damage += poison
	if damage <= 0:
		return false
	var capacity := 0
	for id in game.hand:
		if not game.downgraded.has(id):
			capacity += Rules.soak_value(game.level_data(id), r.damage_element, game.options.get("glass_cannon", false))
	return capacity < damage


static func _preview_final_journey(game, r: Dictionary, out: Dictionary) -> void:
	var tiers: Array = game.dragon.mp_tiers
	out.tier = r.tier
	out.comparisons.append({"label": "Move", "icon": "move", "value": r.move,
		"target": tiers[maxi(r.tier, 0)].mp.value if r.tier < tiers.size() - 1 else tiers[-1].mp.value,
		"target_icon": "mp", "result": "loss" if r.tier < 0 else ("complete" if r.tier == tiers.size() - 1 else "narrow"),
		"note": "", "tiers": tiers.map(func(t): return t.mp.value)})
	if r.tier < 0:
		out.fatal = true
		out.verdict = "loss"
		out.verdict_text = "The dragon escapes"
		return
	out.verdict = out.comparisons[0].result
	out.verdict_text = "Tier %d reached" % (r.tier + 1)
	if r.time_penalty > 0:
		out.costs.append({"id": "time", "icon": "time", "value": r.time_penalty, "element": "", "text": "Time penalty"})


static func _preview_final_enemy(game, r: Dictionary, out: Dictionary) -> void:
	var d: Dictionary = game.dragon
	var tiers: Array = d.hp_tiers
	out.tier = r.tier
	out.comparisons.append({"label": "Attack", "icon": "attack", "value": r.attack,
		"target": tiers[maxi(r.tier, 0)].hp, "target_icon": "hp",
		"result": "loss" if r.tier < 0 else ("complete" if r.tier == tiers.size() - 1 else "narrow"),
		"note": "", "tiers": tiers.map(func(t): return t.hp)})
	out.comparisons.append({"label": "Initiative", "icon": "initiative", "value": r.initiative,
		"target": d.initiative, "target_icon": "initiative", "result": "loss" if r.early else "complete",
		"note": ("Struck first: %d early damage" % d.early_damage.value) if r.early else "You strike first"})
	if r.tier < 0:
		out.fatal = true
		out.verdict = "loss"
		out.verdict_text = "The dragon prevails"
		return
	out.costs.append({"id": "damage", "icon": "hp", "value": r.damage,
		"element": d.early_damage.element, "text": "Damage to Soak"})
	out.fatal = not r.survivable
	out.verdict = "loss" if out.fatal else out.comparisons[0].result
	out.verdict_text = "Your Hand cannot Soak this" if out.fatal else "Tier %d reached" % (r.tier + 1)


static func _stage(game, db) -> Dictionary:
	if game.phase.begins_with("final") or game.phase == "won" or game.phase == "lost":
		return {"kind": "final", "region": game.region, "name": game.dragon.name, "title": game.dragon.title,
			"heading": "Final Battle · %s, %s" % [game.dragon.name, game.dragon.title],
			"element": game.dragon.early_damage.element, "dragon": game.dragon.id, "art": Art.dragon(game.dragon.id)}
	var r: Dictionary = db.region(game.region)
	return {"kind": "region", "region": game.region, "name": r.name, "title": "",
		"heading": "Region %d · %s" % [game.region, r.name], "element": "", "dragon": game.dragon.id,
		"art": Art.dragon(game.dragon.id)}


static func _encounter(game, db) -> Variant:
	match game.phase:
		"setup", "won", "lost":
			return null
		"final_journey", "final_enemy", "final_soak":
			var journey: bool = game.phase == "final_journey"
			return {"kind": "final_journey" if journey else "final_enemy", "title": game.dragon.name,
				"subtitle": game.dragon.title, "element": game.dragon.early_damage.element,
				"dragon": game.dragon, "carried_damage": game.carried_damage, "effects": [], "scene": Art.FINAL_JOURNEY,
				"art": Art.dragon(game.dragon.id)}
	# Until the next Hand is drawn, the table still shows the Encounter just played.
	if not game.faced.is_empty() and (game.phase == "penalty" or game.phase == "upgrade"):
		var f: Dictionary = game.faced
		return encounter_model(db, game.region, f.encounter.kind, f.encounter.index, f.encounter.hardship,
			{"id": f.key, "name": db.mage(f.key).name, "level": f.level, "element": db.mage(f.key).element})
	if game.key_card() == null:
		return null
	var enc: Dictionary = game.encounter()
	var key: String = game.key_card()
	return encounter_model(db, game.region, enc.kind, enc.index, enc.hardship,
		{"id": key, "name": db.mage(key).name, "level": game.cards[key].level, "element": db.mage(key).element})


## A Region Encounter as the Encounter face draws it, with the Key Card that names
## it ({id, name, level, element}). The rulebook builds its examples with this too.
static func encounter_model(db, region: int, kind: String, index: int, hardship, key_card: Dictionary) -> Dictionary:
	var data: Dictionary = db.encounter(region, kind, index)
	var enemy: bool = kind == "enemy"
	var effects := []
	if hardship != null:
		effects.append(hardship)
	if enemy and data.ability != null:
		effects.append(data.ability)
	if not enemy and data.peril != null:
		effects.append(data.peril)
	return {"kind": kind, "index": index, "title": Art.encounter_name(region, kind, index),
		"subtitle": "%s %d" % ["Enemy" if enemy else "Journey", index], "element": data.attack.element if enemy else data.mp.element,
		"data": data, "effects": effects, "reward": data.xp,
		"art": Art.encounter(region, kind, index),
		"scene": Art.FINAL_JOURNEY,
		"key_card": key_card}


static func _sets(game, draft) -> Array:
	var enemy: bool = game.phase == "final_enemy" or (game.phase == "challenge" and game.encounter().kind == "enemy")
	var out := []
	for i in draft.set_count:
		out.append({"roles": draft.sets[i].duplicate(), "boost_to": draft.boost_to[i], "show_boost_to": enemy})
	return out


static func _card(game, draft, db, id: String, vs: Dictionary) -> Dictionary:
	var m: Dictionary = db.mage(id)
	var lv: Dictionary = game.level_data(id)
	var c := {
		"id": id, "name": m.name, "element": m.element, "level": game.cards[id].level,
		"max_level": m.levels.size(), "stats": lv,
		"state": "available", "role": null, "fuse": null, "reserve": false, "reserve_boosts": false,
		"eligible": true, "reason": "", "note": "", "note_icon": "", "match": false,
		"selection_order": -1,
		"downgraded": game.downgraded.has(id),
		"fate": "",
		"alt": null,
		"key_name": Art.encounter_name(game.region, lv.encounter.type, lv.encounter.index),
	}
	# After a battle: which cards are spent and which one stays in the Hand.
	var played = vs.played
	if played != null:
		if played.roles.values().has(id) or played.fuse_bottom == id:
			c.fate = "spent"
		elif played.reserve == id:
			c.fate = "stays" if played.reserve_kept else "spent"
	match game.phase:
		"setup":
			c.selection_order = draft.picks.find(id)
			# A chosen card shows at the Level it will start at; hovering an unchosen
			# one previews that Level. No part outlines: the card's own border is enough.
			var start: int = game.setup_level
			var moves: bool = start != c.level and start >= 1 and start <= 4
			if moves and c.selection_order >= 0:
				c.level = start
				c.stats = db.mage_level(id, start)
			elif moves:
				c.alt = _alt(game, db, id, start, "If chosen")
				c.alt.changed = []
			if c.selection_order >= 0:
				c.state = "selected"
			elif draft.picks.size() >= game.setup_picks:
				c.eligible = false
				c.reason = "%d chosen" % game.setup_picks
		"challenge", "final_journey", "final_enemy":
			_card_in_play(game, draft, db, c)
		"penalty", "poison", "final_soak":
			var value: int = game._soak_value(id)
			var armor = lv.armor
			c.match = armor.element != null and armor.element == game.damage_element
			c.note = "Soaks %d" % value
			c.note_icon = "armor"
			c.selection_order = draft.picks.find(id)
			if c.level > 1:
				c.alt = _alt(game, db, id, c.level - 1, "If Downgraded")
			else:
				c.alt = {"trashed": true, "label": "Trashed if Downgraded", "level": 0, "stats": lv, "changed": []}
			if c.selection_order >= 0:
				c.state = "selected"
			elif c.downgraded:
				c.eligible = false
				c.reason = "Downgraded"
			elif vs.soak.covered:
				c.eligible = false
				c.reason = "Covered"
		"upgrade":
			var cost = lv.upgrade_cost
			if c.downgraded:
				c.eligible = false
				c.reason = "Downgraded"
			elif cost == null:
				c.eligible = false
				c.reason = "Max Level"
			elif cost > game.xp:
				c.eligible = false
				c.reason = "Costs %d XP" % cost
			else:
				c.note = "%d XP" % cost
				c.note_icon = "xp"
			if cost != null and not c.downgraded:
				c.alt = _alt(game, db, id, c.level + 1, "If Upgraded")
	return c


## A card as it would be at another Level, with the figures that would change.
static func _alt(game, db, id: String, level: int, label: String) -> Dictionary:
	var now: Dictionary = game.level_data(id)
	var then: Dictionary = db.mage_level(id, level)
	var changed := []
	for key in ["initiative", "basic", "enhanced", "boost", "armor", "upgrade_cost", "encounter", "hardship"]:
		if now[key] != then[key]:
			changed.append(key)
	return {"trashed": false, "label": label, "level": level, "stats": then, "changed": changed}


## The Action Set just played, for the steps after a battle: its cards, and the
## Reserve, which stays in the Hand unless it was given up or frozen.
static func _played(game) -> Variant:
	if game.phase != "penalty" and game.phase != "upgrade":
		return null
	var a: Dictionary = game._action
	if a.is_empty():
		return null
	return {"roles": a.cards.duplicate(), "reserve": a.reserve,
		"reserve_kept": not game._discard_reserve,
		"fuse_bottom": a.fuse.bottom if a.fuse != null else null}


static func _card_in_play(game, draft, db, c: Dictionary) -> void:
	var id: String = c.id
	c.role = draft.slot_of(id)
	if c.role != null:
		c.state = "assigned"
	if draft.fuse != null:
		if draft.fuse.top == id:
			c.fuse = {"part": "top", "element": draft.fuse.element, "other": draft.fuse.bottom}
		elif draft.fuse.bottom == id:
			c.fuse = {"part": "bottom", "element": draft.fuse.element, "other": draft.fuse.top}
			c.state = "fused_bottom"
	if c.state == "available":
		if draft.is_filled() and game._reserve(draft.sets.slice(0, draft.set_count), draft.fuse) == id:
			c.reserve = true
			c.state = "reserve"
	match draft.mode:
		"fuse_pick":
			var order: int = draft.fuse_pick.find(id)
			if order >= 0:
				c.state = "selected"
				c.selection_order = order
			elif draft.fuse_pick.size() == 1 and db.mage(draft.fuse_pick[0]).element != c.element:
				c.eligible = false
				c.reason = "Other Ether"
		"fuse_element":
			c.selection_order = draft.fuse_pick.find(id)
			if c.selection_order >= 0:
				c.state = "selected"
			c.eligible = c.selection_order >= 0


static func _prompt(game, draft, vs: Dictionary) -> Dictionary:
	var p := {"text": "", "step": "", "primary": {"label": "", "enabled": false, "reason": "", "kind": "primary"}}
	match game.phase:
		"setup":
			var n: int = draft.picks.size()
			p.text = "%s: choose %d of these cards to start at Level %d." % [
				DIFFICULTY_NAMES.get(game.options.get("difficulty", "normal"), ""), game.setup_picks, game.setup_level]
			p.primary.label = "Confirm  %d / %d" % [n, game.setup_picks]
			p.primary.enabled = n == game.setup_picks
			p.primary.reason = "Choose %d more" % (game.setup_picks - n)
		"challenge", "final_journey", "final_enemy":
			p.text = "Build two Action Sets." if draft.set_count > 1 else "Build your Action Set."
			match draft.mode:
				"divert":
					p.step = "Divert"
					p.text = "Choose a Hand card to discard along with the Key Card. A new Key Card is revealed."
				"regroup":
					p.step = "Regroup"
					p.text = "Choose one card to discard. The rest are shuffled back and you draw again."
				"fuse_pick":
					if draft.fuse_pick.is_empty():
						p.step = "Fuse · step 1 of 3"
						p.text = "Choose the card you will play."
					else:
						p.step = "Fuse · step 2 of 3"
						p.text = "Choose a card of the same Ether to tuck behind it."
				"fuse_element":
					p.step = "Fuse · step 3 of 3"
					p.text = "Choose the Ether the fused card counts as."
			var pv: Dictionary = vs.preview
			p.primary.label = "Play"
			p.primary.enabled = pv.status == "ready" and draft.mode == "none"
			if pv.status == "incomplete":
				p.primary.reason = "Still needed: " + ", ".join(pv.missing)
			elif pv.status == "blocked":
				p.primary.reason = pv.reason
			elif draft.mode != "none":
				p.primary.reason = "Finish or cancel " + p.step.get_slice(" ", 0)
			if pv.fatal:
				p.primary.kind = "warning"
		"penalty", "poison", "final_soak":
			var s: Dictionary = vs.soak
			p.step = "Poison" if s.poison else "Soak"
			p.text = "Choose cards to Downgrade. Each Soaks its Armor; Armor of the matching Ether Soaks more."
			p.primary.label = "Take the damage"
			p.primary.enabled = s.covered
			p.primary.reason = "%d more to Soak" % (s.due - s.total)
		"upgrade":
			var affordable := false
			for id in vs.hand:
				affordable = affordable or (vs.cards[id].eligible)
			p.step = "Upgrade"
			if game.xp <= 0:
				p.text = "No XP to spend."
			elif affordable:
				p.text = "Tap a card to Upgrade it. Unspent XP is lost."
			else:
				p.text = "No card can be Upgraded with this XP."
			p.primary.label = "Continue"
			p.primary.enabled = true
	return p


static func _secondary(game, draft, vs: Dictionary) -> Array:
	var out := []
	var cavalier: bool = game.options.get("cavalier", false)
	var fusing: bool = draft.mode.begins_with("fuse")
	match game.phase:
		"challenge":
			if not cavalier and game.hand.size() == Game.HAND_SIZE:
				out.append({"id": "fuse", "label": "Unfuse" if draft.fuse != null else "Fuse", "icon": "fuse",
					"enabled": true, "active": fusing or draft.fuse != null, "reason": ""})
			var left: int = Game.MAX_DIVERTS - game.diverts
			var can: bool = left > 0 and game.deck.size() >= 2
			out.append({"id": "divert", "label": "Divert · %d" % left, "icon": "divert", "enabled": can,
				"active": draft.mode == "divert",
				"reason": "" if can else ("No Diverts left" if left <= 0 else "No other Key Card")})
			var enc: Dictionary = vs.encounter
			if enc != null and enc.kind == "enemy" and enc.data.ability == "ranged":
				out.append({"id": "give_up_reserve", "label": "Give up Reserve", "icon": "reserve",
					"enabled": true, "active": draft.give_up_reserve, "reason": ""})
		"final_journey", "final_enemy":
			if not cavalier:
				out.append({"id": "fuse", "label": "Unfuse" if draft.fuse != null else "Fuse", "icon": "fuse",
					"enabled": true, "active": fusing or draft.fuse != null, "reason": ""})
			if game.phase == "final_journey":
				out.append({"id": "regroup", "label": "Regroup", "icon": "regroup", "enabled": not game._regrouped,
					"active": draft.mode == "regroup", "reason": "" if not game._regrouped else "Already used"})
	if game.phase == "upgrade" and vs.undo > 0:
		out.append({"id": "undo", "label": "Undo Upgrade", "icon": "undo", "enabled": true, "active": false, "reason": ""})
	if draft.mode != "none":
		out.append({"id": "cancel", "label": "Cancel", "icon": "close", "enabled": true, "active": false, "reason": ""})
	return out


## A one-line account of the Encounter just resolved, for the Upgrade and Soak steps.
static func _recap(game) -> Dictionary:
	var r: Dictionary = game.result
	if r.is_empty() or not r.has("outcome"):
		return {}
	return {"outcome": r.outcome, "xp": r.xp, "damage": r.damage, "time_penalty": r.time_penalty,
		"knocked_out": r.get("knocked_out", false)}


static func _ending(game, lost_at: String) -> Variant:
	if game.phase == "won":
		var by_level := {}
		for id in game.cards:
			if not game.trash.has(id):
				var lv: int = game.cards[id].level
				by_level[lv] = by_level.get(lv, 0) + 1
		var rows := []
		var total := 0
		for lv in [4, 3, 2, 1]:
			if by_level.has(lv):
				rows.append({"level": lv, "count": by_level[lv], "points": lv * by_level[lv]})
				total += lv * by_level[lv]
		return {"won": true, "dragon": game.dragon.name, "score": total, "rows": rows, "trashed": game.trash.size()}
	if game.phase == "lost":
		var r: Dictionary = game.result
		var why := ""
		if r.has("move") and r.get("tier", 0) < 0:
			why = "Your Move of %d did not reach the first tier of %d." % [r.move, game.dragon.mp_tiers[0].mp.value]
		elif r.get("tier", 0) < 0:
			why = "Your Attack of %d did not reach the first tier of %d." % [r.get("attack", 0), game.dragon.hp_tiers[0].hp]
		else:
			why = "%s dealt %d damage, more than your Hand could Soak." % [game.dragon.name, r.get("damage", 0)]
		return {"won": false, "dragon": game.dragon.name, "score": 0, "where": lost_at, "why": why}
	return null
