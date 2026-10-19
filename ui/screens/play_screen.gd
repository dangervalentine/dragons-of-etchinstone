extends Control
## The one screen used for every step of play, from choosing starting cards to the
## last blow against the dragon. Regions in fixed places: header; on the left the
## Deck and nothing else, with the Region Card on top, the Encounter zoomed into on
## it, and a note laid over it when there is a step, a result or a refusal to read
## (deck_stack.gd); on the right the Hand, drawn from the Deck, each card under its
## place's label, and the action row under it. Widgets update in place; card nodes
## persist so they can move.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const HeaderBar = preload("res://ui/widgets/header_bar.gd")
const DeckStack = preload("res://ui/widgets/deck_stack.gd")
const PlaceLabels = preload("res://ui/widgets/place_labels.gd")
const HandTray = preload("res://ui/widgets/hand_tray.gd")
const ActionBar = preload("res://ui/widgets/action_bar.gd")
const EtherPicker = preload("res://ui/widgets/ether_picker.gd")
const CardDetail = preload("res://ui/widgets/card_detail.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal intent(data: Dictionary)

var header := HeaderBar.new()
var deck := DeckStack.new()
## The faces on the Deck and what its note holds, kept here by name for the
## screen's other users.
var landed: Control = deck.landed
var dragon_face: Control = deck.dragon_face
var preview: Control = deck.note.preview
var soak_meter: Control = deck.note.soak_meter
var xp_purse: Control = deck.note.xp_purse
var labels := PlaceLabels.new()
var actions := ActionBar.new()
var hand := HandTray.new()
var picker := EtherPicker.new()
var detail := CardDetail.new()
var _hand_panel := Panel.new()
## The deepest place cut into the stone: the Hand's well.
var _hand_well := StoneStyle.new("well", 0.9)
var _breath: Tween
var _input_region := ""
var _hover_id := ""
var _hover_timer := Timer.new()

var plan := {}
var vs := {}
## The layer numbers fly on, set by main.gd (as the animator's is).
var flight: Control
var _regions := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in ["encounter", "actions", "header"]:
		var r := Control.new()
		r.name = key
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_regions[key] = r
		add_child(r)
	_fill(_regions.encounter, deck)
	_fill(_regions.actions, actions)
	_fill(_regions.header, header)
	# The Hand sits in its own well, lit at the rim while it is waiting on the player.
	_hand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_panel.add_theme_stylebox_override("panel", _hand_well)
	add_child(_hand_panel)
	add_child(labels)
	labels.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hand)
	hand.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(picker)
	picker.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(detail)
	_hover_timer.one_shot = true
	_hover_timer.wait_time = 0.3
	_hover_timer.timeout.connect(_show_detail)
	add_child(_hover_timer)
	hand.hover.connect(_on_hover)
	# Whatever the player does next takes a refused move's reason off the Deck.
	for w in [header, deck, labels, actions, hand, picker]:
		w.intent.connect(func(data):
			deck.clear_refusal()
			intent.emit(data))


func apply_layout(p: Dictionary) -> void:
	plan = p
	_place_regions(p)
	_place_hand_panel()
	if not vs.is_empty():
		render(vs)


## Show a view state. `animate` lets moved cards glide; new cards arrive from
## `arrive_from` (a global point) when given.
func render(state: Dictionary, animate := false, arrive_from = null) -> void:
	var fused_before := _fused_top(vs)
	vs = state
	if plan.is_empty():
		return
	header.render(vs)
	plan = _replan(plan, vs)
	_place_hand_panel()
	if not plan.get("positions", []).is_empty():
		deck.set_card_size(plan.positions[0].card.size)
	deck.render(vs)
	labels.render(vs, plan)
	actions.render(vs)
	_render_prominence()
	hand.sync(vs, plan, animate, arrive_from)
	if detail.visible:
		if vs.cards.has(_hover_id):
			_show_detail()
		else:
			detail.hide_card()
	var fused_now := _fused_top(vs)
	if fused_now != "" and fused_now != fused_before and animate:
		hand.celebrate_fuse(fused_now, vs.cards[fused_now].fuse.element)
	var pick: Array = vs.get("fuse_pick", [])
	if vs.fuse_elements and pick.size() == 2 and hand.card(pick[0]) != null:
		var a: Control = hand.card(pick[0])
		var b: Control = hand.card(pick[1])
		var target := Rect2(a.home.position + hand.global_position, a.home.size).merge(Rect2(b.home.position + hand.global_position, b.home.size))
		picker.open(target, plan.content)
	else:
		picker.close()


func _place_regions(p: Dictionary) -> void:
	for key in _regions:
		var r: Rect2 = p.regions[key]
		_regions[key].position = r.position
		_regions[key].size = r.size
	actions.apply_layout(p.regions.actions, p.regions.commit, p.regions.secondary)


## The Hand's panel: round every place, its label and its card, at the Hand
## region's edges (layout_solver.HAND_PAD).
func _place_hand_panel() -> void:
	if plan.is_empty() or plan.get("positions", []).is_empty():
		return
	var cells: Rect2 = plan.positions[0].label.merge(plan.positions[0].card)
	for pos in plan.positions:
		cells = cells.merge(pos.label).merge(pos.card)
	var Solver = load("res://ui/model/layout_solver.gd")
	var panel := cells.grow(Solver.HAND_PAD)
	_hand_panel.position = panel.position
	_hand_panel.size = panel.size


## The part of the screen waiting on the player comes forward; the rest steps back.
func _render_prominence() -> void:
	var region: String = vs.get("input_region", "hand")
	if region == _input_region:
		return
	_input_region = region
	actions.set_ready(region == "commit")
	# The zone waiting on the player lights up and breathes slowly; the light moves
	# with a cross-fade, or at once in reduced motion.
	if _breath != null and _breath.is_valid():
		_breath.kill()
	var lit: StyleBox = _hand_well if region == "hand" else primary_style()
	for style in [_hand_well, primary_style()]:
		if style == null or style.get("glow") == null:
			continue
		var to := 1.0 if style == lit else 0.0
		if UI.reduced_motion or not is_inside_tree():
			style.glow = to
		else:
			create_tween().tween_property(style, "glow", to, T.BASE)
	if lit != null and lit.get("glow") != null and not UI.reduced_motion and is_inside_tree():
		_breath = create_tween().set_loops()
		_breath.tween_interval(T.BASE)
		_breath.tween_property(lit, "glow", 0.85, 1.5).set_trans(Tween.TRANS_SINE)
		_breath.tween_property(lit, "glow", 1.0, 1.5).set_trans(Tween.TRANS_SINE)


func primary_style() -> StyleBox:
	return actions.primary.get_theme_stylebox("normal")


## The board's answer at one zone (contracts/board-life.md): its rim lights in
## `colour` and fades, the Encounter shudders, a role slot flares. In reduced
## motion the rim is held lit for a moment instead.
func flare(target: String, colour: Color, kind: String, duration: float, card_id := "") -> void:
	if target == "slot":
		# The card that took or left a place answers in its own light.
		var card: Control = hand.card(card_id)
		if card != null:
			UI.flash(card, colour)
		return
	var style: StyleBox = null
	var node: Control = null
	match target:
		"hand":
			style = _hand_well
			node = _hand_panel
		"encounter":
			node = encounter_node()
			style = node.get("_stone")
		"header":
			style = header.get("_lintel")
			node = header
	if style == null:
		return
	# Back to the zone's own resting colour, not whatever an overlapping answer left.
	if not style.has_meta("rest_colour"):
		style.set_meta("rest_colour", style.glow_colour)
	var was_colour: Color = style.get_meta("rest_colour")
	var was: float = style.glow
	style.glow_colour = colour
	if UI.reduced_motion:
		style.glow = 1.0
		get_tree().create_timer(T.BASE).timeout.connect(func():
			style.glow = was
			style.glow_colour = was_colour)
		return
	if kind == "shudder" and node != null:
		UI.shake(node, 6.0)
	var tw := create_tween()
	tw.tween_property(style, "glow", 1.0, duration * 0.3)
	tw.tween_property(style, "glow", was, duration * 1.4)
	tw.tween_callback(func(): style.glow_colour = was_colour)


func _fused_top(state: Dictionary) -> String:
	if state.is_empty():
		return ""
	for id in state.hand:
		var f = state.cards[id].get("fuse")
		if f != null and f.part == "top":
			return id
	return ""


## Tracks the card under the pointer.
func _on_hover(id: String, on: bool) -> void:
	# Hovering explains one part of the card at a time (CardView's tooltip) rather
	# than opening the whole card's detail.
	if on:
		_hover_id = id
	else:
		_hover_timer.stop()
		detail.hide_card(id)
		if _hover_id == id:
			_hover_id = ""


func _show_detail() -> void:
	if _hover_id == "" or not vs.cards.has(_hover_id) or plan.is_empty():
		return
	detail.show_card(vs.cards[_hover_id], plan.regions.encounter)


## Finish anything in motion and show the current state exactly.
## Start or stop the cards' Ether fields moving: off while an overlay covers the screen.
func set_fields_live(on: bool) -> void:
	hand.set_live(on)
	detail.set_live(on)


func settle() -> void:
	hand.finish()
	preview.settle()


## A refused move's reason, on the Deck in the card's place (specs/013 FR-011).
func refuse(text: String) -> void:
	deck.show_refusal(text)


## Global points that effects travel between.
func point(anchor: String) -> Vector2:
	match anchor:
		# Cards are drawn from under the Deck's top card and go to its back; the header
		# keeps the exact counts (specs/012 research R9).
		"deck":
			return deck.top_point()
		"discard", "trash":
			return deck.back_point()
		"encounter":
			return _regions.encounter.global_position + _regions.encounter.size / 2.0
		"xp":
			return xp_purse.point() if xp_purse.is_visible_in_tree() else deck.note_point()
		"preview":
			return deck.note_point()
		"hand":
			return plan.regions.hand.get_center() if not plan.is_empty() else size / 2.0
	return size / 2.0


func encounter_node() -> Control:
	return deck.face_node()


func _replan(p: Dictionary, state: Dictionary) -> Dictionary:
	var count: int = state.hand.size()
	var Solver = load("res://ui/model/layout_solver.gd")
	var places: int = Solver.place_count(state)
	var final: bool = Solver.is_final(state)
	var cells: int = state.get("action_cells", 3)
	if p.get("for", []) == [count, places, final, cells]:
		return p
	var q: Dictionary = Solver.solve(p.view, p.safe, count, places, p.points_per_unit, p.get("undersized_upright", false), final, cells)
	q["safe"] = p.safe
	q["undersized_upright"] = p.get("undersized_upright", false)
	q["for"] = [count, places, final, cells]
	if q.regions != p.regions or q.positions != p.get("positions"):
		plan = q
		_place_regions(q)
	return q


func _fill(parent: Control, child: Control) -> void:
	parent.add_child(child)
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
