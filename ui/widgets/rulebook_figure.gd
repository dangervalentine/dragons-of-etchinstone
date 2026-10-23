extends RefCounted
## Labelled examples for the rulebook, drawn with the same widgets as play so a
## reader learns the cards as they will see them: a Mage Card beside its figures
## named, an enemy and a Journey from Region 1, and a dragon with its tiers.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Art = preload("res://ui/model/art.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const CardFace = preload("res://ui/widgets/card_face.gd")
## The badges' least size on the page, so an Armor shield (0.92 of it) is still a
## tap target; and the face's height round four rows of them (its band, margins and
## gaps; face_frame.gd and encounter_face.gd _fit()).
const BADGE_MIN := 48.0
const FACE_CHROME := 110.0
## The Key Card line under the face, and the gap above it.
const CAPTION_H := 30.0
const EncounterFace = preload("res://ui/widgets/encounter_face.gd")
const DragonStats = preload("res://ui/widgets/dragon_stats.gd")
const Glossary = preload("res://ui/model/glossary.gd")

const ACTION_NAMES := {"attack": "Attack", "move": "Move", "flex": "Attack or Move"}
const ROW := {"family": "sans", "size": T.TEXT_MIN, "weight": 500, "spacing": 0.0, "upper": false}
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
	var row := UI.hbox(T.SPACE_4)
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
	# Top to bottom as the card reads: the Level, the strip's Key Card and Upgrade
	# cost, then the figures down the field.
	_row(rows, "crown", "Level %d of 4" % LEVEL, T.PARCHMENT)
	_row(rows, key.type, "Key Card: %s %d" % [key.type.capitalize(), key.index])
	_row(rows, "upgrade", "Upgrade: %d XP" % lv.upgrade_cost if lv.upgrade_cost != null else "Highest Level", T.PARCHMENT)
	_row(rows, "initiative", "Initiative %d" % lv.initiative)
	_row(rows, lv.basic.type if lv.basic.type != "flex" else "attack", "Basic: %d %s" % [lv.basic.value, ACTION_NAMES[lv.basic.type]])
	_row(rows, lv.enhanced.element, "Enhanced: %d %s" % [lv.enhanced.value, ACTION_NAMES[lv.enhanced.type]], T.ether_ink(lv.enhanced.element))
	_row(rows, "boost", "Boost +%d" % lv.boost)
	_row(rows, "armor", "Armor %d" % lv.armor.value)
	row.add_child(rows)
	return row


static func _row(parent: Control, icon: String, text: String, colour: Color = T.PARCHMENT) -> void:
	# Set against the aside's right edge.
	var r := UI.hbox(6)
	r.alignment = BoxContainer.ALIGNMENT_END
	r.add_child(UI.icon_rect(icon, 24, colour))
	r.add_child(UI.label(text, ROW, T.PARCHMENT))
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
	var enc: Dictionary = ViewState.encounter_model(db, 1, kind, 1, null, key)
	var col := UI.vbox(T.SPACE_1)
	var face := EncounterFace.new()
	# The face takes the room the page gives it (owner, 2026-10-23: every page the
	# same height, so nothing may grow it), its badges as large as that allows; the
	# Key Card line goes under the frame, and only where there is room for it.
	var with_caption := size.y - CAPTION_H - T.SPACE_1 >= FACE_CHROME + 4.0 * BADGE_MIN
	face.badge_min = BADGE_MIN
	face.custom_minimum_size = Vector2(size.x, minf(size.y - (CAPTION_H + T.SPACE_1 if with_caption else 0.0), 360.0))
	face.intent.connect(func(d): on_help.call(d))
	face.render(enc)
	col.add_child(face)
	if with_caption:
		var caption := UI.label("%s · Key Card %s, Level %d" % [enc.subtitle, enc.key_card.name, enc.key_card.level], T.BODY_SM, T.PARCHMENT_MUTED)
		caption.clip_text = true
		caption.custom_minimum_size = Vector2(size.x, CAPTION_H)
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		col.add_child(caption)
	return col


static func _dragon(db, size: Vector2) -> Control:
	var id: String = db.dragon_ids()[0]
	var d: Dictionary = db.dragon(id)
	var col := UI.vbox(T.SPACE_2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := UI.hbox(T.SPACE_4)
	var art_name: String = Art.dragon(id)
	head.add_child(UI.texture_rect(UI.head(art_name), minf(96.0, size.y * 0.35), Color.WHITE))
	var names := UI.vbox(0)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_child(UI.label(d.name, T.HEADING, T.PARCHMENT))
	names.add_child(UI.label(d.title, T.BODY_SM, T.PARCHMENT_MUTED))
	head.add_child(names)
	col.add_child(head)
	var stats: Control = DragonStats.make(d)
	stats.custom_minimum_size.x = size.x
	col.add_child(stats)
	return col
