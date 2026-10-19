extends SceneTree
## Drives the real screens through seeded games at every window size in the layout
## matrix and checks what a player would trip over: anything outside the screen or
## under a notch, controls too small to tap, text too small to read, anything that
## scrolls, and any difference from the same game played on the engine alone.
## godot --headless --path . -s tools/ui_check.gd

const Solver = preload("res://ui/model/layout_solver.gd")
const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const DeckStack = preload("res://ui/widgets/deck_stack.gd")
const InspectOverlay = preload("res://ui/overlays/inspect_overlay.gd")
const Game = preload("res://engine/game.gd")
const CardDB = preload("res://engine/card_db.gd")
const CardView = preload("res://ui/widgets/card_view.gd")
const StatChip = preload("res://ui/widgets/stat_chip.gd")
const TitleScreen = preload("res://ui/screens/title_screen.gd")
const RulesScreen = preload("res://ui/screens/rules_screen.gd")
const DragonScreen = preload("res://ui/screens/dragon_screen.gd")
const Settings = preload("res://ui/model/settings.gd")
const ConfirmDialog = preload("res://ui/overlays/confirm_dialog.gd")
const RulebookOverlay = preload("res://ui/overlays/rulebook_overlay.gd")
const GlossaryPopover = preload("res://ui/overlays/glossary_popover.gd")
const Rulebook = preload("res://ui/model/rulebook.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")
const RecordsScreen = preload("res://ui/screens/records_screen.gd")
const MenuOverlay = preload("res://ui/overlays/menu_overlay.gd")
const WindowSizer = preload("res://ui/model/window_sizer.gd")

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
		await _marks_walk(name)
		await _play(name, 11, "casual", false)
	for name in ["desktop", "phone-tall", "tablet"]:
		await _open(name)
		await _deck_walk(name)
	await _open("phone-16x9")
	UI.reduced_motion = true
	await _deck_walk("phone-16x9 reduced motion")
	UI.reduced_motion = false
	await _open("phone-16x9")
	await _play("phone-16x9 animated", 5, "normal", true)
	await _open("desktop")
	await _ending_placing("desktop")
	await _open("phone-tall")
	await _ending_placing("phone-tall")
	await _open("desktop")
	await _resize_mid_turn()
	await _open("phone-16x9")
	await _arrange_walk("phone-16x9")
	await _overlay_over_lifted_cards("phone-16x9")
	await _unspent_xp_walk("phone-16x9")
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
	var view: Vector2 = Solver.matrix_view(name)
	# The game runs in a viewport of exactly this size, in design units, as the
	# project's stretch settings make it for this row's device; the row's window is
	# pretended, since a headless window keeps one size whatever it is asked for.
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
	ui.window_override = m[0]
	# Played as the web build, the one place the size notice is shown.
	ui.notice_applies = true
	if m[1] != [0, 0, 0, 0]:
		ui.safe_override = Solver.matrix_safe(name, name == "phone-tall-flipped")
	host.add_child(ui)
	await process_frame
	await process_frame
	_ok(ui.plan.view == view, "%s: the view is %s, got %s" % [name, str(view), str(ui.plan.view)])
	_ok(ui.plan.undersized == (name == "upright-browser"), "%s: undersized is %s" % [name, ui.plan.undersized])
	_ok(ui._notice != null if name == "upright-browser" else ui._notice == null, "%s: size notice" % name)
	if ui._notice != null:
		_ok(ui.plan.safe.grow(1.0).encloses(ui._notice.get_global_rect()), "%s: size notice at %s is outside the safe area" % [name, str(ui._notice.get_global_rect())])
		# Off the web the same window gets no notice.
		ui.notice_applies = false
		ui._update_notice()
		_ok(ui._notice == null, "%s: no size notice off the web" % name)
		ui.notice_applies = true
		ui._update_notice()


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
	if ui.play.plan.view != Solver.matrix_view(size_name):
		return
	var play = ui.play
	var zones := {"encounter": [play._regions.encounter.get_global_rect(), play.encounter_node()],
		"hand": [play._hand_panel.get_global_rect(), play.hand]}
	space_checks += 1
	for key in zones:
		var e: float = Solver.empty_fraction(zones[key][0], zones[key][1])
		_ok(e <= MAX_EMPTY, "%s: %s is %d%% empty" % [where, key, int(e * 100.0)])


## The note laid on the Deck in the card's place (specs/013 contracts/left-column.md):
## on the Deck, its content inside it, every word at least TEXT_MIN; and before Play
## it shows no figure of the sum (specs/011 FR-001).
func _check_note(where: String) -> void:
	if ui.screen == null or ui.screen != ui.play or ui.vs.is_empty() or ui.animator.is_playing():
		return
	var deck = ui.play.deck
	var want: bool = ui.vs.get("note") != null or deck.result_held or deck.note.refusal != ""
	_ok(deck.note_on == want, "%s: a note lies on the Deck only when there is one (%s, %s)" % [where, deck.note_on, ui.vs.get("note")])
	if not deck.note_on:
		return
	var region: Rect2 = ui.play._regions.encounter.get_global_rect().grow(1)
	_ok(region.encloses(deck.note.get_global_rect()), "%s: the note is on the Deck" % where)
	_ok(deck.note.content_height() <= deck.note.size.y - 2.0 * deck.note.PAD + 1.0,
		"%s: the note's %s fits it (%d of %d)" % [where, str(deck.note.kinds), int(deck.note.content_height()), int(deck.note.size.y)])
	if not deck.result_held:
		var shown: Array = deck.note.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree())
		for s in ui.vs.get("math", {}).get("sums", []):
			_ok(not shown.any(func(l): return l.text == s.label), "%s: no %s row before Play" % [where, s.label])


func _settle() -> void:
	ui.animator.skip()
	await process_frame
	await process_frame
	if ui.game != null:
		_check_deck_settled("%s %s" % [current_size, ui.game.phase])
		_check_note("%s %s" % [current_size, ui.game.phase])
		await _check_space("%s %s" % [current_size, ui.game.phase])


## The Deck at rest (specs/012 contracts/deck-stack.md): zoomed in on the face of
## what is being played, its edges as deep as the Deck count says, nothing held.
func _check_deck_settled(where: String) -> void:
	if ui.screen == null or ui.screen != ui.play or ui.vs.is_empty():
		return
	var deck = ui.play.deck
	_ok(not deck.held, "%s: the Deck is not held at rest" % where)
	_ok(deck.view == "face", "%s: at rest the Deck shows the face" % where)
	_ok(deck.count == ui.vs.piles.deck, "%s: the stack is %d deep for a Deck of %d" % [where, deck.count, ui.vs.piles.deck])
	var enc = ui.vs.encounter
	if enc != null and (enc.kind == "enemy" or enc.kind == "journey"):
		var p = deck.landed.panel.panel
		_ok(deck.landed.visible and p.get("key", "") == "%s:%d" % [enc.kind, enc.index], "%s: the face is the Encounter's panel" % where)
	var region: Rect2 = ui.play._regions.encounter.get_global_rect()
	# Allowing for a shake still settling (UI.shake runs on after a skip).
	_ok(region.grow(16).encloses(deck.face_node().get_global_rect()), "%s: the face %s is on the Deck %s" % [where, deck.face_node().get_global_rect(), region])
	_ok(deck.face_node().size == DeckStack.face_rect(region.size).size, "%s: the face leaves the stack its margin" % where)
	# Zoomed in on a Region Encounter, the card lies exactly where the zoom brought it
	# (specs/013 research R3), so nothing jumps as the landed face takes over.
	if deck.landed.visible:
		var f: Rect2 = DeckStack.face_rect(region.size)
		var at: Dictionary = deck._landing(Rect2(Vector2.ZERO, f.size))
		_ok(deck.landed.card.position.is_equal_approx(at.card.position) and deck.landed.card.size.is_equal_approx(at.card.size),
			"%s: the landed card is where the zoom ends" % where)
		_ok(deck.landed.panel == deck.landed.card.panel(deck.landed.key) and deck.landed.panel.interactive, "%s: its panel is lit and explains itself" % where)
		for l in deck.landed.strip.find_children("*", "Label", true, false):
			_ok(l.get_theme_font_size("font_size") >= T.TEXT_MIN, "%s: the strip's '%s' is at least %d" % [where, l.text.left(20), T.TEXT_MIN])
	# Cards are drawn from the Deck and go to its back (specs/012 R9).
	for anchor in ["deck", "discard"]:
		_ok(region.grow(T.DECK_EDGE).has_point(ui.play.point(anchor)), "%s: cards travel to and from the Deck (%s)" % [where, anchor])


## The reveal frame by frame (specs/012): the start of a game and a Divert, played
## through. While the view is zoomed out everything on the Deck stays inside it,
## clear of the header, the Hand and the action row; between the draw and the zoom
## the whole top card shows; the stack refills before a new Hand. In reduced motion
## nothing on the Deck travels or grows.
func _deck_walk(where: String) -> void:
	ui.start_game({"seed": 5, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await _watch_deck(where + " start")
	var id: String = ui.game.hand[0]
	ui._act({"kind": "divert", "cards": [id], "id": id}, func(): return ui.game.divert(id))
	await _watch_deck(where + " divert")
	await _settle()
	# The end of Region 1: the Deck is gathered, refills before the new Hand, and its
	# card turns over to Region 2.
	var g = ui.game
	g.discard.append_array(g.deck)
	g.deck = []
	g.phase = "upgrade"
	g._action = {"cards": {}, "fuse": null, "reserve": null}
	ui._refresh(false)
	ui._act({"kind": "finish", "cards": []}, func(): return ui.game.finish())
	eq_region(where, g)
	await _watch_deck(where + " region change", ui.vs.piles.deck + ui.vs.hand.size())
	await _settle()
	# The whole card is the printed card, figure for figure (specs/013 SC-001). It is
	# a picture of the card, seen while the Deck zooms; its figures are read zoomed in.
	var card = ui.play.deck.region_card
	for p in card.model.panels:
		var v = card.panel(p.key)
		_ok(v != null and v.panel == p, "%s: panel %s shows its Encounter" % [where, p.key])
		if v == null:
			continue
		var want := {"xp": str(p.xp)}
		if p.kind == "enemy":
			want.merge({"hp": str(p.enemy.hp), "initiative": str(p.enemy.initiative), "attack": str(p.enemy.attack.value), "armor0": str(p.enemy.armor[0].value)})
		else:
			want.merge({"mp": str(p.journey.mp.value), "time": str(p.journey.time_penalty)})
		for chip in want:
			_ok(v.chip(chip) != null and v.chip(chip).text == want[chip], "%s: panel %s's %s reads %s" % [where, p.key, chip, want[chip]])
		_ok(v.discs().size() == (1 if p.effect != null else 0), "%s: panel %s marks its Ability or Peril only if it has one" % [where, p.key])


func eq_region(where: String, g) -> void:
	_ok(g.region == 2 and g.phase == "challenge", "%s: on to Region 2 (%d, %s)" % [where, g.region, g.phase])


## `gathered`: the Deck's count once gathered, which the stack must show by the time
## the card turns.
func _watch_deck(where: String, gathered := -1) -> void:
	var deck = ui.play.deck
	var seen := []
	var on_step := func(kind: String):
		seen.append(kind)
		if kind == "turn_card" and gathered >= 0:
			_ok(deck.count == gathered, "%s: the stack refilled to %d before the turn (%d)" % [where, gathered, deck.count])
	ui.animator.step_started.connect(on_step)
	var region: Rect2 = ui.play._regions.encounter.get_global_rect().grow(1)
	var others := [ui.play.header.get_global_rect(), ui.play._hand_panel.get_global_rect(), ui.play._regions.actions.get_global_rect()]
	var still := true
	var peek_at = null
	var until := Time.get_ticks_msec() + 10000
	while ui.animator.is_playing() and Time.get_ticks_msec() < until:
		await process_frame
		if deck.view == "card":
			var top: Control = deck.top_node()
			# While it grows into a panel (or back) it is clipped to the face (specs/013 R3).
			if top != null and top.visible and top.scale == Vector2.ONE and not deck._tops.clip_contents:
				_ok(region.encloses(top.get_global_rect()), "%s: the top card stays on the Deck (%s in %s)" % [where, top.get_global_rect(), region])
			if deck._tops.clip_contents:
				_ok(region.encloses(deck._tops.get_global_rect()), "%s: the growing card is clipped to the Deck" % where)
			if deck._peek.visible:
				var r: Rect2 = deck._peek_clip.get_global_rect().intersection(deck._peek.get_global_rect())
				_ok(region.encloses(r), "%s: the Key Card stays on the Deck" % where)
				for o in others:
					_ok(not r.intersects(o), "%s: the Key Card stays clear of the rest of the screen" % where)
				if peek_at == null:
					peek_at = deck._peek.position
				elif UI.reduced_motion and deck._peek.position != peek_at:
					still = false
		var drawn: int = seen.rfind("draw")
		if drawn >= 0 and drawn > seen.rfind("zoom_in") and not seen.has("zoom_in"):
			_ok(deck.view == "card", "%s: between the draw and the zoom the whole top card shows" % where)
		if UI.reduced_motion:
			for c in [deck.region_card, deck.landed]:
				if c.scale != Vector2.ONE:
					still = false
	ui.animator.step_started.disconnect(on_step)
	_ok(seen.has("zoom_in"), "%s: the reveal played (%s)" % [where, str(seen)])
	if where.contains("start"):
		_ok(seen.has("key_peek"), "%s: the Key Card rose" % where)
	if gathered >= 0:
		_ok(seen.has("turn_card"), "%s: the card turned" % where)
	if UI.reduced_motion:
		_ok(still, "%s: in reduced motion nothing on the Deck travels or grows" % where)
	_ok(not ui.animator.is_playing(), "%s: the sequence ends within 10 seconds" % where)
	_ok(deck.view == "face" and not deck.held, "%s: the reveal ends on the face (%s, held %s)" % [where, deck.view, deck.held])


## Everything a player can press or must read, checked against the screen.
## Skipped while a sequence is moving things about.
func _inspect_screen(where: String) -> void:
	if ui.animator.is_playing():
		return
	var safe: Rect2 = ui.plan.safe.grow(1.0)
	var view := Rect2(Vector2.ZERO, Vector2(host.size)).grow(1.0)
	var nodes: Array = ui.screen.find_children("*", "Control", true, false) + ui._overlays.find_children("*", "Control", true, false)
	if ui.title_bar.visible:
		nodes += ui.title_bar.find_children("*", "Control", true, false)
	# Every screen has the menu button, in the same place.
	var bar: Control = ui.play.header if ui.play != null and ui.screen == ui.play else ui.title_bar
	var header: Rect2 = ui.plan.regions.header
	var menu_rect: Rect2 = bar.menu_button.get_global_rect()
	_ok(bar.is_visible_in_tree() and menu_rect.position.is_equal_approx(Vector2(header.end.x - menu_rect.size.x, header.position.y)),
		"%s: the menu button is not at the title bar's right" % where)
	if bar == ui.title_bar and bar.back_button.visible:
		_ok(bar.back_button.get_global_rect().position.is_equal_approx(header.position), "%s: Back is not at the title bar's left" % where)
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
			# The menu and Back buttons reach below the header on purpose; their visible parts are inside.
			var r_check := Rect2(r.position, Vector2(r.size.x, minf(r.size.y, 56.0))) if c.name in ["MenuButton", "BackButton"] else r
			_ok(safe.encloses(r_check), "%s: %s at %s is outside the safe area %s" % [where, _name(c), str(r), str(safe)])
		# The printed cards' codes are never shown (specs/013 FR-004).
		if c is Label:
			_ok(not c.text.contains("DOE-"), "%s: a card code shows in '%s'" % [where, c.text.left(30)])
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
	if c is Button and c.text == "":
		return "button at %s" % str(c.get_path()).get_slice("/", str(c.get_path()).get_slice_count("/") - 2) + "/" + c.get_parent().get_class()
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
				var roles := ["spell", "element", "boost"]
				for i in mini(3, hand.size()):
					await _place(hand[i], [0, roles[i]], animated, where)
				if hand.size() > 2 and g.encounter().kind == "enemy":
					await _press({"type": "set_boost_to", "set": 0, "to": "attack"}, animated)
				var a := {"spell": hand[0]}
				if hand.size() > 1:
					a["element"] = hand[1]
				if hand.size() > 2:
					a["boost"] = hand[2]
				a["boost_to"] = "attack"
				a["ranged_discard"] = false
				if not animated:
					_inspect_screen("%s challenge, placed" % where)
					# On a long phone a Region's cards are two fifths again as tall as 009's
					# 196, less what the Boost's column takes from 010's half again.
					if current_size.begins_with("phone-tall") and hand.size() == 4:
						_ok(ui.play.plan.card_size.y >= 274.0, "%s: cards %s, at least 274 tall" % [where, str(ui.play.plan.card_size)])
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
				var can_spend: bool = g.xp > 0 and g.hand.any(func(id): return ui.vs.cards[id].get("eligible", false))
				await _press({"type": "primary"}, animated)
				var top = ui._top_overlay()
				var asked: bool = top != null and top.get_script() == ConfirmDialog
				_ok(asked == (can_spend and Settings.warn_unspent_xp), "%s: unspent XP asks first only when a card could be Upgraded" % where)
				if asked:
					_ok(g.phase == "upgrade", "%s: nothing moves on until answered" % where)
					if not animated:
						await _settle()
						_inspect_screen("%s unspent XP" % where)
					top.confirmed.emit()
					top.close()
					await _settle()
				shadow.finish()
			"final_journey", "final_enemy":
				var hand: Array = g.hand.duplicate()
				var order := ["spell", "element", "boost"]
				for i in mini(6, hand.size()):
					await _place(hand[i], [i / 3, order[i % 3]], animated, where)
				if g.phase == "final_enemy":
					for i in 2:
						await _press({"type": "set_boost_to", "set": i, "to": "attack"}, animated)
				if not animated:
					_inspect_screen("%s %s, placed" % [where, g.phase])
					for i in 2:
						_check_aim(i, g.phase == "final_enemy", "%s %s Boost %d" % [where, g.phase, i + 1])
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


## The landing page and the two setup screens, then each overlay over a game in
## progress, one at a time.
func _screens_and_overlays(where: String) -> void:
	await _settle()
	_inspect_screen("%s title" % where)
	_ok(ui.screen.get_script() == TitleScreen, "%s: launch shows the landing page" % where)
	_ok(ui.screen._tiles.is_empty(), "%s: the landing page offers no choices" % where)
	_ok(not _has_label(ui.screen, "Journey") and not _has_label(ui.screen, "Battle"), "%s: the landing page shows no dragon's figures" % where)
	ui.dispatch({"type": "menu"})
	await _settle()
	_inspect_screen("%s settings" % where)
	var menu: Node = null
	for o in ui._overlays.get_children():
		if o.get_script() == MenuOverlay:
			menu = o
	_ok(menu != null, "%s: settings open" % where)
	if menu != null:
		# Feature 008: the Window row is only on a desktop with a real window. Its
		# tiles are not pressed here, as a headless window cannot change mode.
		var tiles: Dictionary = menu._window_tiles
		_ok(tiles.size() == (2 if WindowSizer.applies() else 0), "%s: Window row on desktops only (%d tiles)" % [where, tiles.size()])
		if not tiles.is_empty():
			_ok(tiles.values().filter(func(t): return t.selected).size() == 1, "%s: one window mode is chosen" % where)
	ui._close_overlays()
	# The tallest the menu gets: in a game, on a desktop with the Window row.
	var tall := MenuOverlay.new()
	ui._overlays.add_child(tall)
	tall.setup(true, ui.plan.content, true)
	await _settle()
	_ok(ui.plan.content.grow(1.0).encloses(tall.panel.get_global_rect()), "%s: the in-game menu at %s fits the content area %s" % [where, str(tall.panel.get_global_rect()), str(ui.plan.content)])
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


## The Leaderboard from the title, empty and then with a seeded history: each
## difficulty and dragon filter whole on the screen; then the History, from the
## menu; clearing the records, from the menu; and back to the title.
func _records_walk(where: String) -> void:
	var kept: Array = HistoryStore.records.duplicate()
	HistoryStore.records = []
	ui.dispatch({"type": "records", "page": "leaderboard", "from": "title"})
	await _settle()
	_ok(ui.screen.get_script() == RecordsScreen and ui.screen.heading == "Leaderboard", "%s: the Leaderboard opens" % where)
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
	ui.title_bar.back_button.pressed.emit()
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
		# Equal wins rank by time played, then by when they ended; the two games here
		# take whatever real time the frames do, so give them the same.
		ui.clock.reset()
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
	_ok(ui.screen.get_script() == RecordsScreen, "%s: the ending's Leaderboard button opens the Leaderboard" % where)
	_ok(_has_label(ui.screen, "1st"), "%s: the win is on the board" % where)
	_inspect_screen("%s records from the ending" % where)
	ui.screen.back()
	await _settle()
	_ok(ui.screen.get_script() != RecordsScreen and ui.game != null and ui.game.phase == "won", "%s: Back returns to the ending" % where)
	_ok(_has_label(ui.screen, "2nd on Hard"), "%s: the ending is as it was" % where)
	HistoryStore.use_empty(HISTORY_DIR)


## The History, from the menu over the Leaderboard: the first and last pages of a
## long history, a difficulty this version no longer has, and back to the Leaderboard.
func _history_walk(where: String) -> void:
	ui.menu.difficulty = "normal"
	_menu_button("History").pressed.emit()
	await _settle()
	var s = ui.screen
	_ok(s.get_script() == RecordsScreen and s.heading == "History", "%s: the menu's History opens the History" % where)
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
	_menu_button("Leaderboard").pressed.emit()
	await _settle()
	s = ui.screen
	_ok(s.heading == "Leaderboard" and not s._tiles.has("difficulty:other") and s._difficulty == "normal", "%s: the Leaderboard has no Other" % where)


## Clear records, in the menu, asks first: keeping them changes nothing, clearing
## empties the Leaderboard. The seeded records are only in memory, so nothing on disk is lost.
func _clear_walk(where: String) -> void:
	var count := HistoryStore.records.size()
	_menu_button("Clear records").pressed.emit()
	await process_frame
	await process_frame
	_inspect_screen("%s clear records dialog" % where)
	ui._top_overlay().close()
	await _settle()
	_ok(HistoryStore.records.size() == count, "%s: keeping the records changes nothing" % where)
	_close_menu()
	await _settle()
	_menu_button("Clear records").pressed.emit()
	await process_frame
	ui._top_overlay().confirmed.emit()
	await _settle()
	_ok(HistoryStore.records.is_empty(), "%s: clearing empties the records" % where)
	_ok(_has_label(ui.screen, "No game won on"), "%s: the Leaderboard is empty after clearing" % where)
	_ok(_menu_button("Clear records").disabled, "%s: nothing left to clear" % where)
	_close_menu()
	await _settle()


## Open the menu and find its button named `text`.
func _menu_button(text: String) -> Button:
	ui.dispatch({"type": "menu"})
	var menu: Node = null
	for o in ui._overlays.get_children():
		if o.get_script() == MenuOverlay and not o.is_queued_for_deletion():
			menu = o
	return menu.find_children("*", "Button", true, false).filter(func(b): return b.text == text)[0]


func _close_menu() -> void:
	for o in ui._overlays.get_children():
		if o.get_script() == MenuOverlay and not o.is_queued_for_deletion():
			o.close()


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
		if Rulebook.step(at, 1) == at:
			break
		book.next()
		await process_frame
		await process_frame
	var total := 0
	for i in Rulebook.section_count():
		total += Rulebook.page_count(i)
	_ok(pages == total, "%s: walked %d of %d rulebook pages" % [where, pages, total])
	_ok(book._next.text == "Close" and not book._next.disabled, "%s: the last page's Next closes the book" % where)
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
	var back = ui._top_overlay()
	_ok(back != null and back.get_script() == MenuOverlay, "%s: escape from the rulebook returns to Settings" % where)
	ui._unhandled_key_input(esc)
	await _settle()
	_ok(ui._top_overlay() == null, "%s: escape then closes Settings mid-game" % where)
	_ok(ui.draft.to_action() == draft and ui.vs.hand == hand and g.phase == phase and g.deck == deck,
		"%s: the game is unchanged after reading the rulebook" % where)
	ui.dispatch({"type": "rulebook"})
	await _settle()
	book = ui._top_overlay()
	_ok(book != null and book.get_script() == RulebookOverlay and book.shown() == left and Rulebook.position == left,
		"%s: the rulebook reopens on the page left, %s" % [where, str(left)])
	ui._close_overlays()
	await process_frame
	# The Leaderboard from the in-game menu, and Back to the same game.
	_menu_button("Leaderboard").pressed.emit()
	await _settle()
	_ok(ui.screen.get_script() == RecordsScreen and ui.screen.heading == "Leaderboard", "%s: the in-game menu opens the Leaderboard" % where)
	ui.screen.back()
	await _settle()
	_ok(ui.screen == ui.play and ui.game == g and ui.draft.to_action() == draft and ui.vs.hand == hand,
		"%s: Back from the Leaderboard returns to the game as it was" % where)


func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e


## Through setup: on to the rules, back to the dragons and on again keeping every
## choice, then set out with them.
func _setup_steps(where: String) -> void:
	await _dragon_walk(where)
	ui.dispatch({"type": "setup_rules", "options": ui.screen.options})
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
	_ok(ui.screen.get_script() == DragonScreen and ui.screen.options.dragon == kept.dragon, "%s: back shows the dragon screen, dragon kept" % where)
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
	_ok(ui.screen.get_script() == DragonScreen, "%s: escape on the rules screen goes back" % where)
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


## Play from the landing page: four dragons in Ether order, none chosen and
## Continue waiting; then the figures of the chosen one only, each explaining
## itself, following each choice; Back and Escape return to the landing page, and
## Play again starts with none chosen.
func _dragon_walk(where: String) -> void:
	await _play_from_landing(where)
	_inspect_screen("%s dragons, none chosen" % where)
	_ok(ui.screen.get_script() == DragonScreen, "%s: Play shows the dragon screen" % where)
	var keys: Array = ui.screen._tiles.keys()
	_ok(keys.size() == 4 and keys.all(func(k): return k.begins_with("dragon:")), "%s: the dragon screen offers four dragons" % where)
	var ethers: Array = ui.screen.ordered_ids().map(func(id): return ui.db.dragon(id).early_damage.element)
	_ok(ethers == ["fire", "lightning", "water", "shadow"], "%s: the dragons run Fire, Lightning, Water, Shadow, %s" % [where, str(ethers)])
	_ok(_shows_none(), "%s: no dragon is chosen at first, Continue waits" % where)
	_ok(ui.get_viewport().gui_get_focus_owner() == null, "%s: no dragon card looks chosen at first" % where)
	for id in ui.screen.ordered_ids():
		ui.screen._choose(id)
		await process_frame
		_inspect_screen("%s dragons %s" % [where, id])
		_ok(_shows_only(id), "%s: only %s's figures are shown" % [where, id])
		_ok(_explains(ui.screen.stats), "%s: %s's figures explain themselves" % [where, id])
	var other: String = ui.db.dragon_ids()[1]
	ui.screen._choose(other)
	ui.screen.back()
	await _settle()
	_ok(ui.screen.get_script() == TitleScreen, "%s: Back on the dragon screen shows the landing page" % where)
	await _play_from_landing(where)
	_ok(ui.screen.get_script() == DragonScreen and _shows_none(), "%s: Play again starts with no dragon chosen" % where)
	ui.screen._choose(other)
	ui._unhandled_key_input(_key(KEY_ESCAPE))
	await _settle()
	_ok(ui.screen.get_script() == TitleScreen, "%s: escape on the dragon screen goes back" % where)
	await _play_from_landing(where)
	ui.screen._choose(other)
	await process_frame


## Presses Play on the landing page, if it is showing.
func _play_from_landing(_where: String) -> void:
	if ui.screen.get_script() == TitleScreen:
		ui.screen._play()
		await _settle()


## The dragon screen before a choice: nothing marked, no figures, Continue off.
func _shows_none() -> bool:
	var s = ui.screen
	return s.options.dragon == "" and s._tiles.values().all(func(t): return not t.selected) \
		and s.stats == null and s._next.disabled


## Every part of the figures that says what it is: the Initiative, Early Damage
## and Ether, each Armor, both ladders and each tier.
func _explains(stats: Control) -> bool:
	if stats == null:
		return false
	var tips: Array = stats.find_children("*", "Control", true, false).filter(func(c): return c.tooltip_text != "" and c.mouse_filter == Control.MOUSE_FILTER_STOP)
	var text := "\n".join(tips.map(func(c): return c.tooltip_text))
	return ["Initiative", "Early Damage", "The dragon's Ether", "Armor", "The Final Journey", "The Final Enemy", "Final Journey tier", "Final Enemy tier"].all(func(k): return text.contains(k))


## The dragon screen marks `id` alone and shows its figures and no other's.
func _shows_only(id: String) -> bool:
	var s = ui.screen
	var marked: Array = s._tiles.keys().filter(func(k): return s._tiles[k].selected)
	var figures: Array = s.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree() and l.text == "Journey")
	return marked == ["dragon:" + id] and is_instance_valid(s.stats) and s.stats.is_inside_tree() \
		and figures.size() == 1 and s._name.text == ui.db.dragon(id).name.to_upper() and not s._next.disabled


## Place a card the way a player does: tap it, then tap its place in the role strip.
## Between the two, and after, every card must be wholly on screen (SC-004a).
func _place(id: String, target: Array, animated: bool, where: String) -> void:
	await _press({"type": "card", "id": id}, animated)
	_ok(ui.draft.held == id, "%s: tapping %s picks it up" % [where, id])
	await _press({"type": "put", "target": target}, animated)
	_ok(ui.draft.slot_of(id) == target, "%s: %s is put in %s" % [where, id, str(target)])
	if not animated:
		_cards_on_screen("%s %s" % [where, ui.game.phase])


## A card lifted out of the Hand (held, or picked up to drag, as a long press does
## on its way to the inspect panel) is drawn above the other cards, but an open
## overlay still covers it.
func _overlay_over_lifted_cards(where: String) -> void:
	ui._close_overlays()
	ui.start_game({"seed": 4, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await _settle()
	var id: String = ui.game.hand[0]
	ui.dispatch({"type": "card", "id": id})
	await _settle()
	_ok(ui.draft.held == id, "%s: the card is held" % where)
	for how in ["held", "dragged"]:
		if how == "dragged":
			ui.play.hand._on_drag_started(id)
		ui.dispatch({"type": "inspect", "id": id})
		await _settle()
		var overlay: CanvasItem = ui._overlays.get_child(-1)
		for node in ui.screen.find_children("*", "CanvasItem", true, false):
			var c := node as CanvasItem
			if c.is_visible_in_tree() and _drawn_z(c) > _drawn_z(overlay):
				_fail("%s: the %s card draws above the inspect panel (z %d over %d)" % [where, how, _drawn_z(c), _drawn_z(overlay)])
				break
		checks += 1
		ui._close_overlays()
		await process_frame
	ui.play.hand._on_dropped(id, ui.play.plan.regions.encounter.get_center())


## The z a node is drawn at: its own, plus its parents' while it is relative to them.
func _drawn_z(c: CanvasItem) -> int:
	var z := c.z_index
	while c.z_as_relative and c.get_parent() is CanvasItem:
		c = c.get_parent()
		z += c.z_index
	return z


func _cards_on_screen(where: String) -> void:
	if ui.screen != ui.play or ui.play.plan.is_empty():
		return
	var view := Rect2(Vector2.ZERO, ui.play.plan.view).grow(1.0)
	for id in ui.play.hand.ids():
		var c: Control = ui.play.hand.card(id)
		var home := Rect2(c.home.position + ui.play.hand.global_position, c.home.size)
		_ok(view.encloses(home), "%s: card %s is on screen, at %s" % [where, id, str(home)])


## Animated runs press again while a sequence is still playing, as a quick player would.
func _press(intent: Dictionary, animated: bool) -> void:
	if animated:
		await process_frame
		if ui.animator.is_playing():
			ui.dispatch({"type": "noop"})
	ui.dispatch(intent)
	if not animated:
		ui.animator.skip()


## The ordered Hand by every input: tap a card then a place, swap by tapping a
## placed card, drag onto a place and away, and the keyboard (specs/009 US1, US2).
## The unspent XP question: "Don't show this again" stops it, and the setting is kept.
func _unspent_xp_walk(where: String) -> void:
	ui._close_overlays()
	Settings.warn_unspent_xp = true
	var c := ConfirmDialog.new()
	ui._overlays.add_child(c)
	c.setup("Question", "Yes", "No", "Don't show this again")
	var box: CheckBox = c.find_children("*", "CheckBox", true, false)[0]
	_ok(box.size.y >= 44.0 or box.custom_minimum_size.y >= 44.0, "%s: the box is a full tap target" % where)
	box.button_pressed = true
	var opted: bool = c.opted_out
	c.close()
	await _settle()
	_ok(opted, "%s: ticking the box is remembered" % where)
	Settings.warn_unspent_xp = true


## A seed and Region whose opening Encounter has this effect (Hardship, ability or
## peril), as [seed, region], or [] when none does.
func _seed_with(effect: String) -> Array:
	for game_seed in range(1, 200):
		var g = Game.new(db, {"seed": game_seed, "dragon": "rodving", "difficulty": "normal"})
		if g.phase != "challenge":
			continue
		for region in range(1, 4):
			g.region = region
			var enc: Dictionary = g.encounter()
			if [enc.hardship, enc.data.get("ability"), enc.data.get("peril")].has(effect):
				return [game_seed, region]
	return []


## Each effect that works against a card's figure shows its mark beside it, inside
## the card and clear of every figure (specs/011 contracts/card-marks.md).
func _marks_walk(where: String) -> void:
	for effect in ["night_travel", "steep", "ranged", "freeze"]:
		var found := _seed_with(effect)
		if found.is_empty():
			_ok(false, "%s: a seed opens on %s" % [where, effect])
			continue
		ui._close_overlays()
		ui.start_game({"seed": found[0], "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
		# The deal's animation ends by drawing the state it began from: end it first.
		ui.animator.skip()
		ui.game.region = found[1]
		ui._refresh()
		await _settle()
		var marked := 0
		for id in ui.game.hand:
			var view: Control = ui.play.hand.card(id)
			var face = view._face
			var all: Dictionary = face.marks()
			for region in all:
				for r in face.mark_rects(region, all[region].size()):
					marked += 1
					_ok(Rect2(Vector2.ZERO, view.size).encloses(r), "%s %s: a mark inside its card" % [where, effect])
					for key in ["initiative", "basic", "enhanced", "boost", "armor"]:
						_ok(not r.intersects(face.region_rect(key)), "%s %s: a mark clear of the %s" % [where, effect, key])
			# An Enemy's Armor may mark the Spell as well.
			for m in ui.vs.cards[id].focus.impacts:
				_ok(m.icon == effect or m.icon == "armor", "%s %s: only its own mark, not %s" % [where, effect, m.icon])
		_ok(marked > 0, "%s %s: the Hand shows its mark" % [where, effect])
		_inspect_screen("%s %s marks" % [where, effect])


## A Boost card's aim zone against an Enemy (specs/011 contracts/card-marks.md): one
## tap target tall, inside the card, no more than half of it, over the Boost plate.
## Set `set_index`'s Boost aim, in the column after its row of places: Attack and
## Initiative against an Enemy (`enemy`), else the fixed Move; every button a tap
## target, inside the Hand's region, clear of every card, and beside that set's row.
func _check_aim(set_index: int, enemy: bool, where: String) -> void:
	var buttons: Array = ui.play.aims.buttons(set_index)
	var want := ["attack", "initiative"] if enemy else ["move"]
	_ok(buttons.map(func(b): return b.get_meta("to")) == want, "%s: the aim offers %s" % [where, str(want)])
	var hand_region: Rect2 = ui.play.plan.regions.hand
	var row := []
	for pos in ui.play.plan.positions:
		if ui.vs.places.size() > ui.play.plan.positions.find(pos):
			var pl: Dictionary = ui.vs.places[ui.play.plan.positions.find(pos)]
			if pl.set == set_index and pl.role != "reserve":
				row.append(pos.card)
	for b in buttons:
		var r: Rect2 = b.get_global_rect()
		_ok(r.size.y >= T.TAP_MIN - 0.5 and r.size.x >= T.TAP_MIN - 0.5, "%s: %s is a tap target, %s" % [where, b.get_meta("to"), str(r.size)])
		_ok(hand_region.grow(0.5).encloses(r), "%s: %s is inside the Hand" % [where, b.get_meta("to")])
		_ok(not ui.play.plan.positions.any(func(pos): return pos.card.intersects(r)), "%s: %s covers no card" % [where, b.get_meta("to")])
		if not row.is_empty():
			_ok(r.position.x >= row.map(func(c): return c.end.x).max() and r.position.y >= row[0].position.y - 0.5 and r.end.y <= row[0].end.y + 0.5,
				"%s: %s is beside its set's row" % [where, b.get_meta("to")])
		_ok(b.text == "" and b.icon != null and b.tooltip_text != "", "%s: %s is its symbol alone, named on hover" % [where, b.get_meta("to")])


## A press and release at a point on a card, as a finger or mouse would.
func _tap_card(view: Control, at: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = at
		view._gui_input(e)


func _arrange_walk(where: String) -> void:
	ui._close_overlays()
	ui.start_game({"seed": 4, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await _settle()
	var g = ui.game
	var hand: Array = g.hand.duplicate()
	var enemy: bool = g.encounter().kind == "enemy"
	_ok(ui.vs.places.map(func(p): return p.card_id) == hand and ui.vs.unplaced.is_empty(),
		"%s: the Hand is dealt into Reserve, Element, Spell, Boost in draw order" % where)
	_ok(ui.vs.preview.status == ("incomplete" if enemy else "ready"), "%s: an outcome shows at once, but for the Boost's aim" % where)
	_ok(ui.play.labels.get_child_count() == 4, "%s: a label over each card" % where)
	_cards_on_screen(where + " dealt")
	# Pressing the Encounter face shows the Key Card that named it, its Key Card part lifted.
	var face: Control = ui.play.landed
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	face.gui_input.emit(up)
	var top = ui._top_overlay()
	_ok(top != null and top.get_script() == InspectOverlay, "%s: pressing the Encounter opens its Key Card" % where)
	if top != null:
		_ok(top.find_children("*", "Label", true, false).any(func(l): return l.text.begins_with("KEY CARD")), "%s: and says it is the Key Card" % where)
		await _settle()
		_inspect_screen(where + " key card")
	ui._close_overlays()
	await _settle()
	_ok(not ui.play.landed.find_children("*", "Label", true, false).any(func(l): return l.text.contains("Key Card")), "%s: the face has no Key Card line" % where)
	if enemy:
		# Play before the Boost has a target: nothing is played, and the board says why.
		ui.dispatch({"type": "primary"})
		await _settle()
		_ok(g.phase == "challenge", "%s: Play waits for the Boost's aim" % where)
		# The reason lies on the Deck in the card's place (specs/013 FR-011).
		_ok(ui.play.deck.note_on and ui.play.deck.note.refusal.contains("Boost"), "%s: and says what is missing" % where)
		ui.play.deck.clear_refusal()
		# The Boost is aimed in its own column after the row: Attack, then Initiative;
		# a tap on the Boost card only picks it up, as on any other card.
		_check_aim(0, true, where)
		ui.play.aims.choice(0, "attack").pressed.emit()
		await _settle()
		_ok(ui.draft.boost_to[0] == "attack", "%s: Attack aims the Boost at Attack" % where)
		_ok(ui.draft.held == null, "%s: and picks no card up" % where)
		ui.play.aims.choice(0, "initiative").pressed.emit()
		await _settle()
		_ok(ui.draft.boost_to[0] == "initiative", "%s: Initiative aims it at Initiative" % where)
		var view: Control = ui.play.hand.card(hand[3])
		_tap_card(view, view.size * Vector2(0.5, 0.9))
		await _settle()
		_ok(ui.draft.held == hand[3] and ui.draft.boost_to[0] == "initiative", "%s: a tap low on the Boost card picks it up, the aim unchanged" % where)
		_tap_card(view, view.size / 2.0)
		await _settle()
		_ok(ui.draft.held == null, "%s: and a second tap puts it down" % where)
	else:
		_check_aim(0, false, where)
	# Tap the Element, then the Boost: they swap.
	ui.dispatch({"type": "card", "id": hand[1]})
	ui.dispatch({"type": "card", "id": hand[3]})
	_ok(ui.draft.sets[0].element == hand[3] and ui.draft.sets[0].boost == hand[1], "%s: tapping two cards swaps them" % where)
	# Drag the Reserve onto the Spell.
	await _settle()
	var tray = ui.play.hand
	var spell_rect: Rect2 = ui.play.plan.positions[2].card
	tray._on_drag_started(hand[0])
	tray._on_dragged(hand[0], spell_rect.get_center())
	tray._on_dropped(hand[0], spell_rect.get_center())
	_ok(ui.draft.sets[0].spell == hand[0] and ui.draft.reserve_card(g.hand) == hand[2], "%s: dragging the Reserve onto the Spell swaps them" % where)
	# Dropped on a label, the card goes to that place too.
	await _settle()
	var label_rect: Rect2 = ui.play.plan.positions[0].label
	tray._on_drag_started(hand[0])
	tray._on_dropped(hand[0], label_rect.get_center())
	_ok(ui.draft.reserve_card(g.hand) == hand[0], "%s: a card dropped on the Reserve's label takes the Reserve" % where)
	# A drag let go away from any place changes nothing.
	await _settle()
	var before: Dictionary = ui.draft.to_action()
	tray._on_drag_started(hand[3])
	tray._on_dropped(hand[3], ui.play.plan.regions.encounter.get_center())
	_ok(ui.draft.to_action() == before, "%s: a drag let go elsewhere changes nothing" % where)
	# The keyboard: pick the first card on screen, aim with Tab, put with Space.
	await _settle()
	var first: String = ui.vs.places[0].card_id
	ui._unhandled_key_input(_key(KEY_1))
	_ok(ui.draft.held == first, "%s: 1 picks the leftmost card" % where)
	ui._unhandled_key_input(_key(KEY_TAB))
	var aim = ui._key_target
	ui._unhandled_key_input(_key(KEY_SPACE))
	_ok(ui.draft.held == null and typeof(ui.draft.place_of(first, g.hand)) == TYPE_ARRAY, "%s: Space swaps it where Tab aimed (%s)" % [where, str(aim)])
	ui._unhandled_key_input(_key(KEY_2))
	ui._unhandled_key_input(_key(KEY_ESCAPE))
	_ok(ui.draft.held == null, "%s: Escape puts the card down" % where)


func _resize_mid_turn() -> void:
	ui.start_game({"seed": 4, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await _settle()
	var g = ui.game
	ui.dispatch({"type": "card", "id": g.hand[0]})
	ui.dispatch({"type": "put", "target": [0, "spell"]})
	ui.dispatch({"type": "card", "id": g.hand[1]})
	ui.dispatch({"type": "put", "target": [0, "element"]})
	var before: Dictionary = ui.draft.to_action()
	host.size = Vector2i(1280, 720)
	ui._on_resize()
	await process_frame
	await process_frame
	_ok(ui.draft.to_action() == before, "resize keeps the placed cards")
	_ok(ui.play.hand.ids().size() == g.hand.size(), "resize keeps every card on screen")
	_inspect_screen("after resize")
