extends "res://tests/base.gd"
## The tokens follow the design system (specs/019): every colour is the one in its
## tokens.json, and every size is its phone points times 1.85, rounded (research R1, R2).

const T = preload("res://ui/theme/tokens.gd")

const SOURCE := "res://specs/019-unified-design-system/design-system/tokens.json"
## Phone points to design units (the 720-unit-tall layout), the system's own factor.
const PT := 1.85


func _tokens() -> Dictionary:
	var f := FileAccess.open(SOURCE, FileAccess.READ)
	ok(f != null, "the design system's tokens.json is readable")
	if f == null:
		return {}
	return JSON.parse_string(f.get_as_text())


func _constants() -> Dictionary:
	return (T as GDScript).get_script_constant_map()


static func _const_name(token: String) -> String:
	return token.to_upper().replace("-", "_")


static func _units(px: String) -> int:
	return roundi(px.trim_suffix("px").to_float() * PT)


func _colour(value: String) -> Color:
	if value.begins_with("rgba("):
		var parts := value.trim_prefix("rgba(").trim_suffix(")").split(",")
		return Color(parts[0].to_float() / 255.0, parts[1].to_float() / 255.0, parts[2].to_float() / 255.0, parts[3].to_float())
	return Color(value)


func test_every_colour_is_the_design_systems() -> void:
	var c := _constants()
	for tok in _tokens().color.tokens:
		var n: String = tok.name
		if n.begins_with("ether-"):
			# ether-lapis(-bright): the drop is Water, the bolt Lightning, the spark
			# Shadow, the flame Fire (specs/019 FR-011).
			var pigment := n.trim_prefix("ether-").trim_suffix("-bright")
			var element: String = {"lapis": "water", "ochre": "lightning", "amethyst": "shadow", "cinnabar": "fire"}[pigment]
			var role := "bright" if n.ends_with("-bright") else "base"
			eq(T.ETHER[element][role].to_html(false), _colour(tok.value).to_html(false), n)
		elif n.begins_with("region-"):
			var region: String = n.trim_prefix("region-")
			var got: Color = T.REGION_LAIR if region == "lair" else T.REGION[["jade", "marsh", "basin", "gath"].find(region) + 1]
			eq(got.to_html(false), _colour(tok.value).to_html(false), n)
		else:
			ok(c.has(_const_name(n)), "%s has a token" % n)
			if c.has(_const_name(n)):
				eq((c[_const_name(n)] as Color).to_html(), _colour(tok.value).to_html(), n)


func test_every_size_is_its_points_times_the_factor() -> void:
	var c := _constants()
	var j := _tokens()
	var names := {
		"space-1": "SPACE_1", "space-2": "SPACE_2", "space-3": "SPACE_3",
		"space-4": "SPACE_4", "space-5": "SPACE_5", "space-6": "SPACE_6",
		"chamfer-sm": "CHAMFER_SM", "chamfer-md": "CHAMFER_MD", "chamfer-lg": "CHAMFER_LG",
		"radius-plate": "RADIUS_PLATE",
		"border-etch": "BORDER_ETCH", "border-edge": "BORDER_EDGE", "border-select": "BORDER_SELECT",
		"topbar-height": "TOPBAR_H", "action-height": "ACTION_H",
	}
	for group in ["spacing", "chamfer", "radius", "borderWidth", "size"]:
		for tok in j[group].tokens:
			if not names.has(tok.name):
				continue
			eq(c[names[tok.name]], _units(tok.value), "%s (%s)" % [tok.name, tok.value])
	# The card radius is a share of the card: 8pt on the system's 100pt card.
	eq(T.CARD_RADIUS_SHARE, 0.08, "radius-card as a share of the card's width")
	eq(T.REGION_WASH, 0.22, "opacity-region-wash")
	eq(T.OUT_OF_PLAY, 0.45, "opacity-out-of-play")
	# The floors: caption is the smallest live text, card names may go to card-name;
	# the tap floor stays above touch-min (research R2).
	eq(T.TEXT_MIN, 22, "TEXT_MIN is caption")
	eq(T.CARD_NAME_MIN, 20, "CARD_NAME_MIN is card-name")
	ok(T.TAP_MIN >= _units("44px"), "TAP_MIN is at least touch-min")


func test_every_type_style_is_the_design_systems() -> void:
	var c := _constants()
	for group in _tokens().type.groups:
		for st in group.styles:
			var key := _const_name(st.name)
			ok(c.has(key), "%s has a type style" % st.name)
			if not c.has(key):
				continue
			var s: Dictionary = c[key]
			eq(s.family, group.family, "%s family" % st.name)
			eq(s.weight, int(st.fontWeight), "%s weight" % st.name)
			eq(s.size, _units(st.fontSize), "%s size" % st.name)
			if st.has("opticalSize"):
				eq(s.opsz, int(st.opticalSize), "%s optical size" % st.name)
			var spacing := 0.0
			if st.has("letterSpacing"):
				spacing = st.letterSpacing.trim_suffix("em").to_float()
			ok(is_equal_approx(s.spacing, spacing), "%s letter spacing %s" % [st.name, s.spacing])
			eq(s.upper, st.name in ["banner", "card-name", "label"], "%s case" % st.name)


func test_no_style_is_below_its_floor() -> void:
	var c := _constants()
	for key in T.STYLES:
		var s: Dictionary = c[key]
		var floor_size: int = T.CARD_NAME_MIN if key == "CARD_NAME" else T.TEXT_MIN
		ok(s.size >= floor_size, "%s is %d, at least %d" % [key, s.size, floor_size])


func test_no_colour_is_written_outside_the_tokens() -> void:
	# SC-001: every palette colour comes from tokens.gd; the interface writes no hex.
	var found := []
	_scan("res://ui", found)
	eq(found, [], "colour literals outside tokens.gd")


func _scan(dir: String, found: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		var path := dir + "/" + f
		if f.ends_with(".gd") and path != "res://ui/theme/tokens.gd":
			var text := FileAccess.get_file_as_string(path)
			var lines := text.split("\n")
			for i in lines.size():
				if lines[i].contains("Color(\"") and not lines[i].strip_edges().begins_with("#"):
					found.append("%s:%d" % [path, i + 1])
	for d in DirAccess.get_directories_at(dir):
		_scan(dir + "/" + d, found)


func test_the_old_palette_is_gone() -> void:
	# FR-001: the night-stone names were removed, not left beside the new ones.
	var c := _constants()
	for old in ["BG_BASE", "BG_SURFACE", "BG_RAISED", "BG_BAND", "LINE_SOFT", "INK", "INK_MUTED", "GOLD", "GOLD_FACE",
			"FOCUS", "ACCENT_MUTE", "GOOD", "CAUTION", "BAD", "HP", "BRONZE", "STONE_L_MIN", "STONE_L_MAX", "LABEL_CAPS",
			"SUBHEAD", "EYEBROW", "LABEL_BOLD", "H1", "NUMERAL_S", "NUMERAL_L", "XS", "S", "M", "L", "XL"]:
		ok(not c.has(old), "%s is gone" % old)
