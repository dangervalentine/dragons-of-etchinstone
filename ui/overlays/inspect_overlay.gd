extends "res://ui/overlays/overlay.gd"
## A card shown large beside the Levels on either side of it: what a Downgrade
## would leave (or that it would be Trashed), and what an Upgrade gives and costs.

const CardFace = preload("res://ui/widgets/card_face.gd")
const Glossary = preload("res://ui/model/glossary.gd")


func setup(db, model: Dictionary, content: Rect2) -> void:
	var id: String = model.id
	var m: Dictionary = db.mage(id)
	var level: int = model.level
	set_dim(0.93)
	var row := UI.hbox(T.XL)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.position = content.position
	row.size = Vector2(content.size.x, content.size.y - 40)
	var h := minf(content.size.y - 150, 440.0)
	var side := Vector2(h * 0.8 * T.CARD_ASPECT, h * 0.8)
	row.add_child(_column("IF DOWNGRADED", _face(db, m, level - 1, side) if level > 1 else _note("Trashed", "trash", side),
		_changes(db, id, level, level - 1) if level > 1 else "A Level 1 card is Trashed and scores nothing.", T.BAD))
	row.add_child(_column("LEVEL %d" % level, _face(db, m, level, Vector2(h * T.CARD_ASPECT, h)), m.name, T.GOLD))
	var cost = db.mage_level(id, level).upgrade_cost
	row.add_child(_column("IF UPGRADED", _face(db, m, level + 1, side) if cost != null else _note("Max Level", "crown", side),
		("Costs %d XP. " % cost + _changes(db, id, level, level + 1)) if cost != null else "This card is at its highest Level.", T.GOOD))
	var hint := UI.label("Tap anywhere to close", T.LABEL, T.INK_MUTED)
	hint.position = Vector2(content.position.x, content.end.y - 30)
	hint.size.x = content.size.x
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	appear()


func _column(title: String, face: Control, caption: String, colour: Color) -> Control:
	var col := UI.vbox(T.S)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UI.label(title, ["display_bold", 24], colour)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(face)
	var c := UI.label(caption, T.LABEL, T.INK, true)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.custom_minimum_size.x = face.custom_minimum_size.x + 60
	col.add_child(c)
	return col


func _face(db, m: Dictionary, level: int, sz: Vector2) -> Control:
	var f := CardFace.new()
	f.custom_minimum_size = sz
	f.set_model({"id": m.id, "name": m.name, "element": m.element, "level": level, "stats": db.mage_level(m.id, level)})
	return f


func _note(text: String, icon: String, sz: Vector2) -> Control:
	var p := UI.panel(T.BG_SURFACE, T.LINE_SOFT, 1, T.RADIUS_CARD)
	p.custom_minimum_size = sz
	var col := UI.vbox(T.S)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var i := UI.icon_rect(icon, 72, T.INK_MUTED)
	col.add_child(i)
	var l := UI.label(text.to_upper(), ["display_bold", 26], T.INK_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	p.add_child(col)
	return p


## What differs between two Levels, in words.
func _changes(db, id: String, from: int, to: int) -> String:
	var a: Dictionary = db.mage_level(id, from)
	var b: Dictionary = db.mage_level(id, to)
	var out := []
	if a.initiative != b.initiative:
		out.append("Initiative %d" % b.initiative)
	if a.basic.value != b.basic.value:
		out.append("basic %d" % b.basic.value)
	if a.enhanced.value != b.enhanced.value:
		out.append("enhanced %d" % b.enhanced.value)
	if a.boost != b.boost:
		out.append("Boost +%d" % b.boost)
	if a.armor.value != b.armor.value or a.armor.element != b.armor.element:
		out.append("Armor %d" % b.armor.value)
	return ("Becomes " + ", ".join(out) + ".") if not out.is_empty() else "Only the Key Card changes."
