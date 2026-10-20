extends Control
## The Dragon Card on top of the Deck in the Final Battle, drawn as the printed card
## (specs/013 research R10, contracts/region-card-face.md "The Dragon Card"): a dark
## band with the dragon's name and title; under it a row of its figures, Initiative,
## Early Damage and Armor; the MP Tiers down the left
## (the Final Journey) and the HP Tiers down the right (the Final Enemy); and the
## whole dragon, large, its head between the two ladders (art_rect()). The Deck
## zooms into one column or the other. Every part is a share of the card's size, as
## on the Region Card; the printed code is not shown.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StatChip = preload("res://ui/widgets/stat_chip.gd")
const Creature = preload("res://ui/fx/creature.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const RegionCard = preload("res://ui/widgets/region_card.gd")
const Art = preload("res://ui/model/art.gd")

## The Dragon Card's hourglass: the Region Card's shape (region_panel.gd) in black,
## as its other figures are, its glass a dark slate so the shape still reads.
const BARS := T.BG_BAND
const GLASS := Color("3b3747")
## Shares of the card's width and height, measured from the scan
## (reference/sheets-official/o5.png, Grimroch and Vuurhast).
const LAYOUT := {
	"band": Rect2(0, 0, 1, 0.105),
	"figures": Rect2(0.12, 0.135, 0.76, 0.075),
	"mp": Rect2(0.02, 0.235, 0.24, 0.27),
	"hp": Rect2(0.74, 0.235, 0.24, 0.27),
	"art": Rect2(0, 0.105, 1, 0.895),
}

var model := {}
var _creature := Creature.new()
var _chips: Array = []
var _rows := {"figures": [], "mp": [], "hp": []}
var _stone := StoneStyle.new("well", 0.5)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
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
	_rows.figures.append([_chip({"icon": "initiative", "text": str(d.initiative), "color": T.BG_BAND})])
	var ed: Dictionary = d.early_damage
	_rows.figures.append([_chip({"icon": "attack_badge", "text": str(ed.value), "color": T.ether(ed.element),
		"ink": T.ether_shade(ed.element, "plate_ink"), "element": ed.element})])
	for a in d.armor:
		_rows.figures.append([_chip({"icon": "armor", "text": str(a.value), "color": T.ether(a.element),
			"ink": T.ether_shade(a.element, "plate_ink"), "element": a.element})])
	for tier in d.mp_tiers:
		_rows.mp.append([
			_chip({"icon": "mp_badge", "text": str(tier.mp.value), "color": T.BG_BAND, "backing": T.ether(tier.mp.element), "element": tier.mp.element}),
			_chip({"icon": "time_badge", "text": str(tier.time_penalty), "color": BARS, "inset": GLASS, "inset_icon": "time_badge_glass", "ink": T.INK})])
	for tier in d.hp_tiers:
		_rows.hp.append([
			_chip({"icon": "hp", "text": str(tier.hp), "color": T.BG_BAND}),
			_chip({"icon": "attack_badge", "text": str(tier.attack.value), "color": T.ether(tier.attack.element),
				"ink": T.ether_shade(tier.attack.element, "plate_ink"), "element": tier.attack.element})])
	_fit()
	queue_redraw()


## The card's size at `width`: the Region Card's shape.
static func card_size(width: float) -> Vector2:
	return RegionCard.card_size(width)


## The part of a card of `card_size` the view zooms into for `target`: the MP Tiers
## ("mp") down the left or the HP Tiers ("hp") down the right, as printed. `_aspect`
## is kept for the Deck's call; the printed column has its own shape.
static func target_rect(card_size: Vector2, target: String, _aspect := 1.0) -> Rect2:
	var r: Rect2 = LAYOUT.mp if target == "mp" else LAYOUT.hp
	return Rect2(card_size * r.position, card_size * r.size)


## Where the whole dragon is drawn on a card of `card_size`, given where its head
## lies in its art (`head`, in the art's 512 units): as wide as the card, but moved
## so its head sits in the gap between the two ladders, just under the row of
## figures, its body running off the left of the card (clipped) and below. With no
## head marked, it fills the body as printed.
static func art_rect(card_size: Vector2, head: Rect2) -> Rect2:
	var side := card_size.x
	var body: Rect2 = LAYOUT.art
	if head == Art.FULL:
		return Rect2(card_size * body.position, Vector2(side, side))
	var k := side / Art.FULL.size.x
	var gap_x := (LAYOUT.mp.end.x + LAYOUT.hp.position.x) / 2.0 * card_size.x
	var top := (LAYOUT.figures.end.y + 0.01) * card_size.y
	var x := minf(0.0, gap_x - head.get_center().x * k)
	var y := maxf(body.position.y * card_size.y, top - head.position.y * k)
	return Rect2(x, y, side, side)


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
	var at := art_rect(size, Art.head(model.art, UI.is_painted(model.art)))
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
	draw_colored_polygon(_stone.part(card, Rect2(0, size.y * LAYOUT.band.end.y, size.x, size.y * (1.0 - LAYOUT.band.end.y))),
		Color(T.ether(model.element), 0.22))
	var b: Rect2 = LAYOUT.band
	var band := Rect2(size * b.position, size * b.size)
	draw_colored_polygon(_stone.part(card, band), T.BG_BAND)
	# Its foot torn as a Mage Card's band is, edged in gold.
	UI.draw_torn_edge(self, band.position.x, band.end.x, band.end.y, band.size.y * 0.12, hash(model.id), T.BG_BAND,
		T.muted(T.GOLD), maxf(1.0, size.y * 0.003))
	var heading := UI.font(T.HEADING[0])
	var name: String = model.name.to_upper()
	var fs := maxi(6, roundi(band.size.y * 0.5))
	while fs > 6 and heading.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > band.size.x * 0.8:
		fs -= 1
	var nw := heading.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(heading, Vector2(band.get_center().x - nw / 2.0, band.position.y + band.size.y * 0.55), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, T.INK)
	var label := UI.font(T.LABEL_BOLD[0])
	var title: String = model.title.to_upper()
	var ls := maxi(6, roundi(band.size.y * 0.24))
	var lw := label.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, ls).x
	draw_string(label, Vector2(band.get_center().x - lw / 2.0, band.position.y + band.size.y * 0.88), title, HORIZONTAL_ALIGNMENT_LEFT, -1, ls, T.GOLD)
