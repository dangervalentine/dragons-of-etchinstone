extends Control
## The action row under the Hand (specs/010 contracts/board-layout.md): the
## secondary cells (Fuse, then Divert or Regroup, then Give up
## Reserve against a Ranged Enemy, or Cancel in place of the one under way), and the
## one primary action, Play, last, under the right thumb. Up to three cells Play
## takes the right half and a cell with nothing on offer is left blank; a fourth
## cell makes every cell a quarter (layout_solver.action_cells_for).

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

## The secondary cells' words.
const CELL_TEXT := 26

signal intent(data: Dictionary)

const Solver = preload("res://ui/model/layout_solver.gd")

var primary := Button.new()
## Over Play while it is not ready: a press here asks why rather than doing nothing.
var _why := Control.new()
var _actions := Control.new()
var _area := Rect2()
var _commit := Rect2()
var _cells_at: Array = []
var _was_enabled := false
var _kind := ""
var _ready := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_actions)
	primary = UI.button("", "primary")
	UI.style_stone_button(primary, "primary")
	primary.pressed.connect(func(): intent.emit({"type": "primary"}))
	add_child(primary)
	_why.mouse_filter = Control.MOUSE_FILTER_STOP
	_why.visible = false
	_why.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			intent.emit({"type": "primary"}))
	add_child(_why)


## actions: the whole row; commit: Play's cell; secondary: the cells before it.
func apply_layout(actions: Rect2, commit: Rect2, secondary: Array = []) -> void:
	_area = actions
	_commit = commit
	_cells_at = secondary
	_actions.position = actions.position - global_position
	_actions.size = actions.size
	_place()


func _place() -> void:
	primary.position = _commit.position - global_position
	primary.size = _commit.size
	_why.position = primary.position
	_why.size = primary.size
	var buttons := _actions.get_children()
	for i in buttons.size():
		var b: Control = buttons[i]
		var cell: int = b.get_meta("cell", i)
		b.visible = b.get_meta("shown", true) and cell < _cells_at.size()
		if cell < _cells_at.size():
			var r: Rect2 = _cells_at[cell]
			b.position = r.position - _area.position
			b.size = r.size


func render(vs: Dictionary) -> void:
	_actions.visible = true
	for c in _actions.get_children():
		_actions.remove_child(c)
		c.queue_free()
	for cell in vs.secondary.size():
		var a = vs.secondary[cell]
		if a == null:
			continue
		var label: String = a.label if a.enabled else a.reason
		var kind: String = "active" if a.active else ("quiet" if a.id == "cancel" else "normal")
		var b := UI.button(label, kind, a.icon)
		UI.style_stone_button(b, kind)
		b.disabled = not a.enabled
		b.tooltip_text = a.reason if a.reason != "" else a.get("tooltip", a.label)
		# Icon over a short label, so the cells can stay narrow.
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 30)
		# The narrow cells' words a step under the button style, so a label such as
		# Give up Reserve stays on one line under its icon (specs/019 research R2).
		b.add_theme_font_size_override("font_size", CELL_TEXT)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
		b.set_meta("cell", cell)
		b.set_meta("id", a.id)
		var id: String = a.id
		b.pressed.connect(func(): intent.emit({"type": "action", "id": id}))
		_actions.add_child(b)
	_place()
	var p: Dictionary = vs.prompt.primary
	primary.visible = p.label != ""
	primary.text = p.label
	primary.disabled = not p.enabled
	_why.visible = primary.visible and not p.enabled and p.reason != ""
	_why.tooltip_text = p.reason
	if p.kind != _kind:
		_kind = p.kind
		UI.style_stone_button(primary, p.kind)
	primary.tooltip_text = p.reason
	_was_enabled = p.enabled


## The secondary button for action `id` (fuse, divert…), or null: what a lesson
## lights (specs/017 contracts/coach-mark.md).
func button(id: String) -> Control:
	for b in _actions.get_children():
		if b.get_meta("id", "") == id and not b.is_queued_for_deletion():
			return b
	return null


## While the Key Card waits on the Deck with its Encounter lit (specs/014): the
## primary action names the Encounter, ready, glowing, and the other actions are
## put away; any press goes on with the reveal (main.gd _input).
func show_confirm(label: String) -> void:
	_actions.visible = false
	primary.visible = true
	primary.text = label
	primary.disabled = false
	primary.tooltip_text = ""
	_why.visible = false
	if _kind != "primary":
		_kind = "primary"
	set_ready(true)


## Whether the set is complete and Play waits on the player. Play is the one brass
## button either way; it does not glow (specs/019 FR-018).
func set_ready(on: bool) -> void:
	_ready = on
	UI.style_stone_button(primary, _kind if _kind != "" else "primary")
