extends Control
## Records: the games played on this device. The Leaderboard ranks the wins on one
## difficulty, all dragons together or one at a time; the History lists every
## attempt with a summary of how each dragon has gone. Nothing here reads the
## engine: only the stored records.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Game = preload("res://engine/game.gd")
const PlayHistory = preload("res://ui/model/play_history.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")

signal intent(data: Dictionary)

const RAIL_W := 270
const ROW_H := 40

var db
var _tab := "leaderboard"
var _difficulty := "normal"
var _dragon := ""
var _page := 0
## Every control a test may press, by name: "tab:history", "difficulty:hard",
## "dragon:helsang", "dragon:" (all), "back", "clear", "prev", "next".
var _tiles := {}
var _layout := Control.new()
var _content := Rect2(16, 16, 1248, 688)


func setup(card_db, difficulty: String) -> void:
	db = card_db
	_difficulty = difficulty if Game.DIFFICULTY.has(difficulty) else "normal"
	_build()


func apply_layout(content: Rect2) -> void:
	_content = content
	_layout.position = content.position
	_layout.size = content.size


## Back to the screen Records was opened from.
func back() -> void:
	intent.emit({"type": "records_back"})


## Build again from the stored records, as after clearing them.
func refresh() -> void:
	_page = 0
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tiles = {}
	_layout = Control.new()
	add_child(_layout)
	apply_layout(_content)
	var root := UI.hbox(T.L)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(root)
	root.add_child(_rail())
	var right := UI.vbox(T.M)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_header())
	if _tab == "leaderboard":
		_leaderboard(right)
	else:
		_history(right)
	root.add_child(right)


# ---------------------------------------------------------------- frame

## The difficulties, down the left; "Other" too on the History, when there are
## records from a difficulty this version no longer has.
func _rail() -> Control:
	var rail := UI.vbox(T.S)
	rail.custom_minimum_size.x = RAIL_W
	var keys: Array = Game.DIFFICULTY.keys()
	if _tab == "history" and _has_other():
		keys.append("other")
	for key in keys:
		var tile: Button = ChoiceTile.make(PlayHistory.difficulty_name(key) if key != "other" else "Other", "")
		tile.size_flags_vertical = Control.SIZE_FILL
		tile.selected = key == _difficulty
		tile.pressed.connect(func():
			_difficulty = key
			_page = 0
			_build())
		rail.add_child(tile)
		_tiles["difficulty:" + key] = tile
	return rail


func _header() -> Control:
	var row := UI.hbox(T.S)
	row.custom_minimum_size.y = T.TAP_MIN
	var back_button := UI.button("Back", "quiet")
	back_button.custom_minimum_size.x = 150
	back_button.pressed.connect(back)
	row.add_child(back_button)
	_tiles["back"] = back_button
	for entry in [["leaderboard", "Leaderboard"], ["history", "History"]]:
		var tile: Button = ChoiceTile.make(entry[1], "")
		tile.size_flags_horizontal = Control.SIZE_FILL
		tile.custom_minimum_size.x = 210
		tile.selected = _tab == entry[0]
		tile.pressed.connect(_show_tab.bind(entry[0]))
		row.add_child(tile)
		_tiles["tab:" + entry[0]] = tile
	row.add_child(UI.spacer())
	var clear := UI.button("Clear records", "quiet", "close")
	clear.custom_minimum_size.x = 240
	clear.disabled = HistoryStore.records.is_empty()
	clear.pressed.connect(func(): intent.emit({"type": "records_clear"}))
	row.add_child(clear)
	_tiles["clear"] = clear
	return row


func _show_tab(tab: String) -> void:
	_tab = tab
	_page = 0
	if tab == "leaderboard" and not Game.DIFFICULTY.has(_difficulty):
		_difficulty = "normal"
	_build()


func _has_other() -> bool:
	return HistoryStore.records.any(func(r): return not Game.DIFFICULTY.has(r.difficulty))


# ---------------------------------------------------------------- leaderboard

func _leaderboard(col: VBoxContainer) -> void:
	var filter := UI.hbox(T.S)
	filter.custom_minimum_size.y = T.TAP_MIN
	for id in [""] + db.dragon_ids():
		var tile: Button = ChoiceTile.make("All dragons" if id == "" else db.dragon(id).name, "",
			"", T.GOLD if id == "" else T.ether(db.dragon(id).early_damage.element).lightened(0.3))
		tile.selected = id == _dragon
		tile.pressed.connect(func():
			_dragon = id
			_build())
		filter.add_child(tile)
		_tiles["dragon:" + id] = tile
	col.add_child(filter)
	var entries := PlayHistory.board(HistoryStore.records, _difficulty, _dragon)
	if entries.is_empty():
		col.add_child(_empty_board())
		return
	var table := UI.vbox(2)
	table.add_child(_board_row(["", "Score", "Dragon", "Rules", "Time", "Date"], T.LABEL, T.INK_MUTED))
	for e in entries:
		var r: Dictionary = e.record
		var colour: Color = T.GOLD if e.rank == 1 else T.INK
		var row := _board_row([PlayHistory.rank_text(e.rank), str(r.score), r.get("dragon_name", r.dragon),
			PlayHistory.rules_text(r), PlayHistory.duration_text(r.active_ms), PlayHistory.date_text(r.ended_at)], T.BODY, colour)
		if e.rank == 1:
			row.get_child(0).add_child(UI.icon_rect("crown", 26, T.GOLD))
		table.add_child(row)
	col.add_child(table)


## One line of the board: rank, score, dragon, rules, time, date.
func _board_row(cells: Array, type: Array, colour: Color) -> Control:
	var row := UI.hbox(T.M)
	row.custom_minimum_size.y = ROW_H
	var widths := [96, 80, 170, 0, 110, 180]
	for i in cells.size():
		var cell := UI.hbox(6)
		cell.custom_minimum_size.x = widths[i]
		if widths[i] == 0:
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := UI.label(cells[i], ["display_bold", type[1]] if i == 1 and type == T.BODY else type, colour if i < 3 else (T.INK_MUTED if type == T.BODY else colour))
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.clip_text = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_child(l)
		row.add_child(cell)
	return row


func _empty_board() -> Control:
	var col := UI.vbox(T.S)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var name := PlayHistory.difficulty_name(_difficulty)
	var head := ("No game won on %s yet." % name) if _dragon == "" else ("%s has not been beaten on %s yet." % [db.dragon(_dragon).name, name])
	col.add_child(UI.icon_rect("trophy", 72, Color(T.INK_MUTED, 0.6)))
	var l := UI.label(head, T.HEADING, T.INK, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	var n := PlayHistory.attempts(HistoryStore.records, _difficulty, _dragon)
	var sub := UI.label(_attempts_text(n), T.BODY, T.INK_MUTED, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	return col


func _attempts_text(n: int) -> String:
	if n == 0:
		return "No attempts yet."
	return "1 attempt so far." if n == 1 else "%d attempts so far." % n


# ---------------------------------------------------------------- history

const SUMMARY_W := 400
const OUTCOME_COLOUR := {"won": T.GOLD, "lost": T.BAD, "abandoned": T.INK_MUTED}


## The difficulty's games, newest first and a page at a time, beside how it has
## gone, dragon by dragon.
func _history(col: VBoxContainer) -> void:
	var body := UI.hbox(T.L)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var p := PlayHistory.page(HistoryStore.records, _difficulty, _page)
	_page = p.index
	var list := UI.vbox(T.S)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if p.records.is_empty():
		var none := UI.label("No games played on %s yet." % _difficulty_label(), T.HEADING, T.INK_MUTED, true)
		none.size_flags_vertical = Control.SIZE_EXPAND_FILL
		none.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		list.add_child(none)
	else:
		for r in p.records:
			list.add_child(_history_row(r))
		list.add_child(UI.spacer())
		list.add_child(_pager(p))
	body.add_child(list)
	body.add_child(_summary())
	col.add_child(body)


## Two lines: how it ended, where and the score; then the dragon, rules, time and date.
func _history_row(r: Dictionary) -> Control:
	var row := UI.vbox(0)
	var top := UI.hbox(T.M)
	var outcome := UI.label(PlayHistory.outcome_name(r.outcome), ["body_bold", T.BODY[1]], OUTCOME_COLOUR.get(r.outcome, T.INK))
	outcome.custom_minimum_size.x = 150
	top.add_child(outcome)
	var stage := UI.label(PlayHistory.stage_name(r.stage), T.BODY, T.INK)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stage)
	top.add_child(UI.label(str(r.score) if r.outcome == "won" else "—", ["display_bold", T.BODY[1]], T.GOLD if r.outcome == "won" else T.INK_MUTED))
	row.add_child(top)
	var bits := [r.get("dragon_name", r.dragon)]
	if PlayHistory.rules_text(r) != "—":
		bits.append(PlayHistory.rules_text(r))
	bits.append_array([PlayHistory.duration_text(r.active_ms), PlayHistory.date_text(r.ended_at)])
	var sub := UI.label("  ·  ".join(bits), T.LABEL, T.INK_MUTED)
	sub.clip_text = true
	row.add_child(sub)
	return row


func _pager(p: Dictionary) -> Control:
	var row := UI.hbox(T.S)
	row.custom_minimum_size.y = T.TAP_MIN
	var prev := UI.button("‹ Newer", "quiet")
	prev.custom_minimum_size.x = 170
	prev.disabled = p.index == 0
	prev.pressed.connect(func():
		_page -= 1
		_build())
	row.add_child(prev)
	_tiles["prev"] = prev
	var at := UI.label("Page %d of %d" % [p.index + 1, p.pages], T.LABEL, T.INK_MUTED)
	at.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	at.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	at.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(at)
	var next := UI.button("Older ›", "quiet")
	next.custom_minimum_size.x = 170
	next.disabled = p.index >= p.pages - 1
	next.pressed.connect(func():
		_page += 1
		_build())
	row.add_child(next)
	_tiles["next"] = next
	return row


## The difficulty as a whole, then each dragon: played, won, rate, best and average.
func _summary() -> Control:
	var s := PlayHistory.summary(HistoryStore.records, _difficulty, db.dragon_ids())
	var panel := UI.panel(T.BG_SURFACE, T.LINE_SOFT, 1, T.RADIUS_M, T.M)
	panel.custom_minimum_size.x = SUMMARY_W
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var col := UI.vbox(T.XS)
	col.add_child(UI.label(_difficulty_label().to_upper(), ["display", 24], T.GOLD))
	col.add_child(UI.label(_tally_text(s), ["body_bold", T.BODY[1]], T.INK))
	col.add_child(UI.label("%s played" % PlayHistory.duration_text(s.active_ms), T.LABEL, T.INK_MUTED))
	for d in s.dragons:
		var gap := Control.new()
		gap.custom_minimum_size.y = T.S
		col.add_child(gap)
		var known: bool = db.dragon_ids().has(d.dragon)
		var name: String = db.dragon(d.dragon).name if known else d.dragon_name
		var colour: Color = T.ether(db.dragon(d.dragon).early_damage.element).lightened(0.35) if known else T.INK
		if d.attempts == 0:
			# One line for a dragon not yet hunted here, so a long list still fits.
			var line := UI.hbox(T.S)
			line.add_child(UI.label(name, ["body_bold", T.BODY[1]], Color(colour, 0.7)))
			line.add_child(UI.label("not played yet", T.LABEL, T.INK_MUTED))
			col.add_child(line)
			continue
		col.add_child(UI.label(name, ["body_bold", T.BODY[1]], colour))
		col.add_child(UI.label(_tally_text(d), T.LABEL, T.INK))
		col.add_child(UI.label("Best %d  ·  average %.1f" % [d.best, d.average] if d.best >= 0 else "Not beaten yet", T.LABEL, T.INK_MUTED))
	panel.add_child(col)
	return panel


func _tally_text(t: Dictionary) -> String:
	if t.attempts == 0:
		return "Not played yet"
	return "%d played  ·  %d won  ·  %d%%" % [t.attempts, t.wins, roundi(t.win_rate * 100.0)]


func _difficulty_label() -> String:
	return "Other" if _difficulty == "other" else PlayHistory.difficulty_name(_difficulty)
