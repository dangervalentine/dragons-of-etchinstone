extends HBoxContainer
## One Action Set: three slots for Spell, Element and Boost. An empty slot names
## its role; a filled slot shows what its card contributes. The slot the next
## card will fill is ringed in gold. Against an enemy, the Boost slot is followed
## by a toggle that sends the Boost to Attack or to Initiative.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal intent(data: Dictionary)

const ROLES := ["spell", "element", "boost"]
const ROLE_NAMES := {"spell": "Spell", "element": "Element", "boost": "Boost"}
const ROLE_ICONS := {"spell": "spell", "element": "element_role", "boost": "boost"}

var set_index := 0
var _slots := {}


func _init() -> void:
	add_theme_constant_override("separation", 6)


func render(vs: Dictionary) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_slots = {}
	if vs.sets.is_empty() and vs.played != null and set_index == 0:
		_render_played(vs)
		return
	if set_index >= vs.sets.size():
		return
	var s: Dictionary = vs.sets[set_index]
	var two: bool = vs.sets.size() > 1
	for role in ROLES:
		var id = s.roles.get(role)
		var active: bool = vs.active_slot == [set_index, role] and vs.mode == "none"
		var b := _slot(role, vs.cards.get(id) if id != null else null, active, two)
		add_child(b)
		_slots[role] = b
	if s.show_boost_to:
		var to_attack: bool = s.boost_to == "attack"
		var t := UI.button("" if two else ("Attack" if to_attack else "Initiative"), "normal", "attack" if to_attack else "initiative")
		t.custom_minimum_size = Vector2(T.TAP_MIN if two else 150, T.TAP_MIN)
		# Sized like the slot subtitles so "Initiative" fits on one line.
		t.add_theme_font_override("font", UI.font(T.LABEL[0]))
		t.add_theme_font_size_override("font_size", T.LABEL[1])
		t.tooltip_text = "Boost adds to %s. Tap to switch." % ("Attack" if to_attack else "Initiative")
		t.pressed.connect(func(): intent.emit({"type": "toggle_boost_to", "set": set_index}))
		var wrap := UI.vbox(0)
		wrap.alignment = BoxContainer.ALIGNMENT_CENTER
		if not two:
			var cap := UI.label("Boost adds to", ["body_medium", 20], T.INK_MUTED)
			cap.set_meta("small_ok", "a caption over the button that says the same")
			cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			wrap.add_child(cap)
		t.size_flags_vertical = Control.SIZE_EXPAND_FILL
		wrap.add_child(t)
		add_child(wrap)


## After a battle: the cards just played, which will be discarded, and the
## Reserve, which stays for the next Hand.
func _render_played(vs: Dictionary) -> void:
	var p: Dictionary = vs.played
	for role in ROLES:
		var id = p.roles.get(role)
		var name: String = vs.cards[id].name if id != null and vs.cards.has(id) else "—"
		add_child(_recap(ROLE_ICONS[role], ROLE_NAMES[role].to_upper(), name, "Discarded after", T.LINE_SOFT, T.INK_MUTED))
	var r = p.reserve
	if r != null and vs.cards.has(r):
		var kept: bool = p.reserve_kept
		add_child(_recap("reserve", "RESERVE", vs.cards[r].name, "Stays in your Hand" if kept else "Discarded after",
			T.GOLD if kept else T.LINE_SOFT, T.GOLD if kept else T.INK_MUTED))
	else:
		add_child(_recap("reserve", "RESERVE", "None", "No card left over", T.LINE_SOFT, T.INK_MUTED))


func _recap(icon: String, role: String, name: String, fate: String, border: Color, ink: Color) -> Control:
	var p := UI.panel(T.BG_SURFACE, border, 2, T.RADIUS_M, 6)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := UI.vbox(2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var head := UI.hbox(5)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(UI.icon_rect(icon, 22, ink))
	head.add_child(UI.label(role, ["body_bold", T.LABEL[1]], ink))
	col.add_child(head)
	var n := UI.label(name, ["display", T.TEXT_MIN], T.INK)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.clip_text = true
	col.add_child(n)
	var f := UI.label(fate, T.LABEL, ink)
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(f)
	p.add_child(col)
	return p


## Global rectangle of a slot, for cards and effects that aim at it.
func slot_rect(role: String) -> Rect2:
	var b: Control = _slots.get(role)
	return b.get_global_rect() if b != null else get_global_rect()


func _slot(role: String, card, active: bool, compact: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	var filled: bool = card != null
	var border: Color = T.GOLD if active else (T.ether(card.element) if filled else T.LINE_SOFT)
	var bg: Color = T.BG_RAISED if filled else T.BG_SURFACE
	b.add_theme_stylebox_override("normal", UI.box(bg, border, 3 if active else 2, T.RADIUS_M, 6))
	b.add_theme_stylebox_override("hover", UI.box(bg.lightened(0.07), border.lightened(0.2), 3 if active else 2, T.RADIUS_M, 6))
	b.add_theme_stylebox_override("pressed", UI.box(bg.darkened(0.1), border, 3, T.RADIUS_M, 6))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, T.GOLD, 3, T.RADIUS_M, 6))
	UI.press_feedback(b)
	var col := UI.vbox(2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	var head := UI.hbox(5)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(UI.icon_rect(ROLE_ICONS[role], 22, T.GOLD if active or filled else T.INK_MUTED))
	# In the narrow Final Battle slots the role icon and set number stand for the name.
	var role_name: String = str(set_index + 1) if compact else ROLE_NAMES[role].to_upper()
	head.add_child(UI.label(role_name, ["body_bold", T.LABEL[1]], T.GOLD if active else T.INK_MUTED))
	b.tooltip_text = "%s %d" % [ROLE_NAMES[role], set_index + 1] if compact else ROLE_NAMES[role]
	col.add_child(head)
	if filled:
		if not compact:
			var name := UI.label(card.name, ["display", T.TEXT_MIN], T.INK)
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name.clip_text = true
			col.add_child(name)
		col.add_child(_contribution(role, card, compact))
	else:
		var hint := UI.label("next card goes here" if active and not compact else ("tap a card" if not compact else ("next" if active else "empty")),
			T.LABEL, T.INK if active else Color(T.INK_MUTED, 0.7))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(hint)
	UI.ignore_mouse(col)
	b.add_child(col)
	b.pressed.connect(func():
		if filled:
			intent.emit({"type": "take_back", "id": card.id})
		else:
			intent.emit({"type": "select_slot", "set": set_index, "role": role}))
	return b


## What a card gives in a role: its action values, its Ether and Initiative, or its Boost.
func _contribution(role: String, card: Dictionary, compact := false) -> Control:
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var lv: Dictionary = card.stats
	var num := ["display_bold", 26]
	match role:
		"spell":
			if compact:
				var cc: Color = T.ether(lv.enhanced.element)
				row.add_child(UI.label(str(lv.basic.value), num))
				var sep := UI.label("/", ["body_medium", 20], T.INK_MUTED)
				sep.set_meta("small_ok", "a separator")
				row.add_child(sep)
				row.add_child(UI.label(str(lv.enhanced.value), num, cc))
				row.add_child(UI.icon_rect(lv.enhanced.element, 20, cc))
				return row
			row.add_child(UI.label(str(lv.basic.value), num))
			_action_icons(row, lv.basic.type, T.INK)
			var sep := UI.label(" or ", ["body_medium", 18], T.INK_MUTED)
			sep.set_meta("small_ok", "a separator")
			row.add_child(sep)
			var c: Color = T.ether(lv.enhanced.element)
			row.add_child(UI.label(str(lv.enhanced.value), num, c))
			_action_icons(row, lv.enhanced.type, c)
			row.add_child(UI.icon_rect(lv.enhanced.element, 20, c))
		"element":
			row.add_child(UI.icon_rect(card.element, 26, T.ether(card.element)))
			row.add_child(UI.icon_rect("initiative", 24, T.INK_MUTED))
			row.add_child(UI.label(str(lv.initiative), num))
		"boost":
			row.add_child(UI.label("+%d" % lv.boost, num))
			row.add_child(UI.icon_rect("boost", 22, T.INK_MUTED))
	return row


func _action_icons(row: HBoxContainer, type: String, colour: Color) -> void:
	if type != "move":
		row.add_child(UI.icon_rect("attack", 20, colour))
	if type != "attack":
		row.add_child(UI.icon_rect("move", 20, colour))
