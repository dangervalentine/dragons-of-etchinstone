extends PanelContainer
## The Soak step: the damage owed, and a meter that fills as cards are chosen to
## Downgrade, its count saying how much is covered (green once it all is).

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

var _box := VBoxContainer.new()
var _meter := Control.new()
var _due := 1
var _total := 0
## How much of the damage the meter shows covered: it fills to `_total` as cards
## are chosen, and back as they are put back (-1 before it has shown any).
var _shown := -1.0
var _fill: Tween


func _init() -> void:
	add_theme_stylebox_override("panel", UI.stone_zone(T.DANGER))
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	_meter.custom_minimum_size.y = 34
	_meter.draw.connect(_draw_meter)


## The height this panel needs at `width`.
func needed_height(width: float) -> float:
	var margins: Vector2 = get_theme_stylebox("panel").get_minimum_size()
	return UI.stack_height(_box, width - margins.x) + margins.y


func render(vs: Dictionary) -> void:
	var s: Dictionary = vs.soak
	var same_due := maxi(1, s.due) == _due and _shown >= 0.0
	_due = maxi(1, s.due)
	_total = s.total
	if _fill != null and _fill.is_valid():
		_fill.kill()
	if same_due and not is_equal_approx(_shown, _total) and is_visible_in_tree() and not UI.reduced_motion:
		_fill = create_tween()
		_fill.tween_method(_show, _shown, float(_total), T.FILL).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		_shown = _total
	if _meter.get_parent() != null:
		_box.remove_child(_meter)
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var head := UI.hbox(T.SPACE_2)
	head.add_child(UI.icon_rect("poison" if s.poison else "hp", T.NOTE_ICON, T.DANGER))
	head.add_child(UI.label(("Poison: %d damage" if s.poison else "%d damage") % s.due, T.HEADING, T.DANGER))
	if s.element != "":
		head.add_child(UI.icon_rect(s.element, T.NOTE_ICON, T.ether_ink(s.element)))
	_box.add_child(head)
	_box.add_child(_meter)
	var how := UI.label("Tap cards to Downgrade them.", T.BODY_SM, T.PARCHMENT_MUTED, true)
	how.custom_minimum_size.x = 300
	_box.add_child(how)
	_meter.queue_redraw()


func _draw_meter() -> void:
	var r := Rect2(Vector2.ZERO, _meter.size)
	_meter.draw_style_box(UI.box(T.WELL, T.LINE, 1, T.RADIUS_PLATE, 0), r)
	var frac := clampf(_shown / float(_due), 0.0, 1.0)
	if frac > 0.0:
		_meter.draw_style_box(UI.box(T.JADE if frac >= 1.0 else T.PARCHMENT_MUTED, Color.TRANSPARENT, 0, T.RADIUS_PLATE, 0),
			Rect2(r.position, Vector2(maxf(20.0, r.size.x * frac), r.size.y)))
	var font := UI.font(T.NUMERAL_SM)
	var fs: int = T.NUMERAL_SM.size
	var text := "%d / %d" % [roundi(_shown), _due]
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	_meter.draw_string(font, Vector2((r.size.x - sz.x) / 2.0, r.size.y / 2.0 + fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, T.PARCHMENT)


func _show(v: float) -> void:
	_shown = v
	_meter.queue_redraw()


## Global centre of the meter, where the damage leaves from as cards Soak it.
func point() -> Vector2:
	return _meter.global_position + _meter.size / 2.0 if _meter.is_inside_tree() else global_position + size / 2.0
