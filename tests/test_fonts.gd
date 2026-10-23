extends "res://tests/base.gd"
## The faces of the design system (specs/019 research R3): every sign the game's text
## uses has a glyph in the face it is set in (Fraunces falling back to Alegreya Sans
## for the few it lacks), and every numeral style's figures are tabular.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")


## Every character above ASCII in the card data and the interface's scripts.
func _signs() -> Dictionary:
	var out := {}
	var files := []
	for f in DirAccess.get_files_at("res://data"):
		if f.ends_with(".json"):
			files.append("res://data/" + f)
	_scripts("res://ui", files)
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for i in text.length():
			if text.unicode_at(i) > 0x7e:
				out[text[i]] = path
	return out


func _scripts(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir + "/" + d, out)


static func _has(font: Font, c: String) -> bool:
	if font.has_char(c.unicode_at(0)):
		return true
	for f in font.fallbacks:
		if _has(f, c):
			return true
	if font is FontVariation and font.base_font != null:
		return font.base_font.has_char(c.unicode_at(0))
	return false


func test_every_sign_has_a_glyph_in_every_style() -> void:
	var signs := _signs()
	ok(signs.size() > 0, "the text has signs beyond ASCII")
	for key in T.STYLES:
		var font := UI.font((T as GDScript).get_script_constant_map()[key])
		for c in signs:
			ok(_has(font, c), "%s has '%s' (U+%04X, from %s)" % [key, c, c.unicode_at(0), signs[c]])


func test_numeral_figures_are_tabular() -> void:
	for key in ["NUMERAL_XL", "NUMERAL", "NUMERAL_SM"]:
		var st: Dictionary = (T as GDScript).get_script_constant_map()[key]
		var font := UI.font(st)
		var widths := {}
		for d in "0123456789":
			widths[font.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, st.size).x] = true
		eq(widths.size(), 1, "%s: every digit one width, got %s" % [key, str(widths.keys())])


func test_cinzel_is_gone() -> void:
	# Fraunces replaced it (specs/019 FR-012); nothing ships or loads it.
	ok(not FileAccess.file_exists("res://art/fonts/Cinzel.ttf"), "Cinzel.ttf is not shipped")
	for path in ["res://ui/theme/theme.gd", "res://ui/widgets/card_face.gd", "res://ui/theme/numerals.gd"]:
		ok(not FileAccess.get_file_as_string(path).contains("Cinzel"), "%s does not load Cinzel" % path)
