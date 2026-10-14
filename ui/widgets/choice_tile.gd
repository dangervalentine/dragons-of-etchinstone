extends Button
## A selectable option on the title screen: a title, an optional emblem and a line
## or two saying what the choice changes.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

var selected := false: set = set_selected
var accent: Color = T.GOLD
var _title: Label
var _desc: Label
var _row: Control
## The height asked for before any text was measured.
var base_height := -1.0


static func make(title: String, desc: String, emblem := "", colour: Color = T.GOLD, emblem_colour = null) -> Button:
	var b = load("res://ui/widgets/choice_tile.gd").new()
	b.accent = colour
	b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	var row := UI.hbox(10)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	if emblem != "":
		row.add_child(UI.icon_rect(emblem, 56, emblem_colour if emblem_colour != null else colour))
	var col := UI.vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b._title = UI.label(title, ["display", 25], T.INK)
	col.add_child(b._title)
	if desc != "":
		b._desc = UI.label(desc, T.LABEL, T.INK_MUTED, true)
		col.add_child(b._desc)
	row.add_child(col)
	UI.ignore_mouse(row)
	b.add_child(row)
	# A Button does not grow with its contents; once it has a width, make room for
	# however many lines the description wraps to.
	b._row = row
	b.resized.connect(b._fit_text, CONNECT_DEFERRED)
	b.selected = false
	UI.press_feedback(b)
	return b


func set_selected(on: bool) -> void:
	selected = on
	var bg: Color = T.BG_RAISED if on else T.BG_SURFACE
	var border: Color = accent if on else T.LINE_SOFT
	var w := 3 if on else 1
	add_theme_stylebox_override("normal", UI.box(bg, border, w))
	add_theme_stylebox_override("hover", UI.box(bg.lightened(0.06), accent, w + (0 if on else 1)))
	add_theme_stylebox_override("pressed", UI.box(bg.darkened(0.1), accent, 3))
	var focus := UI.box(Color.TRANSPARENT, T.GOLD, 3)
	focus.set_expand_margin_all(4)
	add_theme_stylebox_override("focus", focus)
	if _title != null:
		_title.add_theme_color_override("font_color", T.INK if on else Color(T.INK, 0.85))


func _fit_text() -> void:
	if _row == null or size.x < 60:
		return
	if base_height < 0:
		base_height = custom_minimum_size.y
	var need := maxf(base_height, _row.get_combined_minimum_size().y + 20)
	if absf(need - custom_minimum_size.y) > 1.0:
		custom_minimum_size.y = need
