extends "res://ui/overlays/overlay.gd"
## Explanations on demand: one entry beside the thing pressed, or the whole
## glossary as pages of short entries.

const Glossary = preload("res://ui/model/glossary.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")

const PER_PAGE := 8

var _page := 0
var _content := Rect2()
var _panel: Control


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
	_show_page()
	appear()


func _show_page() -> void:
	if _panel != null:
		_panel.queue_free()
	var all: Array = Glossary.all()
	var pages := ceili(all.size() / float(PER_PAGE))
	var p := UI.panel(T.BG_SURFACE, T.LINE_SOFT, 1, T.RADIUS_M, 20)
	p.position = _content.position
	p.size = _content.size
	_panel = p
	var col := UI.vbox(T.M)
	var head := UI.hbox(T.M)
	head.add_child(UI.icon_rect("help", 40, T.GOLD))
	var title := UI.label("GLOSSARY", T.HEADING, T.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UI.label("Page %d of %d" % [_page + 1, pages], T.LABEL, T.INK_MUTED))
	col.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", T.XL)
	grid.add_theme_constant_override("v_separation", T.M)
	for e in all.slice(_page * PER_PAGE, (_page + 1) * PER_PAGE):
		var row := UI.hbox(T.M)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(UI.icon_rect(e.icon if e.icon != "" else "help", 36, T.GOLD))
		var text := UI.vbox(0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UI.label(e.name, ["body_bold", 24], T.INK))
		var desc := UI.label(e.text, ["body", 22], T.INK_MUTED, true)
		desc.custom_minimum_size.x = (_content.size.x - 140) / 2.0 - 60
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
	var done := UI.button("Close", "primary")
	done.pressed.connect(close)
	for b in [prev, next]:
		b.custom_minimum_size.x = 200
		nav.add_child(b)
	nav.add_child(UI.spacer())
	done.custom_minimum_size.x = 220
	nav.add_child(done)
	col.add_child(nav)
	p.add_child(col)
	add_child(p)
