extends Button
## One dragon on the choice of dragon: its Dragon Card, whole, which the player
## taps. The chosen one is edged in its Ether's colour and the others are dimmed
## but still read; before any choice none is dimmed. Each figure on the card
## explains itself on hover, and a tap on a figure still chooses the dragon.
## A locked dragon cannot be chosen; its card shows it locked (DragonCard.locked).

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const DragonCard = preload("res://ui/widgets/dragon_card.gd")

## How bright an unchosen dragon is, and one under the pointer or in focus.
const DIM := Color(0.5, 0.5, 0.55)
const DIM_HOVER := Color(0.78, 0.78, 0.8)
## The edge around the chosen card, and the glow beyond it.
const EDGE := 4
const GLOW := 14

var selected := false: set = set_selected
## Whether any dragon is chosen; until one is, none is dimmed.
var any_chosen := false: set = set_any_chosen
var accent: Color = T.GOLD
var card: Control
## Set before the tile is shown; a locked dragon cannot be chosen.
var locked := false: set = set_locked


static func make(dragon_model: Dictionary, colour: Color) -> Button:
	var b = load("res://ui/widgets/dragon_pick.gd").new()
	b.accent = colour
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.card = DragonCard.new()
	b.card.explain = true
	b.add_child(b.card)
	b.card.render(dragon_model)
	b.resized.connect(b._fit)
	b.mouse_entered.connect(b._shade)
	b.mouse_exited.connect(b._shade)
	b.focus_entered.connect(b._shade)
	b.focus_exited.connect(b._shade)
	UI.press_feedback(b)
	b._shade()
	return b


## The smallest the tile can be and still show the card readably.
func _get_minimum_size() -> Vector2:
	return Vector2(160, DragonCard.card_size(160).y)


func set_selected(on: bool) -> void:
	selected = on
	_shade()


func set_any_chosen(on: bool) -> void:
	any_chosen = on
	_shade()


## The card where it lies in the tile: as large as fits inside the glow, centred
## across, at the foot, so it sits on its flavour below.
func card_rect() -> Rect2:
	var room := Vector2(size.x - 2 * GLOW, size.y - 2 * GLOW)
	var s: Vector2 = DragonCard.card_size(room.x)
	if s.y > room.y:
		s = DragonCard.card_size(maxf(1.0, room.y * s.x / s.y))
	return Rect2(Vector2((size.x - s.x) / 2.0, size.y - GLOW - s.y).round(), s.round())


func set_locked(on: bool) -> void:
	locked = on
	disabled = on
	focus_mode = Control.FOCUS_NONE if on else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if on else Control.CURSOR_ARROW
	if card != null:
		card.locked = on
	_shade()


func _fit() -> void:
	if card == null:
		return
	var r := card_rect()
	card.position = r.position
	card.size = r.size
	pivot_offset = size / 2.0
	queue_redraw()


func _shade() -> void:
	var lit := selected or not any_chosen
	var near := is_hovered() or has_focus()
	var tone: Color = Color.WHITE if lit else (DIM_HOVER if near else DIM)
	if card != null:
		card.modulate = tone
	queue_redraw()


func _draw() -> void:
	if card == null:
		return
	var r := card_rect()
	var radius := UI.card_radius(r.size.x)
	if selected:
		# The chosen card is ringed in its Ether's colour, glowing out from the edge.
		var ring := UI.box(Color.TRANSPARENT, accent, EDGE, radius + EDGE)
		ring.shadow_color = Color(accent, 0.45)
		ring.shadow_size = GLOW
		ring.draw_center = false
		draw_style_box(ring, r.grow(EDGE))
	elif has_focus():
		# Keyboard focus on an unchosen card: a thin muted ring.
		var ring := UI.box(Color.TRANSPARENT, T.muted(T.GOLD), 2, radius + 3)
		ring.draw_center = false
		draw_style_box(ring, r.grow(3))
