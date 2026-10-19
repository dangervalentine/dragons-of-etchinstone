extends Control
## The notes laid on the Deck in the card's place (specs/015 contracts/note-pile.md),
## each a card of its own: the result of the set just played, a step to follow, the
## Soak, the XP to spend, and on top of them all a refused move's reason. Each is
## dealt on from off the left of the screen, turning as it comes and lying square as
## it lands, over whatever lies there already; those under it lie a little askew, so
## their corners show. Once nothing is wanted any more the whole pile is thrown off
## to the left as one discard; a refused move's card is thrown alone. Pressed and
## held, the pile lifts aside to show the card under it. The pile does not clip, so
## a card is seen crossing the Deck's edge (deck_stack.gd keeps its clip on _table).

signal intent(data: Dictionary)

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const TableNote = preload("res://ui/widgets/table_note.gd")
const PreviewPanel = preload("res://ui/widgets/preview_panel.gd")
const SoakMeter = preload("res://ui/widgets/soak_meter.gd")
const XpPurse = preload("res://ui/widgets/xp_purse.gd")

## The cards lying on the Deck, bottom to top; a refused move's card is not one.
var cards: Array = []
## A refused move's card, on top of the rest while it lies there.
var refusal_card: Control = null
## Cards being thrown off, freed as they land.
var leaving: Array = []
## Where a card lies: the face, or while the Deck is prepared, the raised card's place.
var rest := Rect2()
## Whether a press holds the pile aside.
var lifted := false
## Fills a card with its kind for a state (the result from the state it was played
## in); the tests swap it for one that needs no game.
var fill: Callable
var _spares := {}
var _tweens := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	fill = _fill


# ---------------------------------------------------------------- the rules (pure)

## What to do when `wanted` (DeckStack.note_kinds) is asked for with `pile` lying,
## bottom to top: how many cards to throw off the top, and which kinds to deal on.
## Nothing wanted is the end of it all, and the whole pile goes; the last kind
## wanted lying under others is an undo back to it, and those above it go; then each
## kind wanted and not lying is dealt, in order.
static func plan(pile: Array, wanted: Array) -> Dictionary:
	if wanted.is_empty():
		return {"throw": pile.size(), "deal": []}
	var throw := 0
	var at := pile.rfind(wanted.back())
	if at >= 0:
		throw = pile.size() - 1 - at
	var staying := pile.slice(0, pile.size() - throw)
	return {"throw": throw, "deal": wanted.filter(func(k): return not staying.has(k))}


## The tilt, in radians, of a card `depth` under the top one.
static func tilt(depth: int) -> float:
	return deg_to_rad(T.NOTE_TILT[mini(depth, T.NOTE_TILT.size() - 1)])


## Where a card is off the table: left of the screen by a card's width and a fifth,
## level with where it lies, for a pile whose left edge is at `global_x`.
static func off_table(at: Rect2, global_x: float) -> Vector2:
	return Vector2(-global_x - 1.2 * at.size.x, at.position.y)


# ---------------------------------------------------------------- what lies here

## The kinds lying, bottom to top.
func kinds() -> Array:
	return cards.map(func(c): return c.get_meta("kind"))


func card(kind: String) -> Control:
	for c in cards:
		if c.get_meta("kind") == kind:
			return c
	return null


## The top card of the pile, a refused move's card aside.
func top() -> Control:
	return cards.back() if not cards.is_empty() else null


func is_showing() -> bool:
	return not cards.is_empty() or refusal_card != null


func refusal_text() -> String:
	return refusal_card.refusal if refusal_card != null else ""


## The panel `name` ("preview", "soak_meter", "xp_purse") on the card that shows it;
## with no such card, a hidden spare, so whoever asks finds it not showing.
func panel(name: String) -> Control:
	var c: Control = null
	match name:
		"preview":
			for k in ["result", "mode", "setup"]:
				if c == null:
					c = card(k)
		"soak_meter":
			c = card("soak")
		"xp_purse":
			c = card("upgrade")
	if c != null:
		return c.get(name)
	if not _spares.has(name):
		var spare: Control = {"preview": PreviewPanel, "soak_meter": SoakMeter, "xp_purse": XpPurse}[name].new()
		spare.visible = false
		add_child(spare)
		_spares[name] = spare
	return _spares[name]


# ---------------------------------------------------------------- dealing and throwing

## Bring the pile to what `wanted` asks for (plan()), and show each card still
## wanted as it stands in `vs`.
func sync(wanted: Array, vs: Dictionary, result_vs: Dictionary, animate: bool) -> void:
	var p := plan(kinds(), wanted)
	if p.throw > 0:
		throw_top(p.throw, animate)
	for c in cards:
		if wanted.has(c.get_meta("kind")):
			fill.call(c, c.get_meta("kind"), vs, result_vs)
	for k in p.deal:
		deal(k, vs, result_vs, animate)


## Lay a card of `kind` on top of the pile.
func deal(kind: String, vs: Dictionary, result_vs: Dictionary, animate: bool) -> void:
	var c := _new_card()
	c.set_meta("kind", kind)
	fill.call(c, kind, vs, result_vs)
	cards.append(c)
	if refusal_card != null:
		move_child(refusal_card, -1)
	_arrive(c, animate)


## Throw the top `n` cards off as one discard; the whole pile takes a refused move's
## card lying on it too.
func throw_top(n: int, animate: bool) -> void:
	var out := []
	if n >= cards.size() and refusal_card != null:
		out.append(refusal_card)
		refusal_card = null
	for i in mini(n, cards.size()):
		out.append(cards.pop_back())
	for i in out.size():
		_leave(out[i], animate, i * T.NOTE_PILE_STAGGER)
	_lie_down(animate)


func throw_all(animate: bool) -> void:
	throw_top(cards.size(), animate)


## A refused move's reason on a card of its own on top; another refusal while it
## lies there only changes what it says.
func show_refusal(text: String, animate: bool) -> void:
	if refusal_card != null:
		refusal_card.set_refusal(text)
		return
	refusal_card = _new_card()
	refusal_card.set_meta("kind", "refusal")
	refusal_card.set_refusal(text)
	_arrive(refusal_card, animate)


func clear_refusal(animate: bool) -> void:
	if refusal_card == null:
		return
	var c := refusal_card
	refusal_card = null
	_leave(c, animate, 0.0)
	_lie_down(animate)


## Pressed and held, the pile lifts aside to show the card under it; let go, it
## lies back down. Never a move in the game.
func lift(on: bool) -> void:
	if not is_showing() or on == lifted:
		return
	lifted = on
	for c in _lying():
		var tw := _tween_for(c).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if not UI.reduced_motion:
			tw.tween_property(c, "position", _place_of(c), T.FAST)
		tw.tween_property(c, "modulate:a", 0.25 if on else 1.0, T.FAST)


# ---------------------------------------------------------------- laying out and settling

## Where cards lie, as the Deck lays itself out. A new place lands whatever is still
## being dealt or straightened at once; cards being thrown keep to their path.
func lay_out(at: Rect2) -> void:
	var moved := at != rest
	rest = at
	for c in _lying():
		if moved or not _moving(c):
			_kill(c)
			_pose(c)


## Every flight lands at once: dealt cards lie in their places, thrown ones are gone.
func finish() -> void:
	for c in leaving.duplicate():
		_free(c)
	lifted = false
	for c in _lying():
		_kill(c)
		_pose(c)


# ---------------------------------------------------------------- motion

func _arrive(c: Control, animate: bool) -> void:
	lifted = false
	if not animate:
		_pose(c)
		_lie_down(false)
		return
	c.size = rest.size
	c.pivot_offset = rest.size / 2.0
	var tw := _tween_for(c).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if UI.reduced_motion:
		c.position = rest.position
		c.rotation = tilt(0)
		c.modulate.a = 0.0
		tw.tween_property(c, "modulate:a", 1.0, T.FAST)
	else:
		c.position = off_table(rest, global_position.x)
		c.rotation = -deg_to_rad(T.NOTE_TURN)
		c.modulate.a = 1.0
		tw.tween_property(c, "position", rest.position, T.NOTE_DEAL)
		tw.tween_property(c, "rotation", tilt(0), T.NOTE_DEAL)
	# The cards under it settle into their tilts as it lands on them.
	tw.chain().tween_callback(_lie_down.bind(true))


func _leave(c: Control, animate: bool, delay: float) -> void:
	_kill(c)
	leaving.append(c)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not animate:
		_free(c)
		return
	var tw := _tween_for(c).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if UI.reduced_motion:
		tw.tween_property(c, "modulate:a", 0.0, T.FAST)
	else:
		c.pivot_offset = c.size / 2.0
		tw.tween_property(c, "position", off_table(rest, global_position.x), T.NOTE_DISCARD).set_delay(delay)
		tw.tween_property(c, "rotation", c.rotation - deg_to_rad(T.NOTE_TURN), T.NOTE_DISCARD).set_delay(delay)
	tw.chain().tween_callback(_free.bind(c))


## Every card not in flight eases into its tilt and place for its depth.
func _lie_down(animate: bool) -> void:
	for c in _lying():
		if _moving(c):
			continue
		if not animate or UI.reduced_motion:
			_pose(c)
			continue
		var tw := _tween_for(c).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "rotation", tilt(_depth(c)), T.FAST)
		tw.tween_property(c, "position", _place_of(c), T.FAST)


func _pose(c: Control) -> void:
	c.size = rest.size
	c.pivot_offset = rest.size / 2.0
	c.position = _place_of(c)
	c.rotation = tilt(_depth(c))
	c.modulate.a = 0.25 if lifted else 1.0


func _place_of(_c: Control) -> Vector2:
	return rest.position + (Vector2(rest.size.x * 0.6, 0) if lifted and not UI.reduced_motion else Vector2.ZERO)


## How far under the top a lying card is: 0 for the top, a refused move's card
## counting as the top while it lies there.
func _depth(c: Control) -> int:
	if c == refusal_card:
		return 0
	return cards.size() - 1 - cards.find(c) + (1 if refusal_card != null else 0)


func _lying() -> Array:
	var out := cards.duplicate()
	if refusal_card != null:
		out.append(refusal_card)
	return out


func _new_card() -> Control:
	var c := TableNote.new()
	c.size = rest.size
	c.position = rest.position
	c.pivot_offset = rest.size / 2.0
	c.intent.connect(func(data): intent.emit(data))
	c.held.connect(lift)
	add_child(c)
	return c


func _fill(c: Control, kind: String, vs: Dictionary, result_vs: Dictionary) -> void:
	if kind == "result":
		c.result_vs = result_vs
	c.show_kinds([kind], vs)


func _tween_for(c: Control) -> Tween:
	_kill(c)
	var tw := create_tween().set_parallel(true)
	_tweens[c] = tw
	return tw


func _moving(c: Control) -> bool:
	var tw: Tween = _tweens.get(c)
	return tw != null and tw.is_valid() and tw.is_running()


func _kill(c: Control) -> void:
	var tw: Tween = _tweens.get(c)
	if tw != null and tw.is_valid():
		tw.kill()
	_tweens.erase(c)


func _free(c: Control) -> void:
	_kill(c)
	leaving.erase(c)
	if is_instance_valid(c):
		c.visible = false
		c.queue_free()
