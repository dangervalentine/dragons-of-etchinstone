extends "res://ui/widgets/face_frame.gd"
## The dragon in the Final Battle, with its tiers as a ladder. On the Final Journey
## each rung is a Move total and the Time Penalty it leaves; against the Final Enemy
## each rung is an Attack total and the damage still taken.

const StatChip = preload("res://ui/widgets/stat_chip.gd")

signal intent(data: Dictionary)

var _shown := {}
var _rungs: Array = []
var _reached := -2


func render(enc: Dictionary) -> void:
	if enc != _shown:
		_shown = enc.duplicate(true)
		_reached = -2
		_build(enc)


## Light the rung the current Action Sets reach; -1 for none.
func set_reached(tier: int) -> void:
	if tier == _reached:
		return
	_reached = tier
	for i in _rungs.size():
		var on: bool = i == tier
		var passed: bool = tier >= 0 and i < tier
		var rung: PanelContainer = _rungs[i]
		rung.add_theme_stylebox_override("panel", UI.box(
			Color(T.GOLD, 0.92) if on else Color(T.BG_BAND, 0.8),
			T.GOLD if on or passed else Color(T.INK, 0.25), 2 if on else 1, T.RADIUS_S, 5))
		for l in rung.find_children("*", "Label", true, false):
			l.add_theme_color_override("font_color", T.BG_BASE if on else T.INK)
		for t in rung.find_children("*", "TextureRect", true, false):
			if not t.has_meta("keep_colour"):
				t.modulate = T.BG_BASE if on else T.INK


func _build(enc: Dictionary) -> void:
	clear()
	_rungs = []
	var d: Dictionary = enc.dragon
	var journey: bool = enc.kind == "final_journey"
	var colour: Color = T.ether(enc.element)
	set_look(enc.element, "sigil_" + d.id)
	band.add_child(UI.icon_rect("sigil_" + d.id, 44, colour))
	var title := UI.label(d.name.to_upper(), T.HEADING, T.INK)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band.add_child(title)
	var sub := UI.label(d.title, T.LABEL, T.INK_MUTED)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.clip_text = true
	band.add_child(sub)

	if journey:
		var intro := UI.label("Add the Move of both Action Sets. Reach a tier to go on; the higher the tier, the less time it costs.", T.LABEL, T.INK, true)
		intro.custom_minimum_size.x = 360
		body.add_child(intro)
	else:
		var stats := UI.hbox(4)
		stats.add_child(_chip({"icon": "initiative", "text": str(d.initiative), "color": T.BG_BAND,
			"caption": "Initiative", "glossary_id": "initiative", "min_size": Vector2(84, 72)}))
		stats.add_child(_chip({"icon": "attack", "text": "+%d" % d.early_damage.value, "color": colour, "ink": T.BG_BASE,
			"element": d.early_damage.element, "plate": true, "caption": "Early", "glossary_id": "early_damage",
			"min_size": Vector2(108, 72)}))
		for a in d.armor:
			stats.add_child(_chip({"icon": "armor", "text": str(a.value), "color": T.ether(a.element), "ink": T.BG_BASE,
				"element": a.element, "caption": "Armor", "glossary_id": "armor", "min_size": Vector2(70, 72)}))
		body.add_child(stats)

	var tiers: Array = d.mp_tiers if journey else d.hp_tiers
	var rows := []
	for i in tiers.size():
		rows.append(_rung(i, tiers[i], journey, enc.element))
	rows.reverse()
	for r in rows:
		body.add_child(r)
	if not journey and enc.carried_damage > 0:
		body.add_child(UI.label("Plus %d damage carried from the Journey." % enc.carried_damage, T.LABEL, T.BAD, true))
	body.add_child(UI.spacer())
	_fit()
	set_reached(-1)


func _rung(index: int, tier: Dictionary, journey: bool, element: String) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size.y = 46
	p.add_theme_stylebox_override("panel", UI.box(Color(T.BG_BAND, 0.8), Color(T.INK, 0.25), 1, T.RADIUS_S, 5))
	var row := UI.hbox(6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var need: int = tier.mp.value if journey else tier.hp
	var cost: int = tier.time_penalty if journey else tier.attack.value
	row.add_child(UI.icon_rect("move" if journey else "attack", 28))
	row.add_child(UI.label(str(need), T.NUMERAL))
	if journey:
		var e := UI.icon_rect(element, 22, T.ether(element))
		row.add_child(e)
	var arrow := UI.label("then", T.LABEL, T.INK)
	arrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(arrow)
	row.add_child(UI.icon_rect("time" if journey else "hp", 28))
	row.add_child(UI.label(str(cost), T.NUMERAL))
	row.add_child(UI.label("time" if journey else "damage", T.LABEL))
	p.add_child(row)
	UI.ignore_mouse(p)
	_rungs.append(p)
	return p


func _chip(opts: Dictionary) -> Control:
	var c: Control = StatChip.make(opts)
	c.help.connect(func(id, source): intent.emit({"type": "help", "id": id, "source": source}))
	return c
