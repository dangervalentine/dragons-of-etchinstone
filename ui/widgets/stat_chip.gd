extends Control
## A figure with its icon: a number on an icon shape (heart, banner, shield, star)
## or a number beside icons on a plate, with an optional caption underneath.
## Pressing it asks for the explanation of what it shows.

const T = preload("res://ui/theme/tokens.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const UI = preload("res://ui/theme/theme.gd")

signal help(glossary_id: String, source: Control)

var icon := ""
var text := ""
var color := T.BG_RAISED
var ink := T.INK
var caption := ""
## A small Ether icon beside the figure.
var element := ""
## Draw the number beside the icon on a rounded plate instead of on the icon.
var plate := false
var glossary_id := ""
## A chamfered box behind the shape, as the printed Journey MP sits in its Ether colour.
var backing := Color.TRANSPARENT
## A smaller copy of the shape inside it in this colour, as the printed hourglass.
var inset := Color.TRANSPARENT

var _hover := false

## Where the number belongs inside each shape, in the icons' 48-unit view box: the
## widest calm part of its body (the heart between its lobes and point, the shield
## above its point, the flame's round base, the dark hourglass between its bars).
## The number is sized to fit this window and centred on it by its own ink.
const WINDOW := {"hp": Rect2(8, 10, 32, 23), "initiative": Rect2(9, 5, 30, 29),
	"attack_badge": Rect2(11, 20, 26, 23), "armor": Rect2(8, 8, 32, 28),
	"mp_badge": Rect2(10, 27, 28, 16), "time_badge": Rect2(14.5, 12, 19, 24),
	"xp": Rect2(13, 13, 22, 22), "crown": Rect2(10, 18, 28, 18), "mp": Rect2(11, 29, 24, 13)}
const WINDOW_DEFAULT := Rect2(9, 9, 30, 30)
## The dark edge drawn under light digits, as a share of the font size.
const OUTLINE := 0.06

static var _inks := {}

static func make(opts: Dictionary) -> Control:
	var c = load("res://ui/widgets/stat_chip.gd").new()
	for key in opts:
		c.set(key, opts[key])
	c.custom_minimum_size = opts.get("min_size", Vector2(68, 72 if c.caption != "" else 52))
	c.mouse_filter = Control.MOUSE_FILTER_STOP if c.glossary_id != "" else Control.MOUSE_FILTER_IGNORE
	if c.glossary_id != "":
		if c.tooltip_text == "":
			HelpTip.mark(c, c.glossary_id)
		c.mouse_entered.connect(func(): c._hover = true; c.queue_redraw())
		c.mouse_exited.connect(func(): c._hover = false; c.queue_redraw())
	return c


func set_text(value: String) -> void:
	text = value
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if glossary_id != "" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		help.emit(glossary_id, self)
		accept_event()


func _draw() -> void:
	var caption_h := 24.0 if caption != "" else 0.0
	var area := Rect2(0, 0, size.x, size.y - caption_h)
	var font := UI.font("display_bold")
	if _hover:
		draw_style_box(UI.box(Color(1, 1, 1, 0.08), Color.TRANSPARENT, 0, T.RADIUS_S), Rect2(Vector2.ZERO, size))
	if plate:
		var h := minf(area.size.y, 48.0)
		var fs := int(h * 0.72)
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var i := h * 0.6
		var count := (1 if icon != "" else 0) + (1 if element != "" else 0)
		var w := minf(size.x, tw + count * (i + 3) + 18)
		var rect := Rect2((size.x - w) / 2.0, (area.size.y - h) / 2.0, w, h)
		draw_style_box(UI.box(color, Color(0, 0, 0, 0.35), 1, int(h * 0.24), 0), rect)
		var x := rect.position.x + 9
		var base := rect.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
		draw_string(font, Vector2(x, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
		x += tw + 3
		for name in [icon, element]:
			if name != "":
				draw_texture_rect(UI.icon(name), Rect2(x, rect.position.y + (h - i) / 2.0, i, i), false, ink)
				x += i + 3
	else:
		var side := minf(area.size.y, size.x)
		var rect := Rect2((size.x - side) / 2.0, (area.size.y - side) / 2.0, side, side)
		var box := rect
		if backing.a > 0.0:
			var c := side * 0.18
			var pts := PackedVector2Array([box.position + Vector2(c, 0), Vector2(box.end.x, box.position.y), box.end,
				Vector2(box.position.x, box.end.y), box.position + Vector2(0, c)])
			draw_colored_polygon(pts, backing)
			var closed := pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, Color(T.INK, 0.45), maxf(1.0, side * 0.025), true)
			rect = rect.grow(-side * 0.05)
		# A thin pale rim, as the printed badges have.
		draw_texture_rect(UI.icon(icon), rect.grow(maxf(1.0, side * 0.03)), false, Color(T.INK, 0.45))
		draw_texture_rect(UI.icon(icon), rect, false, color)
		if inset.a > 0.0:
			draw_texture_rect(UI.icon(icon), rect.grow(-side * 0.1), false, inset)
		_number(window_rect(icon, rect), text, color, ink)
		if element != "":
			_corner_sigil(element, box.end - Vector2(side * 0.14, side * 0.12), side * 0.36)
	if caption != "":
		var cf := UI.font("body_medium")
		var cs: int = T.LABEL[1]
		while cs > 16 and cf.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs).x > size.x + 6:
			cs -= 1
		var cw := cf.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs).x
		draw_string(cf, Vector2((size.x - cw) / 2.0, size.y - 5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs, T.INK_MUTED)


## The window for `name`'s number when its shape is drawn in `rect`.
static func window_rect(name: String, rect: Rect2) -> Rect2:
	var w: Rect2 = WINDOW.get(name, WINDOW_DEFAULT)
	var k := rect.size / 48.0
	return Rect2(rect.position + w.position * k, w.size * k)


## The digits' ink at `fs`, relative to where the string is drawn (its baseline
## start): the outline of the glyphs themselves, not the font's line box, so a
## number can be centred by what the eye sees.
static func ink_rect(text: String, fs: int) -> Rect2:
	var key := "%s|%d" % [text, fs]
	if _inks.has(key):
		return _inks[key]
	var ts := TextServerManager.get_primary_interface()
	var line := TextLine.new()
	line.add_string(text, UI.font("numeral"), fs)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var x := 0.0
	for g in ts.shaped_text_get_glyphs(line.get_rid()):
		var c: Dictionary = ts.font_get_glyph_contours(g.font_rid, fs, g.index)
		for p in c.get("points", PackedVector3Array()):
			var q := Vector2(x + g.offset.x + p.x, g.offset.y + p.y)
			lo = lo.min(q)
			hi = hi.max(q)
		x += g.advance
	var r := Rect2(lo, hi - lo) if lo.x != INF else Rect2()
	_inks[key] = r
	return r


## The size and baseline start that fit `text`'s ink, with its outline, inside
## `window` and put the ink's centre on the window's centre.
static func fit(text: String, window: Rect2) -> Dictionary:
	var ref := ink_rect(text, 100)
	if ref.size.x <= 0.0 or ref.size.y <= 0.0:
		return {"fs": 1, "pos": window.get_center(), "ink": Rect2()}
	# The outline grows the ink by OUTLINE * fs all round.
	var fs := int(minf(window.size.x / (ref.size.x / 100.0 + OUTLINE), window.size.y / (ref.size.y / 100.0 + OUTLINE)))
	# Hinting changes the outline from size to size, so the estimate is checked at
	# its own size and stepped down until it truly fits.
	var ink := ink_rect(text, fs)
	while fs > 6 and (ink.size.x + 2.0 * OUTLINE * fs > window.size.x or ink.size.y + 2.0 * OUTLINE * fs > window.size.y):
		fs -= 1
		ink = ink_rect(text, fs)
	var pos := window.get_center() - ink.get_center()
	return {"fs": fs, "pos": pos, "ink": Rect2(ink.position + pos, ink.size)}


## The number in its window: light digits get a dark edge in a deep shade of the
## badge, so they read on any fill; dark digits stand on a light fill by themselves.
func _number(window: Rect2, value: String, fill: Color, colour: Color) -> void:
	if value == "":
		return
	var font := UI.font("numeral")
	var f := fit(value, window)
	if colour.get_luminance() > 0.5:
		var edge := maxi(2, int(f.fs * OUTLINE * 2.0))
		draw_string_outline(font, f.pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, f.fs, edge, Color(fill.darkened(0.7), 0.95))
	draw_string(font, f.pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, f.fs, colour)


## The Ether as a bare sigil on the badge's corner, a shade brighter than its colour,
## lifted on a soft shadow, as on the Mage cards.
func _corner_sigil(e: String, centre: Vector2, d: float) -> void:
	var r := Rect2(centre - Vector2(d, d) / 2.0, Vector2(d, d))
	var w := maxf(1.0, d * 0.08)
	for k in 8:
		var off := Vector2.RIGHT.rotated(k * PI / 4.0) * w + Vector2(w * 0.4, w * 1.2)
		draw_texture_rect(UI.icon(e), Rect2(r.position + off, r.size), false, Color(0, 0, 0, 0.22))
	draw_texture_rect(UI.icon(e), r, false, T.ether_shade(e, "plate").lerp(T.ether_shade(e, "lit"), 0.5))


## Tooltips wrap to a narrow panel, like the cards'.
func _make_custom_tooltip(for_text: String) -> Object:
	return HelpTip.tooltip(self, for_text)
