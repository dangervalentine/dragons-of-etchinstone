extends Control
## A figure with its icon: a number on an icon shape (heart, banner, shield, star)
## or a number beside icons on a plate, with an optional caption underneath.
## Pressing it asks for the explanation of what it shows.

const T = preload("res://ui/theme/tokens.gd")
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

var _hover := false


static func make(opts: Dictionary) -> Control:
	var c = load("res://ui/widgets/stat_chip.gd").new()
	for key in opts:
		c.set(key, opts[key])
	c.custom_minimum_size = opts.get("min_size", Vector2(68, 72 if c.caption != "" else 52))
	c.mouse_filter = Control.MOUSE_FILTER_STOP if c.glossary_id != "" else Control.MOUSE_FILTER_IGNORE
	if c.glossary_id != "":
		c.mouse_default_cursor_shape = Control.CURSOR_HELP
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
		if element != "":
			rect.position.x -= side * 0.16
		draw_texture_rect(UI.icon(icon), rect, false, color)
		var fs := int(side * 0.5)
		var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var lift := side * 0.08 if icon == "crown" or icon == "hp" or icon == "mp" else 0.0
		var base := rect.get_center().y + lift + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
		draw_string(font, Vector2(rect.get_center().x - sz.x / 2.0, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
		if element != "":
			var e := side * 0.42
			draw_circle(Vector2(rect.end.x + e * 0.1, rect.end.y - e * 0.6), e * 0.62, T.BG_BAND)
			draw_texture_rect(UI.icon(element), Rect2(rect.end.x - e * 0.4, rect.end.y - e * 1.1, e, e), false, T.ether_ink(element))
	if caption != "":
		var cf := UI.font("body_medium")
		var cs: int = T.LABEL[1]
		while cs > 16 and cf.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs).x > size.x + 6:
			cs -= 1
		var cw := cf.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs).x
		draw_string(cf, Vector2((size.x - cw) / 2.0, size.y - 5), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cs, T.INK_MUTED)
