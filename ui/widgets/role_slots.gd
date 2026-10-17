extends Control
## The role strip: one short section over each place of the Hand, in the rulebook's
## order (specs/009 contracts/board-layout.md), lined up over the place's column. A
## section names its Role and, once a card is there, shows large the number that
## card gives in that Role (the Spell's value from the engine, the Element's
## Initiative, the Boost's bonus, the Reserve's Boost while it counts) beside what
## it counts toward. It never shows the card's name, which the card already shows.
## The section the hint points at is edged in the focus colour, and while a card is
## held every place that can take it glows. Against an Enemy the Boost's target icon
## sends it to Attack or to Initiative; against a Ranged one the Reserve's switch
## gives it up. After a battle the same sections recap the set just played.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal intent(data: Dictionary)

const ROLE_ICONS := {"spell": "spell", "element": "element_role", "boost": "boost", "reserve": "reserve"}
const ROLE_NAMES := {"spell": "Spell", "element": "Element", "boost": "Boost", "reserve": "Reserve"}
## The section's figure; smaller in the Final Battle's narrow sections.
const NUMBER := T.NUMERAL_M
const NUMBER_NARROW := T.NUMERAL
## Below this width a section uses the smaller figure and a narrower switch.
const NARROW_W := 130.0
## The switches' side, the least tap target; with the Role line above it, it fills
## the strip's 88.
const TOGGLE_SIDE := 44.0

var _slots := {}
var _numbers := {}
## Each section's column, in global x: [x, width], one per place, from the layout.
var _columns: Array = []
## Where Set 2 starts, as a global x between two sections, or -1.
var _divider := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)


## The columns of the places (layout_solver's place_rects), so each section sits
## over its place.
func set_columns(rects: Array) -> void:
	_columns = []
	for r in rects:
		_columns.append([r.position.x, r.size.x])
	_place()


func render(vs: Dictionary) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_slots = {}
	_numbers = {}
	_divider = -1.0
	var list: Array = vs.get("places", [])
	for i in list.size():
		var s: Dictionary = list[i]
		var w: float = _columns[i][1] if i < _columns.size() else size.x / maxf(1.0, list.size())
		var b := _slot(s, w < NARROW_W, vs.get("sets", []).size() > 1)
		# The place the keyboard is aiming the held card at is edged in gold.
		var aim = vs.get("key_target")
		if aim != null and s.tap != null and s.tap.get("type") == "put" and typeof(s.tap.target) == typeof(aim) and s.tap.target == aim:
			var style = b.get_theme_stylebox("normal")
			style.edge = T.GOLD
			style.edge_width = 5.0
		add_child(b)
		_slots[s.key] = b
	_place()
	queue_redraw()


func _place() -> void:
	var children := get_children()
	_divider = -1.0
	var list_size := children.size()
	for i in list_size:
		var b: Control = children[i]
		if i < _columns.size():
			b.position = Vector2(_columns[i][0] - global_position.x, 0)
			b.size = Vector2(_columns[i][1], size.y)
		else:
			var w := size.x / maxf(1.0, list_size)
			b.position = Vector2(i * w, 0)
			b.size = Vector2(w - T.S, size.y)
		if b.get_meta("set_start", false) and i > 0:
			_divider = (children[i - 1].position.x + children[i - 1].size.x + b.position.x) / 2.0
	queue_redraw()


func _draw() -> void:
	# Between the two Action Sets of the Final Battle, a gold rule.
	if _divider >= 0.0:
		draw_line(Vector2(_divider, 4), Vector2(_divider, size.y - 4), T.GOLD, 2.0)


## Light the section a card fills for a moment, in `colour` (the board's answer to
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


## The key of a place: "reserve", or "set/role".
static func key_of(set_index: int, role: String) -> String:
	return "reserve" if role == "reserve" else "%d/%s" % [set_index, role]


## Global rectangle of a section, for effects that aim at it.
func slot_rect(set_index: int, role: String) -> Rect2:
	var b: Control = _slots.get(key_of(set_index, role))
	return b.get_global_rect() if b != null else get_global_rect()


## Global rectangle of a section's number, where a flying number lands.
func number_rect(set_index: int, role: String) -> Rect2:
	var l: Control = _numbers.get(key_of(set_index, role))
	return l.get_global_rect() if l != null and l.size != Vector2.ZERO else slot_rect(set_index, role)


## The label showing a section's number, or null; play_screen hides it while a
## number flies in and counts it when the engine's figure changes.
func number_label(set_index: int, role: String) -> Label:
	return _numbers.get(key_of(set_index, role))


func _slot(s: Dictionary, narrow: bool, two: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, T.TAP_MIN)
	b.clip_contents = true
	b.tooltip_text = s.tooltip
	b.set_meta("card_id", s.card_id if s.card_id != null else "")
	b.set_meta("set_start", s.get("set_start", false))
	var state: String = s.state
	var next := state == "next"
	var target := state == "target"
	var filled := state == "filled" or (target and s.card_id != null)
	var spent := state == "played" or state == "discarded" or state == "given_up"
	# A placed Boost against an Enemy waits for its target: lit like the next Role.
	var choices: Array = s.get("choices", [])
	var unchosen: bool = s.card_id != null and not choices.is_empty() and not choices.any(func(c): return c.on)
	next = next or unchosen
	var kept := state == "kept"
	var inactive := state == "inactive"
	# A section is a raised block of stone. The hinted one is edged in the focus
	# colour, like the parts of the Hand cards it asks for; a filled one in its
	# card's Ether; one that can take the held card glows.
	var edge: Color = T.ether(s.ether) if filled and s.ether != null else (T.GOLD if kept else Color(0, 0, 0, 0))
	if target:
		edge = T.FOCUS
	var normal := StoneStyle.new("plinth", 0.3 if spent or inactive else 0.5)
	normal.edge = edge
	normal.edge_width = 3.0
	if next or target:
		normal.glow = 1.0
	var hover := StoneStyle.new("plinth", 0.3)
	hover.edge = edge
	hover.edge_width = 3.0
	hover.glow = 1.0 if next or target else 0.5
	var down := StoneStyle.new("plinth", 0.7)
	down.pressed = true
	down.edge = edge
	for style in [normal, hover, down]:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_content_margin(side, 4)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, T.GOLD, 3, T.RADIUS_M, 4))
	UI.press_feedback(b)

	# Two lines: the Role on top; under it the number and what it counts toward.
	var col := UI.vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 1)
	var head := UI.hbox(4)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	var ink: Color = T.FOCUS if next or target else (T.GOLD if filled or kept else T.INK_MUTED)
	if inactive:
		ink = Color(T.INK_MUTED, 0.5)
	# A narrow section (the Final Battle's) gives its width to the name; the rule
	# between the sets and the tooltip say which set it is.
	var icon := UI.icon_rect(ROLE_ICONS[s.role], 22, ink)
	head.add_child(icon)
	icon.visible = not narrow
	var name: String = ROLE_NAMES[s.role]
	if two and not narrow and s.role != "reserve":
		name += " %d" % (s.set + 1)
	head.add_child(UI.label(name if narrow else name.to_upper(), T.LABEL, ink))
	# With its two targets under it, the Boost's number joins the Role line.
	var on_head: bool = not choices.is_empty() and s.number != null
	col.add_child(head)

	var key: String = s.key
	var row := UI.hbox(6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y = TOGGLE_SIDE
	if on_head:
		var n := UI.label("+%d" % s.number, T.LABEL_BOLD, T.INK)
		head.add_child(n)
		_numbers[key] = n
	elif s.number != null:
		if s.role == "element" and s.ether != null:
			row.add_child(UI.icon_rect(s.ether, 26, T.ether_ink(s.ether)))
		var text := ("+%d" % s.number) if s.role == "boost" or s.role == "reserve" else str(s.number)
		var num := UI.label(text, NUMBER_NARROW if narrow else NUMBER, T.INK)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if spent:
			num.modulate.a = 0.55
			num.draw.connect(func(): num.draw_line(Vector2(0, num.size.y * 0.55), Vector2(num.size.x, num.size.y * 0.45), T.INK_MUTED, 3.0))
		row.add_child(num)
		_numbers[key] = num
	elif spent:
		icon.modulate.a = 0.55
		icon.draw.connect(func(): icon.draw_line(Vector2(0, icon.size.y), Vector2(icon.size.x, 0), T.INK_MUTED, 3.0))
	elif kept:
		var stays := UI.label("Stays", T.LABEL, T.GOLD)
		stays.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(stays)
	# What the number counts toward; for the Boost against an Enemy and the Reserve
	# against a Ranged one, a switch.
	var toggles: Array = []
	if not choices.is_empty():
		for c in choices:
			var t := _choice(c, narrow)
			toggles.append(t)
			row.add_child(t)
	elif s.get("toggle_tap") != null:
		var t := _give_up(s, narrow)
		toggles.append(t)
		row.add_child(t)
	elif s.counts_to != "" and filled:
		row.add_child(UI.icon_rect(s.counts_to, 22, T.INK_MUTED))
	if s.get("rule", "") != "":
		# Steep or Freeze reads this Reserve: its mark sits beside the number.
		row.add_child(UI.icon_rect(s.rule, 24, T.BAD))
	col.add_child(row)
	UI.ignore_mouse(col)
	for t in toggles:
		t.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_child(col)
	if s.tap == null:
		b.disabled = true
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		var tap: Dictionary = s.tap
		b.pressed.connect(func(): intent.emit(tap))
	return b


## One of the Boost's two targets, Attack or Initiative: lit once chosen. Neither
## is chosen at first, so the player decides where the Boost goes.
func _choice(c: Dictionary, narrow: bool) -> Button:
	var t := _switch(UI.icon(c.to), narrow, c.on)
	t.tooltip_text = "Add the Boost to %s." % ("Attack" if c.to == "attack" else "Initiative")
	var tap: Dictionary = c.tap
	t.pressed.connect(func(): intent.emit(tap))
	return t


## Against a Ranged enemy, the switch that gives the Reserve up: struck through
## while it is given up.
func _give_up(s: Dictionary, narrow: bool) -> Button:
	var t := _switch(UI.icon("ranged"), narrow)
	var on: bool = s.get("given_up", false)
	t.tooltip_text = ("Your Reserve is given up: this enemy's Ranged strike is ignored. Tap to keep it." if on
		else "Give up your Reserve to ignore this enemy's Ranged strike")
	if on:
		t.draw.connect(func(): t.draw_line(Vector2(6, t.size.y - 6), Vector2(t.size.x - 6, 6), T.BAD, 3.0))
	var tap: Dictionary = s.toggle_tap
	t.pressed.connect(func(): intent.emit(tap))
	return t


func _switch(tex: Texture2D, narrow: bool, on := false) -> Button:
	var t := Button.new()
	t.custom_minimum_size = Vector2(TOGGLE_SIDE, TOGGLE_SIDE)
	t.set_meta("help_target", true)
	t.icon = tex
	t.expand_icon = true
	t.add_theme_constant_override("icon_max_width", 24)
	t.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var style := StoneStyle.new("inset", 0.6)
	style.edge = T.GOLD if on else T.LINE_SOFT
	if on:
		style.edge_width = 3.0
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, 4)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		t.add_theme_stylebox_override(st, style)
	t.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, T.GOLD, 2, T.RADIUS_S, 2))
	for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		t.add_theme_color_override(c, T.GOLD if on else T.INK)
	return t
