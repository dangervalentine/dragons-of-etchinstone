extends HBoxContainer
## The role rail: one compact token per role of each Action Set, a tap target tall.
## An empty token names its role by icon; a filled one shows what its card gives
## (never the card's name, which the lifted card below already shows). The token
## the next card fills is ringed in the focus colour. Against an enemy, a toggle
## sends the Boost to Attack or to Initiative. After a battle the same tokens recap
## what was played and whether the Reserve stays.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal intent(data: Dictionary)

const ROLE_ICONS := {"spell": "spell", "element": "element_role", "boost": "boost", "reserve": "reserve"}

var _tokens := {}


func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", T.S)


func render(vs: Dictionary) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tokens = {}
	var two: bool = vs.sets.size() > 1
	for t in vs.get("rail", []):
		var b := _toggle(t, two) if t.role == "boost_to" else _token(t, two)
		add_child(b)
		_tokens["%d/%s" % [t.set, t.role]] = b


## Light the token a card fills for a moment, in `colour` (the board's answer to
## placing it); held still under reduced motion.
func flare(card_id: String, colour: Color, duration: float) -> void:
	for key in _tokens:
		var b: Control = _tokens[key]
		if not b is Button or b.tooltip_text == "":
			continue
		var style = b.get_theme_stylebox("normal")
		if style.get("glow") == null or b.get_meta("card_id", "") != card_id:
			continue
		var was: float = style.glow
		style.glow_colour = colour
		if UI.reduced_motion:
			style.glow = 1.0
			b.get_tree().create_timer(T.BASE).timeout.connect(func():
				if is_instance_valid(b):
					style.glow = was)
			return
		var tw := b.create_tween()
		tw.tween_property(style, "glow", 1.0, duration * 0.3)
		tw.tween_property(style, "glow", was, duration * 1.4)


## Global rectangle of a token, for effects that aim at it.
func token_rect(set_index: int, role: String) -> Rect2:
	var b: Control = _tokens.get("%d/%s" % [set_index, role])
	return b.get_global_rect() if b != null else get_global_rect()


func _token(t: Dictionary, two: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(T.TAP_MIN if two else T.RAIL_TOKEN_W, T.TAP_MIN)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	b.tooltip_text = t.tooltip
	b.set_meta("card_id", t.card_id if t.card_id != null else "")
	var state: String = t.state
	var next := state == "next"
	var filled := state == "filled"
	var spent := state == "played" or state == "discarded"
	var kept := state == "kept"
	# A token is a small place cut into the stone. The one being filled next is lit
	# with the same focus colour as the parts of the Hand cards it is asking for;
	# a filled one is edged in its card's Ether.
	var edge: Color = T.ether(t.ether) if filled else (T.GOLD if kept else Color(0, 0, 0, 0))
	var normal := StoneStyle.new("inset", 0.6)
	normal.edge = edge
	if next:
		normal.glow = 1.0
	var hover := StoneStyle.new("inset", 0.4)
	hover.edge = edge
	hover.glow = 0.6 if not next else 1.0
	var down := StoneStyle.new("inset", 0.9)
	down.edge = edge
	for style in [normal, hover, down]:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			style.set_content_margin(side, 4)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, T.GOLD, 3, T.RADIUS_M, 4))
	UI.press_feedback(b)
	var col := UI.vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	var head := UI.hbox(4)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	var ink: Color = T.FOCUS if next else (T.GOLD if filled or kept else T.INK_MUTED)
	var icon := UI.icon_rect(ROLE_ICONS[t.role], 26, ink)
	if spent:
		icon.modulate.a = 0.55
		icon.draw.connect(func(): icon.draw_line(Vector2(0, icon.size.y), Vector2(icon.size.x, 0), T.INK_MUTED, 3.0))
	head.add_child(icon)
	if two:
		var pip := UI.label(str(t.set + 1), ["body_bold", T.TEXT_MIN], ink)
		head.add_child(pip)
	col.add_child(head)
	if filled:
		col.add_child(_contribution(t.role, t.contribution, two))
	UI.ignore_mouse(col)
	b.add_child(col)
	if t.tap == null:
		b.disabled = true
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		var tap: Dictionary = t.tap
		b.pressed.connect(func(): intent.emit(tap))
	return b


func _toggle(t: Dictionary, two: bool) -> Control:
	var to_attack: bool = t.target == "attack"
	var b := UI.button("" if two else ("Attack" if to_attack else "Initiative"), "normal", "attack" if to_attack else "initiative")
	UI.style_stone_button(b)
	b.custom_minimum_size = Vector2(T.TAP_MIN if two else 150, T.TAP_MIN)
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Sized like the token numerals' captions so "Initiative" fits on one line.
	b.add_theme_font_override("font", UI.font(T.LABEL[0]))
	b.add_theme_font_size_override("font_size", T.LABEL[1])
	b.tooltip_text = t.tooltip
	var tap: Dictionary = t.tap
	b.pressed.connect(func(): intent.emit(tap))
	return b


## What a card gives in a role: its action values, its Ether and Initiative, or its Boost.
func _contribution(role: String, v: Array, compact: bool) -> Control:
	var row := UI.hbox(3)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var num := ["display_bold", 26]
	match role:
		"spell":
			var cc: Color = T.ether_ink(v[2])
			row.add_child(UI.label(str(v[0]), num))
			var sep := UI.label("/", ["body_medium", 20], T.INK_MUTED)
			sep.set_meta("small_ok", "a separator")
			row.add_child(sep)
			row.add_child(UI.label(str(v[1]), num, cc))
			if not compact:
				row.add_child(UI.icon_rect(v[2], 20, cc))
		"element":
			row.add_child(UI.icon_rect(v[0], 24, T.ether_ink(v[0])))
			if not compact:
				row.add_child(UI.icon_rect("initiative", 20, T.INK_MUTED))
			row.add_child(UI.label(str(v[1]), num))
		"boost":
			row.add_child(UI.label("+%d" % v[0], num))
	return row
