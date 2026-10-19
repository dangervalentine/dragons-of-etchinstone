extends "res://tests/base.gd"
## The notes laid on the Deck as cards (specs/015): which are dealt on and which
## thrown off, how they lie, and how they come and go.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const NotePile = preload("res://ui/widgets/note_pile.gd")

const REST := Rect2(20, 30, 300, 420)


# ---------------------------------------------------------------- pure

func test_plan_deals_what_is_wanted_and_throws_what_is_done() -> void:
	var rows := [
		[[], ["result"], 0, ["result"], "the tally"],
		[["result"], ["result", "soak"], 0, ["soak"], "damage to Soak"],
		[["result", "soak"], ["result", "upgrade"], 0, ["upgrade"], "the Soak done, XP to spend"],
		[["result", "soak", "upgrade"], [], 3, [], "zoom out to the next Encounter"],
		[["result", "soak", "upgrade"], ["result", "soak"], 1, [], "undo back to the Soak"],
		[["mode"], [], 1, [], "a Fuse cancelled or done"],
		[[], ["result", "soak"], 0, ["result", "soak"], "a skip straight to the after state"],
	]
	for r in rows:
		eq(NotePile.plan(r[0], r[1]), {"throw": r[2], "deal": r[3]}, r[4])
	eq(NotePile.plan([], []), {"throw": 0, "deal": []}, "nothing lying, nothing wanted")


func test_tilt_by_depth() -> void:
	eq(NotePile.tilt(0), 0.0, "the top lies square")
	eq(NotePile.tilt(1), deg_to_rad(-1.2), "the one under it tilts")
	eq(NotePile.tilt(5), deg_to_rad(-0.6), "deeper ones repeat the last")


func test_off_table_is_past_the_left_of_the_screen() -> void:
	eq(NotePile.off_table(REST, 40.0), Vector2(-40.0 - 360.0, 30.0), "a card's width and a fifth left of the screen")


# ---------------------------------------------------------------- the pile

func _pile() -> Control:
	var p = NotePile.new()
	# What a card says is not what these check: fill it with nothing.
	p.fill = func(_c, _k, _vs, _rv): pass
	p.size = Vector2(400, 600)
	p.lay_out(REST)
	return p


func test_cards_pile_up_and_are_thrown_together() -> void:
	var p = _pile()
	p.sync(["result"], {}, {}, false)
	eq(p.kinds(), ["result"], "the result is dealt")
	p.sync(["result", "soak"], {}, {}, false)
	eq(p.kinds(), ["result", "soak"], "the Soak on top of it")
	eq(p.top(), p.card("soak"), "the Soak is the top")
	p.sync([], {}, {}, false)
	p.finish()
	eq(p.kinds(), [], "all thrown once nothing is wanted")
	ok(not p.is_showing(), "nothing lies on the Deck")
	p.free()


func test_one_refusal_card_at_most() -> void:
	var p = _pile()
	p.show_refusal("Aim the Boost", false)
	var first = p.refusal_card
	p.show_refusal("Aim the Boost first", false)
	ok(p.refusal_card == first, "a second refusal is the same card")
	eq(p.refusal_text(), "Aim the Boost first", "with the new reason")
	eq(p.kinds(), [], "and is not part of the pile")
	p.free()


func test_a_missing_panel_is_a_hidden_spare() -> void:
	var p = _pile()
	var spare = p.panel("xp_purse")
	ok(spare != null and not spare.visible, "no XP card: a hidden purse")
	ok(p.panel("xp_purse") == spare, "the same spare each time")
	p.free()


func test_an_undo_throws_only_what_lies_above() -> void:
	var p = _pile()
	p.sync(["result"], {}, {}, false)
	p.sync(["result", "soak"], {}, {}, false)
	p.sync(["result", "upgrade"], {}, {}, false)
	eq(p.kinds(), ["result", "soak", "upgrade"], "the XP over the Soak over the result")
	p.sync(["result", "soak"], {}, {}, false)
	eq(p.kinds(), ["result", "soak"], "undone back to the Soak: only the XP goes")
	p.free()


func test_a_refusal_is_thrown_alone() -> void:
	var p = _pile()
	p.sync(["result", "soak"], {}, {}, false)
	p.show_refusal("Aim the Boost", false)
	p.clear_refusal(false)
	eq(p.kinds(), ["result", "soak"], "the pile under it stays")
	ok(p.refusal_card == null, "the refusal is gone")
	p.free()
