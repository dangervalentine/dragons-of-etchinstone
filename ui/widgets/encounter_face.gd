extends "res://ui/widgets/face_frame.gd"
## The face of the current Region Encounter: what the Key Card asks for.
## An enemy shows HP, Initiative, Attack and Armor; a Journey shows MP and its Time
## Penalty; either may carry a Hardship, an Ability or a Peril.

const StatChip = preload("res://ui/widgets/stat_chip.gd")
const Glossary = preload("res://ui/model/glossary.gd")

signal intent(data: Dictionary)

var _shown := {}


func render(enc: Dictionary) -> void:
	if enc == _shown:
		return
	_shown = enc.duplicate(true)
	clear()
	var enemy: bool = enc.kind == "enemy"
	var d: Dictionary = enc.data
	var colour: Color = T.ether(enc.element)
	set_look(enc.element, "sigil_" + str(enc.element))

	band.add_child(UI.icon_rect("enemy" if enemy else "journey", 34, colour))
	var title := UI.label(enc.title.to_upper(), T.HEADING, T.INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band.add_child(title)
	band.add_child(_chip({"icon": "xp", "text": str(d.xp), "color": T.GOLD, "ink": T.BG_BASE,
		"glossary_id": "xp", "min_size": Vector2(64, 50)}))

	var targets := UI.hbox(6)
	targets.alignment = BoxContainer.ALIGNMENT_BEGIN
	if enemy:
		targets.add_child(_chip({"icon": "hp", "text": str(d.hp), "color": T.HP, "caption": "HP", "glossary_id": "hp"}))
		targets.add_child(_chip({"icon": "initiative", "text": str(d.initiative), "color": T.BG_BAND,
			"caption": "Initiative", "glossary_id": "initiative", "min_size": Vector2(88, 72)}))
		targets.add_child(_chip({"icon": "attack", "text": str(d.attack.value), "color": colour, "ink": T.BG_BASE,
			"element": d.attack.element, "plate": true, "caption": "Attack", "glossary_id": "attack", "min_size": Vector2(104, 72)}))
		for a in d.armor:
			targets.add_child(_chip({"icon": "armor", "text": str(a.value), "color": T.ether(a.element), "ink": T.BG_BASE,
				"element": a.element, "caption": "Armor", "glossary_id": "armor", "min_size": Vector2(78, 72)}))
	else:
		targets.add_child(_chip({"icon": "mp", "text": str(d.mp.value), "color": colour, "ink": T.BG_BASE,
			"element": d.mp.element, "plate": true, "caption": "MP to cover", "glossary_id": "mp", "min_size": Vector2(130, 72)}))
		targets.add_child(_chip({"icon": "time", "text": str(d.time_penalty), "color": T.BG_BAND,
			"plate": true, "caption": "Time Penalty", "glossary_id": "time", "min_size": Vector2(130, 72)}))
	body.add_child(targets)

	for effect in enc.effects:
		body.add_child(_effect_row(effect, enc.get("hardship_id", "") == effect))
	var gap := UI.spacer()
	body.add_child(gap)
	var key: Dictionary = enc.key_card
	var caption := UI.label("Key Card · %s · Level %d" % [key.name, key.level], T.LABEL, Color(T.INK, 0.8))
	caption.clip_text = true
	body.add_child(caption)
	_fit()


func _chip(opts: Dictionary) -> Control:
	var c: Control = StatChip.make(opts)
	c.help.connect(func(id, source): intent.emit({"type": "help", "id": id, "source": source}))
	return c


## One Hardship, Ability or Peril: its icon, its name and what it does, in a line.
func _effect_row(id: String, _hardship: bool) -> Control:
	var e: Dictionary = Glossary.entry(id)
	var b := Button.new()
	b.custom_minimum_size.y = 64
	b.set_meta("help_target", true)
	b.flat = true
	b.mouse_default_cursor_shape = Control.CURSOR_HELP
	b.add_theme_stylebox_override("normal", UI.box(Color(T.BG_BAND, 0.72), Color(T.BAD, 0.7), 1, T.RADIUS_S, 6))
	b.add_theme_stylebox_override("hover", UI.box(Color(T.BG_BAND, 0.9), T.BAD, 1, T.RADIUS_S, 6))
	b.add_theme_stylebox_override("pressed", UI.box(T.BG_BAND, T.BAD, 2, T.RADIUS_S, 6))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, T.GOLD, 3, T.RADIUS_S, 6))
	var row := UI.hbox(T.S)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	row.add_child(UI.icon_rect(e.icon, 36, T.BAD))
	var text := UI.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_child(UI.label(e.name, ["body_bold", T.LABEL[1] + 2], T.INK))
	var short := UI.label(e.short, T.LABEL, T.INK_MUTED)
	short.clip_text = true
	text.add_child(short)
	row.add_child(text)
	UI.ignore_mouse(row)
	b.add_child(row)
	b.pressed.connect(func(): intent.emit({"type": "help", "id": id, "source": b}))
	return b
