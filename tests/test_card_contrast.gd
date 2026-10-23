extends "res://tests/base.gd"
## Every figure on a Mage Card stays readable in every Ether and every treatment
## (specs/019 contracts/checks.md): 4.5:1 for text, 3:1 for the large numerals,
## which WCAG counts as large text.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

## How far a quietened plate's fill moves toward the plate colour (card_face.gd).
const QUIET := 0.75


func _plates() -> Dictionary:
	var out := {"black": T.STAT_PLATE}
	for e in T.ETHER:
		out[e] = T.ether_shade(e, "plate")
	return out


func test_enhanced_plate_ink_reads_on_every_ether() -> void:
	for e in T.ETHER:
		var r := UI.contrast(T.ether_shade(e, "plate_ink"), T.ether_shade(e, "plate"))
		ok(r >= 3.0, "%s plate numerals %.2f:1" % [e, r])


func test_highlighted_pills_read_on_every_ether() -> void:
	for e in T.ETHER:
		var r := UI.contrast(T.ether_shade(e, "pill_ink"), T.ether_shade(e, "pill"))
		ok(r >= 4.5, "%s highlighted figure %.2f:1" % [e, r])


func test_bands_read() -> void:
	ok(UI.contrast(T.PARCHMENT, T.CARD_FRAME) >= 4.5, "name on the frame")
	ok(UI.contrast(T.PARCHMENT, T.CARD_RIBBON) >= 4.5, "the ribbon's cost, %.2f:1" % UI.contrast(T.PARCHMENT, T.CARD_RIBBON))
	ok(UI.contrast(T.BRASS_BRIGHT, T.CARD_RIBBON) >= 4.5, "the ribbon's XP, %.2f:1" % UI.contrast(T.BRASS_BRIGHT, T.CARD_RIBBON))
	# Harm does not read on the leather (2.5:1), so an unaffordable cost sits on its
	# own dark plate in the ribbon (specs/019 research R4).
	ok(UI.contrast(T.DANGER, T.STAT_PLATE) >= 4.5, "an unaffordable cost on its plate, %.2f:1" % UI.contrast(T.DANGER, T.STAT_PLATE))


func test_quietened_plates_stay_readable() -> void:
	var plates := _plates()
	for name in plates:
		var quiet: Color = plates[name].lerp(T.STAT_PLATE, QUIET)
		var r := UI.contrast(T.PARCHMENT_MUTED, quiet)
		ok(r >= 4.5, "quietened %s plate %.2f:1" % [name, r])


func test_full_plates_read() -> void:
	ok(UI.contrast(T.PARCHMENT, T.STAT_PLATE) >= 4.5, "black plate")
	ok(UI.contrast(T.BRASS, T.STAT_PLATE) >= 4.5, "brass on a plate")
	for e in T.ETHER:
		var plate := T.ether_shade(e, "plate")
		ok(UI.contrast(UI.best_ink(plate), plate) >= 3.0, "%s armor crest" % e)
