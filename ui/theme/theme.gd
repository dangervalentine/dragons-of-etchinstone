extends RefCounted
## Builds fonts, styles and small common controls from the tokens.

const T = preload("res://ui/theme/tokens.gd")

## Set from the settings; travel and shake are replaced by fades when true.
static var reduced_motion := false

static var _fonts := {}
static var _icons := {}


static func font(name: String) -> Font:
	if _fonts.is_empty():
		var ts := TextServerManager.get_primary_interface()
		var cinzel: Font = load("res://art/fonts/Cinzel.ttf")
		for entry in [["display", 600], ["display_bold", 800]]:
			var v := FontVariation.new()
			v.base_font = cinzel
			v.variation_opentype = {ts.name_to_tag("wght"): entry[1]}
			_fonts[entry[0]] = v
		for entry in [["body", "Regular"], ["body_medium", "Medium"], ["body_bold", "Bold"]]:
			var v := FontVariation.new()
			v.base_font = load("res://art/fonts/AlegreyaSans-%s.ttf" % entry[1])
			# Lining, tabular figures: numbers sit on the baseline and line up.
			v.opentype_features = {ts.name_to_tag("lnum"): 1, ts.name_to_tag("tnum"): 1}
			_fonts[entry[0]] = v
	return _fonts[name]


## A creature or landscape silhouette from art/creatures/.
static func art(name: String) -> Texture2D:
	return icon("../creatures/" + name)


static func art_rect(name: String, side: float, color: Color = T.INK) -> TextureRect:
	var t := icon_rect("../creatures/" + name, side, color)
	return t


static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		_icons[name] = load("res://art/icons/%s.svg" % name)
	return _icons[name]


## The project-wide Theme: default font and the looks of plain controls.
static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = font("body")
	theme.default_font_size = T.BODY[1]
	theme.set_color("font_color", "Label", T.INK)
	return theme


static func label(text: String, type: Array = T.BODY, color: Color = T.INK, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	style_label(l, type, color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func style_label(l: Label, type: Array, color: Color) -> void:
	l.add_theme_font_override("font", font(type[0]))
	l.add_theme_font_size_override("font_size", type[1])
	l.add_theme_color_override("font_color", color)


static func icon_rect(name: String, side: float, color: Color = T.INK) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(side, side)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	t.modulate = color
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func box(bg: Color, border: Color = Color.TRANSPARENT, width := 0, radius: int = T.RADIUS_M, margin: int = T.S) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.anti_aliasing_size = 0.6
	return s


static func panel(bg: Color = T.BG_SURFACE, border: Color = T.LINE_SOFT, width := 1, radius: int = T.RADIUS_M, margin: int = T.S) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, width, radius, margin))
	return p


## kind: "normal", "primary" (the one gold action), "warning", "active" or "quiet".
static func button(text: String, kind := "normal", icon_name := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_override("font", font(T.BUTTON[0]))
	b.add_theme_font_size_override("font_size", T.BUTTON[1])
	b.focus_mode = Control.FOCUS_ALL
	if icon_name != "":
		b.icon = icon(icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 34)
	style_button(b, kind)
	press_feedback(b)
	return b


static func style_button(b: Button, kind: String) -> void:
	var bg := T.BG_RAISED
	var border := T.LINE_SOFT
	var ink := T.INK
	var width := 2
	match kind:
		"primary":
			bg = T.GOLD
			border = T.GOLD.lightened(0.3)
			ink = T.BG_BASE
		"warning":
			bg = T.BAD
			border = T.BAD.lightened(0.3)
			ink = T.BG_BASE
		"active":
			bg = T.BG_RAISED.lightened(0.08)
			border = T.GOLD
			width = 3
		"quiet":
			bg = T.BG_SURFACE
	b.add_theme_stylebox_override("normal", box(bg, border, width))
	b.add_theme_stylebox_override("hover", box(bg.lightened(0.08), border.lightened(0.25), width))
	b.add_theme_stylebox_override("pressed", box(bg.darkened(0.15), border, width))
	b.add_theme_stylebox_override("disabled", box(Color(T.BG_SURFACE, 0.6), Color(T.LINE_SOFT, 0.5), 1))
	var focus := box(Color.TRANSPARENT, T.GOLD, 3)
	focus.set_expand_margin_all(4)
	b.add_theme_stylebox_override("focus", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("font_disabled_color", Color(T.INK_MUTED, 0.6))
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("icon_disabled_color", Color(T.INK_MUTED, 0.6))


## Scale a control down a touch while it is held, so every press is felt at once.
static func press_feedback(c: Control) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size / 2.0)
	if c is BaseButton:
		c.button_down.connect(func(): pulse_scale(c, 0.96))
		c.button_up.connect(func(): pulse_scale(c, 1.0))


static func pulse_scale(c: Control, to: float) -> void:
	c.pivot_offset = c.size / 2.0
	if not c.is_inside_tree():
		c.scale = Vector2(to, to)
		return
	c.create_tween().tween_property(c, "scale", Vector2(to, to), T.INSTANT)


## A short sideways shake, for refused actions and hits. Does nothing in reduced motion.
static func shake(c: Control, strength := 8.0) -> void:
	if reduced_motion or not c.is_inside_tree():
		return
	var home := c.position
	var tw := c.create_tween()
	for dx in [strength, -strength, strength * 0.5, -strength * 0.5, 0.0]:
		tw.tween_property(c, "position:x", home.x + dx, 0.04)


## A brief brightening, used when a figure changes.
static func flash(c: CanvasItem, color: Color = T.GOLD) -> void:
	if not c.is_inside_tree():
		return
	if not c.has_meta("flash_base"):
		c.set_meta("flash_base", c.modulate)
	c.modulate = color.lightened(0.4)
	c.create_tween().tween_property(c, "modulate", c.get_meta("flash_base"), T.REVEAL)


static func ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			ignore_mouse(child)


static func hbox(separation: int = T.S) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	return row


static func vbox(separation: int = T.S) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", separation)
	return col


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
