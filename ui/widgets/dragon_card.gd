extends Control
## The Dragon Card on top of the Deck in the Final Battle, drawn as the printed card
## (specs/013 research R10, contracts/region-card-face.md "The Dragon Card"): a dark
## band with the dragon's name and title; under it a row of its figures, Initiative,
## Early Damage and Armor; the MP Tiers down the left (the Final Journey) and the HP
## Tiers down the right (the Final Enemy); and the whole dragon, large, filling the
## card under its figures behind the two ladders (art_rect()). The Deck zooms into
## one column or the other. Every part is a share of the card's size, as on the
## Region Card; the printed code is not shown. A locked dragon's card keeps its
## secrets: the dragon a single dark tone on bare stone, neither in its Ether's
## colour, no figures, and in the band a lock and question marks for its name.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const CardFace = preload("res://ui/widgets/card_face.gd")
## A dragon's title, under its name on the card, as a share of the name's floor.
const TITLE_SHARE := 0.7
const StatChip = preload("res://ui/widgets/stat_chip.gd")
const Creature = preload("res://ui/fx/creature.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const RegionCard = preload("res://ui/widgets/region_card.gd")
const RegionPanel = preload("res://ui/widgets/region_panel.gd")
const Art = preload("res://ui/model/art.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const DragonStats = preload("res://ui/widgets/dragon_stats.gd")

## The Dragon Card's hourglass: the Region Card's shape (region_panel.gd) in black,
## as its other figures are, its glass a dark slate so the shape still reads.
const BARS := T.STAT_PLATE
const GLASS := T.GLASS
## Shares of the card's width and height, measured from the scan
## (reference/sheets-official/o5.png, Grimroch and Vuurhast).
const LAYOUT := {
	"band": Rect2(0, 0, 1, 0.105),
	"figures": Rect2(0.12, 0.135, 0.76, 0.075),
	"mp": Rect2(0.02, 0.235, 0.24, 0.27),
	"hp": Rect2(0.74, 0.235, 0.24, 0.27),
	"art": Rect2(0, 0.105, 1, 0.895),
}
## The dragon is held in this share of the card's width from its sides and foot,
## and this far below the row of figures.
const ART_SIDE := 0.03
const ART_GAP := 0.01

var model := {}
## Each figure tells on hover what it means, as on the choice of dragon; on the
## Deck the card takes no part in the mouse. Set before render().
var explain := false
## A dragon not yet unlocked. Changing it redraws the card.
var locked := false:
	set(v):
		if v == locked:
			return
		locked = v
		if not model.is_empty():
			var m := model
			model = {}
			render(m)
## The locked dragon's one tone, and its name.
const LOCKED_TONE := T.LOCKED
const LOCKED_NAME := "? ? ?"
var _creature := Creature.new()
var _chips: Array = []
var _rows := {"figures": [], "mp": [], "hp": []}
var _stone := StoneStyle.new("well", 0.5)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	# Clipped, the stone's drop shadow would show only in the bottom corners.
	_stone.casts_shadow = false
	_creature.held = true
	add_child(_creature)
	resized.connect(_fit)
	_stone.changed.connect(queue_redraw)


func render(m: Dictionary) -> void:
	if m == model:
		return
	model = m.duplicate(true)
	for c in _chips:
		remove_child(c)
		c.queue_free()
	_chips = []
	_rows = {"figures": [], "mp": [], "hp": []}
	var d: Dictionary = m.dragon
	var e: String = m.element
	if m.art != "" and _creature.art_name != m.art:
		_creature.setup(m.art, Color(T.ether(e).lightened(0.3), 0.6), e, false)
	_creature.silhouette(LOCKED_TONE if locked else Color(T.SHADE, 0))
	if locked:
		_fit()
		queue_redraw()
		return
	_rows.figures.append([_chip({"icon": "initiative", "text": str(d.initiative), "color": T.STAT_PLATE})])
	var ed: Dictionary = d.early_damage
	_rows.figures.append([_chip({"icon": "attack_badge", "text": str(ed.value), "color": T.ether(ed.element),
		"ink": T.ether_shade(ed.element, "plate_ink"), "element": ed.element})])
	for a in d.armor:
		_rows.figures.append([_chip({"icon": "armor", "text": str(a.value), "color": T.ether(a.element),
			"ink": T.ether_shade(a.element, "plate_ink"), "element": a.element})])
	for tier in d.mp_tiers:
		_rows.mp.append([
			_chip({"icon": "mp_badge", "text": str(tier.mp.value), "color": T.STAT_PLATE, "backing": T.ether(tier.mp.element), "element": tier.mp.element}),
			_chip({"icon": "time_badge", "text": str(tier.time_penalty), "color": BARS, "inset": GLASS, "inset_icon": "time_badge_glass", "ink": T.PARCHMENT})])
	for tier in d.hp_tiers:
		_rows.hp.append([
			_chip({"icon": "hp", "text": str(tier.hp), "color": T.STAT_PLATE}),
			_chip({"icon": "attack_badge", "text": str(tier.attack.value), "color": T.ether(tier.attack.element),
				"ink": T.ether_shade(tier.attack.element, "plate_ink"), "element": tier.attack.element})])
	if explain:
		_explain(d)
	_fit()
	queue_redraw()


## The card's size at `width`: the Region Card's shape.
## Let the dragon move, or keep it still: still unless something wakes it, as the
## chosen card on the dragon screen does (DragonPick).
func set_live(on: bool) -> void:
	_creature.held = not on


static func card_size(width: float) -> Vector2:
	return RegionCard.card_size(width)


## The part of a card of `card_size` the view zooms into for `target`: the MP Tiers
## ("mp") down the left or the HP Tiers ("hp") down the right, as printed. `_aspect`
## is kept for the Deck's call; the printed column has its own shape.
static func target_rect(card_size: Vector2, target: String, _aspect := 1.0) -> Rect2:
	var r: Rect2 = LAYOUT.mp if target == "mp" else LAYOUT.hp
	return Rect2(card_size * r.position, card_size * r.size)


## Where the art is drawn on a card of `card_size`: the dragon's box on its artboard
## (Art.BODY, where the head already clears the HP Tiers) as large as it fits under
## the row of figures, held in from the card's edges, and centred there, the ladders
## lying over it as printed.
static func art_rect(card_size: Vector2) -> Rect2:
	var body := Art.BODY
	var top := LAYOUT.figures.end.y + ART_GAP
	var room := Rect2(card_size * Vector2(ART_SIDE, top), card_size * Vector2(1.0 - 2.0 * ART_SIDE, 1.0 - top - ART_SIDE))
	var k := minf(room.size.x / body.size.x, room.size.y / body.size.y)
	var at := room.get_center() - body.get_center() * k
	return Rect2(at, Art.FULL.size * k)


## The words for each figure: the opening figures, each Armor, and each tier with
## what its ladder is.
func _explain(d: Dictionary) -> void:
	# Passed on, so a tap on a figure still reaches whatever holds the card.
	var tip := func(c: Control, text: String, icon: String) -> void:
		c.mouse_filter = Control.MOUSE_FILTER_PASS
		HelpTip.show(c, text, icon)
	tip.call(_rows.figures[0][0], DragonStats.initiative_text(d), "initiative")
	tip.call(_rows.figures[1][0], "%s\n\n%s" % [DragonStats.early_damage_text(d), DragonStats.ether_text(d)], "attack")
	for i in d.armor.size():
		tip.call(_rows.figures[2 + i][0], DragonStats.armor_text(d.armor[i]), "armor")
	for journey in [true, false]:
		var rungs: Array = DragonStats.rungs(d, journey)
		var rows: Array = _rows.mp if journey else _rows.hp
		var tier := "Final Journey tier" if journey else "Final Enemy tier"
		for i in rows.size():
			var text := "%s: %s.\n\n%s" % [tier, DragonStats.rung_text(rungs[i], journey), DragonStats.ladder_heading_text(journey)]
			for c in rows[i]:
				tip.call(c, text, "time" if journey else "hp")


func _chip(opts: Dictionary) -> Control:
	var c: Control = StatChip.make(opts)
	c.custom_minimum_size = Vector2.ZERO
	add_child(c)
	_chips.append(c)
	return c


func _fit() -> void:
	# Rounded as a Mage Card is (specs/014 research R5).
	_stone.round_radius = UI.card_radius(size.x)
	if model.is_empty():
		return
	var at := art_rect(size)
	_creature.position = at.position
	_creature.size = at.size
	# The figures in one centred row.
	var f: Rect2 = LAYOUT.figures
	var row := Rect2(size * f.position, size * f.size)
	var side := row.size.y
	var n: int = _rows.figures.size()
	var gap := side * 0.12
	var x := row.get_center().x - (n * side + (n - 1) * gap) / 2.0
	for cell in _rows.figures:
		_put(cell[0], Rect2(x, row.position.y, side, side))
		x += side + gap
	# Each ladder: one row per tier, the need then its cost, side by side.
	for key in ["mp", "hp"]:
		var r: Rect2 = LAYOUT[key]
		var col := Rect2(size * r.position, size * r.size)
		var rows: Array = _rows[key]
		var h := col.size.y / maxf(1.0, rows.size())
		var s := minf(h * 0.9, col.size.x / 2.0 - 2.0)
		for i in rows.size():
			var y := col.position.y + i * h + (h - s) / 2.0
			_put(rows[i][0], Rect2(col.position.x + col.size.x / 2.0 - s - 1.0, y, s, s))
			_put(rows[i][1], Rect2(col.position.x + col.size.x / 2.0 + 1.0, y, s, s))
	queue_redraw()


func _put(c: Control, r: Rect2) -> void:
	c.position = r.position
	c.size = r.size


func _draw() -> void:
	if model.is_empty():
		return
	var card := Rect2(Vector2.ZERO, size)
	draw_style_box(_stone, card)
	if not locked:
		var under := Rect2(0, size.y * LAYOUT.band.end.y, size.x, size.y * (1.0 - LAYOUT.band.end.y))
		var pts := _stone.part(card, under)
		# The dragon's lair (art/painted/lairs/) fills the card under the band, cut to
		# its rounded corners; a dragon without one stands on Ether-tinted stone.
		var lair := UI.painted("lairs/" + model.art) if model.art != "" else null
		if lair != null:
			var src := RegionPanel.cover_region(lair.get_size(), under.size)
			var uvs := PackedVector2Array()
			for pt in pts:
				uvs.append((src.position + (pt - under.position) / under.size * src.size) / lair.get_size())
			draw_colored_polygon(pts, Color.WHITE, uvs, lair)
		else:
			draw_colored_polygon(pts, Color(T.ether(model.element), 0.22))
	var b: Rect2 = LAYOUT.band
	var band := Rect2(size * b.position, size * b.size)
	draw_colored_polygon(_stone.part(card, band), T.STAT_PLATE)
	# Its foot torn as a Mage Card's band is, edged in gold.
	UI.draw_torn_edge(self, band.position.x, band.end.x, band.end.y, band.size.y * 0.12, hash(model.id), T.STAT_PLATE,
		T.EDGE, maxf(1.0, size.y * 0.003))
	if locked:
		_draw_locked_band(band)
		return
	var heading := UI.font(T.HEADING)
	var name: String = model.name
	# Printed on the card, the band's words scale with it as a card's name does
	# (specs/019 FR-015, CardFace.name_floor).
	var least := CardFace.name_floor(size.x)
	# The title reads second, so it may be set smaller: still printed on the card and
	# scaled with it (specs/019 plan, card-print text).
	var title_least := roundi(least * TITLE_SHARE)
	var label := UI.font(T.LABEL)
	var title: String = model.title
	var fs := maxi(least, roundi(band.size.y * 0.5))
	var ls := maxi(title_least, roundi(band.size.y * 0.24))
	# The name and the title, one over the other by their fonts' own heights, as large as
	# the band holds both and the name fits its width.
	var stack := func(f: int, l: int) -> float:
		return heading.get_ascent(f) + heading.get_descent(f) + label.get_ascent(l) + label.get_descent(l)
	while fs > least and (heading.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > band.size.x * 0.8 or stack.call(fs, ls) > band.size.y * 0.94):
		fs -= 1
	while ls > title_least and (stack.call(fs, ls) > band.size.y * 0.94 or label.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ls).x > band.size.x * 0.9):
		ls -= 1
	var top: float = band.position.y + (band.size.y - stack.call(fs, ls)) / 2.0
	var nw := heading.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var name_base: float = top + heading.get_ascent(fs)
	draw_string(heading, Vector2(band.get_center().x - nw / 2.0, name_base), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, T.PARCHMENT)
	UI.drew_text(self, "name", fs, least)
	var lw := label.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ls).x
	var title_base: float = name_base + heading.get_descent(fs) + label.get_ascent(ls)
	draw_string(label, Vector2(band.get_center().x - lw / 2.0, title_base), title, HORIZONTAL_ALIGNMENT_LEFT, -1, ls, T.PARCHMENT_MUTED)
	UI.drew_text(self, "title", ls, title_least)


## The locked band: the lock, then question marks where the name would be, in gold.
func _draw_locked_band(band: Rect2) -> void:
	var heading := UI.font(T.HEADING)
	var fs := maxi(CardFace.name_floor(size.x), roundi(band.size.y * 0.5))
	var nw := heading.get_string_size(LOCKED_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var side := roundf(band.size.y * 0.5)
	var gap := side * 0.4
	var x := band.get_center().x - (side + gap + nw) / 2.0
	var top := band.position.y + (band.size.y - side) / 2.0 - band.size.y * 0.04
	draw_texture_rect(UI.icon("lock"), Rect2(x, top, side, side), false, T.PARCHMENT)
	draw_string(heading, Vector2(x + side + gap, band.position.y + band.size.y * 0.66), LOCKED_NAME, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, T.PARCHMENT)
	UI.drew_text(self, "locked", fs, CardFace.name_floor(size.x))
