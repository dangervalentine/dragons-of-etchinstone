extends Control
## The end of a game: the dragon defeated and the score, or where and why the hunt
## failed. Play again with the same options, or go back to change them.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Creature = preload("res://ui/fx/creature.gd")
const Art = preload("res://ui/model/art.gd")

signal intent(data: Dictionary)

var heading := ""
var _layout := Control.new()
var _content := Rect2(16, 16, 1248, 688)
var _score: Label
var _target := 0


func apply_layout(content: Rect2) -> void:
	_content = content
	_layout.position = content.position
	_layout.size = content.size


func render(vs: Dictionary) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_layout = Control.new()
	add_child(_layout)
	apply_layout(_content)
	var e: Dictionary = vs.ending
	var colour: Color = T.GOLD if e.won else T.BAD
	heading = "Victory" if e.won else "Defeat"
	var root := UI.hbox(T.XL)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(root)

	var left := UI.vbox(T.M)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size.x = 560
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	var sigil := Creature.new()
	sigil.custom_minimum_size = Vector2(220, 220)
	sigil.setup(vs.stage.art, colour if e.won else Color(T.INK_MUTED, 0.6), vs.stage.element if e.won else "")
	sigil.crop = Art.head(vs.stage.art, UI.is_painted(vs.stage.art))
	sigil.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(sigil)
	var head := ("%s is defeated" % e.dragon) if e.won else "You have perished"
	# The verdict, inscribed in a slab of stone (feature 006).
	var slab := UI.slab(colour, 16)
	var verdict := UI.carved_label(head.to_upper(), T.BANNER, colour)
	verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slab.add_child(verdict)
	left.add_child(slab)
	if e.won:
		left.add_child(UI.label("The hunt is over. Your cards carry the marks of every Region.", T.BODY, T.INK, true))
	else:
		left.add_child(UI.label("Lost on %s." % e.where if e.where != "" else "The hunt has failed.", ["body_bold", T.BODY[1]], T.INK, true))
		left.add_child(UI.label(e.why, T.BODY, T.INK_MUTED, true))
	root.add_child(left)

	var right := UI.vbox(T.M)
	right.custom_minimum_size.x = 440
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	var score_row := UI.hbox(T.M)
	score_row.add_child(UI.icon_rect("crown", 72, T.GOLD))
	_score = UI.label("0", T.TITLE, T.GOLD)
	score_row.add_child(_score)
	var cap := UI.label("SCORE", T.HEADING, T.INK_MUTED)
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_row.add_child(cap)
	right.add_child(score_row)
	if e.won:
		var table := UI.slab(T.LINE_SOFT, 14)
		var rows := UI.vbox(6)
		for r in e.rows:
			var line := UI.hbox(T.S)
			line.add_child(UI.label("%d %s at Level %d" % [r.count, "card" if r.count == 1 else "cards", r.level], T.BODY, T.INK))
			line.add_child(UI.spacer())
			line.add_child(UI.label("%d" % r.points, T.NUMERAL, T.GOLD))
			rows.add_child(line)
		if e.trashed > 0:
			rows.add_child(UI.label("%d %s Trashed, scoring nothing" % [e.trashed, "card" if e.trashed == 1 else "cards"], T.LABEL, T.INK_MUTED))
		table.add_child(rows)
		right.add_child(table)
	else:
		right.add_child(UI.label("A lost hunt scores nothing.", T.BODY, T.INK_MUTED))
	# Where the win placed on the leaderboard, then the way to it.
	for i in e.get("placing", []).size():
		var line := UI.hbox(T.S)
		var mark := UI.icon_rect("crown", 32, T.GOLD)
		if i > 0:
			mark.modulate.a = 0.0
		line.add_child(mark)
		line.add_child(UI.label(e.placing[i], ["body_bold", T.BODY[1]], T.GOLD))
		right.add_child(line)
	var board := UI.button("Leaderboard", "quiet", "trophy")
	board.pressed.connect(func(): intent.emit({"type": "records", "page": "leaderboard", "from": "ending"}))
	right.add_child(board)
	right.add_child(UI.spacer())
	var buttons := UI.hbox(T.S)
	var change := UI.button("Change options", "quiet")
	change.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	change.pressed.connect(func(): intent.emit({"type": "to_title"}))
	buttons.add_child(change)
	var again := UI.button("Play again", "primary")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func(): intent.emit({"type": "play_again"}))
	buttons.add_child(again)
	right.add_child(buttons)
	root.add_child(right)
	if e.won and not UI.reduced_motion:
		var burst := CPUParticles2D.new()
		burst.amount = 90
		burst.lifetime = 1.6
		burst.one_shot = true
		burst.explosiveness = 0.9
		burst.direction = Vector2(0, -1)
		burst.spread = 70.0
		burst.initial_velocity_min = 260.0
		burst.initial_velocity_max = 520.0
		burst.gravity = Vector2(0, 520)
		burst.scale_amount_min = 3.0
		burst.scale_amount_max = 7.0
		burst.color = T.GOLD
		burst.position = _content.position + Vector2(140, 200)
		add_child(burst)
		burst.emitting = true
	_target = e.score
	if UI.reduced_motion or _target == 0:
		_score.text = str(_target)
	else:
		create_tween().tween_method(func(v: float): _score.text = str(int(v)), 0.0, float(_target), 1.0).set_ease(Tween.EASE_OUT)
	again.grab_focus.call_deferred(true)
