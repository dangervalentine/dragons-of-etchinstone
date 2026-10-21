extends PanelContainer
## What a step says and what a Play did, on the note laid on the Deck in the card's
## place (specs/013 contracts/left-column.md; before that the box under the face,
## specs/011). Before Play it says only the step, if any: the cards show what each gives. Once Play is pressed,
## reveal() shows the sum the game did (contracts/math-box.md): one equation row per
## sum (Attack and Initiative against an Enemy, Move on a Journey), each term the
## engine's own, signed and named, then the total set against its target, the rows'
## terms, totals and targets in shared columns; the verdict under the first, who
## strikes first under the Initiative; then the damage and any other cost
## (specs/015).

const T = preload("res://ui/theme/tokens.gd")
const HelpTip = preload("res://ui/widgets/help_tip.gd")
const HelpButton = preload("res://ui/widgets/help_button.gd")
const UI = preload("res://ui/theme/theme.gd")

signal intent(data: Dictionary)

const HELP_W := 64.0
## One equation row: a term's number over its label. Every cell is this tall, so
## the box keeps one size as terms arrive. The Final Battle's rows are a little
## smaller, to keep the dragon's sums to their rows.
const ROW_H := 64.0
const ROW_H_FINAL := 52.0
## The verdict's type: bold body text at the subhead's size.
const VERDICT := ["body_bold", 24]
const TERM := T.NUMERAL_S
const TOTAL := T.NUMERAL
const MINUS := "\u2212"
## Whether the note has room to spare (table_note.gd sets it as it lays the card
## out); the result is set out the same either way since specs/015.
var roomy := false
## How wide a line of the card's own words may run before it wraps (table_note.gd
## sets it to its content's width): short lines are centred whole.
var text_room := 300.0

## The step's tip, shown until Play; and the sum, built with it but shown only once
## Play is pressed, so the box is sized for it from the start.
var _box := VBoxContainer.new()
var _sum := VBoxContainer.new()
## The total labels in the sum, by sum id, with the value each shows when settled.
var _totals := {}
var _verdict: Control = null
## The figure of the XP the verdict brings, which counts up in its pill as it is won.
var _xp: Label = null
## The pill of each cost of the Play, by cost id, which stirs as the cost is paid.
var _cost_pills := {}
## The height asked for so far for each Encounter and step, so the panel does not
## change size as cards are placed: it is sized for its fullest look at once.
var _needed := {}
var _key := ""
var _kind := ""
var _phase := ""
var _math := {}
var _preview = null
## How tightly the sum's rows are set, so the widest fits across the card: 0 as
## designed; 1 with narrower gaps between the columns; 2 with each two-word caption
## on two lines; 3 with the numerals at the smallest size read too; 4 with each
## sum's terms together, flush right, sharing no columns; 5 with each sum on a row of
## its own width, centred, sharing no columns at all; 6 with the total and target
## of a sum too wide still on a line of their own under its terms.
var _tight := 0
const TIGHTEST := 6


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
	_xp = null
	_cost_pills = {}
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
	# The sums set out in columns every row shares (specs/015): the lead term (the
	# Spell, or the Element for the Initiative), the Boost (its column held on every
	# row, though it adds to one), any other terms, the total and the target. The
	# verdict comes straight under the first sum, who strikes first under the
	# Initiative; then the damage, then any other cost.
	var room: float = text_room - get_theme_stylebox("panel").get_minimum_size().x
	for tight in TIGHTEST + 1:
		_tight = tight
		if _build_rows(p, m, room) <= room or tight == TIGHTEST:
			return
		for c in _sum.get_children():
			_sum.remove_child(c)
			c.free()
		_totals = {}
		_verdict = null
		_xp = null
		_cost_pills = {}


## The sum's rows, verdict and costs at the present tightness; returns how wide the
## widest row is.
func _build_rows(p: Dictionary, m: Dictionary, room: float) -> float:
	var extra_n := 0
	var boosted := false
	for s in m.sums:
		extra_n = maxi(extra_n, _extras(s).size())
		boosted = boosted or _boost_of(s) != null
	var rows := []
	for i in m.sums.size():
		var s: Dictionary = m.sums[i]
		var row := _grid_row(s, boosted, extra_n)
		rows.append(row)
		_sum.add_child(row)
		if s.target.terms.size() > 1:
			_sum.add_child(_target_sum(s))
		if i == 0:
			_verdict = _verdict_line(p)
			_sum.add_child(_verdict)
		if s.note != "":
			_sum.add_child(_strike_line(s))
	# What the Play cost stands a little apart from the sums and the verdict.
	var damage := _cost_line(p, m, ["damage"])
	var status := _cost_line(p, m, ["poison", "time", "reserve", "knock_out"])
	if damage != null or status != null:
		var gap := Control.new()
		gap.custom_minimum_size.y = T.M
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sum.add_child(gap)
	for line in [damage, status]:
		if line != null:
			_sum.add_child(line)
	if _tight < 5:
		return _align(rows)
	var width := 0.0
	for row in rows:
		if _tight >= 6 and row.get_combined_minimum_size().x > room:
			var out := _split(row)
			_sum.add_child(out)
			_sum.move_child(out, row.get_index() + 1)
			width = maxf(width, out.get_combined_minimum_size().x)
		width = maxf(width, row.get_combined_minimum_size().x)
	return width


## The total and target of `row`, from its "=" on, moved to a row of their own under
## the terms, both centred.
static func _split(row: HBoxContainer) -> HBoxContainer:
	var out := HBoxContainer.new()
	out.add_theme_constant_override("separation", row.get_theme_constant("separation"))
	out.alignment = BoxContainer.ALIGNMENT_CENTER
	out.tooltip_text = row.tooltip_text
	var at: int = row.get_meta("equals")
	while row.get_child_count() > at:
		var c := row.get_child(at)
		row.remove_child(c)
		out.add_child(c)
	return out


## The term a sum's first column shows: the Spell, the Element; never the Boost.
static func _lead_of(s: Dictionary):
	return s.terms[0] if not s.terms.is_empty() and s.terms[0].source != "boost" else null


static func _boost_of(s: Dictionary):
	for t in s.terms:
		if t.source == "boost":
			return t
	return null


## The terms after the lead and the Boost (an Armor, a Night Travel, the Reserve).
static func _extras(s: Dictionary) -> Array:
	var lead = _lead_of(s)
	return s.terms.filter(func(t): return t != lead and t.source != "boost")


## One sum as a row of the shared columns; a column a sum has nothing for is held
## empty, so each column lines up down the card.
func _grid_row(s: Dictionary, boosted: bool, extra_n: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4 if _final() or _tight >= 1 else T.S)
	row.tooltip_text = s.label
	if _tight >= 5:
		row.alignment = BoxContainer.ALIGNMENT_CENTER
	var lead = _lead_of(s)
	var extras := _extras(s)
	if _tight >= 4:
		# Only the sum's own terms, as one column.
		var terms := UI.hbox(T.S)
		terms.alignment = BoxContainer.ALIGNMENT_END
		terms.mouse_filter = Control.MOUSE_FILTER_PASS
		for t in [lead, _boost_of(s)] + extras:
			if t != null:
				terms.add_child(_term(t, t == lead))
		row.add_child(terms)
	else:
		row.add_child(_term(lead, true) if lead != null else _gap())
		if boosted:
			var boost = _boost_of(s)
			row.add_child(_term(boost, false) if boost != null else _gap())
		for i in extra_n:
			row.add_child(_term(extras[i], false) if i < extras.size() else _gap())
	row.set_meta("equals", row.get_child_count())
	row.add_child(_sign("="))
	var colour: Color = T.VERDICT[s.result].color if T.VERDICT.has(s.result) else T.INK
	var total := _cell(str(s.total), s.label, colour, TOTAL if _tight < 3 else [TERM[0], T.TEXT_MIN])
	var value_label: Label = total.get_child(0)
	value_label.set_meta("value", int(s.total))
	_totals[s.id] = value_label
	row.add_child(total)
	# The Final Battle's Attack and Move are set against the tiers, which the dragon's
	# face lists and the verdict names: no target.
	if _final() and s.id != "initiative":
		if _tight < 5:
			row.add_child(_sign(""))
			row.add_child(_gap())
		return row
	row.add_child(_sign("/"))
	var target_name: String = {"hp": "HP", "initiative": "Enemy" if _kind == "enemy" else "Dragon", "mp": "MP"}.get(s.target.icon, "")
	if s.tier != null:
		target_name = "Tier %d" % (s.tier.index + 1) if s.tier.index >= 0 else "Tier 1"
	row.add_child(_cell(str(s.target.value), target_name, T.INK, TERM, s.target.icon))
	return row


func _gap() -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = _row_h()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Each column as wide as its widest cell, down every row; returns how wide the
## rows then are.
static func _align(rows: Array) -> float:
	if rows.is_empty():
		return 0.0
	var n: int = rows[0].get_child_count()
	var width := 0.0
	for j in n:
		var w := 0.0
		for row in rows:
			if j < row.get_child_count():
				w = maxf(w, row.get_child(j).get_combined_minimum_size().x)
		for row in rows:
			if j < row.get_child_count():
				row.get_child(j).custom_minimum_size.x = w
		width += w
	return width + maxi(0, n - 1) * rows[0].get_theme_constant("separation")


## A line of the card's own words: an icon and what it says, at one size and type
## for the verdict and for who strikes first, centred across the card; a line
## wider than the card wraps under itself. `beside` is how wide whatever else
## shares the line is (the verdict's XP).
func _say(icon: String, text: String, colour: Color, beside := 0.0) -> HBoxContainer:
	var line := UI.hbox(T.S)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.custom_minimum_size.y = 40
	var i := UI.icon_rect(icon, T.NOTE_ICON, colour)
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(i)
	var l := UI.label(text, VERDICT, colour, true)
	var room := maxf(80.0, text_room - get_theme_stylebox("panel").get_minimum_size().x - T.NOTE_ICON - T.S - (beside + T.S if beside > 0.0 else 0.0))
	var wide: float = UI.font(VERDICT[0]).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, VERDICT[1]).x + 2.0
	l.custom_minimum_size.x = minf(wide, room)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.tooltip_text = text
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	line.add_child(l)
	return line


## Complete, Narrow Victory, Loss (or the tier reached), and the XP it brings.
func _verdict_line(p: Dictionary) -> Control:
	var look: Dictionary = T.VERDICT.get(p.verdict, T.VERDICT.loss)
	var xp: Control = null
	if p.rewards.xp > 0:
		xp = _pill("+%d" % p.rewards.xp, "xp", "", T.GOLD, "xp")
		xp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_xp = xp.get_meta("label")
		_xp.set_meta("value", int(p.rewards.xp))
	var line := _say(look.icon, p.verdict_text, T.BAD if p.fatal else look.color,
		xp.custom_minimum_size.x if xp != null else 0.0)
	if xp != null:
		line.add_child(xp)
	return line


## Under the Initiative: who strikes first, and why when it is not Initiative.
func _strike_line(s: Dictionary) -> Control:
	var look: Dictionary = T.VERDICT.get(s.result, T.VERDICT.loss)
	return _say(look.icon, s.note, look.color)


## The costs `ids` of the Play, a pill each: the damage as its heart, figure and
## Ether; each other cost (Poison, Time, the Reserve, a Knock Out) as its own. Each
## pill's help names the engine's terms behind it. Null with none of them.
func _cost_line(p: Dictionary, m: Dictionary, ids: Array) -> Control:
	var costs: Array = p.costs.filter(func(c): return ids.has(c.id))
	if costs.is_empty():
		return null
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", T.S)
	row.add_theme_constant_override("v_separation", 4)
	for c in costs:
		var label: String = str(c.value) if c.value > 0 else c.text
		var help: String = {"damage": "soak", "time": "time", "poison": "poison", "reserve": "reserve", "knock_out": "knock_out"}[c.id]
		var pill := _pill(label, c.icon, c.element, T.BAD, help)
		_cost_pills[c.id] = pill
		var why: Array = m.damage_terms if c.id == "damage" else (m.time_terms if c.id == "time" else [])
		pill.tooltip_text = c.text
		if not why.is_empty():
			pill.tooltip_text = "%s: %s" % [c.text, " + ".join(why.map(func(t): return "%s %d" % [t.label, t.value]))]
		row.add_child(pill)
	return row


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
	if _xp != null:
		_xp.text = "+0"


func reveal_verdict(duration: float) -> void:
	if _verdict == null:
		return
	_verdict.modulate.a = 1.0
	if UI.reduced_motion:
		return
	_verdict.pivot_offset = _verdict.size / 2.0
	_verdict.scale = Vector2(1.3, 1.3)
	create_tween().tween_property(_verdict, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## The XP the Encounter brings counts up in its pill beside the verdict, the pill
## lighting up as it fills; nothing flies to it.
func count_xp(duration: float) -> void:
	if _xp == null:
		return
	_count(_xp, 0, _xp.get_meta("value"), duration, "+%d")
	_stir(_xp.get_parent().get_parent().get_parent(), duration)


## The pill of the cost `id` lights up as that cost is paid (the damage taken, the Time
## Penalty's cards leaving the Deck, the Poison laid on it).
func pulse_cost(id: String, duration: float) -> void:
	var pill: Control = _cost_pills.get(id)
	if pill != null and pill.is_inside_tree():
		_stir(pill, duration)


## A brightening and settle, in place: the panel clips what it holds, so a pill
## never grows past its own room.
func _stir(c: Control, duration: float) -> void:
	var up := minf(duration * 0.3, 0.2)
	var tw := c.create_tween()
	tw.tween_property(c, "modulate", Color(1.7, 1.7, 1.7), up).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate", Color.WHITE, maxf(duration - up, 0.3)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


## Put everything in its final state at once.
func settle() -> void:
	for id in _totals:
		var l: Label = _totals[id]
		l.text = str(l.get_meta("value"))
	if _verdict != null:
		_verdict.modulate.a = 1.0
		_verdict.scale = Vector2.ONE
	if _xp != null:
		_xp.text = "+%d" % _xp.get_meta("value")


func _final() -> bool:
	return _kind.begins_with("final")


func _row_h() -> float:
	return ROW_H_FINAL if _final() else ROW_H


func _count(l: Label, from: int, to: int, duration: float, fmt := "%d") -> void:
	if UI.reduced_motion or not l.is_inside_tree():
		l.text = fmt % to
		return
	var show := func(v: float) -> void:
		if is_instance_valid(l):
			l.text = fmt % roundi(v)
	show.call(from)
	# Bound to the label, so the count stops if the box is redrawn under it.
	l.create_tween().tween_method(show, float(from), float(to), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _term(t: Dictionary, first: bool) -> Control:
	var v: int = t.value
	var text := str(v) if first and v >= 0 else (("+%d" % v) if v >= 0 else MINUS + str(-v))
	var colour := T.INK
	if v < 0:
		colour = T.BAD
	elif t.note.begins_with("enhanced") or t.source == "reserve":
		colour = T.GOLD
	var c := _cell(text, t.label, colour, TERM if _tight < 3 else [TERM[0], T.TEXT_MIN])
	c.tooltip_text = t.label + (": " + t.note if t.note != "" else "")
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	return c


## A number over a small label (and an icon beside the number when given).
func _cell(text: String, caption: String, colour: Color, type: Array, icon := "") -> VBoxContainer:
	var c := UI.vbox(0)
	# With captions on two lines the cells differ in height: the numbers keep one
	# line along their tops.
	c.alignment = BoxContainer.ALIGNMENT_BEGIN if _tight >= 2 else BoxContainer.ALIGNMENT_CENTER
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
	var cap := UI.label(caption.replace(" ", "\n") if _tight >= 2 else caption, T.LABEL, T.INK_MUTED)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(cap)
	return c


func _sign(text: String) -> Control:
	var l := UI.label(text, T.NUMERAL_S, T.INK_MUTED)
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	# Along the numbers' tops, though a cell beside it is taller (two-line captions).
	l.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	l.custom_minimum_size = Vector2(14 if _tight < 1 else 10, _row_h())
	return l


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


## The step and what to do next, when there is a step: a Fuse, Divert or Regroup,
## the Soak, the Upgrade, or the Deck being prepared. While a set is built there is
## nothing to say (specs/013 FR-006); a set the engine refuses says why when Play
## is pressed, on the Deck in the card's place.
func _prompt(_vs: Dictionary, _p, prompt: Dictionary) -> void:
	if prompt.step != "":
		_box.add_child(UI.label(prompt.step.to_upper(), T.EYEBROW, T.GOLD))
	# How many of the step there are left to take ("2 Diverts left").
	if prompt.get("count", "") != "":
		_box.add_child(UI.label(prompt.count, T.LABEL_BOLD, T.INK_MUTED))
	if prompt.text != "":
		_box.add_child(UI.label(prompt.text, T.BODY, T.INK, true))


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
	row.add_child(UI.icon_rect(icon_name, T.NOTE_ICON, colour))
	var l := UI.label(text, T.NUMERAL_S if text.is_valid_int() or text.begins_with("+") else T.LABEL_BOLD, T.INK)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	b.set_meta("label", l)
	if element != "":
		row.add_child(UI.icon_rect(element, T.NOTE_ICON, T.ether_ink(element)))
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
