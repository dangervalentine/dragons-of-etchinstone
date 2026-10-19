extends Control
## A note laid on the Deck in the card's place (specs/013 research R6, specs/015):
## a card of its own, dealt over the Encounter for as long as it is needed and
## thrown off again with the rest of the pile (note_pile.gd). It holds one thing to
## read: the sum and verdict of the set just played (the result); the step to
## follow (a Fuse, Divert or Regroup, or the Deck being prepared); the Soak meter;
## the XP to spend; or a refused move's reason. Pressed and held, it lifts aside
## with the pile to show the card under it.

signal intent(data: Dictionary)
## A press on the note begins or ends (note_pile.gd lifts the pile aside while held).
signal held(on: bool)

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const PreviewPanel = preload("res://ui/widgets/preview_panel.gd")
const SoakMeter = preload("res://ui/widgets/soak_meter.gd")
const XpPurse = preload("res://ui/widgets/xp_purse.gd")
const Creature = preload("res://ui/fx/creature.gd")
const Art = preload("res://ui/model/art.gd")

const PAD := 16.0

var preview := PreviewPanel.new()
var soak_meter := SoakMeter.new()
var xp_purse := XpPurse.new()
## What the note shows, as a set of kinds ("result", "mode", "setup", "soak",
## "upgrade"), or the reason of a refusal.
var kinds: Array = []
var refusal := ""
## The state the set just played was played in: the result is always built from it.
var result_vs := {}

## What the card holds, clipped to it; the card itself does not clip, so its shadow
## falls outside it.
var _body := Control.new()
var _box := VBoxContainer.new()
var _setup := VBoxContainer.new()
var _setup_key := ""
var _refusal := Label.new()
var _creature := Creature.new()
var _pressed_at := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_body.clip_contents = true
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_creature.held = true
	_creature.visible = false
	_creature.modulate.a = 0.35
	_body.add_child(_creature)
	_box.add_theme_constant_override("separation", T.M)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_box)
	_setup.add_theme_constant_override("separation", T.S)
	_box.add_child(_setup)
	# On the note the hosted panels draw no stone of their own: the note is the card.
	for panel in [preview, soak_meter, xp_purse]:
		var flat := StyleBoxEmpty.new()
		panel.add_theme_stylebox_override("panel", flat)
		_box.add_child(panel)
		panel.visible = false
	preview.intent.connect(func(data): intent.emit(data))
	UI.style_label(_refusal, T.BODY, T.BAD)
	_refusal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refusal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refusal.visible = false
	_box.add_child(_refusal)
	resized.connect(_fit)


## Show `what` (kinds) for the state `vs`; a result is built from `result_vs`, and
## set out line by line while that fits the note, else on one row.
func show_kinds(what: Array, vs: Dictionary) -> void:
	kinds = what.duplicate()
	var stepping: bool = what.has("mode") or what.has("setup")
	preview.visible = what.has("result") or stepping
	soak_meter.visible = what.has("soak")
	xp_purse.visible = what.has("upgrade")
	_setup.visible = what.has("setup")
	preview.roomy = size.y >= T.NOTE_ROOMY_H
	if what.has("result"):
		_render_result()
	elif preview.visible:
		preview.render(vs)
	if soak_meter.visible:
		soak_meter.render(vs)
	if xp_purse.visible:
		# On a note of its own over the result (specs/015), the purse says again how
		# it went.
		xp_purse.render(vs)
	if _setup.visible:
		_render_setup(vs)
	_creature.visible = _setup.visible and _creature.art_name != ""
	_show_refusal()
	_fit()
	if what.has("result") and preview.roomy and content_height() > size.y - 2.0 * PAD:
		preview.roomy = false
		_render_result()
		_fit()


func _render_result() -> void:
	if result_vs.is_empty():
		return
	preview.render(result_vs)
	preview.reveal()
	preview.settle()


## A refused move's reason, alone on the note; "" to go back to what it showed.
func set_refusal(text: String) -> void:
	refusal = text
	_show_refusal()
	_fit()


func is_showing() -> bool:
	return refusal != "" or not kinds.is_empty()


func _show_refusal() -> void:
	var on := refusal != ""
	_refusal.text = refusal
	_refusal.visible = on
	if on:
		for c in [preview, soak_meter, xp_purse, _setup]:
			c.visible = false
		_creature.visible = false


## Before the first Encounter: the dragon hunted, faint behind the words, and what
## this step is for (it was the face on the Deck before feature 013).
func _render_setup(vs: Dictionary) -> void:
	var key: String = vs.stage.dragon + vs.phase
	if key == _setup_key:
		return
	_setup_key = key
	for c in _setup.get_children():
		_setup.remove_child(c)
		c.queue_free()
	var head := UI.hbox(T.S)
	head.add_child(UI.icon_rect("crown", 34, T.GOLD))
	var title := UI.label("PREPARE YOUR DECK", T.SUBHEAD, T.INK)
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_setup.add_child(head)
	_setup.add_child(UI.label("Four Regions lie between you and the dragon. Your sixteen Mage Cards are your only weapons, and your deck is your time.", T.BODY, T.INK, true))
	_setup.add_child(UI.label("The cards you choose start at a different Level. Hold a card to see its other Levels.", T.LABEL, T.INK_MUTED, true))
	var art: String = vs.stage.get("art", "")
	if art != "" and _creature.art_name != art:
		var e: String = vs.stage.get("element", "")
		_creature.setup(art, Color(T.ether(e) if e != "" else T.INK, 0.5), e, false)
	UI.ignore_mouse(_setup)


func _fit() -> void:
	queue_redraw()
	_body.position = Vector2.ZERO
	_body.size = size
	var inner := Rect2(Vector2(PAD, PAD), size - Vector2(PAD, PAD) * 2.0)
	_box.position = inner.position
	_box.size = Vector2(inner.size.x, 0)
	# Twice: the first pass gives wrapped lines their width, the second the height
	# that width needs (as preview_panel.gd's _lay_out).
	for i in 3:
		_sort(_box)
	# Short content sits in the middle of the note; long content from its top.
	var h := _box.get_combined_minimum_size().y
	_box.size.y = h
	_box.position.y = inner.position.y + maxf(0.0, (inner.size.y - h) / 2.0)
	var a := minf(size.x, size.y) * 0.9
	_creature.size = Vector2(a, a)
	_creature.position = Vector2(size.x - a, size.y - a)
	queue_redraw()


## Lay `node` out from the top down: each container gives its children their
## places (and so their widths) before they lay out their own.
static func _sort(node: Node) -> void:
	if node is Label:
		node.update_minimum_size()
	if node is Container:
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for c in node.get_children():
		_sort(c)


## The height its content takes, for the checks.
func content_height() -> float:
	return _box.get_combined_minimum_size().y


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		held.emit(event.pressed)
		accept_event()


## The card's own stone and rounded corners, with a card's edge and the shadow of
## a card lying on the table: a card laid over the Encounter (specs/015).
func _draw() -> void:
	# As the zoomed face draws itself (deck_stack.gd LandedFace), so the one gives way
	# to the other with nothing round the edge changing.
	var radius: int = UI.card_radius(size.x)
	# Lying on the table, a card casts a soft shadow under it (specs/015).
	for layer in T.CARD_SHADOW:
		var sh := StyleBoxFlat.new()
		sh.bg_color = Color(0, 0, 0, layer[1])
		sh.set_corner_radius_all(radius + int(layer[0]))
		draw_style_box(sh, Rect2(Vector2(2, 4), size).grow(layer[0]))
	# Its edge in card stock, as the Deck's cards have, so each note laid on another
	# reads as a card of its own.
	draw_style_box(UI.box(T.BG_RAISED, T.CARD_EDGE_LINE, 2, radius, 0), Rect2(Vector2.ZERO, size))
