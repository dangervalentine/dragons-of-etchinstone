extends "res://ui/overlays/overlay.gd"
## A card shown large at every one of its Levels, side by side: each Level is its
## own card in this game. The current Level is raised and marked; the ones either
## side say what a Downgrade would leave and what an Upgrade gives and costs.
## Opened from the Encounter face (`key`) it shows only the Key Card that named the
## Encounter, at its current Level, its Key Card part lifted.

const CardFace = preload("res://ui/widgets/card_face.gd")
const Glossary = preload("res://ui/model/glossary.gd")


func setup(db, model: Dictionary, content: Rect2, key := false) -> void:
	var id: String = model.id
	var m: Dictionary = db.mage(id)
	var level: int = model.level
	var count: int = 1 if key else m.levels.size()
	set_dim(0.93)
	var row := UI.hbox(T.SPACE_5)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.position = content.position
	row.size = Vector2(content.size.x, content.size.y - 40)
	# The largest face that fits every Level in a row, with room for titles and captions.
	var by_width := (content.size.x - (count - 1) * T.SPACE_5 - count * 24) / count / T.CARD_ASPECT
	var h := minf(minf(content.size.y - 190, 440.0), by_width)
	var sz := Vector2(roundf(h * T.CARD_ASPECT), roundf(h))
	for lv in ([level] if key else range(1, count + 1)):
		var face = _face(db, m, lv, sz)
		if key:
			face.set_focus({"regions": ["key"]})
		var title := "LEVEL %d" % lv
		var colour := T.PARCHMENT_MUTED
		var caption := ""
		var sign := ""
		if lv == level:
			title = "CURRENT · LEVEL %d" % lv
			colour = T.PARCHMENT
			caption = m.name
			if key:
				title = "KEY CARD · LEVEL %d" % lv
				caption = "%s, on top of the Deck, names this Encounter." % m.name
			elif lv == 1:
				caption = "A Level 1 card is Trashed and scores nothing if Downgraded."
		elif lv == level - 1:
			title = "If downgraded"
			colour = T.DANGER
			sign = "down_arrow"
			caption = _changes(db, id, level, lv)
			face.set_model(face.model, _changed(db, id, level, lv), T.DANGER)
		elif lv == level + 1:
			var cost = db.mage_level(id, level).upgrade_cost
			title = "If upgraded · %d XP" % cost if cost != null else "If upgraded"
			colour = T.JADE
			sign = "crown"
			caption = _changes(db, id, level, lv)
			face.set_model(face.model, _changed(db, id, level, lv), T.PARCHMENT)
		row.add_child(_column(title, _framed(face, lv == level), caption, colour, sz.x, sign))
	var hint := UI.label("Tap anywhere to close", T.CAPTION, T.PARCHMENT_MUTED)
	hint.position = Vector2(content.position.x, content.end.y - 30)
	hint.size.x = content.size.x
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	appear()


## Opened from a pile in the header: the cards in it, each at its current Level, as
## large as lets PILE_AT_ONCE of them show at once, the rest reached by scrolling,
## under the pile's name and what it is. Dragging (or the wheel) scrolls; a tap
## anywhere that is not a drag closes, as on one card.
const PILE_AT_ONCE := 12
## The grids PILE_AT_ONCE cards can be laid out in, as columns × rows.
const PILE_GRIDS := [Vector2i(6, 2), Vector2i(4, 3), Vector2i(3, 4), Vector2i(2, 6), Vector2i(12, 1)]
## How far a press may move and still be a tap.
const TAP_SLOP := 12.0

var _scroll: ScrollContainer
var _press_at = null
var _dragged := false


func setup_pile(db, models: Array, pile: String, content: Rect2) -> void:
	set_dim(0.93)
	close_outside = false
	var entry: Dictionary = Glossary.entry(pile)
	var head := UI.vbox(T.SPACE_1)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.position = content.position
	head.size.x = content.size.x
	var n := models.size()
	var title := UI.label("%s · %d %s" % [entry.name, n, "Card" if n == 1 else "Cards"], T.HEADING, T.PARCHMENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	var about := UI.label(entry.text, T.BODY_SM, T.PARCHMENT, true)
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about.custom_minimum_size.x = minf(content.size.x, 720.0)
	about.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.add_child(about)
	add_child(head)
	var top: float = head.get_combined_minimum_size().y + T.SPACE_4
	var area := Rect2(content.position + Vector2(0, top), Vector2(content.size.x, content.size.y - top - 40))
	if n == 0:
		var none := UI.label("No cards in the %s yet." % entry.name, T.BODY, T.PARCHMENT_MUTED)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		none.position = Vector2(area.position.x, area.get_center().y - 20)
		none.size.x = area.size.x
		add_child(none)
	else:
		_pile_grid(db, models, area)
	var hint := UI.label("Tap anywhere to close" if n <= PILE_AT_ONCE else "Drag to scroll · tap to close", T.CAPTION, T.PARCHMENT_MUTED)
	hint.position = Vector2(content.position.x, content.end.y - 30)
	hint.size.x = content.size.x
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	appear()


## The faces in a grid within `area`, scrolling down past the first PILE_AT_ONCE.
func _pile_grid(db, models: Array, area: Rect2) -> void:
	var gap: float = T.SPACE_4
	var bar := 16.0
	# The grid of PILE_AT_ONCE that gives the largest face.
	var best := Vector2i(6, 2)
	var h := 0.0
	for g in PILE_GRIDS:
		var by_h: float = (area.size.y - (g.y - 1) * gap) / g.y
		var by_w: float = (area.size.x - bar - (g.x - 1) * gap) / g.x / T.CARD_ASPECT
		var fit := minf(minf(by_h, by_w), 440.0)
		if fit > h:
			h = fit
			best = g
	var sz := Vector2(floorf(h * T.CARD_ASPECT), floorf(h))
	var cols: int = mini(best.x, models.size())
	var grid := GridContainer.new()
	grid.columns = cols
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", int(gap))
	grid.add_theme_constant_override("v_separation", int(gap))
	for model in models:
		var face := _face(db, db.mage(model.id), model.level, sz)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(face)
	# Centred across the screen, the scroll bar clear of the cards at its right.
	var width: float = cols * sz.x + (cols - 1) * gap + bar
	var box := CenterContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.custom_minimum_size.x = width
	box.add_child(grid)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# The overlay reads every press itself, so a drag scrolls and a tap closes; the
	# scroll bar still takes its own.
	_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.position = Vector2(area.get_center().x - width / 2.0, area.position.y)
	_scroll.size = Vector2(width, area.size.y)
	_scroll.add_child(box)
	add_child(_scroll)
	UI.ignore_mouse(box)


func _gui_input(event: InputEvent) -> void:
	if _scroll == null and close_outside:
		super(event)
		return
	if event is InputEventMouseButton:
		var wheel := {MOUSE_BUTTON_WHEEL_UP: -1, MOUSE_BUTTON_WHEEL_DOWN: 1}
		if wheel.has(event.button_index):
			if event.pressed and _scroll != null:
				_scroll.scroll_vertical += wheel[event.button_index] * 80
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press_at = event.position
				_dragged = false
			elif _press_at != null:
				_press_at = null
				if not _dragged:
					close()
			accept_event()
	elif event is InputEventMouseMotion and _press_at != null:
		if not _dragged and event.position.distance_to(_press_at) > TAP_SLOP:
			_dragged = true
		if _dragged and _scroll != null:
			_scroll.scroll_vertical -= int(event.relative.y)
		accept_event()


## Every face gets the same frame, so the columns line up; only the current one shows it.
func _framed(face: Control, current: bool) -> Control:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The card being looked at: the brass ring and the lift of a held card (specs/019).
	var s := UI.box(Color.TRANSPARENT, T.BRASS if current else Color.TRANSPARENT, T.BORDER_SELECT, UI.card_radius(face.custom_minimum_size.x) + 4, 4)
	if current:
		s.shadow_color = T.SHADOW_LIFT.colour
		s.shadow_size = int(T.SHADOW_LIFT.blur / 2.0)
		s.shadow_offset = Vector2(0, T.SHADOW_LIFT.drop)
	p.add_theme_stylebox_override("panel", s)
	p.add_child(face)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return p


## The figures that differ between two Levels, as the card face names them.
func _changed(db, id: String, from: int, to: int) -> Array:
	var a: Dictionary = db.mage_level(id, from)
	var b: Dictionary = db.mage_level(id, to)
	var out := []
	for key in ["initiative", "basic", "enhanced", "boost", "armor", "upgrade_cost", "encounter", "hardship"]:
		if a[key] != b[key]:
			out.append(key)
	return out


## `sign` is the icon a good or harmful column carries, so its colour is never the
## only way to tell it (specs/019 FR-009).
func _column(title: String, face: Control, caption: String, colour: Color, width: float, sign := "") -> Control:
	var col := UI.vbox(T.SPACE_2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# A column head (specs/019 Ledger and Slot: the label style).
	var head := UI.hbox(T.SPACE_1)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	if sign != "":
		head.add_child(UI.icon_rect(sign, T.LABEL.size, colour))
	var t := UI.label(title, T.LABEL, colour)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(t)
	col.add_child(head)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(face)
	var c := UI.label(caption, T.BODY_SM, T.PARCHMENT, true)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.custom_minimum_size = Vector2(width + 16, 64)
	col.add_child(c)
	return col


func _face(db, m: Dictionary, level: int, sz: Vector2) -> Control:
	var f := CardFace.new()
	f.custom_minimum_size = sz
	f.set_model({"id": m.id, "name": m.name, "element": m.element, "level": level, "stats": db.mage_level(m.id, level)})
	return f


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
