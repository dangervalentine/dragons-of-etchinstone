extends RefCounted
## Builds fonts, styles and small common controls from the tokens.

const T = preload("res://ui/theme/tokens.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const Haptics = preload("res://ui/fx/haptics.gd")
const Art = preload("res://ui/model/art.gd")

## Set from the settings; travel and shake are replaced by fades when true.
static var reduced_motion := false
## Off, every creature shows its silhouette even where it has a painted picture (the
## tests of the rigged silhouettes turn it off).
static var painted_art := true

static var _fonts := {}
static var _icons := {}


static func font(name: String) -> Font:
	if _fonts.is_empty():
		var ts := TextServerManager.get_primary_interface()
		var cinzel: Font = load("res://art/fonts/Cinzel.ttf")
		for entry in [["display", 600], ["display_bold", 800], ["numeral", 900]]:
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


## A creature or landscape silhouette from art/creatures/, or its painted picture
## from art/painted/ when there is one (a preview of the feature 008 art).
static func art(name: String) -> Texture2D:
	if is_painted(name):
		return painted(name)
	return icon("../creatures/" + name)


## Whether the art has a painted picture in art/painted/, drawn in its own colours.
static func is_painted(name: String) -> bool:
	return painted_art and painted(name) != null


## The picture art/painted/<name>.png, or null when there is none or it cannot be
## loaded (not yet imported, say), so the art falls back to its silhouette.
static func painted(name: String) -> Texture2D:
	var key := "painted/" + name
	if not _icons.has(key):
		var path := "res://art/painted/%s.png" % name
		_icons[key] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _icons[key]


static func art_rect(name: String, side: float, color: Color = T.INK) -> TextureRect:
	var t := icon_rect("../creatures/" + name, side, color)
	return t


## Part of a creature's art, `region` in its 512 units, as a texture of its own.
static func art_crop(name: String, region: Rect2) -> Texture2D:
	var tex := art(name)
	if tex == null:
		return null
	var k := tex.get_width() / 512.0
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(region.position * k, region.size * k)
	return a


## A creature's head, as the places that face it show it: its painted head picture
## (art/painted/<name>-head.png) whole where there is one, or the head cut from its
## painted picture, or from its silhouette.
static func head(name: String) -> Texture2D:
	if is_painted(name + "-head"):
		return art(name + "-head")
	if is_painted(name):
		return art_crop(name, Art.head(name, true))
	return art_crop(Art.head_art(name), Art.head(name))


## The colour head() is drawn in: a silhouette tinted `colour`, a painted head in its own.
static func head_tint(name: String, colour: Color) -> Color:
	return Color.WHITE if is_painted(name + "-head") or is_painted(name) else colour


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
	# Tooltips: an opaque raised panel, so the text never mixes with what is beneath.
	theme.set_stylebox("panel", "TooltipPanel", tooltip_box())
	theme.set_color("font_color", "TooltipLabel", T.INK)
	theme.set_font_size("font_size", "TooltipLabel", T.LABEL[1])
	return theme


static func tooltip_box() -> StyleBoxFlat:
	var s := box(Color(T.BG_BASE, 0.97), Color(T.GOLD, 0.6), 1, T.RADIUS_S, T.S + 2)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 8
	return s


## A tooltip in the one explanation look. Text written "Name: what it means" gets
## the name as a heading, with `icon_name` beside it. Godot sets it in the themed
## tooltip panel, so this is just the content.
static func wrapped_tooltip(text: String, width := 340.0, icon_name := "") -> Control:
	var cut := text.find(": ")
	if cut > 0 and cut < 32:
		return entry_content(text.left(cut), text.substr(cut + 2), icon_name, width)
	var l := label(text, T.LABEL, T.INK, true)
	l.custom_minimum_size.x = minf(width, font(T.LABEL[0]).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, T.LABEL[1]).x + 2)
	return l


## An explanation: the term's icon and name over what it means. Shared by every
## tooltip and the help that opens on a tap, so they always look alike.
static func entry_content(title: String, body: String, icon_name := "", width := 340.0) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", T.S)
	if icon_name != "":
		head.add_child(icon_rect(icon_name, 26, icon_ink(icon_name)))
	var t := label(title.to_upper(), T.SUBHEAD, T.INK)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(t)
	col.add_child(head)
	var l := label(body, T.LABEL, T.INK, true)
	l.custom_minimum_size.x = width
	col.add_child(l)
	return col


## The colour an explanation's icon is drawn in: an Ether in its own ink, any other
## term in gold.
static func icon_ink(id: String) -> Color:
	return T.ether_ink(id) if T.ETHER.has(id) else T.GOLD


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
	return texture_rect(icon(name), side, color)


static func texture_rect(texture: Texture2D, side: float, color: Color = T.INK) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(side, side)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	t.modulate = color
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## The corner radius of a card `width` wide, as a Mage Card draws its own
## (card_face.gd): the Region and Dragon Cards and the Deck's edges match it
## (specs/014 FR-016).
static func card_radius(width: float) -> int:
	return roundi(width * 0.075)


## A title band's foot torn as a Mage Card's is (card_face.gd _draw_tears): from
## `x0` to `x1` along `y`, `colour` torn down by up to `depth`, the same way every
## time for the same `seed`, its steps a share of the width so it tears alike at
## any size. With an `edge` colour, that shows `edge_w` deep under the tear.
static func draw_torn_edge(canvas: CanvasItem, x0: float, x1: float, y: float, depth: float, seed: int,
		colour: Color, edge := Color.TRANSPARENT, edge_w := 0.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var step := maxf(3.0, (x1 - x0) * 0.022)
	var pts := PackedVector2Array([Vector2(x0, y - 1)])
	var x := x0
	while x < x1:
		pts.append(Vector2(x, y + rng.randf_range(0.0, depth)))
		x += step * rng.randf_range(0.6, 1.4)
	pts.append(Vector2(x1, y + rng.randf_range(0.0, depth)))
	pts.append(Vector2(x1, y - 1))
	if edge.a > 0.0 and edge_w > 0.0:
		var under := PackedVector2Array()
		for p in pts:
			under.append(p + Vector2(0, edge_w))
		canvas.draw_colored_polygon(under, edge)
	canvas.draw_colored_polygon(pts, colour)


static func box(bg: Color, border: Color = Color.TRANSPARENT, width := 0, radius: int = T.RADIUS_M, margin: int = T.S) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	s.anti_aliasing_size = 0.6
	return s


## WCAG contrast ratio between two colours, from 1 to 21.
static func contrast(a: Color, b: Color) -> float:
	return T.ratio(a, b)


## The ink, light or dark, that reads best on a background.
static func best_ink(bg: Color) -> Color:
	return T.INK if contrast(T.INK, bg) >= contrast(T.BG_BASE, bg) else T.BG_BASE


## A play-screen panel lifted off the backdrop by its shadow. "active" is the one
## waiting on the player: lighter, with a focus rim. "rest" steps back. `border`
## keeps a panel's own meaningful edge colour (such as the damage on the Soak meter).
static func raised_panel_box(kind: String, border := Color(0, 0, 0, 0), margin: int = T.S) -> StyleBoxFlat:
	var active := kind == "active"
	var s := box(T.BG_RAISED if active else T.BG_SURFACE,
		border if border.a > 0.0 else (Color(T.FOCUS, 0.6) if active else Color(T.LINE_SOFT, 0.5)),
		2 if active or border.a > 0.0 else 1, T.RADIUS_M, margin)
	s.shadow_color = Color(0, 0, 0, 0.4 if active else 0.3)
	s.shadow_size = 12 if active else 6
	s.shadow_offset = Vector2(0, 4 if active else 2)
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
	# Feature 006: every button is a plinth of stone.
	style_stone_button(b, kind)
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
	var normal := box(bg, border, width)
	normal.shadow_color = Color(0, 0, 0, 0.3)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0, 2)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = bg.lightened(0.08)
	hover.border_color = border.lightened(0.25)
	b.add_theme_stylebox_override("hover", hover)
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


## A place cut into or standing out of the carved stone (feature 006): "well" for
## a zone, "inset" for a chip, "plinth" for a button, "slab" for an overlay, "lintel"
## for a band across the screen.
static func stone_box(kind: String, depth := 0.5) -> StyleBox:
	return StoneStyle.new(kind, depth)


## A zone well on the play screen, edged in a colour that means something (damage
## owed, XP, a fatal choice), or plain stone when `edge_colour` is clear.
static func stone_zone(edge_colour := Color(0, 0, 0, 0), margin := 12, edge_width := 2.0) -> StyleBox:
	var s := StoneStyle.new("well", 0.6)
	s.edge = edge_colour
	s.edge_width = edge_width
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_content_margin(side, margin)
	return s


## A raised slab of stone for a popup, edged in `edge_colour`.
static func stone_slab(edge_colour := T.GOLD, margin := 14) -> StyleBox:
	var s := StoneStyle.new("slab", 0.3)
	s.edge = edge_colour
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_content_margin(side, margin)
	return s


## A PanelContainer drawn as a raised slab (menus, dialogs, the rulebook): the frame
## every overlay shares from feature 006 on.
static func slab(edge_colour := T.GOLD, margin := 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stone_slab(edge_colour, margin))
	return p


static func stone_panel(kind: String, depth := 0.5) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stone_box(kind, depth))
	return p


## A button carved as a plinth of stone. kind as for style_button: the "primary"
## plinth is gold-leafed, a "warning" one is red, and "active" is lit at the rim.
static func style_stone_button(b: Button, kind := "normal") -> void:
	var ink := T.INK
	var leaf := Color(0, 0, 0, 0)
	match kind:
		"primary":
			leaf = T.GOLD_FACE
			ink = T.BG_BASE
		"warning":
			leaf = T.BAD.lerp(T.BG_RAISED, 0.2)
			ink = T.BG_BASE
	var normal := StoneStyle.new("plinth", 0.3 if kind == "quiet" else 0.5)
	normal.face = leaf
	if kind == "active":
		normal.glow = 1.0
		normal.glow_colour = T.GOLD
	b.add_theme_stylebox_override("normal", normal)
	var hover := StoneStyle.new("plinth", 0.2)
	hover.face = leaf.lightened(0.1) if leaf.a > 0.0 else Color(1, 1, 1, 0.04)
	hover.glow = normal.glow
	hover.glow_colour = normal.glow_colour
	b.add_theme_stylebox_override("hover", hover)
	var down := StoneStyle.new("plinth", 0.7)
	down.pressed = true
	down.face = leaf.darkened(0.15) if leaf.a > 0.0 else Color(0, 0, 0, 0)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	var off := StoneStyle.new("plinth", 0.3)
	off.face = Color(T.BG_BASE, 0.45)
	b.add_theme_stylebox_override("disabled", off)
	var focus := box(Color.TRANSPARENT, T.muted(T.GOLD), 3)
	focus.set_expand_margin_all(4)
	b.add_theme_stylebox_override("focus", focus)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("font_disabled_color", Color(T.INK_MUTED, 0.6))
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("icon_disabled_color", Color(T.INK_MUTED, 0.6))


## A display heading cut into the stone: a dark edge above the letters and a light
## one below, so they read as incised.
static func carved_label(text: String, type: Array = T.HEADING, color: Color = T.INK) -> Label:
	var l := label(text, type, color)
	l.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.10))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("outline_size", 2)
	return l


## Scale a control down a touch while it is held, and tick the phone on the press,
## so every press is felt at once.
static func press_feedback(c: Control) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size / 2.0)
	if c is BaseButton:
		c.button_down.connect(func(): pulse_scale(c, 0.96))
		c.button_up.connect(func(): pulse_scale(c, 1.0))
		c.pressed.connect(Haptics.tap)


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


## The height a VBoxContainer's children need when it is `width` wide, worked out
## from the fonts for wrapped labels (whose own minimum lags a frame behind).
static func stack_height(box: VBoxContainer, width: float) -> float:
	var h := 0.0
	var n := 0
	for c in box.get_children():
		if not c is Control or not c.visible or c.is_queued_for_deletion():
			continue
		n += 1
		if c is Label and c.autowrap_mode != TextServer.AUTOWRAP_OFF:
			var font: Font = c.get_theme_font("font")
			var fs: int = c.get_theme_font_size("font_size")
			h += font.get_multiline_string_size(c.text, HORIZONTAL_ALIGNMENT_LEFT, width, fs).y
		elif c is FlowContainer:
			h += _flow_height(c, width)
		else:
			h += c.get_combined_minimum_size().y
	return h + maxi(0, n - 1) * box.get_theme_constant("separation")


static func _flow_height(flow: FlowContainer, width: float) -> float:
	var x := 0.0
	var row_h := 0.0
	var total := 0.0
	var hs: int = flow.get_theme_constant("h_separation")
	var vs: int = flow.get_theme_constant("v_separation")
	for c in flow.get_children():
		if not c is Control or not c.visible:
			continue
		var m: Vector2 = c.get_combined_minimum_size()
		if x > 0.0 and x + m.x > width:
			total += row_h + vs
			x = 0.0
			row_h = 0.0
		x += m.x + hs
		row_h = maxf(row_h, m.y)
	return total + row_h


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
