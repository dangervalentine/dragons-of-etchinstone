extends BoxContainer
## A row of tabs: a filter or a one-of-many choice (specs/019 contracts/components.md
## "Tabs"). Each tab is a stone plinth a tap target high, as wide as its label plus a
## gutter each side; the one selected is rimmed in brass with its label in parchment,
## the rest muted. Exactly one is selected. Left and right move between them from the
## keyboard (up and down in a vertical rail); Enter chooses.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal chosen(id)

var selected = null
var _tabs := {}


func _init() -> void:
	add_theme_constant_override("separation", T.SPACE_1)


## `options` is [{id, text, icon?}]; `selected_id` the one chosen.
func setup(options: Array, selected_id) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tabs = {}
	for o in options:
		var b := Button.new()
		b.text = o.text
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
		b.add_theme_font_override("font", UI.font(T.BUTTON, T.BODY.size))
		b.add_theme_font_size_override("font_size", T.BODY.size)
		if o.get("icon", "") != "":
			b.icon = UI.icon(o.icon)
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 30)
		b.set_meta("tab", o.id)
		if vertical:
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var id = o.id
		b.pressed.connect(func(): choose(id))
		b.gui_input.connect(_on_key.bind(b))
		add_child(b)
		_tabs[str(id)] = b
	select(selected_id)


## Show `id` as the one selected, without emitting.
func select(id) -> void:
	selected = id
	for key in _tabs:
		_style(_tabs[key], key == str(id))


func choose(id) -> void:
	select(id)
	chosen.emit(id)


func tab(id) -> Button:
	return _tabs.get(str(id))


func _style(b: Button, on: bool) -> void:
	var make := func(hover := false, down := false) -> StoneStyle:
		var st := StoneStyle.new("plinth")
		st.size = "sm"
		st.selected = on
		st.pressed = down
		if on:
			st.face = T.STONE
		elif hover:
			st.face = T.STONE_RAISED.lerp(T.PARCHMENT, 0.04)
		st.content_margin_left = T.SPACE_4
		st.content_margin_right = T.SPACE_4
		return st
	b.add_theme_stylebox_override("normal", make.call())
	b.add_theme_stylebox_override("hover", make.call(true))
	b.add_theme_stylebox_override("pressed", make.call(false, true))
	b.add_theme_stylebox_override("hover_pressed", make.call(true, true))
	b.add_theme_stylebox_override("focus", UI.focus_ring("sm"))
	var ink := T.PARCHMENT if on else T.PARCHMENT_MUTED
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, ink)
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(c, ink)
	b.set_meta("selected", on)


func _on_key(event: InputEvent, b: Button) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var keys := _tabs.keys()
	var at := keys.find(str(b.get_meta("tab")))
	match event.keycode:
		KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
			var forward: bool = event.keycode == KEY_RIGHT or event.keycode == KEY_DOWN
			var next: int = clampi(at + (1 if forward else -1), 0, keys.size() - 1)
			_tabs[keys[next]].grab_focus()
			b.accept_event()
		KEY_ENTER, KEY_KP_ENTER:
			choose(b.get_meta("tab"))
			b.accept_event()
