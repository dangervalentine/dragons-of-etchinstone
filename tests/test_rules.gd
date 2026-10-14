extends "res://tests/base.gd"

const Rules = preload("res://engine/rules.gd")

var db = CardDB.new()


func _enemy_set(card: String, level: int, element := "", over := {}) -> Dictionary:
	var s := {"spell": db.mage_level(card, level), "element": element, "initiative": 0,
		"boost": 0, "boost_to": "attack", "has_reserve": true, "ranged_discard": false}
	s.merge(over, true)
	return s


func _journey_set(card: String, level: int, element := "", over := {}) -> Dictionary:
	var s := {"spell": db.mage_level(card, level), "element": element, "initiative": 0,
		"boost": 0, "reserve_boost": 0}
	s.merge(over, true)
	return s


# --- action value ---

func test_action_is_basic_without_matching_element() -> void:
	var a = Rules.action(db.mage_level("DOE-A03", 2), "water", ["attack"])
	eq(a.value, 3, "value")
	eq(a.enhanced, false, "enhanced")


func test_action_is_enhanced_when_element_matches() -> void:
	var a = Rules.action(db.mage_level("DOE-A03", 2), "fire", ["attack"])
	eq(a.value, 8, "value")
	eq(a.enhanced, true, "enhanced")
	eq(a.element, "fire", "element")


func test_wrong_action_type_counts_as_one() -> void:
	# Burning Bridges only moves; against an enemy it is worth 1.
	eq(Rules.action(db.mage_level("DOE-A15", 2), "fire", ["attack"]).value, 1, "value")


func test_enhanced_of_wrong_type_falls_back_to_basic() -> void:
	# Determined March: basic attack 4, enhanced move 7 (shadow).
	var a = Rules.action(db.mage_level("DOE-A11", 2), "shadow", ["attack"])
	eq(a.value, 4, "value")
	eq(a.enhanced, false, "enhanced")


func test_flex_action_fits_either_encounter() -> void:
	eq(Rules.action(db.mage_level("DOE-A07", 2), "shadow", ["move"]).value, 5, "move")
	eq(Rules.action(db.mage_level("DOE-A07", 2), "shadow", ["attack"]).value, 5, "attack")


# --- enemies ---

func test_enemy_complete_victory_gives_xp_and_no_damage() -> void:
	# Region 1 enemy 1: hp 7, init 8, attack 1 lightning, armor lightning 1, xp 4.
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 1), null,
		_enemy_set("DOE-A03", 2, "fire", {"initiative": 8}))
	eq(r.outcome, "complete", "outcome")
	eq(r.xp, 4, "xp")
	eq(r.damage, 0, "damage")


func test_enemy_narrow_victory_gives_xp_and_combat_damage() -> void:
	# Region 1 enemy 2: hp 11, attack 2 fire. Basic attack 6 at level 4 is >= ceil(11/2).
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), null,
		_enemy_set("DOE-A03", 4, "", {"initiative": 4}))
	eq(r.outcome, "narrow", "outcome")
	eq(r.xp, 7, "xp")
	eq(r.damage, 2, "damage")
	eq(r.damage_element, "fire", "damage element")


func test_enemy_loss_gives_no_xp() -> void:
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), null,
		_enemy_set("DOE-A03", 2, "", {"initiative": 4}))
	eq(r.outcome, "loss", "outcome")
	eq(r.xp, 0, "xp")
	eq(r.damage, 2, "damage")


func test_slower_than_enemy_takes_early_damage_on_top() -> void:
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), null,
		_enemy_set("DOE-A03", 2, "", {"initiative": 3}))
	eq(r.early, true, "early")
	eq(r.damage, 4, "damage")


func test_equal_initiative_avoids_early_damage() -> void:
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), null,
		_enemy_set("DOE-A03", 2, "", {"initiative": 4}))
	eq(r.early, false, "early")


func test_boost_can_go_to_initiative() -> void:
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), null,
		_enemy_set("DOE-A03", 2, "", {"initiative": 2, "boost": 2, "boost_to": "initiative"}))
	eq(r.initiative, 4, "initiative")
	eq(r.attack, 3, "attack")
	eq(r.early, false, "early")


func test_boost_goes_to_attack() -> void:
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), null,
		_enemy_set("DOE-A03", 2, "", {"boost": 2}))
	eq(r.attack, 5, "attack")


func test_enemy_armor_reduces_matching_enhanced_attack() -> void:
	# Enhanced fire 8 into fire armor 1.
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), null,
		_enemy_set("DOE-A03", 2, "fire"))
	eq(r.attack, 7, "attack")


func test_enemy_armor_ignores_basic_attack() -> void:
	# Frostfire Wall basic 3 with no element into water armor 2.
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 3), null, _enemy_set("DOE-A04", 2))
	eq(r.attack, 3, "attack")


func test_ambush_doubles_early_damage() -> void:
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), "ambush", _enemy_set("DOE-A03", 2))
	eq(r.early_damage, 4, "early damage")


func test_hazards_cost_time_for_each_kind_of_damage() -> void:
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), "hazards", _enemy_set("DOE-A03", 2))
	eq(r.time_penalty, 2, "time penalty")


func test_storm_turns_time_penalty_into_damage() -> void:
	var j = Rules.resolve_journey(db.encounter(1, "journey", 1), "storm", _journey_set("DOE-A15", 2))
	eq(j.time_penalty, 2, "time penalty")
	eq(j.damage, 2, "damage")


func test_night_travel_reduces_boost_by_initiative() -> void:
	var r = Rules.resolve_enemy(db.encounter(1, "enemy", 2), "night_travel",
		_enemy_set("DOE-A03", 2, "", {"initiative": 1, "boost": 3}))
	eq(r.attack, 5, "attack")
	var r2 = Rules.resolve_enemy(db.encounter(1, "enemy", 2), "night_travel",
		_enemy_set("DOE-A03", 2, "", {"initiative": 6, "boost": 3}))
	eq(r2.attack, 3, "attack floor")


func test_ranged_enemy_hits_early_even_when_outpaced() -> void:
	# Region 2 enemy 1: ranged, init 6, attack 2.
	var r = Rules.resolve_enemy(db.encounter(2, "enemy", 1), null,
		_enemy_set("DOE-A03", 2, "", {"initiative": 9}))
	eq(r.early, true, "early")


func test_ranged_is_ignored_by_giving_up_the_reserve() -> void:
	var r = Rules.resolve_enemy(db.encounter(2, "enemy", 1), null,
		_enemy_set("DOE-A03", 2, "", {"initiative": 9, "ranged_discard": true}))
	eq(r.early, false, "early")
	eq(r.discard_reserve, true, "discard reserve")


func test_freeze_discards_reserve_after_early_damage() -> void:
	# Region 2 enemy 4: freeze, init 5.
	var slow = Rules.resolve_enemy(db.encounter(2, "enemy", 4), null, _enemy_set("DOE-A03", 2))
	eq(slow.discard_reserve, true, "discard when hit early")
	var fast = Rules.resolve_enemy(db.encounter(2, "enemy", 4), null,
		_enemy_set("DOE-A03", 2, "", {"initiative": 5}))
	eq(fast.discard_reserve, false, "keep when not hit early")


func test_poison_adds_one_per_kind_of_damage() -> void:
	# Region 3 enemy 3: poison, hp 11, init 9, attack 2.
	var both = Rules.resolve_enemy(db.encounter(3, "enemy", 3), null, _enemy_set("DOE-A03", 2))
	eq(both.poison, 2, "early and combat")
	var one = Rules.resolve_enemy(db.encounter(3, "enemy", 3), null,
		_enemy_set("DOE-A03", 2, "", {"initiative": 9}))
	eq(one.poison, 1, "combat only")


func test_slow_enemy_can_be_beaten_with_move() -> void:
	# Region 2 enemy 3: slow, hp 15. Burning Bridges level 4 enhanced move 9 is >= 8.
	var r = Rules.resolve_enemy(db.encounter(2, "enemy", 3), null, _enemy_set("DOE-A15", 4, "fire"))
	eq(r.attack, 9, "value")
	eq(r.outcome, "narrow", "outcome")


# --- journeys ---

func test_journey_complete_victory() -> void:
	# Region 1 journey 2: mp 8 water, time 1, xp 3. River Swiftness L4 enhanced move 12.
	var j = Rules.resolve_journey(db.encounter(1, "journey", 2), null, _journey_set("DOE-A08", 4, "water"))
	eq(j.outcome, "complete", "outcome")
	eq(j.xp, 3, "xp")
	eq(j.time_penalty, 0, "time")


func test_journey_narrow_victory_gives_xp_and_time_penalty() -> void:
	var j = Rules.resolve_journey(db.encounter(1, "journey", 2), null,
		_journey_set("DOE-A08", 2, "", {"boost": 1}))
	eq(j.move, 4, "move")
	eq(j.outcome, "narrow", "outcome")
	eq(j.xp, 3, "xp")
	eq(j.time_penalty, 1, "time")


func test_journey_loss() -> void:
	var j = Rules.resolve_journey(db.encounter(1, "journey", 1), null, _journey_set("DOE-A08", 2))
	eq(j.outcome, "loss", "outcome")
	eq(j.xp, 0, "xp")
	eq(j.time_penalty, 2, "time")


func test_reserve_boost_added_when_enhanced_move_matches_journey() -> void:
	var j = Rules.resolve_journey(db.encounter(1, "journey", 2), null,
		_journey_set("DOE-A08", 2, "water", {"reserve_boost": 2}))
	eq(j.move, 8, "move")


func test_reserve_boost_not_added_for_other_elements() -> void:
	var j = Rules.resolve_journey(db.encounter(1, "journey", 1), null,
		_journey_set("DOE-A08", 2, "water", {"reserve_boost": 2}))
	eq(j.move, 6, "move")


func test_steep_raises_mp_by_reserve_boost() -> void:
	# Region 3 journey 1: steep, mp 14.
	var j = Rules.resolve_journey(db.encounter(3, "journey", 1), null,
		_journey_set("DOE-A08", 2, "", {"reserve_boost": 2}))
	eq(j.mp, 16, "mp")


func test_treacherous_deals_one_damage_unless_complete() -> void:
	# Region 3 journey 3: treacherous, mp 10 fire.
	var fail = Rules.resolve_journey(db.encounter(3, "journey", 3), null, _journey_set("DOE-A08", 2))
	eq(fail.damage, 1, "damage on failure")
	var win = Rules.resolve_journey(db.encounter(3, "journey", 3), null,
		_journey_set("DOE-A08", 4, "water"))
	eq(win.damage, 0, "no damage on complete")


# --- armor ---

func test_armor_soaks_printed_value() -> void:
	eq(Rules.soak_value(db.mage_level("DOE-A04", 2), "fire"), 2, "soak")


func test_matching_armor_soaks_double() -> void:
	eq(Rules.soak_value(db.mage_level("DOE-A04", 2), "water"), 4, "soak")


func test_plain_armor_never_doubles() -> void:
	eq(Rules.soak_value(db.mage_level("DOE-A03", 2), ""), 1, "soak")


func test_glass_cannon_matching_armor_adds_one() -> void:
	eq(Rules.soak_value(db.mage_level("DOE-A04", 2), "water", true), 3, "soak")
