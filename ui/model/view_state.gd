extends RefCounted
## Turns a game and the player's draft into everything a screen needs to draw.
## Pure: the same game and draft always give the same result, and nothing is changed.
## This is the only UI file that reads the engine's internals.

const Game = preload("res://engine/game.gd")
const Rules = preload("res://engine/rules.gd")
const Art = preload("res://ui/model/art.gd")
const Emphasis = preload("res://ui/model/emphasis.gd")

const ROLE_NAMES := {"spell": "Spell", "element": "Element", "boost": "Boost"}
## The Roles of an Action Set as the Hand holds them, left to right (rulebook p. 15).
const ORDER := ["element", "spell", "boost"]
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
	# What each Level up from its own would cost each card in the Hand, so an
	# Upgrade, of one Level or several, shows its own.
	var costs := {}
	for id in game.hand:
		var steps := []
		var level: int = game.cards[id].level
		var cost = game.level_data(id).upgrade_cost
		while cost != null:
			steps.append(cost)
			level += 1
			cost = game.db.mage_level(id, level).upgrade_cost
		if not steps.is_empty():
			costs[id] = steps
	return {
		"phase": game.phase, "region": game.region, "xp": game.xp, "damage_due": game.damage_due,
		"deck": game.deck.duplicate(), "hand": game.hand.duplicate(),
		"discard": game.discard.duplicate(), "trash": game.trash.duplicate(),
		"levels": levels, "costs": costs, "offer": game.setup_offer.duplicate() if game.phase == "setup" else [],
		"encounter": _region_encounter(game),
	}


## The Region Encounter on the table, {kind, index, hardship}: the one the Key Card
## names, or the one just played until the next Hand is drawn; null otherwise.
static func _region_encounter(game) -> Variant:
	match game.phase:
		"challenge", "poison":
			return game.encounter() if game.key_card() != null else null
		"penalty", "upgrade":
			return game.faced.encounter if not game.faced.is_empty() else null
	return null



## extra: message (a refusal to show), previous_preview, lost_at (where the game was lost).
static func build(game, draft, db, extra := {}) -> Dictionary:
	var phase: String = game.phase
	var playing: bool = phase == "challenge" or phase == "final_journey" or phase == "final_enemy"
	var vs := {
		"phase": phase,
		"mode": draft.mode,
		"stage": _stage(game, db),
		"piles": {"deck": game.deck.size(), "discard": game.discard.size(), "trash": game.trash.size()},
		"hand": game.setup_offer.duplicate() if phase == "setup" else game.hand.duplicate(),
		"cards": {},
		"encounter": _encounter(game, db),
		"preview": null,
		"explain": {},
		"math": {},
		"sets": [],
		"active_slot": draft.active.duplicate(),
		"soak": null,
		"xp": game.xp,
		"recap": _recap(game),
		"ending": _ending(game, extra.get("lost_at", ""), extra.get("placing", [])),
		"message": extra.get("message", ""),
		"fuse_elements": draft.mode == "fuse_element",
		"fuse_pick": draft.fuse_pick.duplicate(),
		"played": _played(game),
		"key_target": extra.get("key_target"),
	}
	if playing:
		vs.preview = preview(game, draft, extra.get("previous_preview"))
		vs.explain = explain(game, draft)
		vs.math = math(game, vs.preview, vs.explain)
		vs.sets = _sets(game, draft)
	if phase == "upgrade":
		vs.xp = game.xp - staged_cost(game, draft)
		# All the XP there was to spend, before any Upgrade chosen: the bar it empties.
		vs["xp_total"] = game.xp
	# The XP kept between Encounters, for the bar (Persistent XP); -1 hides it. Nothing
	# spends it in the Final Battle, so it is not shown there.
	var regions_left: bool = not phase.begins_with("final") and phase != "won" and phase != "lost"
	vs["banked_xp"] = vs.xp if game.keeps_xp() and regions_left else -1
	if SOAK_PHASES.has(phase):
		var total := 0
		for id in draft.picks:
			total += game._soak_value(id)
		vs.soak = {"due": game.damage_due, "element": game.damage_element, "total": total,
			"covered": total >= game.damage_due, "poison": phase == "poison"}
	var ctx := Emphasis.context(game, draft, vs.explain,
		vs.encounter.get("effects", []) if vs.encounter != null else [])
	vs["next_role"] = ctx.next_role
	for id in vs.hand:
		vs.cards[id] = _card(game, draft, db, id, vs)
		vs.cards[id]["focus"] = Emphasis.focus(vs.cards[id], game.level_data(id), ctx)
		# The Reserve's Boost is adding to the Move, so the card is playing a part too.
		vs.cards[id]["reserve_boosts"] = vs.cards[id].reserve and vs.cards[id].focus.regions.has("boost")
		# After a battle: the role this card was just played as, so the Hand says it.
		vs.cards[id]["played_role"] = null
		if vs.played != null:
			for role in vs.played.roles:
				if vs.played.roles[role] == id:
					vs.cards[id]["played_role"] = [0, role]
	vs["held"] = draft.held
	vs["places"] = places(vs, game, draft)
	# A Reserve given up is out of play (specs/019 "Out of play").
	for p in vs.places:
		if p.given_up and p.card_id != null and vs.cards.has(p.card_id):
			vs.cards[p.card_id]["out_of_play"] = true
	for id in vs.hand:
		vs.cards[id]["place"] = null
	for pl in vs.places:
		if pl.card_id != null and vs.cards.has(pl.card_id):
			vs.cards[pl.card_id]["place"] = pl.key
	# The cards in no place, in Hand order: every card in setup and Soak, which have
	# no places; while building only a Fuse's tucked card, which sits behind its partner.
	vs["unplaced"] = vs.hand.filter(func(id): return vs.cards[id].place == null)
	vs["prompt"] = _prompt(game, draft, vs)
	vs["secondary"] = _secondary(game, draft, vs)
	# The action row's cells, Play's included (research R5): never fewer than three,
	# so Play keeps the right half until a third action joins.
	vs["action_cells"] = maxi(3, vs.secondary.size() + 1)
	vs["input_region"] = _input_region(game, draft, vs)
	# The Deck on the left side (specs/012 data-model.md).
	vs["top_card"] = _top_card(game, db)
	vs["key_face"] = _key_face(game, draft, db, vs)
	vs["note"] = note_for(draft, vs)
	vs["zoom"] = zoom_for({"phase": phase, "encounter": _region_encounter(game)}, extra.get("lost_at", ""))
	return vs


## The card on top of the Deck: the Region Card turned to this Region, or the Dragon
## Card in the Final Battle; none while the Deck is being prepared.
static func _top_card(game, db) -> Variant:
	if game.phase == "setup":
		return null
	if game.phase.begins_with("final") or game.phase == "won" or game.phase == "lost":
		return dragon_card_model(game.dragon)
	return region_card_model(db, game.region)


## The Key Card under the Region Card, as a card face draws it. After the Cleanup
## draw (poison included) it is the new top card; through Penalty and Upgrade, the
## card that named the Encounter just played.
static func _key_face(game, draft, db, vs: Dictionary) -> Variant:
	var id = null
	match game.phase:
		"challenge", "poison":
			id = game.key_card()
		"penalty", "upgrade":
			id = game.faced.get("key")
	if id == null:
		return null
	return _card(game, draft, db, id, vs)


## What lies on the Deck in the card's place (specs/013 data-model.md): a step to
## follow, the Soak, the XP to spend, or the Deck being prepared; null for the card.
## A Play's result and a refusal come and go with the sequence and the screen.
static func note_for(draft, vs: Dictionary) -> Variant:
	if draft.mode != "none":
		return {"kind": "mode"}
	if vs.get("soak") != null:
		return {"kind": "soak"}
	match vs.phase:
		"upgrade":
			return {"kind": "upgrade"}
		"setup":
			return {"kind": "setup"}
	return null


## Where the Deck's view rests in a state: on a Region Card tile ("enemy:2"), on the
## Dragon Card's MP or HP Tiers, or "" with nothing to zoom into. `state` needs only
## {phase, encounter}, so a snapshot answers too; `lost_at` says where a lost game
## ended (the engine only loses in the Final Battle).
static func zoom_for(state: Dictionary, lost_at := "") -> String:
	var enc = state.get("encounter")
	match state.phase:
		"challenge", "poison", "penalty", "upgrade":
			return "%s:%d" % [enc.kind, enc.index] if enc != null else ""
		"final_journey":
			return "mp"
		"final_enemy", "final_soak", "won":
			return "hp"
		"lost":
			return "mp" if lost_at == "the Final Journey" else "hp"
	return ""


## A Region Card, turned to `region` (specs/013 data-model.md): its name and
## number, and its eight Encounters as printed panels, Enemies 1-4 then Journeys 1-4,
## with every figure the panel shows. `pair` says which of the two physical cards it
## is, so turning to the other side can be told from changing cards; it is never
## shown. Hardships belong to the Key Card, so a panel carries only an Enemy's
## Ability or a Journey's Peril.
static func region_card_model(db, region: int) -> Dictionary:
	var r: Dictionary = db.region(region)
	var panels := []
	for kind in ["enemy", "journey"]:
		for index in range(1, 5):
			var d: Dictionary = db.encounter(region, kind, index)
			var enemy: bool = kind == "enemy"
			var p := {"key": "%s:%d" % [kind, index], "kind": kind, "index": index,
				"title": Art.encounter_name(region, kind, index), "art": Art.encounter(region, kind, index),
				"element": d.attack.element if enemy else d.mp.element, "xp": d.xp,
				"effect": d.ability if enemy else d.peril}
			if enemy:
				p["enemy"] = {"hp": d.hp, "initiative": d.initiative, "attack": d.attack.duplicate(), "armor": d.armor.duplicate(true)}
			else:
				p["journey"] = {"mp": d.mp.duplicate(), "time_penalty": d.time_penalty}
			panels.append(p)
	return {"kind": "region", "region": region, "name": r.name, "pair": r.card, "side": (region - 1) % 2, "panels": panels}


## The Dragon Card on top of the Deck in the Final Battle: its MP Tiers and HP Tiers
## are what the view zooms into.
static func dragon_card_model(dragon: Dictionary) -> Dictionary:
	return {"kind": "dragon", "id": dragon.id, "name": dragon.name, "title": dragon.title,
		"element": dragon.early_damage.element, "dragon": dragon,
		"art": Art.dragon(dragon.id), "targets": ["mp", "hp"]}


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
				if vs.cards[id].get("can_raise", false):
					return "hand"
	return "commit"


## The predicted result of committing the draft, shaped for display. Every figure
## is the engine's own; this only arranges them.
static func preview(game, draft, previous = null) -> Dictionary:
	var action: Dictionary = draft.to_action()
	var final: bool = game.phase != "challenge"
	var r: Dictionary = game.preview_final(action) if final else game.preview(action)
	var out := {"status": "ready", "missing": [], "reason": "", "comparisons": [], "verdict": "",
		"verdict_text": "", "aftermath": "", "rewards": {"xp": 0}, "costs": [], "fatal": false, "tier": -1,
		"figures": {}, "changed": []}
	# Against an Enemy each placed Boost waits for the player to send it to Attack or
	# to Initiative; until then there is no outcome to show.
	var targets := []
	if _boost_has_target(game):
		for i in draft.boost_unchosen():
			targets.append("Boost target" + (" %d" % (i + 1) if draft.set_count > 1 else ""))
	if r.has("error"):
		if INCOMPLETE_ERRORS.has(r.error) and not draft.empty_slots().is_empty():
			out.status = "incomplete"
			for slot in draft.empty_slots():
				var name: String = ROLE_NAMES[slot[1]]
				out.missing.append(name + (" %d" % (slot[0] + 1) if draft.set_count > 1 else ""))
			out.missing.append_array(targets)
		else:
			out.status = "blocked"
			out.reason = r.error
		return out
	if not targets.is_empty():
		out.status = "incomplete"
		out.missing = targets
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


## Whether a Boost can go to Attack or to Initiative here: against an Enemy.
static func _boost_has_target(game) -> bool:
	return game.phase == "final_enemy" or (game.phase == "challenge" and game.encounter().kind == "enemy")


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
	var hardship = enc.hardship
	var ability = enc.data.get("ability") if enc.kind == "enemy" else null
	# Each cost says what brought it, so a Narrow victory or a Loss reads as the harm
	# it does, not only as a badge.
	var hurt := []
	if enc.kind == "enemy":
		# An enemy that struck first has already hurt you, so a Complete victory
		# cannot say it fell untouched.
		out.aftermath = ({"complete": "It strikes first, but falls to your blow",
			"narrow": "It strikes first, and hits back as it falls",
			"loss": "It strikes first and stands: no XP, and it hits back"} if r.early else
			{"complete": "It falls before it can strike",
			"narrow": "It falls, but hits back as it does",
			"loss": "It stands: no XP, and it hits back"})[r.outcome]
		if r.early:
			var forced: bool = ability == "ranged" and enc.data.initiative <= r.initiative
			hurt.append([r.early_damage, ("from its Ranged shot" if forced else "as it strikes first")
				+ (", doubled by Ambush" if hardship == "ambush" else "")])
		if r.combat_damage > 0:
			hurt.append([r.combat_damage, "as it hits back"])
	else:
		out.aftermath = {"complete": "Through in good time",
			"narrow": "Through, but it takes time",
			"loss": "Turned back: no XP, and time lost"}[r.outcome]
		var treacherous: int = r.damage - (r.time_penalty if hardship == "storm" else 0)
		if treacherous > 0:
			hurt.append([treacherous, "from the Treacherous path"])
	if hardship == "storm" and r.time_penalty > 0:
		hurt.append([r.time_penalty, "from the Storm"])
	if r.damage > 0:
		out.costs.append({"id": "damage", "icon": "hp", "value": r.damage,
			"element": r.damage_element, "text": "Damage", "why": _damage_why(hurt)})
	if r.time_penalty > 0:
		out.costs.append({"id": "time", "icon": "time", "value": r.time_penalty, "element": "", "text": "Time penalty",
			"why": ("Hazards: %s off the Deck" if enc.kind == "enemy" else "Time Penalty: %s off the Deck") % _cards(r.time_penalty)})
	if r.get("poison", 0) > 0:
		out.costs.append({"id": "poison", "icon": "poison", "value": r.poison, "element": "", "text": "Poison next Hand",
			"why": "Poison: %d more damage on your next Hand" % r.poison})
	if r.get("discard_reserve", false):
		out.costs.append({"id": "reserve", "icon": "reserve", "value": 0, "element": "", "text": "Reserve discarded",
			"why": "Frozen: your Reserve is discarded" if ability == "freeze" and r.early else "Your Reserve is discarded to dodge the shot"})
	if _would_knock_out(game, draft, r):
		out.costs.append({"id": "knock_out", "icon": "down_arrow", "value": 0, "element": "", "text": "Knocked Out",
			"why": "Your Hand cannot Soak it all: Knocked Out"})


## The damage to Soak and what dealt it, from `hurt` ([amount, "as it hits back"]
## each): the amounts are left out when there is only one cause.
static func _damage_why(hurt: Array) -> String:
	if hurt.size() == 1:
		return "Damage to Soak, " + hurt[0][1]
	return "Damage to Soak: " + ", ".join(hurt.map(func(h): return "%d %s" % h))


## "1 card", "3 cards".
static func _cards(n: int) -> String:
	return "%d card%s" % [n, "" if n == 1 else "s"]


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
	# How the chase leaves you for the fight, by the tier reached: the top tier, the
	# lowest, or one between.
	out.aftermath = "You feel ready for this confrontation" if r.tier == tiers.size() - 1 \
		else ("True terror stands before you" if r.tier == 0 else "The real battle begins now")
	if r.time_penalty > 0:
		out.costs.append({"id": "time", "icon": "time", "value": r.time_penalty, "element": "", "text": "Time penalty",
			"why": "Tier time: %s off the Deck; any the Deck lacks hit you in the fight" % _cards(r.time_penalty)})


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
	var hurt := [[tiers[r.tier].attack.value, "as it strikes back"]]
	if r.early:
		hurt.append([d.early_damage.value, "as it strikes first"])
	if game.carried_damage > 0:
		hurt.append([game.carried_damage, "from time the Deck could not pay"])
	out.costs.append({"id": "damage", "icon": "hp", "value": r.damage,
		"element": d.early_damage.element, "text": "Damage to Soak", "why": _damage_why(hurt)})
	out.fatal = not r.survivable
	out.verdict = "loss" if out.fatal else out.comparisons[0].result
	out.verdict_text = "Your Hand cannot Soak this" if out.fatal else "Tier %d reached" % (r.tier + 1)


static func _stage(game, db) -> Dictionary:
	if game.phase.begins_with("final") or game.phase == "won" or game.phase == "lost":
		return {"kind": "final", "region": game.region, "name": game.dragon.name, "title": game.dragon.title,
			# The place first, the stage after it, muted (specs/019 TopBar).
			"heading": "%s, %s · Final Battle" % [game.dragon.name, game.dragon.title],
			"heading_parts": ["%s, %s" % [game.dragon.name, game.dragon.title], " · Final Battle"],
			"element": game.dragon.early_damage.element, "dragon": game.dragon.id, "art": Art.dragon(game.dragon.id)}
	var r: Dictionary = db.region(game.region)
	return {"kind": "region", "region": game.region, "name": r.name, "title": "",
		"heading": "%s · Region %d" % [r.name, game.region],
		"heading_parts": [r.name, " · Region %d" % game.region], "element": "", "dragon": game.dragon.id,
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


## The engine's explanation of the draft as it stands: the result and the `terms`
## behind it, even while a role is empty (`complete` false). Empty when the engine
## refuses the set outright.
static func explain(game, draft) -> Dictionary:
	var action: Dictionary = draft.to_action()
	var e: Dictionary = game.explain_final(action) if game.phase != "challenge" else game.explain(action)
	return {} if e.has("error") else e


## The math box (contracts/math-box.md): the result as sums of the engine's terms,
## each set against its target. No arithmetic here: totals and term values are
## copied from `explain`, outcomes from the preview. Empty when the engine refuses
## the set outright (the preview then says why).
static func math(game, pv: Dictionary, e: Dictionary) -> Dictionary:
	if e.is_empty():
		return {}
	var complete: bool = e.get("complete", false) and pv.status == "ready"
	var terms: Array = e.terms
	var by_sum := func(id: String) -> Array:
		return terms.filter(func(t): return t.sum == id)
	var out := {"complete": complete, "sums": [], "missing": pv.missing,
		"damage_terms": by_sum.call("damage"), "time_terms": by_sum.call("time")}
	var labels := {"attack": "Attack", "initiative": "Initiative", "move": "Move"}
	var ids: Array = ["move"] if e.has("move") else ["attack", "initiative"]
	for i in ids.size():
		var id: String = ids[i]
		var cmp: Dictionary = pv.comparisons[i] if complete and i < pv.comparisons.size() else {}
		var s := {"id": id, "label": labels[id], "icon": id, "terms": by_sum.call(id),
			"total": e[id] if complete else null, "target": _math_target(game, e, id, cmp, by_sum.call("target")),
			"result": cmp.get("result", ""), "note": "", "missing": [] if complete else pv.missing,
			"tier": null}
		if id == "initiative" and complete:
			s.note = cmp.get("note", "")
			# Ranged strikes first whatever the Initiative: say so, not "You strike first".
			for t in out.damage_terms:
				if t.note.begins_with("Ranged"):
					s.note = "%s · %d early damage" % [t.note, t.value]
		if game.phase != "challenge" and id != "initiative" and complete:
			s.tier = {"index": e.tier, "text": pv.verdict_text}
		out.sums.append(s)
	return out


## What a sum is set against: an Enemy's HP or Initiative, a Journey's MP (with its
## own terms when a Steep peril raises it), or the next tier in the Final Battle.
static func _math_target(game, e: Dictionary, id: String, cmp: Dictionary, target_terms: Array) -> Dictionary:
	if not cmp.is_empty():
		return {"value": cmp.target, "icon": cmp.target_icon,
			"terms": target_terms if id == "move" and target_terms.size() > 1 else []}
	# Incomplete: the target is known even though the total is not.
	var enc: Dictionary = game.encounter() if game.phase == "challenge" else {}
	match id:
		"attack":
			return {"value": enc.data.hp if not enc.is_empty() else game.dragon.hp_tiers[0].hp, "icon": "hp", "terms": []}
		"initiative":
			return {"value": enc.data.initiative if not enc.is_empty() else game.dragon.initiative, "icon": "initiative", "terms": []}
	if enc.is_empty():
		return {"value": game.dragon.mp_tiers[0].mp.value, "icon": "mp", "terms": []}
	return {"value": e.mp, "icon": "mp", "terms": target_terms if target_terms.size() > 1 else []}


## The places of the Hand, in the rulebook's order from the left: the Reserve, then
## each Action Set's Element, Spell and Boost, then the Final Enemy's extras, which
## have no Role (contracts/board-layout.md). Every card has one. A place is labelled
## with its Role and state, never a number: the math box shows what each card gives.
## After a battle the same places recap what was played and whether the Reserve
## stays. The Final Enemy keeps no Reserve.
static func places(vs: Dictionary, game = null, draft = null) -> Array:
	var out := []
	if vs.sets.is_empty():
		var p = vs.played
		if p == null:
			return out
		var r = p.reserve
		out.append(_place("reserve", 0, "reserve", "kept" if r != null and p.reserve_kept else "discarded", r,
			{"type": "inspect", "id": r} if r != null else null, _tip(vs, 0, "reserve", r)))
		for role in ORDER:
			var id = p.roles.get(role)
			out.append(_place("0/" + role, 0, role, "played" if id != null else "discarded", id,
				{"type": "inspect", "id": id} if id != null else null, _tip(vs, 0, role, id)))
		return _indexed(out)
	var held = draft.held if draft != null else null
	var idle: bool = held == null and vs.mode == "none"
	# One target at a time (specs/019 data-model "Place state"): with a card held, the
	# place it is aimed at (by the keyboard or the pointer), the rest open to it; with
	# none held, the empty Role the next card goes to.
	var aim = vs.get("key_target")
	var next_key := ""
	if held == null and draft != null and str(vs.get("next_role", "")) != "":
		next_key = "%d/%s" % [draft.active[0], vs.next_role]
	# With a card held, every other place takes it: a place with a card trades with it.
	var tap_for := func(id, target) -> Variant:
		if held != null:
			if id == held:
				return {"type": "put_down"}
			return {"type": "put", "target": {"card": id} if id != null else target}
		return {"type": "pick", "id": id} if id != null and idle else null
	var state_for := func(id, filled: bool, key := "", target = null) -> String:
		if held != null and id != held:
			var put = {"card": id} if id != null else target
			return "target" if aim != null and typeof(put) == typeof(aim) and put == aim else "open"
		if key != "" and key == next_key and not filled:
			return "target"
		return "filled" if filled else "empty"
	if draft == null or draft.with_reserve:
		var offered: bool = draft == null or draft.reserve_offered(vs.hand)
		var r = draft.reserve_card(vs.hand) if draft != null else null
		var given_up: bool = r != null and draft != null and draft.give_up_reserve
		var state: String = "inactive"
		if offered:
			state = state_for.call(r, r != null, "reserve", "reserve")
		if given_up:
			state = "given_up"
		var place := _place("reserve", 0, "reserve", state, r, tap_for.call(r, "reserve") if offered else null,
			_tip(vs, 0, "reserve", r))
		place["given_up"] = given_up
		# A rule of this Encounter that reads the Reserve: Steep raises the MP by its
		# Boost, Freeze can take it away. The place shows that rule's mark.
		var effects: Array = vs.encounter.get("effects", []) if vs.encounter != null else []
		for rule in ["steep", "freeze"]:
			if effects.has(rule):
				place["rule"] = rule
		out.append(place)
	var two: bool = vs.sets.size() > 1
	for i in vs.sets.size():
		var st: Dictionary = vs.sets[i]
		for role in ORDER:
			var id = st.roles.get(role)
			var place := _place("%d/%s" % [i, role], i, role, state_for.call(id, id != null, "%d/%s" % [i, role], [i, role]), id,
				tap_for.call(id, [i, role]), _tip(vs, i, role, id))
			place["set_start"] = two and i == 1 and role == ORDER[0]
			out.append(place)
	if draft != null:
		for id in draft.extras(vs.hand):
			out.append(_place("extra/" + id, -1, "extra", state_for.call(id, true), id, tap_for.call(id, null),
				vs.cards[id].name if vs.cards.has(id) else ""))
	return _indexed(out)


static func _indexed(places: Array) -> Array:
	for i in places.size():
		places[i]["index"] = i
	return places


static func _place(key: String, set_index: int, role: String, state: String, id, tap, tooltip: String) -> Dictionary:
	return {"key": key, "set": set_index, "role": role, "state": state, "card_id": id, "tap": tap,
		"tooltip": tooltip, "set_start": false, "given_up": false, "rule": "", "index": -1}


static func _tip(vs: Dictionary, set_index: int, role: String, id) -> String:
	var name: String = "Reserve" if role == "reserve" else ROLE_NAMES[role] + " %d" % (set_index + 1)
	if id != null and vs.cards.has(id):
		return "%s: %s" % [name, vs.cards[id].name]
	return name


static func _sets(game, draft) -> Array:
	var enemy: bool = game.phase == "final_enemy" or (game.phase == "challenge" and game.encounter().kind == "enemy")
	var out := []
	for i in draft.set_count:
		out.append({"roles": draft.sets[i].duplicate(), "boost_to": draft.boost_to[i], "show_boost_to": enemy})
	return out


## A card face up as it lies, with nothing chosen and no part to play: a Time
## Penalty's cards, which go from the Deck to the Discard without being in the Hand.
static func plain_card(game, db, id: String) -> Dictionary:
	var m: Dictionary = db.mage(id)
	var lv: Dictionary = game.level_data(id)
	return {
		"id": id, "name": m.name, "element": m.element, "level": game.cards[id].level,
		"max_level": m.levels.size(), "stats": lv,
		"state": "available", "role": null, "fuse": null, "reserve": false, "reserve_boosts": false,
		"eligible": true, "reason": "", "note": "", "note_icon": "", "match": false,
		"selection_order": -1,
		# Chosen in the Soak or Upgrade step: the face shows the card as it will become.
		"turned": false,
		"downgraded": game.downgraded.has(id),
		"fate": "",
		"alt": null,
		"key_name": Art.encounter_name(game.region, lv.encounter.type, lv.encounter.index),
	}


static func _card(game, draft, db, id: String, vs: Dictionary) -> Dictionary:
	var lv: Dictionary = game.level_data(id)
	var c := plain_card(game, db, id)
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
			c["soaks"] = value
			c.note_icon = "armor"
			c.selection_order = draft.picks.find(id)
			# A chosen card shows the Level it will be Downgraded to.
			c.turned = c.selection_order >= 0
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
			# A chosen card shows the Level it will be Upgraded to, once per tap while
			# the XP left and its Levels allow, then a Level back per tap down to where
			# it began. What is chosen is taken from the XP left until Confirm.
			var staged: int = draft.picks.count(id)
			var cost = db.mage_level(id, c.level + staged).upgrade_cost
			c.selection_order = draft.picks.find(id)
			c.turned = staged > 0
			c["can_raise"] = not c.downgraded and cost != null and cost <= vs.xp
			if c.turned:
				c.state = "selected"
				c.note = "%d XP" % _card_cost(game, db, id, staged)
				c.note_icon = "xp"
				c.alt = _alt(game, db, id, c.level + staged, "If Upgraded")
			elif c.downgraded:
				c.eligible = false
				c.reason = "Downgraded"
			elif cost == null:
				c.eligible = false
				c.reason = "Max Level"
			elif cost > vs.xp:
				c.eligible = false
				c.reason = "Costs %d XP" % cost
			else:
				c.note = "%d XP" % cost
				c.note_icon = "xp"
			if not c.turned and cost != null and not c.downgraded:
				c.alt = _alt(game, db, id, c.level + 1, "If Upgraded")
	return c


## The XP taking card `id` up `levels` Levels from its own costs.
static func _card_cost(game, db, id: String, levels: int) -> int:
	var cost := 0
	for k in levels:
		cost += int(db.mage_level(id, game.cards[id].level + k).upgrade_cost)
	return cost


## The XP the Upgrades chosen but not yet confirmed will take.
static func staged_cost(game, draft) -> int:
	var cost := 0
	var counted := {}
	for id in draft.picks:
		if not counted.has(id):
			counted[id] = true
			cost += _card_cost(game, game.db, id, draft.picks.count(id))
	return cost


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
	if c.state == "available" and draft.reserve_card(game.hand) == id:
		c.reserve = true
		c.state = "reserve"
	if draft.held == id:
		c.state = "held"
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
		"divert", "regroup":
			# The card chosen to discard, waiting for the step to be confirmed.
			if draft.mode_pick == id:
				c.state = "selected"
				c.selection_order = 0
				c.note = "Discard"
				c.note_icon = draft.mode


static func _prompt(game, draft, vs: Dictionary) -> Dictionary:
	var p := {"text": "", "step": "", "count": "", "primary": {"label": "", "enabled": false, "reason": "", "title": "", "kind": "primary"}}
	match game.phase:
		"setup":
			var n: int = draft.picks.size()
			p.text = "%s: choose %d of these cards to start at Level %d." % [
				DIFFICULTY_NAMES.get(game.options.get("difficulty", "normal"), ""), game.setup_picks, game.setup_level]
			p.primary.label = "Confirm  %d / %d" % [n, game.setup_picks]
			p.primary.enabled = n == game.setup_picks
			p.primary.reason = "Choose %d more" % (game.setup_picks - n)
		"challenge", "final_journey", "final_enemy":
			# While a set is built nothing is said: the cards show what each gives
			# (specs/013 FR-006). Fuse, Divert and Regroup say what each step asks.
			match draft.mode:
				"divert":
					p.step = "Divert"
					var left: int = Game.MAX_DIVERTS - game.diverts
					p.count = "%d Divert%s left" % [left, "" if left == 1 else "s"]
					if draft.mode_pick == null:
						p.text = "Choose a Hand card to discard along with the Key Card. A new Key Card is revealed."
					else:
						p.text = "Discard %s along with the Key Card? Press Divert to confirm, or choose another card." % _card_name(vs, draft.mode_pick)
				"regroup":
					p.step = "Regroup"
					if draft.mode_pick == null:
						p.text = "Choose one card to discard. The rest are shuffled back and you draw again."
					else:
						p.text = "Discard %s and shuffle the rest back to draw again? Press Regroup to confirm, or choose another card." % _card_name(vs, draft.mode_pick)
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
			# What a refused Play was, the title of the card that says why (specs/015).
			if pv.status == "incomplete":
				p.primary.reason = "Still needed: " + ", ".join(pv.missing)
				p.primary.title = "Still Needed"
				if pv.missing.all(func(m): return m.begins_with("Boost target")):
					p.primary.reason = "Choose whether the Boost adds to Attack or to Initiative."
					p.primary.title = "Boost Assignment"
			elif pv.status == "blocked":
				p.primary.reason = pv.reason
				p.primary.title = "Action Set"
			elif draft.mode != "none":
				p.primary.reason = "Finish or cancel " + p.step.get_slice(" ", 0)
				p.primary.title = p.step.get_slice(" ", 0)
			# A Divert or Regroup is confirmed with the primary action once its card is
			# chosen (specs/015).
			if draft.mode == "divert" or draft.mode == "regroup":
				p.primary.label = p.step
				p.primary.enabled = draft.mode_pick != null
				p.primary.reason = "" if p.primary.enabled else "Choose the card to discard first."
				p.primary.title = p.step
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
				affordable = affordable or vs.cards[id].get("can_raise", false)
			p.step = "Upgrade"
			var leftover := "Unspent XP carries over." if game.keeps_xp() else "Unspent XP is lost."
			if not draft.picks.is_empty():
				p.text = "Tap a card again to Upgrade it further, or take its Upgrades back. " + leftover
			elif game.xp <= 0:
				p.text = "No XP to spend."
			elif affordable:
				p.text = "Tap cards to Upgrade them, then Confirm. " + leftover
			else:
				p.text = "No card can be Upgraded with this XP."
			p.primary.label = "Confirm" if not draft.picks.is_empty() else "Continue"
			p.primary.enabled = true
	return p


static func _card_name(vs: Dictionary, id) -> String:
	var c: Dictionary = vs.get("cards", {}).get(id, {})
	return str(c.get("name", "that card"))


## The secondary actions for the action row, one per cell (specs/010 research R5,
## R8): Fuse, then Divert or Regroup, then, against a Ranged Enemy
## while the Reserve holds a card, Give up Reserve. A null entry leaves its cell
## blank, so Play keeps its half when an action is not on offer.
static func _secondary(game, draft, vs: Dictionary) -> Array:
	var out := []
	var cavalier: bool = game.options.get("cavalier", false)
	var fusing: bool = draft.mode.begins_with("fuse")
	var fuse := {"id": "fuse", "label": "Unfuse" if draft.fuse != null else "Fuse", "icon": "fuse",
		"enabled": true, "active": fusing or draft.fuse != null, "reason": ""}
	match game.phase:
		"challenge":
			out.append(fuse if not cavalier and game.hand.size() == Game.HAND_SIZE else null)
			var left: int = Game.MAX_DIVERTS - game.diverts
			var can: bool = left > 0 and game.deck.size() >= 2
			out.append({"id": "divert", "label": "Divert · %d" % left, "icon": "divert", "enabled": can,
				"active": draft.mode == "divert",
				"reason": "" if can else ("No Diverts left" if left <= 0 else "No other Key Card")})
		"final_journey", "final_enemy":
			out.append(fuse if not cavalier else null)
			if game.phase == "final_journey":
				out.append({"id": "regroup", "label": "Regroup", "icon": "regroup", "enabled": not game._regrouped,
					"active": draft.mode == "regroup", "reason": "" if not game._regrouped else "Already used"})
	var enc = vs.encounter
	if game.phase == "challenge" and enc != null and enc.kind == "enemy" and enc.data.get("ability") == "ranged" \
			and draft.reserve_card(game.hand) != null:
		while out.size() < 2:
			out.append(null)
		var on: bool = draft.give_up_reserve
		out.append({"id": "give_up_reserve", "label": "Give up Reserve", "icon": "ranged",
			"enabled": true, "active": on, "reason": "",
			"tooltip": ("Your Reserve is given up: this enemy's Ranged strike is ignored. Tap to keep it." if on
				else "Give up your Reserve to ignore this enemy's Ranged strike.")})
	# While a step is under way, the action that started it becomes its Cancel, in
	# its own cell, so the row never needs a button more than the actions themselves.
	if draft.mode != "none":
		var started: String = "fuse" if fusing else draft.mode
		var cancel := {"id": "cancel", "label": "Cancel", "icon": "close", "enabled": true, "active": true,
			"reason": "", "tooltip": "Cancel " + started.capitalize()}
		var at := -1
		for i in out.size():
			if out[i] != null and out[i].id == started:
				at = i
		if at >= 0:
			out[at] = cancel
		elif out.size() < 2:
			out.append(cancel)
		else:
			out[0] = cancel
	return out


static func _recap(game) -> Dictionary:
	var r: Dictionary = game.result
	if r.is_empty() or not r.has("outcome"):
		return {}
	return {"outcome": r.outcome, "xp": r.xp, "damage": r.damage, "time_penalty": r.time_penalty,
		"knocked_out": r.get("knocked_out", false)}


## `placing`: what the leaderboard says of this game, line by line (from PlayHistory).
static func _ending(game, lost_at: String, placing: Array = []) -> Variant:
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
		return {"won": true, "dragon": game.dragon.name, "score": total, "rows": rows, "trashed": game.trash.size(), "placing": placing}
	if game.phase == "lost":
		var r: Dictionary = game.result
		var why := ""
		if r.has("move") and r.get("tier", 0) < 0:
			why = "Your Move of %d did not reach the first tier of %d." % [r.move, game.dragon.mp_tiers[0].mp.value]
		elif r.get("tier", 0) < 0:
			why = "Your Attack of %d did not reach the first tier of %d." % [r.get("attack", 0), game.dragon.hp_tiers[0].hp]
		else:
			why = "%s dealt %d damage, more than your Hand could Soak." % [game.dragon.name, r.get("damage", 0)]
		return {"won": false, "dragon": game.dragon.name, "score": 0, "where": lost_at, "why": why, "placing": []}
	return null
