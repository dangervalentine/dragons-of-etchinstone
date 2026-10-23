extends PanelContainer
## The Upgrade step: the XP there is to spend, and, unless the card says it
## elsewhere (`recap` off, as on the Upgrade note, specs/015), how the Encounter went.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

var _box := VBoxContainer.new()
var amount: Label
var _icon: Control
## The XP there is, as a bar that empties as it is spent (the Soak's meter fills
## as the damage is covered; specs/015): what is left of all there was.
var _bar := Control.new()
var _total := 0
var _left := 0.0
## The bar and figure counting to what is left (count_to()).
var _count: Tween
## Whether to say how the Encounter went above the XP.
var recap := true


func _init() -> void:
	add_theme_stylebox_override("panel", UI.stone_zone())
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	_bar.custom_minimum_size.y = 34
	_bar.draw.connect(_draw_bar)


## The height this panel needs at `width`.
func needed_height(width: float) -> float:
	var margins: Vector2 = get_theme_stylebox("panel").get_minimum_size()
	return UI.stack_height(_box, width - margins.x) + margins.y


func render(vs: Dictionary) -> void:
	if _bar.get_parent() != null:
		_box.remove_child(_bar)
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	# Drawn again as Upgrades are chosen or taken back, the bar drains or fills from
	# where it stood to what is left; a new purse starts full.
	var draining := amount != null and int(vs.get("xp_total", vs.xp)) == _total and not is_equal_approx(_left, vs.xp)
	_total = int(vs.get("xp_total", vs.xp))
	if not draining:
		_kill_count()
		_left = float(vs.xp)
	var r: Dictionary = vs.recap if recap else {}
	if not r.is_empty():
		var look: Dictionary = T.VERDICT[r.outcome]
		var head := UI.hbox(T.SPACE_2)
		head.add_child(UI.icon_rect(look.icon, 34, look.color))
		head.add_child(UI.label(look.text, T.HEADING, look.color))
		_box.add_child(head)
		var notes := []
		if r.damage > 0:
			notes.append("%d damage" % r.damage)
		if r.time_penalty > 0:
			notes.append("%d time" % r.time_penalty)
		if r.knocked_out:
			notes.append("Knocked Out")
		if not notes.is_empty():
			_box.add_child(UI.label("Cost: " + ", ".join(notes), T.BODY_SM, T.PARCHMENT_MUTED))
	var purse := UI.hbox(T.SPACE_2)
	_icon = UI.icon_rect("xp", T.NOTE_ICON, T.BRASS_BRIGHT)
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	purse.add_child(_icon)
	amount = UI.label(str(roundi(_left)), T.NUMERAL, T.BRASS_BRIGHT)
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purse.add_child(amount)
	var cap := UI.label("XP to spend", T.BODY, T.PARCHMENT)
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purse.add_child(cap)
	_box.add_child(purse)
	_box.add_child(_bar)
	_bar.queue_redraw()
	_box.add_child(UI.label(vs.prompt.text, T.BODY_SM, T.PARCHMENT_MUTED, true))
	if draining:
		count_to(vs.xp, T.FILL)


## The bar: gold for the XP left, emptying from the right as it is spent, its
## count of what is left over all there was.
func _draw_bar() -> void:
	var r := Rect2(Vector2.ZERO, _bar.size)
	_bar.draw_style_box(UI.box(T.WELL, T.LINE, 1, T.RADIUS_PLATE, 0), r)
	var frac := clampf(_left / float(_total), 0.0, 1.0) if _total > 0 else 0.0
	if frac > 0.0:
		_bar.draw_style_box(UI.box(T.BRASS_BRIGHT, Color.TRANSPARENT, 0, T.RADIUS_PLATE, 0),
			Rect2(r.position, Vector2(maxf(20.0, r.size.x * frac), r.size.y)))
	var font := UI.font(T.NUMERAL_SM)
	var fs: int = T.NUMERAL_SM.size
	var text := "%d / %d" % [roundi(_left), _total]
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	_bar.draw_string(font, Vector2((r.size.x - sz.x) / 2.0, r.size.y / 2.0 + fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		T.GROUND if frac >= 0.5 else T.PARCHMENT)


func _set_left(v: float) -> void:
	_left = v
	if is_instance_valid(amount):
		amount.text = str(roundi(v))
	_bar.queue_redraw()


## Global centre of the XP figure, where XP flies to.
func point() -> Vector2:
	return amount.global_position + amount.size / 2.0 if amount != null else global_position + size / 2.0


## Global centre of the big star, where XP stars leave from and come back to.
func star_point() -> Vector2:
	return _icon.global_position + _icon.size / 2.0 if _icon != null and _icon.is_inside_tree() else point()


## Count the XP figure and its bar down (or up) from where they stand to `n`.
func count_to(n: int, duration: float) -> void:
	_kill_count()
	if UI.reduced_motion or not is_inside_tree():
		_set_left(n)
		return
	# Bound to the purse, not its figure, so drawing the purse again does not cut it off.
	_count = create_tween()
	_count.tween_method(_set_left, _left, float(n), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _kill_count() -> void:
	if _count != null and _count.is_valid():
		_count.kill()


## The XP left unspent fades away as the Upgrade step ends: it is lost.
func fade_out(duration: float) -> void:
	for c in [amount, _icon]:
		if c != null and c.is_inside_tree():
			c.create_tween().tween_property(c, "modulate:a", 0.0, duration)
	count_to(0, duration)
