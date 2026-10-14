extends "res://tests/base.gd"
## The player's uncommitted choices: slots, Fuse, modes and the action sent to the engine.

const Draft = preload("res://ui/model/turn_draft.gd")

var db = CardDB.new()


func _two_of_one_ether() -> Array:
	var ids: Array = db.mage_ids()
	for a in ids:
		for b in ids:
			if a != b and db.mage(a).element == db.mage(b).element:
				return [a, b]
	return []


func _two_of_different_ether() -> Array:
	var ids: Array = db.mage_ids()
	for b in ids:
		if db.mage(ids[0]).element != db.mage(b).element:
			return [ids[0], b]
	return []


func test_placing_fills_the_active_slot_and_advances() -> void:
	var d = Draft.new()
	eq(d.tap("a"), "", "tap a")
	eq(d.active, [0, "element"], "advanced to element")
	d.tap("b")
	d.tap("c")
	eq(d.sets[0], {"spell": "a", "element": "b", "boost": "c"}, "filled in order")
	ok(d.is_filled(), "one set is filled")
	eq(d.empty_slots(), [], "no empty slots")


func test_tapping_a_placed_card_takes_it_back_and_reopens_its_slot() -> void:
	var d = Draft.new()
	d.tap("a")
	d.tap("b")
	d.tap("a")
	eq(d.slot_of("a"), null, "a is back in the Hand")
	eq(d.active, [0, "spell"], "its slot is active again")
	d.tap("c")
	eq(d.sets[0].spell, "c", "the next card fills the reopened slot")


func test_selecting_a_slot_chooses_where_the_next_card_goes() -> void:
	var d = Draft.new()
	d.select_slot(0, "boost")
	d.tap("a")
	eq(d.sets[0], {"boost": "a"}, "placed in the chosen slot")
	eq(d.active, [0, "spell"], "then the first empty slot")


func test_a_card_fills_one_role_across_two_sets() -> void:
	var d = Draft.new()
	d.reset(2)
	for id in ["a", "b", "c", "d"]:
		d.tap(id)
	eq(d.slot_of("d"), [1, "spell"], "the fourth card starts the second set")
	d.tap("a")
	eq(d.slot_of("a"), null, "tapping again takes it back, never a second role")
	ok(not d.is_filled(), "two sets need six cards")


func test_fuse_flow_tucks_the_second_card_and_frees_its_slot() -> void:
	var pair := _two_of_one_ether()
	var d = Draft.new()
	d.tap(pair[1])
	d.begin_mode("fuse_pick")
	eq(d.pick_for_fuse(pair[0], db), "", "first pick")
	eq(d.pick_for_fuse(pair[1], db), "", "second pick")
	eq(d.mode, "fuse_element", "now choose the Ether")
	d.choose_fuse_element("fire")
	eq(d.fuse, {"top": pair[0], "bottom": pair[1], "element": "fire"}, "fused")
	eq(d.slot_of(pair[1]), null, "the tucked card fills no role")
	eq(d.mode, "none", "mode ends")
	ok(d.tap(pair[1]) != "", "a tucked card cannot be placed")
	eq(d.to_action().fuse, d.fuse, "the Fuse is part of the action")


func test_fusing_different_ethers_is_refused() -> void:
	var pair := _two_of_different_ether()
	var d = Draft.new()
	d.begin_mode("fuse_pick")
	d.pick_for_fuse(pair[0], db)
	ok(d.pick_for_fuse(pair[1], db) != "", "refused with a reason")
	eq(d.mode, "none", "mode ends")
	eq(d.fuse, null, "nothing fused")


func test_cancelling_any_mode_leaves_the_draft_as_it_was() -> void:
	var pair := _two_of_one_ether()
	var d = Draft.new()
	d.tap("x")
	var before: Dictionary = d.to_action()
	for m in ["divert", "regroup", "fuse_pick"]:
		d.begin_mode(m)
		d.cancel_mode()
		eq(d.to_action(), before, "cancel from " + m)
	d.begin_mode("fuse_pick")
	d.pick_for_fuse(pair[0], db)
	d.cancel_mode()
	eq(d.to_action(), before, "cancel after one Fuse pick")
	d.begin_mode("fuse_pick")
	d.pick_for_fuse(pair[0], db)
	d.pick_for_fuse(pair[1], db)
	d.cancel_mode()
	eq(d.to_action(), before, "cancel at the Ether choice")
	eq(d.mode, "none", "no mode")


func test_action_for_one_set() -> void:
	var d = Draft.new()
	for id in ["a", "b", "c"]:
		d.tap(id)
	d.toggle_boost_to(0)
	d.give_up_reserve = true
	eq(d.to_action(), {"spell": "a", "element": "b", "boost": "c", "boost_to": "initiative", "ranged_discard": true},
		"same shape the engine takes today")


func test_action_for_two_sets() -> void:
	var d = Draft.new()
	d.reset(2)
	for id in ["a", "b", "c", "d", "e", "f"]:
		d.tap(id)
	d.toggle_boost_to(1)
	eq(d.to_action(), {"sets": [
		{"spell": "a", "element": "b", "boost": "c", "boost_to": "attack"},
		{"spell": "d", "element": "e", "boost": "f", "boost_to": "initiative"}]}, "two sets")
	ok(d.is_filled(), "both sets filled")


func test_dropping_a_card_that_left_the_hand() -> void:
	var d = Draft.new()
	d.tap("a")
	d.tap("b")
	d.drop("a")
	eq(d.slot_of("a"), null, "forgotten")
	eq(d.active, [0, "spell"], "its slot is next")
