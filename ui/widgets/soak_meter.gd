extends PanelContainer
## The Soak step: the damage owed, a meter that fills as cards are chosen to
## Downgrade, and whether it is covered yet.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

var _box := VBoxContainer.new()
var _meter := Control.new()
var _due := 1
var _total := 0


func _init() -> void:
	add_theme_stylebox_override("panel", UI.box(T.BG_SURFACE, T.BAD, 2, T.RADIUS_M, 12))
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	_meter.custom_minimum_size.y = 34
	_meter.draw.connect(_draw_meter)


func render(vs: Dictionary) -> void:
	var s: Dictionary = vs.soak
	_due = maxi(1, s.due)
	_total = s.total
	if _meter.get_parent() != null:
		_box.remove_child(_meter)
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var head := UI.hbox(T.S)
	head.add_child(UI.icon_rect("poison" if s.poison else "hp", 36, T.BAD))
	head.add_child(UI.label(("Poison: %d damage" if s.poison else "%d damage") % s.due, T.HEADING, T.BAD))
	if s.element != "":
		head.add_child(UI.icon_rect(s.element, 30, T.ether(s.element)))
	_box.add_child(head)
	_box.add_child(_meter)
	var status := "Covered. Take the damage to go on." if s.covered else "%d more to Soak." % (s.due - s.total)
	_box.add_child(UI.label(status, ["body_bold", T.BODY[1]], T.GOOD if s.covered else T.INK))
	var how := UI.label("Tap cards to Downgrade them. Matching Armor Soaks double.", T.LABEL, T.INK_MUTED, true)
	how.custom_minimum_size.x = 300
	_box.add_child(how)
	_meter.queue_redraw()


func _draw_meter() -> void:
	var r := Rect2(Vector2.ZERO, _meter.size)
	_meter.draw_style_box(UI.box(T.BG_RAISED, T.LINE_SOFT, 1, 10, 0), r)
	var frac := clampf(_total / float(_due), 0.0, 1.0)
	if frac > 0.0:
		_meter.draw_style_box(UI.box(T.GOOD if frac >= 1.0 else T.GOLD, Color.TRANSPARENT, 0, 10, 0),
			Rect2(r.position, Vector2(maxf(20.0, r.size.x * frac), r.size.y)))
	var font := UI.font("display_bold")
	var text := "%d / %d" % [_total, _due]
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	_meter.draw_string(font, Vector2((r.size.x - sz.x) / 2.0, r.size.y / 2.0 + 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, T.INK)
