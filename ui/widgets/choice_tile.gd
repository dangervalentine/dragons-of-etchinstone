extends Button
## A selectable option on the title screen: a title, an optional emblem and a line
## or two saying what the choice changes, with optional further content underneath.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

var selected := false: set = set_selected
var accent: Color = T.BRASS
var _title: Label
var _desc: Label
var _row: Control
## The height asked for before any text was measured.
var base_height := -1.0


## `emblem` is an icon's name or a texture. `extra`, if given, sits under the
## emblem and text across the whole tile.
static func make(title: String, desc: String, emblem: Variant = "", colour: Color = T.PARCHMENT, emblem_colour = null, emblem_side := 56.0, extra: Control = null) -> Button:
	var b = load("res://ui/widgets/choice_tile.gd").new()
	b.accent = colour
	b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	var row := UI.hbox(10)
	var tint: Color = emblem_colour if emblem_colour != null else colour
	if emblem is Texture2D:
		row.add_child(UI.texture_rect(emblem, emblem_side, tint))
	elif emblem is String and emblem != "":
		row.add_child(UI.icon_rect(emblem, emblem_side, tint))
	var col := UI.vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b._title = UI.label(title, T.BUTTON, T.PARCHMENT)
	col.add_child(b._title)
	if desc != "":
		b._desc = UI.label(desc, T.BODY_SM, T.PARCHMENT_MUTED, true)
		col.add_child(b._desc)
	row.add_child(col)
	var content: Control = row
	if extra != null:
		content = UI.vbox(T.SPACE_2)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_child(row)
		content.add_child(extra)
	# In from the sides past the chamfer's cut (specs/019), and from top and foot.
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	content.offset_left = T.SPACE_3
	content.offset_right = -T.SPACE_3
	UI.ignore_mouse(content)
	b.add_child(content)
	# A Button does not grow with its contents; once it has a width, make room for
	# however many lines the description wraps to.
	b._row = content
	b.resized.connect(b._fit_text, CONNECT_DEFERRED)
	b.selected = false
	UI.press_feedback(b)
	return b


func set_selected(on: bool) -> void:
	selected = on
	# A raised plinth of stone; the chosen one is rimmed in brass (specs/019
	# "Selected"), the focused one in jade. The accent no longer edges it: brass is
	# the only sign of the choice.
	var normal := StoneStyle.new("plinth")
	normal.selected = on
	var hover := StoneStyle.new("plinth")
	hover.selected = on
	hover.face = T.STONE_RAISED.lerp(T.PARCHMENT, 0.04)
	var down := StoneStyle.new("plinth")
	down.pressed = true
	down.selected = on
	for st in [normal, hover, down]:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			st.set_content_margin(side, T.SPACE_1)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", down)
	add_theme_stylebox_override("hover_pressed", down)
	add_theme_stylebox_override("focus", UI.focus_ring())
	if _title != null:
		_title.add_theme_color_override("font_color", T.PARCHMENT if on else T.PARCHMENT_MUTED)


func _fit_text() -> void:
	if _row == null or size.x < 60:
		return
	if base_height < 0:
		base_height = custom_minimum_size.y
	var need := maxf(base_height, _row.get_combined_minimum_size().y + 20)
	if absf(need - custom_minimum_size.y) > 1.0:
		custom_minimum_size.y = need
