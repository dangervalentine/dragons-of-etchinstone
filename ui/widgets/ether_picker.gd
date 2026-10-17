extends Control
## The last step of a Fuse: four Ethers to choose from, floating just above the
## two cards being fused, over whatever is behind them. It springs open and closes
## away again once a choice is made.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal intent(data: Dictionary)

var _panel := PanelContainer.new()
var _pointer := Control.new()
var _open := false
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_panel.add_theme_stylebox_override("panel", UI.stone_slab(T.GOLD, 12))
	var col := UI.vbox(T.S)
	var title := UI.label("The fused card counts as", T.LABEL_BOLD, T.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var row := UI.hbox(T.S)
	for e in T.ETHER:
		var b := Button.new()
		b.custom_minimum_size = Vector2(104, 104)
		b.focus_mode = Control.FOCUS_ALL
		var c: Color = T.ether(e)
		b.add_theme_stylebox_override("normal", UI.box(T.BG_BAND, c, 2))
		b.add_theme_stylebox_override("hover", UI.box(Color(c, 0.25), c, 3))
		b.add_theme_stylebox_override("pressed", UI.box(Color(c, 0.4), c, 3))
		var focus := UI.box(Color.TRANSPARENT, T.GOLD, 3)
		focus.set_expand_margin_all(4)
		b.add_theme_stylebox_override("focus", focus)
		var inner := UI.vbox(2)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.add_child(UI.icon_rect(e, 46, c))
		var name := UI.label(e.capitalize(), T.LABEL, T.INK)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(name)
		UI.ignore_mouse(inner)
		b.add_child(inner)
		UI.press_feedback(b)
		b.pressed.connect(func(): intent.emit({"type": "fuse_element", "element": e}))
		row.add_child(b)
	col.add_child(row)
	_panel.add_child(col)
	add_child(_panel)
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.draw.connect(func():
		_pointer.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(28, 0), Vector2(14, 16)]), T.GOLD))
	_pointer.size = Vector2(28, 16)
	add_child(_pointer)


## Open above `target` (a global rectangle), kept inside `bounds`.
func open(target: Rect2, bounds: Rect2) -> void:
	_panel.reset_size()
	var sz := _panel.get_combined_minimum_size()
	var pos := Vector2(target.get_center().x - sz.x / 2.0, target.position.y - sz.y - 18)
	pos.x = clampf(pos.x, bounds.position.x, bounds.end.x - sz.x)
	pos.y = maxf(pos.y, bounds.position.y)
	_panel.position = pos - global_position
	_panel.size = sz
	_pointer.position = Vector2(clampf(target.get_center().x - 14, pos.x + 20, pos.x + sz.x - 48), pos.y + sz.y - 1) - global_position
	if _open:
		return
	_open = true
	visible = true
	_panel.pivot_offset = Vector2(sz.x / 2.0, sz.y)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	modulate.a = 0.0
	_tween.tween_property(self, "modulate:a", 1.0, T.FAST)
	if not UI.reduced_motion:
		_panel.scale = Vector2(0.7, 0.7)
		_tween.tween_property(_panel, "scale", Vector2.ONE, T.BASE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not _open:
		return
	_open = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not is_inside_tree():
		visible = false
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, T.FAST)
	if not UI.reduced_motion:
		_tween.tween_property(_panel, "scale", Vector2(0.85, 0.85), T.FAST)
	_tween.chain().tween_callback(func(): visible = _open)
