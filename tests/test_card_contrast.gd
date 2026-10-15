extends "res://tests/base.gd"
## Every figure on a Mage Card stays readable in every Ether and every treatment:
## 4.5:1 for text, 3:1 for the large numerals.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

## How far a quietened plate's fill moves toward the band colour (card_face.gd).
const QUIET := 0.75


func _plates() -> Dictionary:
	var out := {"black": T.BG_BAND}
	for e in T.ETHER:
		out[e] = T.ether_shade(e, "plate")
	return out


func test_enhanced_plate_ink_reads_on_every_ether() -> void:
	for e in T.ETHER:
		var r := UI.contrast(T.ether_shade(e, "plate_ink"), T.ether_shade(e, "plate"))
		ok(r >= 3.0, "%s plate numerals %.2f:1" % [e, r])


func test_bands_read() -> void:
	ok(UI.contrast(T.INK, T.CARD_FRAME) >= 4.5, "name on the frame")
	ok(UI.contrast(T.INK, T.BRONZE) >= 4.5, "Key Card strip text, %.2f:1" % UI.contrast(T.INK, T.BRONZE))
	ok(UI.contrast(T.GOLD, T.BRONZE) >= 3.0, "affordable cost, %.2f:1" % UI.contrast(T.GOLD, T.BRONZE))
	ok(UI.contrast(T.BAD, T.BRONZE) >= 3.0, "unaffordable cost, %.2f:1" % UI.contrast(T.BAD, T.BRONZE))
	ok(UI.contrast(T.INK_MUTED, T.BRONZE) >= 3.0, "quietened strip, %.2f:1" % UI.contrast(T.INK_MUTED, T.BRONZE))


func test_quietened_plates_stay_readable() -> void:
	var plates := _plates()
	for name in plates:
		var quiet: Color = plates[name].lerp(T.BG_BAND, QUIET)
		var r := UI.contrast(T.INK_MUTED, quiet)
		ok(r >= 4.5, "quietened %s plate %.2f:1" % [name, r])


func test_full_plates_read() -> void:
	ok(UI.contrast(T.INK, T.BG_BAND) >= 4.5, "black plate")
	for e in T.ETHER:
		var plate := T.ether_shade(e, "plate")
		ok(UI.contrast(UI.best_ink(plate), plate) >= 3.0, "%s armor crest" % e)
