extends RefCounted
## Minimal assertion helpers for the headless test runner (tests/run.gd).

const CardDB = preload("res://engine/card_db.gd")

var errors: Array = []
var checks := 0


func eq(actual, expected, what := "") -> void:
	checks += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		errors.append("%s: expected %s, got %s" % [what, str(expected), str(actual)])


func ok(cond: bool, what := "") -> void:
	checks += 1
	if not cond:
		errors.append("%s: expected true" % what)
