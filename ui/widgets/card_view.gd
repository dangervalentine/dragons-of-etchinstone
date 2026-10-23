extends Control
## One Mage Card on screen. The node lives as long as the card is visible, so it
## can move between places. It draws the face, shows the card's state on top of it
## (role, Reserve, selection, fused, unavailable) and reports taps and holds.
## When the Level it shows changes, it turns over as if the new Level were printed
## on the back: right to left going up, left to right going down.

const T = preload("res://ui/theme/tokens.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const UI = preload("res://ui/theme/theme.gd")
const Haptics = preload("res://ui/fx/haptics.gd")
const CardFace = preload("res://ui/widgets/card_face.gd")
const TrashedBack = preload("res://ui/widgets/trashed_back.gd")
const TURN_SHADER = preload("res://ui/fx/shaders/card_turn.gdshader")
## Room round the card in the turning picture, as a share of its size: for the tag
## above it, its shadow, and the near edge growing as it comes forward.
const TURN_ROOM := Vector2(0.15, 0.3)

const HOLD_SECONDS := 0.35
## How far the pointer moves with the button down before a press becomes a drag.
const DRAG_START := 12.0
const ROLE_ICONS := {"spell": "spell", "element": "element_role", "boost": "boost"}
const ROLE_NAMES := {"spell": "Spell", "element": "Element", "boost": "Boost"}
## The widest tag a card carries on its top edge.
const TAG_LONGEST := "Element · Discarded after"

signal tapped(id: String)
signal held(id: String)
## The pointer has come to rest on the card, or left it (mouse only).
signal hovered(id: String, on: bool)
## A drag: started, moved to a global point, and let go at one.
signal drag_started(id: String)
signal dragged(id: String, at: Vector2)
signal dropped(id: String, at: Vector2)

var id := ""
var model := {}
## Two Action Sets are in play, so ribbons say which set.
var show_set_number := false
## Where the card belongs when nothing is moving it.
var home := Rect2()

const Glossary = preload("res://ui/model/glossary.gd")
var _face := CardFace.new()
## The face and the marks on it, turned over together when the Level shown changes,
## so the card's own place in the Hand moves on undisturbed.
var _turn := Control.new()
## What a card to be Trashed turns to: a back shared by all such cards, no figures.
var _back := TrashedBack.new()
var _flip: Tween
## While the card turns, the face is drawn into this picture, and `_turning` shows
## it laid on the turning plane (ui/fx/shaders/card_turn.gdshader).
var _picture: SubViewport
var _turning: TextureRect
## The Level the face shows, or is turning to show (0 for a card to be Trashed).
var _shown_level := -1
## Whether the face shows the card as it will become (model.turned), once turned.
var _face_turned := false
## The parts a tooltip can explain; the Ether sigils are checked first, as they sit on the plates.
const PART_ORDER := ["level", "cost", "key", "initiative", "basic", "enhanced", "boost", "armor"]
var _marks := Control.new()
var _hold := Timer.new()
var _pressing := false
var _held := false
var _hover := false
var _press_at := Vector2.ZERO
var _dragging := false
## What the Boost's aim mark means, said when the pointer rests on it.
const AIM_HELP := "Where this Boost goes: choose Attack or Initiative beside the Hand."


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_turn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_turn)
	_turn.add_child(_face)
	_back.visible = false
	_turn.add_child(_back)
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.draw.connect(_draw_marks)
	_turn.add_child(_marks)
	_hold.one_shot = true
	_hold.wait_time = HOLD_SECONDS
	_hold.timeout.connect(_on_hold)
	add_child(_hold)
	resized.connect(_fit)
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))


func set_model(m: Dictionary) -> void:
	var same_card: bool = not model.is_empty() and model.id == m.id
	model = m
	id = m.id
	_cursor = Control.CURSOR_POINTING_HAND if m.get("eligible", true) else Control.CURSOR_ARROW
	mouse_default_cursor_shape = _cursor
	var level := shown_level(m)
	if same_card and level != _shown_level and is_inside_tree() and not UI.reduced_motion:
		_turn_over(-1.0 if level > _shown_level else 1.0)
	elif _flip == null or not _flip.is_valid():
		_show_face()
	_shown_level = level


## The Level a card's face shows: the one it will become while it is turned (0 if
## it will be Trashed), else its own.
static func shown_level(m: Dictionary) -> int:
	var alt = m.get("alt")
	if m.get("turned", false) and alt != null:
		return 0 if alt.trashed else int(alt.level)
	return int(m.level)


## Draw the face for the model as it stands: the card as it will become while it
## is turned, with the figures that change ringed, or the Trashed back.
func _show_face() -> void:
	var alt = model.get("alt")
	_face_turned = model.get("turned", false) and alt != null
	var trashed: bool = _face_turned and alt.trashed
	_face.visible = not trashed
	_back.visible = trashed
	if not _face_turned or trashed:
		_face.set_model(model)
		_face.dimmed = not model.get("eligible", true)
		_face.out_of_play = model.get("out_of_play", false)
	else:
		var m := model.duplicate()
		m.level = alt.level
		m.stats = alt.stats
		_face.set_model(m, alt.changed, T.PARCHMENT if alt.level > model.level else T.DANGER)
		_face.dimmed = false
	_face.set_focus(model.get("focus", {}))
	# The card picked up casts the larger shadow of a card held up (specs/019).
	_face.lifted = model.get("state", "") == "selected" or _dragging
	_marks.queue_redraw()


## Turn the card over about its upright axis, in perspective; `dir` is the way
## the edge it is turned by travels, -1 right to left and 1 left to right. That
## edge lifts toward the eye and sweeps across; the face changes while the card is
## edge-on, and the new face comes down from the other side.
func _turn_over(dir: float) -> void:
	if _flip != null and _flip.is_valid():
		_flip.kill()
	_begin_turning()
	var mat: ShaderMaterial = _turning.material
	var turn := func(t: float) -> void:
		# The first half turns the old face to its edge, the second brings the new one
		# down from the far side, so the same edge leads all the way across.
		var a: float = dir * PI * t if t <= 0.5 else -dir * PI * (1.0 - t)
		mat.set_shader_parameter("angle", a)
	_flip = create_tween().set_trans(Tween.TRANS_SINE)
	_flip.tween_method(turn, 0.0, 0.5, T.TURN / 2.0).set_ease(Tween.EASE_IN)
	_flip.tween_callback(_show_face)
	_flip.tween_method(turn, 0.5, 1.0, T.TURN / 2.0).set_ease(Tween.EASE_OUT)
	_flip.tween_callback(_end_turning)


## Move the face into the picture, sharp at the size it is on screen, and show the
## picture on the turning plane in its place.
func _begin_turning() -> void:
	var px: Vector2 = get_viewport().get_final_transform().get_scale() * get_global_transform_with_canvas().get_scale()
	var k := maxf(1.0, maxf(px.x, px.y))
	var room := size * TURN_ROOM
	if _picture == null:
		_picture = SubViewport.new()
		_picture.transparent_bg = true
		_picture.disable_3d = true
		add_child(_picture)
		_turning = TextureRect.new()
		_turning.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_turning.texture = _picture.get_texture()
		_turning.stretch_mode = TextureRect.STRETCH_SCALE
		_turning.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_turning.material = ShaderMaterial.new()
		_turning.material.shader = TURN_SHADER
		add_child(_turning)
	_picture.size = Vector2i(((size + room * 2.0) * k).ceil())
	_picture.canvas_transform = Transform2D(0.0, Vector2(k, k), 0.0, room * k)
	_picture.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if _turn.get_parent() != _picture:
		remove_child(_turn)
		_picture.add_child(_turn)
	# The plane's rect reaches further up and down than the picture, for the near edge.
	var reach := Vector2(room.x, room.y * 1.6)
	_turning.position = -reach
	_turning.size = size + reach * 2.0
	_turning.visible = true
	var mat: ShaderMaterial = _turning.material
	mat.set_shader_parameter("card_size", size)
	mat.set_shader_parameter("rect_origin", -reach)
	mat.set_shader_parameter("rect_size", _turning.size)
	mat.set_shader_parameter("tex_origin", -room)
	mat.set_shader_parameter("tex_size", size + room * 2.0)
	mat.set_shader_parameter("angle", 0.0)


## The face back in its place, the picture put away.
func _end_turning() -> void:
	if _picture == null or _turn.get_parent() != _picture:
		return
	_picture.remove_child(_turn)
	add_child(_turn)
	move_child(_turn, 0)
	_turning.visible = false
	_picture.render_target_update_mode = SubViewport.UPDATE_DISABLED


## Whether the card's Ether field moves: off while something covers the screen.
func set_live(on: bool) -> void:
	_face.motion = on


## Put the card where it belongs, at once.
func snap_home() -> void:
	position = home.position
	size = home.size
	scale = Vector2.ONE
	rotation = 0.0
	modulate = Color.WHITE
	pivot_offset = size / 2.0


func _fit() -> void:
	_turn.position = Vector2.ZERO
	_turn.size = size
	_face.position = Vector2.ZERO
	_face.size = size
	_marks.position = Vector2.ZERO
	_back.position = Vector2.ZERO
	_back.size = size
	_marks.size = size
	pivot_offset = size / 2.0
	_marks.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	# The tooltip is the part under the pointer, or none at all over the background.
	if event is InputEventMouseMotion:
		# Moving far enough with the button down picks the card up to drag it; it
		# then is not a hold, so the inspector does not open.
		if _pressing and not _held and not _dragging and event.position.distance_to(_press_at) > DRAG_START:
			_dragging = true
			_face.lifted = true
			_hold.stop()
			UI.pulse_scale(self, 1.0)
			drag_started.emit(id)
		if _dragging:
			dragged.emit(id, get_global_transform() * event.position)
			accept_event()
			return
		HelpTip.show(self, part_help(event.position), part_icon(event.position), _cursor)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			held.emit(id)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressing = true
				_held = false
				_dragging = false
				_press_at = event.position
				_hold.start()
				UI.pulse_scale(self, 0.96)
			elif _pressing:
				_pressing = false
				_hold.stop()
				UI.pulse_scale(self, 1.0)
				if _dragging:
					_dragging = false
					_face.lifted = model.get("state", "") == "selected"
					dropped.emit(id, get_global_transform() * event.position)
				elif not _held and Rect2(Vector2.ZERO, size).has_point(event.position):
					hovered.emit(id, false)
					Haptics.tap()
					tapped.emit(id)
			accept_event()


func _on_hold() -> void:
	if _pressing:
		_held = true
		UI.pulse_scale(self, 1.0)
		Haptics.hold()
		held.emit(id)


## The mark under `at` beside a figure (an effect's icon, or the Boost's aim), or "".
func _mark_at(at: Vector2) -> String:
	var all: Dictionary = _face.marks()
	for region in all:
		var rects: Array = _face.mark_rects(region, all[region].size())
		for i in rects.size():
			if rects[i].grow(2).has_point(at - _face.position):
				return all[region][i].get("icon", "aim")
	return ""


## The global rect of the Ether sigil beside the card's name: what a lesson lights
## to show a card's Ether (specs/017 research R6).
func ether_rect() -> Rect2:
	var rects: Array = _face.sigil_rects()
	if rects.is_empty():
		return Rect2()
	return _face.get_global_transform() * (rects[0] as Rect2)


## Hovering a part of the card explains just that part: what the term means, not
## its figures, which the card itself shows (and may be previewing at another Level).
func part_help(at: Vector2) -> String:
	if model.is_empty():
		return ""
	# The face may be previewing another Level, with a Hardship of its own.
	var h = _face.model.get("stats", {}).get("hardship")
	if h != null and _face.hardship_rect().grow(3).has_point(at - _face.position):
		return hardship_help(h)
	var mark := _mark_at(at)
	if mark == "aim" or mark == "attack" or mark == "initiative":
		return AIM_HELP
	if mark != "":
		return HelpTip.text(mark)
	# A sigil explains the Ether it shows, as the Glossary does.
	var ethers: Array = _face.sigil_ethers()
	var rects: Array = _face.sigil_rects()
	for i in rects.size():
		if rects[i].grow(3).has_point(at - _face.position):
			return HelpTip.text(str(ethers[i]))
	for key in PART_ORDER:
		if _face.region_rect(key).grow(2).has_point(at - _face.position):
			if key == "basic" or key == "enhanced":
				return _action_help(key, _face.model.stats[key].type)
			return PART_HELP.get(key, "")
	return ""


## The cursor away from any explained part: a hand while the card can be tapped.
var _cursor := Control.CURSOR_POINTING_HAND


## The icon heading the tooltip for the part at `at`.
func part_icon(at: Vector2) -> String:
	if model.is_empty():
		return ""
	var stats: Dictionary = _face.model.get("stats", {})
	var h = stats.get("hardship")
	if h != null and _face.hardship_rect().grow(3).has_point(at - _face.position):
		return h
	var mark := _mark_at(at)
	if mark != "":
		return "boost" if mark == "aim" else mark
	var ethers: Array = _face.sigil_ethers()
	var rects: Array = _face.sigil_rects()
	for i in rects.size():
		if rects[i].grow(3).has_point(at - _face.position):
			return str(ethers[i])
	for key in PART_ORDER:
		if _face.region_rect(key).grow(2).has_point(at - _face.position):
			if key == "basic" or key == "enhanced":
				return "move" if stats[key].type == "move" else "attack"
			return PART_ICONS.get(key, "")
	return ""


const PART_ICONS := {"level": "crown", "cost": "upgrade", "key": "deck", "initiative": "initiative",
	"boost": "boost", "armor": "armor"}


## A Hardship's name and what it does; that it comes from the Key Card goes unsaid,
## as it sits on the Key Card strip.
static func hardship_help(id: String) -> String:
	return HelpTip.text(id)


## Names the action this card gives: Attack, Move, or either for a card that allows both.
static func _action_help(key: String, type: String) -> String:
	var act: String = {"attack": "Attack", "move": "Move"}.get(type, "Attack or Move")
	if key == "basic":
		return "Basic action: the %s this card gives as the Spell." % act
	return "Enhanced action: a stronger %s, if the Element supplies the Ether on its corner." % act


const PART_HELP := {
	"level": "Level: how strong this card is, from 1 to 4. Upgrading raises it; Downgrading lowers it, and a Level 1 card is Trashed.",
	"key": "Key Card: while this card is on top of the Deck, this names the Encounter you face next, and any Hardship that comes with it.",
	"cost": "Upgrade cost: the XP needed to raise this card one Level after an Encounter.",
	"initiative": "Initiative: used when this card is the Element. If the enemy's Initiative is higher, it strikes first with Early Damage.",
	"boost": "Boost: when this card is the Boost, this is added to your Attack, Initiative or Move.",
	"armor": "Armor: the damage this card Soaks when Downgraded, doubled against damage of the Ether marked beside it.",
}


## The part's explanation wrapped to a narrow, opaque panel rather than one long line.
func _make_custom_tooltip(for_text: String) -> Object:
	return HelpTip.tooltip(self, for_text)


func _set_hover(on: bool) -> void:
	if DisplayServer.is_touchscreen_available():
		return
	_hover = on
	hovered.emit(id, on)
	_marks.queue_redraw()


## State drawn over the face: outline, ribbon, Ether badge, caption.
func _draw_marks() -> void:
	if model.is_empty():
		return
	var w := size.x
	var radius := UI.card_radius(w)
	var state: String = model.get("state", "available")
	var outline := Color.TRANSPARENT
	# The card picked up takes the brass ring (specs/019 "Selected"); a card placed in
	# a set needs none, its place's header names it; a hovered one a parchment edge.
	if state == "selected":
		outline = T.BRASS
	elif _hover and model.get("eligible", true):
		outline = T.PARCHMENT
	if outline.a > 0.0:
		var s := StyleBoxFlat.new()
		s.draw_center = false
		s.border_color = outline
		s.set_border_width_all(T.BORDER_SELECT if outline == T.BRASS else maxi(3, int(w * 0.022)))
		s.set_corner_radius_all(radius + 2)
		s.set_expand_margin_all(2)
		_marks.draw_style_box(s, Rect2(Vector2.ZERO, size))
	var boosting: bool = model.get("reserve_boosts", false)
	if state == "reserve":
		_dashed_outline(T.PARCHMENT if boosting else T.PARCHMENT_MUTED)

	var ribbon := ""
	var ribbon_icon := ""
	# A card's ribbons are the leather of its stat ribbon, lettered in parchment
	# (specs/019 MageCard; 5.5:1).
	var ribbon_bg := T.CARD_RIBBON
	var ribbon_ink := T.PARCHMENT
	if state == "assigned":
		var role: Array = model.role
		ribbon = ROLE_NAMES[role[1]] + (" %d" % (role[0] + 1) if show_set_number else "")
		ribbon_icon = ROLE_ICONS[role[1]]
	elif state == "reserve" and boosting:
		ribbon = "+%d" % model.stats.boost
		ribbon_icon = "boost"
	elif state == "reserve":
		ribbon = "Reserve"
		ribbon_icon = "reserve"
		ribbon_bg = T.STONE_RAISED
		ribbon_ink = T.PARCHMENT
	elif state == "fused_bottom":
		ribbon = "Tucked"
		ribbon_icon = "fuse"
		ribbon_bg = T.STONE_RAISED
		ribbon_ink = T.PARCHMENT
	elif not model.get("eligible", true) and model.get("reason", "") != "":
		ribbon = model.reason
		ribbon_bg = T.STAT_PLATE
		ribbon_ink = T.PARCHMENT
	elif model.get("note", "") != "":
		ribbon = model.note
		ribbon_icon = model.get("note_icon", "")
		var good: bool = model.get("match", false)
		# A good match is jade, and never by colour alone (specs/019 FR-009).
		if good and ribbon_icon == "":
			ribbon_icon = "victory"
		ribbon_bg = T.JADE if good else T.STAT_PLATE
		ribbon_ink = T.STAT_PLATE if good else T.PARCHMENT
	# The Trashed back carries nothing but its own mark.
	if _back.visible:
		return
	if ribbon != "":
		_ribbon(ribbon, ribbon_icon, ribbon_bg, ribbon_ink)

	# A tag on the top edge: the Level a turned card becomes, or its fate after a battle.
	var alt = model.get("alt")
	if _face_turned and alt != null:
		var up: bool = alt.level > model.level
		_tag("Level %d" % alt.level, "crown" if up else "down_arrow", T.BRASS_BRIGHT if up else T.DANGER, T.ON_BRASS if up else T.STAT_PLATE)
	elif model.get("fate", "") == "stays":
		_tag("Stays in Hand", "reserve", T.CARD_RIBBON, T.PARCHMENT)
	elif model.get("fate", "") == "spent":
		# The role it was just played as, so the recap needs no names.
		var played = model.get("played_role")
		if played != null:
			_tag("%s · Discarded after" % ROLE_NAMES[played[1]], ROLE_ICONS[played[1]], T.STONE_RAISED, T.PARCHMENT_MUTED)
		else:
			_tag("Discarded after", "discard", T.STONE_RAISED, T.PARCHMENT_MUTED)

	var fuse = model.get("fuse")
	if fuse != null and fuse.part == "top":
		var d := maxf(40.0, w * 0.26)
		var c := Vector2(w - d * 0.4, size.y * 0.46)
		_marks.draw_circle(c, d / 2.0 + 3, T.PARCHMENT)
		_marks.draw_circle(c, d / 2.0, T.GROUND)
		_marks.draw_texture_rect(UI.icon(fuse.element), Rect2(c - Vector2(d, d) * 0.3, Vector2(d, d) * 0.6), false, T.ether_ink(fuse.element))


func _ribbon(text: String, icon_name: String, bg: Color, ink: Color) -> void:
	# A tag in the lower right of the field, where the sigil is, so no figure is hidden.
	var font := UI.font(T.BODY_STRONG)
	var max_w := size.x * 0.6
	# Printed on the card, fitted to it, never under the card-text floor that scales
	# with the card (specs/019 FR-015, CardFace.name_floor); a word that will not fit
	# leaves its icon alone.
	var least := CardFace.name_floor(size.x)
	var fs := int(clampf(size.x * 0.12, 16.0, T.BODY_SM.size))
	var h := fs * 1.45
	var icon_w := (h * 0.68 + 3) if icon_name != "" else 0.0
	while fs > least and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + icon_w + 14 > max_w:
		fs -= 1
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if tw + icon_w + 14 > max_w and icon_name != "":
		text = ""
		tw = 0.0
	var w := minf(max_w, tw + icon_w + 14)
	var pad := size.x * 0.045
	var rect := Rect2(size.x - pad - w, size.y - pad - h, w, h)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(h / 2.0))
	s.border_color = Color(T.SHADE, 0.5)
	s.set_border_width_all(1)
	s.shadow_color = Color(T.SHADE, 0.45)
	s.shadow_size = 4
	_marks.draw_style_box(s, rect)
	var x := rect.position.x + (rect.size.x - tw - icon_w) / 2.0
	if icon_name != "":
		_marks.draw_texture_rect(UI.icon(icon_name), Rect2(x, rect.position.y + h * 0.16, h * 0.68, h * 0.68), false, ink)
		x += icon_w
	if text != "":
		var base := rect.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
		_marks.draw_string(font, Vector2(x, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
		UI.drew_text(self, "ribbon", fs, least)


func _tag(text: String, icon_name: String, bg: Color, ink: Color) -> void:
	var font := UI.font(T.BODY_STRONG)
	# Fitted to the card like the ribbon, on the card-text floor (specs/019 FR-015).
	var least := CardFace.name_floor(size.x)
	var fs := int(clampf(size.x * 0.105, 15.0, 20.0))
	var h := fs * 1.5
	var icon_w := h * 0.66 + 3
	# Sized for the longest tag, not this one, so every card of a size in a row
	# carries its tag at the same size.
	var widest := text
	if font.get_string_size(TAG_LONGEST, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x:
		widest = TAG_LONGEST
	while fs > least and font.get_string_size(widest, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + icon_w + 16 > size.x + 8:
		fs -= 1
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w := tw + icon_w + 16
	var rect := Rect2((size.x - w) / 2.0, -h * 0.78, w, h)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(h / 2.0))
	s.border_color = Color(T.SHADE, 0.55)
	s.set_border_width_all(1)
	s.shadow_color = Color(T.SHADE, 0.4)
	s.shadow_size = 3
	_marks.draw_style_box(s, rect)
	var x := rect.position.x + 8
	_marks.draw_texture_rect(UI.icon(icon_name), Rect2(x, rect.position.y + h * 0.17, h * 0.66, h * 0.66), false, ink)
	var base := rect.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	_marks.draw_string(font, Vector2(x + icon_w, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
	UI.drew_text(self, "tag", fs, least)



func _dashed_outline(colour: Color) -> void:
	var r := Rect2(Vector2(-2, -2), size + Vector2(4, 4))
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		_marks.draw_dashed_line(corners[i], corners[(i + 1) % 4], colour, 3.0, 10.0)
