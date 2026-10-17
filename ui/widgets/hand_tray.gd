extends Control
## Owns the card nodes on the play screen, one per visible card, and puts each
## where it belongs: in its place's column under the role strip, or floating in the
## row at the foot of the Hand until it has one; lifted while it is picked up,
## tucked behind its partner when fused. It also draws the outline of each empty
## place, which takes the held card when tapped. Cards keep their node while they stay visible,
## so they can glide from one place to the next.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const CardView = preload("res://ui/widgets/card_view.gd")
const Solver = preload("res://ui/model/layout_solver.gd")

signal intent(data: Dictionary)
signal hover(id: String, on: bool)

var _cards := {}
var _tweens: Array = []
var _outlines: Array = []
var _plan := {}
var _vs := {}
## The card being dragged and where the pointer holds it, from its top-left.
var _drag_id := ""
var _drag_grip := Vector2.ZERO


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
## `arrive_from` (a global point) is where new cards come from, one after another.
## A placed card sits in its place's column; the rest float in a row at the foot of
## the Hand (contracts/board-layout.md).
func sync(vs: Dictionary, plan: Dictionary, animate := false, arrive_from = null) -> void:
	finish()
	_plan = plan
	_vs = vs
	var hand: Array = vs.hand
	var places: Array = vs.get("places", [])
	var floating: Array = vs.get("floating", hand)
	var floating_rects: Array = Solver.floating_rects(plan, floating.size())
	var place_rects: Array = plan.get("place_rects", [])
	for id in _cards.keys():
		if not hand.has(id):
			_cards[id].queue_free()
			_cards.erase(id)
	_sync_outlines(vs, plan, places, floating.size())
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
		var r: Rect2 = _home_of(id, m, places, place_rects, floating, floating_rects)
		var home: Rect2 = Rect2(r.position - global_position, r.size)
		if m.state == "held" or m.state == "selected":
			home.position.y -= Solver.HELD_LIFT
		view.home = home
		view.z_index = 1 if m.state == "held" else 0
		if fresh and animate and arrive_from != null:
			var start := Rect2(arrive_from - global_position - home.size * 0.15, home.size * 0.3)
			view.position = start.position
			view.size = start.size
			view.modulate.a = 0.0
			_glide(view, arrivals * T.STAGGER)
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
	for view in _cards.values():
		if view.home.size != Vector2.ZERO:
			view.snap_home()


func _glide(view: Control, delay: float) -> void:
	var d: float = T.FAST if UI.reduced_motion else T.MOVE
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if UI.reduced_motion:
		view.position = view.home.position
		view.size = view.home.size
		tw.tween_property(view, "modulate:a", 1.0, d).set_delay(delay)
	else:
		tw.tween_property(view, "position", view.home.position, d).set_delay(delay)
		tw.tween_property(view, "size", view.home.size, d).set_delay(delay)
		tw.tween_property(view, "modulate:a", 1.0, d * 0.6).set_delay(delay)
	_tweens.append(tw)


## Where a card belongs, in global units: its place's column, or its spot in the
## floating row. A card in neither (the tucked half of a Fuse) starts at the first
## floating spot; sync() then tucks it behind its partner.
func _home_of(id: String, m: Dictionary, places: Array, place_rects: Array, floating: Array, floating_rects: Array) -> Rect2:
	var key = m.get("place")
	if key != null:
		for i in places.size():
			if places[i].key == key and i < place_rects.size():
				return place_rects[i]
	var at := floating.find(id)
	if at >= 0 and at < floating_rects.size():
		return floating_rects[at]
	if not floating_rects.is_empty():
		return floating_rects[0]
	if not place_rects.is_empty():
		return place_rects[0]
	return Rect2(_plan.regions.hand.position, _plan.card_size)


## The outline of each empty place, under its section of the role strip, and the
## floating row's band, which takes a held card back. Both are tap targets under
## the cards.
func _sync_outlines(vs: Dictionary, plan: Dictionary, places: Array, floating: int) -> void:
	for o in _outlines:
		o.queue_free()
	_outlines = []
	var rects: Array = plan.get("place_rects", [])
	var h := Solver.outline_height(plan, floating) if not rects.is_empty() else 0.0
	for i in places.size():
		var p: Dictionary = places[i]
		if p.card_id != null or i >= rects.size():
			continue
		var r: Rect2 = rects[i]
		var o := _Outline.new()
		o.state = p.state
		o.position = r.position - global_position
		o.size = Vector2(r.size.x, h)
		o.tooltip_text = p.tooltip
		if p.tap != null and p.state != "inactive":
			var tap: Dictionary = p.tap
			o.pressed.connect(func(): intent.emit(tap))
		else:
			o.disabled = true
		add_child(o)
		move_child(o, 0)
		_outlines.append(o)
	# While a card is held, the floating row's band takes it back.
	if vs.get("held") != null and not rects.is_empty():
		var band: Rect2 = plan.regions.hand
		var top: float = rects[0].position.y + h + Solver.GAP / 2.0
		var f := Solver.floating_rects(plan, maxi(floating, 1))
		if not f.is_empty():
			top = minf(top, f[0].position.y - Solver.GAP / 2.0)
		var back := _Outline.new()
		back.state = "floating"
		back.position = Vector2(band.position.x, top) - global_position
		back.size = Vector2(band.size.x, band.end.y - top)
		back.tooltip_text = "Put it back with the other cards"
		back.pressed.connect(func(): intent.emit({"type": "put", "target": "floating"}))
		add_child(back)
		move_child(back, 0)
		_outlines.append(back)


## An empty place: a stroke the size of the card it waits for, glowing while a held
## card can go there. The floating row's band is one too, drawn only as a faint wash.
class _Outline extends Button:
	const T = preload("res://ui/theme/tokens.gd")
	var state := "empty"

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			add_theme_stylebox_override(st, StyleBoxEmpty.new())

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size).grow(-2)
		if state == "floating":
			draw_rect(r, Color(T.FOCUS, 0.06), true)
			return
		var lit := state == "target" or state == "next"
		var colour: Color = T.FOCUS if lit else T.muted(T.FOCUS)
		if state == "inactive":
			colour = Color(T.INK_MUTED, 0.25)
		if lit:
			draw_rect(r, Color(T.FOCUS, 0.08 if state == "next" else 0.14), true)
		draw_rect(r, colour, false, 3.0 if lit else 2.0)


## Whether cards can be dragged into places now: while building, outside any mode.
func _can_drag() -> bool:
	return not _vs.is_empty() and _vs.get("mode", "") == "none" and not _vs.get("places", []).is_empty() 		and ["challenge", "final_journey", "final_enemy"].has(_vs.get("phase", ""))


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


## Let go: over a place or the floating row, the card is put there; anywhere else
## it glides home and nothing changes.
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


## The place (as the draft names it) or "floating" under a global point, or null.
func _drop_target(at: Vector2) -> Variant:
	var rects: Array = _plan.get("place_rects", [])
	var places: Array = _vs.get("places", [])
	# The places row is a card tall once any card is placed, else as tall as its
	# outlines (shorter when the floating cards need two rows).
	var any := places.any(func(p): return p.card_id != null)
	var h: float = _plan.card_size.y if any else Solver.outline_height(_plan, _vs.get("floating", []).size())
	for i in mini(rects.size(), places.size()):
		var r: Rect2 = rects[i]
		# The place and its section of the role strip above it both take the card.
		var top: float = _plan.regions.slots.position.y
		var column := Rect2(r.position.x, top, r.size.x, r.position.y + h - top)
		if column.grow(Solver.GAP / 2.0).has_point(at) and places[i].state != "inactive":
			var p: Dictionary = places[i]
			return "reserve" if p.role == "reserve" else [p.set, p.role]
	var band: Rect2 = _plan.regions.hand
	if band.has_point(at) and not rects.is_empty() and at.y > rects[0].position.y + h:
		return "floating"
	return null


## The tucked card that travels with a fused card, if any.
func _partners(id: String) -> Array:
	var out := []
	var f = _vs.get("cards", {}).get(id, {}).get("fuse")
	if f != null and f.part == "top" and _cards.has(f.other):
		out.append(_cards[f.other])
	return out
