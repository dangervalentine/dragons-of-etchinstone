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

## How far a number sits below the middle of its shape, as a share of its size, so
## it lands in the shape's body.
const LIFT := {"crown": 0.08, "hp": 0.06, "mp": 0.08, "attack_badge": 0.14, "mp_badge": 0.2,
	"initiative": -0.05, "armor": -0.02}
## The number's size as a share of the shape, where the shape leaves less room.
const NUMBER := {"mp_badge": 0.4, "time_badge": 0.42}


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
		var scale: float = NUMBER.get(icon, 0.5)
		var fs := int(side * scale)
		var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var lift: float = LIFT.get(icon, 0.0)
		var base := rect.get_center().y + side * lift + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
		draw_string(font, Vector2(rect.get_center().x - sz.x / 2.0, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
		if element != "":
			_corner_sigil(element, box.end - Vector2(side * 0.14, side * 0.12), side * 0.36)
	if caption != "":
		var cf := UI.font("body_medium")
		var cs: int = T.LABEL[1]
		while cs > 16 and cf.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs).x > size.x + 6:
			cs -= 1
		var cw := cf.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs).x
		draw_string(cf, Vector2((size.x - cw) / 2.0, size.y - 5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs, T.INK_MUTED)


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
