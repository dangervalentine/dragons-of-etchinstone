extends VBoxContainer
## A table of records (specs/019 contracts/components.md "Ledger"): column heads in the
## label style, muted; rows in body-sm with hairlines between them; scores in the
## numeral style with tabular figures; a missing value and a place muted; and the best
## row, only it, in bright brass. A row that opens something is the whole tap target.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

## The least height of a row and its padding top and bottom (4pt). A row that opens
## something is a whole tap target; a row only read is 44 (24pt), under the system's
## 30pt, so a ten-place board fits a phone (a departure, recorded in the plan).
const ROW_H := 44.0
const PAD_Y := T.SPACE_1
## The room under the column heads.
const HEAD_GAP := 4

signal pressed(row_index: int)


## `columns` is [{head, width (0 fills), align ("left", "right", "center"), numeral?,
## muted?}]; `rows` is [{cells: [text or Control], best?, press?}].
func setup(columns: Array, rows: Array) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	add_theme_constant_override("separation", 0)
	add_child(_line(columns, columns.map(func(c): return c.head), "head", false))
	for i in rows.size():
		add_child(_rule())
		var r: Dictionary = rows[i]
		var line := _line(columns, r.cells, "row", r.get("best", false))
		if r.get("press", false):
			var b := Button.new()
			b.flat = true
			b.custom_minimum_size.y = maxf(ROW_H, T.TAP_MIN)
			b.add_theme_stylebox_override("hover", UI.box(Color(T.SHEEN, 0.04), Color.TRANSPARENT, 0, T.RADIUS_PLATE, 0))
			b.add_theme_stylebox_override("focus", UI.focus_ring("sm"))
			line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			UI.ignore_mouse(line)
			b.add_child(line)
			var index := i
			b.pressed.connect(func(): pressed.emit(index))
			add_child(b)
		else:
			add_child(line)


func _line(columns: Array, cells: Array, kind: String, best: bool) -> Control:
	var row := UI.hbox(T.SPACE_3)
	row.custom_minimum_size.y = ROW_H - 2 * PAD_Y if kind == "row" else 0.0
	for i in columns.size():
		var col: Dictionary = columns[i]
		var cell = cells[i] if i < cells.size() else ""
		var holder := UI.hbox(T.SPACE_1)
		holder.alignment = {"left": BoxContainer.ALIGNMENT_BEGIN, "right": BoxContainer.ALIGNMENT_END,
			"center": BoxContainer.ALIGNMENT_CENTER}[col.get("align", "left")]
		holder.custom_minimum_size.x = col.get("width", 0)
		if col.get("width", 0) == 0:
			holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if cell is Control:
			holder.add_child(cell)
		elif kind == "head":
			holder.add_child(UI.label(str(cell), T.LABEL, T.PARCHMENT_MUTED))
		else:
			var absent: bool = str(cell) == "—"
			var colour: Color = T.BRASS_BRIGHT if best else (T.PARCHMENT_MUTED if absent or col.get("muted", false) else T.PARCHMENT)
			var l := UI.label(str(cell), T.NUMERAL_SM if col.get("numeral", false) else T.BODY_SM, colour)
			l.clip_text = col.get("width", 0) > 0
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.horizontal_alignment = {"left": HORIZONTAL_ALIGNMENT_LEFT, "right": HORIZONTAL_ALIGNMENT_RIGHT,
				"center": HORIZONTAL_ALIGNMENT_CENTER}[col.get("align", "left")]
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			holder.add_child(l)
		row.add_child(holder)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", PAD_Y if kind == "row" else 0)
	m.add_theme_constant_override("margin_bottom", PAD_Y if kind == "row" else HEAD_GAP)
	m.add_child(row)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = T.LINE
	r.custom_minimum_size.y = T.BORDER_ETCH
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
