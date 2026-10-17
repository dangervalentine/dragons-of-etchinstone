extends RefCounted
## Which parts of each Mage Card matter in the current step, so the face can lift
## them and quieten the rest: Armor while Soaking, the cost while Upgrading, the
## actions, Ether and Initiative or Boost as each slot comes up. Pure: the same game
## and draft always give the same focus. The table this follows is in
## specs/005-playfield-polish/contracts/step-emphasis.md.

const Rules = preload("res://engine/rules.gd")

const BUILDING := ["challenge", "final_journey", "final_enemy"]
const SOAKING := ["penalty", "poison", "final_soak"]
const ROLE_REGIONS := {"spell": ["basic", "enhanced"], "element": ["ether", "initiative"], "boost": ["boost"]}
## Figures an Upgrade changes, named as card regions.
const CHANGED_REGIONS := {"upgrade_cost": "cost", "encounter": "key", "hardship": "key"}


## What every card's focus depends on, worked out once per view state.
static func context(game, draft) -> Dictionary:
	var phase: String = game.phase
	var ctx := {"phase": phase, "mode": draft.mode, "next_role": "", "kinds": [], "sets": [],
		"journey_ether": "", "reserve_counts": false, "damage_element": "", "xp": game.xp}
	if SOAKING.has(phase):
		ctx.damage_element = game.damage_element
	if not BUILDING.has(phase):
		return ctx
	var a: Array = draft.active
	# The hint points the floating cards at the next Role, except while one is held.
	if draft.mode == "none" and draft.held == null and a[0] < draft.set_count and not draft.sets[a[0]].has(a[1]):
		ctx.next_role = a[1]
	match phase:
		"challenge":
			var enc: Dictionary = game.encounter()
			if enc.kind == "enemy":
				ctx.kinds = ["attack", "move"] if enc.data.ability == "slow" else ["attack"]
			else:
				ctx.kinds = ["move"]
				ctx.journey_ether = enc.data.mp.element
		"final_journey":
			ctx.kinds = ["move"]
			ctx.journey_ether = game.dragon.mp_tiers[0].mp.element
		"final_enemy":
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


## The focus for one card: {"regions": [...], "mark": "", "damage_element": ""}.
## `c` is the card model ViewState has built so far; `lv` its current Level's figures.
static func focus(c: Dictionary, lv: Dictionary, ctx: Dictionary) -> Dictionary:
	var out := {"regions": [], "mark": "", "damage_element": ""}
	var phase: String = ctx.phase
	if BUILDING.has(phase):
		out.regions = _building(c, lv, ctx)
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
		return ["boost"] if ctx.reserve_counts else []
	if c.get("state", "") == "fused_bottom" or ctx.next_role == "":
		return []
	return ROLE_REGIONS[ctx.next_role].duplicate()
