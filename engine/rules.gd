extends RefCounted
## Pure encounter maths. No game state: everything is passed in and a result is returned.
##
## An action set is a Dictionary:
##   spell          level data of the Spell card (see CardDB.mage_level), or null
##   element        Ether element supplied by the Element card, "" if none
##   initiative     Initiative of the Element card, 0 if none
##   boost          Boost of the Boost card, 0 if none
##   boost_to       "attack" or "initiative" (enemies only)
##   reserve_boost  Boost of the Reserve card, 0 if none (journeys only)
##   has_reserve / ranged_discard  (enemies only)


## The Spell's value for an encounter that accepts the given action types.
## Enhanced applies when the element matches and the enhanced action fits the
## encounter; otherwise the basic action if it fits; otherwise 1.
static func action(spell, element: String, kinds: Array) -> Dictionary:
	if spell == null:
		return {"value": 0, "enhanced": false, "element": "", "type": ""}
	var enh = spell.enhanced
	if element != "" and element == enh.element and _fits(enh.type, kinds):
		return {"value": enh.value, "enhanced": true, "element": enh.element, "type": _as(enh.type, kinds)}
	if _fits(spell.basic.type, kinds):
		return {"value": spell.basic.value, "enhanced": false, "element": "", "type": _as(spell.basic.type, kinds)}
	return {"value": 1, "enhanced": false, "element": "", "type": kinds[0]}


static func outcome(value: int, target: int) -> String:
	if value >= target:
		return "complete"
	if value >= ceili(target / 2.0):
		return "narrow"
	return "loss"


static func resolve_enemy(enemy: Dictionary, hardship, s: Dictionary) -> Dictionary:
	var boost := _boost(s, hardship)
	var to_initiative: bool = s.get("boost_to", "attack") == "initiative"
	var initiative: int = s.initiative + (boost if to_initiative else 0)
	var kinds := ["attack", "move"] if enemy.ability == "slow" else ["attack"]
	var act := action(s.spell, s.element, kinds)
	var attack: int = act.value + (0 if to_initiative else boost)
	if act.enhanced and act.type == "attack":
		attack = maxi(0, attack - _armor(enemy.armor, [act.element]))

	var dodge_ranged: bool = enemy.ability == "ranged" and s.get("ranged_discard", false) and s.get("has_reserve", false)
	var early: bool = enemy.initiative > initiative
	if enemy.ability == "ranged" and not dodge_ranged:
		early = true
	var early_damage: int = 0
	if early:
		early_damage = enemy.attack.value * (2 if hardship == "ambush" else 1)

	var result := outcome(attack, enemy.hp)
	var combat_damage: int = 0 if result == "complete" else enemy.attack.value
	var time_penalty := 0
	if hardship == "hazards":
		time_penalty = (1 if early else 0) + (1 if combat_damage > 0 else 0)
	var poison := 0
	if enemy.ability == "poison":
		poison = (1 if early else 0) + (1 if combat_damage > 0 else 0)
	return {
		"attack": attack, "initiative": initiative, "enhanced": act.enhanced,
		"outcome": result, "xp": 0 if result == "loss" else enemy.xp,
		"early": early, "early_damage": early_damage, "combat_damage": combat_damage,
		"time_penalty": time_penalty,
		"damage": early_damage + combat_damage + (time_penalty if hardship == "storm" else 0),
		"damage_element": enemy.attack.element,
		"discard_reserve": dodge_ranged or (enemy.ability == "freeze" and early),
		"poison": poison,
	}


static func resolve_journey(journey: Dictionary, hardship, s: Dictionary) -> Dictionary:
	var reserve_boost: int = s.get("reserve_boost", 0)
	var act := action(s.spell, s.element, ["move"])
	var move: int = act.value + _boost(s, hardship)
	if act.enhanced and act.element == journey.mp.element:
		move += reserve_boost
	var mp: int = journey.mp.value + (reserve_boost if journey.peril == "steep" else 0)
	var result := outcome(move, mp)
	var time_penalty: int = 0 if result == "complete" else journey.time_penalty
	var damage := 1 if journey.peril == "treacherous" and result != "complete" else 0
	if hardship == "storm":
		damage += time_penalty
	return {
		"move": move, "mp": mp, "enhanced": act.enhanced, "outcome": result,
		"xp": 0 if result == "loss" else journey.xp,
		"time_penalty": time_penalty, "damage": damage, "damage_element": "",
	}


## Damage a card soaks when Downgraded from the given level.
static func soak_value(level: Dictionary, damage_element: String, glass_cannon := false) -> int:
	var armor = level.armor
	if armor.element != null and armor.element == damage_element:
		return armor.value + 1 if glass_cannon else armor.value * 2
	return armor.value


## Sum of the armor entries matching any of the given elements, each element once.
static func _armor(armor: Array, elements: Array) -> int:
	var total := 0
	for a in armor:
		if elements.has(a.element):
			total += a.value
	return total


static func _boost(s: Dictionary, hardship) -> int:
	if hardship == "night_travel":
		return maxi(0, s.boost - s.initiative)
	return s.boost


static func _fits(type: String, kinds: Array) -> bool:
	return type == "flex" or kinds.has(type)


static func _as(type: String, kinds: Array) -> String:
	return kinds[0] if type == "flex" else type
