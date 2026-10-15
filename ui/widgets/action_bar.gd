extends Control
## The secondary actions (Fuse, Divert, Regroup, Give up Reserve, Cancel, or the
## four Ethers while finishing a Fuse) and the one primary action, which sits in
## the bottom right corner under the right thumb.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal intent(data: Dictionary)

var primary := Button.new()
var _actions := HBoxContainer.new()
var _was_enabled := false
var _kind := ""
var _ready := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actions.add_theme_constant_override("separation", T.S)
	add_child(_actions)
	primary = UI.button("", "primary")
	UI.style_stone_button(primary, "primary")
	primary.pressed.connect(func(): intent.emit({"type": "primary"}))
	add_child(primary)


func apply_layout(actions: Rect2, commit: Rect2) -> void:
	_actions.position = actions.position - global_position
	_actions.size = actions.size
	primary.position = commit.position - global_position
	primary.size = commit.size


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
		b.tooltip_text = a.reason
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): intent.emit({"type": "action", "id": a.id}))
		_actions.add_child(b)
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
