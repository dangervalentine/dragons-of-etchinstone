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
## Printed as a game's reference card is (specs/015): a border of the card stock
## round a dark face, a title band across the top with a torn edge in the note's
## colour, the rest read from the top down, and a narrow band along the foot. The
## border as a share of the card's width; the bands' heights.
const BORDER := 0.035
const BAND_H := 54.0
const FOOT_H := 18.0
## Each kind's title, icon and colour as the band shows them. A step's title is its
## mode's name (FUSE, DIVERT, REGROUP).
const LOOKS := {
	"setup": {"title": "PREPARE YOUR DECK", "icon": "crown", "accent": "gold"},
	"mode": {"title": "", "icon": "", "accent": "focus"},
	"result": {"title": "RESULT", "icon": "attack", "accent": "gold"},
	"soak": {"title": "SOAK THE DAMAGE", "icon": "hp", "accent": "bad"},
	"upgrade": {"title": "UPGRADE", "icon": "upgrade", "accent": "gold"},
	"refusal": {"title": "NOT ALLOWED", "icon": "close", "accent": "bad"},
}

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
## The title band's icon and words.
var _band := HBoxContainer.new()
var _band_icon := TextureRect.new()
var _band_title := Label.new()
var _band_key := ""
var _accent: Color = T.GOLD
## While _fit_result() lays the card out again.
var _refitting := false
## A layout asked for at the end of the frame, as what a panel shows changes.
var _fit_pending := false
## The size and result found too tall to set out line by line: kept on one row.
var _compact_key := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_body.clip_contents = true
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_band.add_theme_constant_override("separation", T.S)
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_band_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_band_icon.custom_minimum_size = Vector2(30, 30)
	_band_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_band_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(_band_icon)
	UI.style_label(_band_title, T.SUBHEAD, T.INK)
	_band_title.clip_text = true
	_band_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_band_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_band.add_child(_band_title)
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
	# The animator reveals the sum on the panel directly (the tally): lay the card out
	# again as it grows.
	preview.minimum_size_changed.connect(_queue_fit)
	UI.style_label(_refusal, T.BODY, T.INK)
	_refusal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refusal.visible = false
	_box.add_child(_refusal)
	# Over the art behind the words, as printed.
	_body.add_child(_band)
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
	if not what.is_empty():
		var mode: String = str(vs.get("mode", ""))
		_set_band(what[0], mode.get_slice("_", 0) if what[0] == "mode" else "")
	_show_refusal()
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
		_set_band("refusal")


## The title band for `kind`; a step's (`mode`, as "fuse") names it.
func _set_band(kind: String, mode := "") -> void:
	var look: Dictionary = LOOKS.get(kind, LOOKS.result)
	var title: String = mode.to_upper() if kind == "mode" and mode != "" else look.title
	var icon: String = mode if kind == "mode" and mode != "" else look.icon
	if kind == "mode" and title == "":
		title = "NEXT STEP"
		icon = "help"
	_accent = {"gold": T.GOLD, "focus": T.FOCUS, "bad": T.BAD}[look.accent]
	var key := "%s|%s" % [title, icon]
	if key == _band_key:
		return
	_band_key = key
	_band_title.text = title
	_band_icon.texture = UI.icon(icon) if icon != "" else null
	_band_icon.modulate = _accent
	_band_icon.visible = icon != ""
	_fit_title()
	queue_redraw()


## The title as large as the band lets it be, down to the smallest text read.
func _fit_title() -> void:
	var font := UI.font(T.SUBHEAD[0])
	var room := face_rect().size.x - 28.0 - (30.0 + T.S if _band_icon.visible else 0.0)
	var fs: int = T.SUBHEAD[1]
	while fs > T.TEXT_MIN and font.get_string_size(_band_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		fs -= 1
	_band_title.add_theme_font_size_override("font_size", fs)


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
	# Its title is the card's own band.
	_setup.add_child(UI.label("Four Regions lie between you and the dragon. Your sixteen Mage Cards are your only weapons, and your deck is your time.", T.BODY, T.INK, true))
	_setup.add_child(UI.label("The cards you choose start at a different Level. Hold a card to see its other Levels.", T.LABEL, T.INK_MUTED, true))
	var art: String = vs.stage.get("art", "")
	if art != "" and _creature.art_name != art:
		var e: String = vs.stage.get("element", "")
		_creature.setup(art, Color(T.ether(e) if e != "" else T.INK, 0.5), e, false)
	UI.ignore_mouse(_setup)


## The printed face inside the card-stock border.
func face_rect() -> Rect2:
	var b := roundf(maxf(6.0, size.x * BORDER))
	return Rect2(Vector2(b, b), size - Vector2(b, b) * 2.0)


## Where the content is read: under the title band, over the foot, inside the pad.
func content_rect() -> Rect2:
	var f := face_rect()
	var top := f.position.y + BAND_H + PAD
	return Rect2(f.position.x + PAD, top, f.size.x - 2.0 * PAD, f.end.y - FOOT_H - PAD - top)


## How tall the content may be and still fit the card (for the result's layout and
## the checks).
func content_room() -> float:
	return content_rect().size.y


func _fit() -> void:
	queue_redraw()
	_body.position = Vector2.ZERO
	_body.size = size
	var f := face_rect()
	_band.position = f.position + Vector2(14, 0)
	_band.size = Vector2(f.size.x - 28, BAND_H - 6)
	_fit_title()
	var inner := content_rect()
	_box.position = inner.position
	_box.size = Vector2(inner.size.x, 0)
	# Twice: the first pass gives wrapped lines their width, the second the height
	# that width needs (as preview_panel.gd's _lay_out).
	for i in 3:
		_sort(_box)
	_sort(_band)
	# Read from the top down, as a reference card is.
	_box.size.y = _box.get_combined_minimum_size().y
	var a := minf(f.size.x, f.size.y) * 0.9
	_creature.size = Vector2(a, a)
	_creature.position = f.end - Vector2(a, a + FOOT_H)
	_fit_result()
	queue_redraw()


## A result is set out line by line while that fits the card at its size, else on
## one row: chosen again whenever the card is laid out, as it may be sized after it
## was filled.
func _fit_result() -> void:
	if _refitting or not kinds.has("result") or refusal != "" or result_vs.is_empty():
		return
	_refitting = true
	var key := "%s|%d" % [size, result_vs.hash()]
	var roomy: bool = size.y >= T.NOTE_ROOMY_H and key != _compact_key
	if preview.roomy != roomy:
		preview.roomy = roomy
		_render_result()
		_fit()
	if preview.roomy and content_height() > content_room():
		_compact_key = key
		preview.roomy = false
		_render_result()
		_fit()
	_refitting = false


func _queue_fit() -> void:
	if _fit_pending or _refitting:
		return
	_fit_pending = true
	_deferred_fit.call_deferred()


func _deferred_fit() -> void:
	_fit_pending = false
	if is_inside_tree():
		_fit()


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
	# Printed on the card stock the Deck's edges show, its border that stock.
	draw_style_box(UI.box(T.CARD_EDGE, T.CARD_EDGE_LINE, 2, radius, 0), Rect2(Vector2.ZERO, size))
	var f := face_rect()
	var inner_r := maxi(2, radius - int(f.position.x))
	draw_style_box(UI.box(T.BG_RAISED, Color.TRANSPARENT, 0, inner_r, 0), f)
	# The title band, its foot torn, the tear edged in the note's colour.
	var torn := _torn_band(f, BAND_H)
	draw_colored_polygon(_shifted(torn, Vector2(0, 3)), _accent)
	draw_colored_polygon(torn, T.BG_BAND)
	# Where the words end short of the foot, the card's emblem printed faint, as a
	# reference card fills its face; the setup card has the dragon there instead.
	if _band_icon.visible and _band_icon.texture != null and not _creature.visible:
		var top := _box.position.y + _box.size.y + PAD
		var room := Rect2(f.position.x, top, f.size.x, f.end.y - FOOT_H - PAD - top)
		var side := minf(room.size.x * 0.55, room.size.y * 0.8)
		if side >= 64.0:
			var at := Rect2(room.get_center() - Vector2(side, side) / 2.0, Vector2(side, side))
			draw_texture_rect(_band_icon.texture, at, false, Color(_accent, 0.07))
	# The foot: a narrow band of the same dark, a rule of the note's colour over it
	# and a small mark at its middle, as a printed card's bottom edge.
	var foot := Rect2(f.position.x, f.end.y - FOOT_H, f.size.x, FOOT_H)
	var fs := StyleBoxFlat.new()
	fs.bg_color = T.BG_BAND
	fs.corner_radius_bottom_left = inner_r
	fs.corner_radius_bottom_right = inner_r
	draw_style_box(fs, foot)
	draw_line(foot.position, Vector2(foot.end.x, foot.position.y), Color(_accent, 0.7), 2.0)
	var c := foot.get_center()
	var d := FOOT_H * 0.3
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), _accent)


## The title band across the top of `f`, `h` deep, its top corners rounded as the
## face's are and its foot torn: the same tear on every note, so it reads as print.
func _torn_band(f: Rect2, h: float) -> PackedVector2Array:
	var r := float(maxi(2, UI.card_radius(size.x) - int(f.position.x)))
	var pts := PackedVector2Array()
	# Round the top-left corner, along the top, round the top-right corner.
	for i in 5:
		var a := PI + i * (PI / 2.0) / 4.0
		pts.append(f.position + Vector2(r, r) + Vector2(cos(a), sin(a)) * r)
	for i in 5:
		var a := -PI / 2.0 + i * (PI / 2.0) / 4.0
		pts.append(Vector2(f.end.x - r, f.position.y + r) + Vector2(cos(a), sin(a)) * r)
	# The torn foot, right to left.
	var steps := 18
	var bottom := f.position.y + h
	for i in range(steps, -1, -1):
		var x := f.position.x + f.size.x * i / steps
		var jag: float = [0.0, 4.0, 1.5, 5.0, 2.0, 3.5, 0.5, 4.5, 1.0][i % 9]
		pts.append(Vector2(x, bottom - jag))
	return pts


static func _shifted(pts: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + by)
	return out
