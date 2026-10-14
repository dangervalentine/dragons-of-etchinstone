extends Control
## The one screen used for every step of play, from choosing starting cards to the
## last blow against the dragon. Seven regions in fixed places: header, Encounter,
## preview, slots, Hand, secondary actions and the primary action. Widgets update
## in place; card nodes persist so they can move.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const HeaderBar = preload("res://ui/widgets/header_bar.gd")
const EncounterFace = preload("res://ui/widgets/encounter_face.gd")
const DragonFace = preload("res://ui/widgets/dragon_face.gd")
const FaceFrame = preload("res://ui/widgets/face_frame.gd")
const PreviewPanel = preload("res://ui/widgets/preview_panel.gd")
const SoakMeter = preload("res://ui/widgets/soak_meter.gd")
const XpPurse = preload("res://ui/widgets/xp_purse.gd")
const SlotRow = preload("res://ui/widgets/slot_row.gd")
const HandTray = preload("res://ui/widgets/hand_tray.gd")
const ActionBar = preload("res://ui/widgets/action_bar.gd")
const EtherPicker = preload("res://ui/widgets/ether_picker.gd")
const CardDetail = preload("res://ui/widgets/card_detail.gd")

signal intent(data: Dictionary)

var header := HeaderBar.new()
var encounter_face := EncounterFace.new()
var dragon_face := DragonFace.new()
var setup_face := FaceFrame.new()
var preview := PreviewPanel.new()
var soak_meter := SoakMeter.new()
var xp_purse := XpPurse.new()
var slots := HBoxContainer.new()
var actions := ActionBar.new()
var hand := HandTray.new()
var picker := EtherPicker.new()
var detail := CardDetail.new()
var _hover_id := ""
var _hover_timer := Timer.new()

var plan := {}
var vs := {}
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
	slots.add_theme_constant_override("separation", T.M)
	_fill(_regions.slots, slots)
	_fill(_regions.actions, actions)
	_fill(_regions.header, header)
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
	for w in [header, encounter_face, dragon_face, preview, actions, hand, picker]:
		w.intent.connect(func(data): intent.emit(data))


func apply_layout(p: Dictionary) -> void:
	plan = p
	for key in _regions:
		var r: Rect2 = p.regions[key] if key != "actions" else Rect2(p.regions.actions.position, p.regions.commit.end - p.regions.actions.position)
		_regions[key].position = r.position
		_regions[key].size = r.size
	actions.apply_layout(p.regions.actions, p.regions.commit)
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
	_render_encounter()
	_render_preview()
	_render_slots()
	actions.render(vs)
	# The hand plan depends on how many cards there are and how many sets.
	plan = _replan(plan, vs)
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


func _fused_top(state: Dictionary) -> String:
	if state.is_empty():
		return ""
	for id in state.hand:
		var f = state.cards[id].get("fuse")
		if f != null and f.part == "top":
			return id
	return ""


## A card's detail opens after the pointer rests on it a moment, over the left column.
func _on_hover(id: String, on: bool) -> void:
	if on:
		_hover_id = id
		_hover_timer.start()
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
	var sets: int = maxi(1, state.sets.size())
	if p.get("for", []) == [count, sets]:
		return p
	var Solver = load("res://ui/model/layout_solver.gd")
	var q: Dictionary = Solver.solve(p.view, p.safe, count, sets, p.points_per_unit)
	q["safe"] = p.safe
	q["for"] = [count, sets]
	if q.regions != p.regions:
		plan = q
		for key in _regions:
			var r: Rect2 = q.regions[key] if key != "actions" else Rect2(q.regions.actions.position, q.regions.commit.end - q.regions.actions.position)
			_regions[key].position = r.position
			_regions[key].size = r.size
		actions.apply_layout(q.regions.actions, q.regions.commit)
		_render_slots()
	return q


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
	setup_face.set_look(vs.stage.get("element", ""), "sigil_" + vs.stage.dragon, vs.stage.get("art", ""))
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


func _render_slots() -> void:
	var count: int = vs.sets.size() if not vs.sets.is_empty() else (1 if vs.played != null else 0)
	while slots.get_child_count() > count:
		var c := slots.get_child(slots.get_child_count() - 1)
		slots.remove_child(c)
		c.queue_free()
	while slots.get_child_count() < count:
		var row := SlotRow.new()
		row.set_index = slots.get_child_count()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.intent.connect(func(data): intent.emit(data))
		slots.add_child(row)
	for row in slots.get_children():
		row.render(vs)


func _fill(parent: Control, child: Control) -> void:
	parent.add_child(child)
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
