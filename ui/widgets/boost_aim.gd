extends Control
## Where each Action Set's Boost goes, in its own column after that set's row of
## places (layout_solver.BOOST_W): against an Enemy a choice of Attack or Initiative,
## the one chosen leafed in gold; on a Journey the Boost always adds to Move, shown
## so the column reads the same in every Hand. Each is its symbol alone, named when
## the pointer rests on it, under the Boost's symbol in the labels' strip.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal intent(data: Dictionary)

const CHOICES := [["attack", "Attack"], ["initiative", "Initiative"]]

var _key := []
## Each set's column of choices, by set.
var _cols: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Show the aim of each set in `vs` at the plan's `boost_aims`.
func render(vs: Dictionary, plan: Dictionary) -> void:
	var rects: Array = plan.get("boost_aims", [])
	var sets: Array = vs.get("sets", [])
	var key := [rects, sets.map(func(s): return [s.boost_to, s.show_boost_to]), plan.get("label_h", 0.0), global_position]
	if key == _key:
		return
	_key = key
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_cols = []
	if sets.is_empty() or rects.is_empty():
		return
	var label_h: float = plan.get("label_h", 0.0)
	if label_h > 0.0:
		var head := UI.icon_rect("boost", 22, T.PARCHMENT_MUTED)
		head.tooltip_text = "Where each Boost goes"
		head.position = rects[0].position - Vector2(0, label_h) - global_position
		head.size = Vector2(rects[0].size.x, label_h)
		add_child(head)
	for i in mini(sets.size(), rects.size()):
		var r: Rect2 = rects[i]
		var col := Control.new()
		col.position = r.position - global_position
		col.size = r.size
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(col)
		_cols.append(col)
		var st: Dictionary = sets[i]
		var shown: Array = []
		if st.show_boost_to:
			for choice in CHOICES:
				shown.append(_option(i, choice[0], choice[1], st.boost_to == choice[0]))
		else:
			shown.append(_fixed())
		# The choices share the column's height, a gap between them; the fixed Move is
		# one choice's height, in the middle.
		var each := (r.size.y - T.SPACE_2) / 2.0
		var y := (r.size.y - (shown.size() * each + (shown.size() - 1) * T.SPACE_2)) / 2.0
		for b in shown:
			b.position = Vector2(0, y)
			b.size = Vector2(r.size.x, each)
			col.add_child(b)
			y += each + T.SPACE_2


## The buttons shown for set `set_index`: Attack and Initiative, or the fixed Move.
func buttons(set_index: int) -> Array:
	return _cols[set_index].get_children() if set_index < _cols.size() else []


## Set `set_index`'s button for `to`, or null.
func choice(set_index: int, to: String) -> Button:
	for b in buttons(set_index):
		if b.get_meta("to") == to:
			return b
	return null


## One choice of two, as a tab: its symbol, rimmed in brass when it is the set's aim
## (specs/019: selected, not the screen's one primary action).
func _option(set_index: int, to: String, name: String, chosen: bool) -> Button:
	var b := _plinth(to, "active" if chosen else "normal")
	b.tooltip_text = "Boost %d adds to %s" % [set_index + 1, name]
	b.pressed.connect(func(): intent.emit({"type": "set_boost_to", "set": set_index, "to": to}))
	return b


## On a Journey: Move, the only place the Boost can go, so nothing to press.
func _fixed() -> Button:
	var b := _plinth("move", "normal")
	b.tooltip_text = "On a Journey the Boost adds to Move"
	b.disabled = true
	b.focus_mode = Control.FOCUS_NONE
	# Not greyed out: the aim is set, just not a choice.
	b.add_theme_stylebox_override("disabled", b.get_theme_stylebox("normal"))
	b.add_theme_color_override("font_disabled_color", T.PARCHMENT)
	b.add_theme_color_override("icon_disabled_color", T.PARCHMENT)
	return b


func _plinth(icon_name: String, kind: String) -> Button:
	var b := UI.button("", kind, icon_name)
	b.set_meta("to", icon_name)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 40)
	b.custom_minimum_size = Vector2(0, T.TAP_MIN)
	return b
