extends Control
## The strip across the top of the play screen: where you are, how much of the deck
## is left, the three piles with their counts, and the menu button. It is a shallow
## lintel of carved stone with the heading cut into it, and it stays quiet, so the
## Encounter and the cards below it come first.

const T = preload("res://ui/theme/tokens.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const HelpButton = preload("res://ui/widgets/help_button.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal intent(data: Dictionary)

const PILES := ["deck", "discard", "trash"]
const PILE_NAMES := {"deck": "Deck", "discard": "Discard", "trash": "Trash"}

var menu_button := Button.new()
var _row := HBoxContainer.new()
var _heading := Label.new()
var _progress := Control.new()
var _counts := {}
var _icons := {}
var _shown := {"deck": 0, "discard": 0, "trash": 0}
var _fraction := 1.0
var _lintel := StoneStyle.new("lintel", 0.15)


func _init() -> void:
	_row.add_theme_constant_override("separation", T.M)
	add_child(_row)
	UI.style_label(_heading, T.HEADING, T.INK)
	# Cut into the stone: a dark edge round the letters, a light one below.
	_heading.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.10))
	_heading.add_theme_constant_override("shadow_offset_x", 0)
	_heading.add_theme_constant_override("shadow_offset_y", 1)
	_heading.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_heading.add_theme_constant_override("outline_size", 2)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heading.clip_text = true
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_heading)
	_progress.custom_minimum_size = Vector2(150, 10)
	_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress.draw.connect(_draw_progress)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_progress)
	for pile in PILES:
		var b := HelpButton.new()
		b.flat = true
		b.custom_minimum_size = Vector2(80, 48)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		HelpTip.mark(b, pile)
		for state in ["normal", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", UI.box(Color(1, 1, 1, 0.07), Color.TRANSPARENT, 0, T.RADIUS_S, 0))
		var box := UI.hbox(5)
		box.name = pile
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var icon := UI.icon_rect(pile, 26, Color(T.INK_MUTED, 0.8))
		box.add_child(icon)
		var count := UI.label("0", ["display_bold", 24], T.INK_MUTED)
		count.custom_minimum_size.x = 34
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(count)
		UI.ignore_mouse(box)
		b.add_child(box)
		b.pressed.connect(func(): intent.emit({"type": "help", "id": pile, "source": b}))
		_row.add_child(b)
		_counts[pile] = count
		_icons[pile] = icon
	# The header is shorter than a thumb, so the menu button reaches below it.
	menu_button.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	menu_button.flat = true
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		menu_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var icon := UI.icon_rect("menu", 34, T.INK)
	icon.position = Vector2(27, 7)
	icon.size = Vector2(34, 34)
	menu_button.add_child(icon)
	menu_button.mouse_entered.connect(func(): icon.modulate = T.GOLD)
	menu_button.mouse_exited.connect(func(): icon.modulate = T.INK)
	menu_button.pressed.connect(func(): intent.emit({"type": "menu"}))
	UI.press_feedback(menu_button)
	add_child(menu_button)
	resized.connect(_fit)
	_lintel.changed.connect(queue_redraw)


func _draw() -> void:
	draw_style_box(_lintel, Rect2(Vector2(-T.S, -4), size + Vector2(2 * T.S, 8)))


func render(vs: Dictionary) -> void:
	_heading.text = vs.stage.heading
	var total: int = maxi(1, vs.progress.total)
	_fraction = clampf(vs.progress.deck / float(total), 0.0, 1.0)
	_progress.queue_redraw()
	set_counts(vs.piles)


func set_counts(piles: Dictionary) -> void:
	for pile in PILES:
		_shown[pile] = piles[pile]
		_counts[pile].text = str(piles[pile])


## Change one pile's count as a card arrives or leaves, with a flash.
func bump(pile: String, delta: int) -> void:
	_shown[pile] = maxi(0, _shown[pile] + delta)
	_counts[pile].text = str(_shown[pile])
	UI.flash(_icons[pile], T.GOLD)


## Global centre of a pile's icon, for cards flying to or from it.
func pile_point(pile: String) -> Vector2:
	var icon: Control = _icons[pile]
	return icon.global_position + icon.size / 2.0


func _fit() -> void:
	menu_button.position = Vector2.ZERO
	menu_button.size = Vector2(T.TAP_MIN, T.TAP_MIN)
	_row.position = Vector2(T.TAP_MIN, 0)
	_row.size = Vector2(size.x - T.TAP_MIN - T.S, size.y)


func _draw_progress() -> void:
	var r := Rect2(Vector2.ZERO, _progress.size)
	_progress.draw_style_box(UI.box(Color(T.LINE_SOFT, 0.5), Color.TRANSPARENT, 0, 7, 0), r)
	if _fraction > 0.0:
		_progress.draw_style_box(UI.box(T.INK_MUTED, Color.TRANSPARENT, 0, 7, 0),
			Rect2(r.position, Vector2(maxf(14.0, r.size.x * _fraction), r.size.y)))
