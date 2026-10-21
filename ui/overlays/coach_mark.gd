extends Control
## The lesson's coach mark (specs/017, contracts/coach-mark.md): the screen dimmed
## round the one thing a step is about, a rim round that thing, and the step's
## message in a bubble beside it. It sits under the overlays (main.gd), so the
## Glossary, How to Play or the menu open over it and it waits beneath; it is not an
## Overlay, so it never stops the play clock and Escape never closes it.
##
## While a message is read, nothing under the dimming can be pressed. While the
## player acts, there is no dimming at all, so nothing looks shut that must be
## pressed: the rim goes round the target and round the button that carries the move
## on (`press`), the bubble keeps clear of both and has no button of its own, and the
## lesson's gate (ui/model/tutorial.gd) holds back a wrong commit instead.
##
## The lit thing is followed every frame (`target`), so a card gliding home, a note
## dealt onto the Deck or a resized window carries the rim and the bubble with it.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal next
signal back
signal skip
## A term in the message was pressed: its Glossary id and where it was pressed.
signal term(id: String, anchor: Rect2)
## A button of a choice (lesson complete, the summary) was pressed.
signal chosen(id: String)

## The narrowest the bubble is set beside its target before it goes above or below
## it instead.
const MIN_W := 360.0

var bubble := PanelContainer.new()
## The lit rect, global, before the rim's padding: empty when nothing is lit.
var lit := Rect2()
## Returns the lit rect now; called every frame while shown.
var target: Callable
## On an action step, the global rects of the buttons that carry the move on (Play,
## Confirm, Continue): rimmed too, and kept clear of the bubble.
var pressed := []
## Returns `pressed` now; called every frame while shown.
var press: Callable
var _dims: Array = []
var _text := RichTextLabel.new()
var _buttons := HBoxContainer.new()
var _content := Rect2()
var _reading := true
## The fade in and the bubble's glide, apart, so a glide begun while the mark is
## still fading in never leaves it see-through (and its dimming catching presses).
var _fade: Tween
var _glide: Tween
## Where the bubble is going, global: its place once any glide has finished.
var _to := Vector2.ZERO
var _width := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	for i in 4:
		var d := ColorRect.new()
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(d)
		_dims.append(d)
	bubble.add_theme_stylebox_override("panel", UI.tooltip_box())
	bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := UI.vbox(T.M)
	bubble.add_child(col)
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_override("normal_font", UI.font(T.BODY[0]))
	_text.add_theme_font_override("bold_font", UI.font("body_bold"))
	_text.add_theme_font_size_override("normal_font_size", T.BODY[1])
	_text.add_theme_font_size_override("bold_font_size", T.BODY[1])
	_text.add_theme_color_override("default_color", T.INK)
	_text.meta_clicked.connect(_on_meta)
	col.add_child(_text)
	_buttons.alignment = BoxContainer.ALIGNMENT_END
	_buttons.add_theme_constant_override("separation", T.S)
	col.add_child(_buttons)
	add_child(bubble)


## A step: `text` (BBCode) beside what `at` returns (a global rect, or an empty one
## to light nothing). Read, it offers Skip, Back when `can_back`, and Next; acted on,
## no button at all (owner review), since the way on is the game's own button,
## which `on` returns (an Array of global rects) to be rimmed as well.
func show_step(text: String, at: Callable, reading: bool, can_back: bool, content: Rect2, on := Callable()) -> void:
	var buttons := []
	if reading:
		buttons.append({"id": "skip", "label": "Skip", "kind": "quiet"})
	if reading and can_back:
		buttons.append({"id": "back", "label": "Back", "kind": "normal"})
	if reading:
		buttons.append({"id": "next", "label": "Next", "kind": "primary"})
	press = on if not reading else Callable()
	pressed = press.call() if press.is_valid() else []
	_show(text, at, reading, buttons, content)


## A choice over the dimmed screen: lesson complete, the summary. Each button is
## {id, label, kind}; pressing one emits `chosen`.
func show_choice(text: String, buttons: Array, content: Rect2) -> void:
	press = Callable()
	pressed = []
	_show(text, func(): return Rect2(), true, buttons, content)


func hide_mark() -> void:
	visible = false
	lit = Rect2()
	target = Callable()
	press = Callable()
	pressed = []
	_set_dims_filter(Control.MOUSE_FILTER_IGNORE)


## The window changed: the same message in its new room.
func set_content(content: Rect2) -> void:
	_content = content
	if visible:
		_place(false)


## At rest at once: any fade or glide finished (tools, and reduced motion).
func settle() -> void:
	for tw in [_fade, _glide]:
		if tw != null and tw.is_valid():
			tw.kill()
	modulate.a = 1.0
	if visible:
		_follow()
		_place(false)


func _process(_delta: float) -> void:
	if visible:
		_follow()


## The target moved: the rim and bubble go with it.
func _follow() -> void:
	if not target.is_valid():
		return
	var now: Rect2 = target.call()
	var on: Array = press.call() if press.is_valid() else []
	if not now.is_equal_approx(lit) or on != pressed:
		lit = now
		pressed = on
		_place(false)


func _show(text: String, at: Callable, reading: bool, buttons: Array, content: Rect2) -> void:
	var was_shown := visible
	target = at
	lit = at.call() if at.is_valid() else Rect2()
	_content = content
	_reading = reading
	_text.text = text
	for b in _buttons.get_children():
		_buttons.remove_child(b)
		b.queue_free()
	for spec in buttons:
		var b := UI.button(spec.label, spec.get("kind", "normal"))
		# A word or two each: kept whole on one line.
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		var id: String = spec.id
		b.pressed.connect(func(): _press(id))
		_buttons.add_child(b)
	_buttons.visible = not buttons.is_empty()
	visible = true
	for d in _dims:
		d.color = Color(T.BG_BASE, T.COACH_DIM)
		d.visible = reading
	_set_dims_filter(Control.MOUSE_FILTER_STOP if reading else Control.MOUSE_FILTER_IGNORE)
	var glide := was_shown and not UI.reduced_motion and is_inside_tree()
	_place(glide)
	if not was_shown and not UI.reduced_motion and is_inside_tree():
		modulate.a = 0.0
		if _fade != null and _fade.is_valid():
			_fade.kill()
		_fade = create_tween()
		_fade.tween_property(self, "modulate:a", 1.0, T.COACH_FADE)
	elif not was_shown:
		modulate.a = 1.0


func _press(id: String) -> void:
	match id:
		"next":
			next.emit()
		"back":
			back.emit()
		"skip":
			skip.emit()
		_:
			chosen.emit(id)


func _on_meta(meta) -> void:
	term.emit(str(meta), Rect2(get_global_mouse_position(), Vector2.ZERO))


func _set_dims_filter(f: int) -> void:
	for d in _dims:
		d.mouse_filter = f


## The bubble's size when `width` wide.
func _measure(width: float) -> Vector2:
	if not is_equal_approx(width, _width):
		_width = width
		var pad: float = UI.tooltip_box().get_margin(SIDE_LEFT) + UI.tooltip_box().get_margin(SIDE_RIGHT)
		_text.custom_minimum_size.x = width - pad
		_text.size.x = width - pad
		bubble.custom_minimum_size.x = width
	# Measured at this width, not at whatever width it was last laid out at.
	_text.custom_minimum_size.y = 0
	_text.size.y = 0
	_text.custom_minimum_size.y = _text.get_content_height()
	bubble.size = Vector2.ZERO
	bubble.reset_size()
	return bubble.get_combined_minimum_size()


## The dimming round the lit rect, the rim, and the bubble where it fits.
func _place(animate: bool) -> void:
	var view := get_viewport_rect().size if is_inside_tree() else _content.end
	var hole := lit.grow(T.COACH_PAD) if lit.has_area() else Rect2()
	var bands: Array
	if not hole.has_area():
		bands = [Rect2(Vector2.ZERO, view), Rect2(), Rect2(), Rect2()]
	else:
		bands = [Rect2(0, 0, view.x, hole.position.y),
			Rect2(0, hole.end.y, view.x, view.y - hole.end.y),
			Rect2(0, hole.position.y, hole.position.x, hole.size.y),
			Rect2(hole.end.x, hole.position.y, view.x - hole.end.x, hole.size.y)]
	for i in 4:
		var r: Rect2 = bands[i]
		_dims[i].position = r.position - global_position
		_dims[i].size = Vector2(maxf(r.size.x, 0.0), maxf(r.size.y, 0.0))
	var room: Rect2 = _content if _content.has_area() else Rect2(Vector2.ZERO, view)
	var spot := _spot(hole, room)
	_measure(spot.width)
	bubble.size = Vector2(spot.width, bubble.get_combined_minimum_size().y)
	_to = spot.at
	if _glide != null and _glide.is_valid():
		_glide.kill()
	if animate:
		_glide = create_tween()
		_glide.tween_property(bubble, "position", _to - global_position, T.MOVE) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		bubble.position = _to - global_position
	queue_redraw()


## Where the bubble goes, and how wide: beside the hole on the side with the most room
## that holds it, as wide as that side allows up to COACH_MAX_W (never under MIN_W);
## else above or below it; else centred in the room. {at, width}.
func _spot(hole: Rect2, room: Rect2) -> Dictionary:
	var full := minf(T.COACH_MAX_W, room.size.x)
	if not hole.has_area():
		var s := _measure(full)
		return {"at": _clamped(room.get_center() - s / 2.0, s, room), "width": full}
	var g := T.COACH_GAP
	var sides := [
		{"room": room.end.x - hole.end.x - g, "axis": "x", "side": "right"},
		{"room": hole.position.x - room.position.x - g, "axis": "x", "side": "left"},
		{"room": room.end.y - hole.end.y - g, "axis": "y", "side": "below"},
		{"room": hole.position.y - room.position.y - g, "axis": "y", "side": "above"},
	]
	sides.sort_custom(func(a, b): return a.room > b.room)
	for side in sides:
		var w := full
		if side.axis == "x":
			w = minf(full, side.room)
			if w < MIN_W:
				continue
		var s := _measure(w)
		if side.axis == "y" and s.y > side.room:
			continue
		if side.axis == "x" and s.y > room.size.y:
			continue
		var at: Vector2
		match side.side:
			"right":
				at = Vector2(hole.end.x + g, hole.get_center().y - s.y / 2.0)
			"left":
				at = Vector2(hole.position.x - g - s.x, hole.get_center().y - s.y / 2.0)
			"below":
				at = Vector2(hole.get_center().x - s.x / 2.0, hole.end.y + g)
			"above":
				at = Vector2(hole.get_center().x - s.x / 2.0, hole.position.y - g - s.y)
		at = _clamped(at, s, room)
		if not Rect2(at, s).intersects(hole) and not _covers_press(Rect2(at, s)):
			return {"at": at, "width": w}
	var s := _measure(full)
	return {"at": _clamped(room.get_center() - s / 2.0, s, room), "width": full}


func _covers_press(r: Rect2) -> bool:
	for p in pressed:
		if r.intersects((p as Rect2).grow(T.COACH_PAD)):
			return true
	return false


static func _clamped(p: Vector2, s: Vector2, room: Rect2) -> Vector2:
	return Vector2(clampf(p.x, room.position.x, maxf(room.position.x, room.end.x - s.x)),
		clampf(p.y, room.position.y, maxf(room.position.y, room.end.y - s.y)))


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = T.FOCUS
	box.set_border_width_all(int(T.COACH_RIM))
	box.set_corner_radius_all(T.RADIUS_S)
	for rect in [lit] + pressed:
		if (rect as Rect2).has_area():
			var r: Rect2 = (rect as Rect2).grow(T.COACH_PAD)
			draw_style_box(box, Rect2(r.position - global_position, r.size))
