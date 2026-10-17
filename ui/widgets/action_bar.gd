extends Control
## The action column beside the role slots (contracts/role-slots.md): the secondary
## actions (Fuse, Divert, Regroup, Give up Reserve, Undo Upgrade, or Cancel in place
## of the one under way) in a row of tap targets, and the one primary action, Play,
## across the column under them, under the right thumb
## (layout_solver.PLAY_IN_COLUMN is false).

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal intent(data: Dictionary)

const Solver = preload("res://ui/model/layout_solver.gd")

var primary := Button.new()
var _actions := Control.new()
var _area := Rect2()
var _commit := Rect2()
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


## actions: the whole column; commit: Play's cells inside it.
func apply_layout(actions: Rect2, commit: Rect2) -> void:
	_area = actions
	_commit = commit
	_actions.position = actions.position - global_position
	_actions.size = actions.size
	primary.position = commit.position - global_position
	primary.size = commit.size
	_place()


## Where `count` secondary actions go: side by side across the column above Play,
## in as many rows as the room above it holds (one, beside the slots).
func _cells(count: int) -> Array:
	var room := _commit.position.y - _area.position.y - T.S
	if count == 0 or room < T.TAP_MIN:
		return []
	var cols := maxi(1, floori((_area.size.x + T.S) / (T.TAP_MIN + T.S)))
	var rows := ceili(count / float(cols))
	var h := (room - (rows - 1) * T.S) / rows
	var out := []
	for i in count:
		var r := i / cols
		var in_row := mini(cols, count - r * cols)
		var w := (_area.size.x - (in_row - 1) * T.S) / in_row
		out.append(Rect2((i - r * cols) * (w + T.S), r * (h + T.S), w, h))
	return out


func _place() -> void:
	var buttons := _actions.get_children()
	# Alone in the column (Soak, setup), Play takes all of it.
	var alone := buttons.is_empty() and _area.size != Vector2.ZERO
	var r := _area if alone else _commit
	primary.position = r.position - global_position
	primary.size = r.size
	var cells := _cells(buttons.size())
	for i in buttons.size():
		var b: Control = buttons[i]
		b.visible = i < cells.size()
		if b.visible:
			b.position = cells[i].position
			b.size = cells[i].size


func render(vs: Dictionary) -> void:
	for c in _actions.get_children():
		_actions.remove_child(c)
		c.queue_free()
	for a in vs.secondary:
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
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		b.custom_minimum_size = Vector2(T.TAP_MIN, T.TAP_MIN)
		b.pressed.connect(func(): intent.emit({"type": "action", "id": a.id}))
		_actions.add_child(b)
	_place()
	var p: Dictionary = vs.prompt.primary
	primary.visible = p.label != ""
	primary.text = p.label
	primary.disabled = not p.enabled
	if p.kind != _kind:
		_kind = p.kind
		UI.style_stone_button(primary, p.kind)
	primary.tooltip_text = p.reason
	if p.enabled and not _was_enabled and is_inside_tree():
		UI.flash(primary, T.GOLD)
	_was_enabled = p.enabled
	if _ready:
		_glow()


## The primary action glows while it is the thing waiting on the player.
func set_ready(on: bool) -> void:
	_ready = on
	UI.style_stone_button(primary, _kind if _kind != "" else "primary")
	if on:
		_glow()


func _glow() -> void:
	var s = primary.get_theme_stylebox("normal")
	if s.get("glow") != null and s.glow < 1.0:
		s.glow = 1.0
		s.glow_colour = T.FOCUS
