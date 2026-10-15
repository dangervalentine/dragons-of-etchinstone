extends Control
## One Mage Card on screen. The node lives as long as the card is visible, so it
## can move between places. It draws the face, shows the card's state on top of it
## (role, Reserve, selection, fused, unavailable) and reports taps and holds.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const CardFace = preload("res://ui/widgets/card_face.gd")

const HOLD_SECONDS := 0.35
const ROLE_ICONS := {"spell": "spell", "element": "element_role", "boost": "boost"}
const ROLE_NAMES := {"spell": "Spell", "element": "Element", "boost": "Boost"}

signal tapped(id: String)
signal held(id: String)
## The pointer has come to rest on the card, or left it (mouse only).
signal hovered(id: String, on: bool)

var id := ""
var model := {}
## Two Action Sets are in play, so ribbons say which set.
var show_set_number := false
## Where the card belongs when nothing is moving it.
var home := Rect2()

var _face := CardFace.new()
var _marks := Control.new()
var _hold := Timer.new()
var _showing_alt := false
var _pressing := false
var _held := false
var _hover := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	add_child(_face)
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.draw.connect(_draw_marks)
	add_child(_marks)
	_hold.one_shot = true
	_hold.wait_time = HOLD_SECONDS
	_hold.timeout.connect(_on_hold)
	add_child(_hold)
	resized.connect(_fit)
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))


func set_model(m: Dictionary) -> void:
	model = m
	id = m.id
	_showing_alt = false
	_face.set_model(m)
	_face.dimmed = not m.get("eligible", true)
	_face.set_focus(m.get("focus", {}))
	if _hover:
		_show_alt(true)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if m.get("eligible", true) else Control.CURSOR_ARROW
	_marks.queue_redraw()


## Whether the card's Ether field moves: off while something covers the screen.
func set_live(on: bool) -> void:
	_face.motion = on


## Put the card where it belongs, at once.
func snap_home() -> void:
	position = home.position
	size = home.size
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	pivot_offset = size / 2.0


func _fit() -> void:
	_face.position = Vector2.ZERO
	_face.size = size
	_marks.position = Vector2.ZERO
	_marks.size = size
	pivot_offset = size / 2.0
	_marks.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			held.emit(id)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressing = true
				_held = false
				_hold.start()
				UI.pulse_scale(self, 0.96)
			elif _pressing:
				_pressing = false
				_hold.stop()
				UI.pulse_scale(self, 1.0)
				if not _held and Rect2(Vector2.ZERO, size).has_point(event.position):
					hovered.emit(id, false)
					tapped.emit(id)
			accept_event()


func _on_hold() -> void:
	if _pressing:
		_held = true
		UI.pulse_scale(self, 1.0)
		held.emit(id)


func _set_hover(on: bool) -> void:
	if DisplayServer.is_touchscreen_available():
		return
	_hover = on
	_show_alt(on)
	hovered.emit(id, on)
	_marks.queue_redraw()


## While hovered in the Soak and Upgrade steps, show the card as it would become.
func _show_alt(on: bool) -> void:
	var alt = model.get("alt")
	if alt == null or on == _showing_alt:
		return
	_showing_alt = on
	if not on:
		_face.set_model(model)
		_face.dimmed = not model.get("eligible", true)
	elif alt.trashed:
		_face.dimmed = true
	else:
		var m := model.duplicate()
		m.level = alt.level
		m.stats = alt.stats
		m.downgraded = false
		_face.set_model(m, alt.changed, T.GOLD if alt.level > model.level else T.BAD)
		_face.dimmed = false
	_marks.queue_redraw()


## State drawn over the face: outline, ribbon, order badge, Ether badge, caption.
func _draw_marks() -> void:
	if model.is_empty():
		return
	var w := size.x
	var radius := int(w * 0.075)
	var state: String = model.get("state", "available")
	var outline := Color.TRANSPARENT
	if state == "assigned" or state == "selected":
		outline = T.GOLD
	elif _hover and model.get("eligible", true):
		outline = T.INK
	if outline.a > 0.0:
		var s := StyleBoxFlat.new()
		s.draw_center = false
		s.border_color = outline
		s.set_border_width_all(maxi(3, int(w * 0.022)))
		s.set_corner_radius_all(radius + 2)
		s.set_expand_margin_all(2)
		_marks.draw_style_box(s, Rect2(Vector2.ZERO, size))
	if state == "reserve":
		_dashed_outline()

	var ribbon := ""
	var ribbon_icon := ""
	var ribbon_bg := T.GOLD
	var ribbon_ink := T.BG_BASE
	if state == "assigned":
		var role: Array = model.role
		ribbon = ROLE_NAMES[role[1]] + (" %d" % (role[0] + 1) if show_set_number else "")
		ribbon_icon = ROLE_ICONS[role[1]]
	elif state == "reserve":
		ribbon = "Reserve"
		ribbon_icon = "reserve"
		ribbon_bg = T.BG_RAISED
		ribbon_ink = T.INK
	elif state == "fused_bottom":
		ribbon = "Tucked"
		ribbon_icon = "fuse"
		ribbon_bg = T.BG_RAISED
		ribbon_ink = T.INK
	elif not model.get("eligible", true) and model.get("reason", "") != "":
		ribbon = model.reason
		ribbon_bg = T.BG_BAND
		ribbon_ink = T.INK
	elif model.get("note", "") != "":
		ribbon = model.note
		ribbon_icon = model.get("note_icon", "")
		ribbon_bg = T.GOOD if model.get("match", false) else T.BG_BAND
		ribbon_ink = T.BG_BASE if model.get("match", false) else T.INK
	if ribbon != "":
		_ribbon(ribbon, ribbon_icon, ribbon_bg, ribbon_ink)

	# A tag on the top edge: what the card would become, or its fate after a battle.
	var alt = model.get("alt")
	if _showing_alt and alt != null:
		var up: bool = not alt.trashed and alt.level > model.level
		var text: String = alt.label if alt.trashed else "%s · Level %d" % [alt.label, alt.level]
		_tag(text, "trash" if alt.trashed else ("crown" if up else "down_arrow"), T.GOLD if up else T.BAD, T.BG_BASE)
	elif model.get("fate", "") == "stays":
		_tag("Stays in Hand", "reserve", T.GOLD, T.BG_BASE)
	elif model.get("fate", "") == "spent":
		_tag("Discarded after", "discard", T.BG_RAISED, T.INK_MUTED)

	if model.get("selection_order", -1) >= 0:
		var d := maxf(34.0, w * 0.2)
		var c := Vector2(w - d * 0.45, d * 0.45)
		_marks.draw_circle(c, d / 2.0 + 2, T.BG_BASE)
		_marks.draw_circle(c, d / 2.0, T.GOLD)
		_centred(Rect2(c - Vector2(d, d) / 2.0, Vector2(d, d)), str(model.selection_order + 1), d * 0.62, T.BG_BASE, "display_bold")

	var fuse = model.get("fuse")
	if fuse != null and fuse.part == "top":
		var d := maxf(40.0, w * 0.26)
		var c := Vector2(w - d * 0.4, size.y * 0.46)
		_marks.draw_circle(c, d / 2.0 + 3, T.GOLD)
		_marks.draw_circle(c, d / 2.0, T.BG_BASE)
		_marks.draw_texture_rect(UI.icon(fuse.element), Rect2(c - Vector2(d, d) * 0.3, Vector2(d, d) * 0.6), false, T.ether_ink(fuse.element))


func _ribbon(text: String, icon_name: String, bg: Color, ink: Color) -> void:
	# A tag in the lower right of the field, where the sigil is, so no figure is hidden.
	var font := UI.font("body_bold")
	var max_w := size.x * 0.6
	var fs := int(clampf(size.x * 0.12, 16.0, T.LABEL[1]))
	var h := fs * 1.45
	var icon_w := (h * 0.68 + 3) if icon_name != "" else 0.0
	while fs > 15 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + icon_w + 14 > max_w:
		fs -= 1
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if tw + icon_w + 14 > max_w and icon_name != "":
		text = ""
		tw = 0.0
	var w := minf(max_w, tw + icon_w + 14)
	var pad := size.x * 0.045
	var rect := Rect2(size.x - pad - w, size.y - pad - h, w, h)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(h / 2.0))
	s.border_color = Color(0, 0, 0, 0.5)
	s.set_border_width_all(1)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 4
	_marks.draw_style_box(s, rect)
	var x := rect.position.x + (rect.size.x - tw - icon_w) / 2.0
	if icon_name != "":
		_marks.draw_texture_rect(UI.icon(icon_name), Rect2(x, rect.position.y + h * 0.16, h * 0.68, h * 0.68), false, ink)
		x += icon_w
	if text != "":
		var base := rect.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
		_marks.draw_string(font, Vector2(x, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)


func _tag(text: String, icon_name: String, bg: Color, ink: Color) -> void:
	var font := UI.font("body_bold")
	var fs := int(clampf(size.x * 0.105, 15.0, 20.0))
	var h := fs * 1.5
	var icon_w := h * 0.66 + 3
	while fs > 13 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + icon_w + 16 > size.x + 8:
		fs -= 1
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w := tw + icon_w + 16
	var rect := Rect2((size.x - w) / 2.0, -h * 0.78, w, h)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(h / 2.0))
	s.border_color = Color(0, 0, 0, 0.55)
	s.set_border_width_all(1)
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 3
	_marks.draw_style_box(s, rect)
	var x := rect.position.x + 8
	_marks.draw_texture_rect(UI.icon(icon_name), Rect2(x, rect.position.y + h * 0.17, h * 0.66, h * 0.66), false, ink)
	var base := rect.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	_marks.draw_string(font, Vector2(x + icon_w, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)


func _centred(rect: Rect2, text: String, font_size: float, color: Color, font_name: String) -> void:
	var font := UI.font(font_name)
	var fs := int(font_size)
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var base := rect.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	_marks.draw_string(font, Vector2(rect.get_center().x - sz.x / 2.0, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


func _dashed_outline() -> void:
	var r := Rect2(Vector2(-2, -2), size + Vector2(4, 4))
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		_marks.draw_dashed_line(corners[i], corners[(i + 1) % 4], T.INK_MUTED, 3.0, 10.0)
