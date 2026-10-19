extends Control
## The Deck on the left side of the play screen (specs/012, specs/013): the Mage
## Cards held as in the rulebook's left hand, with the Region Card on top (the Dragon
## Card in the Final Battle) and the Hand drawn from under it. It is all the left
## side holds. Back to front:
##   the card edges, as many as the Deck's depth (edges());
##   the Key Card, which rises from under the top card to show the Encounter it
##     names and any Hardship, then slides back (peek());
##   the top card, whole while the view is zoomed out;
##   the face being played against: the top card's panel for that Encounter, grown
##     to fill the left side with a few lines under it saying what its marks mean
##     (the landed face), or in the Final Battle the dragon's face;
##   a note laid over it all in the card's place while there is something else to
##     read: a step to follow, the result of a Play, the Soak, the XP to spend, a
##     refused move (table_note.gd).
## The settled view is always the face; the whole top card shows only while a
## sequence plays, which holds the view (hold_card) until its zoom_in lands.

signal intent(data: Dictionary)

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const DragonFace = preload("res://ui/widgets/dragon_face.gd")
const RegionCard = preload("res://ui/widgets/region_card.gd")
const RegionPanel = preload("res://ui/widgets/region_panel.gd")
const DragonCard = preload("res://ui/widgets/dragon_card.gd")
const CardFace = preload("res://ui/widgets/card_face.gd")
const TableNote = preload("res://ui/widgets/table_note.gd")
const StatChip = preload("res://ui/widgets/stat_chip.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const Glossary = preload("res://ui/model/glossary.gd")

## How far each card's edge shows below and to the right of the one above it.
const EDGE_STEP := 3.0
## The most edges drawn: 8 at a full Deck of 16, filling DECK_EDGE.
const EDGES_MAX := 8
## One line of the reading strip under the landed panel: a 44-unit disc, or a line
## of body text, and the gap after it.
const STRIP_LINE := 52.0
## The share of a zoom over which the landed face fades in (or out, zooming out).
const LAND_FADE := 0.35
## The phases in which a new Encounter is being played: a Play's result held on the
## note is done with by then.
const PLAYING := ["challenge", "poison", "final_journey", "final_enemy", "setup"]


## The face once zoomed in on a Region Encounter: the Region Card itself, drawn as
## large as the zoom made it (every part of it is a share of its size, so it stays
## sharp), clipped to the face, the Encounter's panel lit and the rest of the card
## stepped back round it; along the foot, the reading strip. Pressing it (not the
## panel's badges, which explain themselves) shows the Key Card that named it.
class LandedFace extends Control:
	signal intent(data: Dictionary)
	var card = load("res://ui/widgets/region_card.gd").new()
	## The lit panel, once set.
	var panel: Control = null
	var key := ""
	var strip := VBoxContainer.new()
	var _back := ColorRect.new()
	var _stone = load("res://ui/theme/stone_style.gd").new("well", 0.5)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		clip_contents = true
		add_child(card)
		_back.color = Color(0.06, 0.05, 0.09, 0.88)
		_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_back)
		strip.add_theme_constant_override("separation", 8)
		add_child(strip)
		_stone.changed.connect(queue_redraw)
		gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed and panel != null:
				intent.emit({"type": "inspect_key"}))

	## The card `m`, lit at `k`'s panel, which carries the Key Card's `hardship` and
	## explains its badges when pressed.
	func show_panel(m: Dictionary, k: String, p: Dictionary, hardship) -> void:
		card.render(m)
		key = k
		var v: Control = card.panel(k)
		if v != panel and panel != null and is_instance_valid(panel):
			panel.render(panel.panel, null, false)
			panel.set_live(false)
		panel = v
		if panel != null:
			if not panel.intent.is_connected(_relay):
				panel.intent.connect(_relay)
			panel.render(p, hardship, true)
		card.set_focus(k, 1.0)

	func lay_out(at: Dictionary) -> void:
		card.position = at.card.position
		card.size = at.card.size
		_back.position = at.strip.position
		_back.size = at.strip.size
		strip.position = at.strip.position + Vector2(16, 8)
		strip.size = Vector2(at.strip.size.x - 32, 0)

	func _relay(data: Dictionary) -> void:
		intent.emit(data)

	func centre() -> Vector2:
		return global_position + size / 2.0

	func _draw() -> void:
		draw_style_box(_stone, Rect2(Vector2.ZERO, size))


var landed := LandedFace.new()
var dragon_face := DragonFace.new()
var region_card := RegionCard.new()
var dragon_card := DragonCard.new()
var note := TableNote.new()

## "face" (zoomed in on `zoomed`) or "card" (the whole top card).
var view := "face"
## While true, render() refreshes what each layer shows but not the view or which
## top card is on show: the sequence playing moves them (data-model.md).
var held := false
## The Deck's count as drawn.
var count := 0
var vs := {}
## The sum and verdict of the set just played stay on the note from the tally until
## the next Encounter is being played (contracts/left-column.md).
var result_held := false
## Whether the note lies on the Deck, as last laid out.
var note_on := false

var _edges := Control.new()
var _peek_clip := Control.new()
var _peek := CardFace.new()
var _tops := Control.new()
var _faces := Control.new()
## The top card on show, and where the view is zoomed into on it.
var _shown_top = null
var zoomed := ""
## The rect the stack's edges hang from: the face's, or the top card's when zoomed out.
var _stack_rect := Rect2()
var _card_size := Vector2(190, 266)
var _tweens: Array = []
var _note_tween: Tween
## While the card grows into a panel or back: what else settles meanwhile (the Key
## Card sliding home) leaves it be.
var _zooming := false
var _refusal_timer := Timer.new()
var _strip_key := []


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in [_edges, _peek_clip, _tops, _faces]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
	_edges.draw.connect(_draw_edges)
	# Only what has risen above the top card shows; the rest of the Key Card is under it.
	_peek_clip.clip_contents = true
	_peek_clip.add_child(_peek)
	_peek.visible = false
	for top in [region_card, dragon_card]:
		_tops.add_child(top)
		top.visible = false
	for face in [landed, dragon_face]:
		_faces.add_child(face)
		face.visible = false
	landed.intent.connect(func(data): intent.emit(data))
	dragon_face.intent.connect(func(data): intent.emit(data))
	add_child(note)
	note.visible = false
	note.intent.connect(func(data): intent.emit(data))
	note.held.connect(_lift_note)
	_refusal_timer.one_shot = true
	_refusal_timer.timeout.connect(func(): clear_refusal())
	add_child(_refusal_timer)
	resized.connect(_place)


# ---------------------------------------------------------------- geometry (pure)

## How many card edges show under the top card for a Deck of `n`.
static func edges(n: int) -> int:
	if n <= 0:
		return 0
	return clampi(ceili(n / 2.0), 1, EDGES_MAX)


## Where the face sits on a Deck of `deck_size`: all of it but the edges' margin.
static func face_rect(deck_size: Vector2) -> Rect2:
	return Rect2(0, 0, deck_size.x - T.DECK_EDGE, deck_size.y - T.DECK_EDGE)


## How far the Deck dips while the Key Card rises from it: half the way, but no
## further than the margin under the face, so the card stays on the Deck.
static func dip(peek_h: float) -> float:
	return minf(float(T.DECK_EDGE), peek_h / 2.0)


## Where the top card sits. Zoomed out it is the printed card's shape (5 by 7) as
## wide as the face, or as tall as fits under the room the Key Card rises into, the
## rest of that rise being the Deck's dip (peek()), centred in what is left; the
## Dragon Card, with nothing rising from under it, the same shape in the whole face.
## Zoomed in it is the face's rect.
static func card_rect(deck_size: Vector2, v: String, peek_h: float) -> Rect2:
	var f := face_rect(deck_size)
	if v != "card":
		return f
	var room := maxf(0.0, peek_h - dip(peek_h)) if peek_h > 0.0 else 0.0
	var s := RegionCard.card_size(f.size.x)
	if s.y > f.size.y - room:
		s = Vector2((f.size.y - room) * RegionCard.ASPECT, f.size.y - room)
	var spare := f.size.y - room - s.y
	return Rect2(Vector2((f.size.x - s.x) / 2.0, room + spare / 2.0), s)


## How much a panel grows to fill the face: as much as fits both ways, as a printed
## panel is not the face's shape.
static func zoom_scale(face: Rect2, tile: Rect2) -> float:
	return minf(face.size.x / maxf(tile.size.x, 1.0), face.size.y / maxf(tile.size.y, 1.0))


## Where the Deck comes to rest zoomed in on `key` on a face of `face`: the reading
## strip of `strip_lines` lines along the face's foot; the panel as large as fits in
## the rest, keeping its printed shape, centred there; and the whole card, grown
## alike, where that puts it (most of it beyond the face, which clips it).
static func landing(face: Rect2, key: String, strip_lines: int) -> Dictionary:
	var strip_h := strip_lines * STRIP_LINE + T.M
	var strip := Rect2(face.position + Vector2(0, face.size.y - strip_h), Vector2(face.size.x, strip_h))
	var area := Rect2(face.position, Vector2(face.size.x, face.size.y - strip_h))
	var unit := RegionCard.card_size(1000.0)
	var pr := RegionCard.panel_rect(unit, key)
	var k := minf(area.size.x / pr.size.x, area.size.y / pr.size.y)
	var panel := Rect2(area.get_center() - pr.size * k / 2.0, pr.size * k)
	var card := Rect2(panel.position - pr.position * k, unit * k)
	# Where the card is larger than the room, it is moved (and the panel with it) so
	# none of the face above the strip is left bare: a top-row panel sits a little
	# higher on a tall face.
	var shift := Vector2.ZERO
	for axis in [0, 1]:
		if card.size[axis] >= area.size[axis]:
			if card.position[axis] > area.position[axis]:
				shift[axis] = area.position[axis] - card.position[axis]
			elif card.end[axis] < area.end[axis]:
				shift[axis] = area.end[axis] - card.end[axis]
	panel.position += shift
	card.position += shift
	return {"strip": strip, "panel": panel, "card": card}


## Which note lies on the Deck: a refused move's reason over all else; then, set
## out together, what the state asks for (a step to follow, the Soak, the XP) and
## any result held from the last Play.
static func note_kinds(state_note, result: bool) -> Array:
	var out := []
	if result:
		out.append("result")
	if state_note != null:
		out.append(state_note.kind)
	return out


## How far a Key Card of `card_size` rises to show its title band and Key Card
## strip (card_face.gd's geometry), and no more.
static func peek_h(card_size: Vector2) -> float:
	return roundf(card_size.y * 0.155) + roundf(card_size.y * 0.09)


# ---------------------------------------------------------------- state

## The Hand's card size, which the Key Card is drawn at.
func set_card_size(s: Vector2) -> void:
	if s.x > 0.0 and s != _card_size:
		_card_size = s
		_place()


func render(state: Dictionary) -> void:
	vs = state
	count = state.piles.deck
	if result_held and PLAYING.has(state.phase):
		result_held = false
	_render_faces()
	if not held:
		_show_top(state.top_card)
		zoomed = state.zoom
		view = "face" if state.zoom != "" or state.top_card == null else "card"
		_hold_faces(false)
	_place()
	_update_note(is_inside_tree())


## Zoomed out at once, with no motion: the start of a game, before its first reveal.
func show_card() -> void:
	held = true
	view = "card"
	_hold_faces(true)
	_place()


func hold_card(on: bool) -> void:
	held = on


func set_count(n: int) -> void:
	count = n
	_edges.queue_redraw()


func bump(delta: int) -> void:
	set_count(maxi(0, count + delta))


## Stop everything in motion and show the current state exactly.
func finish() -> void:
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens = []
	held = false
	_zooming = false
	_clip_tops(false)
	region_card.set_focus("", 0.0)
	for c in [region_card, dragon_card, landed, dragon_face, _peek]:
		c.scale = Vector2.ONE
		c.modulate.a = 1.0
	_peek.visible = false
	if not vs.is_empty():
		render(vs)


## The visible face: the one zoomed into, or with none (the Deck being prepared)
## the note lying in its place.
func face_node() -> Control:
	for face in [landed, dragon_face]:
		if face.visible:
			return face
	return note if note_on else self


func top_node() -> Control:
	if _shown_top == null:
		return null
	return dragon_card if _shown_top.kind == "dragon" else region_card


## Global points cards travel to and from: under the top card's top edge, where
## the Key Card sits and the Hand is drawn from; and the back of the Deck.
func top_point() -> Vector2:
	var r := card_rect(size, view, _peek_h())
	return global_position + Vector2(r.get_center().x, r.position.y + 8.0)


func back_point() -> Vector2:
	var f := face_rect(size)
	var n := edges(count)
	return global_position + f.end + Vector2.ONE * (EDGE_STEP * n if n > 0 else T.DECK_EDGE * 0.5)


## The note's centre, where numbers fly to and from it.
func note_point() -> Vector2:
	return note.global_position + note.size / 2.0


func _peek_h() -> float:
	var top = _shown_top if _shown_top != null else vs.get("top_card")
	return peek_h(_card_size) if top != null and top.kind == "region" else 0.0


func _show_top(m) -> void:
	_shown_top = m.duplicate(true) if m != null else null
	_render_top()


func _render_top() -> void:
	region_card.visible = false
	dragon_card.visible = false
	if _shown_top == null:
		return
	if _shown_top.kind == "dragon":
		dragon_card.render(_shown_top)
	else:
		region_card.render(_shown_top)


## The panel of the top card for `key`, as the model has it.
func _panel_model(key: String) -> Dictionary:
	var top = vs.get("top_card")
	if top == null or top.kind != "region":
		return {}
	for p in top.panels:
		if p.key == key:
			return p
	return {}


## The Key Card's Hardship on the Encounter: whichever of its effects is not the
## Encounter's own Ability or Peril.
static func hardship_of(enc: Dictionary, panel: Dictionary):
	for e in enc.get("effects", []):
		if e != panel.get("effect"):
			return e
	return null


func _render_faces() -> void:
	if vs.is_empty():
		return
	var enc = vs.get("encounter")
	landed.visible = false
	dragon_face.visible = false
	if enc != null and (enc.kind == "enemy" or enc.kind == "journey"):
		var key := "%s:%d" % [enc.kind, enc.index]
		var p := _panel_model(key)
		if not p.is_empty():
			landed.show_panel(vs.top_card, key, p, hardship_of(enc, p))
			_render_strip(enc, p)
			landed.visible = true
	elif enc != null and enc.kind.begins_with("final"):
		dragon_face.render(enc)
		# No tier is lit before Play: the cards show what counts (specs/011 FR-001).
		dragon_face.set_reached(-1)
		dragon_face.visible = true


## What the panel's marks mean, under it (contracts/region-card-face.md): which
## Encounter it is, then the Key Card's Hardship and the Encounter's own Ability or
## Peril, each beside the disc the panel shows for it.
func _render_strip(enc: Dictionary, p: Dictionary) -> void:
	var hardship = hardship_of(enc, p)
	var key := [p.key, enc.title, hardship, p.effect]
	if key == _strip_key:
		return
	_strip_key = key
	for c in landed.strip.get_children():
		landed.strip.remove_child(c)
		c.queue_free()
	var head := UI.hbox(T.S)
	head.add_child(UI.icon_rect(p.kind, 34, T.ether_ink(p.element)))
	head.add_child(UI.label(str(p.index), T.SUBHEAD, T.ether_ink(p.element)))
	var title := UI.label(enc.title.to_upper(), T.SUBHEAD, T.INK)
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	UI.ignore_mouse(head)
	landed.strip.add_child(head)
	for id in [hardship, p.effect]:
		if id == null:
			continue
		var e: Dictionary = Glossary.entry(id)
		var row := UI.hbox(T.S)
		var disc: Control = StatChip.make({"icon": e.icon, "text": "", "color": T.INK, "glossary_id": id, "min_size": Vector2(44, 44)})
		disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		disc.help.connect(func(gid, source): intent.emit({"type": "help", "id": gid, "source": source}))
		row.add_child(disc)
		var words := UI.label("%s: %s" % [e.name, e.short] if e.short != "" else e.name, T.BODY, T.INK, true)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(words)
		landed.strip.add_child(row)


func _strip_lines() -> int:
	return maxi(1, landed.strip.get_child_count())


## The landed face's layout on a face rect `f`, in `f`'s own coordinates.
func _landing(f: Rect2) -> Dictionary:
	var key: String = landed.key if landed.key != "" else "enemy:1"
	return landing(f, key, _strip_lines())


## Lay every layer out for the current view, with nothing in motion.
func _place() -> void:
	var f := face_rect(size)
	for c in [_edges, _tops, _faces]:
		c.position = Vector2.ZERO
		c.size = size
	# While the card grows in or out of a panel it is clipped to the face, as the
	# landed face is.
	if _tops.clip_contents:
		_tops.size = f.size
	var cr := card_rect(size, view, _peek_h())
	# The Key Card never shows below the top card, which covers the rest of it.
	_peek_clip.position = Vector2.ZERO
	_peek_clip.size = Vector2(size.x, maxf(cr.end.y, 0.0))
	for face in [landed, dragon_face]:
		face.position = f.position
		face.size = f.size
		face.pivot_offset = f.size / 2.0
	landed.lay_out(_landing(Rect2(Vector2.ZERO, f.size)))
	note.position = f.position
	note.size = f.size
	_render_top()
	var top: Control = top_node()
	if top != null:
		top.position = cr.position
		top.size = cr.size
		top.pivot_offset = cr.size / 2.0
		top.visible = view == "card"
	var showing_face := view == "face" or _shown_top == null
	if showing_face:
		_render_faces()
	else:
		for face in [landed, dragon_face]:
			face.visible = false
	_stack_rect = f if showing_face else cr
	_edges.queue_redraw()


func _draw_edges() -> void:
	var n := edges(count)
	for i in range(n, 0, -1):
		var r := _stack_rect
		r.position += Vector2.ONE * EDGE_STEP * i
		_edges.draw_rect(r, T.BG_RAISED)
		_edges.draw_rect(r, T.BRONZE_DARK, false, 1.5)


func _hold_faces(on: bool) -> void:
	if landed.panel != null:
		landed.panel.set_live(not on)
	dragon_face.set_held(on)


func _keep(tw: Tween) -> Tween:
	_tweens.append(tw)
	return tw


func _set_stack_rect(r: Rect2) -> void:
	_stack_rect = r
	_edges.queue_redraw()


## The rect of `target` on the shown top card, in the Deck's own coordinates, for a
## top card at `cr`.
func _target_rect(target: String, cr: Rect2) -> Rect2:
	var f := face_rect(size)
	var r: Rect2
	if target == "mp" or target == "hp":
		r = DragonCard.target_rect(cr.size, target, f.size.x / maxf(f.size.y, 1.0))
	else:
		r = RegionCard.panel_rect(cr.size, target)
	return Rect2(cr.position + r.position, r.size)


# ---------------------------------------------------------------- the note

## Lay the note on the Deck, take it off, or change what it says, for the state on
## show (contracts/left-column.md "The note").
func _update_note(animate: bool) -> void:
	if vs.is_empty():
		return
	var kinds := note_kinds(vs.get("note"), result_held)
	var showing := note.refusal != "" or not kinds.is_empty()
	var changed: bool = kinds != note.kinds
	if not kinds.is_empty() or note.refusal != "":
		note.show_kinds(kinds, vs)
	else:
		note.kinds = []
	if showing != note_on:
		_slide_note(showing, animate)
	elif showing and changed and animate and not UI.reduced_motion:
		note.modulate.a = 0.6
		_note_to(note.position, 1.0, T.FAST)


## The sum of the set just played comes onto the note (the animator's tally).
func show_result() -> void:
	result_held = true
	if vs.is_empty():
		return
	note.result_vs = vs
	note.show_kinds(note_kinds(vs.get("note"), true), vs)
	if not note_on:
		_slide_note(true, is_inside_tree())


## Done with the result before the Deck zooms out to the next Encounter.
func clear_result(d: float) -> void:
	if not result_held:
		return
	result_held = false
	var kinds := note_kinds(vs.get("note"), false)
	if kinds.is_empty() and note.refusal == "":
		_slide_note(false, is_inside_tree(), d)
	else:
		note.show_kinds(kinds, vs)


## A refused move's reason lies on the Deck for a moment (T.NOTE_HOLD), or until
## the player does something else.
func show_refusal(text: String) -> void:
	if text == "":
		return
	note.set_refusal(text)
	if not note_on:
		_slide_note(true, is_inside_tree())
	_refusal_timer.start(T.NOTE_HOLD)


func clear_refusal() -> void:
	if note.refusal == "":
		return
	_refusal_timer.stop()
	note.set_refusal("")
	if not vs.is_empty():
		note.show_kinds(note_kinds(vs.get("note"), result_held), vs)
	if note.kinds.is_empty():
		_slide_note(false, is_inside_tree())


func _slide_note(on: bool, animate: bool, d: float = T.BASE) -> void:
	note_on = on
	var f := face_rect(size)
	if _note_tween != null and _note_tween.is_valid():
		_note_tween.kill()
	if not animate:
		note.visible = on
		note.position = f.position
		note.modulate.a = 1.0
		return
	note.visible = true
	var away := f.position + Vector2(T.DECK_EDGE, 0)
	if on:
		note.position = f.position if UI.reduced_motion else away
		note.modulate.a = 0.0
		_note_to(f.position, 1.0, d)
	else:
		_note_to(f.position if UI.reduced_motion else away, 0.0, d)
		_note_tween.tween_callback(func():
			if not note_on:
				note.visible = false
				note.position = f.position
				note.modulate.a = 1.0)


func _note_to(at: Vector2, alpha: float, d: float) -> void:
	_note_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not UI.reduced_motion:
		_note_tween.tween_property(note, "position", at, d)
	_note_tween.tween_property(note, "modulate:a", alpha, d)
	_note_tween.set_parallel(false)


## Pressed and held, the note lifts aside to show the card under it; let go, it
## lies back down. Never a move in the game.
func _lift_note(on: bool) -> void:
	if not note_on:
		return
	var f := face_rect(size)
	if on:
		var aside := f.position + Vector2(f.size.x * 0.6, 0)
		_note_to(f.position if UI.reduced_motion else aside, 0.15 if UI.reduced_motion else 0.25, T.FAST)
	else:
		_note_to(f.position, 1.0, T.FAST)


# ---------------------------------------------------------------- motion

## From the face out to the whole top card. A Region Encounter's landed panel is
## the card's own panel grown, so the card simply shrinks back from it.
func zoom_out(d: float) -> void:
	held = true
	clear_result(d * 0.3)
	var top: Control = top_node()
	if view != "face" or top == null or zoomed == "":
		view = "card"
		_place()
		return
	_hold_faces(true)
	var face: Control = face_node()
	var f := face_rect(size)
	var cr := card_rect(size, "card", _peek_h())
	var tile := _target_rect(zoomed, cr)
	view = "card"
	top.position = cr.position
	top.size = cr.size
	top.visible = true
	if UI.reduced_motion:
		top.modulate.a = 0.0
		var tw := _keep(create_tween().set_parallel(true))
		tw.tween_property(top, "modulate:a", 1.0, d)
		tw.tween_property(face, "modulate:a", 0.0, d)
		tw.chain().tween_callback(_settle_view)
		return
	var pivot := tile.get_center() - cr.position
	top.pivot_offset = pivot
	var tw := _keep(create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT))
	if face == landed:
		# The card starts exactly as the landed face draws it, and shrinks back to its
		# place on the Deck as the rest of it comes back up round the panel.
		var at := _landing(f)
		_zooming = true
		_clip_tops(true)
		top.pivot_offset = Vector2.ZERO
		_card_at(at.card.position + f.position, at.card.size)
		top.modulate.a = 1.0
		region_card.set_focus(zoomed, 1.0)
		face.visible = false
		tw.tween_method(func(v: float):
			var r := _lerp_rect(Rect2(at.card.position + f.position, at.card.size), cr, v)
			_card_at(r.position, r.size)
			region_card.set_focus(zoomed, 1.0 - v), 0.0, 1.0, d)
		tw.tween_method(_set_stack_rect, f, cr, d)
		tw.chain().tween_callback(func():
			_zooming = false
			_settle_view())
		return
	else:
		var k := zoom_scale(f, tile)
		top.scale = Vector2.ONE * k
		top.position = f.get_center() - pivot
		top.modulate.a = 0.0
		face.pivot_offset = f.size / 2.0
		tw.tween_property(top, "modulate:a", 1.0, d * 0.4)
		tw.tween_property(face, "scale", Vector2.ONE / k, d)
		tw.tween_property(face, "position", tile.get_center() - f.size / 2.0, d)
		tw.tween_property(face, "modulate:a", 0.0, d * 0.4).set_delay(d * 0.6)
	tw.tween_property(top, "scale", Vector2.ONE, d)
	tw.tween_property(top, "position", cr.position, d)
	tw.tween_method(_set_stack_rect, f, cr, d)
	tw.chain().tween_callback(_settle_view)


## From the whole top card into `target`. A Region Encounter's panel grows until it
## lies exactly where the landed panel sits, which then takes its place, with the
## lines under it fading in; in the Final Battle the dragon's face grows out of the
## Tiers. The face's creature wakes as it lands.
func zoom_in(target: String, d: float) -> void:
	# Without a turn of the card first (a skipped one), the right card is simply on
	# top when the zoom starts.
	if vs.get("top_card") != null and _shown_top != vs.top_card:
		_show_top(vs.top_card)
	var top: Control = top_node()
	zoomed = target
	if top == null or view != "card":
		_land()
		return
	_render_faces()
	_hold_faces(true)
	var face: Control = face_node()
	var f := face_rect(size)
	var cr := card_rect(size, "card", _peek_h())
	var tile := _target_rect(target, cr)
	face.position = f.position
	face.size = f.size
	face.visible = true
	if UI.reduced_motion:
		face.modulate.a = 0.0
		var tw := _keep(create_tween().set_parallel(true))
		tw.tween_property(face, "modulate:a", 1.0, d)
		tw.tween_property(top, "modulate:a", 0.0, d)
		tw.chain().tween_callback(_land)
		return
	var pivot := tile.get_center() - cr.position
	top.pivot_offset = pivot
	var tw := _keep(create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT))
	if face == landed:
		# The card itself grows, drawn at each size rather than scaled, until it lies
		# exactly as the landed face draws it; the landed face then takes over.
		_zooming = true
		_clip_tops(true)
		landed.lay_out(_landing(Rect2(Vector2.ZERO, f.size)))
		var at := _landing(f)
		top.pivot_offset = Vector2.ZERO
		face.modulate.a = 0.0
		tw.tween_method(func(v: float):
			var r := _lerp_rect(cr, Rect2(at.card.position + f.position, at.card.size), v)
			_card_at(r.position, r.size)
			region_card.set_focus(target, v), 0.0, 1.0, d)
		tw.tween_property(face, "modulate:a", 1.0, d * LAND_FADE).set_delay(d * (1.0 - LAND_FADE))
		tw.tween_method(_set_stack_rect, cr, f, d)
		tw.chain().tween_callback(_land)
		return
	else:
		var k := zoom_scale(f, tile)
		face.pivot_offset = f.size / 2.0
		face.scale = Vector2.ONE / k
		face.position = tile.get_center() - f.size / 2.0
		face.modulate.a = 0.0
		tw.tween_property(top, "scale", Vector2.ONE * k, d)
		tw.tween_property(top, "position", f.get_center() - pivot, d)
		tw.tween_property(top, "modulate:a", 0.0, d * 0.4).set_delay(d * 0.6)
		tw.tween_property(face, "scale", Vector2.ONE, d)
		tw.tween_property(face, "position", f.position, d)
		tw.tween_property(face, "modulate:a", 1.0, d * 0.4)
	tw.tween_method(_set_stack_rect, cr, f, d)
	tw.chain().tween_callback(_land)


## The top card at `at`, `size`, laid out afresh (not scaled), so it stays sharp.
func _card_at(at: Vector2, card_size: Vector2) -> void:
	var top: Control = top_node()
	top.scale = Vector2.ONE
	top.position = at
	top.size = card_size


func _clip_tops(on: bool) -> void:
	_tops.clip_contents = on
	_tops.size = face_rect(size).size if on else size


static func _lerp_rect(a: Rect2, b: Rect2, v: float) -> Rect2:
	return Rect2(a.position.lerp(b.position, v), a.size.lerp(b.size, v))


func _settle_view() -> void:
	if _zooming:
		return
	for c in [region_card, dragon_card, landed, dragon_face]:
		c.scale = Vector2.ONE
		c.modulate.a = 1.0
	region_card.set_focus("", 0.0)
	_clip_tops(false)
	_place()


func _land() -> void:
	_zooming = false
	view = "face"
	held = false
	_settle_view()
	_hold_faces(false)


## The card on top changes: placed on the Deck at the start, turned over to the
## other Region on the same card, or swapped for the other card (or the dragon's).
func turn_to(m, d: float) -> void:
	if m == null:
		return
	var was = _shown_top
	view = "card"
	var cr := card_rect(size, "card", peek_h(_card_size) if m.kind == "region" else 0.0)
	if UI.reduced_motion or was == null:
		_show_top(m)
		_place()
		var top: Control = top_node()
		top.modulate.a = 0.0
		var tw := _keep(create_tween().set_parallel(true))
		tw.tween_property(top, "modulate:a", 1.0, d)
		if not UI.reduced_motion:
			# Laid on top of the Deck from just above it.
			top.position = cr.position - Vector2(0, T.DECK_EDGE)
			tw.tween_property(top, "position", cr.position, d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(_settle_view)
		return
	var old: Control = top_node()
	var same_card: bool = was.kind == "region" and m.kind == "region" and was.pair == m.pair
	var tw := _keep(create_tween().set_trans(Tween.TRANS_QUAD))
	if same_card:
		# Turned end over end to the card's other Region.
		old.pivot_offset = old.size / 2.0
		tw.tween_property(old, "scale:y", 0.0, d / 2.0).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			_show_top(m)
			_place()
			var top: Control = top_node()
			top.scale.y = 0.0)
		tw.tween_method(func(v: float): top_node().scale.y = v, 0.0, 1.0, d / 2.0).set_ease(Tween.EASE_OUT)
	else:
		# The old card goes to the back; the next comes up from behind the Deck.
		var away := old.position + Vector2.ONE * T.DECK_EDGE
		tw.tween_property(old, "position", away, d / 2.0).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(old, "modulate:a", 0.0, d / 2.0)
		tw.tween_callback(func():
			old.modulate.a = 1.0
			_show_top(m)
			_place()
			var top: Control = top_node()
			top.position = cr.position + Vector2.ONE * T.DECK_EDGE
			top.modulate.a = 0.0)
		tw.tween_method(func(v: float):
			var top: Control = top_node()
			top.position = cr.position + Vector2.ONE * T.DECK_EDGE * (1.0 - v)
			top.modulate.a = v, 0.0, 1.0, d / 2.0).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_settle_view)


## The Key Card rises from under the Region Card just far enough to show the
## Encounter it names and any Hardship, holds, and slides back down. The Deck dips
## a little as it is drawn up (dip()), so the Region Card can stay large.
func peek(face_model, d: float) -> void:
	if face_model == null or _shown_top == null or _shown_top.kind != "region" or view != "card":
		return
	var cr := card_rect(size, "card", _peek_h())
	var ph := _peek_h()
	var down := dip(ph)
	_peek.size = _card_size
	_peek.set_model(face_model, ["encounter"])
	var x := cr.get_center().x - _card_size.x / 2.0
	var rest := Vector2(x, cr.position.y)
	var up := Vector2(x, cr.position.y + down - ph)
	_peek.visible = true
	var total := T.PEEK_RISE + T.PEEK_HOLD + T.PEEK_FALL
	var tw := _keep(create_tween())
	if UI.reduced_motion:
		# Already raised, the Deck already dipped, with no travel: it fades in, holds
		# and fades out.
		_dip_to(down, cr)
		_peek.position = up
		_peek.modulate.a = 0.0
		var fade := minf(T.FAST, d / 3.0)
		tw.tween_property(_peek, "modulate:a", 1.0, fade)
		tw.tween_interval(maxf(0.0, d - 2.0 * fade))
		tw.tween_property(_peek, "modulate:a", 0.0, fade)
	else:
		_peek.position = rest
		_peek.modulate.a = 1.0
		var rise := d * T.PEEK_RISE / total
		var fall := d * T.PEEK_FALL / total
		tw.tween_property(_peek, "position", up, rise).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_method(_dip_to.bind(cr), 0.0, down, rise).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_interval(d * T.PEEK_HOLD / total)
		tw.tween_property(_peek, "position", rest, fall).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.parallel().tween_method(_dip_to.bind(cr), down, 0.0, fall).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_peek.visible = false
		_peek.modulate.a = 1.0
		_settle_view())


## The top card and the edges under it, `by` below where they rest.
func _dip_to(by: float, cr: Rect2) -> void:
	var top: Control = top_node()
	if top != null:
		top.position = cr.position + Vector2(0, by)
	_set_stack_rect(Rect2(cr.position + Vector2(0, by), cr.size))
