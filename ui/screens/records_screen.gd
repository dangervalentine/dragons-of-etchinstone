extends Control
## The games played on this device, as one of two pages: the Leaderboard ranks the
## wins on one difficulty, all dragons together or one at a time; the History lists
## every attempt with a summary of how each dragon has gone. Nothing here reads the
## engine: only the stored records. Clearing them is in the menu.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Ledger = preload("res://ui/widgets/ledger.gd")
const TabRow = preload("res://ui/widgets/tab_row.gd")
const Game = preload("res://engine/game.gd")
const PlayHistory = preload("res://ui/model/play_history.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")

signal intent(data: Dictionary)

const RAIL_W := 270

var heading := "Leaderboard"
var db
## "leaderboard" or "history".
var _tab := "leaderboard"
var _difficulty := "normal"
var _dragon := ""
var _page := 0
## Every control a test may press, by name: "difficulty:hard", "dragon:helsang",
## "dragon:" (all), "prev", "next". Back is in the title bar.
var _tiles := {}
var _layout := Control.new()
var _content := Rect2(16, 16, 1248, 688)


func setup(card_db, difficulty: String, page := "leaderboard") -> void:
	db = card_db
	_tab = page if page == "history" else "leaderboard"
	heading = "History" if _tab == "history" else "Leaderboard"
	_difficulty = difficulty if Game.DIFFICULTY.has(difficulty) else "normal"
	_build()


func apply_layout(content: Rect2) -> void:
	# How many games a page shows depends on the height (_history), so a new height
	# builds the page again.
	var taller := not is_equal_approx(content.size.y, _content.size.y)
	_content = content
	_layout.position = content.position
	_layout.size = content.size
	if taller and _layout.get_child_count() > 0:
		_build()


## Back to the screen this page was opened from.
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
	var root := UI.hbox(T.SPACE_4)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(root)
	root.add_child(_rail())
	var right := UI.vbox(T.SPACE_1)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _tab == "leaderboard":
		right.add_child(_dragon_filter())
		_leaderboard(right)
	else:
		# On the History, the records from a difficulty this version no longer has:
		# here rather than a seventh tile in the rail, which would not fit under the
		# title bar.
		if _has_other():
			right.add_child(_other_row())
		_history(right)
	root.add_child(right)


# ---------------------------------------------------------------- frame

## The difficulties, down the left: a filter, so a rail of tabs (specs/019 Tabs).
func _rail() -> Control:
	var rail := TabRow.new()
	rail.vertical = true
	rail.custom_minimum_size.x = RAIL_W
	rail.setup(Game.DIFFICULTY.keys().map(func(k): return {"id": k, "text": PlayHistory.difficulty_name(k)}), _difficulty)
	rail.chosen.connect(_choose_difficulty)
	for key in Game.DIFFICULTY.keys():
		_tiles["difficulty:" + key] = rail.tab(key)
	return rail


func _choose_difficulty(key) -> void:
	_difficulty = key
	_page = 0
	_build()


## The records of difficulties this version no longer has, as one more tab.
func _other_row() -> Control:
	var row := TabRow.new()
	row.setup([{"id": "other", "text": "Other"}], _difficulty)
	row.chosen.connect(_choose_difficulty)
	_tiles["difficulty:other"] = row.tab("other")
	return row


func _has_other() -> bool:
	return HistoryStore.records.any(func(r): return not Game.DIFFICULTY.has(r.difficulty))


# ---------------------------------------------------------------- leaderboard

## All dragons, then each one: a filter, so a row of tabs (specs/019 Tabs).
func _dragon_filter() -> Control:
	var filter := TabRow.new()
	var ids: Array = [""] + db.dragon_ids()
	filter.setup(ids.map(func(id): return {"id": id, "text": "All dragons" if id == "" else db.dragon(id).name}), _dragon)
	filter.chosen.connect(func(id):
		_dragon = id
		_build())
	for id in ids:
		_tiles["dragon:" + id] = filter.tab(id)
	return filter


func _leaderboard(col: VBoxContainer) -> void:
	var entries := PlayHistory.board(HistoryStore.records, _difficulty, _dragon)
	if entries.is_empty():
		col.add_child(_empty_board())
		return
	# A ledger (specs/019 Ledger): muted heads, hairlines, scores in figures, and the
	# best run alone in bright brass, with its crown.
	var rows := []
	for e in entries:
		var r: Dictionary = e.record
		var place = PlayHistory.rank_text(e.rank)
		if e.rank == 1:
			var first := UI.hbox(T.SPACE_1)
			first.add_child(UI.label(place, T.BODY_SM, T.BRASS_BRIGHT))
			first.add_child(UI.icon_rect("crown", 26, T.BRASS_BRIGHT))
			place = first
		rows.append({"cells": [place, str(r.score), r.get("dragon_name", r.dragon), PlayHistory.rules_text(r),
			PlayHistory.duration_text(r.active_ms), PlayHistory.date_text(r.ended_at)], "best": e.rank == 1})
	var table := Ledger.new()
	table.setup([
		{"head": "", "width": 96, "muted": true}, {"head": "Score", "width": 80, "numeral": true, "align": "right"},
		{"head": "Dragon", "width": 170}, {"head": "Rules", "width": 0, "muted": true},
		{"head": "Time", "width": 110, "muted": true}, {"head": "Date", "width": 180, "muted": true}], rows)
	col.add_child(table)


func _empty_board() -> Control:
	var col := UI.vbox(T.SPACE_1)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var name := PlayHistory.difficulty_name(_difficulty)
	var head := ("No game won on %s yet." % name) if _dragon == "" else ("%s has not been beaten on %s yet." % [db.dragon(_dragon).name, name])
	col.add_child(UI.icon_rect("trophy", 72, Color(T.PARCHMENT_MUTED, 0.6)))
	var l := UI.label(head, T.HEADING, T.PARCHMENT, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(l)
	var n := PlayHistory.attempts(HistoryStore.records, _difficulty, _dragon)
	var sub := UI.label(_attempts_text(n), T.BODY, T.PARCHMENT_MUTED, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	return col


func _attempts_text(n: int) -> String:
	if n == 0:
		return "No attempts yet."
	return "1 attempt so far." if n == 1 else "%d attempts so far." % n


# ---------------------------------------------------------------- history

const SUMMARY_W := 400
const OUTCOME_COLOUR := {"won": T.JADE, "lost": T.DANGER, "abandoned": T.PARCHMENT_MUTED}


## The difficulty's games, newest first and a page at a time, beside how it has
## gone, dragon by dragon.
func _history(col: VBoxContainer) -> void:
	var body := UI.hbox(T.SPACE_4)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# As many games a page as the screen holds under what is above the list, with the
	# pager, up to PlayHistory.PAGE_SIZE: the shortest phones take fewer at the design
	# system's type sizes (specs/019).
	var room: float = _content.size.y - col.get_combined_minimum_size().y - col.get_theme_constant("separation")
	var p := {}
	var list: VBoxContainer
	for per in range(PlayHistory.PAGE_SIZE, 2, -1):
		if list != null:
			list.free()
		p = PlayHistory.page(HistoryStore.records, _difficulty, _page, per)
		list = _history_list(p)
		if list.get_combined_minimum_size().y <= room or per == 3:
			break
	_page = p.index
	body.add_child(list)
	body.add_child(_summary())
	col.add_child(body)


func _history_list(p: Dictionary) -> VBoxContainer:
	var list := UI.vbox(T.SPACE_1)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if p.records.is_empty():
		var none := UI.label("No games played on %s yet." % _difficulty_label(), T.HEADING, T.PARCHMENT_MUTED, true)
		none.size_flags_vertical = Control.SIZE_EXPAND_FILL
		none.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		list.add_child(none)
	else:
		for r in p.records:
			list.add_child(_history_row(r))
		list.add_child(UI.spacer())
		list.add_child(_pager(p))
	return list


## Two lines: how it ended, where and the score; then the dragon, rules, time and date.
## A ledger's rows are body-sm, its fine print caption (specs/019 Ledger).
func _history_row(r: Dictionary) -> Control:
	var row := UI.vbox(0)
	var top := UI.hbox(T.SPACE_2)
	var outcome := UI.label(PlayHistory.outcome_name(r.outcome), UI.restyle(T.BODY_STRONG, T.BODY_SM.size), OUTCOME_COLOUR.get(r.outcome, T.PARCHMENT))
	outcome.custom_minimum_size.x = 150
	top.add_child(outcome)
	var stage := UI.label(PlayHistory.stage_name(r.stage), T.BODY_SM, T.PARCHMENT)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stage)
	top.add_child(UI.label(str(r.score) if r.outcome == "won" else "—", T.NUMERAL_SM, T.BRASS_BRIGHT if r.outcome == "won" else T.PARCHMENT_MUTED))
	row.add_child(top)
	var bits := [r.get("dragon_name", r.dragon)]
	if PlayHistory.rules_text(r) != "—":
		bits.append(PlayHistory.rules_text(r))
	bits.append_array([PlayHistory.duration_text(r.active_ms), PlayHistory.date_text(r.ended_at)])
	var sub := UI.label("  ·  ".join(bits), T.CAPTION, T.PARCHMENT_MUTED)
	sub.clip_text = true
	row.add_child(sub)
	return row


func _pager(p: Dictionary) -> Control:
	var row := UI.hbox(T.SPACE_1)
	row.custom_minimum_size.y = T.TAP_MIN
	var prev := UI.button("‹ Newer", "quiet")
	prev.custom_minimum_size.x = 170
	prev.disabled = p.index == 0
	prev.pressed.connect(func():
		_page -= 1
		_build())
	row.add_child(prev)
	_tiles["prev"] = prev
	var at := UI.label("Page %d of %d" % [p.index + 1, p.pages], T.CAPTION, T.PARCHMENT_MUTED)
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


## The difficulty as a whole, then each dragon: played, won, rate, best and average,
## in the ledger's sizes (specs/019 Ledger).
func _summary() -> Control:
	var s := PlayHistory.summary(HistoryStore.records, _difficulty, db.dragon_ids())
	var panel := UI.slab(Color(T.SHADE, 0), T.SPACE_2)
	panel.custom_minimum_size.x = SUMMARY_W
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var col := UI.vbox(T.SPACE_1)
	col.add_child(UI.label(_difficulty_label(), T.LABEL, T.PARCHMENT_MUTED))
	col.add_child(UI.label(_tally_text(s), UI.restyle(T.BODY_STRONG, T.BODY_SM.size), T.PARCHMENT))
	col.add_child(UI.label("%s played" % PlayHistory.duration_text(s.active_ms), T.CAPTION, T.PARCHMENT_MUTED))
	for d in s.dragons:
		var gap := Control.new()
		gap.custom_minimum_size.y = T.SPACE_1
		col.add_child(gap)
		var known: bool = db.dragon_ids().has(d.dragon)
		var name: String = db.dragon(d.dragon).name if known else d.dragon_name
		var colour: Color = T.ether_ink(db.dragon(d.dragon).early_damage.element) if known else T.PARCHMENT
		if d.attempts == 0:
			# One line for a dragon not yet hunted here, so a long list still fits.
			var line := UI.hbox(T.SPACE_1)
			line.add_child(UI.label(name, UI.restyle(T.BODY_STRONG, T.BODY_SM.size), Color(colour, 0.7)))
			line.add_child(UI.label("not played yet", T.CAPTION, T.PARCHMENT_MUTED))
			col.add_child(line)
			continue
		# The name and its tally on one line, so every dragon fits the shortest phone.
		var head := UI.hbox(T.SPACE_2)
		head.add_child(UI.label(name, UI.restyle(T.BODY_STRONG, T.BODY_SM.size), colour))
		var tally := UI.label(_tally_text(d), T.CAPTION, T.PARCHMENT)
		tally.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		head.add_child(tally)
		col.add_child(head)
		col.add_child(UI.label("Best %d  ·  average %.1f" % [d.best, d.average] if d.best >= 0 else "Not beaten yet", T.CAPTION, T.PARCHMENT_MUTED))
	panel.add_child(col)
	return panel


func _tally_text(t: Dictionary) -> String:
	if t.attempts == 0:
		return "Not played yet"
	return "%d played  ·  %d won  ·  %d%%" % [t.attempts, t.wins, roundi(t.win_rate * 100.0)]


func _difficulty_label() -> String:
	return "Other" if _difficulty == "other" else PlayHistory.difficulty_name(_difficulty)
