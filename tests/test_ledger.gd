extends "res://tests/base.gd"
## The ledger (specs/019 contracts/components.md "Ledger"): muted heads, the best row
## alone in bright brass, scores in the numeral style, rows a tap target when pressed.

const T = preload("res://ui/theme/tokens.gd")
const Ledger = preload("res://ui/widgets/ledger.gd")

const COLUMNS := [{"head": "Place", "width": 80}, {"head": "Score", "width": 90, "numeral": true, "align": "right"},
	{"head": "Dragon", "width": 0}]


func _labels(n: Node) -> Array:
	return n.find_children("*", "Label", true, false)


func test_heads_are_muted_labels() -> void:
	var l = Ledger.new()
	l.setup(COLUMNS, [])
	for lab in _labels(l):
		eq(lab.get_theme_color("font_color"), T.PARCHMENT_MUTED, "%s is muted" % lab.text)
		ok(lab.uppercase, "%s is in capitals" % lab.text)
	l.free()


func test_only_the_best_row_is_bright_brass() -> void:
	var l = Ledger.new()
	l.setup(COLUMNS, [{"cells": ["1st", "35", "Rodving"], "best": true}, {"cells": ["2nd", "20", "Helsang"]}, {"cells": ["3rd", "—", "Vuurhast"]}])
	var bright := _labels(l).filter(func(x): return x.get_theme_color("font_color") == T.BRASS_BRIGHT).map(func(x): return x.text)
	eq(bright, ["1st", "35", "Rodving"], "the best row, and only it")
	var dash: Label = _labels(l).filter(func(x): return x.text == "—")[0]
	eq(dash.get_theme_color("font_color"), T.PARCHMENT_MUTED, "an absent value is muted")
	var score: Label = _labels(l).filter(func(x): return x.text == "20")[0]
	eq(score.get_theme_font_size("font_size"), T.NUMERAL_SM.size, "scores in the numeral style")
	l.free()


func test_a_pressed_row_is_a_tap_target() -> void:
	var l = Ledger.new()
	l.setup(COLUMNS, [{"cells": ["1st", "35", "Rodving"], "press": true}])
	var b: Button = l.find_children("*", "Button", true, false)[0]
	ok(b.custom_minimum_size.y >= T.TAP_MIN, "the row is a tap target")
	var heard := []
	l.pressed.connect(func(i): heard.append(i))
	b.pressed.emit()
	eq(heard, [0], "and says which row")
	l.free()
