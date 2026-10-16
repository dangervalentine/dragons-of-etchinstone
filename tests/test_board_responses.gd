extends "res://tests/base.gd"
## The board's response to each action: one per event, each with a moving form and
## a still one for reduced motion, and every sequence step either answered or
## deliberately quiet.

const T = preload("res://ui/theme/tokens.gd")
const BoardResponse = preload("res://ui/model/board_response.gd")

const EVENTS := ["place", "take_back", "fuse", "divert", "regroup", "play", "hit_enemy",
	"take_damage", "soak", "upgrade", "encounter_won", "encounter_lost"]
const KINDS := ["flare", "shudder", "sweep", "dim"]
## Every step kind ui/fx/animator.gd handles.
const STEPS := ["play_cards", "tally", "verdict", "gain_xp", "damage", "pay_time", "poison_pending",
	"knock_out", "downgrade", "upgrade", "trash", "discard", "gather_shuffle", "stage_banner", "draw", "ending"]


func test_every_event_has_a_moving_and_a_still_form() -> void:
	eq(BoardResponse.TABLE.keys().size(), EVENTS.size(), "one entry per event")
	for e in EVENTS:
		ok(BoardResponse.TABLE.has(e), "an entry for " + e)
		if not BoardResponse.TABLE.has(e):
			continue
		var r: Dictionary = BoardResponse.TABLE[e]
		ok(["hand", "encounter", "header", "slot"].has(r.target), e + " answers at a zone")
		ok(["ether", "focus", "gold", "bad", "neutral"].has(r.colour), e + " has a colour")
		ok(KINDS.has(r.motion.kind), e + " moves in a known way")
		ok(r.motion.duration >= T.FAST and r.motion.duration <= T.REVEAL, e + " is quick, never long")
		ok(not r.still.is_empty(), e + " has a still form")


func test_every_sequence_step_is_answered_or_quiet() -> void:
	for kind in STEPS:
		var e := BoardResponse.for_step(kind, {"outcome": "complete", "won": true, "amount": 2}, "enemy")
		if e == "":
			ok(BoardResponse.QUIET_STEPS.has(kind), kind + " is quiet on purpose")
		else:
			ok(BoardResponse.TABLE.has(e), "%s answers with %s" % [kind, e])
	eq(BoardResponse.for_step("play_cards", {}, "enemy"), "hit_enemy", "cards played at an Enemy hit it")
	eq(BoardResponse.for_step("play_cards", {}, "journey"), "play", "cards played on a Journey surge")


func test_a_verdict_wins_or_loses() -> void:
	eq(BoardResponse.for_step("verdict", {"outcome": "complete"}, "enemy"), "encounter_won", "complete")
	eq(BoardResponse.for_step("verdict", {"outcome": "narrow"}, "enemy"), "encounter_won", "narrow")
	eq(BoardResponse.for_step("verdict", {"outcome": "loss"}, "enemy"), "encounter_lost", "loss")
	eq(BoardResponse.for_step("damage", {"amount": 0}, "enemy"), "", "no damage, no flash")
	eq(BoardResponse.for_step("damage", {"amount": 3}, "enemy"), "take_damage", "damage taken")
