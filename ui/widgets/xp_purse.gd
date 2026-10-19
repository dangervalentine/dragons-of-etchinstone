extends PanelContainer
## The Upgrade step: how the Encounter went, and the XP there is to spend.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

var _box := VBoxContainer.new()
var amount: Label
var _icon: Control


func _init() -> void:
	add_theme_stylebox_override("panel", UI.stone_zone(T.GOLD))
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)


## The height this panel needs at `width`.
func needed_height(width: float) -> float:
	var margins: Vector2 = get_theme_stylebox("panel").get_minimum_size()
	return UI.stack_height(_box, width - margins.x) + margins.y


func render(vs: Dictionary) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	var r: Dictionary = vs.recap
	if not r.is_empty():
		var look: Dictionary = T.VERDICT[r.outcome]
		var head := UI.hbox(T.S)
		head.add_child(UI.icon_rect(look.icon, 34, look.color))
		head.add_child(UI.label(look.text.to_upper(), T.SUBHEAD, look.color))
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
	_icon = UI.icon_rect("xp", 56, T.GOLD)
	purse.add_child(_icon)
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


## Global centre of the big star, where XP stars leave from and come back to.
func star_point() -> Vector2:
	return _icon.global_position + _icon.size / 2.0 if _icon != null and _icon.is_inside_tree() else point()


## Count the XP figure down (or up) to `n` while stars fly from it (specs/011 R7).
func count_to(n: int, duration: float) -> void:
	if amount == null:
		return
	var from := int(amount.text)
	if UI.reduced_motion or not amount.is_inside_tree():
		amount.text = str(n)
		return
	var l := amount
	var show := func(v: float) -> void:
		if is_instance_valid(l):
			l.text = str(roundi(v))
	l.create_tween().tween_method(show, float(from), float(n), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## The XP left unspent fades away as the Upgrade step ends: it is lost.
func fade_out(duration: float) -> void:
	for c in [amount, _icon]:
		if c != null and c.is_inside_tree():
			c.create_tween().tween_property(c, "modulate:a", 0.0, duration)
