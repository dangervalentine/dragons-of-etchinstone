extends SceneTree
## Drives the real screens through seeded games at every window size in the layout
## matrix and checks what a player would trip over: anything outside the screen or
## under a notch, controls too small to tap, text too small to read, anything that
## scrolls, and any difference from the same game played on the engine alone.
## godot --headless --path . -s tools/ui_check.gd

const Solver = preload("res://ui/model/layout_solver.gd")
const T = preload("res://ui/theme/tokens.gd")
const Game = preload("res://engine/game.gd")
const CardDB = preload("res://engine/card_db.gd")
const CardView = preload("res://ui/widgets/card_view.gd")
const StatChip = preload("res://ui/widgets/stat_chip.gd")
const TitleScreen = preload("res://ui/screens/title_screen.gd")
const RulesScreen = preload("res://ui/screens/rules_screen.gd")
const Settings = preload("res://ui/model/settings.gd")
const RulebookOverlay = preload("res://ui/overlays/rulebook_overlay.gd")
const GlossaryPopover = preload("res://ui/overlays/glossary_popover.gd")
const Rulebook = preload("res://ui/model/rulebook.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")
const RecordsScreen = preload("res://ui/screens/records_screen.gd")

## Games played here are recorded in their own folder, never the player's records.
const HISTORY_DIR := "user://tool_history/"

const HELP_MIN := 44.0

var failures := 0
## The viewport the game runs in, sized for each window in the matrix.
var host: SubViewport
var checks := 0
var ui
var db = CardDB.new()


func _initialize() -> void:
	_clear_history()
	_run()


func _clear_history() -> void:
	HistoryStore.use_empty(HISTORY_DIR)


func _run() -> void:
	for name in Solver.MATRIX:
		await _open(name)
		await _screens_and_overlays(name)
		await _play(name, 11, "casual", false)
	await _open("phone-16x9")
	await _play("phone-16x9 animated", 5, "normal", true)
	await _open("desktop")
	await _ending_placing("desktop")
	await _open("phone-tall")
	await _ending_placing("phone-tall")
	await _open("desktop")
	await _resize_mid_turn()
	print("ui check: %d checks, %d failed (%d space checks)" % [checks, failures, space_checks])
	ui.free()
	quit(1 if failures > 0 else 0)


func _fail(what: String) -> void:
	failures += 1
	print("FAIL " + what)


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		_fail(what)


func _open(name: String) -> void:
	var m: Array = Solver.MATRIX[name]
	var view: Vector2 = Solver.view_for_window(m[0])
	# The game runs in a viewport of exactly this size, in design units, as the
	# project's stretch settings make it: a headless window keeps one
	# size whatever it is asked for, so the root cannot stand in for each screen.
	if host == null:
		host = SubViewport.new()
		host.disable_3d = true
		root.add_child(host)
	host.size = Vector2i(view)
	current_size = name
	await process_frame
	if ui != null:
		ui.free()
	ui = load("res://scenes/main.tscn").instantiate()
	var real: Vector2 = Vector2(host.size)
	var k: float = real.x / m[0].x
	var inset: Array = m[1]
	if name == "phone-tall-flipped":
		inset = [inset[2], inset[1], inset[0], inset[3]]
	if inset != [0, 0, 0, 0]:
		ui.safe_override = Rect2(inset[0] * k, inset[1] * k, real.x - (inset[0] + inset[2]) * k, real.y - (inset[1] + inset[3]) * k)
	host.add_child(ui)
	await process_frame
	await process_frame
	_ok(ui.plan.undersized == (name == "upright-browser"), "%s: undersized is %s" % [name, ui.plan.undersized])
	_ok(ui._notice != null if name == "upright-browser" else ui._notice == null, "%s: size notice" % name)
	if ui._notice != null:
		_ok(ui.plan.safe.grow(1.0).encloses(ui._notice.get_global_rect()), "%s: size notice at %s is outside the safe area" % [name, str(ui._notice.get_global_rect())])


## The minimum window sizes, where no play-screen zone may be over a third empty
## (feature 006, SC-002). Zones are the panels drawn: the Encounter, the preview,
## the role slots and the panel round the Hand.
const SPACE_SIZES := ["phone-16x9", "phone-small"]
const MAX_EMPTY := 1.0 / 3.0
var space_checks := 0
## The matrix entry the game is laid out for now.
var current_size := ""


## Run once the screen has settled and its containers have laid out.
func _check_space(where: String) -> void:
	if ui.screen == null or ui.screen != ui.play or ui.play.plan.is_empty() or ui.animator.is_playing():
		return
	var size_name := current_size
	if not SPACE_SIZES.has(size_name):
		return
	# Only when the window really has that size: a headless window may not resize.
	if ui.play.plan.view != Solver.view_for_window(Solver.MATRIX[size_name][0]):
		return
	var play = ui.play
	var zones := {"encounter": [play._regions.encounter.get_global_rect(), play.encounter_node()],
		"hand": [play._hand_panel.get_global_rect(), play.hand]}
	for panel in [play.preview, play.soak_meter, play.xp_purse]:
		if panel.visible:
			zones["preview"] = [panel.get_global_rect(), panel]
	if play._regions.slots.size.y > 0.0:
		zones["slots"] = [play._regions.slots.get_global_rect(), play._regions.slots]
	space_checks += 1
	for key in zones:
		var e: float = Solver.empty_fraction(zones[key][0], zones[key][1])
		_ok(e <= MAX_EMPTY, "%s: %s is %d%% empty" % [where, key, int(e * 100.0)])


func _settle() -> void:
	ui.animator.skip()
	await process_frame
	await process_frame
	if ui.game != null:
		_check_space("%s %s" % [current_size, ui.game.phase])


## Everything a player can press or must read, checked against the screen.
## Skipped while a sequence is moving things about.
func _inspect_screen(where: String) -> void:
	if ui.animator.is_playing():
		return
	var safe: Rect2 = ui.plan.safe.grow(1.0)
	var view := Rect2(Vector2.ZERO, Vector2(host.size)).grow(1.0)
	var nodes: Array = ui.screen.find_children("*", "Control", true, false) + ui._overlays.find_children("*", "Control", true, false)
	for node in nodes:
		var c := node as Control
		if not c.is_visible_in_tree() or c.is_queued_for_deletion() or c.modulate.a < 0.5:
			continue
		if c is ScrollContainer:
			_fail("%s: %s scrolls" % [where, c.get_path()])
		var interactive: bool = c is BaseButton or c is CardView or (c is StatChip and c.glossary_id != "")
		if interactive:
			var r := c.get_global_rect()
			var minimum: float = HELP_MIN if c.has_meta("help_target") or c is StatChip else float(T.TAP_MIN)
			_ok(minf(r.size.x, r.size.y) >= minimum - 0.5, "%s: %s is %s, under %d" % [where, _name(c), str(r.size), int(minimum)])
			if ui.plan.undersized:
				continue
			# The menu button reaches below the header on purpose; its visible part is inside.
			var r_check := Rect2(r.position, Vector2(r.size.x, minf(r.size.y, 56.0))) if c == ui.play.header.menu_button if ui.play != null else false else r
			_ok(safe.encloses(r_check), "%s: %s at %s is outside the safe area %s" % [where, _name(c), str(r), str(safe)])
		if c is Label and c.text != "" and not c.has_meta("small_ok"):
			var fs: int = c.get_theme_font_size("font_size")
			_ok(fs >= T.TEXT_MIN, "%s: text '%s' is set at %d" % [where, c.text.left(30), fs])
		if c is Label and not ui.plan.undersized and c.text != "":
			_ok(view.encloses(c.get_global_rect()), "%s: text '%s' runs off the screen" % [where, c.text.left(30)])
			_ok(safe.encloses(c.get_global_rect()), "%s: text '%s' at %s is outside the safe area %s" % [where, c.text.left(30), str(c.get_global_rect()), str(safe)])
		if c is RichTextLabel and c.text != "":
			var shown: String = c.get_parsed_text().left(30)
			var size: int = c.get_theme_font_size("normal_font_size")
			_ok(size >= T.TEXT_MIN, "%s: text '%s' is set at %d" % [where, shown, size])
			if not ui.plan.undersized:
				_ok(view.encloses(c.get_global_rect()), "%s: text '%s' runs off the screen" % [where, shown])
				_ok(safe.encloses(c.get_global_rect()), "%s: text '%s' at %s is outside the safe area %s" % [where, shown, str(c.get_global_rect()), str(safe)])


func _name(c: Control) -> String:
	if c is CardView:
		return "card " + c.id
	if c is Button:
		return "button '%s'" % c.text
	return str(c.get_path()).get_file()


## Choices both the UI run and the engine-only run make.
func _soak_ids(g) -> Array:
	var ids := []
	var total := 0
	for id in g.hand:
		if total < g.damage_due and not g.downgraded.has(id):
			ids.append(id)
			total += g._soak_value(id)
	return ids


func _play(where: String, game_seed: int, difficulty: String, animated: bool) -> void:
	var opts := {"seed": game_seed, "dragon": db.dragon_ids()[game_seed % 4], "difficulty": difficulty, "cavalier": false, "glass_cannon": false}
	var shadow = Game.new(db, opts)
	ui.start_game(opts)
	var recorded := HistoryStore.records.size()
	await _settle()
	var g = ui.game
	var guard := 0
	var first := true
	while g.phase != "won" and g.phase != "lost" and guard < 400:
		guard += 1
		if not animated:
			await _settle()
		if not animated and (first or guard % 7 == 0):
			_inspect_screen("%s %s" % [where, g.phase])
		first = false
		match g.phase:
			"setup":
				var picks: Array = g.setup_offer.slice(0, g.setup_picks)
				for id in picks:
					await _press({"type": "card", "id": id}, animated)
				await _press({"type": "primary"}, animated)
				shadow.choose_setup_cards(picks)
			"challenge":
				var hand: Array = g.hand.duplicate()
				for id in hand.slice(0, mini(3, hand.size())):
					await _press({"type": "card", "id": id}, animated)
				var a := {"spell": hand[0]}
				if hand.size() > 1:
					a["element"] = hand[1]
				if hand.size() > 2:
					a["boost"] = hand[2]
				a["boost_to"] = "attack"
				a["ranged_discard"] = false
				if not animated:
					_inspect_screen("%s challenge, placed" % where)
				await _press({"type": "primary"}, animated)
				shadow.play(a)
			"penalty", "poison", "final_soak":
				var ids := _soak_ids(g)
				for id in ids:
					await _press({"type": "card", "id": id}, animated)
				if not animated:
					_inspect_screen("%s soak" % where)
				await _press({"type": "primary"}, animated)
				shadow.soak(_soak_ids(shadow))
			"upgrade":
				if not animated:
					_inspect_screen("%s upgrade" % where)
				await _press({"type": "primary"}, animated)
				shadow.finish()
			"final_journey", "final_enemy":
				var hand: Array = g.hand.duplicate()
				for id in hand.slice(0, mini(6, hand.size())):
					await _press({"type": "card", "id": id}, animated)
				if not animated:
					_inspect_screen("%s %s, placed" % [where, g.phase])
				var sets := [{}, {}]
				var roles := ["spell", "element", "boost"]
				for i in mini(6, hand.size()):
					sets[i / 3][roles[i % 3]] = hand[i]
				for s in sets:
					s["boost_to"] = "attack"
				await _press({"type": "primary"}, animated)
				shadow.play_final({"sets": sets})
		if g.phase != shadow.phase:
			_fail("%s: the UI game is in %s but the engine-only game is in %s" % [where, g.phase, shadow.phase])
			break
	await _settle()
	await create_timer(0.4).timeout
	_ok(g.phase == "won" or g.phase == "lost", "%s: the game finished (%s)" % [where, g.phase])
	_ok(ui.screen != ui.play and ui.screen != null, "%s: the ending screen is shown" % where)
	_ok(g.hand == shadow.hand and g.deck == shadow.deck and g.discard == shadow.discard and g.trash == shadow.trash,
		"%s: same cards in the same places as the engine-only game" % where)
	var same_levels := true
	for id in g.cards:
		same_levels = same_levels and g.cards[id].level == shadow.cards[id].level
	_ok(same_levels, "%s: same Levels as the engine-only game" % where)
	_ok(HistoryStore.records.size() == recorded + 1, "%s: the game left one record (%d)" % [where, HistoryStore.records.size() - recorded])
	if HistoryStore.records.size() > recorded:
		var r: Dictionary = HistoryStore.records[-1]
		_ok(r.outcome == g.phase, "%s: recorded as %s, ended %s" % [where, r.outcome, g.phase])
		_ok(r.difficulty == difficulty and r.dragon == opts.dragon, "%s: recorded with its options" % where)
		_ok(r.score == g.score(), "%s: recorded score %d is the game's %d" % [where, r.score, g.score()])
		_ok(r.active_ms > 0, "%s: some active time was recorded" % where)
		_ok(not FileAccess.file_exists(HISTORY_DIR + "in_progress.json"), "%s: no game left in progress" % where)
	if ui.screen != null and ui.screen != ui.play:
		_inspect_screen("%s ending" % where)
		if g.phase == "lost":
			_ok(not _has_label(ui.screen, "New best") and not _has_label(ui.screen, "Best against"), "%s: a loss does not place" % where)


## The two setup screens, then each overlay over a game in progress, one at a time.
func _screens_and_overlays(where: String) -> void:
	await _settle()
	_inspect_screen("%s title" % where)
	_ok(ui.screen.get_script() == TitleScreen, "%s: launch shows the dragon screen" % where)
	_ok(not ui.screen._tiles.keys().any(func(k): return not k.begins_with("dragon:")), "%s: the dragon screen offers only dragons" % where)
	ui.dispatch({"type": "settings"})
	await _settle()
	_inspect_screen("%s settings" % where)
	ui._close_overlays()
	await _records_walk(where)
	await _rulebook_walk(where)
	await _setup_steps(where)
	ui.start_game({"seed": 3, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await _settle()
	var opens := {
		"menu": func(): ui.dispatch({"type": "menu"}),
		"glossary": func(): ui.dispatch({"type": "glossary"}),
		"rulebook": func(): ui.dispatch({"type": "rulebook"}),
		"help": func(): ui.dispatch({"type": "help", "id": "soak", "source": null}),
		"leave": func(): ui.dispatch({"type": "leave"}),
		"inspect": func(): ui._inspect(ui.vs.hand[0]),
		"banner": func(): ui._banner({"phase": "challenge", "region": 1}, 60.0),
	}
	for key in opens:
		opens[key].call()
		await process_frame
		await process_frame
		for o in ui._overlays.get_children():
			o.modulate.a = 1.0
			for c in o.find_children("*", "Control", true, false):
				c.modulate.a = 1.0
		_inspect_screen("%s %s overlay" % [where, key])
		ui._close_overlays()
		await process_frame
	await _rulebook_mid_game(where)


## The Records screen from the title, empty and then with a seeded history: each
## tab, difficulty and dragon filter whole on the screen, then back to the title.
func _records_walk(where: String) -> void:
	var kept: Array = HistoryStore.records.duplicate()
	HistoryStore.records = []
	ui.dispatch({"type": "records", "from": "title"})
	await _settle()
	_ok(ui.screen.get_script() == RecordsScreen, "%s: Records opens" % where)
	_inspect_screen("%s records, empty" % where)
	_ok(_has_label(ui.screen, "No game won on"), "%s: an empty board says so" % where)
	HistoryStore.records = _sample_records(60)
	ui.screen.refresh()
	await _settle()
	_inspect_screen("%s records leaderboard" % where)
	for key in ui.screen._tiles.keys().filter(func(k): return k.begins_with("dragon:")):
		ui.screen._tiles[key].pressed.emit()
		await process_frame
		_inspect_screen("%s records %s" % [where, key])
	ui.screen._tiles["dragon:"].pressed.emit()
	for key in ui.screen._tiles.keys().filter(func(k): return k.begins_with("difficulty:")):
		ui.screen._tiles[key].pressed.emit()
		await process_frame
		_inspect_screen("%s records %s" % [where, key])
	await _history_walk(where)
	await _clear_walk(where)
	ui.screen._tiles["back"].pressed.emit()
	await _settle()
	_ok(ui.screen.get_script() == TitleScreen, "%s: Back returns to the title" % where)
	HistoryStore.records = kept


## A won game's ending names its placing, and its Leaderboard button goes to the
## Records and back to the same ending. The win is made directly on the engine
## (the check's own games are played to lose) and recorded the way a real one is.
func _ending_placing(where: String) -> void:
	HistoryStore.use_empty(HISTORY_DIR)
	for i in 2:
		ui.start_game({"seed": 8, "dragon": "helsang", "difficulty": "hard", "cavalier": false, "glass_cannon": false})
		await _settle()
		ui.game.phase = "won"
		ui._record("won")
		ui._refresh(false, false)
		ui._show_ending()
		await _settle()
		var first := i == 0
		_ok(_has_label(ui.screen, "New best on Hard") == first, "%s: the %s win %s a new best" % [where, "first" if first else "second", "is" if first else "is not"])
		if not first:
			_ok(_has_label(ui.screen, "2nd on Hard"), "%s: the second equal win is 2nd" % where)
	_inspect_screen("%s ending with a placing" % where)
	var board: Button = ui.screen.find_children("*", "Button", true, false).filter(func(b): return b.text == "Leaderboard")[0]
	board.pressed.emit()
	await _settle()
	_ok(ui.screen.get_script() == RecordsScreen, "%s: the ending's Leaderboard button opens Records" % where)
	_ok(_has_label(ui.screen, "1st"), "%s: the win is on the board" % where)
	_inspect_screen("%s records from the ending" % where)
	ui.screen.back()
	await _settle()
	_ok(ui.screen.get_script() != RecordsScreen and ui.game != null and ui.game.phase == "won", "%s: Back returns to the ending" % where)
	_ok(_has_label(ui.screen, "2nd on Hard"), "%s: the ending is as it was" % where)
	HistoryStore.use_empty(HISTORY_DIR)


## The History tab: the first and last pages of a long history, a difficulty this
## version no longer has, and back to the Leaderboard.
func _history_walk(where: String) -> void:
	var s = ui.screen
	s._tiles["difficulty:normal"].pressed.emit()
	s._tiles["tab:history"].pressed.emit()
	await process_frame
	_inspect_screen("%s records history" % where)
	_ok(s._tiles["prev"].disabled, "%s: no newer page than the first" % where)
	var pages := 1
	while not s._tiles["next"].disabled and pages < 20:
		s._tiles["next"].pressed.emit()
		pages += 1
	await process_frame
	_ok(pages > 1, "%s: a long history has more than one page" % where)
	_inspect_screen("%s records history, last page" % where)
	_ok(s._tiles.has("difficulty:other"), "%s: games from a lost difficulty are under Other" % where)
	s._tiles["difficulty:other"].pressed.emit()
	await process_frame
	_inspect_screen("%s records history, other" % where)
	s._tiles["tab:leaderboard"].pressed.emit()
	await process_frame
	_ok(not s._tiles.has("difficulty:other") and s._difficulty == "normal", "%s: the Leaderboard has no Other" % where)


## Clear records asks first: keeping them changes nothing, clearing empties both tabs.
## The seeded records are only in memory, so nothing on disk is lost.
func _clear_walk(where: String) -> void:
	var count := HistoryStore.records.size()
	ui.screen._tiles["clear"].pressed.emit()
	await process_frame
	await process_frame
	_inspect_screen("%s clear records dialog" % where)
	ui._top_overlay().close()
	await _settle()
	_ok(HistoryStore.records.size() == count, "%s: keeping the records changes nothing" % where)
	ui.screen._tiles["clear"].pressed.emit()
	await process_frame
	ui._top_overlay().confirmed.emit()
	await _settle()
	_ok(HistoryStore.records.is_empty(), "%s: clearing empties the records" % where)
	_ok(_has_label(ui.screen, "No game won on"), "%s: the Leaderboard is empty after clearing" % where)
	_ok(ui.screen._tiles["clear"].disabled, "%s: nothing left to clear" % where)


## Made-up records over every difficulty, dragon and outcome, as a long history.
func _sample_records(count: int) -> Array:
	var out := []
	var diffs: Array = Game.DIFFICULTY.keys()
	var dragons: Array = db.dragon_ids()
	var outcomes := ["won", "lost", "abandoned"]
	var stages := ["region_1", "region_2", "region_3", "region_4", "final_journey"]
	for i in count:
		var outcome: String = outcomes[i % 3] if i % 5 != 0 else "won"
		var dragon: String = dragons[i % dragons.size()]
		out.append({"v": 1, "id": i + 1, "outcome": outcome, "difficulty": "normal" if i % 4 == 0 else diffs[i % diffs.size()],
			"dragon": dragon, "dragon_name": db.dragon(dragon).name, "cavalier": i % 7 == 0, "glass_cannon": i % 11 == 0,
			"stage": "final_enemy" if outcome == "won" else ("final_journey" if outcome == "lost" else stages[i % 5]),
			"score": 20 + (i * 7) % 23 if outcome == "won" else 0, "active_ms": 300000 + i * 61000,
			"started_at": 1790000000 + i * 3600, "ended_at": 1790000000 + i * 3600 + 1800, "seed": i})
	# A game from an older version, on a difficulty and against a dragon since removed.
	out.append({"v": 1, "id": count + 1, "outcome": "won", "difficulty": "legendary", "dragon": "oldwyrm",
		"dragon_name": "Old Wyrm", "cavalier": false, "glass_cannon": false, "stage": "final_enemy", "score": 31,
		"active_ms": 900000, "started_at": 1780000000, "ended_at": 1780001000, "seed": 0})
	out.append({"v": 1, "id": count + 2, "outcome": "lost", "difficulty": "normal", "dragon": "oldwyrm",
		"dragon_name": "Old Wyrm", "cavalier": false, "glass_cannon": false, "stage": "final_journey", "score": 0,
		"active_ms": 700000, "started_at": 1780002000, "ended_at": 1780003000, "seed": 0})
	return out


func _has_label(node: Node, prefix: String) -> bool:
	return node.find_children("*", "Label", true, false).any(func(l): return l.is_visible_in_tree() and l.text.begins_with(prefix))


## The rulebook from the title screen: every page in order, each one whole on the
## screen, then closed with nothing on the title screen changed.
func _rulebook_walk(where: String) -> void:
	var options: Dictionary = ui.screen.options.duplicate()
	Rulebook.position = {"section": 0, "page": 0}
	ui._unhandled_key_input(_key(KEY_H))
	await _settle()
	var book = ui._top_overlay()
	_ok(book != null and book.get_script() == RulebookOverlay, "%s: H opens the rulebook" % where)
	if book == null or book.get_script() != RulebookOverlay:
		return
	_ok(book.shown() == {"section": 0, "page": 0}, "%s: the rulebook opens at its first page" % where)
	book._unhandled_key_input(_key(KEY_RIGHT))
	_ok(book.shown() == Rulebook.step({"section": 0, "page": 0}, 1), "%s: Right turns the page" % where)
	book._unhandled_key_input(_key(KEY_C))
	_ok(book._contents_open, "%s: C opens the contents" % where)
	book._unhandled_key_input(_key(KEY_C))
	book._unhandled_key_input(_key(KEY_LEFT))
	_ok(not book._contents_open and book.shown() == {"section": 0, "page": 0}, "%s: C closes the contents and Left turns back" % where)
	await process_frame
	var pages := 0
	while true:
		pages += 1
		book.modulate.a = 1.0
		for c in book.find_children("*", "Control", true, false):
			c.modulate.a = 1.0
		var at: Dictionary = book.shown()
		var label := "%s rulebook %s p%d" % [where, Rulebook.SECTIONS[at.section].id, at.page + 1]
		_ok(book.fits(), "%s: the page does not fit" % label)
		_inspect_screen(label)
		var chips: Array = book.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("term"))
		_ok(chips.size() == Rulebook.terms(at.section, at.page).size(), "%s: %d terms chips for %d terms" % [label, chips.size(), Rulebook.terms(at.section, at.page).size()])
		_ok(chips.all(func(b): return b.has_meta("help_target")), "%s: every terms chip is a help target" % label)
		if Rulebook.SECTIONS[at.section].id == "mage_cards" and at.page == 0 and not chips.is_empty():
			chips[0].pressed.emit()
			await _settle()
			var top = ui._top_overlay()
			_ok(top != null and top.get_script() == GlossaryPopover, "%s: a terms chip opens its Glossary entry" % label)
			if top != null:
				top.modulate.a = 1.0
			_inspect_screen("%s help" % label)
			var esc_help := InputEventKey.new()
			esc_help.keycode = KEY_ESCAPE
			esc_help.pressed = true
			ui._unhandled_key_input(esc_help)
			await _settle()
			_ok(ui._top_overlay() == book and book.shown() == at, "%s: closing the entry returns to the same page" % label)
		if book._next.disabled:
			break
		book.next()
		await process_frame
		await process_frame
	var total := 0
	for i in Rulebook.section_count():
		total += Rulebook.page_count(i)
	_ok(pages == total, "%s: walked %d of %d rulebook pages" % [where, pages, total])
	_ok(book._next.text == "End of rulebook", "%s: the last page says it is the end" % where)
	_ok(book._prev.disabled == false or total == 1, "%s: the last page can step back" % where)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	ui._unhandled_key_input(esc)
	await _settle()
	_ok(ui._top_overlay() == null, "%s: escape closes the rulebook" % where)
	_ok(ui.screen.get_script() == TitleScreen and ui.screen.options == options, "%s: the title screen is unchanged after the rulebook" % where)


## Mid-game: Menu, How to Play, the contents, a jump and a step, then closed with
## the game exactly as it was; reopened, the rulebook is on the page left.
func _rulebook_mid_game(where: String) -> void:
	ui._close_overlays()
	ui.start_game({"seed": 3, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await _settle()
	var g = ui.game
	ui.dispatch({"type": "card", "id": g.hand[0]})
	ui.dispatch({"type": "card", "id": g.hand[1]})
	await _settle()
	var draft: Dictionary = ui.draft.to_action()
	var hand: Array = ui.vs.hand.duplicate()
	var phase: String = g.phase
	var deck: Array = g.deck.duplicate()
	ui.dispatch({"type": "menu"})
	await _settle()
	var how: Button = null
	for b in ui._top_overlay().find_children("*", "Button", true, false):
		if b.text == "How to Play":
			how = b
	_ok(how != null, "%s: the in-game menu offers How to Play" % where)
	if how == null:
		ui._close_overlays()
		return
	how.pressed.emit()
	await _settle()
	var book = ui._top_overlay()
	_ok(book != null and book.get_script() == RulebookOverlay and ui._overlays.get_children().filter(func(o): return not o.is_queued_for_deletion()).size() == 1,
		"%s: How to Play replaces the menu with the rulebook" % where)
	if book == null or book.get_script() != RulebookOverlay:
		ui._close_overlays()
		return
	book.toggle_contents()
	await process_frame
	await process_frame
	book.modulate.a = 1.0
	for c in book.find_children("*", "Control", true, false):
		c.modulate.a = 1.0
	_inspect_screen("%s rulebook contents" % where)
	_ok(book.fits(), "%s rulebook contents: does not fit" % where)
	var entries: Array = book.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("section"))
	_ok(entries.size() == Rulebook.section_count(), "%s: the contents list every section (%d)" % [where, entries.size()])
	var penalty: Button = null
	for b in entries:
		if b.get_meta("section") == Rulebook.find("penalty"):
			penalty = b
	if penalty != null:
		penalty.pressed.emit()
		await process_frame
	_ok(book.shown() == {"section": Rulebook.find("penalty"), "page": 0}, "%s: choosing Penalty Phase shows it, got %s" % [where, str(book.shown())])
	book.next()
	await process_frame
	var left: Dictionary = book.shown()
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	ui._unhandled_key_input(esc)
	await _settle()
	_ok(ui._top_overlay() == null, "%s: escape closes the rulebook mid-game" % where)
	_ok(ui.draft.to_action() == draft and ui.vs.hand == hand and g.phase == phase and g.deck == deck,
		"%s: the game is unchanged after reading the rulebook" % where)
	ui.dispatch({"type": "rulebook"})
	await _settle()
	book = ui._top_overlay()
	_ok(book != null and book.get_script() == RulebookOverlay and book.shown() == left and Rulebook.position == left,
		"%s: the rulebook reopens on the page left, %s" % [where, str(left)])
	ui._close_overlays()
	await process_frame


func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e


## Through setup: on to the rules, back to the dragons and on again keeping every
## choice, then set out with them.
func _setup_steps(where: String) -> void:
	ui.dispatch({"type": "setup_rules", "options": ui.menu})
	await _settle()
	_inspect_screen("%s rules" % where)
	_ok(ui.screen.get_script() == RulesScreen, "%s: continue shows the rules screen" % where)
	var keys: Array = ui.screen._tiles.keys()
	_ok(keys.size() == 8 and keys.has("cavalier") and keys.has("glass_cannon") and keys.filter(func(k): return k.begins_with("difficulty:")).size() == 6,
		"%s: the rules screen offers six difficulties and both rules" % where)
	ui.dispatch({"type": "glossary"})
	await _settle()
	_inspect_screen("%s rules glossary" % where)
	ui._close_overlays()
	await process_frame
	ui.screen._choose("difficulty", "hard")
	ui.screen._choose("cavalier", null)
	var kept: Dictionary = ui.screen.options.duplicate()
	ui.screen.back()
	await _settle()
	_ok(ui.screen.get_script() == TitleScreen, "%s: back shows the dragon screen" % where)
	var other: String = ui.db.dragon_ids().filter(func(id): return id != kept.dragon)[0]
	ui.screen._choose(other)
	ui.dispatch({"type": "setup_rules", "options": ui.screen.options})
	await _settle()
	var now: Dictionary = ui.screen.options
	_ok(now.dragon == other and now.difficulty == kept.difficulty and now.cavalier == kept.cavalier and now.glass_cannon == kept.glass_cannon,
		"%s: going back and on keeps the choices, %s" % [where, str(now)])
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	ui._unhandled_key_input(esc)
	await _settle()
	_ok(ui.screen.get_script() == TitleScreen, "%s: escape on the rules screen goes back" % where)
	ui.dispatch({"type": "setup_rules", "options": ui.screen.options})
	await _settle()
	var chosen: Dictionary = ui.screen.options.duplicate()
	ui.dispatch({"type": "start", "options": chosen})
	await _settle()
	_ok(ui.game != null and ui.screen == ui.play, "%s: set out starts a game" % where)
	for key in ["dragon", "difficulty", "cavalier", "glass_cannon"]:
		_ok(Settings.last_options[key] == chosen[key], "%s: set out remembers %s" % [where, key])
	ui.dispatch({"type": "to_title"})
	await _settle()


## Animated runs press again while a sequence is still playing, as a quick player would.
func _press(intent: Dictionary, animated: bool) -> void:
	if animated:
		await process_frame
		if ui.animator.is_playing():
			ui.dispatch({"type": "noop"})
	ui.dispatch(intent)
	if not animated:
		ui.animator.skip()


func _resize_mid_turn() -> void:
	ui.start_game({"seed": 4, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await _settle()
	var g = ui.game
	ui.dispatch({"type": "card", "id": g.hand[0]})
	ui.dispatch({"type": "card", "id": g.hand[1]})
	var before: Dictionary = ui.draft.to_action()
	host.size = Vector2i(1280, 720)
	ui._on_resize()
	await process_frame
	await process_frame
	_ok(ui.draft.to_action() == before, "resize keeps the placed cards")
	_ok(ui.play.hand.ids().size() == g.hand.size(), "resize keeps every card on screen")
	_inspect_screen("after resize")
