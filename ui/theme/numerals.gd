extends RefCounted
## Numbers placed by their ink, for the badges and the cards: a number is measured
## by the outline of its own glyphs, not the font's line box, so it can be centred
## by what the eye sees, sized to fit the window its shape leaves for it, and given
## a dark edge so light digits read on any fill.

const UI = preload("res://ui/theme/theme.gd")

## The dark edge drawn under light digits, each side, as a share of the font size.
const OUTLINE := 0.06

static var _inks := {}


static func font() -> Font:
	return UI.font("numeral")


## The digits' ink at `fs`, relative to where the string is drawn (its baseline start).
static func ink_rect(text: String, fs: int) -> Rect2:
	var key := "%s|%d" % [text, fs]
	if _inks.has(key):
		return _inks[key]
	var ts := TextServerManager.get_primary_interface()
	var line := TextLine.new()
	line.add_string(text, font(), fs)
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


## The size and baseline start that fit `text`'s ink, with its edge, inside `window`
## and put the ink's centre on the window's centre. `most` caps the size, so the
## numbers of one card keep a common size and only shrink where they must.
static func fit(text: String, window: Rect2, most := 0) -> Dictionary:
	var ref := ink_rect(text, 100)
	if ref.size.x <= 0.0 or ref.size.y <= 0.0:
		return {"fs": 1, "pos": window.get_center(), "ink": Rect2()}
	var fs := int(minf(window.size.x / (ref.size.x / 100.0 + 2.0 * OUTLINE), window.size.y / (ref.size.y / 100.0 + 2.0 * OUTLINE)))
	if most > 0:
		fs = mini(fs, most)
	# Hinting changes the outline from size to size, so the estimate is checked at
	# its own size and stepped down until it truly fits.
	var ink := ink_rect(text, fs)
	while fs > 6 and (ink.size.x + 2.0 * OUTLINE * fs > window.size.x or ink.size.y + 2.0 * OUTLINE * fs > window.size.y):
		fs -= 1
		ink = ink_rect(text, fs)
	var pos := window.get_center() - ink.get_center()
	return {"fs": fs, "pos": pos, "ink": Rect2(ink.position + pos, ink.size)}


## `text` fitted and centred in `window` on `canvas`. Light digits get a dark edge
## in a deep shade of `fill`, fading with them; dark digits stand on a light fill
## by themselves.
static func draw(canvas: CanvasItem, window: Rect2, text: String, colour: Color, fill: Color, most := 0) -> void:
	if text == "":
		return
	var f := fit(text, window, most)
	_put(canvas, f.pos, text, f.fs, colour, fill)


## `text` at size `fs`, starting at `x` and centred by its ink on the row from `top`
## of height `h`. Returns the width it takes.
static func draw_left(canvas: CanvasItem, x: float, top: float, h: float, text: String, fs: int, colour: Color, fill: Color) -> float:
	var ink := ink_rect(text, fs)
	_put(canvas, Vector2(x, top + h / 2.0 - ink.get_center().y), text, fs, colour, fill)
	return width(text, fs)


## The width `text` takes at `fs`, for laying out what follows it.
static func width(text: String, fs: int) -> float:
	return font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


static func _put(canvas: CanvasItem, pos: Vector2, text: String, fs: int, colour: Color, fill: Color) -> void:
	if colour.get_luminance() > 0.5:
		var edge := Color(fill.darkened(0.7), 0.95 * colour.a)
		canvas.draw_string_outline(font(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, int(2.0 * OUTLINE * fs)), edge)
	canvas.draw_string(font(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)
