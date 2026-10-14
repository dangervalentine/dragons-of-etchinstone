extends Control
## Owns the card nodes on the play screen, one per visible card, and puts each
## where it belongs: its place in the Hand, lifted when it fills a role, tucked
## behind its partner when fused. Cards keep their node while they stay visible,
## so they can glide from one place to the next.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const CardView = preload("res://ui/widgets/card_view.gd")
const Solver = preload("res://ui/model/layout_solver.gd")

signal intent(data: Dictionary)
signal hover(id: String, on: bool)

var _cards := {}
var _tweens: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func card(id: String) -> Control:
	return _cards.get(id)


func ids() -> Array:
	return _cards.keys()


## Bring the cards in line with the view state. `animate` glides moved cards;
## `arrive_from` (a global point) is where new cards come from, one after another.
func sync(vs: Dictionary, plan: Dictionary, animate := false, arrive_from = null) -> void:
	finish()
	var hand: Array = vs.hand
	var rects := Solver.card_rects(plan.regions.hand, plan.card_size, hand.size(), plan.hand_rows) if not hand.is_empty() else []
	for id in _cards.keys():
		if not hand.has(id):
			_cards[id].queue_free()
			_cards.erase(id)
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
			add_child(view)
			_cards[id] = view
		view.show_set_number = vs.sets.size() > 1
		view.set_model(m)
		var home: Rect2 = Rect2(rects[i].position - global_position, rects[i].size)
		if m.state == "assigned" or m.state == "selected" or m.get("fate", "") == "stays":
			home.position.y -= Solver.CARD_LIFT
		view.home = home
		view.z_index = 0
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
