extends HBoxContainer
## The role slots: a full-size raised box for each role of each Action Set, above the
## Hand (contracts/role-slots.md). A filled slot shows, large, the number its card
## gives in that role (the Spell's value from the engine, the Element's Initiative,
## the Boost's bonus) over what it counts toward. It never shows the card's name,
## which the card in the Hand already shows. The slot the next card fills is edged
## in the focus colour. Against an Enemy the Boost slot's target icon sends the Boost
## to Attack or to Initiative. After a battle the same slots recap the set just
## played and whether the Reserve stays.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal intent(data: Dictionary)

const ROLE_ICONS := {"spell": "spell", "element": "element_role", "boost": "boost", "reserve": "reserve"}
const ROLE_NAMES := {"spell": "Spell", "element": "Element", "boost": "Boost", "reserve": "Reserve"}
## The slot's large figure; 44 at full size, smaller in the Final Battle's narrow slots.
const NUMBER := ["display_bold", 44]
const NUMBER_NARROW := ["display_bold", 36]
## Below this width a slot shows its role by icon only.
const NAME_MIN_W := 130.0
## The Boost target icon's hit area, like the other small help targets.
const TOGGLE_SIDE := 44.0

var _slots := {}
var _numbers := {}


func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", T.S)


func render(vs: Dictionary) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_slots = {}
	_numbers = {}
	var list: Array = vs.get("slots", [])
	var narrow: bool = list.size() > 4 or (size.x > 0.0 and (size.x - (list.size() - 1) * T.S) / maxf(1.0, list.size()) < NAME_MIN_W)
	for s in list:
		var b := _slot(s, narrow, vs.sets.size() > 1)
		add_child(b)
		_slots["%d/%s" % [s.set, s.role]] = b


## Light the slot a card fills for a moment, in `colour` (the board's answer to
## placing it); held still under reduced motion.
func flare(card_id: String, colour: Color, duration: float) -> void:
	for key in _slots:
		var b: Control = _slots[key]
		if b.get_meta("card_id", "") != card_id:
			continue
		var style = b.get_theme_stylebox("normal")
		if style.get("glow") == null:
			continue
		var was: float = style.glow
		if not style.has_meta("rest_colour"):
			style.set_meta("rest_colour", style.glow_colour)
		var rest: Color = style.get_meta("rest_colour")
		style.glow_colour = colour
		if UI.reduced_motion:
			style.glow = 1.0
			b.get_tree().create_timer(T.BASE).timeout.connect(func():
				if is_instance_valid(b):
					style.glow = was
					style.glow_colour = rest)
			return
		var tw := b.create_tween()
		tw.tween_property(style, "glow", 1.0, duration * 0.3)
		tw.tween_property(style, "glow", was, duration * 1.4)
		tw.tween_callback(func(): style.glow_colour = rest)


## Global rectangle of a slot, for effects that aim at it.
func slot_rect(set_index: int, role: String) -> Rect2:
	var b: Control = _slots.get("%d/%s" % [set_index, role])
	return b.get_global_rect() if b != null else get_global_rect()


## Global rectangle of a slot's number, where a flying number lands.
func number_rect(set_index: int, role: String) -> Rect2:
	var l: Control = _numbers.get("%d/%s" % [set_index, role])
	return l.get_global_rect() if l != null and l.size != Vector2.ZERO else slot_rect(set_index, role)


## The label showing a slot's number, or null; play_screen hides it while a number
## flies in and counts it when the engine's figure changes.
func number_label(set_index: int, role: String) -> Label:
	return _numbers.get("%d/%s" % [set_index, role])


func _slot(s: Dictionary, narrow: bool, two: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	b.tooltip_text = s.tooltip
	b.set_meta("card_id", s.card_id if s.card_id != null else "")
	var state: String = s.state
	var next := state == "next"
	var filled := state == "filled"
	var spent := state == "played" or state == "discarded"
	var kept := state == "kept"
	# A slot is a raised block of stone. The next one is edged in the focus colour,
	# like the parts of the Hand cards it asks for; a filled one in its card's Ether.
	var edge: Color = T.ether(s.ether) if filled and s.ether != null else (T.GOLD if kept else Color(0, 0, 0, 0))
	var normal := StoneStyle.new("plinth", 0.4 if spent else 0.5)
	normal.edge = edge
	normal.edge_width = 3.0
	if next:
		normal.glow = 1.0
	var hover := StoneStyle.new("plinth", 0.3)
	hover.edge = edge
	hover.edge_width = 3.0
	hover.glow = 1.0 if next else 0.5
	var down := StoneStyle.new("plinth", 0.7)
	down.pressed = true
	down.edge = edge
	for style in [normal, hover, down]:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_content_margin(side, 6)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, T.GOLD, 3, T.RADIUS_M, 4))
	UI.press_feedback(b)

	var col := UI.vbox(2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	var head := UI.hbox(4)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	var ink: Color = T.FOCUS if next else (T.GOLD if filled or kept else T.INK_MUTED)
	var icon := UI.icon_rect(ROLE_ICONS[s.role], 24 if filled else 30, ink)
	head.add_child(icon)
	if two:
		head.add_child(UI.label(str(s.set + 1), ["body_bold", T.TEXT_MIN], ink))
	elif not narrow:
		head.add_child(UI.label(ROLE_NAMES[s.role].to_upper(), T.LABEL, ink))
	col.add_child(head)

	var key := "%d/%s" % [s.set, s.role]
	if s.number != null:
		var row := UI.hbox(4)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		if s.role == "element" and s.ether != null:
			row.add_child(UI.icon_rect(s.ether, 30, T.ether_ink(s.ether)))
		var text := ("+%d" % s.number) if s.role == "boost" else str(s.number)
		var num := UI.label(text, NUMBER_NARROW if narrow else NUMBER, T.INK)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if spent:
			num.modulate.a = 0.55
			num.draw.connect(func(): num.draw_line(Vector2(0, num.size.y * 0.55), Vector2(num.size.x, num.size.y * 0.45), T.INK_MUTED, 3.0))
		row.add_child(num)
		_numbers[key] = num
		col.add_child(row)
	elif spent:
		icon.modulate.a = 0.55
		icon.draw.connect(func(): icon.draw_line(Vector2(0, icon.size.y), Vector2(icon.size.x, 0), T.INK_MUTED, 3.0))
	elif kept:
		var stays := UI.label("Stays", T.LABEL, T.GOLD)
		stays.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(stays)

	# What the number counts toward; for the Boost against an Enemy, a switch.
	var toggle: Button = null
	if s.counts_to != "" and (filled or s.get("toggle_tap") != null):
		var foot := UI.hbox(4)
		foot.alignment = BoxContainer.ALIGNMENT_CENTER
		if s.get("toggle_tap") != null:
			toggle = _toggle(s)
			foot.add_child(toggle)
		else:
			foot.add_child(UI.icon_rect(s.counts_to, 24, T.INK_MUTED))
		col.add_child(foot)
	UI.ignore_mouse(col)
	if toggle != null:
		toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_child(col)
	if s.tap == null:
		b.disabled = true
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		var tap: Dictionary = s.tap
		b.pressed.connect(func(): intent.emit(tap))
	return b


## The Boost's target, Attack or Initiative, as a small switch in its slot.
func _toggle(s: Dictionary) -> Button:
	var to_attack: bool = s.boost_to == "attack"
	var t := Button.new()
	t.custom_minimum_size = Vector2(TOGGLE_SIDE * 2, TOGGLE_SIDE)
	t.set_meta("help_target", true)
	t.icon = UI.icon("attack" if to_attack else "initiative")
	t.expand_icon = true
	t.add_theme_constant_override("icon_max_width", 26)
	t.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.tooltip_text = "Boost adds to %s. Tap to switch." % ("Attack" if to_attack else "Initiative")
	var style := StoneStyle.new("inset", 0.6)
	style.edge = T.LINE_SOFT
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, 4)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		t.add_theme_stylebox_override(st, style)
	t.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, T.GOLD, 2, T.RADIUS_S, 2))
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		t.add_theme_color_override(c, T.INK)
	var tap: Dictionary = s.toggle_tap
	t.pressed.connect(func(): intent.emit(tap))
	return t
