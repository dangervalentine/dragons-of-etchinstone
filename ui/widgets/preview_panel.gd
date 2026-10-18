extends PanelContainer
## The math box (contracts/math-box.md): the sum the game is doing for this Action
## Set. One equation row per sum (Attack and Initiative against an Enemy, Move on a
## Journey), each term the engine's own, signed and named, then the total set
## against its target; under them the verdict and its consequences. While a role is
## empty the rows show the terms so far and what is still needed. During a
## multi-step action it shows that step's instruction instead.

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
## A row the Boost is aimed from (Attack or Initiative against an Enemy) is a tap
## target, so never shorter than this (specs/010 research R4).
const ROW_H_AIM := float(T.TAP_MIN)
## The verdict's type: bold body text at the subhead's size.
const VERDICT := ["body_bold", 24]
## How the Hand is arranged (specs/010): a card's place is its Role.
const HINT := "Tap two cards to swap their Roles. Hold a card to inspect it."
const TERM := T.NUMERAL_S
const TOTAL := T.NUMERAL
const MINUS := "\u2212"

var _box := VBoxContainer.new()
## The total labels on show, by sum id, with the value each shows when settled.
var _totals := {}
var _shown_totals := {}
var _verdict: Control = null
## The height asked for so far for each Encounter and step, so the panel does not
## change size as cards are placed: it is sized for its fullest look at once.
var _needed := {}
var _key := ""
var _kind := ""
var _phase := ""
## Whether the Attack and Initiative rows aim the Boost in this step.
var _aiming := false


func _init() -> void:
	add_theme_stylebox_override("panel", UI.stone_zone())
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)


func render(vs: Dictionary) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_totals = {}
	_verdict = null
	var p = vs.preview
	var prompt: Dictionary = vs.prompt
	var enc = vs.encounter
	_kind = enc.kind if enc != null else ""
	_phase = vs.phase
	_key = "%s|%s|%s" % [enc.get("title", "") if enc != null else "", vs.phase, vs.mode]
	var fatal: bool = p != null and p.fatal and vs.mode == "none"
	add_theme_stylebox_override("panel", UI.stone_zone(T.BAD if fatal else Color(0, 0, 0, 0), 12, 3.0 if fatal else 2.0))
	var m: Dictionary = vs.get("math", {})
	if p == null or vs.mode != "none" or p.status == "blocked" or m.is_empty():
		_shown_totals = {}
		_prompt(vs, p, prompt)
		return
	_aiming = m.sums.any(func(s): return s.get("aim") != null)
	for s in m.sums:
		if s.get("aim") != null:
			_box.add_child(_aim_row(s))
		else:
			_box.add_child(_row(s))
			if s.note != "" and not _final():
				_box.add_child(_note(s))
		if s.target.terms.size() > 1:
			_box.add_child(_target_sum(s))
	if not m.complete:
		_box.add_child(UI.spacer())
		if _aiming and m.missing.all(func(x): return x.begins_with("Boost target")):
			# All that is left is the Boost's aim, which the rows' "Add Boost" cells ask
			# for: no more words, so the rows keep their room (specs/010 research R4).
			pass
		else:
			_box.add_child(UI.label(prompt.text, T.BODY, T.INK, true))
			# By the Final Battle the player knows how to swap cards, and its box is short.
			if not _final():
				_box.add_child(UI.label(HINT, T.LABEL, T.INK_MUTED, true))
		_shown_totals = {}
		return
	_box.add_child(UI.spacer())
	_verdict = _outcome_row(p, m, fatal)
	_box.add_child(_verdict)
	# A set that ends the game is said by the red edge, the verdict and Play's warning
	# look; the box keeps its room for the rows that aim the Boost (specs/010 R4).
	if p.changed.has("verdict"):
		UI.flash(_verdict, T.INK)
	_count_changed()


## The height this panel needs at `width`: the larger of what it shows now and its
## fullest look for this Encounter and step (every row, the notes, the outcome and
## the warning), and never less than it asked for earlier in the same Encounter and
## step.
func needed_height(width: float) -> float:
	var margins: Vector2 = get_theme_stylebox("panel").get_minimum_size()
	var sep: int = _box.get_theme_constant("separation")
	var h: float = UI.stack_height(_box, width - margins.x)
	# Fullest look: the rows, the Initiative note (Region Enemies; inside its row
	# while the Boost is aimed from it), a spacer and the outcome row, plus a second
	# line of outcome when the verdict and its cost do not share one (Final Enemy).
	var r := _row_h()
	var rows: Array = {"enemy": [r, r, 26.0], "journey": [r, 26.0],
		"final_journey": [r], "final_enemy": [r, r]}.get(_kind, [r])
	if _aiming:
		# Two aim rows; the Initiative note sits inside its row.
		rows = [ROW_H_AIM, ROW_H_AIM]
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


## A total that changed since the last render counts to its new value.
func _count_changed() -> void:
	var now := {}
	for id in _totals:
		var v: int = _totals[id].get_meta("value")
		now[id] = v
		if _shown_totals.has(id) and _shown_totals[id] != v:
			_count(_totals[id], _shown_totals[id], v, T.COUNT)
	_shown_totals = now


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


## Inside an aim row, the Initiative note's line: the row's cells give it this much of
## the row's 88, so the row stays one tap target tall.
const NOTE_H := 28.0
## Inner room each side of an aim row, so its terms stand clear of its edge.
const AIM_PAD := 10


## A row the Boost is aimed from: the sum's row as a button, lit while the Boost is
## aimed here, inviting the tap with a "Boost?" cell while a Boost waits for its aim.
## The Initiative row carries its note inside it.
func _aim_row(s: Dictionary) -> Control:
	var aim: Dictionary = s.aim
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Add the Boost to %s." % s.label
	var lit: bool = not aim.on.is_empty()
	var edge: Color = T.GOLD if aim.open else (T.FOCUS if lit else Color(T.LINE_SOFT, 0.6))
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var fill := Color(T.FOCUS, 0.10 if lit else 0.0)
		if st != "normal" and st != "disabled":
			fill = Color(T.FOCUS, 0.18)
		b.add_theme_stylebox_override(st, UI.box(fill, edge, 2, T.RADIUS_S, 0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var col := UI.vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	# The "Add Boost" cell asks for the aim itself: the row lists only what else is missing.
	var shown := s.duplicate()
	shown.missing = s.missing.filter(func(x): return not x.begins_with("Boost target"))
	var row := _row(shown)
	if aim.open:
		var ask := _cell("?", "Add Boost", T.GOLD, TERM)
		ask.modulate.a = 0.75
		row.add_child(ask)
	col.add_child(row)
	if s.note != "" and not _final():
		# The note shares the row's 88: the cells give up its line.
		for c in row.get_children():
			if c.custom_minimum_size.y == _row_h():
				c.custom_minimum_size.y = ROW_H_AIM - NOTE_H
		col.add_child(_note(s))
	UI.ignore_mouse(col)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, AIM_PAD)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(col)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(m)
	# A tap target both ways from the start, before the box has laid it out full width.
	b.custom_minimum_size = Vector2(ROW_H_AIM, maxf(ROW_H_AIM, m.get_combined_minimum_size().y))
	m.minimum_size_changed.connect(func(): b.custom_minimum_size.y = maxf(ROW_H_AIM, m.get_combined_minimum_size().y))
	var to: String = aim.to
	b.pressed.connect(func(): intent.emit({"type": "aim_boost", "to": to}))
	return b


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


func _prompt(vs: Dictionary, p, prompt: Dictionary) -> void:
	if prompt.step != "":
		_box.add_child(UI.label(prompt.step.to_upper(), T.EYEBROW, T.GOLD))
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
		_box.add_child(UI.label(HINT, T.LABEL, T.INK_MUTED, true))


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
