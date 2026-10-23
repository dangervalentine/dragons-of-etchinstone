extends Control
## Owns the card nodes on the play screen, one per visible card, and puts each
## where it belongs: in its place, under the place's label (in setup and Soak, in
## Hand order); lifted while it is picked up, tucked behind its partner when fused.
## It also draws the outline of each empty place, which takes the held card when
## tapped. Cards keep their node while they stay visible, so they can glide from one
## place to the next.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const CardView = preload("res://ui/widgets/card_view.gd")
const Solver = preload("res://ui/model/layout_solver.gd")
const PlaceLabels = preload("res://ui/widgets/place_labels.gd")

signal intent(data: Dictionary)
signal hover(id: String, on: bool)

var _cards := {}
var _tweens: Array = []
var _outlines: Array = []
var _plan := {}
var _vs := {}
## The card being dragged and where the pointer holds it, from its top-left.
var _drag_id := ""
## Where the pointer last aimed the held card (main.gd "aim").
var _aim = null
var _drag_grip := Vector2.ZERO
## Cards passing by and not in the Hand: a Time Penalty's, on their way to the Discard.
var _passing: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func card(id: String) -> Control:
	return _cards.get(id)


func ids() -> Array:
	return _cards.keys()


## Start or stop every card's Ether field moving.
func set_live(on: bool) -> void:
	for view in _cards.values():
		view.set_live(on)


## Bring the cards in line with the view state. `animate` glides moved cards;
## `arrive_from` (a global rect, the top card on the Deck) is where new cards come
## from, one after another, at its size, shrinking into their places as they go.
## Every card has a place (contracts/board-layout.md); in setup and Soak, which have
## none, the cards take the plan's positions in Hand order.
func sync(vs: Dictionary, plan: Dictionary, animate := false, arrive_from = null) -> void:
	finish()
	_plan = plan
	_vs = vs
	var hand: Array = vs.hand
	var places: Array = vs.get("places", [])
	for id in _cards.keys():
		if not hand.has(id):
			_cards[id].queue_free()
			_cards.erase(id)
	sync_outlines(places, plan)
	var arrivals := 0
	for i in hand.size():
		var id: String = hand[i]
		var m: Dictionary = vs.cards[id]
		var view: Control = _cards.get(id)
		var fresh := view == null
		if fresh:
			view = CardView.new()
			view.tapped.connect(func(card_id): intent.emit({"type": "card", "id": card_id}))
			view.held.connect(func(card_id): intent.emit({"type": "inspect", "id": card_id}))
			view.hovered.connect(func(card_id, on): hover.emit(card_id, on))
			view.drag_started.connect(_on_drag_started)
			view.dragged.connect(_on_dragged)
			view.dropped.connect(_on_dropped)
			add_child(view)
			_cards[id] = view
		view.show_set_number = vs.sets.size() > 1
		view.set_model(m)
		var r: Rect2 = _home_of(id, m, places, vs.get("unplaced", hand))
		var home: Rect2 = Rect2(r.position - global_position, r.size)
		# A card picked up rises a little; a chosen one stays put, its border (and in
		# the Soak and Upgrade steps its turned face) enough to show it.
		if m.state == "held":
			home.position.y -= Solver.HELD_LIFT
		view.home = home
		view.z_index = 1 if m.state == "held" else 0
		if fresh and animate and arrive_from != null:
			var start: Rect2 = arrive_from
			view.position = start.position - global_position
			view.size = start.size
			view.modulate.a = 0.0
			_glide(view, arrivals * T.STAGGER, true)
			arrivals += 1
		elif fresh or not animate:
			view.snap_home()
		else:
			_glide(view, 0.0)
	# While the Ether is chosen, the second card leans in behind the first.
	var pick: Array = vs.get("fuse_pick", [])
	if vs.get("fuse_elements", false) and pick.size() == 2 and _cards.has(pick[0]) and _cards.has(pick[1]):
		var top: Control = _cards[pick[0]]
		var lean: Control = _cards[pick[1]]
		lean.home = Rect2(top.home.position + Vector2(-top.home.size.x * 0.2, -top.home.size.y * 0.1), top.home.size)
		# Behind its partner but above everything outside the Hand: draw it first.
		lean.z_index = 0
		move_child(lean, 0)
		if animate:
			_glide(lean, 0.0)
			if not UI.reduced_motion:
				_tweens[-1].tween_property(lean, "rotation", deg_to_rad(-7.0), T.MOVE)
		else:
			lean.snap_home()
			lean.rotation = deg_to_rad(-7.0)
	# A tucked card sits behind its partner, offset so its edge shows.
	for id in hand:
		var m: Dictionary = vs.cards[id]
		if m.fuse != null and m.fuse.part == "bottom" and _cards.has(m.fuse.other):
			var top: Control = _cards[m.fuse.other]
			var view: Control = _cards[id]
			view.home = Rect2(top.home.position + Vector2(-top.home.size.x * 0.16, -top.home.size.y * 0.07), top.home.size)
			view.z_index = 0
			if animate:
				_glide(view, 0.0)
				if not UI.reduced_motion:
					_tweens[-1].tween_property(view, "rotation", 0.0, T.MOVE)
			else:
				view.snap_home()
			move_child(view, 0)


## A short flourish when two cards become one.
func celebrate_fuse(id: String, element: String) -> void:
	var view: Control = _cards.get(id)
	if view == null:
		return
	UI.flash(view, T.ether(element))
	if UI.reduced_motion:
		return
	view.pivot_offset = view.size / 2.0
	var tw := create_tween()
	tw.tween_interval(T.MOVE * 0.8)
	tw.tween_property(view, "scale", Vector2(1.08, 1.08), T.FAST).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(view, "scale", Vector2.ONE, T.BASE)
	_tweens.append(tw)


## Stop every glide and put each card at its place.
func finish() -> void:
	for tw in _tweens:
		if tw.is_valid():
			tw.kill()
	_tweens = []
	for view in _passing:
		view.queue_free()
	_passing = []
	for view in _cards.values():
		if view.home.size != Vector2.ZERO:
			view.snap_home()


## `fly`: a card just drawn, whole and face-up, moving and shrinking together from
## the top card on the Deck to its place (specs/014 research R1).
func _glide(view: Control, delay: float, fly := false) -> void:
	var d: float = T.FAST if UI.reduced_motion else (T.DRAW_FLY if fly else T.MOVE)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if UI.reduced_motion:
		view.position = view.home.position
		view.size = view.home.size
		tw.tween_property(view, "modulate:a", 1.0, d).set_delay(delay)
	elif fly:
		# Out of sight until its turn, then whole from its first frame.
		tw.tween_property(view, "modulate:a", 1.0, 0.001).set_delay(delay)
		tw.tween_property(view, "position", view.home.position, d).set_delay(delay)
		tw.tween_property(view, "size", view.home.size, d).set_delay(delay)
	else:
		# A card moving between places slides and settles with a short overshoot, as on
		# a table (specs/019 Motion); a drawn card's flight from the Deck keeps its path.
		tw.tween_property(view, "position", view.home.position, d).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(view, "size", view.home.size, d).set_delay(delay)
		tw.tween_property(view, "modulate:a", 1.0, d * 0.6).set_delay(delay)
	_tweens.append(tw)


## A card that leaves the top card on the Deck (`from`, a global rect) after
## `delay` as a drawn one does, but goes to the pile whose icon is at `to` (a
## global rect) instead of the Hand, shrinking into it; `landed` is called as it
## arrives. In reduced motion it shows at the icon and fades.
func pass_to(m: Dictionary, from: Rect2, to: Rect2, delay: float, d: float, landed: Callable) -> void:
	var view := CardView.new()
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	view.set_model(m)
	view.size = from.size
	view.pivot_offset = from.size / 2.0
	view.position = from.position - global_position
	view.modulate.a = 0.0
	_passing.append(view)
	var end := to.get_center() - global_position - from.size / 2.0
	var shrink := Vector2.ONE * minf(1.0, to.size.y * 1.2 / maxf(1.0, from.size.y))
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if UI.reduced_motion:
		view.position = end
		view.scale = shrink
		tw.tween_property(view, "modulate:a", 1.0, d * 0.4).set_delay(delay)
		tw.tween_property(view, "modulate:a", 0.0, d * 0.4).set_delay(delay + d * 0.6)
	else:
		# Out of sight until its turn, then whole from its first frame, fading only as
		# it goes into the icon.
		tw.tween_property(view, "modulate:a", 1.0, 0.001).set_delay(delay)
		tw.tween_property(view, "position", end, d).set_delay(delay)
		tw.tween_property(view, "scale", shrink, d).set_delay(delay)
		tw.tween_property(view, "modulate:a", 0.0, d * 0.2).set_delay(delay + d * 0.8)
	tw.chain().tween_callback(func():
		landed.call()
		_passing.erase(view)
		view.queue_free())
	_tweens.append(tw)


## pass_to() the other way: a card comes out of the pile whose icon is at `from` (a
## global rect) after `delay`, growing to the top card's size as it goes to `to` (a
## global rect, the top card's), and is gone as it lands under it; `landed` is
## called then. In reduced motion it shows at the top card and fades.
func pass_from(m: Dictionary, from: Rect2, to: Rect2, delay: float, d: float, landed: Callable) -> void:
	var view := CardView.new()
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	view.set_model(m)
	view.size = to.size
	view.pivot_offset = to.size / 2.0
	view.position = from.get_center() - global_position - to.size / 2.0
	view.scale = Vector2.ONE * minf(1.0, from.size.y * 1.2 / maxf(1.0, to.size.y))
	view.modulate.a = 0.0
	_passing.append(view)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if UI.reduced_motion:
		view.position = to.position - global_position
		view.scale = Vector2.ONE
		tw.tween_property(view, "modulate:a", 1.0, d * 0.4).set_delay(delay)
		tw.tween_property(view, "modulate:a", 0.0, d * 0.4).set_delay(delay + d * 0.6)
	else:
		# Fading in only as it leaves the icon, then whole until it is under the card.
		tw.tween_property(view, "modulate:a", 1.0, d * 0.2).set_delay(delay)
		tw.tween_property(view, "position", to.position - global_position, d).set_delay(delay)
		tw.tween_property(view, "scale", Vector2.ONE, d).set_delay(delay)
	tw.chain().tween_callback(func():
		landed.call()
		_passing.erase(view)
		view.queue_free())
	_tweens.append(tw)


## A card in the Hand goes back to the Deck as a drawn one came, in reverse: after
## `delay` it moves and grows together from its place to `to` (a global rect, the
## top card's), and is gone as it lands; `landed` is called then. It leaves the
## Hand at once, so a Hand drawn after it comes from the Deck afresh. In reduced
## motion it fades where it is.
func undraw(id: String, to: Rect2, delay: float, d: float, landed: Callable) -> void:
	var view: Control = _cards.get(id)
	if view == null:
		return
	_cards.erase(id)
	_passing.append(view)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if UI.reduced_motion:
		tw.tween_property(view, "modulate:a", 0.0, d).set_delay(delay)
	else:
		tw.tween_property(view, "position", to.position - global_position, d).set_delay(delay)
		tw.tween_property(view, "size", to.size, d).set_delay(delay)
	tw.chain().tween_callback(func():
		landed.call()
		_passing.erase(view)
		view.queue_free())
	_tweens.append(tw)


## A card in the Hand goes to the pile whose icon is at `to` (a global rect) as a
## Time Penalty's does: after `delay` it moves from its place and shrinks into the
## icon, fading only as it goes in; `landed` is called as it arrives. It leaves the
## Hand at once. In reduced motion it fades where it is.
func send_to(id: String, to: Rect2, delay: float, d: float, landed: Callable) -> void:
	var view: Control = _cards.get(id)
	if view == null:
		return
	_cards.erase(id)
	_passing.append(view)
	view.z_index = 5
	view.pivot_offset = view.size / 2.0
	var end := to.get_center() - global_position - view.size / 2.0
	var shrink := Vector2.ONE * minf(1.0, to.size.y * 1.2 / maxf(1.0, view.size.y))
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if UI.reduced_motion:
		tw.tween_property(view, "modulate:a", 0.0, d).set_delay(delay)
	else:
		tw.tween_property(view, "position", end, d).set_delay(delay)
		tw.tween_property(view, "scale", shrink, d).set_delay(delay)
		tw.tween_property(view, "rotation", 0.0, d).set_delay(delay)
		tw.tween_property(view, "modulate:a", 0.0, d * 0.2).set_delay(delay + d * 0.8)
	tw.chain().tween_callback(func():
		landed.call()
		_passing.erase(view)
		view.queue_free())
	_tweens.append(tw)


## Where a card belongs, in global units: its place's card rect, or (in setup and
## Soak) the position of its turn in Hand order. The tucked half of a Fuse has
## neither; it starts at the first position and sync() tucks it behind its partner.
func _home_of(id: String, m: Dictionary, places: Array, unplaced: Array) -> Rect2:
	var positions: Array = _plan.get("positions", [])
	var key = m.get("place")
	if key != null:
		for p in places:
			if p.key == key and p.index < positions.size():
				return positions[p.index].card
	var at := unplaced.find(id) + places.size()
	if at >= places.size() and at < positions.size():
		return positions[at].card
	if not positions.is_empty():
		return positions[0].card
	return Rect2(_plan.regions.hand.position, _plan.card_size)


## The well of each empty place, under its label: a tap target under the cards
## that takes the held card.
func sync_outlines(places: Array, plan: Dictionary) -> void:
	for o in _outlines:
		o.queue_free()
	_outlines = []
	var positions: Array = plan.get("positions", [])
	for p in places:
		if p.card_id != null or p.index >= positions.size():
			continue
		var o := _Outline.new()
		o.state = p.state
		o.role_name = PlaceLabels.ROLE_NAMES.get(p.role, "")
		var r: Rect2 = positions[p.index].card
		o.position = r.position - global_position
		o.size = r.size
		o.tooltip_text = p.tooltip
		if p.tap != null and p.state != "inactive":
			var tap: Dictionary = p.tap
			o.pressed.connect(func(): intent.emit(tap))
		else:
			o.disabled = true
		add_child(o)
		move_child(o, 0)
		_outlines.append(o)


## An empty place: a well the size of the card it waits for (specs/019 Slot). The
## target, the one place the next tap fills, takes the brass rim and its name inside;
## a place open to the held card the etched edge; the rest a hairline.
class _Outline extends Button:
	const T = preload("res://ui/theme/tokens.gd")
	const UI = preload("res://ui/theme/theme.gd")
	const StoneStyle = preload("res://ui/theme/stone_style.gd")
	var state := "empty"
	var role_name := ""

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func _draw() -> void:
		if state == "inactive":
			return
		var well := StoneStyle.new("well")
		well.selected = state == "target"
		if state == "open":
			well.edge = T.EDGE
		draw_style_box(well, Rect2(Vector2.ZERO, size))
		if state == "target" and role_name != "":
			var font := UI.font(T.LABEL)
			var text := role_name.to_upper()
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, T.LABEL.size).x
			draw_string(font, Vector2((size.x - w) / 2.0, size.y / 2.0 + T.LABEL.size * 0.35), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, T.LABEL.size, T.BRASS)


## Whether cards can be dragged into places now: while building, outside any mode.
func _can_drag() -> bool:
	return not _vs.is_empty() and _vs.get("mode", "") == "none" and not _vs.get("places", []).is_empty() 		and ["challenge", "final_journey", "final_enemy"].has(_vs.get("phase", ""))


## The pointer over a place while a card is held aims the card there (specs/019:
## one target at a time); main.gd draws the places again for it.
func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or _vs.is_empty() or _vs.get("held") == null or _drag_id != "":
		return
	var aim = _drop_target(event.global_position, str(_vs.held))
	if typeof(aim) != typeof(_aim) or aim != _aim:
		_aim = aim
		intent.emit({"type": "aim", "target": aim})


func _on_drag_started(id: String) -> void:
	if not _can_drag() or _vs.cards.get(id, {}).get("state", "") == "fused_bottom":
		return
	var view: Control = _cards.get(id)
	_drag_id = id
	_drag_grip = view.get_local_mouse_position()
	view.z_index = 2
	for partner in _partners(id):
		partner.z_index = 2


func _on_dragged(id: String, at: Vector2) -> void:
	if id != _drag_id:
		return
	var view: Control = _cards[id]
	var to := at - global_position - _drag_grip
	var moved := to - view.position
	view.position = to
	for partner in _partners(id):
		partner.position += moved


## Let go: over another card or an empty place (its label too), the card is put
## there; anywhere else it glides home and nothing changes.
func _on_dropped(id: String, at: Vector2) -> void:
	if id != _drag_id:
		return
	_drag_id = ""
	var target = _drop_target(at)
	if target == null:
		var view: Control = _cards[id]
		view.z_index = 0
		_glide(view, 0.0)
		for partner in _partners(id):
			partner.z_index = 0
			_glide(partner, 0.0)
		return
	intent.emit({"type": "drag_put", "id": id, "target": target})


## What a card dropped at a global point is put on: another card's place
## ({"card": id}), or an empty place as the draft names it; null over its own place
## or nowhere.
func _drop_target(at: Vector2, skip := "") -> Variant:
	var positions: Array = _plan.get("positions", [])
	var own := skip if skip != "" else _drag_id
	for p in _vs.get("places", []):
		if p.index >= positions.size() or p.state == "inactive" or p.card_id == own:
			continue
		var pos: Dictionary = positions[p.index]
		if not pos.label.merge(pos.card).grow(Solver.GAP / 2.0).has_point(at):
			continue
		if p.card_id != null:
			return {"card": p.card_id}
		return "reserve" if p.role == "reserve" else [p.set, p.role]
	return null


## The tucked card that travels with a fused card, if any.
func _partners(id: String) -> Array:
	var out := []
	var f = _vs.get("cards", {}).get(id, {}).get("fuse")
	if f != null and f.part == "top" and _cards.has(f.other):
		out.append(_cards[f.other])
	return out
