extends Control
## Draws the face of a Mage Card at any size, arranged like the printed card:
## Level crown and name across the top; the Key Card strip under it; then, down the
## left edge of the Ether field, Initiative, basic action, enhanced action, Boost
## and Armor. Only the current Level is drawn.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const FIELD_SHADER = preload("res://ui/fx/shaders/ether_field.gdshader")

var model := {}
## Greyed out, for a card that cannot be chosen.
var dimmed := false: set = set_dimmed
## Figures to ring, such as those an Upgrade or Downgrade would change.
var changed: Array = []
var glow: Color = T.GOLD

var _field := ColorRect.new()
var _ink := Control.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.material = ShaderMaterial.new()
	_field.material.shader = FIELD_SHADER
	add_child(_field)
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.draw.connect(_draw_ink)
	add_child(_ink)
	resized.connect(_layout)


func set_model(m: Dictionary, ring: Array = [], ring_colour: Color = T.GOLD) -> void:
	model = m
	changed = ring
	glow = ring_colour
	_layout()


func set_dimmed(value: bool) -> void:
	dimmed = value
	_field.material.set_shader_parameter("dim", 0.85 if dimmed else 0.0)
	_ink.queue_redraw()


func _border() -> float:
	return maxf(2.0, roundf(size.x * 0.016))


func _band_h() -> float:
	return roundf(size.y * 0.165)


func _strip_h() -> float:
	return roundf(size.y * 0.1)


func _field_rect() -> Rect2:
	var b := _border()
	var top := _band_h() + _strip_h()
	return Rect2(b, top, size.x - 2 * b, size.y - top - b)


func _layout() -> void:
	_ink.position = Vector2.ZERO
	_ink.size = size
	var f := _field_rect()
	_field.position = f.position
	_field.size = f.size
	if not model.is_empty():
		_field.material.set_shader_parameter("tint", T.ether(model.element))
	_field.material.set_shader_parameter("size", f.size)
	queue_redraw()
	_ink.queue_redraw()


func _draw() -> void:
	draw_style_box(_frame(true), Rect2(Vector2.ZERO, size))


func _frame(filled: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = T.BG_BAND
	s.draw_center = filled
	s.border_color = T.ether(model.get("element")) if not dimmed else T.LINE_SOFT
	s.set_border_width_all(int(_border()))
	s.set_corner_radius_all(int(size.x * 0.075))
	s.anti_aliasing_size = 0.6
	if filled:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 6
		s.shadow_offset = Vector2(0, 3)
	return s


func _draw_ink() -> void:
	if model.is_empty() or size.x < 8:
		return
	var w := size.x
	var pad := roundf(w * 0.04)
	var band := _band_h()
	var strip := _strip_h()
	var lv: Dictionary = model.stats
	var ether: Color = T.ether(model.element)
	var ink := T.INK if not dimmed else T.INK_MUTED

	# Top band: Level crown and name.
	var crown := roundf(band * 0.84)
	var crown_rect := Rect2(pad, (band - crown) / 2.0 + 1, crown, crown)
	_icon("crown", crown_rect, T.GOLD if not dimmed else T.INK_MUTED)
	_number(Rect2(crown_rect.position + Vector2(0, crown * 0.12), crown_rect.size), str(model.level), crown * 0.56, T.BG_BASE)
	if model.get("downgraded", false):
		var a := crown * 0.5
		_icon("down_arrow", Rect2(crown_rect.end - Vector2(a * 0.8, a * 0.8), Vector2(a, a)), T.BAD)
	var name_x := crown_rect.end.x + pad * 0.7
	_name(Rect2(name_x, 2, w - name_x - pad, band - 2), model.name.to_upper(), ink)

	# Key Card strip: the Encounter this card asks for, and its Upgrade cost.
	var sy := band
	var si := roundf(strip * 0.74)
	var x := pad
	var key: Dictionary = lv.encounter
	if changed.has("encounter") or changed.has("hardship"):
		_ring("encounter" if changed.has("encounter") else "hardship", Rect2(pad, sy + 2, w * 0.4, strip - 4))
	_icon(key.type, Rect2(x, sy + (strip - si) / 2.0, si, si), T.INK_MUTED)
	x += si + 2
	x += _text(Vector2(x, sy), strip, str(key.index), strip * 0.8, T.INK_MUTED) + pad * 0.6
	if lv.hardship != null:
		_icon(lv.hardship, Rect2(x, sy + (strip - si) / 2.0, si, si), T.BAD if not dimmed else T.INK_MUTED)
	var cost: String = str(lv.upgrade_cost) if lv.upgrade_cost != null else "max"
	var cost_w := UI.font("display_bold").get_string_size(cost, HORIZONTAL_ALIGNMENT_LEFT, -1, int(strip * 0.8)).x
	var cx := w - pad - si
	_ring("upgrade_cost", Rect2(cx - cost_w - 5, sy + 2, cost_w + si + 6, strip - 4))
	_icon("xp", Rect2(cx, sy + (strip - si) / 2.0, si, si), T.GOLD if not dimmed else T.INK_MUTED)
	_text(Vector2(cx - cost_w - 3, sy), strip, cost, strip * 0.8, T.GOLD if not dimmed else T.INK_MUTED)

	# The Ether field: a faint sigil, and the stat column down the left edge.
	var f := _field_rect()
	var sig := minf(f.size.x * 0.66, f.size.y * 0.74)
	_icon("sigil_" + model.element, Rect2(f.end.x - sig - pad * 0.5, f.get_center().y - sig / 2.0, sig, sig), Color(1, 1, 1, 0.2))
	var badge := roundf(strip * 1.05)
	var badge_rect := Rect2(f.end.x - badge - pad * 0.6, f.position.y + pad * 0.6, badge, badge)
	_ink.draw_circle(badge_rect.get_center(), badge / 2.0, T.BG_BAND)
	_icon(model.element, badge_rect.grow(-badge * 0.2), ether if not dimmed else T.INK_MUTED)

	var gap := maxf(2.0, roundf(f.size.y * 0.016))
	var row := floorf((f.size.y - pad - gap * 4) / 5.0)
	var plate_w := roundf(w * 0.44)
	var y := f.position.y + pad * 0.5
	var num := minf(row * 0.86, T.NUMERAL[1] * 1.15)
	# Initiative, on its banner.
	_ring("initiative", Rect2(pad, y, row, row))
	_icon("initiative", Rect2(pad, y, row, row), T.BG_BAND)
	_number(Rect2(pad, y - row * 0.06, row, row), str(lv.initiative), num * 0.78, ink)
	y += row + gap
	_ring("basic", Rect2(pad, y, plate_w, row))
	_action(Rect2(pad, y, plate_w, row), lv.basic, T.BG_BAND, ink, "", num)
	y += row + gap
	var enh: Color = T.ether(lv.enhanced.element) if not dimmed else T.INK_MUTED.darkened(0.25)
	_ring("enhanced", Rect2(pad, y, plate_w + row * 0.5, row))
	_action(Rect2(pad, y, plate_w + row * 0.5, row), lv.enhanced, enh, T.BG_BASE, lv.enhanced.element, num)
	y += row + gap
	var boost_rect := Rect2(pad, y, roundf(plate_w * 0.86), row)
	_ring("boost", boost_rect)
	_plate(boost_rect, T.BG_BAND)
	_number(boost_rect, "+%d" % lv.boost, num, ink)
	y += row + gap
	var armored: bool = lv.armor.element != null
	var shield: Color = T.ether(lv.armor.element) if armored and not dimmed else T.BG_BAND
	_ring("armor", Rect2(pad, y, row * (1.7 if armored else 1.0), row))
	_icon("armor", Rect2(pad, y, row, row), shield)
	_number(Rect2(pad, y - row * 0.04, row, row), str(lv.armor.value), num * 0.74, T.BG_BASE if armored and not dimmed else ink)
	if armored:
		var e := row * 0.6
		_icon(lv.armor.element, Rect2(pad + row + 3, y + (row - e) / 2.0, e, e), shield)

	# The frame's border again, over the field's square corners.
	_ink.draw_style_box(_frame(false), Rect2(Vector2.ZERO, size))
	if model.get("downgraded", false):
		_crack()


## Jagged cracks from the top right corner: this card was Downgraded this Encounter.
func _crack() -> void:
	var w := size.x
	var o := Vector2(w - 2, 2)
	var lines := [
		[o, o + Vector2(-w * 0.12, w * 0.1), o + Vector2(-w * 0.16, w * 0.24), o + Vector2(-w * 0.27, w * 0.31)],
		[o + Vector2(-w * 0.12, w * 0.1), o + Vector2(-w * 0.26, w * 0.12), o + Vector2(-w * 0.33, w * 0.06)],
		[o, o + Vector2(-w * 0.03, w * 0.2), o + Vector2(-w * 0.08, w * 0.34)],
	]
	for pts in lines:
		_ink.draw_polyline(PackedVector2Array(pts), Color(T.BG_BASE, 0.9), maxf(3.0, w * 0.024))
		_ink.draw_polyline(PackedVector2Array(pts), T.BAD, maxf(1.5, w * 0.01))


## A number with the icons for its action type on a plate; `element` adds its Ether icon.
func _action(rect: Rect2, action: Dictionary, bg: Color, ink: Color, element: String, num: float) -> void:
	_plate(rect, bg)
	var icons := []
	if action.type != "move":
		icons.append("attack")
	if action.type != "attack":
		icons.append("move")
	if element != "":
		icons.append(element)
	var i := rect.size.y * 0.62
	var text := str(action.value)
	var font := UI.font("display_bold")
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(num)).x
	var total := tw + icons.size() * (i + 2)
	var x := rect.position.x + maxf(4.0, (rect.size.x - total) / 2.0)
	_text(Vector2(x, rect.position.y), rect.size.y, text, num, ink)
	x += tw + 3
	for name in icons:
		_icon(name, Rect2(x, rect.position.y + (rect.size.y - i) / 2.0, i, i), ink)
		x += i + 2


## A ring behind a figure that would change.
func _ring(key: String, rect: Rect2) -> void:
	if not changed.has(key):
		return
	var s := StyleBoxFlat.new()
	s.bg_color = Color(glow, 0.35)
	s.border_color = glow
	s.set_border_width_all(maxi(2, int(size.x * 0.016)))
	s.set_corner_radius_all(int(rect.size.y * 0.3))
	_ink.draw_style_box(s, rect.grow(maxf(3.0, size.x * 0.018)))


func _plate(rect: Rect2, bg: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(rect.size.y * 0.24))
	s.border_color = Color(0, 0, 0, 0.35)
	s.set_border_width_all(1)
	_ink.draw_style_box(s, rect)


func _icon(name: String, rect: Rect2, color: Color) -> void:
	_ink.draw_texture_rect(UI.icon(name), rect, false, color)


## Text centred in a rectangle.
func _number(rect: Rect2, text: String, font_size: float, color: Color) -> void:
	var font := UI.font("display_bold")
	var fs := int(font_size)
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var base := rect.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	_ink.draw_string(font, Vector2(rect.get_center().x - sz.x / 2.0, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


## Left-aligned text centred vertically in a row; returns its width.
func _text(pos: Vector2, row_h: float, text: String, font_size: float, color: Color) -> float:
	var font := UI.font("display_bold")
	var fs := int(font_size)
	var base := pos.y + row_h / 2.0 + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	_ink.draw_string(font, Vector2(pos.x, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


## The name on one or two lines, at the largest size that fits.
func _name(rect: Rect2, text: String, color: Color) -> void:
	var font := UI.font("display")
	var words := text.split(" ")
	var lines := [text]
	if words.size() > 1:
		# Break where the two lines are closest in length.
		var best := 100000.0
		for i in range(1, words.size()):
			var a := " ".join(words.slice(0, i))
			var b := " ".join(words.slice(i))
			var worst := maxf(a.length(), b.length())
			if worst < best:
				best = worst
				lines = [a, b]
	var fs := int(minf(T.CARD_NAME[1] * size.x / 190.0, rect.size.y / (lines.size() * 1.3)))
	while fs > 9:
		var fits := true
		for line in lines:
			if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rect.size.x:
				fits = false
		if fits:
			break
		fs -= 1
	var line_h := font.get_height(fs) * 0.9
	var y := rect.position.y + (rect.size.y - line_h * lines.size()) / 2.0 + font.get_ascent(fs) * 0.9
	for line in lines:
		_ink.draw_string(font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
		y += line_h
