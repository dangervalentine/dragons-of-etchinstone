extends PanelContainer
## The Upgrade step: how the Encounter went, and the XP there is to spend.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

var _box := VBoxContainer.new()
var amount: Label


func _init() -> void:
	add_theme_stylebox_override("panel", UI.raised_panel_box("rest", T.GOLD, 12))
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)


func render(vs: Dictionary) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var r: Dictionary = vs.recap
	if not r.is_empty():
		var look: Dictionary = T.VERDICT[r.outcome]
		var head := UI.hbox(T.S)
		head.add_child(UI.icon_rect(look.icon, 34, look.color))
		head.add_child(UI.label(look.text.to_upper(), ["display_bold", 28], look.color))
		_box.add_child(head)
		var notes := []
		if r.damage > 0:
			notes.append("%d damage" % r.damage)
		if r.time_penalty > 0:
			notes.append("%d time" % r.time_penalty)
		if r.knocked_out:
			notes.append("Knocked Out")
		if not notes.is_empty():
			_box.add_child(UI.label("Cost: " + ", ".join(notes), T.LABEL, T.INK_MUTED))
	var purse := UI.hbox(T.S)
	purse.add_child(UI.icon_rect("xp", 56, T.GOLD))
	amount = UI.label(str(vs.xp), T.NUMERAL_L, T.GOLD)
	purse.add_child(amount)
	var cap := UI.label("XP to spend", T.BODY, T.INK)
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purse.add_child(cap)
	_box.add_child(purse)
	_box.add_child(UI.label(vs.prompt.text, T.LABEL, T.INK_MUTED, true))


## Global centre of the XP figure, where XP flies to.
func point() -> Vector2:
	return amount.global_position + amount.size / 2.0 if amount != null else global_position + size / 2.0
