extends "res://tests/base.gd"
## The lesson gate, Back and lesson progress (specs/017, research R4, data-model.md).

const Tutorial = preload("res://ui/model/tutorial.gd")
const Lessons = preload("res://ui/model/lessons.gd")

const PLAY := {"spell": "a", "element": "b", "boost": "c", "boost_to": "attack"}
const FIXTURE := {"id": "fixture", "steps": [
	{"text": "Read [[deck|this]].", "target": "deck", "wait": "next"},
	{"text": "And this.", "target": "screen", "wait": "next"},
	{"text": "Swap.", "target": "place:0/spell", "wait": "arrange", "expect": {"places": {"0/spell": "a", "reserve": "d"}}},
	{"text": "Play.", "target": "primary", "wait": "play", "expect": PLAY, "hint": "Play a, b, c."},
	{"text": "Watch.", "target": "screen", "wait": "sequence"},
	{"text": "Soak.", "target": "soak", "wait": "soak", "expect": {"picks": ["a", "b"]}, "hint": "Soak a and b."},
	{"text": "Raise.", "target": "xp", "wait": "upgrade", "expect": {"picks": ["a", "a"]}, "hint": "Raise a twice."},
	{"text": "Anything.", "target": "xp", "wait": "upgrade", "expect": {}},
	{"text": "Fuse.", "target": "action:fuse", "wait": "fuse_begin", "hint": "Press Fuse."},
	{"text": "Fire.", "target": "picker", "wait": "fuse_element", "expect": {"top": "a", "bottom": "b", "element": "fire"}, "hint": "Fire."},
]}


func _at(i: int):
	var t = Tutorial.new(FIXTURE)
	t.index = i
	t.floor_index = i
	return t


func test_read_steps_go_on_and_back_but_not_past_a_move() -> void:
	var t = Tutorial.new(FIXTURE)
	ok(t.reading(), "the first step is read")
	ok(not t.can_back(), "nothing to go back to")
	t.next()
	eq(t.index, 1, "next")
	ok(t.can_back(), "back is offered")
	t.back()
	eq(t.index, 0, "back")
	t.next()
	t.next()
	eq(t.index, 2, "on to the arrange step")
	t.next()
	eq(t.index, 2, "next does not pass a step that waits for a move")


func test_an_arrange_step_moves_on_when_the_places_match_and_never_refuses() -> void:
	var t = _at(2)
	t.draft_changed({"0/spell": "b", "reserve": "d"})
	eq(t.index, 2, "not yet")
	t.draft_changed({"0/spell": "a", "0/boost": "c", "reserve": "d"})
	eq(t.index, 3, "moved on")
	ok(not t.can_back(), "Back stops after the arrangement")


func test_the_guided_play_passes_and_others_are_refused() -> void:
	var t = _at(3)
	eq(t.check("play", PLAY), "", "the guided play")
	eq(t.check("play", {"spell": "a", "element": "b", "boost": "c"}), "", "a missing boost_to is Attack")
	eq(t.check("play", {"spell": "a", "element": "b", "boost": "c", "boost_to": "attack", "ranged_discard": false}), "", "ranged_discard is ignored")
	for wrong in [{"spell": "b", "element": "a", "boost": "c"}, {"spell": "a", "element": "b", "boost": "d"},
			{"spell": "a", "element": "b", "boost": "c", "boost_to": "initiative"},
			{"spell": "a", "element": "b", "boost": "c", "fuse": {"top": "b", "bottom": "d", "element": "fire"}}]:
		eq(t.check("play", wrong), "Play a, b, c.", "refused: %s" % [wrong])


func test_a_move_the_step_does_not_wait_for_is_not_yet() -> void:
	var t = _at(3)
	ok(t.check("soak", ["a"]).begins_with("Not yet"), "soak before its step")
	eq(t.check("divert", "a"), Tutorial.NOT_IN_LESSON, "divert")
	eq(t.check("fuse_begin"), Tutorial.NOT_IN_LESSON, "fuse")


func test_acting_and_sequences_move_on_and_fix_the_floor() -> void:
	var t = _at(3)
	t.acted("soak")
	eq(t.index, 3, "a move the step does not wait for changes nothing")
	t.acted("play")
	eq(t.index, 4, "played")
	ok(not t.can_back(), "no Back past the play")
	t.sequence_done()
	eq(t.index, 5, "the sequence ended")


func test_soak_is_a_set_and_upgrade_a_multiset() -> void:
	var t = _at(5)
	eq(t.check("soak", ["b", "a"]), "", "any order")
	eq(t.check("soak", ["a"]), "Soak a and b.", "too few")
	t = _at(6)
	eq(t.check("upgrade", ["a", "a"]), "", "twice")
	eq(t.check("upgrade", ["a"]), "Raise a twice.", "once is not enough")
	t.acted("upgrade")
	eq(t.index, 7, "one call covers the Upgrades and Cleanup")
	eq(t.check("upgrade", []), "", "{} takes none")
	eq(t.check("upgrade", ["x", "y"]), "", "{} takes any")


func test_fusing_is_checked_by_pair_and_ether() -> void:
	var t = _at(8)
	eq(t.check("fuse_begin"), "", "press Fuse")
	t.acted("fuse_begin")
	eq(t.check("fuse_element", {"top": "a", "bottom": "b", "element": "fire"}), "", "the guided Fuse")
	eq(t.check("fuse_element", {"top": "a", "bottom": "b", "element": "water"}), "Fire.", "wrong Ether")
	eq(t.check("fuse_element", {"top": "b", "bottom": "a", "element": "fire"}), "Fire.", "upside down")
	t.acted("fuse_element")
	ok(t.finished(), "the last step done")


func test_progress_is_in_order() -> void:
	var ids: Array = Lessons.ids()
	eq(Tutorial.first_unfinished([]), 0, "nothing done")
	eq(Tutorial.first_unfinished([ids[0]]), 1, "the first done")
	eq(Tutorial.first_unfinished([ids[0], ids[2]]), 1, "a gap is the first unfinished")
	eq(Tutorial.first_unfinished(ids), -1, "all done")
	ok(Tutorial.is_open(0, []), "the first lesson is open")
	ok(not Tutorial.is_open(1, []), "the second is not")
	ok(Tutorial.is_open(1, [ids[0]]), "it opens after the first")
	ok(not Tutorial.is_open(2, [ids[0]]), "one at a time")
	for i in ids.size():
		ok(Tutorial.is_open(i, ids), "all open once done: %d" % i)
