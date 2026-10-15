extends HBoxContainer
## The role rail: one compact token per role of each Action Set, a tap target tall.
## An empty token names its role by icon; a filled one shows what its card gives
## (never the card's name, which the lifted card below already shows). The token
## the next card fills is ringed in the focus colour. Against an enemy, a toggle
## sends the Boost to Attack or to Initiative. After a battle the same tokens recap
## what was played and whether the Reserve stays.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

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
	var state: String = t.state
	var next := state == "next"
	var filled := state == "filled"
	var spent := state == "played" or state == "discarded"
	var kept := state == "kept"
	# The token being filled next wears the same focus colour as the parts of the
	# Hand cards it is asking for.
	var border: Color = T.FOCUS if next else (T.ether(t.ether) if filled else (T.GOLD if kept else T.LINE_SOFT))
	var bg: Color = T.BG_RAISED if filled or kept else T.BG_SURFACE
	var normal := UI.box(bg, border, 3 if next else 2, T.RADIUS_M, 4)
	if next:
		normal.shadow_color = Color(T.FOCUS, 0.35)
		normal.shadow_size = 10
	else:
		normal.shadow_color = Color(0, 0, 0, 0.3)
		normal.shadow_size = 6
		normal.shadow_offset = Vector2(0, 2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", UI.box(bg.lightened(0.07), border.lightened(0.2), 3 if next else 2, T.RADIUS_M, 4))
	b.add_theme_stylebox_override("pressed", UI.box(bg.darkened(0.1), border, 3, T.RADIUS_M, 4))
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
