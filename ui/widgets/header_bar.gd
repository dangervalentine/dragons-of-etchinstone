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
## How far the slabs and chips in the bar stand in from its top and foot.
const BAR_INSET := 6.0
## How far Back, the heading and the menu button stand in from the band's ends.
const PAD_X := T.SPACE_4
## The space between the piles' chips and the menu button, so the button stands apart.
const MENU_GAP := T.SPACE_4

var menu_button := Button.new()
var back_button := Button.new()
var _row := HBoxContainer.new()
var _heading := Label.new()
## The muted rest of the play screen's heading: " · Region 1" after the place's name.
var _heading_more := Label.new()
var _counts := {}
var _icons := {}
var _piles := []
## The room each pile's chip takes in the row.
var _slots := []
## The visible stone slabs of the menu and Back buttons, inside the bar.
var _menu_face := PanelContainer.new()
var _back_face := PanelContainer.new()
var _shown := {"deck": 0, "discard": 0, "trash": 0}
## Whether the bar shows only a screen's name (set_title), centred.
var _titled := false


func _init() -> void:
	_row.add_theme_constant_override("separation", T.SPACE_4)
	add_child(_row)
	# The heading in the title style, title case: the place in parchment, the number
	# after it muted (specs/019 TopBar).
	UI.style_label(_heading, T.TITLE, T.PARCHMENT)
	UI.style_label(_heading_more, T.TITLE, T.PARCHMENT_MUTED)
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for l in [_heading, _heading_more]:
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.clip_text = true
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading_row := UI.hbox(0)
	heading_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The place's name at its own width; only the muted rest gives way when short.
	_heading.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_heading.clip_text = false
	_heading_more.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(_heading)
	heading_row.add_child(_heading_more)
	_row.add_child(heading_row)
	# Each pile's count is a chip in the bar (specs/019 TopBar), pressed through a tap
	# target a full one wide and as tall as the bar: reaching below it, as the menu
	# button does in its corner, would cover the Action Set's headers under the piles
	# (a departure from analysis I6, recorded in the plan). A place in the row holds the
	# chip's room, and the button is laid over it in _fit.
	for pile in PILES:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(T.TAP_MIN, 0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_row.add_child(slot)
		_slots.append(slot)
		var b := HelpButton.new()
		b.flat = true
		b.custom_minimum_size = Vector2(T.TAP_MIN, 0)
		HelpTip.mark(b, pile)
		for state in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		b.add_theme_stylebox_override("focus", UI.focus_ring("sm"))
		var chip := UI.chip(pile, "0")
		chip.name = pile
		chip.custom_minimum_size = Vector2(T.TAP_MIN, 0)
		b.add_child(chip)
		var count: Label = chip.get_meta("figure")
		var icon: Control = chip.get_child(0).get_child(0)
		# The Discard opens on the cards in it; the other piles explain themselves.
		var kind := "pile" if pile == "discard" else "help"
		b.pressed.connect(func(): intent.emit({"type": kind, "id": pile, "source": b}))
		add_child(b)
		_piles.append(b)
		_counts[pile] = count
		_icons[pile] = icon
	_make_menu(menu_button, _menu_face)
	menu_button.pressed.connect(func(): intent.emit({"type": "menu"}))
	add_child(menu_button)
	# Back mirrors the menu button: a full tap target reaching below the header, its
	# word in the header's left end.
	back_button.name = "BackButton"
	back_button.tooltip_text = "Back"
	back_button.custom_minimum_size = Vector2(BACK_W, T.TAP_MIN)
	back_button.flat = true
	back_button.visible = false
	for state in ["normal", "hover", "pressed", "disabled"]:
		back_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	back_button.add_theme_stylebox_override("focus", UI.focus_ring())
	var word := UI.label("‹ Back", T.BUTTON, T.PARCHMENT)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_back_face.add_child(word)
	_slab_face(back_button, _back_face)
	back_button.pressed.connect(func(): intent.emit({"type": "back"}))
	UI.press_feedback(back_button)
	add_child(back_button)
	resized.connect(_fit)
	# The band follows the screen's edges, so it is redrawn when the bar moves.
	item_rect_changed.connect(queue_redraw)
	item_rect_changed.connect(_fit)


func _draw() -> void:
	# A flat band of stone across the whole screen, from its very top to just under the
	# bar, with the dark line of a card's frame along its foot (specs/019 TopBar).
	var view := get_global_transform().affine_inverse() * get_viewport_rect()
	var top := view.position.y
	var band := Rect2(view.position.x, top, view.size.x, size.y + 4.0 - top)
	draw_rect(band, T.STONE)
	draw_rect(Rect2(band.position.x, band.end.y - T.BORDER_EDGE, band.size.x, T.BORDER_EDGE), T.CARD_FRAME)


## The menu button `b` with its slab `face`: the header is shorter than a thumb, so
## the button reaches below it, a stone slab in the bar (specs/019 TopBar) with the
## icon in the middle. The landing page, which has no bar, makes its own alike.
static func _make_menu(b: Button, face: PanelContainer) -> void:
	b.name = "MenuButton"
	b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	b.flat = true
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", UI.focus_ring())
	face.add_child(UI.icon_rect("menu", 34, T.PARCHMENT))
	_slab_face(b, face)
	UI.press_feedback(b)


## A menu button and its slab, for a screen without the bar; place it with
## menu_face_rect().
static func menu_button_alone() -> Button:
	var b := Button.new()
	var face := PanelContainer.new()
	face.name = "Face"
	_make_menu(b, face)
	return b


## Where the menu button's slab sits on it, for a bar resting at `header` (the
## window's top at 0): as _fit() and _inside() place it.
static func menu_face_rect(header: Rect2) -> Rect2:
	var lift := roundf((4.0 - minf(header.position.y, T.SPACE_4)) / 2.0)
	var top := maxf(-header.position.y, -T.SPACE_4) + BAR_INSET
	var bottom := header.size.y + 4.0 - T.BORDER_EDGE - T.SHADOW_SLAB.drop - BAR_INSET
	return Rect2(0, top - lift, T.TAP_MIN, maxf(0.0, bottom - top))


## A button's visible stone slab, inside the bar while its hit area reaches below:
## raised at rest, sunk while pressed.
static func _slab_face(b: Button, face: PanelContainer) -> void:
	var rest := StoneStyle.new("plinth")
	rest.size = "sm"
	var down := StoneStyle.new("plinth")
	down.size = "sm"
	down.pressed = true
	# No padding above and below: the bar is shorter than a slab's padded minimum.
	for st in [rest, down]:
		st.content_margin_top = 0
		st.content_margin_bottom = 0
	face.add_theme_stylebox_override("panel", rest)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in face.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_child(face)
	b.button_down.connect(func(): face.add_theme_stylebox_override("panel", down))
	b.button_up.connect(func(): face.add_theme_stylebox_override("panel", rest))


## Show only a heading and the menu button, as on every screen but the play screen,
## and Back when the screen can go back.
func set_title(text: String, can_go_back := false) -> void:
	_titled = true
	_heading.text = text
	_heading_more.text = ""
	_heading_more.visible = false
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_heading.clip_text = true
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_button.visible = can_go_back
	for b in _piles:
		b.visible = false
	for slot in _slots:
		slot.visible = false
	_fit()


func render(vs: Dictionary) -> void:
	var parts: Array = vs.stage.get("heading_parts", [vs.stage.heading, ""])
	_heading.text = parts[0]
	_heading_more.text = parts[1]
	_heading_more.visible = parts[1] != ""
	set_counts(vs.piles)


func set_counts(piles: Dictionary) -> void:
	for pile in PILES:
		_shown[pile] = piles[pile]
		_counts[pile].text = str(piles[pile])


## Change one pile's count as a card arrives or leaves, with a flash.
func bump(pile: String, delta: int) -> void:
	_shown[pile] = maxi(0, _shown[pile] + delta)
	_counts[pile].text = str(_shown[pile])
	UI.flash(_icons[pile], T.PARCHMENT)


## Global centre of a pile's icon, for cards flying to or from it.
func pile_point(pile: String) -> Vector2:
	return pile_rect(pile).get_center()


## Global rect of a pile's icon.
func pile_rect(pile: String) -> Rect2:
	var icon: Control = _icons[pile]
	return Rect2(icon.global_position, icon.size)


## How far the bar's contents are raised, so they sit level with the middle of the
## band that shows, which runs from the screen's top (or the margin under a notch)
## to just under the bar.
func lift() -> float:
	var view_top := (get_global_transform().affine_inverse() * get_viewport_rect()).position.y
	return roundf((4.0 - minf(-view_top, T.SPACE_4)) / 2.0)


func _fit() -> void:
	var lift := lift()
	menu_button.size = Vector2(T.TAP_MIN, T.TAP_MIN)
	menu_button.position = Vector2(size.x - PAD_X - T.TAP_MIN, lift)
	back_button.size = Vector2(BACK_W, T.TAP_MIN)
	back_button.position = Vector2(PAD_X, lift)
	# A name alone is centred on the bar, clear of Back and the menu button alike;
	# on the play screen the row runs from the left end, past the padding, to a gap
	# before the menu button.
	var left: float = PAD_X + (maxf(BACK_W, T.TAP_MIN) if _titled else 0.0)
	var right: float = PAD_X + (maxf(BACK_W, T.TAP_MIN) if _titled else float(T.TAP_MIN + MENU_GAP))
	_row.position = Vector2(left, lift)
	_row.size = Vector2(maxf(0.0, size.x - left - right), size.y)
	# The slabs and chips sit inside the bar, clear of its foot line with their drop.
	var room := _inside()
	_menu_face.position = Vector2(0, room.position.y - lift)
	_menu_face.size = Vector2(T.TAP_MIN, room.size.y)
	_back_face.position = Vector2(0, room.position.y - lift)
	_back_face.size = Vector2(BACK_W, room.size.y)
	_place_piles.call_deferred()


## The bar's band from just under the screen's top to just over its foot line and
## a slab's drop, in this control's coordinates: where its slabs and chips go.
func _inside() -> Rect2:
	var view_top := (get_global_transform().affine_inverse() * get_viewport_rect()).position.y
	var top := maxf(view_top, -T.SPACE_4) + BAR_INSET
	var bottom := size.y + 4.0 - T.BORDER_EDGE - T.SHADOW_SLAB.drop - BAR_INSET
	return Rect2(0, top, 0, maxf(0.0, bottom - top))


## Lay each pile's button over its room in the row, its chip in the bar.
func _place_piles() -> void:
	var room := _inside()
	for i in _piles.size():
		var b: Control = _piles[i]
		b.visible = _slots[i].visible
		b.size = Vector2(T.TAP_MIN, size.y)
		b.position = _slots[i].position + _row.position
		var chip: Control = b.get_child(0)
		chip.position = Vector2(0, room.position.y + T.SHADOW_SLAB.drop / 2.0 - _row.position.y)
		chip.size = Vector2(T.TAP_MIN, room.size.y)

