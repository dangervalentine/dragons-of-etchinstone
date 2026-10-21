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
	_score = null
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
	left.alignment = BoxContainer.ALIGNMENT_BEGIN
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
	# The whole dragon, and beside its top where the win placed on the leaderboard.
	# The dragon is drawn larger than the room left, running off the foot of the screen.
	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UI.hbox(T.L)
	stage.add_child(row)
	# The box round all the dragon draws holds the place in the row, so the lines beside
	# it start at its top; the art is whole and unclipped around it, so a tail swaying
	# past the box is still drawn.
	# A painted dragon's full-body picture where there is one; its plain picture is
	# cut to the Dragon Card.
	var body: String = vs.stage.art + "-full" if UI.is_painted(vs.stage.art + "-full") else vs.stage.art
	var drawn := _drawn(body)
	var place := Control.new()
	place.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(place)
	var sigil := Creature.new()
	sigil.setup(body, colour if e.won else Color(T.INK_MUTED, 0.6), vs.stage.element if e.won else "")
	place.add_child(sigil)
	var placings := UI.vbox(T.S)
	placings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placings.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	for i in e.get("placing", []).size():
		var line := UI.hbox(T.S)
		var mark := UI.icon_rect("crown", 32, T.GOLD)
		mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		line.add_child(mark)
		var said := UI.label(e.placing[i], ["body_bold", T.BODY[1]], T.GOLD, true)
		said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(said)
		placings.add_child(line)
	row.add_child(placings)
	stage.resized.connect(func():
		var aspect := drawn.size.x / drawn.size.y
		var tall := clampf(stage.size.y * 1.2, 220.0, 600.0)
		tall = minf(tall, (stage.size.x - 360.0) / aspect)
		var k := tall / drawn.size.y
		place.custom_minimum_size = drawn.size * k
		sigil.position = -drawn.position * k
		sigil.size = Vector2(512, 512) * k
		row.size = Vector2(stage.size.x, tall))
	left.add_child(stage)
	root.add_child(left)

	# What the cards scored, the way to the leaderboard, and what next.
	var right := UI.vbox(T.M)
	right.custom_minimum_size.x = 440
	right.alignment = BoxContainer.ALIGNMENT_CENTER
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
		# The score, the sum of the rows above it.
		var rule := ColorRect.new()
		rule.color = T.LINE_SOFT
		rule.custom_minimum_size.y = 2
		rows.add_child(rule)
		var total := UI.hbox(T.S)
		var crown := UI.icon_rect("crown", 40, T.GOLD)
		crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		total.add_child(crown)
		var cap := UI.label("SCORE", T.HEADING, T.INK_MUTED)
		cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		total.add_child(cap)
		total.add_child(UI.spacer())
		_score = UI.label("0", T.NUMERAL_L, T.GOLD)
		total.add_child(_score)
		rows.add_child(total)
		table.add_child(rows)
		right.add_child(table)
	else:
		right.add_child(UI.label("A lost hunt scores nothing.", T.BODY, T.INK_MUTED))
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
		burst.position = _content.position + Vector2(200, 380)
		add_child(burst)
		burst.emitting = true
	_target = e.score
	if _score == null:
		pass  # A lost hunt has no score to count up.
	elif UI.reduced_motion or _target == 0:
		_score.text = str(_target)
	else:
		create_tween().tween_method(func(v: float): _score.text = str(int(v)), 0.0, float(_target), 1.0).set_ease(Tween.EASE_OUT)
	again.grab_focus.call_deferred(true)


## The box round all a dragon's art draws, in its 512 units: measured from a painted
## picture, whose dragons don't each fill the box they share (Art.PAINTED_BODY).
static func _drawn(art: String) -> Rect2:
	if not UI.is_painted(art):
		return Art.body(art)
	var image := UI.art(art).get_image()
	if image.is_compressed():
		image.decompress()
	var used := Rect2(image.get_used_rect())
	var unit := 512.0 / image.get_width()
	return Rect2(used.position * unit, used.size * unit)
