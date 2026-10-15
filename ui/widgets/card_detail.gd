extends PanelContainer
## A larger copy of a hovered Mage Card beside every figure on it spelled out:
## what it asks for as Key Card, each action, Boost, Armor and the Upgrade, plus
## what it means for the current step. Shown over the left column while the
## pointer rests on a card; it never takes a press.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const CardFace = preload("res://ui/widgets/card_face.gd")
const Glossary = preload("res://ui/model/glossary.gd")

const ACTION_NAMES := {"attack": "Attack", "move": "Move", "flex": "Attack or Move"}

var _face := CardFace.new()
var _rows := VBoxContainer.new()
var _shown_id := ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	add_theme_stylebox_override("panel", UI.box(Color(T.BG_RAISED, 0.98), T.GOLD, 2, T.RADIUS_M, 14))
	var row := UI.hbox(14)
	_face.custom_minimum_size = Vector2(170, 238)
	_face.motion = false
	_face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_face)
	_rows.add_theme_constant_override("separation", 5)
	_rows.custom_minimum_size.x = 230
	row.add_child(_rows)
	add_child(row)
	UI.ignore_mouse(row)


func show_card(m: Dictionary, area: Rect2) -> void:
	_shown_id = m.id
	_face.set_model(m)
	_face.motion = true
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	var lv: Dictionary = m.stats
	var name := UI.label(m.name.to_upper(), ["display_bold", 26], T.INK, true)
	name.custom_minimum_size.x = 230
	_rows.add_child(name)
	_line(m.element, "%s Ether · Level %d of %d" % [m.element.capitalize(), m.level, m.max_level], T.ether_ink(m.element))
	var key: Dictionary = lv.encounter
	var key_text := "%s (%s %d)" % [m.key_name, key.type.capitalize(), key.index]
	if lv.hardship != null:
		key_text += ", with %s" % Glossary.entry(lv.hardship).name
	_row(key.type, "As Key Card", key_text)
	_row("initiative", "Initiative", str(lv.initiative))
	_row("attack" if lv.basic.type != "move" else "move", "Basic action", "%d %s" % [lv.basic.value, ACTION_NAMES[lv.basic.type]])
	var e: String = lv.enhanced.element
	_row(e, "Enhanced action", "%d %s, with a %s Element" % [lv.enhanced.value, ACTION_NAMES[lv.enhanced.type], e.capitalize()], T.ether_ink(e))
	_row("boost", "Boost", "+%d" % lv.boost)
	var armor: String = str(lv.armor.value)
	if lv.armor.element != null:
		armor += ", %d against %s" % [lv.armor.value * 2, String(lv.armor.element).capitalize()]
	_row("armor", "Armor (Soaks)", armor)
	_row("xp", "Upgrade", ("%d XP to Level %d" % [lv.upgrade_cost, m.level + 1]) if lv.upgrade_cost != null else "Highest Level", T.GOLD)
	var now := _context(m)
	if now != "":
		var l := UI.label(now, ["body_bold", T.LABEL[1]], T.GOLD, true)
		l.custom_minimum_size.x = 230
		_rows.add_child(l)
	reset_size()
	position = Vector2(area.position.x, area.position.y + maxf(0.0, (area.size.y - size.y) * 0.2)) - get_parent().global_position
	if not visible:
		visible = true
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, T.FAST)


## Whether the face's Ether field moves; it only does while the detail is shown.
func set_live(on: bool) -> void:
	_face.motion = on and visible


func hide_card(id := "") -> void:
	if id == "" or id == _shown_id:
		visible = false
		_shown_id = ""
		_face.motion = false


## What the card means right now: its role, its Soak, its Upgrade, or why it is out.
func _context(m: Dictionary) -> String:
	var parts := []
	if m.role != null:
		parts.append("Placed as %s" % ["Spell", "Element", "Boost"][["spell", "element", "boost"].find(m.role[1])])
	if m.get("reserve", false):
		parts.append("This is your Reserve")
	if m.get("fate", "") == "stays":
		parts.append("Stays in your Hand")
	elif m.get("fate", "") == "spent":
		parts.append("Discarded after this Encounter")
	if m.get("note", "") != "":
		parts.append(m.note)
	if not m.get("eligible", true) and m.get("reason", "") != "":
		parts.append(m.reason)
	var alt = m.get("alt")
	if alt != null:
		parts.append(alt.label if alt.trashed else "%s: Level %d" % [alt.label, alt.level])
	return "\n".join(parts)


func _row(icon: String, label: String, value: String, colour: Color = T.INK) -> void:
	var r := UI.hbox(8)
	var i := UI.icon_rect(icon, 26, colour)
	i.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	r.add_child(i)
	var col := UI.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label(label, T.LABEL, T.INK_MUTED))
	var v := UI.label(value, ["body_bold", T.BODY[1] - 2], T.INK, true)
	v.custom_minimum_size.x = 190
	col.add_child(v)
	r.add_child(col)
	_rows.add_child(r)


func _line(icon: String, text: String, colour: Color) -> void:
	var r := UI.hbox(6)
	r.add_child(UI.icon_rect(icon, 22, colour))
	r.add_child(UI.label(text, T.LABEL, T.INK_MUTED))
	_rows.add_child(r)
