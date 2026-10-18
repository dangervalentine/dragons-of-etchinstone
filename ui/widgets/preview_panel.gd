extends PanelContainer
## The box under the Encounter face (specs/011 contracts/left-box.md). Before Play it
## says only what to do next: the cards show what each gives. Once Play is pressed,
## reveal() shows the sum the game did (contracts/math-box.md): one equation row per
## sum (Attack and Initiative against an Enemy, Move on a Journey), each term the
## engine's own, signed and named, then the total set against its target; under
## them the verdict and its consequences.

const T = preload("res://ui/theme/tokens.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const HelpButton = preload("res://ui/widgets/help_button.gd")
const UI = preload("res://ui/theme/theme.gd")

signal intent(data: Dictionary)

const HELP_W := 64.0
## One equation row: a term's number over its label. Every cell is this tall, so
## the box keeps one size as terms arrive. The Final Battle's rows are a little
## smaller: the dragon's face leaves the box less room (T.DRAGON_MIN).
const ROW_H := 64.0
const ROW_H_FINAL := 52.0
## The verdict's type: bold body text at the subhead's size.
const VERDICT := ["body_bold", 24]
const TERM := T.NUMERAL_S
const TOTAL := T.NUMERAL
const MINUS := "\u2212"

## The step's tip, shown until Play; and the sum, built with it but shown only once
## Play is pressed, so the box is sized for it from the start.
var _box := VBoxContainer.new()
var _sum := VBoxContainer.new()
## The total labels in the sum, by sum id, with the value each shows when settled.
var _totals := {}
var _verdict: Control = null
## The height asked for so far for each Encounter and step, so the panel does not
## change size as cards are placed: it is sized for its fullest look at once.
var _needed := {}
var _key := ""
var _kind := ""
var _phase := ""
var _math := {}
var _preview = null


func _init() -> void:
	# The sum after Play never spills past the box (the Final Battle's dragon face
	# keeps its whole ladder, so the box may be shorter than the sum wants).
	clip_contents = true
	add_theme_stylebox_override("panel", UI.stone_zone())
	for b in [_box, _sum]:
		b.add_theme_constant_override("separation", 6)
		add_child(b)
	_sum.visible = false


func render(vs: Dictionary) -> void:
	for b in [_box, _sum]:
		for c in b.get_children():
			b.remove_child(c)
			c.queue_free()
	_box.visible = true
	_sum.visible = false
	_totals = {}
	_verdict = null
	var p = vs.preview
	var enc = vs.encounter
	_kind = enc.kind if enc != null else ""
	_phase = vs.phase
	_key = "%s|%s|%s" % [enc.get("title", "") if enc != null else "", vs.phase, vs.mode]
	_math = vs.get("math", {})
	_preview = p
	_prompt(vs, p, vs.prompt)
	if p != null and p.status == "ready" and vs.mode == "none" and not _math.is_empty() and _math.complete:
		_build_sum(p, _math)
	_lay_out()


## Lay the tip out at once rather than at the end of the frame: its wrapped lines
## take their width now, so nothing reads the box half laid out.
func _lay_out() -> void:
	if not is_inside_tree():
		return
	# Twice: the first pass gives the wrapped lines their width, the second the height
	# that width needs.
	for i in 2:
		for b in [_box, _sum]:
			for c in b.get_children():
				if c is Label:
					c.update_minimum_size()
			b.update_minimum_size()
		for c in [self, _box, _sum]:
			c.notification(Container.NOTIFICATION_SORT_CHILDREN)


## Show the sum of the set just played in place of the tip: called by the animator
## as the totals count up. Built from the state before Play, which the screen keeps
## until the sequence ends.
func reveal() -> void:
	if _sum.get_child_count() == 0:
		return
	_box.visible = false
	_sum.visible = true
	_lay_out()


## Back to the tip, as before Play (the UI check measures the box both ways).
func conceal() -> void:
	_box.visible = true
	_sum.visible = false
	_lay_out()


## Whether there is a sum to reveal: a complete set the engine accepts.
func has_sum() -> bool:
	return _sum.get_child_count() > 0


func _build_sum(p: Dictionary, m: Dictionary) -> void:
	var fatal: bool = p.fatal
	for s in m.sums:
		_sum.add_child(_row(s))
		if s.note != "" and not _final():
			_sum.add_child(_note(s))
		if s.target.terms.size() > 1:
			_sum.add_child(_target_sum(s))
	_sum.add_child(UI.spacer())
	_verdict = _outcome_row(p, m, fatal)
	_sum.add_child(_verdict)


## The height this panel needs at `width`: the larger of its tip and its sum, and of
## the sum's fullest look for this Encounter and step (every row, the notes and the
## outcome), and never less than it asked for earlier in the same Encounter and step.
func needed_height(width: float) -> float:
	var margins: Vector2 = get_theme_stylebox("panel").get_minimum_size()
	var sep: int = _sum.get_theme_constant("separation")
	var h: float = maxf(UI.stack_height(_box, width - margins.x), UI.stack_height(_sum, width - margins.x))
	# Fullest look: the rows, the Initiative note (Region Enemies), a spacer and the
	# outcome row, plus a second line of outcome when the verdict and its cost do not
	# share one (Final Enemy).
	var r := _row_h()
	var rows: Array = {"enemy": [r, r, 26.0], "journey": [r, 26.0],
		"final_journey": [r], "final_enemy": [r, r]}.get(_kind, [r])
	var full: float = rows.reduce(func(a, b): return a + b, 0.0) + 44.0 + rows.size() * sep
	if _kind == "final_enemy":
		full += 44.0 + 4.0
	h = maxf(h, full) + margins.y
	h = maxf(h, _needed.get(_key, 0.0))
	_needed[_key] = h
	return h


## Count the totals up from nothing; used when the Action Set is played.
func play_tally(duration: float) -> void:
	for id in _totals:
		_count(_totals[id], 0, _totals[id].get_meta("value"), duration)
	if _verdict != null:
		_verdict.modulate.a = 0.0


func reveal_verdict(duration: float) -> void:
	if _verdict == null:
		return
	_verdict.modulate.a = 1.0
	if UI.reduced_motion:
		return
	_verdict.pivot_offset = _verdict.size / 2.0
	_verdict.scale = Vector2(1.3, 1.3)
	create_tween().tween_property(_verdict, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Put everything in its final state at once.
func settle() -> void:
	for id in _totals:
		var l: Label = _totals[id]
		l.text = str(l.get_meta("value"))
	if _verdict != null:
		_verdict.modulate.a = 1.0
		_verdict.scale = Vector2.ONE


func _final() -> bool:
	return _kind.begins_with("final")


func _row_h() -> float:
	return ROW_H_FINAL if _final() else ROW_H


func _count(l: Label, from: int, to: int, duration: float) -> void:
	if UI.reduced_motion or not l.is_inside_tree():
		l.text = str(to)
		return
	var show := func(v: float) -> void:
		if is_instance_valid(l):
			l.text = str(roundi(v))
	show.call(from)
	# Bound to the label, so the count stops if the box is redrawn under it.
	l.create_tween().tween_method(show, float(from), float(to), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## One equation row: each term, then "=" and the total over the sum's name, then
## "/" and the target over what it is. While incomplete, "Still needed" instead of
## the total.
func _row(s: Dictionary) -> Control:
	var row := HFlowContainer.new()
	# Wide enough apart that the captions under neighbouring terms read as two.
	# The Final Battle's box is narrow: closer terms keep each sum on one line.
	row.add_theme_constant_override("h_separation", 4 if _final() else T.S + 2)
	row.add_theme_constant_override("v_separation", 4)
	row.tooltip_text = s.label
	for i in s.terms.size():
		row.add_child(_term(s.terms[i], i == 0))
	if s.total == null and s.missing.is_empty():
		# Only the Boost's aim is missing, which its own cell asks for.
		return row
	if s.total == null:
		# With nothing placed, the sum's icon and name lead the list, rather than an
		# empty cell whose caption runs on into it.
		var lead := "Still needed:"
		if s.terms.is_empty():
			if s.icon != "":
				row.add_child(UI.icon_rect(s.icon, 26, T.INK_MUTED))
			lead = "%s still needs" % s.label
		# The Final Enemy's two rows share a short box: the list wraps beside the cell
		# rather than dropping under it, so each row keeps its one height.
		var beside := _kind == "final_enemy"
		# The Final Battle's list of six Roles is longer than the box is wide: it wraps.
		var long: bool = s.missing.size() > 3
		var need := UI.label(lead + (" " if beside else "\n") + ", ".join(s.missing),
			T.LABEL, T.INK_MUTED, beside or long)
		need.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		need.custom_minimum_size.y = _row_h()
		if beside or long:
			need.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			need.custom_minimum_size.x = 160
		row.add_child(need)
		return row
	if not s.terms.is_empty():
		row.add_child(_sign("="))
	var colour: Color = T.VERDICT[s.result].color if T.VERDICT.has(s.result) else T.INK
	var total := _cell(str(s.total), s.label, colour, TOTAL)
	var value_label: Label = total.get_child(0)
	value_label.set_meta("value", int(s.total))
	_totals[s.id] = value_label
	row.add_child(total)
	# The Final Battle's Attack and Move are set against the tiers, which the dragon's
	# face lists and the verdict names; the row stops at the total.
	if _final() and s.id != "initiative":
		return row
	row.add_child(_sign("/"))
	var target_name: String = {"hp": "HP", "initiative": "Enemy" if _kind == "enemy" else "Dragon", "mp": "MP"}.get(s.target.icon, "")
	if s.tier != null:
		target_name = "Tier %d" % (s.tier.index + 1) if s.tier.index >= 0 else "Tier 1"
	row.add_child(_cell(str(s.target.value), target_name, T.INK, TERM, s.target.icon))
	return row


func _term(t: Dictionary, first: bool) -> Control:
	var v: int = t.value
	var text := str(v) if first and v >= 0 else (("+%d" % v) if v >= 0 else MINUS + str(-v))
	var colour := T.INK
	if v < 0:
		colour = T.BAD
	elif t.note.begins_with("enhanced") or t.source == "reserve":
		colour = T.GOLD
	var c := _cell(text, t.label, colour, TERM)
	c.tooltip_text = t.label + (": " + t.note if t.note != "" else "")
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	return c


## A number over a small label (and an icon beside the number when given).
func _cell(text: String, caption: String, colour: Color, type: Array, icon := "") -> VBoxContainer:
	var c := UI.vbox(0)
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	c.custom_minimum_size.y = _row_h()
	var top: Control
	var value := UI.label(text, type, colour)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if icon != "":
		var line := UI.hbox(2)
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		if text != "":
			line.add_child(value)
		line.add_child(UI.icon_rect(icon, 22, T.INK_MUTED))
		top = line
	else:
		top = value
	c.add_child(top)
	var cap := UI.label(caption, T.LABEL, T.INK_MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(cap)
	return c


func _sign(text: String) -> Control:
	var l := UI.label(text, T.NUMERAL_S, T.INK_MUTED)
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.custom_minimum_size = Vector2(14, _row_h())
	return l


## Under the Initiative row: who strikes first, and why when it is not Initiative.
func _note(s: Dictionary) -> Control:
	var look: Dictionary = T.VERDICT.get(s.result, T.VERDICT.loss)
	var row := UI.hbox(6)
	row.add_child(UI.icon_rect(look.icon, 20, look.color))
	var l := UI.label(s.note, T.LABEL, look.color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	l.tooltip_text = s.note
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(l)
	return row


## A target that is itself a sum (a Steep peril raising the MP), as one small line
## of the engine's terms.
func _target_sum(s: Dictionary) -> Control:
	var parts := []
	for i in s.target.terms.size():
		var t: Dictionary = s.target.terms[i]
		parts.append(("%s %d" % [t.label, t.value]) if i == 0 else ("+ %s %d" % [t.label, t.value]))
	var l := UI.label("%s = %d" % [" ".join(parts), s.target.value], T.LABEL, T.CAUTION)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	return l


## The step and what to do next. Never a figure: a set the engine refuses says why.
func _prompt(vs: Dictionary, p, prompt: Dictionary) -> void:
	if prompt.step != "":
		_box.add_child(UI.label(prompt.step.to_upper(), T.EYEBROW, T.GOLD))
	_box.add_child(UI.label(prompt.text, T.BODY, T.INK, true))
	if p != null and vs.mode == "none" and p.status == "blocked":
		_box.add_child(UI.label(p.reason, T.BODY, T.BAD, true))
	if vs.phase == "setup":
		_box.add_child(UI.spacer())
		_box.add_child(UI.label("Hold a card to see its other Levels.", T.LABEL, T.INK_MUTED, true))


## The verdict and its consequences on one line: rewards, then each cost. Each
## cost's help names the engine's terms behind it ("Early damage 2 + Ambush 2").
func _outcome_row(p: Dictionary, m: Dictionary, fatal: bool) -> Control:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 4)
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	var look: Dictionary = T.VERDICT.get(p.verdict, T.VERDICT.loss)
	var colour: Color = T.BAD if fatal else look.color
	var verdict := UI.hbox(6)
	verdict.custom_minimum_size.y = 44
	verdict.add_child(UI.icon_rect(look.icon, 30, colour))
	# In the body face, narrower than the display one, so the verdict and its rewards
	# and costs share one line in the left side's width.
	var text := UI.label(p.verdict_text, VERDICT, colour)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	verdict.add_child(text)
	row.add_child(verdict)
	if p.rewards.xp > 0:
		row.add_child(_pill("+%d" % p.rewards.xp, "xp", "", T.GOLD, "xp"))
	for c in p.costs:
		var label: String = str(c.value) if c.value > 0 else c.text
		var help: String = {"damage": "soak", "time": "time", "poison": "poison", "reserve": "reserve", "knock_out": "knock_out"}[c.id]
		var pill := _pill(label, c.icon, c.element, T.BAD, help)
		var why: Array = m.damage_terms if c.id == "damage" else (m.time_terms if c.id == "time" else [])
		if not why.is_empty():
			pill.tooltip_text = "%s: %s" % [c.text, " + ".join(why.map(func(t): return "%s %d" % [t.label, t.value]))]
		row.add_child(pill)
	if p.rewards.xp <= 0 and p.costs.is_empty() and p.tier < 0 and not fatal:
		row.add_child(UI.label("No reward, no cost", T.LABEL, T.INK_MUTED))
	return row


func _pill(text: String, icon_name: String, element: String, colour: Color, help_id: String) -> Control:
	var b := HelpButton.new()
	b.custom_minimum_size = Vector2(64, 44)
	HelpTip.mark(b, help_id)
	var edge := T.muted(colour)
	b.add_theme_stylebox_override("normal", UI.box(Color(colour, 0.12), edge, 2, 22, 4))
	b.add_theme_stylebox_override("hover", UI.box(Color(colour, 0.24), edge, 2, 22, 4))
	b.add_theme_stylebox_override("pressed", UI.box(Color(colour, 0.32), edge, 2, 22, 4))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.icon_rect(icon_name, 26, colour))
	var l := UI.label(text, T.NUMERAL_S if text.is_valid_int() or text.begins_with("+") else T.LABEL_BOLD, T.INK)
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
