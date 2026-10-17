extends "res://ui/overlays/overlay.gd"
## Explanations on demand: one entry beside the thing pressed, or the whole
## glossary as pages of short entries.

const Glossary = preload("res://ui/model/glossary.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")

## At most this many entries to a page; fewer when their text will not fit.
const PER_PAGE := 8
const MARGIN := 20
## Entries read together, kept on one page: the four Ethers.
const KEEP_TOGETHER := [["fire", "water", "lightning", "shadow"]]

var _page := 0
## Each page's entries, as [first, past the last], fitted to the panel's height.
var _pages := []
var _content := Rect2()
var _panel: Control
var _close: Button
var _caps := []


## One entry, placed beside `anchor` (a global rectangle) and kept inside `content`.
func show_entry(id: String, anchor: Rect2, content: Rect2) -> void:
	set_dim(0.25)
	# The same look as the hover tooltip for this term.
	var e: Dictionary = Glossary.entry(id)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.tooltip_box())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(UI.entry_content(e.name, HelpTip.body(id), e.icon))
	add_child(p)
	p.reset_size()
	var pos := Vector2(anchor.end.x + 12, anchor.position.y)
	if pos.x + p.size.x > content.end.x:
		pos.x = anchor.position.x - p.size.x - 12
	if pos.x < content.position.x:
		pos = Vector2(anchor.get_center().x - p.size.x / 2.0, anchor.end.y + 12)
	pos.x = clampf(pos.x, content.position.x, content.end.x - p.size.x)
	pos.y = clampf(pos.y, content.position.y, content.end.y - p.size.y)
	p.position = pos
	appear()


## Every entry, a page at a time.
func show_all(content: Rect2) -> void:
	_content = content
	close_outside = false
	_paginate()
	_show_page()
	appear()


func _show_page() -> void:
	if _panel != null:
		_panel.queue_free()
	var all: Array = Glossary.all()
	var pages := _pages.size()
	_page = clampi(_page, 0, pages - 1)
	var p := UI.slab(T.GOLD, MARGIN)
	p.position = _content.position
	p.size = _content.size
	_panel = p
	var col := UI.vbox(T.M)
	var head := UI.hbox(T.M)
	head.custom_minimum_size.y = HEAD_H
	head.add_child(UI.icon_rect("glossary", 40, T.GOLD))
	var title := UI.label("GLOSSARY", T.HEADING, T.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var where := UI.label("Page %d of %d" % [_page + 1, pages], T.LABEL, T.INK_MUTED)
	where.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(where)
	var clear := Control.new()
	clear.custom_minimum_size.x = close_clearance(MARGIN)
	head.add_child(clear)
	col.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", T.XL)
	grid.add_theme_constant_override("v_separation", T.M)
	for e in all.slice(_pages[_page][0], _pages[_page][1]):
		var row := UI.hbox(T.M)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(UI.icon_rect(e.icon if e.icon != "" else "help", 36, UI.icon_ink(e.id)))
		var text := UI.vbox(0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UI.label(e.name, T.SUBHEAD, T.INK))
		var desc := UI.label(e.text, T.LABEL, T.INK_MUTED, true)
		desc.custom_minimum_size.x = _desc_w()
		text.add_child(desc)
		row.add_child(text)
		grid.add_child(row)
	col.add_child(grid)
	var nav := UI.hbox(T.S)
	var prev := UI.button("Previous", "quiet")
	prev.disabled = _page == 0
	prev.pressed.connect(func(): _page -= 1; _show_page())
	var next := UI.button("Next", "normal")
	next.disabled = _page >= pages - 1
	next.pressed.connect(func(): _page += 1; _show_page())
	# Previous and Next at the two ends of the row, as in the rulebook.
	prev.custom_minimum_size.x = 220
	next.custom_minimum_size.x = 260
	nav.add_child(prev)
	nav.add_child(UI.spacer())
	nav.add_child(next)
	col.add_child(nav)
	p.add_child(col)
	add_child(p)
	if _close != null:
		_close.queue_free()
	_close = place_close_button(_content)
	# Woodcut caps across the slab's top and bottom edges, as on the rulebook.
	for c in _caps:
		c.queue_free()
	_caps = add_edge_caps(_content)


func _desc_w() -> float:
	return (_content.size.x - 140) / 2.0 - 60


## Break the entries into pages, two to a row, filling each page only as far as the
## panel has room between its heading and its Previous and Next, which are a tap
## target tall each.
func _paginate() -> void:
	_pages = []
	var all: Array = Glossary.all()
	var room := _content.size.y - 2 * MARGIN - HEAD_H - T.TAP_MIN - 2 * T.M
	var name_font := UI.font(T.SUBHEAD[0])
	var desc_font := UI.font(T.LABEL[0])
	# A Label adds its line spacing under every line, which the font's measure leaves out.
	var spacing: int = ThemeDB.get_default_theme().get_constant("line_spacing", "Label")
	var ids: Array = all.map(func(e): return e.id)
	var start := 0
	var used := 0.0
	var i := 0
	while i < all.size():
		var row_h := 0.0
		for e in all.slice(i, i + 2):
			var desc := desc_font.get_multiline_string_size(e.text, HORIZONTAL_ALIGNMENT_LEFT, _desc_w(), T.LABEL[1])
			var lines := roundi(desc.y / desc_font.get_height(T.LABEL[1]))
			row_h = maxf(row_h, name_font.get_height(T.SUBHEAD[1]) + desc.y + (lines + 1) * spacing)
		if i > start and (used + T.M + row_h > room or i - start >= PER_PAGE):
			# A break inside a group moves back to its start, so it turns over whole.
			var cut := _group_start(ids, i)
			if cut > start:
				i = cut
			_pages.append([start, i])
			start = i
			used = 0.0
			continue
		used += row_h + (T.M if i > start else 0)
		i += 2
	_pages.append([start, all.size()])


## Where the group kept together that `i` falls inside begins, or `i` itself.
func _group_start(ids: Array, i: int) -> int:
	for group in KEEP_TOGETHER:
		var first: int = ids.find(group[0])
		var last: int = ids.find(group[group.size() - 1])
		if first >= 0 and first < i and i <= last:
			return first
	return i
