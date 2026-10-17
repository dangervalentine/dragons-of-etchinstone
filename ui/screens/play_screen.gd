extends Control
## The one screen used for every step of play, from choosing starting cards to the
## last blow against the dragon. Regions in fixed places: header, Encounter, the
## math box on the left; on the right the role strip, the Hand (its ordered places
## and the floating cards) and the action row under them. Widgets update in place;
## card nodes persist so they can move.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const HeaderBar = preload("res://ui/widgets/header_bar.gd")
const EncounterFace = preload("res://ui/widgets/encounter_face.gd")
const DragonFace = preload("res://ui/widgets/dragon_face.gd")
const FaceFrame = preload("res://ui/widgets/face_frame.gd")
const PreviewPanel = preload("res://ui/widgets/preview_panel.gd")
const SoakMeter = preload("res://ui/widgets/soak_meter.gd")
const XpPurse = preload("res://ui/widgets/xp_purse.gd")
const RoleSlots = preload("res://ui/widgets/role_slots.gd")
const HandTray = preload("res://ui/widgets/hand_tray.gd")
const ActionBar = preload("res://ui/widgets/action_bar.gd")
const EtherPicker = preload("res://ui/widgets/ether_picker.gd")
const CardDetail = preload("res://ui/widgets/card_detail.gd")
const Art = preload("res://ui/model/art.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal intent(data: Dictionary)

var header := HeaderBar.new()
var encounter_face := EncounterFace.new()
var dragon_face := DragonFace.new()
var setup_face := FaceFrame.new()
var preview := PreviewPanel.new()
var soak_meter := SoakMeter.new()
var xp_purse := XpPurse.new()
var slots := RoleSlots.new()
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
var _toast := PanelContainer.new()
var _toast_label := Label.new()
var _toast_tween: Tween
var _setup_key := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in ["encounter", "preview", "slots", "actions", "header"]:
		var r := Control.new()
		r.name = key
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_regions[key] = r
		add_child(r)
	for face in [encounter_face, dragon_face, setup_face]:
		_fill(_regions.encounter, face)
	for panel in [preview, soak_meter, xp_purse]:
		_fill(_regions.preview, panel)
	_fill(_regions.slots, slots)
	_fill(_regions.actions, actions)
	_fill(_regions.header, header)
	# The Hand sits in its own well, lit at the rim while it is waiting on the player.
	_hand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand_panel.add_theme_stylebox_override("panel", _hand_well)
	add_child(_hand_panel)
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
	_toast.add_theme_stylebox_override("panel", UI.box(Color(T.BG_BAND, 0.95), T.BAD, 2, 22, 10))
	UI.style_label(_toast_label, ["body_bold", T.BODY[1]], T.INK)
	_toast.add_child(_toast_label)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
	for w in [header, encounter_face, dragon_face, preview, slots, actions, hand, picker]:
		w.intent.connect(func(data): intent.emit(data))


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
	var slots_before: Array = vs.get("places", [])
	vs = state
	if plan.is_empty():
		return
	header.render(vs)
	# The preview first: the layout depends on how tall it needs to be, as well as
	# how many cards and sets there are; everything else is drawn at the final sizes.
	_render_preview()
	plan = _replan(plan, vs)
	_place_hand_panel()
	_render_encounter()
	slots.render(vs)
	actions.render(vs)
	_answer_slots(slots_before, animate)
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
	slots.set_columns(p.get("place_rects", []))


## The slots answer a placement (contracts/role-slots.md): a newly filled slot's
## number flies up from its card and shows when it lands; a number the engine
## changed while its card stayed (an Element enabling the enhanced Spell) counts to
## its new value and the slot's edge flashes. At once under reduced motion.
func _answer_slots(before: Array, animate: bool) -> void:
	if not animate or UI.reduced_motion:
		return
	var old := {}
	for s in before:
		old[s.key] = s
	for s in vs.get("places", []):
		if s.state != "filled" or s.number == null:
			continue
		var key: String = s.key
		var was: Dictionary = old.get(key, {})
		var label: Label = slots.number_label(s.set, s.role)
		if label == null:
			continue
		if was.get("card_id") != s.card_id:
			var card: Control = hand.card(s.card_id)
			if card == null or flight == null:
				continue
			label.modulate.a = 0.0
			var colour: Color = T.ether_ink(s.ether) if s.ether != null else T.INK
			var text := label.text
			var from := card.get_global_rect().get_center()
			# The slot's containers sort on the next frame; aim once they have.
			_fly_after_layout.call_deferred(label, text, from, colour, s.set, s.role)
		elif was.get("number") != null and was.number != s.number:
			_count(label, int(was.number), int(s.number), s.role == "boost")
			slots.flare(s.card_id, T.GOLD, T.BASE)


func _fly_after_layout(label, text: String, from: Vector2, colour: Color, set_index: int, role: String) -> void:
	# The slots may have been redrawn (and this label freed) before the frame came.
	if not is_instance_valid(label):
		return
	var to := slots.number_rect(set_index, role).get_center()
	var tw: Tween = flight.fly_text(text, from, to, colour)
	if tw == null:
		label.modulate.a = 1.0
		return
	tw.finished.connect(func():
		if is_instance_valid(label):
			label.modulate.a = 1.0)


## Count a slot's number from `from` to `to` over T.COUNT.
func _count(label: Label, from: int, to: int, signed: bool) -> void:
	var show := func(v: float) -> void:
		if is_instance_valid(label):
			label.text = ("+%d" % roundi(v)) if signed else str(roundi(v))
	show.call(from)
	label.create_tween().tween_method(show, float(from), float(to), T.COUNT)


## The Hand's panel: round its whole band while cards float under the places, round
## the places alone once every card has one, and round the cards themselves when
## there are no places (setup, Soak).
func _place_hand_panel() -> void:
	if plan.is_empty():
		return
	var panel: Rect2 = plan.regions.hand.grow(6.0)
	var floating: int = vs.get("floating", []).size() if not vs.is_empty() else plan.hand_count
	if not plan.place_rects.is_empty() and floating == 0:
		var row: Rect2 = plan.place_rects[0]
		for r in plan.place_rects:
			row = row.merge(r)
		panel = Rect2(plan.regions.hand.position.x - 6.0, row.position.y - 6.0, plan.regions.hand.size.x + 12.0, row.size.y + 12.0)
	elif plan.place_rects.is_empty():
		var Solver = load("res://ui/model/layout_solver.gd")
		var rects: Array = Solver.floating_rects(plan, plan.hand_count)
		if rects.is_empty():
			return
		var cards: Rect2 = rects[0]
		for r in rects:
			cards = cards.merge(r)
		panel = Rect2(cards.position.x - 10.0, cards.position.y - 24.0, cards.size.x + 20.0, cards.size.y + 36.0)
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
		slots.flare(card_id, colour, duration)
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
	var area := Rect2(plan.regions.encounter.position, plan.regions.preview.end - plan.regions.encounter.position)
	detail.show_card(vs.cards[_hover_id], area)


## Finish anything in motion and show the current state exactly.
## Start or stop the cards' Ether fields moving: off while an overlay covers the screen.
func set_fields_live(on: bool) -> void:
	hand.set_live(on)
	detail.set_live(on)


func settle() -> void:
	hand.finish()
	preview.settle()


func toast(text: String) -> void:
	if text == "":
		return
	_toast_label.text = text
	_toast.reset_size()
	var region: Rect2 = plan.regions.hand if not plan.is_empty() else Rect2(Vector2.ZERO, size)
	_toast.position = Vector2(region.get_center().x - _toast.size.x / 2.0, region.end.y - _toast.size.y - 4)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, T.BASE)


## Global points that effects travel between.
func point(anchor: String) -> Vector2:
	match anchor:
		"deck", "discard", "trash":
			return header.pile_point(anchor)
		"encounter":
			return _regions.encounter.global_position + _regions.encounter.size / 2.0
		"xp":
			return xp_purse.point() if xp_purse.visible else _regions.preview.global_position + _regions.preview.size / 2.0
		"preview":
			return _regions.preview.global_position + _regions.preview.size / 2.0
		"hand":
			return plan.regions.hand.get_center() if not plan.is_empty() else size / 2.0
	return size / 2.0


func encounter_node() -> Control:
	for face in [encounter_face, dragon_face, setup_face]:
		if face.visible:
			return face
	return _regions.encounter


func _replan(p: Dictionary, state: Dictionary) -> Dictionary:
	var count: int = state.hand.size()
	var Solver = load("res://ui/model/layout_solver.gd")
	var places: int = Solver.place_count(state)
	var final: bool = Solver.is_final(state)
	# The preview asks for the height its fullest look needs this Encounter, so this
	# changes between steps and Encounters, not as cards are placed.
	var needed := roundi(_preview_widget().needed_height(p.regions.preview.size.x))
	var enc = state.get("encounter")
	var least: int = T.DRAGON_MIN if enc != null and enc.kind.begins_with("final") else T.ENCOUNTER_MIN
	if p.get("for", []) == [count, places, final, needed, least]:
		return p
	var q: Dictionary = Solver.solve(p.view, p.safe, count, places, p.points_per_unit, needed, least, p.get("undersized_upright", false), final)
	q["safe"] = p.safe
	q["undersized_upright"] = p.get("undersized_upright", false)
	q["for"] = [count, places, final, needed, least]
	if q.regions != p.regions or q.place_rects != p.get("place_rects"):
		plan = q
		_place_regions(q)
	return q


## Whichever of the preview, the Soak meter and the XP purse is showing.
func _preview_widget() -> Control:
	return soak_meter if soak_meter.visible else (xp_purse if xp_purse.visible else preview)


func _render_encounter() -> void:
	var enc = vs.encounter
	encounter_face.visible = enc != null and (enc.kind == "enemy" or enc.kind == "journey")
	dragon_face.visible = enc != null and enc.kind.begins_with("final")
	setup_face.visible = enc == null
	if encounter_face.visible:
		encounter_face.render(enc)
	elif dragon_face.visible:
		dragon_face.render(enc)
		var p = vs.preview
		dragon_face.set_reached(p.tier if p != null and p.status == "ready" else -1)
	else:
		_render_setup_face()


## Before the first Encounter: the dragon you are hunting and what this step is for.
func _render_setup_face() -> void:
	var key: String = vs.stage.dragon + vs.phase
	if key == _setup_key:
		return
	_setup_key = key
	setup_face.clear()
	var art: String = vs.stage.get("art", "")
	setup_face.set_look(vs.stage.get("element", ""), "sigil_" + vs.stage.dragon, art, Art.head(art))
	setup_face.band.add_child(UI.icon_rect("crown", 34, T.GOLD))
	var title := UI.label("PREPARE YOUR DECK", T.HEADING, T.INK)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	setup_face.band.add_child(title)
	# The words keep to the left; the dragon waits on the right.
	for line in [["Four Regions lie between you and the dragon. Your sixteen Mage Cards are your only weapons, and your deck is your time.", T.BODY, T.INK], ["", T.LABEL, T.INK], ["The cards you choose start at a different Level.", T.LABEL, T.INK_MUTED]]:
		if line[0] == "":
			setup_face.body.add_child(UI.spacer())
			continue
		var l := UI.label(line[0], line[1], line[2], true)
		l.custom_minimum_size.x = 230
		l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		setup_face.body.add_child(l)


func _render_preview() -> void:
	var phase: String = vs.phase
	var soak: bool = vs.soak != null
	var upgrade: bool = phase == "upgrade"
	soak_meter.visible = soak
	xp_purse.visible = upgrade
	preview.visible = not soak and not upgrade
	if soak:
		soak_meter.render(vs)
	elif upgrade:
		xp_purse.render(vs)
	else:
		preview.render(vs)


func _fill(parent: Control, child: Control) -> void:
	parent.add_child(child)
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
