extends "res://tests/base.gd"


func test_mage_level_returns_stats_for_that_level() -> void:
	var db = CardDB.new()
	var lv = db.mage_level("DOE-A03", 2)
	eq(lv.initiative, 1, "initiative")
	eq(lv.basic, {"type": "attack", "value": 3}, "basic")
	eq(lv.enhanced, {"type": "attack", "value": 8, "element": "fire"}, "enhanced")
	eq(lv.upgrade_cost, 4, "cost")


func test_sixteen_mage_cards() -> void:
	eq(CardDB.new().mage_ids().size(), 16, "count")


func test_mage_card_has_own_element() -> void:
	eq(CardDB.new().mage("DOE-A03").element, "water", "element")


func test_encounter_lookup_by_region_type_and_index() -> void:
	var db = CardDB.new()
	eq(db.encounter(1, "enemy", 2).hp, 11, "enemy hp")
	eq(db.encounter(1, "journey", 1).mp, {"value": 12, "element": "lightning"}, "journey mp")


func test_dragon_lookup() -> void:
	eq(CardDB.new().dragon("rodving").initiative, 9, "initiative")
