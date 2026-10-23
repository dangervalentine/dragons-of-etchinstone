extends RefCounted
## Builds fonts, styles and small common controls from the tokens.

const T = preload("res://ui/theme/tokens.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const Haptics = preload("res://ui/fx/haptics.gd")
const Art = preload("res://ui/model/art.gd")

## Set from the settings; travel and shake are replaced by fades when true.
static var reduced_motion := false

static var _fonts := {}
static var _icons := {}

## Alegreya Sans by weight (specs/019 research R3).
const SANS := {500: "Medium", 700: "Bold", 800: "ExtraBold"}
## The font for a type style (tokens.gd), one cached variation per face: Fraunces at
## the style's weight and optical size, softened (SOFT 50) and never wonky (WONK 0), or
## Alegreya Sans at its weight with lining, tabular figures. Fraunces falls back to
## Alegreya for the few signs it lacks (→). Letter spacing is set for `size` (the
## style's own when -1).
static func font(st: Dictionary, size := -1) -> Font:
	var px: int = size if size > 0 else st.get("size", 0)
	var key := "%s/%d/%d/%d" % [st.family, st.weight, st.get("opsz", 0), roundi(st.spacing * px)]
	if not _fonts.has(key):
		_fonts[key] = _face(st, roundi(st.spacing * px))
	return _fonts[key]


static func _face(st: Dictionary, spacing: int) -> Font:
	var ts := TextServerManager.get_primary_interface()
	var v := FontVariation.new()
	var figures := "res://art/fonts/FrauncesFigures-%d-%d.ttf" % [st.weight, st.get("opsz", 0)]
	if st.family == "display" and ResourceLoader.exists(figures):
		# A numeral style: its static cut with tabular digits (tools/make_figures.py),
		# since Fraunces has none, so sums and tables line up (FR-014).
		v.base_font = load(figures)
	elif st.family == "display":
		v.base_font = load("res://art/fonts/Fraunces.ttf")
		v.variation_opentype = {ts.name_to_tag("wght"): st.weight, ts.name_to_tag("opsz"): st.opsz,
			ts.name_to_tag("SOFT"): 50, ts.name_to_tag("WONK"): 0}
	if st.family == "display":
		v.fallbacks = [_face({"family": "sans", "weight": SANS.keys().reduce(
			func(a, w): return w if absi(w - st.weight) < absi(a - st.weight) else a), "spacing": 0.0}, 0)]
	else:
		v.base_font = load("res://art/fonts/AlegreyaSans-%s.ttf" % SANS[st.weight])
		# Lining, tabular figures: numbers sit on the baseline and line up.
		v.opentype_features = {ts.name_to_tag("lnum"): 1, ts.name_to_tag("tnum"): 1}
	v.spacing_glyph = spacing
	return v


## A type style at another size (a fitted name, a figure sized to its box).
static func restyle(style: Dictionary, size: int) -> Dictionary:
	var out := style.duplicate()
	out.size = size
	return out


## A creature's painted picture from art/painted/, or, for art with none (the Final
## Journey's road), its silhouette from art/creatures/.
static func art(name: String) -> Texture2D:
	if is_painted(name):
		return painted(name)
	return icon("../creatures/" + name)


## Whether the art has a painted picture in art/painted/, drawn in its own colours.
static func is_painted(name: String) -> bool:
	return painted(name) != null


## The picture art/painted/<name>.png, or null when there is none or it cannot be
## loaded (not yet imported, say).
static func painted(name: String) -> Texture2D:
	var key := "painted/" + name
	if not _icons.has(key):
		var path := "res://art/painted/%s.png" % name
		_icons[key] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _icons[key]


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


## A dragon's head, as the places that face it show it, in its own colours: its head
## picture (art/painted/<name>-head.png) whole where there is one, or the head cut
## from its picture.
static func head(name: String) -> Texture2D:
	if is_painted(name + "-head"):
		return art(name + "-head")
	return art_crop(name, Art.head(name))


static func icon(name: String) -> Texture2D:
	if not _icons.has(name):
		_icons[name] = load("res://art/icons/%s.svg" % name)
	return _icons[name]


## The project-wide Theme: default font and the looks of plain controls.
static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = font(T.BODY)
	theme.default_font_size = T.BODY.size
	theme.set_color("font_color", "Label", T.PARCHMENT)
	# Tooltips are a raised stone sheet, so the text never mixes with what is beneath.
	theme.set_stylebox("panel", "TooltipPanel", tooltip_box())
	theme.set_color("font_color", "TooltipLabel", T.PARCHMENT)
	theme.set_font_size("font_size", "TooltipLabel", T.BODY_SM.size)
	return theme


## Paper (specs/019 contracts/materials-and-ground.md): coach tips and the unspent
## XP question; the glossary and the rulebook moved to stone (owner, 2026-10-23). A dim, warm
## sheet with a darker paper edge, rounded as paper is, lifted off the table by the
## card shadow. Text on it is PAPER_INK, PAPER_MUTED for the secondary.
static func paper_box(margin: int = T.SPACE_3) -> StyleBoxFlat:
	var s := box(T.PAPER, T.PAPER.darkened(0.15), T.BORDER_ETCH, T.RADIUS_PLATE, margin)
	s.shadow_color = T.SHADOW_CARD.colour
	s.shadow_size = int(T.SHADOW_CARD.blur / 2.0)
	s.shadow_offset = Vector2(0, T.SHADOW_CARD.drop)
	return s


## Every tooltip and the help a tap opens: a raised stone sheet with the etched rim,
## lifted off the table by the card shadow, its text parchment (owner, 2026-10-23:
## no paper behind the glossary).
static func tooltip_box() -> StyleBoxFlat:
	var s := box(T.STONE_RAISED, T.EDGE, T.BORDER_ETCH, T.RADIUS_PLATE, T.SPACE_2)
	s.shadow_color = T.SHADOW_CARD.colour
	s.shadow_size = int(T.SHADOW_CARD.blur / 2.0)
	s.shadow_offset = Vector2(0, T.SHADOW_CARD.drop)
	return s


## Notes the size of text a widget drew by hand at `site`, with the least it may be,
## so the UI check holds drawn text to the floors as it does labels (specs/019
## FR-015). Each site keeps its latest size.
static func drew_text(owner: Object, site: String, fs: int, least: int = T.TEXT_MIN) -> void:
	var drawn: Dictionary = owner.get_meta("drawn_text", {})
	drawn[site] = [fs, least]
	owner.set_meta("drawn_text", drawn)


## A tooltip in the one explanation look. Text written "Name: what it means" gets
## the name as a heading, with `icon_name` beside it. Godot sets it in the themed
## tooltip panel, so this is just the content.
static func wrapped_tooltip(text: String, width := 340.0, icon_name := "") -> Control:
	var cut := text.find(": ")
	if cut > 0 and cut < 32:
		return entry_content(text.left(cut), text.substr(cut + 2), icon_name, width)
	var l := label(text, T.BODY_SM, T.PARCHMENT, true)
	l.custom_minimum_size.x = minf(width, font(T.BODY_SM).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, T.BODY_SM.size).x + 2)
	return l


## An explanation: the term's icon and name over what it means. Shared by every
## tooltip and the help that opens on a tap, so they always look alike.
static func entry_content(title: String, body: String, icon_name := "", width := 340.0) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", T.SPACE_2)
	if icon_name != "":
		head.add_child(icon_rect(icon_name, 26, icon_ink(icon_name)))
	var t := label(title, T.HEADING, T.PARCHMENT)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(t)
	col.add_child(head)
	var l := label(body, T.BODY_SM, T.PARCHMENT, true)
	l.custom_minimum_size.x = width
	col.add_child(l)
	return col


## The colour an icon is printed in on paper: an Ether in its deep pigment, any other
## sign in the paper's ink.
static func paper_ink(id: String) -> Color:
	return T.ether_shade(id, "paper") if T.ETHER.has(id) else T.PAPER_INK


## The colour an explanation's icon is drawn in: an Ether in its own ink, any other
## term in the text's (brass is for what you can do next, specs/019 research R6).
static func icon_ink(id: String) -> Color:
	return T.ether_ink(id) if T.ETHER.has(id) else T.PARCHMENT


static func label(text: String, type: Dictionary = T.BODY, color: Color = T.PARCHMENT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	style_label(l, type, color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Sets a label in a type style: its face, its size, its colour, and capitals when
## the style is set in them (banner, card name, label).
static func style_label(l: Label, type: Dictionary, color: Color) -> void:
	l.add_theme_font_override("font", font(type))
	l.add_theme_font_size_override("font_size", type.size)
	l.uppercase = type.get("upper", false)
	l.add_theme_color_override("font_color", color)


static func icon_rect(name: String, side: float, color: Color = T.PARCHMENT) -> TextureRect:
	return texture_rect(icon(name), side, color)


static func texture_rect(texture: Texture2D, side: float, color: Color = T.PARCHMENT) -> TextureRect:
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


## The corner radius of a card `width` wide: every card, of any kind and size, is cut
## alike (specs/014 FR-016; the share is the design system's, specs/019).
static func card_radius(width: float) -> int:
	return roundi(width * T.CARD_RADIUS_SHARE)


## A card's shadow on `canvas` under `rect` (specs/019 "Depth"): a hard drop onto the
## table and a soft shade, the larger lift while it is held, dragged or inspected.
static func draw_card_shadow(canvas: CanvasItem, rect: Rect2, radius: int, lifted := false) -> void:
	var sh: Dictionary = T.SHADOW_LIFT if lifted else T.SHADOW_CARD
	var soft := StyleBoxFlat.new()
	soft.bg_color = Color(sh.colour, 0.0)
	soft.set_corner_radius_all(radius)
	soft.shadow_color = sh.colour
	soft.shadow_size = int(sh.blur / 2.0)
	soft.shadow_offset = Vector2(0, sh.offset / 2.0)
	canvas.draw_style_box(soft, rect)
	canvas.draw_style_box(box(T.SHADOW_DROP, Color.TRANSPARENT, 0, radius, 0), Rect2(rect.position + Vector2(0, sh.drop), rect.size))


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


static func box(bg: Color, border: Color = Color.TRANSPARENT, width := 0, radius: int = T.CHAMFER_MD, margin: int = T.SPACE_2) -> StyleBoxFlat:
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
	return T.PARCHMENT if contrast(T.PARCHMENT, bg) >= contrast(T.GROUND, bg) else T.GROUND


static func panel(bg: Color = T.STONE, border: Color = T.EDGE, width := 1, radius: int = T.CHAMFER_MD, margin: int = T.SPACE_2) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border, width, radius, margin))
	return p


## kind: "normal" (a stone slab), "primary" (the one brass action on a screen, marked
## with the meta `primary` for the UI check), "active" (a toggled action, rimmed in
## brass as selected) or "quiet" (the lesser actions in a row) (specs/019
## contracts/components.md).
static func button(text: String, kind := "normal", icon_name := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_override("font", font(T.BUTTON))
	b.add_theme_font_size_override("font_size", T.BUTTON.size)
	b.focus_mode = Control.FOCUS_ALL
	if icon_name != "":
		b.icon = icon(icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 34)
	# Feature 006: every button is a plinth of stone.
	style_stone_button(b, kind)
	b.set_meta("primary", kind == "primary")
	press_feedback(b)
	return b


## A zone on the play screen: a stone panel, edged in a colour that means something
## (damage owed), or the etched edge when `edge_colour` is clear.
static func stone_zone(edge_colour := Color(T.SHADE, 0), margin := 12, edge_width: float = T.BORDER_EDGE) -> StyleBox:
	var s := StoneStyle.new("slab")
	s.edge = edge_colour
	s.edge_width = edge_width
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_content_margin(side, margin)
	return s


## A raised slab of stone for a popup or dialog, with the large cut; an edge colour
## only when it means something (specs/019: no gold outline at rest).
static func stone_slab(edge_colour := Color(T.SHADE, 0), margin := 14) -> StyleBox:
	var s := StoneStyle.new("slab")
	s.size = "lg"
	s.edge = edge_colour
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_content_margin(side, margin)
	return s


## A PanelContainer drawn as a raised slab (menus, dialogs, the rulebook): the frame
## every overlay shares from feature 006 on.
static func slab(edge_colour := Color(T.SHADE, 0), margin := 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stone_slab(edge_colour, margin))
	return p


## A chip: a small sunken counter for one figure (specs/019 contracts/components.md
## "Chip"): a well with the game's icon, then the figure in the small numeral style.
## tone "plain" is parchment, "reward" bright brass, "harm" danger (whose figure
## carries its sign or the heart). A caller wraps it in a hit area when it opens the
## glossary.
static func chip(icon_name: String, figure: String, tone := "plain") -> PanelContainer:
	var p := PanelContainer.new()
	var well := StoneStyle.new("well")
	well.size = "sm"
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		well.set_content_margin(side, T.SPACE_2)
	for side in [SIDE_TOP, SIDE_BOTTOM]:
		well.set_content_margin(side, 0)
	p.add_theme_stylebox_override("panel", well)
	p.custom_minimum_size.y = T.CHIP_H
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink: Color = {"plain": T.PARCHMENT, "reward": T.BRASS_BRIGHT, "harm": T.DANGER}[tone]
	var row := hbox(T.SPACE_1)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if icon_name != "":
		row.add_child(icon_rect(icon_name, 26, ink))
	var l := label(figure, T.NUMERAL_SM, ink)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	p.add_child(row)
	p.set_meta("figure", l)
	return p


## A panel with a head (specs/019 contracts/components.md "Panel"): a slab whose head
## is a muted glyph and the heading in parchment over a hairline, then `content`.
static func titled_panel(heading: String, icon_name: String, content: Control, size := "md") -> PanelContainer:
	var p := PanelContainer.new()
	var st := StoneStyle.new("slab")
	st.size = size
	p.add_theme_stylebox_override("panel", st)
	var col := vbox(T.SPACE_2)
	var head := hbox(T.SPACE_2)
	if icon_name != "":
		head.add_child(icon_rect(icon_name, 30, T.PARCHMENT_MUTED))
	head.add_child(label(heading, T.HEADING, T.PARCHMENT))
	col.add_child(head)
	var rule := ColorRect.new()
	rule.color = T.LINE
	rule.custom_minimum_size.y = T.BORDER_ETCH
	col.add_child(rule)
	col.add_child(content)
	p.add_child(col)
	return p


## A button carved as a plinth of stone (specs/019 contracts/materials-and-ground.md):
## the raised stone you press, or brass for the "primary" action with dark ink on it.
## Pressed, its bevel collapses; disabled, it is flat stone with a faint label that is
## kept, so the player sees what will unlock; focused, its rim is jade.
static func style_stone_button(b: Button, kind := "normal") -> void:
	var primary := kind == "primary"
	var ink := T.ON_BRASS if primary else T.PARCHMENT
	var leaf := T.BRASS if primary else Color(T.SHADE, 0)
	var make := func(hover := false, down := false, off := false) -> StoneStyle:
		var st := StoneStyle.new("plinth")
		st.face = leaf.lightened(0.08) if hover and primary else (T.STONE_RAISED.lerp(T.PARCHMENT, 0.04) if hover else leaf)
		st.pressed = down
		st.disabled = off
		# A toggled action (Divert under way, the current section) is selected.
		st.selected = kind == "active" and not off
		return st
	b.add_theme_stylebox_override("normal", make.call())
	b.add_theme_stylebox_override("hover", make.call(true))
	b.add_theme_stylebox_override("pressed", make.call(false, true))
	b.add_theme_stylebox_override("hover_pressed", make.call(true, true))
	b.add_theme_stylebox_override("disabled", make.call(false, false, true))
	b.add_theme_stylebox_override("focus", focus_ring())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("font_disabled_color", T.PARCHMENT_FAINT)
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(c, ink)
	b.add_theme_color_override("icon_disabled_color", T.PARCHMENT_FAINT)


## Sets a button's words at its left, clear of the chamfer's cut (specs/019): a
## centred label needs no more room, a left-aligned one does.
static func align_left(b: Button) -> void:
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var st := b.get_theme_stylebox(state)
		if st != null:
			st.content_margin_left = T.SPACE_3


## Keyboard or controller focus: a jade rim in the control's own chamfered shape,
## drawn over its face (specs/019 FR-019).
static func focus_ring(size := "") -> StyleBox:
	var st := StoneStyle.new("plinth")
	st.focus = true
	st.ring_only = true
	st.size = size
	return st


## A display heading cut into the stone: a dark edge above the letters and a light
## one below, so they read as incised.
static func carved_label(text: String, type: Dictionary = T.HEADING, color: Color = T.PARCHMENT) -> Label:
	var l := label(text, type, color)
	l.add_theme_color_override("font_shadow_color", Color(T.SHEEN, 0.10))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_color_override("font_outline_color", Color(T.SHADE, 0.55))
	l.add_theme_constant_override("outline_size", 2)
	return l


## Tick the phone on the press, so every press is felt at once. The slab itself
## sinks by its pressed style (StoneStyle.pressed), not by moving the control, which a
## container would undo (specs/019 "Pressed").
static func press_feedback(c: Control) -> void:
	if c is BaseButton:
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
static func flash(c: CanvasItem, color: Color = T.PARCHMENT) -> void:
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


static func hbox(separation: int = T.SPACE_2) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	return row


static func vbox(separation: int = T.SPACE_2) -> VBoxContainer:
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
