extends PanelContainer
## The decision panel for an Action Set: what is still needed, or the predicted
## outcome as comparisons (your total against the target), a verdict, and the
## rewards and costs. During a multi-step action it shows that step's instruction.

const T = preload("res://ui/theme/tokens.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const HelpButton = preload("res://ui/widgets/help_button.gd")
const UI = preload("res://ui/theme/theme.gd")

signal intent(data: Dictionary)

const HELP_W := 64.0

var _box := VBoxContainer.new()
var _bars: Array = []
var _verdict: Control = null
## The height asked for so far for each Encounter and step, so the panel does not
## change size as cards are placed: it is sized for its fullest look at once.
var _needed := {}
var _key := ""
var _kind := ""


func _init() -> void:
	add_theme_stylebox_override("panel", UI.stone_zone())
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)


func render(vs: Dictionary) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_bars = []
	_verdict = null
	var p = vs.preview
	var prompt: Dictionary = vs.prompt
	var enc = vs.encounter
	_kind = enc.kind if enc != null else ""
	_key = "%s|%s|%s" % [enc.get("title", "") if enc != null else "", vs.phase, vs.mode]
	var fatal: bool = p != null and p.fatal and vs.mode == "none"
	add_theme_stylebox_override("panel", UI.stone_zone(T.BAD if fatal else Color(0, 0, 0, 0), 12, 3.0 if fatal else 2.0))
	if p == null or vs.mode != "none" or p.status != "ready":
		_prompt(vs, p, prompt)
		return
	for i in p.comparisons.size():
		var bar := _Compare.new()
		bar.data = p.comparisons[i]
		bar.custom_minimum_size.y = 76 if p.comparisons[i].note != "" else 52
		_box.add_child(bar)
		_bars.append(bar)
		if p.changed.has("value%d" % i) or p.changed.has("result%d" % i):
			bar.pulse()
	_box.add_child(UI.spacer())
	_verdict = _verdict_row(p, fatal)
	_box.add_child(_verdict)
	if p.changed.has("verdict"):
		UI.flash(_verdict, T.INK)
	_box.add_child(_outcome_row(p))


## The height this panel needs at `width`: the larger of what it shows now and its
## fullest look for this Encounter (every comparison, the verdict and the outcome),
## and never less than it asked for earlier in the same Encounter and step.
func needed_height(width: float) -> float:
	var margins: Vector2 = get_theme_stylebox("panel").get_minimum_size()
	var sep: int = _box.get_theme_constant("separation")
	var h: float = UI.stack_height(_box, width - margins.x)
	# Fullest look: the comparison rows, a spacer, the verdict and the outcome row.
	var rows: Array = [52.0, 76.0] if _kind == "enemy" else [52.0]
	var full: float = rows.reduce(func(a, b): return a + b, 0.0) + 36.0 + 44.0 + (rows.size() + 2) * sep
	if _kind.begins_with("final"):
		full += 26.0  # the warning when playing would end the game
	h = maxf(h, full) + margins.y
	h = maxf(h, _needed.get(_key, 0.0))
	_needed[_key] = h
	return h


## Count the totals up from nothing; used when the Action Set is played.
func play_tally(duration: float) -> void:
	for bar in _bars:
		bar.shown = 0.0
		create_tween().tween_property(bar, "shown", 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if _verdict != null:
		_verdict.modulate.a = 0.0


func reveal_verdict(duration: float) -> void:
	if _verdict == null:
		return
	_verdict.modulate.a = 1.0
	if UI.reduced_motion:
		return
	_verdict.pivot_offset = _verdict.size / 2.0
	_verdict.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(_verdict, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Put everything in its final state at once.
func settle() -> void:
	for bar in _bars:
		bar.shown = 1.0
	if _verdict != null:
		_verdict.modulate.a = 1.0
		_verdict.scale = Vector2.ONE


func _prompt(vs: Dictionary, p, prompt: Dictionary) -> void:
	if prompt.step != "":
		_box.add_child(UI.label(prompt.step.to_upper(), ["body_bold", T.LABEL[1]], T.GOLD))
	_box.add_child(UI.label(prompt.text, T.BODY, T.INK, true))
	if p != null and vs.mode == "none":
		if p.status == "incomplete":
			_box.add_child(UI.label("Still needed", T.LABEL, T.INK_MUTED))
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 6)
			flow.add_theme_constant_override("v_separation", 6)
			for name in p.missing:
				var pill := UI.stone_panel("inset", 0.4)
				var inset: StyleBox = pill.get_theme_stylebox("panel")
				inset.edge = T.GOLD
				inset.edge_width = 1.0
				var l := UI.label("  %s  " % name, T.LABEL, T.INK)
				pill.add_child(l)
				flow.add_child(pill)
			_box.add_child(flow)
		elif p.status == "blocked":
			_box.add_child(UI.label(p.reason, T.BODY, T.BAD, true))
	_box.add_child(UI.spacer())
	if vs.phase == "setup":
		_box.add_child(UI.label("Hold a card to see its other Levels.", T.LABEL, T.INK_MUTED, true))
	elif p != null and vs.mode == "none":
		_box.add_child(UI.label("Tap a card to place it. Hold a card to inspect it.", T.LABEL, T.INK_MUTED, true))


func _verdict_row(p: Dictionary, fatal: bool) -> Control:
	var look: Dictionary = T.VERDICT.get(p.verdict, T.VERDICT.loss)
	var colour: Color = T.BAD if fatal else look.color
	var row := UI.hbox(T.S)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.icon_rect(look.icon, 36, colour))
	var text := UI.label(p.verdict_text.to_upper(), ["display_bold", 28], colour)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(text)
	if not fatal:
		return row
	var col := UI.vbox(0)
	col.add_child(row)
	var warn := UI.label("Playing this ends the game in defeat.", ["body_bold", T.LABEL[1]], T.BAD)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(warn)
	return col


## Rewards on the left, each cost on the right.
func _outcome_row(p: Dictionary) -> Control:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 4)
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	if p.rewards.xp > 0:
		row.add_child(_pill("+%d" % p.rewards.xp, "xp", "", T.GOLD, "xp"))
	for c in p.costs:
		var text: String = str(c.value) if c.value > 0 else c.text
		var help: String = {"damage": "soak", "time": "time", "poison": "poison", "reserve": "reserve", "knock_out": "knock_out"}[c.id]
		row.add_child(_pill(text, c.icon, c.element, T.BAD, help))
	if p.rewards.xp <= 0 and p.costs.is_empty() and p.tier < 0:
		row.add_child(UI.label("No reward, no cost", T.LABEL, T.INK_MUTED))
	return row


func _pill(text: String, icon_name: String, element: String, colour: Color, help_id: String) -> Control:
	var b := HelpButton.new()
	b.custom_minimum_size = Vector2(64, 44)
	HelpTip.mark(b, help_id)
	b.add_theme_stylebox_override("normal", UI.box(Color(colour, 0.16), colour, 2, 22, 4))
	b.add_theme_stylebox_override("hover", UI.box(Color(colour, 0.3), colour, 2, 22, 4))
	b.add_theme_stylebox_override("pressed", UI.box(Color(colour, 0.4), colour, 2, 22, 4))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.icon_rect(icon_name, 26, colour))
	var l := UI.label(text, ["display_bold", 26] if text.is_valid_int() or text.begins_with("+") else ["body_bold", T.LABEL[1]], T.INK)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	if element != "":
		row.add_child(UI.icon_rect(element, 22, T.ether_ink(element)))
	UI.ignore_mouse(row)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 12)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(row)
	b.add_child(m)
	m.minimum_size_changed.connect(func(): b.custom_minimum_size.x = maxf(HELP_W, m.get_combined_minimum_size().x))
	b.custom_minimum_size.x = maxf(HELP_W, m.get_combined_minimum_size().x)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(func(): intent.emit({"type": "help", "id": help_id, "source": b}))
	return b


## One comparison: your total, a bar filled toward the target, and the target.
class _Compare extends Control:
	const T = preload("res://ui/theme/tokens.gd")
	const UI = preload("res://ui/theme/theme.gd")

	var data := {}
	## 0 to 1: how much of the total has been counted up.
	var shown := 1.0: set = _set_shown

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _set_shown(v: float) -> void:
		shown = v
		queue_redraw()

	func pulse() -> void:
		UI.flash(self, T.GOLD)

	func _draw() -> void:
		var num := UI.font("display_bold")
		var lab := UI.font("body_medium")
		var row_h := 52.0
		var colour: Color = T.VERDICT[data.result].color
		var value := int(round(data.value * shown))
		var value_text := str(value)
		var fs := 44
		var icon := 30.0
		# Your side: icon, label and total.
		draw_texture_rect(UI.icon(data.icon), Rect2(0, 2, icon, icon), false, T.INK)
		draw_string(lab, Vector2(0, row_h - 2), data.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, T.INK_MUTED)
		var vx := 96.0
		var vw := 66.0
		var base := row_h / 2.0 + (num.get_ascent(fs) - num.get_descent(fs)) / 2.0
		var sz := num.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(num, Vector2(vx + vw - sz.x, base), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)
		# Their side: the target.
		var target_text := str(data.target)
		var ts := 34
		var tsz := num.get_string_size(target_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ts)
		var tx := size.x - tsz.x - 30
		var tbase := row_h / 2.0 + (num.get_ascent(ts) - num.get_descent(ts)) / 2.0
		draw_string(num, Vector2(tx, tbase), target_text, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, T.INK)
		draw_texture_rect(UI.icon(data.target_icon), Rect2(size.x - 26, (row_h - 26) / 2.0, 26, 26), false, T.INK_MUTED)
		# The bar between them.
		var bx := vx + vw + 12
		var bar := Rect2(bx, row_h / 2.0 - 8, maxf(20.0, tx - 12 - bx), 16)
		draw_style_box(UI.box(T.BG_RAISED, T.LINE_SOFT, 1, 8, 0), bar)
		var tiers: Array = data.get("tiers", [])
		var top: float = float(tiers[-1]) if not tiers.is_empty() else float(data.target)
		var full: float = maxf(1.0, top)
		var frac := clampf(value / full, 0.0, 1.0)
		if frac > 0.0:
			draw_style_box(UI.box(colour, Color.TRANSPARENT, 0, 8, 0),
				Rect2(bar.position, Vector2(maxf(16.0, bar.size.x * frac), bar.size.y)))
		# Marks: half the target for a Narrow Victory, or each tier.
		var marks: Array = tiers.slice(0, tiers.size() - 1) if not tiers.is_empty() else []
		if tiers.is_empty() and data.icon != "initiative":
			marks = [ceili(data.target / 2.0)]
		for m in marks:
			var mx: float = bar.position.x + bar.size.x * clampf(m / full, 0.0, 1.0)
			draw_line(Vector2(mx, bar.position.y - 5), Vector2(mx, bar.end.y + 5), T.INK, 2.0)
		if data.note != "":
			draw_texture_rect(UI.icon(T.VERDICT[data.result].icon), Rect2(vx, row_h + 1, 20, 20), false, colour)
			draw_string(lab, Vector2(vx + 26, row_h + 19), data.note, HORIZONTAL_ALIGNMENT_LEFT, size.x - vx - 26, T.LABEL[1], colour)
