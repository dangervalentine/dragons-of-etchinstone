extends Control
## Base for everything shown above a screen: dims what is behind, closes on Escape
## or a press outside its panel, and never changes the game.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal closed

## A page overlay's heading: as tall as a title over a line of text. The X stands
## in the panel's corner beside it, outside its layout, so the heading need not be
## a whole tap target tall.
const HEAD_H := 70
## How far the X stands in from the panel's top right corner.
const CLOSE_INSET := 8
## The width a heading leaves clear at its right end for the X, inside a panel
## whose content margin is `margin`.
static func close_clearance(margin: int) -> float:
	return T.TAP_MIN + CLOSE_INSET * 2 - margin

## Close when the dimmed area outside the panel is pressed.
var close_outside := true
var _dim := ColorRect.new()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.color = Color(T.BG_BASE, 0.78)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)


func set_dim(alpha: float) -> void:
	_dim.color.a = alpha


func appear() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, T.FAST)


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


## The X every overlay closes by, at the right end of its heading: a full tap
## target, drawn as just the cross.
func make_close_button() -> Button:
	var b := Button.new()
	b.name = "Close"
	b.tooltip_text = "Close"
	b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	b.flat = true
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var focus := UI.box(Color.TRANSPARENT, T.muted(T.GOLD), 3)
	focus.set_expand_margin_all(-12)
	b.add_theme_stylebox_override("focus", focus)
	var icon := UI.icon_rect("close", 36, T.INK)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -18
	icon.offset_top = -18
	icon.offset_right = 18
	icon.offset_bottom = 18
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	b.mouse_entered.connect(func(): icon.modulate = T.GOLD)
	b.mouse_exited.connect(func(): icon.modulate = T.INK)
	b.pressed.connect(close)
	UI.press_feedback(b)
	return b


## The X set in the top right corner of `rect`, a panel's rectangle in this overlay.
func place_close_button(rect: Rect2) -> Button:
	var b := make_close_button()
	b.position = Vector2(rect.end.x - CLOSE_INSET - T.TAP_MIN, rect.position.y + CLOSE_INSET)
	b.size = Vector2(T.TAP_MIN, T.TAP_MIN)
	add_child(b)
	return b


## The woodcut divider of the difficulty page set across the middle of `rect`'s
## top and bottom edges, drawn flat, over everything added before it. Returns the
## two so the caller can take them away when it builds again.
func add_edge_caps(rect: Rect2) -> Array:
	var caps := []
	var w := minf(rect.size.x * 0.4, 360.0)
	var h := w * 16.0 / 192.0
	for y in [rect.position.y, rect.end.y]:
		var cap := UI.icon_rect("orn_divider", 10, T.muted(T.GOLD))
		cap.custom_minimum_size = Vector2.ZERO
		cap.size = Vector2(w, h)
		cap.position = Vector2(rect.get_center().x - w / 2.0, y - h / 2.0)
		add_child(cap)
		caps.append(cap)
	return caps


func _gui_input(event: InputEvent) -> void:
	if close_outside and event is InputEventMouseButton and event.pressed:
		close()
		accept_event()
