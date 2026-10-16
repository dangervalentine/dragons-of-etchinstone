extends "res://ui/overlays/overlay.gd"
## How to Play: the rules of the game a page at a time, over whatever is showing.
## A header names the section and where it sits in the book; the body holds the
## page's text beside its aside (a table or a labelled example); the footer steps
## back and forth, and the contents jump to any section. Nothing scrolls: every
## page is written to fit the screen whole.

const Rulebook = preload("res://ui/model/rulebook.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const HelpButton = preload("res://ui/widgets/help_button.gd")
const Glossary = preload("res://ui/model/glossary.gd")
const RulebookFigure = preload("res://ui/widgets/rulebook_figure.gd")

signal intent(data: Dictionary)

## Padding inside the panel, and the gap between the text and the aside.
const PAD := 20
const COLUMN_GAP := T.XL
## Text sizes: body text, and the smaller text of tables and captions.
const TEXT := T.BODY
const SMALL := ["body", 24]
## Terms chips: tall enough to press, set at the smallest readable size.
const CHIP_H := 48
const CHIP_TEXT := T.TEXT_MIN
const CHIP_ICON := 26

var db = null
var _content := Rect2()
var _pos := {"section": 0, "page": 0}
var _panel: PanelContainer
var _title: Label
var _where: Label
var _body: VBoxContainer
var _prev: Button
var _next: Button
var _close: Button
var _contents: Button
var _contents_open := false
var _text_w := 0.0
var _aside_w := 0.0


## Fill `content` (a global rectangle) and show the page last read, or the first
## page of the section named.
func open(content: Rect2, section_id := "", card_db = null) -> void:
	db = card_db
	close_outside = false
	var at := Rulebook.find(section_id) if section_id != "" else -1
	_pos = {"section": at, "page": 0} if at >= 0 else _valid(Rulebook.position)
	_build(content)
	show_page(_pos.section, _pos.page, false)
	appear()


## Fit a new content rectangle, keeping the page.
func relayout(content: Rect2) -> void:
	_build(content)
	show_page(_pos.section, _pos.page, false)


func show_page(section: int, page_index: int, fade := true) -> void:
	_contents_open = false
	_contents.text = "Contents"
	_pos = {"section": section, "page": page_index}
	Rulebook.position = _pos.duplicate()
	var s: Dictionary = Rulebook.SECTIONS[section]
	_title.text = s.title.to_upper()
	var where := "Section %d of %d" % [section + 1, Rulebook.section_count()]
	if Rulebook.page_count(section) > 1:
		where += " · Page %d of %d" % [page_index + 1, Rulebook.page_count(section)]
	_where.text = where
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_body.add_child(_page_view(Rulebook.page(section, page_index)))
	var first := Rulebook.step(_pos, -1) == _pos
	var last := Rulebook.step(_pos, 1) == _pos
	_prev.disabled = first
	_next.disabled = last
	_next.text = "End of rulebook" if last else "Next"
	if fade and is_inside_tree():
		_body.modulate.a = 0.0
		create_tween().tween_property(_body, "modulate:a", 1.0, T.FAST)
	(_close if last else _next).grab_focus.call_deferred()


func next() -> void:
	if _contents_open:
		return
	var to := Rulebook.step(_pos, 1)
	if to != _pos:
		show_page(to.section, to.page)


func previous() -> void:
	if _contents_open:
		return
	var to := Rulebook.step(_pos, -1)
	if to != _pos:
		show_page(to.section, to.page)


## Swap the page for the contents, or back.
func toggle_contents() -> void:
	if _contents_open:
		show_page(_pos.section, _pos.page)
		return
	_contents_open = true
	_contents.text = "Back to page"
	_title.text = "CONTENTS"
	_where.text = "%d sections · you are in section %d" % [Rulebook.section_count(), _pos.section + 1]
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_body.add_child(_contents_view())
	_prev.disabled = true
	_next.disabled = true
	_contents.grab_focus.call_deferred()


## The page shown, as {section, page}.
func shown() -> Dictionary:
	return _pos.duplicate()


## True when everything on the page fits inside the content rectangle.
func fits() -> bool:
	return _panel.get_combined_minimum_size().y <= _content.size.y + 0.5 and _panel.get_combined_minimum_size().x <= _content.size.x + 0.5


# ---------------------------------------------------------------- frame

var _caps := []


func _build(content: Rect2) -> void:
	_content = content
	if _panel != null:
		remove_child(_panel)
		_panel.queue_free()
	_panel = UI.slab(T.GOLD, PAD)
	_panel.position = content.position
	_panel.size = content.size
	# A scroll: woodcut caps across the slab's top and bottom edges, drawn flat.
	for c in _caps:
		c.queue_free()
	_caps = []
	for top in [true, false]:
		var cap := UI.icon_rect("orn_scroll_end", 10, T.muted(T.GOLD))
		cap.custom_minimum_size = Vector2.ZERO
		cap.size = Vector2(content.size.x * 0.4, 22)
		cap.position = Vector2(content.position.x + content.size.x * 0.3, (content.position.y - 11) if top else (content.end.y - 11))
		cap.flip_v = not top
		_caps.append(cap)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var inner := content.size.x - PAD * 2 - COLUMN_GAP
	_text_w = floorf(inner * 0.6)
	_aside_w = floorf(inner - _text_w)
	var col := UI.vbox(T.M)

	var head := UI.hbox(T.M)
	head.custom_minimum_size.y = T.TAP_MIN
	head.add_child(UI.icon_rect("book", 44, T.GOLD))
	var names := UI.vbox(0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	_title = UI.label("", T.HEADING, T.GOLD)
	_title.clip_text = true
	names.add_child(_title)
	_where = UI.label("", T.LABEL, T.INK_MUTED)
	names.add_child(_where)
	head.add_child(names)
	_contents = UI.button("Contents", "quiet", "menu")
	_contents.custom_minimum_size.x = 250
	_contents.pressed.connect(toggle_contents)
	head.add_child(_contents)
	_close = UI.button("Close", "quiet", "close")
	_close.custom_minimum_size.x = 180
	_close.pressed.connect(close)
	head.add_child(_close)
	col.add_child(head)

	_body = UI.vbox(0)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_body)

	var foot := UI.hbox(T.S)
	_prev = UI.button("Previous", "quiet")
	_prev.custom_minimum_size.x = 220
	_prev.pressed.connect(previous)
	foot.add_child(_prev)
	foot.add_child(UI.spacer())
	_next = UI.button("Next", "normal")
	_next.custom_minimum_size.x = 260
	_next.pressed.connect(next)
	foot.add_child(_next)
	col.add_child(foot)

	_panel.add_child(col)
	add_child(_panel)
	for cap in _caps:
		add_child(cap)


## A position that exists, falling back to the first page.
func _valid(pos: Dictionary) -> Dictionary:
	var s: int = pos.get("section", 0)
	var p: int = pos.get("page", 0)
	if s < 0 or s >= Rulebook.section_count() or p < 0 or p >= Rulebook.page_count(s):
		return {"section": 0, "page": 0}
	return {"section": s, "page": p}


# ---------------------------------------------------------------- contents

## Every section as a button, in as many columns as the body's height needs.
func _contents_view() -> Control:
	var rows := maxi(1, floori((_body_height() + T.S) / (T.TAP_MIN + T.S)))
	var count := Rulebook.section_count()
	var grid := GridContainer.new()
	grid.columns = ceili(count / float(rows))
	grid.add_theme_constant_override("h_separation", T.S)
	grid.add_theme_constant_override("v_separation", T.S)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in count:
		var b := UI.button("%d. %s" % [i + 1, Rulebook.SECTIONS[i].title], "active" if i == _pos.section else "quiet")
		b.add_theme_font_size_override("font_size", SMALL[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("section", i)
		b.pressed.connect(show_page.bind(i, 0))
		grid.add_child(b)
	return grid


# ---------------------------------------------------------------- pages

func _page_view(p: Dictionary) -> Control:
	var row := UI.hbox(COLUMN_GAP)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var text := UI.vbox(T.M)
	text.custom_minimum_size.x = _text_w
	for b in p.text:
		text.add_child(_block(b, _text_w))
	row.add_child(text)
	var aside := UI.vbox(T.M)
	aside.custom_minimum_size.x = _aside_w
	var terms_h := _terms_height(p.terms)
	for b in p.aside:
		if b.has("figure"):
			var room := Vector2(_aside_w, _body_height() - terms_h - (T.M * 2 if terms_h > 0 else 0))
			aside.add_child(RulebookFigure.make(b.figure, db, room, func(d): intent.emit(d)))
		else:
			aside.add_child(_block(b, _aside_w))
	if not p.terms.is_empty():
		aside.add_child(UI.spacer())
		aside.add_child(_terms(p.terms))
	# The first page credits the game's makers, in the room its aside leaves.
	if _pos.section == 0 and _pos.page == 0:
		aside.add_child(UI.spacer())
		var credit := UI.label(Rulebook.CREDIT, T.LABEL, T.INK_MUTED, true)
		credit.custom_minimum_size.x = _aside_w
		aside.add_child(credit)
	row.add_child(aside)
	return row


## The height the body has for a page at this size.
func _body_height() -> float:
	return _content.size.y - PAD * 2 - T.TAP_MIN * 2 - T.M * 2


## The Glossary terms of the page as chips; each opens its entry beside it.
func _terms(ids: Array) -> Control:
	var col := UI.vbox(T.S)
	col.add_child(UI.label("Terms on this page", T.LABEL, T.INK_MUTED))
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", T.S)
	flow.add_theme_constant_override("v_separation", T.S)
	flow.custom_minimum_size.x = _aside_w
	for id in ids:
		var e: Dictionary = Glossary.entry(id)
		var chip := UI.button(e.name, "quiet", e.icon if e.icon != "" else "help")
		chip.set_script(HelpButton)
		chip.custom_minimum_size = Vector2(CHIP_H, CHIP_H)
		chip.autowrap_mode = TextServer.AUTOWRAP_OFF
		# A fixed-size icon counts toward the chip's width; an expanding one would be squeezed out.
		chip.expand_icon = false
		chip.add_theme_font_size_override("font_size", CHIP_TEXT)
		chip.add_theme_constant_override("icon_max_width", CHIP_ICON)
		chip.set_meta("term", id)
		HelpTip.mark(chip, id)
		chip.pressed.connect(func(): intent.emit({"type": "help", "id": id, "source": chip}))
		flow.add_child(chip)
	col.add_child(flow)
	return col


## How tall the terms chips will be, packed into rows across the aside.
func _terms_height(ids: Array) -> float:
	if ids.is_empty():
		return 0.0
	var font := UI.font(T.BUTTON[0])
	var rows := 1
	var x := 0.0
	for id in ids:
		var w: float = font.get_string_size(Glossary.entry(id).name, HORIZONTAL_ALIGNMENT_LEFT, -1, CHIP_TEXT).x + CHIP_ICON + 4 * T.S + 4
		if x > 0.0 and x + w > _aside_w:
			rows += 1
			x = 0.0
		x += w + T.S
	return T.LABEL[1] * 1.4 + T.S + rows * CHIP_H + (rows - 1) * T.S


func _block(b: Dictionary, width: float) -> Control:
	if b.has("p"):
		return _rich(b.p, width)
	if b.has("steps") or b.has("list"):
		var items: Array = b.get("steps", b.get("list", []))
		var col := UI.vbox(T.S)
		for i in items.size():
			var line := UI.hbox(T.S)
			var mark := UI.label(("%d." % (i + 1)) if b.has("steps") else "•", ["body_bold", TEXT[1]], T.GOLD)
			mark.custom_minimum_size.x = 32
			mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			line.add_child(mark)
			line.add_child(_rich(items[i], width - 32 - T.S))
			col.add_child(line)
		return col
	if b.has("note"):
		var panel := UI.panel(T.BG_RAISED, Color(T.GOLD, 0.5), 1, T.RADIUS_S, 12)
		panel.add_child(_rich(b.note, width - 24))
		return panel
	if b.has("table"):
		return _table(b.table, width)
	return Control.new()


## A paragraph: body text with bold terms and inline icons.
func _rich(bbcode: String, width: float, size: Array = TEXT) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.custom_minimum_size.x = width
	r.add_theme_font_override("normal_font", UI.font(size[0]))
	r.add_theme_font_override("bold_font", UI.font("body_bold"))
	r.add_theme_font_size_override("normal_font_size", size[1])
	r.add_theme_font_size_override("bold_font_size", size[1])
	r.add_theme_color_override("default_color", T.INK)
	r.text = bbcode
	return r


## A grid of cells; the head row in bold. "difficulty" is built from the engine.
func _table(t, width: float) -> Control:
	var head: Array
	var rows: Array
	if t is String and t == "difficulty":
		head = ["Difficulty", "Cards drawn", "Changed", "To Level"]
		rows = Rulebook.difficulty_rows().map(func(r): return [r.name, str(r.offered), str(r.changed), str(r.level)])
	else:
		head = t.head
		rows = t.rows
	var grid := GridContainer.new()
	grid.columns = head.size()
	grid.add_theme_constant_override("h_separation", T.M)
	grid.add_theme_constant_override("v_separation", T.S)
	# Columns share the width by the length of their longest cell.
	var weights := []
	for c in head.size():
		var longest := 4
		for r in [head] + rows:
			longest = maxi(longest, _plain(r[c]).length())
		weights.append(clampi(longest, 6, 40))
	var total := 0
	for w in weights:
		total += w
	var free := width - T.M * (head.size() - 1)
	for r in [head] + rows:
		for c in head.size():
			var text: String = r[c]
			var cell := _rich("[b]%s[/b]" % text if r == head else text, floorf(free * weights[c] / total), SMALL)
			grid.add_child(cell)
	return grid


## The visible text of a cell, an inline icon counted as two letters.
func _plain(bbcode: String) -> String:
	var icons := RegEx.create_from_string(r"\[img[^\]]*\][^\[]*\[/img\]")
	var tags := RegEx.create_from_string(r"\[[^\]]*\]")
	return tags.sub(icons.sub(bbcode, "  ", true), "", true)


# ---------------------------------------------------------------- keys

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo or not _on_top():
		return
	match event.keycode:
		KEY_RIGHT, KEY_PAGEDOWN:
			next()
		KEY_LEFT, KEY_PAGEUP:
			previous()
		KEY_C:
			toggle_contents()
		_:
			return
	get_viewport().set_input_as_handled()


## Only the topmost overlay answers keys, so a Glossary entry opened over the
## rulebook keeps them.
func _on_top() -> bool:
	var parent := get_parent()
	if parent == null:
		return false
	for i in range(parent.get_child_count() - 1, -1, -1):
		var o := parent.get_child(i)
		if not o.is_queued_for_deletion():
			return o == self
	return false
