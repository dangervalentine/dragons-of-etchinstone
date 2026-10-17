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
const SMALL := T.LABEL
## Terms chips: tall enough to press, set at the smallest readable size.
const CHIP_H := 44
## The "Terms on this page" label, on two lines beside the chips.
const TERMS_LABEL_W := 110
const CHIP_TEXT := T.TEXT_MIN
const CHIP_ICON := 26
## Room either side of the text in a table's cell.
const CELL_PAD := 8
## Previous and Next, alike so Contents sits in the middle between them.
const FOOT_W := 240

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
	# On the last page the same button closes the book.
	_next.disabled = false
	_next.text = "Close" if last else "Next"
	if fade and is_inside_tree():
		_body.modulate.a = 0.0
		create_tween().tween_property(_body, "modulate:a", 1.0, T.FAST)
	_next.grab_focus.call_deferred(true)


func next() -> void:
	if _contents_open:
		return
	var to := Rulebook.step(_pos, 1)
	if to != _pos:
		show_page(to.section, to.page)
	else:
		close()


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
	_contents.grab_focus.call_deferred(true)


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
	for c in _caps:
		c.queue_free()
	_caps = []
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var inner := content.size.x - PAD * 2 - COLUMN_GAP
	_text_w = floorf(inner * 0.6)
	_aside_w = floorf(inner - _text_w)
	# Heading, page and footer close together, so the page has the most room.
	var col := UI.vbox(T.S)

	var head := UI.hbox(T.M)
	head.custom_minimum_size.y = HEAD_H
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
	var clear := Control.new()
	clear.custom_minimum_size.x = close_clearance(PAD)
	head.add_child(clear)
	col.add_child(head)

	_body = UI.vbox(0)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_body)

	# Previous and Next at the two ends, Contents midway between them: the ends are
	# one width, so the middle is the slab's.
	var foot := UI.hbox(T.S)
	_prev = UI.button("Previous", "quiet")
	_prev.custom_minimum_size.x = FOOT_W
	_prev.pressed.connect(previous)
	foot.add_child(_prev)
	foot.add_child(UI.spacer())
	_contents = UI.button("Contents", "quiet", "menu")
	_contents.custom_minimum_size.x = 250
	_contents.pressed.connect(toggle_contents)
	foot.add_child(_contents)
	foot.add_child(UI.spacer())
	_next = UI.button("Next", "normal")
	_next.custom_minimum_size.x = FOOT_W
	_next.pressed.connect(next)
	foot.add_child(_next)
	col.add_child(foot)

	_panel.add_child(col)
	add_child(_panel)
	if _close != null:
		_close.queue_free()
	_close = place_close_button(content)
	# Woodcut caps across the slab's top and bottom edges, as on the glossary.
	_caps = add_edge_caps(content)


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
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("section", i)
		b.pressed.connect(show_page.bind(i, 0))
		grid.add_child(b)
	return grid


# ---------------------------------------------------------------- pages

func _page_view(p: Dictionary) -> Control:
	var page := UI.vbox(T.M)
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# The two columns, divided by a rule down the middle of the gap between them.
	var row := UI.hbox(floori((COLUMN_GAP - 1) / 2.0))
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var text := UI.vbox(T.M)
	text.custom_minimum_size.x = _text_w
	for b in p.text:
		text.add_child(_block(b, _text_w))
	row.add_child(text)
	var rule := ColorRect.new()
	rule.color = Color(T.LINE_SOFT, 0.8)
	rule.custom_minimum_size.x = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(rule)
	var aside := UI.vbox(T.S)
	aside.custom_minimum_size.x = _aside_w
	# The terms sit at the foot of the aside, just above Next; a figure takes the rest.
	var terms_h := _terms_height(p.terms, _aside_w)
	for b in p.aside:
		if b.has("figure"):
			var room := Vector2(_aside_w, _body_height() - (terms_h + T.S if terms_h > 0.0 else 0.0))
			aside.add_child(RulebookFigure.make(b.figure, db, room, func(d): intent.emit(d)))
		else:
			aside.add_child(_block(b, _aside_w))
	# The first page credits the game's makers, in the room its aside leaves.
	if _pos.section == 0 and _pos.page == 0:
		aside.add_child(UI.spacer())
		var credit := UI.label(Rulebook.CREDIT, T.LABEL, T.INK_MUTED, true)
		credit.custom_minimum_size.x = _aside_w
		aside.add_child(credit)
	if not p.terms.is_empty():
		aside.add_child(_terms(p.terms, _aside_w))
	row.add_child(aside)
	page.add_child(row)
	return page


## The height the body has for a page at this size.
func _body_height() -> float:
	return _content.size.y - PAD * 2 - HEAD_H - T.TAP_MIN - T.S * 2


## How tall the terms will be in a column `width` wide: rows of chips beside the label.
func _terms_height(ids: Array, width: float) -> float:
	if ids.is_empty():
		return 0.0
	var font := UI.font(T.BUTTON[0])
	var room := width - TERMS_LABEL_W - T.S
	var rows := 1
	var x := 0.0
	for id in ids:
		var w: float = font.get_string_size(Glossary.entry(id).name, HORIZONTAL_ALIGNMENT_LEFT, -1, CHIP_TEXT).x + CHIP_ICON + 4 * T.S + 4
		if x > 0.0 and x + w > room:
			rows += 1
			x = 0.0
		x += w + T.S
	return rows * _chip_h() + (rows - 1) * T.S


## A chip's real height, its text and the stone's margins, never less than CHIP_H.
func _chip_h() -> float:
	# Measured in the tree, where the stone's margins resolve as they will on the page.
	var probe := _chip("help")
	add_child(probe)
	var h := maxf(CHIP_H, probe.get_combined_minimum_size().y)
	remove_child(probe)
	probe.free()
	return h


func _chip(id: String) -> Button:
	var e: Dictionary = Glossary.entry(id)
	var chip := UI.button(e.name, "quiet", e.icon if e.icon != "" else "help")
	chip.custom_minimum_size = Vector2(CHIP_H, CHIP_H)
	chip.autowrap_mode = TextServer.AUTOWRAP_OFF
	# A fixed-size icon counts toward the chip's width; an expanding one would be squeezed out.
	chip.expand_icon = false
	chip.add_theme_font_size_override("font_size", CHIP_TEXT)
	chip.add_theme_constant_override("icon_max_width", CHIP_ICON)
	return chip


## The Glossary terms of the page as chips, set to the right with their label
## beside them; each opens its entry beside it.
func _terms(ids: Array, width: float) -> Control:
	# Takes the aside's spare height and sits at its foot, just above Next.
	var row := UI.hbox(T.S)
	row.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	var label := UI.label("Terms on this page", T.LABEL, T.INK_MUTED, true)
	label.custom_minimum_size.x = TERMS_LABEL_W
	label.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(label)
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_END
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", T.S)
	flow.add_theme_constant_override("v_separation", T.S)
	flow.custom_minimum_size.x = width - TERMS_LABEL_W - T.S
	for id in ids:
		var chip := _chip(id)
		chip.set_script(HelpButton)
		chip.set_meta("term", id)
		HelpTip.mark(chip, id)
		chip.pressed.connect(func(): intent.emit({"type": "help", "id": id, "source": chip}))
		flow.add_child(chip)
	row.add_child(flow)
	return row


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


## A table in a frame: the head row on a band in gold, a rule between rows. The
## columns that name things keep to one line where they can, and the widest column,
## the one that explains, wraps in what is left. "difficulty" is built from the engine.
func _table(t, width: float) -> Control:
	var head: Array
	var rows: Array
	if t is String and t == "difficulty":
		head = ["Difficulty", "Drawn", "Changed", "To Level"]
		rows = Rulebook.difficulty_rows().map(func(r): return [r.name, str(r.offered), str(r.changed), str(r.level)])
	else:
		head = t.head
		rows = t.rows
	# A margin of the border's width, so the head band never covers the frame.
	var frame := UI.panel(Color(T.BG_BASE, 0.35), T.LINE_SOFT, 1, T.RADIUS_S, 1)
	var widths := _column_widths([head] + rows, width - 2 - CELL_PAD * 2 * head.size())
	var col := UI.vbox(0)
	for i in rows.size() + 1:
		var r: Array = head if i == 0 else rows[i - 1]
		if i > 1:
			var rule := ColorRect.new()
			rule.color = Color(T.LINE_SOFT, 0.7)
			rule.custom_minimum_size.y = 1
			col.add_child(rule)
		var band := PanelContainer.new()
		var look := StyleBoxFlat.new()
		look.bg_color = T.BG_RAISED if i == 0 else Color(0, 0, 0, 0)
		look.corner_radius_top_left = T.RADIUS_S if i == 0 else 0
		look.corner_radius_top_right = look.corner_radius_top_left
		look.content_margin_top = 5 if i == 0 else 6
		look.content_margin_bottom = look.content_margin_top
		band.add_theme_stylebox_override("panel", look)
		var line := UI.hbox(0)
		for c in head.size():
			var cell := MarginContainer.new()
			cell.add_theme_constant_override("margin_left", CELL_PAD)
			cell.add_theme_constant_override("margin_right", CELL_PAD)
			var text := _rich("[b]%s[/b]" % r[c] if i == 0 else r[c], widths[c], SMALL)
			if i == 0:
				text.add_theme_color_override("default_color", T.GOLD)
			cell.add_child(text)
			line.add_child(cell)
		band.add_child(line)
		col.add_child(band)
	frame.add_child(col)
	return frame


## Each column's width within `room`, as a browser sets out a table: every column
## at its one-line width if they all fit; otherwise each starts at its longest word
## and the room left is shared in proportion to how much more each needs for one line.
func _column_widths(cells: Array, room: float) -> Array:
	var n: int = cells[0].size()
	var font := UI.font("body_bold")
	var fs: int = SMALL[1]
	var line := []
	var word := []
	for c in n:
		line.append(0.0)
		word.append(0.0)
	for r in cells:
		for c in n:
			var icons := _icon_count(r[c]) * (Rulebook.ICON_SIZE + 4)
			var plain := _plain(r[c]).strip_edges()
			line[c] = maxf(line[c], font.get_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + icons + 2)
			for w in plain.split(" ", false):
				word[c] = maxf(word[c], font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + icons + 2)
	var line_total := 0.0
	var word_total := 0.0
	for c in n:
		line_total += line[c]
		word_total += word[c]
	var widths := []
	if line_total <= room:
		widths = line.duplicate()
		widths[n - 1] += room - line_total
		return widths
	var share := clampf((room - word_total) / maxf(1.0, line_total - word_total), 0.0, 1.0)
	for c in n:
		widths.append(word[c] + (line[c] - word[c]) * share)
	return widths


## The visible text of a cell, without its tags or inline icons.
func _plain(bbcode: String) -> String:
	var icons := RegEx.create_from_string(r"\[img[^\]]*\][^\[]*\[/img\]")
	var tags := RegEx.create_from_string(r"\[[^\]]*\]")
	return tags.sub(icons.sub(bbcode, "", true), "", true)


func _icon_count(bbcode: String) -> int:
	return RegEx.create_from_string(r"\[img[^\]]*\]").search_all(bbcode).size()


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
