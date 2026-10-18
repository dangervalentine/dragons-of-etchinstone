extends Control
## The label over each place of the Hand (specs/010 contracts/board-layout.md): the
## Role's icon and name and the place's state, never a number, which the math box
## shows. Each label sits on its card, so label and card read as one cell; a tap on
## the label is a tap on the place. Set 2's first label is set off from Set 1 by a
## gold rule, the Reserve's carries the mark of a rule that reads it (Steep,
## Freeze), and after a battle the labels recap the set just played.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Solver = preload("res://ui/model/layout_solver.gd")

signal intent(data: Dictionary)

const ROLE_ICONS := {"spell": "spell", "element": "element_role", "boost": "boost", "reserve": "reserve"}
const ROLE_NAMES := {"spell": "Spell", "element": "Element", "boost": "Boost", "reserve": "Reserve"}
## Below this width a label drops its icon, so the name keeps its size.
const NARROW_W := 130.0

var _labels := {}
## Where each set divider falls, as [x, top, bottom] in local units.
var _dividers: Array = []
## The same between the rows of the Final Battle's grid, as [from, to] in local units.
var _rules: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Show the places of `vs` at the plan's positions.
func render(vs: Dictionary, plan: Dictionary) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_labels = {}
	_dividers = []
	_rules = []
	var positions: Array = plan.get("positions", [])
	# In the Final Battle's grid one label names a column for both sets.
	var shared: bool = plan.get("set_rows", false)
	var two: bool = vs.get("sets", []).size() > 1 and not shared
	var aim = vs.get("key_target")
	for s in vs.get("places", []):
		if s.index >= positions.size() or plan.get("label_h", 0.0) <= 0.0:
			continue
		var pos: Dictionary = positions[s.index]
		if s.get("set_start", false) and s.index > 0 and shared:
			# Between the sets' rows, a gold rule across Set 2's places.
			var last: Dictionary = positions[mini(s.index + 2, positions.size() - 1)]
			var y: float = pos.card.position.y - Solver.GAP / 2.0 - global_position.y
			_rules.append([Vector2(pos.card.position.x - global_position.x, y), Vector2(last.card.end.x - global_position.x, y)])
		if pos.label.size.y <= 0.0:
			continue
		var l := _label(s, pos.label.size.x < NARROW_W, two)
		l.position = pos.label.position - global_position
		l.size = pos.label.size
		# The place the keyboard is aiming the held card at is edged in gold.
		var put = s.tap.get("target") if s.tap != null and s.tap.get("type") == "put" else null
		l.set_meta("aimed", aim != null and put != null and typeof(put) == typeof(aim) and put == aim)
		add_child(l)
		_labels[s.key] = l
		if s.get("set_start", false) and s.index > 0 and not shared:
			var before: Dictionary = positions[s.index - 1]
			if is_equal_approx(before.label.position.y, pos.label.position.y):
				var x: float = (before.label.end.x + pos.label.position.x) / 2.0 - global_position.x
				_dividers.append([x, pos.label.position.y - global_position.y, pos.card.end.y - global_position.y])
	queue_redraw()


func _draw() -> void:
	# Between the two Action Sets of the Final Battle, a gold rule.
	for d in _dividers:
		draw_line(Vector2(d[0], d[1] + 4), Vector2(d[0], d[2] - 4), T.GOLD, 2.0)
	for r in _rules:
		draw_line(r[0] + Vector2(4, 0), r[1] - Vector2(4, 0), T.GOLD, 2.0)


## Global rectangle of a place's label, for effects that aim at it.
func label_rect(key: String) -> Rect2:
	var l: Control = _labels.get(key)
	return l.get_global_rect() if l != null else Rect2()


func _label(s: Dictionary, narrow: bool, two: bool) -> Control:
	var l := _Label.new()
	l.state = s.state
	l.tooltip_text = s.tooltip
	var state: String = s.state
	var ink: Color = T.INK_MUTED
	match state:
		"target":
			ink = T.FOCUS
		"filled", "kept":
			ink = T.GOLD
		"inactive":
			ink = Color(T.INK_MUTED, 0.5)
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if s.role != "extra":
		var icon := UI.icon_rect(ROLE_ICONS[s.role], 22, ink)
		icon.visible = not narrow
		row.add_child(icon)
		var name: String = ROLE_NAMES[s.role]
		if two and s.role != "reserve":
			name += " %d" % (s.set + 1)
		var text := UI.label(name if narrow else name.to_upper(), T.LABEL_BOLD if state == "target" else T.LABEL, ink)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(text)
		l.struck = state == "given_up" or state == "discarded"
	if s.get("rule", "") != "":
		row.add_child(UI.icon_rect(s.rule, 22, T.BAD))
	if state == "kept":
		row.add_child(UI.label("· Stays", T.LABEL, T.GOLD))
	UI.ignore_mouse(row)
	l.add_child(row)
	if s.tap != null and state != "inactive":
		var tap: Dictionary = s.tap
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		# A touch arrives as a mouse press too (emulated): reading only the mouse keeps a
		# tap to one intent.
		l.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
				intent.emit(tap))
	else:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A label's plate: a faint wash, lit while the held card can go to its place or the
## keyboard aims there; struck through when its card is given up or spent.
class _Label extends Control:
	const T = preload("res://ui/theme/tokens.gd")
	var state := "empty"
	var struck := false

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size).grow(-1)
		var lit := state == "target"
		var aimed: bool = get_meta("aimed", false)
		if lit or aimed:
			draw_rect(r, Color(T.FOCUS, 0.14), true)
			draw_rect(r, T.GOLD if aimed else T.FOCUS, false, 3.0 if aimed else 2.0)
		elif state != "inactive":
			draw_line(Vector2(r.position.x + 6, r.end.y), Vector2(r.end.x - 6, r.end.y), Color(T.INK_MUTED, 0.35), 1.0)
		if struck:
			draw_line(Vector2(r.position.x + 8, r.end.y - 8), Vector2(r.end.x - 8, r.position.y + 8), T.INK_MUTED, 2.0)
