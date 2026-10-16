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
	var pre_armor := attack
	if act.enhanced and act.type == "attack":
		attack = maxi(0, attack - _armor(enemy.armor, [act.element]))

	var dodge_ranged: bool = enemy.ability == "ranged" and s.get("ranged_discard", false) and s.get("has_reserve", false)
	var early: bool = enemy.initiative > initiative
	var forced := false
	if enemy.ability == "ranged" and not dodge_ranged:
		forced = not early
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

	var terms := []
	_spell_term(terms, "attack", s, act)
	var target := "initiative" if to_initiative else "attack"
	_boost_terms(terms, target, s, hardship)
	if attack != pre_armor:
		_term(terms, "attack", "Armor", "armor", attack - pre_armor, null, act.element)
	_term(terms, "initiative", "Element", "element", s.initiative, null)
	if early:
		var note := "Ranged: strikes first whatever the Initiative" if forced else ""
		_term(terms, "damage", "Early damage", "ability" if forced else "enemy", enemy.attack.value, null, note)
		if hardship == "ambush":
			_term(terms, "damage", "Ambush", "hardship", enemy.attack.value, null)
	_term(terms, "damage", "Combat damage", "enemy", combat_damage, null)
	_term(terms, "time", "Hazards", "hardship", time_penalty, null)
	return {
		"attack": attack, "initiative": initiative, "enhanced": act.enhanced,
		"outcome": result, "xp": 0 if result == "loss" else enemy.xp,
		"early": early, "early_damage": early_damage, "combat_damage": combat_damage,
		"time_penalty": time_penalty,
		"damage": early_damage + combat_damage + (time_penalty if hardship == "storm" else 0),
		"damage_element": enemy.attack.element,
		"discard_reserve": dodge_ranged or (enemy.ability == "freeze" and early),
		"poison": poison,
		"terms": terms,
	}


static func resolve_journey(journey: Dictionary, hardship, s: Dictionary) -> Dictionary:
	var reserve_boost: int = s.get("reserve_boost", 0)
	var act := action(s.spell, s.element, ["move"])
	var move: int = act.value + _boost(s, hardship)
	var reserve_added := 0
	if act.enhanced and act.element == journey.mp.element:
		reserve_added = reserve_boost
		move += reserve_boost
	var mp: int = journey.mp.value + (reserve_boost if journey.peril == "steep" else 0)
	var result := outcome(move, mp)
	var time_penalty: int = 0 if result == "complete" else journey.time_penalty
	var damage := 1 if journey.peril == "treacherous" and result != "complete" else 0
	var treacherous := damage
	if hardship == "storm":
		damage += time_penalty

	var terms := []
	_spell_term(terms, "move", s, act)
	_boost_terms(terms, "move", s, hardship)
	_term(terms, "move", "Reserve", "reserve", reserve_added, null, "enhanced Ether matches the MP")
	_term(terms, "target", "MP", "enemy", journey.mp.value, null)
	if journey.peril == "steep":
		_term(terms, "target", "Steep", "hardship", reserve_boost, null, "the Reserve's Boost")
	_term(terms, "damage", "Treacherous", "hardship", treacherous, null)
	if hardship == "storm":
		_term(terms, "damage", "Storm", "hardship", time_penalty, null)
	_term(terms, "time", "Time Penalty", "enemy", time_penalty, null)
	return {
		"move": move, "mp": mp, "enhanced": act.enhanced, "outcome": result,
		"xp": 0 if result == "loss" else journey.xp,
		"time_penalty": time_penalty, "damage": damage, "damage_element": "",
		"terms": terms,
	}


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


## One line of the math, reporting only: {sum, label, source, value, card, note}.
## Zero values are left out; the caller decides which lines always show.
static func _term(terms: Array, sum: String, label: String, source: String, value: int, card, note := "") -> void:
	if value != 0:
		terms.append({"sum": sum, "label": label, "source": source, "value": value, "card": card, "note": note})


## The Spell's line: its value for this Encounter and why. Absent with no Spell.
static func _spell_term(terms: Array, sum: String, s: Dictionary, act: Dictionary) -> void:
	if s.spell == null:
		return
	var note := ""
	if act.enhanced:
		note = "enhanced: Ether matches"
	elif act.value == 1 and not _fits(s.spell.basic.type, [act.type]):
		note = "counts as 1: no action fits"
	_term(terms, sum, "Spell", "spell", act.value, null, note)


## The Boost's line in `sum`, followed by Night Travel's cut when it applies.
static func _boost_terms(terms: Array, sum: String, s: Dictionary, hardship) -> void:
	_term(terms, sum, "Boost", "boost", s.boost, null)
	_term(terms, sum, "Night Travel", "hardship", _boost(s, hardship) - s.boost, null, "Boost less the Element's Initiative")


static func _boost(s: Dictionary, hardship) -> int:
	if hardship == "night_travel":
		return maxi(0, s.boost - s.initiative)
	return s.boost


static func _fits(type: String, kinds: Array) -> bool:
	return type == "flex" or kinds.has(type)


static func _as(type: String, kinds: Array) -> String:
	return kinds[0] if type == "flex" else type
