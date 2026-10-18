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
	d.set_boost_to(0, "initiative")
	d.give_up_reserve = true
	eq(d.to_action(), {"spell": "a", "element": "b", "boost": "c", "boost_to": "initiative", "ranged_discard": true},
		"same shape the engine takes today")


func test_action_for_two_sets() -> void:
	var d = Draft.new()
	d.reset(2)
	for id in ["a", "b", "c", "d", "e", "f"]:
		d.tap(id)
	d.set_boost_to(1, "initiative")
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


# Feature 009: the Hand in rulebook order. A card is picked up, then put in a place.

const HAND := ["a", "b", "c", "d"]


func test_held_and_reserve_start_empty_and_are_copied() -> void:
	var d = Draft.new()
	eq(d.held, null, "nothing held")
	eq(d.reserve, null, "no Reserve chosen")
	d.pick("a")
	d.put("reserve", HAND)
	d.pick("b")
	var c = d.duplicate_draft()
	eq(c.held, "b", "held is copied")
	eq(c.reserve, "a", "the Reserve is copied")
	d.reset()
	eq([d.held, d.reserve], [null, null], "reset clears both")


func test_a_dealt_hand_floats() -> void:
	var d = Draft.new()
	eq(d.extras(HAND), HAND, "every card floats, in Hand order")
	for id in HAND:
		eq(d.place_of(id, HAND), null, id + " has no place")
	eq(d.reserve_card(HAND), null, "no Reserve yet")


func test_pick_then_put_places_a_card() -> void:
	var d = Draft.new()
	eq(d.pick("c"), "", "picked")
	eq(d.held, "c", "held")
	eq(d.put([0, "element"], HAND), "", "put")
	eq(d.held, null, "no longer held")
	eq(d.sets[0], {"element": "c"}, "c is the Element")
	eq(d.place_of("c", HAND), [0, "element"], "its place")
	eq(d.extras(HAND), ["a", "b", "d"], "the rest float")
	eq(d.active, [0, "spell"], "the hint is the first empty Role")


func test_picking_the_held_card_again_puts_it_down() -> void:
	var d = Draft.new()
	d.pick("a")
	d.pick("a")
	eq(d.held, null, "put down")
	d.pick("b")
	d.put_down()
	eq(d.held, null, "put down")
	eq(d.sets[0], {}, "nothing placed")


func test_the_last_card_goes_to_the_reserve() -> void:
	var d = Draft.new()
	for pair in [["a", [0, "spell"]], ["b", [0, "element"]], ["c", [0, "boost"]]]:
		d.pick(pair[0])
		d.put(pair[1], HAND)
	eq(d.reserve_card(HAND), "d", "the one left over is the Reserve")
	eq(d.place_of("d", HAND), "reserve", "shown in the Reserve place")
	eq(d.extras(HAND), [], "nothing floats")
	eq(d.to_action(), {"spell": "a", "element": "b", "boost": "c", "boost_to": "attack", "ranged_discard": false},
		"the engine gets what tapping gave it before")


func test_a_card_can_be_put_in_the_reserve_first() -> void:
	var d = Draft.new()
	d.pick("b")
	eq(d.put("reserve", HAND), "", "the Reserve takes it")
	eq(d.reserve_card(HAND), "b", "b is the Reserve")
	eq(d.extras(HAND), ["a", "c", "d"], "it no longer floats")


func test_no_reserve_with_a_small_hand_or_in_the_final_enemy() -> void:
	var d = Draft.new()
	d.pick("a")
	ok(d.put("reserve", ["a", "b", "c"]) != "", "three cards fill the three Roles")
	eq(d.reserve, null, "nothing in the Reserve")
	d.reset(2, false)
	var seven := ["a", "b", "c", "d", "e", "f", "g"]
	d.pick("a")
	ok(d.put("reserve", seven) != "", "the Final Enemy keeps no Reserve")
	d.reset(2)
	d.pick("a")
	eq(d.put("reserve", seven), "", "the Final Journey does")


func test_a_tucked_card_cannot_be_picked_or_be_the_reserve() -> void:
	var pair := _two_of_one_ether()
	var hand := [pair[0], pair[1], "x", "y"]
	var d = Draft.new()
	d.pick(pair[1])
	d.put("reserve", hand)
	d.begin_mode("fuse_pick")
	d.pick_for_fuse(pair[0], db)
	d.pick_for_fuse(pair[1], db)
	d.choose_fuse_element("fire")
	eq(d.reserve, null, "the tucked card left the Reserve")
	ok(d.pick(pair[1]) != "", "it cannot be picked")
	eq(d.held, null, "nothing held")
	ok(not d.extras(hand).has(pair[1]), "it does not float either")


func test_dropping_forgets_held_and_reserve() -> void:
	var d = Draft.new()
	d.pick("a")
	d.put("reserve", HAND)
	d.pick("b")
	d.drop("a")
	d.drop("b")
	eq([d.held, d.reserve], [null, null], "both forgotten")


func test_starting_a_mode_puts_the_held_card_down() -> void:
	var d = Draft.new()
	d.pick("a")
	d.begin_mode("divert")
	eq(d.held, null, "nothing held during a Divert")


func _full(d) -> void:
	for pair in [["a", [0, "spell"]], ["b", [0, "element"]], ["c", [0, "boost"]]]:
		d.pick(pair[0])
		d.put(pair[1], HAND)


func test_two_placed_cards_swap() -> void:
	var d = Draft.new()
	_full(d)
	d.pick("c")
	d.put([0, "element"], HAND)
	eq(d.sets[0], {"spell": "a", "element": "c", "boost": "b"}, "the Boost and the Element trade places")
	eq(d.reserve_card(HAND), "d", "the Reserve is untouched")


func test_the_reserve_swaps_with_a_role() -> void:
	var d = Draft.new()
	_full(d)
	d.pick("d")
	d.put([0, "spell"], HAND)
	eq(d.sets[0].spell, "d", "the Reserve became the Spell")
	eq(d.reserve_card(HAND), "a", "the former Spell is the Reserve")
	eq(d.reserve, "a", "and is held there")


func test_a_floating_card_displaces_a_placed_one() -> void:
	var d = Draft.new()
	d.pick("a")
	d.put([0, "spell"], HAND)
	d.pick("b")
	d.put([0, "spell"], HAND)
	eq(d.sets[0], {"spell": "b"}, "b is the Spell")
	ok(d.extras(HAND).has("a"), "a floats again")


func test_a_fused_card_moves_with_its_partner() -> void:
	var pair := _two_of_one_ether()
	var hand := [pair[0], pair[1], "x", "y"]
	var d = Draft.new()
	d.begin_mode("fuse_pick")
	d.pick_for_fuse(pair[0], db)
	d.pick_for_fuse(pair[1], db)
	d.choose_fuse_element("fire")
	d.pick(pair[0])
	d.put([0, "element"], hand)
	d.pick(pair[0])
	d.put([0, "boost"], hand)
	eq(d.slot_of(pair[0]), [0, "boost"], "the top card moved")
	eq(d.fuse, {"top": pair[0], "bottom": pair[1], "element": "fire"}, "the Fuse is intact")
	eq(d.slot_of(pair[1]), null, "the tucked card fills no Role")
	ok(not d.extras(hand).has(pair[1]) and d.reserve_card(hand) != pair[1], "nor floats, nor is the Reserve")


# Feature 010: the Hand is dealt into its places in draw order; the player swaps.

func test_a_hand_is_dealt_in_draw_order() -> void:
	var d = Draft.new()
	d.deal(HAND)
	eq(d.reserve, "a", "the first card drawn is the Reserve")
	eq(d.sets[0], {"element": "b", "spell": "c", "boost": "d"}, "then Element, Spell, Boost")
	eq(d.extras(HAND), [], "every card has a place")
	eq(d.to_action(), {"spell": "c", "element": "b", "boost": "d", "boost_to": "attack", "ranged_discard": false},
		"the engine gets the same action as placing them by hand")


func test_a_short_hand_fills_the_spell_first() -> void:
	var d = Draft.new()
	d.deal(["a", "b", "c"])
	eq(d.sets[0], {"spell": "a", "element": "b", "boost": "c"}, "three cards: every Role, no Reserve")
	eq(d.reserve, null, "no Reserve")
	d.deal(["a", "b"])
	eq(d.sets[0], {"spell": "a", "element": "b"}, "two: Spell, then Element")
	d.deal(["a"])
	eq(d.sets[0], {"spell": "a"}, "one: the Spell")


func test_the_final_battle_is_dealt_in_rulebook_order() -> void:
	var seven := ["a", "b", "c", "d", "e", "f", "g"]
	var d = Draft.new()
	d.reset(2, true)
	d.deal(seven)
	eq(d.reserve, "a", "Final Journey: the Reserve first")
	eq(d.sets[0], {"element": "b", "spell": "c", "boost": "d"}, "then Set 1")
	eq(d.sets[1], {"element": "e", "spell": "f", "boost": "g"}, "then Set 2")
	var nine := ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
	d.reset(2, false)
	d.deal(nine)
	eq(d.reserve, null, "Final Enemy: no Reserve")
	eq(d.sets[0], {"element": "a", "spell": "b", "boost": "c"}, "Set 1 first")
	eq(d.sets[1], {"element": "d", "spell": "e", "boost": "f"}, "then Set 2")
	eq(d.extras(nine), ["g", "h", "i"], "the rest are extras, in Hand order")


func test_a_divert_moves_the_reserve_into_the_empty_role() -> void:
	var d = Draft.new()
	d.deal(HAND)
	d.drop("c")
	d.settle(["a", "b", "d"])
	eq(d.sets[0], {"element": "b", "spell": "a", "boost": "d"}, "the Reserve became the Spell")
	eq(d.reserve, null, "three cards keep no Reserve")


func test_a_fuse_moves_the_reserve_into_the_tucked_role() -> void:
	var pair := _two_of_one_ether()
	var hand := ["r", "x", pair[0], pair[1]]
	var d = Draft.new()
	d.deal(hand)
	eq(d.sets[0].boost, pair[1], "the second of the pair is the Boost")
	d.begin_mode("fuse_pick")
	d.pick_for_fuse(pair[0], db)
	d.pick_for_fuse(pair[1], db)
	d.choose_fuse_element("fire")
	d.settle(hand)
	eq(d.sets[0].boost, "r", "the Reserve took the tucked card's Role")
	eq(d.reserve, null, "a fused Hand of four keeps no Reserve")
	d.unfuse()
	d.settle(hand)
	eq(d.reserve, pair[1], "unfused, the freed card takes the first empty place")
	eq(d.extras(hand), [], "and nothing is left over")


func test_swapping_two_cards_trades_their_roles() -> void:
	var d = Draft.new()
	d.deal(HAND)
	d.swap("b", "d", HAND)
	eq(d.sets[0], {"element": "d", "spell": "c", "boost": "b"}, "Element and Boost traded")
	d.swap("c", "a", HAND)
	eq(d.sets[0].spell, "a", "the Reserve became the Spell")
	eq(d.reserve, "c", "and the Spell the Reserve")
	eq(d.held, null, "nothing left held")


func test_tapping_another_card_while_holding_one_swaps_them() -> void:
	var d = Draft.new()
	d.deal(HAND)
	d.pick("b")
	eq(d.put({"card": "c"}, HAND), "", "put on c")
	eq(d.sets[0], {"element": "c", "spell": "b", "boost": "d"}, "b and c traded")


func test_an_extra_swaps_into_a_role() -> void:
	var nine := ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
	var d = Draft.new()
	d.reset(2, false)
	d.deal(nine)
	d.swap("h", "b", nine)
	eq(d.sets[0].spell, "h", "the extra became the Spell")
	ok(d.extras(nine).has("b"), "the Spell became an extra")
	d.swap("b", "c", nine)
	eq(d.sets[0].boost, "b", "an extra put on a card takes its Role")
	ok(d.extras(nine).has("c"), "and that card becomes an extra")


func test_a_swap_keeps_the_boost_aim() -> void:
	var d = Draft.new()
	d.deal(HAND)
	d.set_boost_to(0, "initiative")
	d.swap("d", "a", HAND)
	eq(d.sets[0].boost, "a", "a new Boost")
	eq(d.boost_to[0], "initiative", "still aimed at Initiative")


func test_which_boost_a_row_tap_aims() -> void:
	var d = Draft.new()
	d.deal(HAND)
	eq(d.boost_target_set(null), 0, "one set: always that one")
	d.set_boost_to(0, "attack")
	eq(d.boost_target_set(null), 0, "even once aimed")
	var nine := ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
	d.reset(2, false)
	d.deal(nine)
	eq(d.boost_target_set(null), 0, "two sets: the first unaimed")
	d.set_boost_to(0, "attack")
	eq(d.boost_target_set(null), 1, "then the second")
	d.set_boost_to(1, "attack")
	eq(d.boost_target_set(null), -1, "both aimed: the player must pick one up")
	eq(d.boost_target_set("f"), 1, "the held Boost card's set")
	eq(d.boost_target_set("c"), 0, "Set 1's Boost")
	eq(d.boost_target_set("b"), -1, "a held Spell aims nothing")
