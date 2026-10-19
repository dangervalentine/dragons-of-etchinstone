extends Control
## The strip across the top of every screen, with the menu button always at its right.
## On the play screen it also shows where you are and the three piles with their
## counts; elsewhere the screen's name, centred
## (set_title), and, on a screen that can go back, Back at its left.
## It is a shallow lintel of carved stone with the heading cut into it, and it stays
## quiet, so what is below it comes first.

const T = preload("res://ui/theme/tokens.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const HelpButton = preload("res://ui/widgets/help_button.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal intent(data: Dictionary)

const PILES := ["deck", "discard", "trash"]
const PILE_NAMES := {"deck": "Deck", "discard": "Discard", "trash": "Trash"}
## The width of Back's tap target.
const BACK_W := 150

var menu_button := Button.new()
var back_button := Button.new()
var _row := HBoxContainer.new()
var _heading := Label.new()
var _counts := {}
var _icons := {}
var _piles := []
var _shown := {"deck": 0, "discard": 0, "trash": 0}
var _lintel := StoneStyle.new("lintel", 0.15)
## Whether the bar shows only a screen's name (set_title), centred.
var _titled := false


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
		var count := UI.label("0", T.NUMERAL_S, T.INK_MUTED)
		count.custom_minimum_size.x = 34
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(count)
		UI.ignore_mouse(box)
		b.add_child(box)
		b.pressed.connect(func(): intent.emit({"type": "help", "id": pile, "source": b}))
		_row.add_child(b)
		_piles.append(b)
		_counts[pile] = count
		_icons[pile] = icon
	# The header is shorter than a thumb, so the menu button reaches below it.
	menu_button.name = "MenuButton"
	menu_button.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	menu_button.flat = true
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		menu_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var icon := UI.icon_rect("menu", 34, T.INK)
	# Its icon sits at the button's right end, level with the body's right edge.
	icon.position = Vector2(T.TAP_MIN - 34, 7)
	icon.size = Vector2(34, 34)
	menu_button.add_child(icon)
	menu_button.mouse_entered.connect(func(): icon.modulate = T.GOLD)
	menu_button.mouse_exited.connect(func(): icon.modulate = T.INK)
	menu_button.pressed.connect(func(): intent.emit({"type": "menu"}))
	UI.press_feedback(menu_button)
	add_child(menu_button)
	# Back mirrors the menu button: a full tap target reaching below the header, its
	# word in the header's left end.
	back_button.name = "BackButton"
	back_button.tooltip_text = "Back"
	back_button.custom_minimum_size = Vector2(BACK_W, T.TAP_MIN)
	back_button.flat = true
	back_button.visible = false
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		back_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var word := UI.label("‹ Back", T.BUTTON, T.INK)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word.position = Vector2.ZERO
	word.size = Vector2(BACK_W, 48)
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_button.add_child(word)
	back_button.mouse_entered.connect(func(): word.add_theme_color_override("font_color", T.GOLD))
	back_button.mouse_exited.connect(func(): word.add_theme_color_override("font_color", T.INK))
	back_button.pressed.connect(func(): intent.emit({"type": "back"}))
	UI.press_feedback(back_button)
	add_child(back_button)
	resized.connect(_fit)
	# The band follows the screen's edges, so it is redrawn when the bar moves.
	item_rect_changed.connect(queue_redraw)
	_lintel.changed.connect(queue_redraw)


func _draw() -> void:
	# A flat band across the whole screen, from its very top to just under the bar.
	# The stone runs past the left, right and top edges by more than its chamfer, so
	# only its straight bottom edge shows.
	var view := get_global_transform().affine_inverse() * get_viewport_rect()
	var over := T.CHAMFER_L + 8.0
	var top := view.position.y - over
	var band := Rect2(view.position.x - over, top, view.size.x + 2.0 * over, size.y + 4.0 - top)
	draw_style_box(_lintel, band)


## Show only a heading and the menu button, as on every screen but the play screen,
## and Back when the screen can go back.
func set_title(text: String, can_go_back := false) -> void:
	_titled = true
	_heading.text = text
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_button.visible = can_go_back
	for b in _piles:
		b.visible = false
	_fit()


func render(vs: Dictionary) -> void:
	_heading.text = vs.stage.heading
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
	return pile_rect(pile).get_center()


## Global rect of a pile's icon.
func pile_rect(pile: String) -> Rect2:
	var icon: Control = _icons[pile]
	return Rect2(icon.global_position, icon.size)


func _fit() -> void:
	menu_button.size = Vector2(T.TAP_MIN, T.TAP_MIN)
	menu_button.position = Vector2(size.x - T.TAP_MIN, 0)
	back_button.size = Vector2(BACK_W, T.TAP_MIN)
	back_button.position = Vector2.ZERO
	# A name alone is centred on the bar, clear of Back and the menu button alike;
	# on the play screen the row runs from the left edge, level with the body below,
	# to the menu button.
	var left: float = maxf(BACK_W, T.TAP_MIN) if _titled else 0.0
	var right: float = maxf(BACK_W, T.TAP_MIN) if _titled else float(T.TAP_MIN)
	_row.position = Vector2(left, 0)
	_row.size = Vector2(maxf(0.0, size.x - left - right), size.y)

