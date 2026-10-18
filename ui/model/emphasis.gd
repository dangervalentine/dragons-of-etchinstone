extends RefCounted
## Which parts of each Mage Card matter in the current step, so the face can lift
## them and quieten the rest: Armor while Soaking, the cost while Upgrading, the
## actions, Ether and Initiative or Boost as each slot comes up. Pure: the same game
## and draft always give the same focus. The table this follows is in
## specs/005-playfield-polish/contracts/step-emphasis.md.

const Rules = preload("res://engine/rules.gd")

const BUILDING := ["challenge", "final_journey", "final_enemy"]
const SOAKING := ["penalty", "poison", "final_soak"]
## The figures of the stat column, the ones a placed card can quieten.
const STAT_REGIONS := ["initiative", "basic", "enhanced", "boost", "armor"]
const ROLE_REGIONS := {"spell": ["basic", "enhanced"], "element": ["ether", "initiative"], "boost": ["boost"]}
## Figures an Upgrade changes, named as card regions.
const CHANGED_REGIONS := {"upgrade_cost": "cost", "encounter": "key", "hardship": "key"}


## What every card's focus depends on, worked out once per view state. `e` is the
## engine's explain for the draft (its `terms` decide what each card gives, specs/011
## research R1) and `effects` the Encounter's Hardship, ability and peril (R2).
static func context(game, draft, e := {}, effects := []) -> Dictionary:
	var phase: String = game.phase
	var ctx := {"phase": phase, "mode": draft.mode, "next_role": "", "kinds": [], "sets": [],
		"journey_ether": "", "reserve_counts": false, "damage_element": "", "xp": game.xp,
		"terms": e.get("terms", []), "effects": effects, "give_up_reserve": draft.give_up_reserve,
		"boost_to": draft.boost_to.duplicate(), "enemy": false}
	if SOAKING.has(phase):
		ctx.damage_element = game.damage_element
	if not BUILDING.has(phase):
		return ctx
	var a: Array = draft.active
	# The hint points the cards with no place (an extra, a short Hand's) at an empty
	# Role, except while a card is held.
	if draft.mode == "none" and draft.held == null and a[0] < draft.set_count and not draft.sets[a[0]].has(a[1]):
		ctx.next_role = a[1]
	match phase:
		"challenge":
			var enc: Dictionary = game.encounter()
			if enc.kind == "enemy":
				ctx.enemy = true
				ctx.kinds = ["attack", "move"] if enc.data.ability == "slow" else ["attack"]
			else:
				ctx.kinds = ["move"]
				ctx.journey_ether = enc.data.mp.element
		"final_journey":
			ctx.kinds = ["move"]
			ctx.journey_ether = game.dragon.mp_tiers[0].mp.element
		"final_enemy":
			ctx.enemy = true
			ctx.kinds = ["attack"]
	for i in draft.set_count:
		var s: Dictionary = draft.sets[i]
		var element := ""
		if s.get("element") != null:
			var fused: bool = draft.fuse != null and draft.fuse.top == s.element
			element = draft.fuse.element if fused else game.db.mage(s.element).element
		var spell = game.level_data(s.spell) if s.get("spell") != null else null
		ctx.sets.append({"element": element, "spell": spell})
		# The Reserve's Boost adds to Move when a Spell's enhanced action matches the journey.
		if spell != null and ctx.journey_ether != "":
			var act := Rules.action(spell, element, ctx.kinds)
			if act.enhanced and act.element == ctx.journey_ether:
				ctx.reserve_counts = true
	return ctx


## The focus for one card: {"regions": [...], "mark": "", "damage_element": "",
## "impacts": [{region, icon}], "aim": null or {"to": ...}}. `c` is the card model
## ViewState has built so far; `lv` its current Level's figures.
static func focus(c: Dictionary, lv: Dictionary, ctx: Dictionary) -> Dictionary:
	var out := {"regions": [], "mark": "", "damage_element": "", "impacts": [], "aim": null, "quiet": []}
	var phase: String = ctx.phase
	if BUILDING.has(phase):
		out.regions = _building(c, lv, ctx)
		var role = c.get("role")
		if ctx.enemy and ctx.mode == "none" and role != null and role[1] == "boost":
			out.aim = {"to": ctx.boost_to[role[0]]}
		if ctx.mode == "none":
			out.impacts = _impacts(c, ctx)
			# A placed card's other figures play no part: they step back a little.
			if c.get("role") != null or c.get("reserve", false):
				var marked: Array = out.impacts.map(func(m): return m.region)
				out.quiet = STAT_REGIONS.filter(func(r): return not out.regions.has(r) and not marked.has(r))
	elif SOAKING.has(phase):
		if not c.get("downgraded", false):
			out.regions = ["armor"]
			out.mark = "soaks_more" if c.get("match", false) else ""
		out.damage_element = ctx.damage_element
	elif phase == "upgrade" and not c.get("downgraded", false):
		out.regions = ["cost"]
		if lv.upgrade_cost == null:
			out.mark = "max_level"
		elif lv.upgrade_cost > ctx.xp:
			out.mark = "unaffordable"
		else:
			out.mark = "affordable"
			var alt = c.get("alt")
			if alt != null:
				for key in alt.changed:
					var region: String = CHANGED_REGIONS.get(key, key)
					if not out.regions.has(region):
						out.regions.append(region)
	return out


static func _building(c: Dictionary, lv: Dictionary, ctx: Dictionary) -> Array:
	var role = c.get("role")
	if role != null:
		if ctx.mode == "none" and not ctx.terms.is_empty():
			return _counted(role, ctx)
		if role[1] == "spell":
			var element: String = ctx.sets[role[0]].element
			if element == "":
				return ["basic", "enhanced"]
			return ["enhanced"] if Rules.action(lv, element, ctx.kinds).enhanced else ["basic"]
		return ROLE_REGIONS[role[1]].duplicate()
	match ctx.mode:
		"fuse_pick", "fuse_element":
			return ["ether"]
		"divert", "regroup":
			return []
	if c.get("reserve", false):
		if not ctx.terms.is_empty():
			return ["boost"] if ctx.terms.any(func(t): return t.source == "reserve") else []
		return ["boost"] if ctx.reserve_counts else []
	if c.get("state", "") == "fused_bottom" or ctx.next_role == "":
		return []
	return ROLE_REGIONS[ctx.next_role].duplicate()


## The parts of a placed card the engine counts (specs/011 research R1), read from its
## own terms: the Spell's action in effect (none when it counts as 1), the Element's
## Ether and, where it adds to Initiative, its Initiative, and the Boost while it adds.
static func _counted(role: Array, ctx: Dictionary) -> Array:
	var i: int = role[0]
	match role[1]:
		"spell":
			if ctx.sets[i].element == "":
				return ["basic", "enhanced"]
			var t = term_for(ctx.terms, "Spell", i)
			if t == null or t.note.begins_with("counts as 1"):
				return []
			return ["enhanced"] if t.note.begins_with("enhanced") else ["basic"]
		"element":
			var t = term_for(ctx.terms, "Element", i)
			return ["ether", "initiative"] if t != null and t.sum == "initiative" else ["ether"]
		"boost":
			return ["boost"] if term_for(ctx.terms, "Boost", i) != null else []
	return []


## The term the engine gave set `i`'s card in this role: labelled "Spell" in a Region,
## "Spell 1" and "Spell 2" in the Final Battle. Null when that card adds nothing.
static func term_for(terms: Array, name: String, i: int) -> Variant:
	for t in terms:
		var parts: PackedStringArray = t.label.split(" ")
		if parts[0] == name and (int(parts[1]) - 1 if parts.size() > 1 else 0) == i:
			return t
	return null


## What this Encounter works against on the card (specs/011 contracts/card-marks.md):
## Night Travel takes the Element's Initiative off the Boost, so it marks both; Steep
## raises the MP by the Reserve's Boost, and Ranged and Freeze can take the Reserve,
## so they mark it beside its Boost (Ranged until it is given up); Armor marks the
## enhanced attack it is taken from.
static func _impacts(c: Dictionary, ctx: Dictionary) -> Array:
	var out := []
	var role = c.get("role")
	var effects: Array = ctx.effects
	if role != null:
		if effects.has("night_travel") and role[1] == "boost":
			out.append({"region": "boost", "icon": "night_travel"})
		if effects.has("night_travel") and role[1] == "element":
			out.append({"region": "initiative", "icon": "night_travel"})
		if role[1] == "spell" and ctx.terms.any(func(t): return t.label == "Armor"):
			var t = term_for(ctx.terms, "Spell", role[0])
			if t != null and t.note.begins_with("enhanced"):
				out.append({"region": "enhanced", "icon": "armor"})
	elif c.get("reserve", false):
		for effect in ["steep", "ranged", "freeze"]:
			if effects.has(effect) and not (effect == "ranged" and ctx.give_up_reserve):
				out.append({"region": "boost", "icon": effect})
	return out
