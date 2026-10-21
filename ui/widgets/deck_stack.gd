extends Control
## The Deck on the left side of the play screen (specs/012, specs/013, specs/014):
## the Mage Cards held face up as in the rulebook's left hand, with the Region Card
## on top (the Dragon Card in the Final Battle) and the Hand drawn from under it,
## each card leaving at the top card's size (top_rect()). It is all the left side
## holds. Back to front:
##   the card edges, as many as the Deck's depth (edges()): rounded card-stock
##     sides with a soft shadow under them (_draw_edges());
##   the Key Card, as big as the Region Card, which rises from under it to show the
##     Encounter it names and any Hardship, lights its number and then that panel,
##     and stays up until zoom_in() slides it back down (peek());
##   the top card, whole while the view is zoomed out;
##   the face being played against: the top card's panel for that Encounter, grown
##     to fill the left side with a few lines under it saying what its marks mean
##     (the landed face), or in the Final Battle the dragon's face;
##   the notes laid over it all in the card's place while there is something else
##     to read, each a card of its own dealt on from the left and piled up: the
##     result of a Play, a step to follow, the Soak, the XP to spend, a refused move;
##     thrown off to the left together once done with (note_pile.gd, specs/015).
## The settled view is always the face; the whole top card shows only while a
## sequence plays, which holds the view (hold_card) until its zoom_in lands.

signal intent(data: Dictionary)
## Each beat of a reveal as it starts: "key_lit", "panel_lit", "zoom" (specs/014
## contracts/deck-motion.md), for tools/ui_check.gd to check their order.
signal reveal_beat(name: String)

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const DragonFace = preload("res://ui/widgets/dragon_face.gd")
const RegionCard = preload("res://ui/widgets/region_card.gd")
const RegionPanel = preload("res://ui/widgets/region_panel.gd")
const DragonCard = preload("res://ui/widgets/dragon_card.gd")
const CardFace = preload("res://ui/widgets/card_face.gd")
const NotePile = preload("res://ui/widgets/note_pile.gd")
const StatChip = preload("res://ui/widgets/stat_chip.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const Glossary = preload("res://ui/model/glossary.gd")

## How far each card's edge shows below and to the right of the one above it.
const EDGE_STEP := 3.0
## The most edges drawn: 8 at a full Deck of 16, filling DECK_EDGE.
const EDGES_MAX := 8
## Each edge's small, fixed offset from true, so the pile is a little uneven like a
## real one but never shimmers as it thins (specs/014 research R4). The deepest
## keeps inside the margin.
const JITTER := [Vector2(0, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(-1, 0),
	Vector2(0, 1), Vector2(-1, 0)]
## One line of the reading strip under the landed panel: a 44-unit disc, or a line
## of body text, and the gap after it.
const STRIP_LINE := 52.0
## The share of a card's height its band and strip take (peek_h()).
const PEEK_FRAC := 0.245
## The share of a zoom over which the landed face fades in (or out, zooming out).
const LAND_FADE := 0.35
## The phases in which a new Encounter is being played: a Play's result held on the
## note is done with by then.
const PLAYING := ["challenge", "poison", "final_journey", "final_enemy", "setup"]


## The face once zoomed in on a Region Encounter: the Region Card itself, drawn as
## large as the zoom made it (every part of it is a share of its size, so it stays
## sharp), clipped to the face, the Encounter's panel lit and the rest of the card
## stepped back round it; along the foot, the reading strip. Pressing it (not the
## panel's badges, which explain themselves) zooms back out to the whole card with
## the Key Card that named it risen over it (look_out()).
class LandedFace extends Control:
	signal intent(data: Dictionary)
	var card = load("res://ui/widgets/region_card.gd").new()
	## The lit panel, once set.
	var panel: Control = null
	var key := ""
	var strip := VBoxContainer.new()
	var _back := ColorRect.new()
	## The strip's own room under the panel, clipped at the panel's foot, so the strip
	## slides down into it from behind the art (slide_strip()).
	var _strip_room := Control.new()
	## How far above its place the strip is, sliding down.
	var _strip_up := 0.0
	var _strip_tween: Tween
	var _stone = load("res://ui/theme/stone_style.gd").new("well", 0.5)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		clip_contents = true
		# Its corners rounded as the card's are (specs/014): what it draws masks the card.
		clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		card.set_numbers(0.0)
		add_child(card)
		_strip_room.clip_contents = true
		_strip_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_strip_room)
		_back.color = Color(0.06, 0.05, 0.09, 0.88)
		_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_strip_room.add_child(_back)
		strip.add_theme_constant_override("separation", 8)
		_strip_room.add_child(strip)
		_stone.changed.connect(queue_redraw)
		gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed and panel != null:
				intent.emit({"type": "look_out"}))

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
		_strip_room.position = at.strip.position
		_strip_room.size = at.strip.size
		_back.size = at.strip.size
		strip.size = Vector2(at.strip.size.x - 32, 0)
		_place_strip(_strip_up)

	func _place_strip(up: float) -> void:
		_strip_up = up
		_back.position = Vector2(0, -up)
		strip.position = Vector2(16, 8 - up)

	## The strip slides down from behind the panel's foot into its place after
	## `delay`, over `d`.
	func slide_strip(delay: float, d: float) -> void:
		settle_strip()
		_place_strip(_strip_room.size.y)
		_strip_tween = create_tween()
		_strip_tween.tween_interval(delay)
		_strip_tween.tween_method(_place_strip, _strip_room.size.y, 0.0, d).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	## The strip in its place, any slide stopped.
	func settle_strip() -> void:
		if _strip_tween != null and _strip_tween.is_valid():
			_strip_tween.kill()
		_place_strip(0.0)

	func _relay(data: Dictionary) -> void:
		intent.emit(data)

	func centre() -> Vector2:
		return global_position + size / 2.0

	func _draw() -> void:
		draw_style_box(UI.box(T.BG_RAISED, Color.TRANSPARENT, 0, UI.card_radius(size.x), 0), Rect2(Vector2.ZERO, size))


var landed := LandedFace.new()
var dragon_face := DragonFace.new()
var region_card := RegionCard.new()
var dragon_card := DragonCard.new()
## The notes lying on the Deck (specs/015).
var pile := NotePile.new()

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
## Whether a note lies on the Deck.
var note_on: bool:
	get:
		return pile.is_showing()

## The Deck's own cards, clipped to it; the notes lie outside it, so a note is seen
## crossing the Deck's edge as it is dealt or thrown (specs/015 research R3).
var _table := Control.new()
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
var _tweens: Array = []
## The state the set just played was played in: the result is built from it.
var _result_vs := {}
## Which Encounter the notes lying on the Deck belong to; and the Encounter, phase
## and notes wanted when the Deck zoomed out of it, whose notes are done with until
## anything else is wanted.
var _note_key := ""
var _closed_key := ""
## While the card grows into a panel or back: what else settles meanwhile (the Key
## Card sliding home) leaves it be.
var _zooming := false
## How far the top card and the edges have dipped for the Key Card, while it is up.
var _dip := 0.0
## Whether the Key Card is up, waiting for zoom_in() to slide it back down.
var _peek_up := false
var _strip_key := []
## Whether the player has zoomed out of the Encounter to look at the whole card,
## the Key Card risen over it, until a press zooms back in (look_out()).
var _looking := false
## Over the Deck while looking: any press on it zooms back in.
var _catch := Control.new()


func _init() -> void:
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_table.clip_contents = true
	_table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_table)
	for c in [_edges, _peek_clip, _tops, _faces]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_table.add_child(c)
	_edges.draw.connect(_draw_edges)
	_tops.draw.connect(_draw_tops_mask)
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
	landed.intent.connect(func(data):
		if data.type == "look_out":
			look_out(T.ZOOM)
		else:
			intent.emit(data))
	_catch.mouse_filter = Control.MOUSE_FILTER_STOP
	_catch.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_catch.visible = false
	_catch.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			look_in(T.ZOOM))
	_table.add_child(_catch)
	dragon_face.intent.connect(func(data): intent.emit(data))
	add_child(pile)
	pile.intent.connect(func(data): intent.emit(data))
	resized.connect(_place)


# ---------------------------------------------------------------- geometry (pure)

## How many card edges show under the top card for a Deck of `n`.
static func edges(n: int) -> int:
	if n <= 0:
		return 0
	return clampi(ceili(n / 2.0), 1, EDGES_MAX)


## The corner radius of a card `width` wide, as a Mage Card draws its own
## (card_face.gd), so the top card, the Key Card and the Deck's edges match.
static func card_radius(width: float) -> int:
	return UI.card_radius(width)


## The pile's edges under a top card at `stack`, deepest first: as many as edges(n)
## says, each a card the size of the top one, a step further down and right and a
## little off true. Only the count goes in, so nothing about any card shows.
static func edge_rects(stack: Rect2, n: int) -> Array:
	var out := []
	for i in range(edges(n), 0, -1):
		out.append(Rect2(stack.position + Vector2.ONE * EDGE_STEP * i + JITTER[i - 1], stack.size))
	return out


## Where the face sits on a Deck of `deck_size`: all of it but the edges' margin.
static func face_rect(deck_size: Vector2) -> Rect2:
	return Rect2(0, 0, deck_size.x - T.DECK_EDGE, deck_size.y - T.DECK_EDGE)


## How far the Deck dips while the Key Card rises from it: half the way, but no
## further than the margin under the face, so the card stays on the Deck.
static func dip(peek_h: float) -> float:
	return minf(float(T.DECK_EDGE), peek_h / 2.0)


## Where the top card sits. Zoomed out it is the printed card's shape (5 by 7) as
## wide as the face, or as tall as fits under the room a Key Card of its own size
## rises into (`peek`: a Region Card), the rest of that rise being the Deck's dip
## (peek()), centred in what is left; the Dragon Card, with nothing rising from under
## it, the same shape in the whole face. Zoomed in it is the face's rect.
static func card_rect(deck_size: Vector2, v: String, peek := false) -> Rect2:
	var f := face_rect(deck_size)
	if v != "card":
		return f
	var s := RegionCard.card_size(f.size.x)
	var room := rise_room(s) if peek else 0.0
	if s.y > f.size.y - room:
		# As tall as h + room(h) allows, room(h) being PEEK_FRAC h less the dip: the
		# full margin once that is half the rise or less, else half the rise.
		var h := f.size.y
		if peek:
			h = (f.size.y + T.DECK_EDGE) / (1.0 + PEEK_FRAC)
			if PEEK_FRAC * h / 2.0 < T.DECK_EDGE:
				h = f.size.y / (1.0 + PEEK_FRAC / 2.0)
		h = floorf(h)
		s = Vector2(h * RegionCard.ASPECT, h)
		room = rise_room(s) if peek else 0.0
		# peek_h() rounds its band and strip; give back what that takes.
		while peek and s.y + room > f.size.y + 0.01 and h > 1.0:
			h -= 1.0
			s = Vector2(h * RegionCard.ASPECT, h)
			room = rise_room(s)
	var spare := maxf(0.0, f.size.y - room - s.y)
	return Rect2(Vector2((f.size.x - s.x) / 2.0, room + spare / 2.0), s)


## How much of a Key Card the size of `card` must rise above it: its band and strip,
## less the Deck's dip.
static func rise_room(card: Vector2) -> float:
	var ph := peek_h(card)
	return ph - dip(ph)


## The Key Card on a Deck of `deck_size`: the Region Card's own size and place, at
## rest under it or raised to show its band and strip, the Deck dipped meanwhile.
static func key_rect(deck_size: Vector2, raised: bool) -> Rect2:
	var cr := card_rect(deck_size, "card", true)
	var ph := peek_h(cr.size)
	var y := cr.position.y + (dip(ph) - ph if raised else 0.0)
	return Rect2(Vector2(cr.position.x, y), cr.size)


## How much a panel grows to fill the face: as much as fits both ways, as a printed
## panel is not the face's shape.
static func zoom_scale(face: Rect2, tile: Rect2) -> float:
	return minf(face.size.x / maxf(tile.size.x, 1.0), face.size.y / maxf(tile.size.y, 1.0))


## Where the Deck comes to rest zoomed in on `key` on a face of `face`: room for the
## reading strip of `strip_lines` lines kept along the face's foot; the panel as
## large as fits in the rest, keeping its printed shape, centred there; the strip
## itself right under the panel; and the whole card, grown alike, where that puts it
## (most of it beyond the face, which clips it).
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
	# The strip comes up to the panel's foot, however few its lines, so the name sits
	# right under the Encounter it names.
	strip.position.y = minf(strip.position.y, panel.end.y)
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
## strip (card_face.gd's geometry), and no more: about PEEK_FRAC of its height.
static func peek_h(card_size: Vector2) -> float:
	return roundf(card_size.y * 0.155) + roundf(card_size.y * 0.09)


# ---------------------------------------------------------------- state

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
	# Anything to read on the Deck brings the view back to the Encounter first.
	if _looking and note_on:
		look_in(T.ZOOM)


## Zoomed out at once, with no motion: the start of a game, before its first reveal.
func show_card() -> void:
	held = true
	view = "card"
	_hold_faces(true)
	if _peeks():
		_raise()
	_place()


## The Deck raised to where the Key Card rises to, as it starts a game: the first
## reveal brings it down as the Key Card comes up (peek()).
func _raise() -> void:
	_dip = -rise_room(card_rect(size, "card", true).size)


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
	_looking = false
	_catch.visible = false
	_clip_tops(false)
	region_card.set_focus("", 0.0)
	region_card.set_rim(0.0)
	region_card.set_numbers(1.0)
	_tops.z_index = 0
	z_index = 0
	_put_peek_away()
	for c in [region_card, dragon_card, landed, dragon_face, _peek]:
		c.scale = Vector2.ONE
		c.modulate = Color.WHITE
	_peek.visible = false
	pile.finish()
	if not vs.is_empty():
		render(vs)


## The visible face: the one zoomed into, or with none (the Deck being prepared)
## the note lying in its place.
func face_node() -> Control:
	for face in [landed, dragon_face]:
		if face.visible:
			return face
	return pile.top() if pile.top() != null else self


func top_node() -> Control:
	if _shown_top == null:
		return null
	return dragon_card if _shown_top.kind == "dragon" else region_card


## Global points cards travel to and from: under the top card's top edge, where
## the Key Card sits and the Hand is drawn from; and the back of the Deck.
func top_point() -> Vector2:
	var r := card_rect(size, view, _peeks())
	if view == "card":
		r.position.y += _dip
	return global_position + Vector2(r.get_center().x, r.position.y + 8.0)


func back_point() -> Vector2:
	var f := face_rect(size)
	var n := edges(count)
	return global_position + f.end + Vector2.ONE * (EDGE_STEP * n if n > 0 else T.DECK_EDGE * 0.5)


## The note's centre, where numbers fly to and from it.
func note_point() -> Vector2:
	return global_position + _note_rect().get_center()


## The panel `name` ("preview", "soak_meter", "xp_purse") on the note that shows it,
## or a hidden one with none (note_pile.gd).
func panel(name: String) -> Control:
	return pile.panel(name)


## Whether a Key Card rises from under the top card: a Region Card's, not the
## Dragon Card's.
func _peeks() -> bool:
	var top = _shown_top if _shown_top != null else vs.get("top_card")
	return top != null and top.kind == "region"


## The global rect of the whole top card resting on the Deck, zoomed out whatever
## the view, raised or dipped as it is: where every drawn card starts (specs/014
## research R1).
func top_rect() -> Rect2:
	var r := card_rect(size, "card", _peeks())
	return Rect2(global_position + r.position + Vector2(0, _dip), r.size)


## The global rect of the Key Card risen, where the Deck starts a game: the note
## lies there while the Deck is prepared, and the starting cards go back under it.
func raised_rect() -> Rect2:
	var r := key_rect(size, true)
	return Rect2(global_position + r.position, r.size)


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
	for c in [_table, _edges, _tops, _faces, pile]:
		c.position = Vector2.ZERO
		c.size = size
	# While the card grows in or out of a panel it is clipped to the face, as the
	# landed face is.
	if _tops.clip_contents:
		_tops.size = f.size
	var cr := card_rect(size, view, _peeks())
	# The Key Card never shows below the top card, which covers the rest of it.
	_peek_clip.position = Vector2.ZERO
	_clip_peek(cr.end.y + (minf(_dip, 0.0) if view == "card" else 0.0))
	for face in [landed, dragon_face]:
		face.position = f.position
		face.size = f.size
		face.pivot_offset = f.size / 2.0
	landed.lay_out(_landing(Rect2(Vector2.ZERO, f.size)))
	_catch.position = f.position
	_catch.size = f.size
	var nr := _note_rect()
	pile.lay_out(nr)
	_render_top()
	# While the Key Card is up, the card and its edges stay dipped under it.
	if view == "card":
		cr.position.y += _dip
	if _peek_up and not _zooming:
		_peek.size = key_rect(size, true).size
		_peek.position = key_rect(size, true).position
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
	# While the Deck is prepared, its edges hang from the note lying in the card's place.
	_stack_rect = (nr if _preparing() else f) if showing_face else cr
	_edges.queue_redraw()


## Whether the Deck is being prepared: no card on it yet, the note lying where the
## Region Card will.
func _preparing() -> bool:
	return vs.get("phase", "") == "setup"


## Where the note lies: the face, or while the Deck is prepared, where the Region
## Card will first lie, raised (raised_rect()), so the starting cards go back under
## it at its size.
func _note_rect() -> Rect2:
	return key_rect(size, true) if _preparing() else face_rect(size)


## The Deck seen from the side, face up (specs/014 contracts/deck-pile.md): a soft
## shadow, then each card's edge in card stock with a line between it and the next,
## rounded as the cards are.
func _draw_edges() -> void:
	var rects := edge_rects(_stack_rect, count)
	if rects.is_empty():
		return
	var radius := card_radius(_stack_rect.size.x)
	var deepest: Rect2 = rects[0]
	for layer in T.CARD_SHADOW:
		var sh := StyleBoxFlat.new()
		sh.bg_color = Color(0, 0, 0, layer[1])
		sh.set_corner_radius_all(radius + int(layer[0]))
		_edges.draw_style_box(sh, Rect2(deepest.position + Vector2(2, 4), deepest.size).grow(layer[0]))
	var card := StyleBoxFlat.new()
	card.bg_color = T.CARD_EDGE
	card.border_color = T.CARD_EDGE_LINE
	card.set_border_width_all(2)
	card.set_corner_radius_all(radius)
	card.anti_aliasing = true
	for r in rects:
		_edges.draw_style_box(card, r)


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

## Deal the notes the state on show wants onto the Deck, and throw off those done
## with (specs/015 contracts/note-pile.md).
func _update_note(animate: bool) -> void:
	if vs.is_empty():
		return
	# The notes of one Encounter are all thrown together before the next one's are
	# dealt, though the last of them is still wanted as the Deck zooms out of it.
	var key := note_key(vs)
	if key != _note_key:
		pile.throw_all(animate)
		_note_key = key
	var wanted := note_kinds(vs.get("note"), result_held)
	if _closed_key != "":
		if _closed_key == _closing_key(wanted):
			wanted = []
		else:
			_closed_key = ""
	pile.sync(wanted, vs, _result_vs, animate)


## What a state wanting `wanted` on the Deck is, for the notes closed as the Deck
## zoomed out: the same Encounter, phase and notes wanted.
func _closing_key(wanted: Array) -> String:
	return "%s|%s|%s" % [note_key(vs), vs.get("phase", ""), ",".join(wanted)]


## Which Encounter a state's notes belong to: the Region and where the Deck is
## zoomed into (none while the Deck is prepared).
static func note_key(state: Dictionary) -> String:
	return "%s|%s" % [state.get("region", ""), state.get("zoom", "")]


## The sum of the set just played comes onto the Deck on a note of its own (the
## animator's tally).
func show_result() -> void:
	result_held = true
	if vs.is_empty():
		return
	_result_vs = vs
	_update_note(is_inside_tree())


## Done with the result before the Deck zooms out to the next Encounter: with
## nothing else wanted, the notes are thrown off together.
func clear_result(_d: float) -> void:
	if not result_held:
		return
	result_held = false
	_close_notes()


## Every note is thrown off as the Deck zooms out of the Encounter, before the next
## Key Card rises and its panel is lit: the result and the XP after a battle, a
## Divert's or Regroup's card once it is confirmed (specs/015). Until the sequence
## ends, the state it started from deals none of them again.
func _close_notes() -> void:
	if not vs.is_empty():
		_closed_key = _closing_key(note_kinds(vs.get("note"), result_held))
	_update_note(is_inside_tree())


## A refused move's reason lies on the Deck on a note of its own, titled with what
## was refused, until the player presses anywhere (play_screen.gd).
func show_refusal(text: String, title := "") -> void:
	if text == "":
		return
	pile.show_refusal(text, is_inside_tree(), title)


func clear_refusal() -> void:
	if pile.refusal_text() == "":
		return
	pile.clear_refusal(is_inside_tree())


# ---------------------------------------------------------------- motion

## From the face out to the whole top card. A Region Encounter's landed panel is
## the card's own panel grown, so the card simply shrinks back from it.
func zoom_out(d: float) -> void:
	held = true
	result_held = false
	_close_notes()
	var top: Control = top_node()
	if view != "face" or top == null or zoomed == "":
		view = "card"
		_place()
		return
	_hold_faces(true)
	var face: Control = face_node()
	var f := face_rect(size)
	var cr := card_rect(size, "card", _peeks())
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
			region_card.set_focus(zoomed, 1.0 - v)
			region_card.set_numbers(v), 0.0, 1.0, d)
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
	reveal_beat.emit("zoom")
	var face: Control = face_node()
	var f := face_rect(size)
	var cr := card_rect(size, "card", _peeks())
	var tile := _target_rect(target, cr)
	# Where the Key Card left the card: dipped, the panel already lit and rimmed.
	var from := Rect2(cr.position + Vector2(0, _dip), cr.size)
	var lit0: float = region_card.focus if region_card.focus_key == target else 0.0
	var rim0: float = region_card.rim
	face.position = f.position
	face.size = f.size
	face.visible = true
	if UI.reduced_motion:
		face.modulate.a = 0.0
		var tw := _keep(create_tween().set_parallel(true))
		tw.tween_property(face, "modulate:a", 1.0, d)
		tw.tween_property(top, "modulate:a", 0.0, d)
		if _peek_up:
			tw.tween_property(_peek, "modulate:a", 0.0, d)
		tw.chain().tween_callback(_land)
		return
	var pivot := tile.get_center() - cr.position
	top.pivot_offset = pivot
	var tw := _keep(create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT))
	if _peek_up:
		# The Key Card slides back down under the card as the zoom starts.
		tw.tween_property(_peek, "position", key_rect(size, false).position, d * T.PEEK_FALL / T.ZOOM).set_ease(Tween.EASE_IN)
		tw.tween_property(_peek, "lit", 0.0, d * T.PEEK_FALL / T.ZOOM)
	_dip = 0.0
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
			var r := _lerp_rect(from, Rect2(at.card.position + f.position, at.card.size), v)
			_card_at(r.position, r.size)
			region_card.set_focus(target, lerpf(lit0, 1.0, v))
			region_card.set_rim(lerpf(rim0, 0.0, v))
			region_card.set_numbers(1.0 - v), 0.0, 1.0, d)
		tw.tween_property(face, "modulate:a", 1.0, d * LAND_FADE).set_delay(d * (1.0 - LAND_FADE))
		# The Encounter's name comes down from behind the panel as the face takes over.
		landed.slide_strip(d * (1.0 - LAND_FADE), T.MOVE)
		tw.tween_method(_set_stack_rect, from, f, d)
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


## The player's look at the whole card: from the landed face out to the Region Card,
## its Encounter's panel still lit, and the Key Card that named it rising over its
## top as it settles, as the reveal left them (peek()). A press zooms back in.
func look_out(d: float) -> void:
	var top: Control = top_node()
	if _looking or held or _zooming or view != "face" or zoomed == "" or top == null or not _peeks() \
			or not landed.visible or note_on:
		return
	_looking = true
	_catch.visible = true
	held = true
	_hold_faces(true)
	var f := face_rect(size)
	var cr := card_rect(size, "card", true)
	var key_face = vs.get("key_face")
	_dip = dip(peek_h(cr.size)) if key_face != null else 0.0
	var home := Rect2(cr.position + Vector2(0, _dip), cr.size)
	if key_face != null:
		_peek.size = cr.size
		_peek.set_model(key_face, ["encounter"])
		_peek.lit = 1.0
		_peek.modulate.a = 1.0
		_peek.position = key_rect(size, false).position
	view = "card"
	var at := _landing(f)
	_zooming = true
	_clip_tops(true)
	top.scale = Vector2.ONE
	top.modulate = Color.WHITE
	top.pivot_offset = Vector2.ZERO
	top.visible = true
	landed.visible = false
	region_card.set_focus(zoomed, 1.0)
	_clip_peek(home.end.y)
	var done := func():
		_zooming = false
		_peek_up = key_face != null
		_clip_tops(false)
		_place()
	if UI.reduced_motion:
		_card_at(home.position, home.size)
		region_card.set_rim(1.0)
		region_card.set_numbers(1.0)
		_set_stack_rect(home)
		top.modulate.a = 0.0
		var tw := _keep(create_tween().set_parallel(true))
		tw.tween_property(top, "modulate:a", 1.0, d)
		if key_face != null:
			_peek.position = key_rect(size, true).position
			_peek.modulate.a = 0.0
			_peek.visible = true
			tw.tween_property(_peek, "modulate:a", 1.0, d)
		tw.chain().tween_callback(done)
		return
	var from := Rect2(at.card.position + f.position, at.card.size)
	_card_at(from.position, from.size)
	var tw := _keep(create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT))
	tw.tween_method(func(v: float):
		var r := _lerp_rect(from, home, v)
		_card_at(r.position, r.size)
		region_card.set_rim(v)
		region_card.set_numbers(v), 0.0, 1.0, d)
	tw.tween_method(_set_stack_rect, f, home, d)
	if key_face != null:
		# The Key Card rises over the top as the card comes to rest.
		# Kept out of sight until then: the card grown past the face may not cover it.
		var rise := minf(T.PEEK_RISE, d)
		tw.tween_callback(func(): _peek.visible = true).set_delay(d - rise)
		tw.tween_property(_peek, "position", key_rect(size, true).position, rise) \
			.set_ease(Tween.EASE_OUT).set_delay(d - rise)
	tw.chain().tween_callback(done)


## Back in from the player's look at the whole card to the Encounter, the Key Card
## sliding back down as on a reveal (zoom_in()).
func look_in(d: float) -> void:
	if not _looking or _zooming:
		return
	_looking = false
	_catch.visible = false
	zoom_in(zoomed, d)


## At once, the player's look at the whole card ended, back on the Encounter: a
## sequence starting plays from the face.
func stop_look() -> void:
	if not _looking and not _catch.visible:
		return
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens = []
	_looking = false
	_catch.visible = false
	_zooming = false
	_clip_tops(false)
	region_card.set_rim(0.0)
	region_card.set_numbers(1.0)
	_land()


## The top card at `at`, `size`, laid out afresh (not scaled), so it stays sharp.
func _card_at(at: Vector2, card_size: Vector2) -> void:
	var top: Control = top_node()
	top.scale = Vector2.ONE
	top.position = at
	top.size = card_size


func _clip_tops(on: bool) -> void:
	_tops.clip_contents = on
	# Rounded as the landed face is, so the corners do not change as it takes over.
	_tops.clip_children = CanvasItem.CLIP_CHILDREN_ONLY if on else CanvasItem.CLIP_CHILDREN_DISABLED
	_tops.size = face_rect(size).size if on else size
	_tops.queue_redraw()


func _draw_tops_mask() -> void:
	if _tops.clip_contents:
		_tops.draw_style_box(UI.box(Color.WHITE, Color.TRANSPARENT, 0, card_radius(_tops.size.x), 0), Rect2(Vector2.ZERO, _tops.size))


## While the Hand is drawn, the top card lies over the cards being drawn, so each
## comes out from under it (specs/014): for `t` seconds, or until finish().
func cover_draw(t: float) -> void:
	_tops.z_index = 3
	var tw := _keep(create_tween())
	tw.tween_interval(t)
	tw.tween_callback(func(): _tops.z_index = 0)


## The whole Deck over the cards for `t`, whatever its view: a Time Penalty's
## cards leave from under the top card or the face zoomed into on it, and the
## note on it.
func cover_pass(t: float) -> void:
	z_index = 3
	var tw := _keep(create_tween())
	tw.tween_interval(t)
	tw.tween_callback(func(): z_index = 0)


static func _lerp_rect(a: Rect2, b: Rect2, v: float) -> Rect2:
	return Rect2(a.position.lerp(b.position, v), a.size.lerp(b.size, v))


func _settle_view() -> void:
	if _zooming:
		return
	for c in [region_card, dragon_card, landed, dragon_face]:
		c.scale = Vector2.ONE
		c.modulate = Color.WHITE
	region_card.set_focus("", 0.0)
	region_card.set_rim(0.0)
	region_card.set_numbers(1.0)
	_clip_tops(false)
	_place()


## The Key Card back under the Region Card, unlit and out of sight, the Deck no
## longer dipped.
func _put_peek_away() -> void:
	_peek_up = false
	_dip = 0.0
	_peek.visible = false
	_peek.lit = 0.0
	_peek.modulate.a = 1.0


func _land() -> void:
	_put_peek_away()
	_zooming = false
	view = "face"
	held = false
	_settle_view()
	_hold_faces(false)


## The card on top changes: placed on the Deck at the start, turned over right to
## left to the next Region on its back, or after the last Region to the dragon's.
func turn_to(m, d: float) -> void:
	if m == null:
		return
	var was = _shown_top
	view = "card"
	var cr := card_rect(size, "card", m.kind == "region")
	if UI.reduced_motion or was == null:
		# Laid on the Deck at the start, a Region Card lies raised where the note
		# preparing the Deck lay, until the first reveal brings it down.
		if was == null and m.kind == "region":
			_raise()
		cr.position.y += _dip
		_show_top(m)
		_place()
		# The note preparing the Deck lies on it as a card would: thrown off to the
		# left as a discard, it shows the Region Card already under it.
		if was == null and note_on and _preparing():
			pile.throw_all(true)
			if not UI.reduced_motion:
				return
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
	var tw := _keep(create_tween().set_trans(Tween.TRANS_QUAD))
	if was.kind == "region":
		# Turned over right to left, the next Region (or the dragon) on its back.
		old.pivot_offset = old.size / 2.0
		# Where the card on show rests: the new one, once turned, rests at its own place.
		var home := [old.position]
		tw.tween_method(func(v: float):
			if v >= 0.5 and _shown_top != m:
				_show_top(m)
				_place()
				home[0] = top_node().position
			_flip_at(v, home[0]), 0.0, 1.0, d).set_ease(Tween.EASE_IN_OUT)
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


## The top card `v` of the way through being turned over right to left about its
## upright middle, resting at `home`: edge on at the half, leaning left the way it
## turns as a step note does (note_pile.gd _flip()), lifted a little and shaded as
## it turns away from the light.
func _flip_at(v: float, home: Vector2) -> void:
	var top: Control = top_node()
	var a := v * PI
	top.scale = Vector2(absf(cos(a)), 1.0 + 0.04 * sin(a))
	top.position = home - Vector2(top.size.x * 0.08 * sin(a), 0)
	var shade := 1.0 - 0.35 * sin(a)
	top.modulate = Color(shade, shade, shade, top.modulate.a)


## The Key Card, as big as the Region Card and lined up with it, rises from under
## it just far enough to show the Encounter it names and any Hardship; its number
## lights up, then `target`'s panel on the Region Card, and it stays up, both lit,
## until zoom_in() slides it back down (specs/014 contracts/deck-motion.md). The Deck
## dips a little as it is drawn up (dip()), so the Region Card can stay large.
func peek(face_model, target: String, d: float) -> void:
	if face_model == null or _shown_top == null or _shown_top.kind != "region" or view != "card":
		return
	var cr := card_rect(size, "card", true)
	var down := dip(peek_h(cr.size))
	_peek.size = cr.size
	_peek.set_model(face_model, ["encounter"])
	_peek.lit = 0.0
	var rest := key_rect(size, false).position
	var up := key_rect(size, true).position
	_peek.visible = true
	# The beats keep their shares of KEY_PEEK in whatever time the step is given.
	var k := d / T.KEY_PEEK
	var rise := T.PEEK_RISE * k
	var panel_at := (T.PEEK_RISE + 0.6 * T.KEY_LIT) * k
	var tw := _keep(create_tween().set_parallel(true))
	if UI.reduced_motion:
		# Already raised, the Deck already dipped, with no travel: it fades in.
		_dip_to(down, cr)
		_peek.position = up
		_peek.modulate.a = 0.0
		tw.tween_property(_peek, "modulate:a", 1.0, minf(T.FAST, rise))
	else:
		_peek.position = rest
		_peek.modulate.a = 1.0
		tw.tween_property(_peek, "position", up, rise).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# From where it lies: at rest, or raised at the start of a game, when it comes
		# down the whole way the Key Card rises.
		tw.tween_method(_dip_to.bind(cr), _dip, down, rise).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		_peek_up = true
		reveal_beat.emit("key_lit")).set_delay(rise)
	tw.tween_property(_peek, "lit", 1.0, T.KEY_LIT * k).set_delay(rise)
	tw.tween_callback(func(): reveal_beat.emit("panel_lit")).set_delay(panel_at)
	tw.tween_method(func(v: float):
		region_card.set_focus(target, v)
		region_card.set_rim(v), 0.0, 1.0, T.PANEL_LIT * k).set_delay(panel_at)


## At once, with no motion: the whole Region Card, the Key Card up under it as
## peek() leaves it, its number lit and `target`'s panel lit, waiting on the player
## (a sequence hurried on to its reveal, animator.gd press()).
func show_reveal(face_model, target: String) -> void:
	if face_model == null:
		return
	held = true
	view = "card"
	if vs.get("top_card") != null and _shown_top != vs.top_card:
		_show_top(vs.top_card)
	if _shown_top == null or _shown_top.kind != "region":
		return
	var cr := card_rect(size, "card", true)
	_hold_faces(true)
	_peek.size = cr.size
	_peek.set_model(face_model, ["encounter"])
	_peek.lit = 1.0
	_peek.modulate.a = 1.0
	_peek.visible = true
	_peek_up = true
	_dip = dip(peek_h(cr.size))
	region_card.set_focus(target, 1.0)
	region_card.set_rim(1.0)
	_place()


func _clip_peek(bottom: float) -> void:
	_peek_clip.size = Vector2(size.x, maxf(bottom, 0.0))


## The top card and the edges under it, `by` below where they rest (above, when
## negative: raised).
func _dip_to(by: float, cr: Rect2) -> void:
	_dip = by
	_clip_peek(cr.end.y + minf(by, 0.0))
	var top: Control = top_node()
	if top != null:
		top.position = cr.position + Vector2(0, by)
	_set_stack_rect(Rect2(cr.position + Vector2(0, by), cr.size))
