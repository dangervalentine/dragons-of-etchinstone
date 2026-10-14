extends RefCounted
## Labelled examples for the rulebook, drawn with the same widgets as play so a
## reader learns the cards as they will see them: a Mage Card beside its figures
## named, an enemy and a Journey from Region 1, and a dragon with its tiers.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Art = preload("res://ui/model/art.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const CardFace = preload("res://ui/widgets/card_face.gd")
const EncounterFace = preload("res://ui/widgets/encounter_face.gd")
const DragonStats = preload("res://ui/widgets/dragon_stats.gd")
const Glossary = preload("res://ui/model/glossary.gd")

const ACTION_NAMES := {"attack": "Attack", "move": "Move", "flex": "Attack or Move"}
const ROW := ["body_medium", T.TEXT_MIN]
## The Level the examples are shown at: every card starts there.
const LEVEL := 2


## An example of `kind` ("mage", "enemy", "journey" or "dragon") within `size`.
## Presses on its figures ask for an explanation through `on_help`.
static func make(kind: String, db, size: Vector2, on_help: Callable) -> Control:
	match kind:
		"mage":
			return _mage(db, size)
		"enemy", "journey":
			return _encounter(db, kind, size, on_help)
		"dragon":
			return _dragon(db, size)
	return Control.new()


static func _mage(db, size: Vector2) -> Control:
	var id: String = db.mage_ids()[0]
	var m: Dictionary = db.mage(id)
	var lv: Dictionary = db.mage_level(id, LEVEL)
	var row := UI.hbox(T.M)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := minf(size.y, 240.0)
	var face := CardFace.new()
	face.custom_minimum_size = Vector2(roundf(h * T.CARD_ASPECT), h)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face.set_model({"id": id, "name": m.name, "element": m.element, "level": LEVEL, "stats": lv})
	row.add_child(face)
	var rows := UI.vbox(2)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var key: Dictionary = lv.encounter
	_row(rows, "crown", "Level %d of 4" % LEVEL, T.GOLD)
	_row(rows, key.type, "Key Card: %s %d" % [key.type.capitalize(), key.index])
	_row(rows, "initiative", "Initiative %d" % lv.initiative)
	_row(rows, lv.basic.type if lv.basic.type != "flex" else "attack", "Basic: %d %s" % [lv.basic.value, ACTION_NAMES[lv.basic.type]])
	_row(rows, lv.enhanced.element, "Enhanced: %d %s" % [lv.enhanced.value, ACTION_NAMES[lv.enhanced.type]], T.ether(lv.enhanced.element))
	_row(rows, "boost", "Boost +%d" % lv.boost)
	_row(rows, "armor", "Armor %d" % lv.armor.value)
	_row(rows, "xp", "Upgrade: %d XP" % lv.upgrade_cost if lv.upgrade_cost != null else "Highest Level", T.GOLD)
	row.add_child(rows)
	return row


static func _row(parent: Control, icon: String, text: String, colour: Color = T.INK) -> void:
	var r := UI.hbox(6)
	r.add_child(UI.icon_rect(icon, 24, colour))
	r.add_child(UI.label(text, ROW, T.INK))
	parent.add_child(r)


## A Region 1 Encounter, named by a real card that brings it as Key Card.
static func _encounter(db, kind: String, size: Vector2, on_help: Callable) -> Control:
	var key_id: String = db.mage_ids()[0]
	for id in db.mage_ids():
		var e: Dictionary = db.mage_level(id, LEVEL).encounter
		if e.type == kind and e.index == 1:
			key_id = id
			break
	var key := {"id": key_id, "name": db.mage(key_id).name, "level": LEVEL, "element": db.mage(key_id).element}
	var face := EncounterFace.new()
	face.custom_minimum_size = Vector2(size.x, minf(size.y, 320.0))
	face.intent.connect(func(d): on_help.call(d))
	face.render(ViewState.encounter_model(db, 1, kind, 1, null, key))
	return face


static func _dragon(db, size: Vector2) -> Control:
	var id: String = db.dragon_ids()[0]
	var d: Dictionary = db.dragon(id)
	var col := UI.vbox(T.S)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := UI.hbox(T.M)
	var art_name: String = Art.dragon(id)
	var colour: Color = T.ether(d.early_damage.element)
	head.add_child(UI.texture_rect(UI.art_crop(art_name, Art.head(art_name)), minf(96.0, size.y * 0.35), colour))
	var names := UI.vbox(0)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_child(UI.label(d.name.to_upper(), ["display_bold", 28], T.INK))
	names.add_child(UI.label(d.title, T.LABEL, T.INK_MUTED))
	head.add_child(names)
	col.add_child(head)
	var stats: Control = DragonStats.make(d)
	stats.custom_minimum_size.x = size.x
	col.add_child(stats)
	return col
