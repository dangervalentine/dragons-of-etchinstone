extends "res://tests/base.gd"

const Game = preload("res://engine/game.gd")

var db = CardDB.new()

# Key Cards at level 2 in region 1 used below:
#   DOE-A15 -> enemy 1   (hp 7, init 8, attack 1 lightning, xp 4)
#   DOE-A10 -> enemy 2   (hp 11, init 4, attack 2 fire, xp 7)
#   DOE-A08 -> journey 1 (mp 12 lightning, time 2, xp 5)
const FILLER := ["DOE-A05", "DOE-A10", "DOE-A09", "DOE-A12", "DOE-A14", "DOE-A16"]
const HAND := ["DOE-A03", "DOE-A13", "DOE-A11", "DOE-A07"]
# Destruction as Spell, fire Adapt as Element (enhanced 8), Determined March as Boost (+3).
const PLAY := {"spell": "DOE-A03", "element": "DOE-A13", "boost": "DOE-A11"}


func _game(hand: Array, deck: Array, opts := {}):
	var o := {"seed": 1, "dragon": "rodving"}
	o.merge(opts, true)
	var g = Game.new(db, o)
	g.hand = hand.duplicate()
	g.deck = deck.duplicate()
	g.discard = []
	for id in db.mage_ids():
		if not hand.has(id) and not deck.has(id):
			g.discard.append(id)
	return g


func _lv(g, ids: Array, level: int) -> void:
	for id in ids:
		g.cards[id].level = level


# --- setup ---

func test_new_game_deals_four_from_sixteen_level_two_cards() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving"})
	eq(g.hand.size(), 4, "hand")
	eq(g.deck.size(), 12, "deck")
	eq(g.region, 1, "region")
	eq(g.phase, "challenge", "phase")
	var levels := {}
	for id in g.cards:
		levels[g.cards[id].level] = true
	eq(levels.keys(), [2], "levels")


func test_same_seed_gives_same_shuffle() -> void:
	var a = Game.new(db, {"seed": 7, "dragon": "rodving"})
	var b = Game.new(db, {"seed": 7, "dragon": "rodving"})
	var c = Game.new(db, {"seed": 8, "dragon": "rodving"})
	eq(a.deck, b.deck, "same seed")
	ok(a.deck != c.deck or a.hand != c.hand, "different seed differs")


func _count(g, level: int) -> int:
	var n := 0
	for id in g.cards:
		n += 1 if g.cards[id].level == level else 0
	return n


func test_hard_difficulty_offers_five_drawn_cards_before_dealing() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving", "difficulty": "hard"})
	eq(g.phase, "setup", "phase")
	eq(g.setup_offer.size(), 5, "offer")
	eq(g.setup_picks, 2, "picks")
	eq(g.hand.size(), 0, "no hand yet")


func test_hard_difficulty_downgrades_the_two_chosen_cards() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving", "difficulty": "hard"})
	var picks: Array = [g.setup_offer[1], g.setup_offer[4]]
	eq(g.choose_setup_cards(picks), "", "choose")
	eq(g.cards[picks[0]].level, 1, "first pick")
	eq(g.cards[picks[1]].level, 1, "second pick")
	eq(_count(g, 1), 2, "level 1 cards")
	eq(g.phase, "challenge", "phase")
	eq(g.hand.size(), 4, "hand")
	eq(g.deck.size(), 12, "deck")


func test_easy_difficulty_upgrades_the_two_chosen_cards() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving", "difficulty": "easy"})
	g.choose_setup_cards(g.setup_offer.slice(0, 2))
	eq(_count(g, 3), 2, "level 3 cards")


func test_setup_choice_must_be_the_right_number_of_offered_cards() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving", "difficulty": "hard"})
	ok(g.choose_setup_cards([g.setup_offer[0]]) != "", "too few refused")
	ok(g.choose_setup_cards([g.setup_offer[0], g.setup_offer[0]]) != "", "duplicate refused")
	var outside: Array = g.deck.filter(func(id): return not g.setup_offer.has(id))
	ok(g.choose_setup_cards([g.setup_offer[0], outside[0]]) != "", "card outside the offer refused")
	eq(g.phase, "setup", "phase unchanged")
	eq(_count(g, 2), 16, "nothing changed")


func test_casual_difficulty_upgrades_four_of_the_five_drawn() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving", "difficulty": "casual"})
	eq(g.setup_offer.size(), 5, "offer")
	eq(g.setup_picks, 4, "picks")
	var picks: Array = g.setup_offer.slice(1)
	eq(g.choose_setup_cards(picks), "", "choose")
	for id in picks:
		eq(g.cards[id].level, 3, id)
	eq(_count(g, 3), 4, "level 3 cards")


func test_impossible_difficulty_needs_no_choice() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving", "difficulty": "impossible"})
	eq(g.phase, "challenge", "phase")
	eq(_count(g, 1), 5, "level 1 cards")


func test_dont_even_try_downgrades_seven() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving", "difficulty": "dont_even_try"})
	eq(_count(g, 1), 7, "level 1 cards")


func test_play_is_refused_during_setup() -> void:
	var g = Game.new(db, {"seed": 7, "dragon": "rodving", "difficulty": "hard"})
	ok(g.play({"spell": g.deck[0]}) != "", "refused")


# --- challenge phase ---

func test_key_card_picks_the_encounter() -> void:
	var g = _game(HAND, ["DOE-A10"] + FILLER)
	eq(g.encounter().kind, "enemy", "kind")
	eq(g.encounter().data.hp, 11, "hp")
	eq(g.encounter().hardship, null, "hardship")


func test_key_card_hardship_is_reported() -> void:
	# Sword of Light level 2: journey 1 with Night Travel.
	var g = _game(HAND, ["DOE-A02"] + FILLER)
	eq(g.encounter().kind, "journey", "kind")
	eq(g.encounter().hardship, "night_travel", "hardship")


func test_encounter_uses_key_card_current_level() -> void:
	var g = _game(HAND, ["DOE-A10"] + FILLER)
	_lv(g, ["DOE-A10"], 4)  # Rain of Blood level 4 points at enemy 1
	eq(g.encounter().data.hp, 7, "hp")


func test_divert_discards_key_card_and_chosen_hand_card() -> void:
	var g = _game(HAND, ["DOE-A15", "DOE-A10"] + FILLER.slice(2))
	eq(g.divert("DOE-A07"), "", "divert")
	eq(g.hand.size(), 3, "hand")
	eq(g.deck[0], "DOE-A10", "new key card")
	ok(g.discard.has("DOE-A15") and g.discard.has("DOE-A07"), "discarded")


func test_only_two_diverts_per_encounter() -> void:
	var g = _game(HAND, ["DOE-A15", "DOE-A10"] + FILLER.slice(2))
	g.divert("DOE-A07")
	g.divert("DOE-A11")
	ok(g.divert("DOE-A13") != "", "third divert refused")
	eq(g.hand.size(), 2, "hand")


func test_divert_needs_a_hand_card() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	ok(g.divert("DOE-A01") != "", "refused")


# --- action phase ---

func test_play_resolves_enemy_and_awaits_soak() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	eq(g.play(PLAY), "", "play")
	eq(g.result.outcome, "complete", "outcome")
	eq(g.result.attack, 11, "attack 8 + boost 3")
	eq(g.xp, 4, "xp")
	eq(g.damage_due, 1, "early damage")
	eq(g.phase, "penalty", "phase")


func test_boost_to_initiative_is_passed_through() -> void:
	var g = _game(HAND, ["DOE-A10"] + FILLER)
	var a := PLAY.duplicate()
	a["boost_to"] = "initiative"
	g.play(a)
	eq(g.result.initiative, 6, "initiative")
	eq(g.result.early, false, "early")


func test_play_without_damage_goes_straight_to_upgrade() -> void:
	# Journey 2 (mp 8 water) beaten outright by River Swiftness level 4.
	var g = _game(["DOE-A08", "DOE-A01", "DOE-A11", "DOE-A07"], ["DOE-A09"] + FILLER.slice(3))
	_lv(g, ["DOE-A08"], 4)
	eq(g.play({"spell": "DOE-A08", "element": "DOE-A01", "boost": "DOE-A11"}), "", "play")
	eq(g.result.outcome, "complete", "outcome")
	eq(g.phase, "upgrade", "phase")


func test_play_requires_a_spell() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	ok(g.play({"element": "DOE-A13", "boost": "DOE-A11"}) != "", "refused")
	eq(g.phase, "challenge", "phase unchanged")


func test_play_requires_all_three_roles_with_a_full_hand() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	ok(g.play({"spell": "DOE-A03", "element": "DOE-A13"}) != "", "refused")


func test_play_rejects_cards_not_in_hand_or_used_twice() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	ok(g.play({"spell": "DOE-A03", "element": "DOE-A13", "boost": "DOE-A01"}) != "", "not in hand")
	ok(g.play({"spell": "DOE-A03", "element": "DOE-A03", "boost": "DOE-A11"}) != "", "used twice")


func test_short_hand_after_diverting_needs_only_a_spell() -> void:
	var g = _game(HAND, ["DOE-A15", "DOE-A08", "DOE-A10"] + FILLER.slice(2))
	g.divert("DOE-A07")
	g.divert("DOE-A11")
	eq(g.play({"spell": "DOE-A03", "element": "DOE-A13"}), "", "play")
	eq(g.result.attack, 7, "enhanced 8 minus fire armor 1")


func test_fuse_lets_top_card_supply_any_element() -> void:
	# Frostfire Wall and Brute Force are both water; fused, Frostfire Wall counts as fire.
	var g = _game(["DOE-A03", "DOE-A04", "DOE-A01", "DOE-A11"], ["DOE-A15"] + FILLER)
	var a := {"spell": "DOE-A03", "element": "DOE-A04", "boost": "DOE-A11",
		"fuse": {"top": "DOE-A04", "bottom": "DOE-A01", "element": "fire"}}
	eq(g.play(a), "", "play")
	eq(g.result.enhanced, true, "enhanced")
	eq(g.result.initiative, 5, "top card keeps its initiative")


func test_fuse_needs_two_cards_of_the_same_element() -> void:
	var g = _game(["DOE-A03", "DOE-A04", "DOE-A13", "DOE-A11"], ["DOE-A15"] + FILLER)
	var a := {"spell": "DOE-A03", "element": "DOE-A04", "boost": "DOE-A11",
		"fuse": {"top": "DOE-A04", "bottom": "DOE-A13", "element": "fire"}}
	ok(g.play(a) != "", "refused")


func test_cavalier_rule_forbids_fusing() -> void:
	var g = _game(["DOE-A03", "DOE-A04", "DOE-A01", "DOE-A11"], ["DOE-A15"] + FILLER, {"cavalier": true})
	var a := {"spell": "DOE-A03", "element": "DOE-A04", "boost": "DOE-A11",
		"fuse": {"top": "DOE-A04", "bottom": "DOE-A01", "element": "fire"}}
	ok(g.play(a) != "", "refused")


func test_reserve_boost_reaches_journey_maths() -> void:
	# Journey 2 (mp 8 water). River Swiftness enhanced move 6 water, reserve Adapt boost 3.
	var g = _game(["DOE-A08", "DOE-A01", "DOE-A15", "DOE-A07"], ["DOE-A09"] + FILLER.slice(3))
	g.play({"spell": "DOE-A08", "element": "DOE-A01", "boost": "DOE-A15"})
	eq(g.result.move, 11, "6 + boost 2 + reserve boost 3")


# --- penalty phase ---

func test_journey_time_penalty_discards_from_the_deck() -> void:
	var g = _game(HAND, ["DOE-A08"] + FILLER)
	g.play(PLAY)  # Destruction cannot move: 1 + 3 is a loss, time penalty 2
	eq(g.result.outcome, "loss", "outcome")
	eq(g.deck.size(), 5, "deck")
	eq(g.deck[0], "DOE-A10", "top of deck")
	eq(g.phase, "upgrade", "phase")


func test_time_penalty_past_the_deck_becomes_damage() -> void:
	var g = _game(HAND, ["DOE-A08"])
	g.play(PLAY)
	eq(g.deck.size(), 0, "deck")
	eq(g.damage_due, 1, "damage")
	eq(g.phase, "penalty", "phase")


func test_soak_downgrades_the_chosen_card() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	g.play(PLAY)
	eq(g.soak(["DOE-A07"]), "", "soak")
	eq(g.cards["DOE-A07"].level, 1, "level")
	eq(g.phase, "upgrade", "phase")


func test_soak_must_cover_the_damage() -> void:
	# Enemy 2 with no initiative: early 2 + combat 2 = 4 fire damage. Destruction armor is 1.
	var g = _game(HAND, ["DOE-A10"] + FILLER)
	g.play({"spell": "DOE-A07", "element": "DOE-A03", "boost": "DOE-A11"})
	eq(g.damage_due, 4, "damage")
	ok(g.soak(["DOE-A03"]) != "", "too little refused")
	eq(g.phase, "penalty", "phase")
	eq(g.cards["DOE-A03"].level, 2, "nothing downgraded")


func test_soak_refuses_more_cards_than_needed() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	g.play(PLAY)
	ok(g.soak(["DOE-A07", "DOE-A11"]) != "", "refused")


func test_matching_armor_soaks_double_in_play() -> void:
	# 4 fire damage; Destruction level 3 has fire armor 2, which doubles.
	var g = _game(HAND, ["DOE-A10"] + FILLER)
	_lv(g, ["DOE-A03"], 3)
	g.play({"spell": "DOE-A07", "element": "DOE-A03", "boost": "DOE-A11"})
	eq(g.soak(["DOE-A03"]), "", "soak")


func test_downgrading_a_level_one_card_trashes_it() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	_lv(g, ["DOE-A07"], 1)
	g.play(PLAY)
	g.soak(["DOE-A07"])
	ok(g.trash.has("DOE-A07"), "trashed")
	ok(not g.hand.has("DOE-A07"), "out of hand")


func test_knock_out_downgrades_everything_and_discards_four() -> void:
	# Region 4 enemy 4 hits for 5 early + 5 combat; four level 1 cards soak 4.
	var hand := ["DOE-A03", "DOE-A15", "DOE-A01", "DOE-A13"]
	var g = _game(hand, ["DOE-A07"] + FILLER)
	g.region = 4
	_lv(g, hand, 1)
	g.play({"spell": "DOE-A03", "element": "DOE-A15", "boost": "DOE-A01"})
	eq(g.result.knocked_out, true, "knocked out")
	eq(g.trash.size(), 4, "trash")
	eq(g.deck.size(), 3, "deck")
	eq(g.phase, "upgrade", "phase")


# --- upgrade phase ---

func test_upgrade_spends_xp_and_raises_level() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	g.play(PLAY)
	g.soak(["DOE-A07"])
	eq(g.upgrade("DOE-A03"), "", "upgrade")  # cost 4
	eq(g.cards["DOE-A03"].level, 3, "level")
	eq(g.xp, 0, "xp")
	ok(g.upgrade("DOE-A13") != "", "no xp left")


func test_downgraded_card_cannot_be_upgraded() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	g.play(PLAY)
	g.soak(["DOE-A07"])
	ok(g.upgrade("DOE-A07") != "", "refused")


# --- cleanup ---

func test_cleanup_discards_action_set_keeps_reserve_and_refills() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	g.play(PLAY)
	g.soak(["DOE-A07"])
	eq(g.finish(), "", "finish")
	eq(g.phase, "challenge", "phase")
	eq(g.hand, ["DOE-A07", "DOE-A15", "DOE-A05", "DOE-A10"], "hand")
	ok(g.discard.has("DOE-A03") and g.discard.has("DOE-A13") and g.discard.has("DOE-A11"), "action set discarded")
	eq(g.xp, 0, "unspent xp lost")


func test_cleanup_discards_both_fused_cards() -> void:
	var g = _game(["DOE-A03", "DOE-A04", "DOE-A01", "DOE-A11"], ["DOE-A15"] + FILLER)
	g.play({"spell": "DOE-A03", "element": "DOE-A04", "boost": "DOE-A11",
		"fuse": {"top": "DOE-A04", "bottom": "DOE-A01", "element": "fire"}})
	g.soak(["DOE-A01"])
	g.finish()
	ok(g.discard.has("DOE-A01") and g.discard.has("DOE-A04"), "fused pair discarded")
	ok(not g.hand.has("DOE-A01"), "bottom card not kept as reserve")


func test_freeze_discards_the_reserve() -> void:
	# Region 2 enemy 4 freezes; Adapt (lightning) level 2 is its Key Card.
	var g = _game(["DOE-A03", "DOE-A13", "DOE-A11", "DOE-A15"], ["DOE-A07"] + FILLER)
	g.region = 2
	g.play(PLAY)
	g.soak(["DOE-A11", "DOE-A13", "DOE-A15"])  # 6 water damage: 3 + 2 + 1
	g.finish()
	ok(g.discard.has("DOE-A15"), "reserve discarded")
	ok(not g.hand.has("DOE-A15"), "reserve gone from hand")


func test_region_ends_when_fewer_than_five_cards_remain() -> void:
	var g = _game(HAND, ["DOE-A15"])
	g.play(PLAY)
	g.soak(["DOE-A07"])
	g.upgrade("DOE-A03")
	g.finish()
	eq(g.region, 2, "region")
	eq(g.hand.size(), 4, "hand")
	eq(g.deck.size(), 12, "deck")
	eq(g.cards["DOE-A03"].level, 3, "levels kept")
	eq(g.phase, "challenge", "phase")


func test_trashed_cards_stay_out_of_the_next_region() -> void:
	var g = _game(HAND, ["DOE-A15"])
	_lv(g, ["DOE-A07"], 1)
	g.play(PLAY)
	g.soak(["DOE-A07"])
	g.finish()
	eq(g.hand.size() + g.deck.size(), 15, "cards in play")


func test_after_region_four_comes_the_final_journey() -> void:
	var g = _game(HAND, ["DOE-A15"])
	g.region = 4
	g.play({"spell": "DOE-A03", "element": "DOE-A13", "boost": "DOE-A11", "boost_to": "initiative"})
	g.soak(["DOE-A11"])  # combat 2 + poison 1, landing now because the region is over
	g.finish()
	eq(g.phase, "final_journey", "phase")
	eq(g.hand.size(), 7, "hand")
	eq(g.deck.size(), 9, "deck")


# --- poison ---

func test_poison_hits_the_next_hand() -> void:
	# Region 3 enemy 3: poison, attack 2 fire. Early + combat means 2 poison.
	var g = _game(HAND, ["DOE-A01"] + FILLER)
	g.region = 3
	g.play({"spell": "DOE-A07", "element": "DOE-A03", "boost": "DOE-A11"})
	eq(g.damage_due, 4, "damage now")
	g.soak(["DOE-A11", "DOE-A07"])
	g.finish()
	eq(g.phase, "poison", "phase")
	eq(g.damage_due, 2, "poison damage")
	eq(g.soak(["DOE-A05"]), "", "soak poison")
	eq(g.phase, "challenge", "phase after")
	eq(g.cards["DOE-A05"].level, 1, "downgraded")


func test_poisoned_card_can_still_be_downgraded_next_encounter() -> void:
	var g = _game(HAND, ["DOE-A01"] + FILLER)
	g.region = 3
	g.play({"spell": "DOE-A07", "element": "DOE-A03", "boost": "DOE-A11"})
	g.soak(["DOE-A11", "DOE-A07"])
	g.finish()
	g.soak(["DOE-A05"])
	eq(g.downgraded, [], "fresh slate")


func test_poison_lands_now_when_the_region_is_ending() -> void:
	var g = _game(HAND, ["DOE-A01"])
	g.region = 3
	g.play({"spell": "DOE-A07", "element": "DOE-A03", "boost": "DOE-A11"})
	eq(g.damage_due, 6, "4 damage + 2 poison")


# --- final battle (Rodving: mp 20/23/28, hp 22/27/32, init 9, early 9 fire, armor fire 4) ---

const J_HAND := ["DOE-A08", "DOE-A03", "DOE-A11", "DOE-A06", "DOE-A07", "DOE-A15", "DOE-A13"]
const J_DECK := ["DOE-A01", "DOE-A02", "DOE-A04", "DOE-A05"]
# River Swiftness (water element from Destruction) and Fleet Footed (lightning from Adapt).
const J_SETS := [
	{"spell": "DOE-A08", "element": "DOE-A03", "boost": "DOE-A11"},
	{"spell": "DOE-A06", "element": "DOE-A07", "boost": "DOE-A15"},
]


func _final_journey():
	var g = _game(J_HAND, J_DECK)
	g.phase = "final_journey"
	return g


func test_final_journey_below_first_tier_loses() -> void:
	var g = _final_journey()  # level 2: (6 + 3) + (9 + 2) = 20 would pass, so weaken it
	_lv(g, ["DOE-A08", "DOE-A06"], 1)
	eq(g.play_final({"sets": J_SETS}), "", "play")
	eq(g.phase, "lost", "phase")
	eq(g.score(), 0, "score")


func test_final_journey_tier_sets_time_penalty() -> void:
	var g = _final_journey()
	g.play_final({"sets": J_SETS})  # 20: first tier, time penalty 3
	eq(g.result.move, 20, "move")
	eq(g.result.time_penalty, 3, "time penalty")
	eq(g.phase, "final_enemy", "phase")
	eq(g.hand, ["DOE-A05"], "one card left after three are discarded")
	for id in J_HAND:
		ok(g.discard.has(id), "journey hand discarded " + id)


func test_final_journey_top_tier() -> void:
	var g = _final_journey()
	_lv(g, ["DOE-A08", "DOE-A06"], 4)  # (12 + 3) + (14 + 2) = 31
	g.play_final({"sets": J_SETS})
	eq(g.result.time_penalty, 1, "time penalty")
	eq(g.hand, ["DOE-A02", "DOE-A04", "DOE-A05"], "hand")


func test_final_journey_needs_two_full_sets() -> void:
	var g = _final_journey()
	ok(g.play_final({"sets": [J_SETS[0], {"spell": "DOE-A06"}]}) != "", "refused")


func test_regroup_swaps_the_hand_once() -> void:
	var g = _final_journey()
	eq(g.regroup("DOE-A13"), "", "regroup")
	eq(g.hand.size(), 7, "hand")
	ok(g.discard.has("DOE-A13"), "discarded")
	for id in J_DECK:
		ok(g.hand.has(id), "drew " + id)
	ok(g.regroup(g.hand[0]) != "", "second regroup refused")


const E_HAND := ["DOE-A05", "DOE-A13", "DOE-A11", "DOE-A03", "DOE-A15", "DOE-A12"]
# Rain of Blood 14 fire + 6, Destruction 13 fire + 5; initiative 4 + 3.
const E_SETS := [
	{"spell": "DOE-A05", "element": "DOE-A13", "boost": "DOE-A11"},
	{"spell": "DOE-A03", "element": "DOE-A15", "boost": "DOE-A12"},
]


func _final_enemy(level := 4):
	var g = _game(E_HAND, [])
	_lv(g, E_HAND, level)
	g.phase = "final_enemy"
	return g


func test_final_enemy_subtracts_matching_armor_once() -> void:
	var g = _final_enemy()
	eq(g.play_final({"sets": E_SETS}), "", "play")
	eq(g.result.attack, 34, "20 + 18 - 4")
	eq(g.result.early, true, "initiative 7 is under 9")
	eq(g.damage_due, 24, "early 9 + third tier 15")
	eq(g.phase, "final_soak", "phase")


func test_final_enemy_boost_to_initiative_avoids_early_damage() -> void:
	var g = _final_enemy()
	var sets := [E_SETS[0].duplicate(), E_SETS[1]]
	sets[0]["boost_to"] = "initiative"
	g.play_final({"sets": sets})
	eq(g.result.early, false, "initiative 13")
	eq(g.result.attack, 28, "14 + 18 - 4")
	eq(g.damage_due, 24, "second tier attack")


func test_final_enemy_below_first_tier_loses() -> void:
	var g = _final_enemy(1)
	g.play_final({"sets": E_SETS})
	eq(g.phase, "lost", "phase")


func test_surviving_the_dragon_wins_and_scores_levels() -> void:
	var g = _final_enemy()
	g.play_final({"sets": E_SETS})
	# vs fire: Burning Bridges 6, Destruction 6, Rain of Blood 5, Determined March 4, Adapt 3
	eq(g.soak(["DOE-A15", "DOE-A03", "DOE-A05", "DOE-A11", "DOE-A13"]), "", "soak")
	eq(g.phase, "won", "phase")
	eq(g.score(), 5 * 3 + 4 + 10 * 2, "score")


func test_unsoakable_dragon_damage_loses() -> void:
	var g = _final_enemy()
	g.carried_damage = 10  # 34 damage against 28 armor
	g.play_final({"sets": E_SETS})
	eq(g.phase, "lost", "phase")


func test_final_enemy_allows_a_short_second_set() -> void:
	var g = _final_enemy()
	g.hand = E_HAND.slice(0, 4)
	eq(g.play_final({"sets": [E_SETS[0], {"spell": "DOE-A03"}]}), "", "play")
	eq(g.result.attack, 22, "20 + basic 6 - 4")


func test_too_few_cards_for_a_region_skips_to_the_final_battle() -> void:
	var g = _game(HAND, ["DOE-A15"])
	g.trash = g.discard
	g.discard = []
	_lv(g, ["DOE-A07"], 1)
	g.play(PLAY)
	g.soak(["DOE-A07"])  # trashed: four cards left, not enough for an Encounter
	g.finish()
	eq(g.phase, "final_journey", "phase")
	eq(g.hand.size(), 4, "hand")


# --- previews ---

func test_preview_matches_play_without_changing_anything() -> void:
	var g = _game(HAND, ["DOE-A08"] + FILLER)
	var p = g.preview(PLAY)
	eq(p.outcome, "loss", "outcome")
	eq(p.time_penalty, 2, "time penalty")
	eq(g.phase, "challenge", "phase")
	eq(g.deck.size(), 7, "deck untouched")
	eq(g.xp, 0, "xp untouched")
	g.play(PLAY)
	eq(g.result.move, p.move, "same move as play")


func test_preview_reports_why_an_action_is_refused() -> void:
	var g = _game(HAND, ["DOE-A15"] + FILLER)
	ok(g.preview({"spell": "DOE-A03"}).error != "", "error")


func test_preview_final_journey_reports_tier_without_moving_on() -> void:
	var g = _final_journey()
	var p = g.preview_final({"sets": J_SETS})
	eq(p.move, 20, "move")
	eq(p.tier, 0, "tier")
	eq(p.time_penalty, 3, "time penalty")
	eq(g.phase, "final_journey", "phase")
	eq(g.hand.size(), 7, "hand untouched")


func test_preview_final_enemy_reports_damage() -> void:
	var g = _final_enemy()
	var p = g.preview_final({"sets": E_SETS})
	eq(p.attack, 34, "attack")
	eq(p.damage, 24, "damage")
	eq(g.phase, "final_enemy", "phase")
