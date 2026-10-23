extends "res://tests/base.gd"
## The tab row (specs/019 contracts/components.md "Tabs"): one selected, choosing moves
## the brass rim and says so, and every tab is a tap target.

const T = preload("res://ui/theme/tokens.gd")
const TabRow = preload("res://ui/widgets/tab_row.gd")


func _row() -> Object:
	var row = TabRow.new()
	row.setup([{"id": "a", "text": "All dragons"}, {"id": "b", "text": "Rodving"}, {"id": "c", "text": "Helsang"}], "a")
	return row


func _selected(row) -> Array:
	return row.get_children().filter(func(b): return b.get_meta("selected", false)).map(func(b): return b.get_meta("tab"))


func test_exactly_one_is_selected() -> void:
	var row = _row()
	eq(_selected(row), ["a"], "the one given")
	ok(row.tab("a").get_theme_stylebox("normal").selected, "rimmed in brass")
	ok(not row.tab("b").get_theme_stylebox("normal").selected, "the others are not")
	row.free()


func test_choosing_moves_the_rim_and_says_so() -> void:
	var row = _row()
	var heard := []
	row.chosen.connect(func(id): heard.append(id))
	row.tab("c").pressed.emit()
	eq(_selected(row), ["c"], "the one chosen")
	eq(heard, ["c"], "and the choice is told")
	row.free()


func test_every_tab_is_a_tap_target() -> void:
	var row = _row()
	for b in row.get_children():
		ok(b.get_combined_minimum_size().y >= T.TAP_MIN and b.get_combined_minimum_size().x >= T.TAP_MIN, "%s is a tap target" % b.text)
	row.free()
