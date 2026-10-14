extends "res://tests/base.gd"
## Undoing an Upgrade puts the game back exactly as it was.

const Game = preload("res://engine/game.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const Undo = preload("res://ui/model/upgrade_undo.gd")

var db = CardDB.new()


func test_undo_restores_level_and_xp_and_the_upgrade_can_be_made_again() -> void:
	var g = Game.new(db, {"seed": 2, "difficulty": "normal"})
	g.phase = "upgrade"
	g.xp = 9
	var id: String = g.hand[0]
	var before: Dictionary = ViewState.snapshot(g)
	var entry: Dictionary = Undo.record(g, id)
	eq(g.upgrade(id), "", "upgraded")
	ok(ViewState.snapshot(g) != before, "something changed")
	Undo.undo(g, entry)
	eq(ViewState.snapshot(g), before, "everything is as it was")
	eq(g.upgrade(id), "", "and the Upgrade can be made again")


func test_undo_does_nothing_once_the_step_is_over() -> void:
	var g = Game.new(db, {"seed": 2, "difficulty": "normal"})
	g.phase = "upgrade"
	g.xp = 9
	var id: String = g.hand[0]
	var entry: Dictionary = Undo.record(g, id)
	g.upgrade(id)
	var level: int = g.cards[id].level
	g.phase = "challenge"
	Undo.undo(g, entry)
	eq(g.cards[id].level, level, "unchanged")
