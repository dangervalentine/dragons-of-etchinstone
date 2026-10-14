extends Control
## Base for everything shown above a screen: dims what is behind, closes on Escape
## or a press outside its panel, and never changes the game.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal closed

## Close when the dimmed area outside the panel is pressed.
var close_outside := true
var _dim := ColorRect.new()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.color = Color(T.BG_BASE, 0.78)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)


func set_dim(alpha: float) -> void:
	_dim.color.a = alpha


func appear() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, T.FAST)


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


func _gui_input(event: InputEvent) -> void:
	if close_outside and event is InputEventMouseButton and event.pressed:
		close()
		accept_event()
