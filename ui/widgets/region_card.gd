extends Control
## The Region Card on top of the Deck, turned to the current Region, drawn as the
## printed card (specs/013 research R1, contracts/region-card-face.md): a dark band
## with the Region's name and number between two ornaments, its four Enemies two by
## two, and its four Journeys in a row beneath them. Every part is a fixed share of
## the card, so the whole card scales as one picture and the Deck can zoom into any
## panel of it (deck_stack.gd). The card's printed code is not shown: the model
## keeps which physical card it is only to tell a turn from a change of card.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const RegionPanel = preload("res://ui/widgets/region_panel.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

## Width over height, as printed (about 498 by 695 on the scan).
const ASPECT := 5.0 / 7.0
## Shares of the card's width (x) and height (y), measured from the scan
## (reference/sheets-official/o5.png).
const LAYOUT := {
	"band": Rect2(0, 0, 1, 0.105),
	"enemy_x": [0.045, 0.49, 0.51, 0.955],
	"enemy_y": [0.135, 0.355, 0.39, 0.61],
	"journey_x": [0.005, 0.995],
	"journey_gap": 0.008,
	"journey_y": [0.655, 0.955],
}

var model := {}
## The panel looked at once the Deck has zoomed in, and how far the rest of the
## card is dimmed around it, 0 to 1.
var focus_key := ""
var focus := 0.0
var _panels := {}
var _stone := StoneStyle.new("well", 0.5)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_fit)
	_stone.changed.connect(queue_redraw)


func render(m: Dictionary) -> void:
	if m == model:
		return
	model = m.duplicate(true)
	for v in _panels.values():
		remove_child(v)
		v.queue_free()
	_panels = {}
	for p in model.panels:
		var view := RegionPanel.new()
		add_child(view)
		view.render(p)
		_panels[p.key] = view
	_fit()
	queue_redraw()


## Dim the card round `key`'s panel by `amount` (0 to 1), so the eye goes to it.
func set_focus(key: String, amount: float) -> void:
	focus_key = key
	focus = amount
	for k in _panels:
		var dim := 1.0 - 0.62 * amount if k != key else 1.0
		_panels[k].modulate = Color(dim, dim, dim * 1.04)
	queue_redraw()


func panel(key: String) -> Control:
	return _panels.get(key)


func panels() -> Dictionary:
	return _panels


## The card's size at `width`.
static func card_size(width: float) -> Vector2:
	return Vector2(width, width / ASPECT)


## Where a panel sits on a card of `card_size`, as printed.
static func panel_rect(card_size: Vector2, key: String) -> Rect2:
	var parts := key.split(":")
	var i := int(parts[1]) - 1
	if parts[0] == "enemy":
		var xs: Array = LAYOUT.enemy_x
		var ys: Array = LAYOUT.enemy_y
		var col := i % 2
		var row := i / 2
		var x0: float = xs[col * 2]
		var x1: float = xs[col * 2 + 1]
		var y0: float = ys[row * 2]
		var y1: float = ys[row * 2 + 1]
		return Rect2(card_size.x * x0, card_size.y * y0, card_size.x * (x1 - x0), card_size.y * (y1 - y0))
	var span: Array = LAYOUT.journey_x
	var gap: float = LAYOUT.journey_gap
	var w: float = (span[1] - span[0] - 3.0 * gap) / 4.0
	var x: float = span[0] + i * (w + gap)
	var y: Array = LAYOUT.journey_y
	return Rect2(card_size.x * x, card_size.y * y[0], card_size.x * w, card_size.y * (y[1] - y[0]))


func _fit() -> void:
	for key in _panels:
		var r := panel_rect(size, key)
		_panels[key].position = r.position
		_panels[key].size = r.size
	queue_redraw()


func _draw() -> void:
	if model.is_empty():
		return
	var card := Rect2(Vector2.ZERO, size)
	draw_style_box(_stone, card)
	var b: Rect2 = LAYOUT.band
	var band := Rect2(card.size * b.position, card.size * b.size)
	draw_rect(band, T.BG_BAND)
	draw_line(Vector2(band.position.x, band.end.y), band.end, T.muted(T.GOLD), maxf(1.0, size.y * 0.003))
	# An ornament at each end, the name between them, and the Region's number under it.
	var o := band.size.y * 0.72
	var oy := band.get_center().y - o / 2.0
	var mark: Texture2D = UI.icon("sigil_region")
	for x in [band.position.x + band.size.y * 0.2, band.end.x - band.size.y * 0.2 - o]:
		draw_texture_rect(mark, Rect2(x, oy, o, o), false, Color(T.INK, 0.85))
	var room := band.size.x - 2.0 * (o + band.size.y * 0.4)
	var heading := UI.font(T.HEADING[0])
	var name: String = model.name.to_upper()
	var fs := maxi(6, roundi(band.size.y * 0.46))
	while fs > 6 and heading.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		fs -= 1
	var nw := heading.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(heading, Vector2(band.get_center().x - nw / 2.0, band.position.y + band.size.y * 0.52), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, T.INK)
	var label := UI.font(T.LABEL_BOLD[0])
	var line := "REGION %d" % model.region
	var ls := maxi(6, roundi(band.size.y * 0.26))
	var lw := label.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, ls).x
	draw_string(label, Vector2(band.get_center().x - lw / 2.0, band.position.y + band.size.y * 0.88), line, HORIZONTAL_ALIGNMENT_LEFT, -1, ls, T.GOLD)
	# The card's own band and stone step back with the other panels (set_focus).
	if focus > 0.0:
		draw_rect(card, Color(0, 0, 0, 0.62 * focus))
