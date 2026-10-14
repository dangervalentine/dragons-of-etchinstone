extends "res://ui/widgets/face_frame.gd"
## The dragon in the Final Battle. On the Final Journey the road runs off to the
## dragon, small and waiting on the far side, beside the ladder of Move totals and
## the Time Penalty each leaves. When the Final Enemy begins the dragon crosses to
## the near side, large, and its battle figures and the ladder of Attack totals
## take the other side.

const StatChip = preload("res://ui/widgets/stat_chip.gd")

signal intent(data: Dictionary)

## Share of the width the picture takes; the figures take the rest. The battle
## has more figures, so the dragon gives up a little more room then.
const SCENE_SHARE := 0.4
const BATTLE_SHARE := 0.33
const CROSSING := 0.9

var _shown := {}
var _kind := ""
var _rungs: Array = []
var _reached := -2
var _stage := Control.new()
var _scene := Control.new()
var _road := Creature.new()
var _beast := Creature.new()
var _panel := VBoxContainer.new()
var _how: Label
var _room := INF
var _tween: Tween


func _init() -> void:
	super._init()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene.add_child(_road)
	_scene.add_child(_beast)
	_stage.add_child(_scene)
	_panel.add_theme_constant_override("separation", 6)
	_stage.add_child(_panel)
	_panel.sort_children.connect(_trim)
	_stage.resized.connect(func(): _place(false))


func render(enc: Dictionary) -> void:
	if enc == _shown:
		return
	var crossing: bool = _kind == "final_journey" and enc.kind != "final_journey" and is_inside_tree()
	_shown = enc.duplicate(true)
	_reached = -2
	_build(enc)
	_place(crossing and not UI.reduced_motion)


## Light every rung the current Action Sets reach, since reaching one tier meets
## the easier ones too; -1 for none.
func set_reached(tier: int) -> void:
	if tier == _reached:
		return
	_reached = tier
	for i in _rungs.size():
		var on: bool = i <= tier
		var rung: PanelContainer = _rungs[i]
		rung.add_theme_stylebox_override("panel", UI.box(
			Color(T.GOLD, 0.92) if on else Color(T.BG_BAND, 0.85),
			T.GOLD if on else Color(T.INK, 0.25), 2 if on else 1, T.RADIUS_S, 4))
		for l in rung.find_children("*", "Label", true, false):
			l.add_theme_color_override("font_color", T.BG_BASE if on else T.INK)
		for t in rung.find_children("*", "TextureRect", true, false):
			if not t.has_meta("keep_colour"):
				t.modulate = T.BG_BASE if on else T.INK


func _build(enc: Dictionary) -> void:
	var d: Dictionary = enc.dragon
	var journey: bool = enc.kind == "final_journey"
	var colour: Color = T.ether(enc.element)
	var first := _kind == ""
	_kind = enc.kind
	if first or band.get_child_count() == 0:
		clear()
		set_look(enc.element, "")
		band.add_child(UI.icon_rect("sigil_" + d.id, 44, colour))
		var title := UI.label(d.name.to_upper(), T.HEADING, T.INK)
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		band.add_child(title)
		var sub := UI.label(d.title, T.LABEL, T.INK_MUTED)
		sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sub.clip_text = true
		band.add_child(sub)
		body.add_child(_stage)
		_road.setup(enc.scene, Color(colour.lightened(0.5), 0.5), "", false)
		_beast.setup(enc.art, Color(colour.lightened(0.4), 0.9), enc.element)
	_road.visible = true

	for c in _panel.get_children():
		_panel.remove_child(c)
		c.queue_free()
	_rungs = []
	_how = null
	if journey:
		var intro := UI.label("THE FINAL JOURNEY", ["body_bold", T.LABEL[1]], T.GOLD)
		_panel.add_child(intro)
		var how := UI.label("Add the Move of both sets. Each tier reached costs less time.", T.LABEL, T.INK, true)
		how.custom_minimum_size.x = 200
		_panel.add_child(how)
		_how = how
	else:
		_panel.add_child(UI.label("THE FINAL ENEMY", ["body_bold", T.LABEL[1]], T.GOLD))
		# One row of figures, named once underneath; each explains itself when pressed.
		var stats := HFlowContainer.new()
		stats.add_theme_constant_override("h_separation", 2)
		stats.add_theme_constant_override("v_separation", 2)
		stats.add_child(_chip({"icon": "initiative", "text": str(d.initiative), "color": T.BG_BAND,
			"glossary_id": "initiative", "min_size": Vector2(44, 48)}))
		stats.add_child(_chip({"icon": "attack", "text": "+%d" % d.early_damage.value, "color": colour, "ink": T.BG_BASE,
			"element": d.early_damage.element, "plate": true, "glossary_id": "early_damage", "min_size": Vector2(84, 48)}))
		for a in d.armor:
			stats.add_child(_chip({"icon": "armor", "text": str(a.value), "color": T.ether(a.element), "ink": T.BG_BASE,
				"element": a.element, "glossary_id": "armor", "min_size": Vector2(44, 48)}))
		_panel.add_child(stats)
		var names := "Initiative · early · Armor"
		if enc.carried_damage > 0:
			names += " · %d carried" % enc.carried_damage
		var caption := UI.label(names, T.LABEL, T.INK_MUTED, true)
		caption.custom_minimum_size.x = 200
		_panel.add_child(caption)
		_how = caption
	var tiers: Array = d.mp_tiers if journey else d.hp_tiers
	var rows := []
	for i in tiers.size():
		rows.append(_rung(tiers[i], journey, enc.element))
	# The journey ladder runs from the easiest Move down to the hardest; the
	# battle ladder puts the hardest Attack on top.
	if not journey:
		rows.reverse()
	for r in rows:
		_panel.add_child(r)
	set_reached(-1)


## Lay out the picture and the figures; `crossing` animates the dragon coming over.
func _place(crossing: bool) -> void:
	var w := _stage.size.x
	var h := _stage.size.y
	if w <= 0:
		return
	var journey := _kind == "final_journey"
	var scene_w := roundf(w * (SCENE_SHARE if journey else BATTLE_SHARE))
	var scene_x := w - scene_w if journey else 0.0
	var panel_x := 0.0 if journey else scene_w + T.S
	var panel := Rect2(panel_x, 0, w - scene_w - T.S, h)
	var scene := Rect2(scene_x, 0, scene_w, h)
	# On the road, the dragon is small and far off at the top of the picture;
	# in battle it fills its side.
	var road_side := minf(scene_w, h * 0.75)
	var road := Rect2((scene_w - road_side) / 2.0, h - road_side, road_side, road_side)
	var far := minf(scene_w * 0.5, h * 0.36)
	var beast_far := Rect2(scene_w - far, 0, far, far)
	var near := minf(scene_w, h * 0.95)
	var beast_near := Rect2((scene_w - near) / 2.0, (h - near) / 2.0, near, near)
	var beast: Rect2 = beast_far if journey else beast_near
	_fit_ladder(panel)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_road.position = road.position
	_road.size = road.size
	if not crossing:
		_panel.position = panel.position
		_panel.size = panel.size
		_scene.position = scene.position
		_scene.size = scene.size
		_beast.position = beast.position
		_beast.size = beast.size
		_road.modulate.a = 1.0 if journey else 0.0
		return
	# The dragon comes across the field: the figures slide away, the road fades,
	# and the dragon grows into the near side.
	var start := _beast.global_position
	_scene.position = scene.position
	_scene.size = scene.size
	_beast.global_position = start
	_panel.size = panel.size
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_panel.modulate.a = 0.0
	_panel.position = panel.position
	_tween.tween_property(_beast, "position", beast.position, CROSSING)
	_tween.tween_property(_beast, "size", beast.size, CROSSING)
	_tween.tween_property(_road, "modulate:a", 0.0, CROSSING * 0.6)
	_tween.tween_property(_panel, "modulate:a", 1.0, CROSSING * 0.5).set_delay(CROSSING * 0.6)


## On short screens the ladder would run out of the frame; drop the line that
## explains the panel first, since each rung and figure explains itself.
## Wrapped text and figures only know their height once laid out, so this
## checks after each sort of the panel.
func _fit_ladder(panel: Rect2) -> void:
	_room = panel.size.y
	if _how != null:
		_how.visible = true


func _trim() -> void:
	if _how == null or not _how.visible or _panel.get_child_count() == 0:
		return
	var last: Control = _panel.get_child(-1)
	if last.position.y + last.size.y > _room:
		_how.visible = false


func _rung(tier: Dictionary, journey: bool, element: String) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size.y = 36
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var need: int = tier.mp.value if journey else tier.hp
	var cost: int = tier.time_penalty if journey else tier.attack.value
	row.add_child(UI.icon_rect("move" if journey else "attack", 24))
	row.add_child(UI.label(str(need), ["display_bold", 28]))
	if journey:
		var e := UI.icon_rect(element, 20, T.ether(element))
		e.set_meta("keep_colour", true)
		row.add_child(e)
	var arrow := UI.label("→", ["display_bold", 24], T.INK)
	arrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(arrow)
	row.add_child(UI.icon_rect("time" if journey else "hp", 24))
	row.add_child(UI.label(str(cost), ["display_bold", 28]))
	p.tooltip_text = ("Move %d or more: lose %d time" if journey else "Attack %d or more: take %d damage") % [need, cost]
	p.add_child(row)
	UI.ignore_mouse(p)
	_rungs.append(p)
	return p


func _chip(opts: Dictionary) -> Control:
	var c: Control = StatChip.make(opts)
	c.help.connect(func(id, source): intent.emit({"type": "help", "id": id, "source": source}))
	return c
