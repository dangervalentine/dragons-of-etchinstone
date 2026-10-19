extends Control
## The root of the interface. It owns the game, the player's draft and the current
## screen; lays the screen out for the window; turns every press into an intent
## and applies it, to the draft or to the game; and has each change to the game
## shown as a sequence before the next decision.

const CardDB = preload("res://engine/card_db.gd")
const Game = preload("res://engine/game.gd")
const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Draft = preload("res://ui/model/turn_draft.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const Sequencer = preload("res://ui/model/sequencer.gd")
const Solver = preload("res://ui/model/layout_solver.gd")
const Settings = preload("res://ui/model/settings.gd")
const Undo = preload("res://ui/model/upgrade_undo.gd")
const Art = preload("res://ui/model/art.gd")
const Haptics = preload("res://ui/fx/haptics.gd")
const PlayClock = preload("res://ui/model/play_clock.gd")
const PlayHistory = preload("res://ui/model/play_history.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")
const PlayScreen = preload("res://ui/screens/play_screen.gd")
const TitleScreen = preload("res://ui/screens/title_screen.gd")
const RulesScreen = preload("res://ui/screens/rules_screen.gd")
const DragonScreen = preload("res://ui/screens/dragon_screen.gd")
const RecordsScreen = preload("res://ui/screens/records_screen.gd")
const EndingScreen = preload("res://ui/screens/ending_screen.gd")
const Animator = preload("res://ui/fx/animator.gd")
const FlightLayer = preload("res://ui/fx/flight_layer.gd")
const BACKDROP = preload("res://ui/fx/shaders/backdrop.gdshader")
const BackdropLayer = preload("res://ui/fx/backdrop_layer.gd")
const BoardResponse = preload("res://ui/model/board_response.gd")
const InspectOverlay = preload("res://ui/overlays/inspect_overlay.gd")
const GlossaryPopover = preload("res://ui/overlays/glossary_popover.gd")
const RulebookOverlay = preload("res://ui/overlays/rulebook_overlay.gd")
const StageBanner = preload("res://ui/overlays/stage_banner.gd")
const ConfirmDialog = preload("res://ui/overlays/confirm_dialog.gd")
const MenuOverlay = preload("res://ui/overlays/menu_overlay.gd")
const SizeNotice = preload("res://ui/overlays/size_notice.gd")
const WindowSizer = preload("res://ui/model/window_sizer.gd")
const HeaderBar = preload("res://ui/widgets/header_bar.gd")

var db = CardDB.new()
var game: Variant = null
var draft = Draft.new()
## The options of the game in progress, or to start next.
var menu := Settings.DEFAULT_OPTIONS.duplicate()
var vs := {}
var plan := {}

var screen: Control
var play: Control
var animator := Animator.new()
var _screen_host := Control.new()
## The title bar over every screen but the play screen, which has its own in the same
## place, so the menu button never moves.
var title_bar := HeaderBar.new()
var _flight := FlightLayer.new()
var _overlays := Control.new()
var _backdrop := ColorRect.new()
## The stone backdrop's settings.
var backdrop_layer := BackdropLayer.new()
var _backdrop_ether := ""
var _notice: Control = null
var _notice_dismissed := false
var _lost_at := ""
var _last_card := ""
## While a card is held, the place Tab has moved to and Space puts it in.
var _key_target: Variant = null
## Upgrades made in this Upgrade step, newest last, so they can be taken back.
var _undo: Array = []
## For tools: pretend the device has these safe-area insets (design units).
var safe_override := Rect2()
## For tools: pretend the window has this size in pixels.
var window_override := Vector2()
## Whether an upright or unreadably small window gets the size notice: only on the
## web, where a browser can be held or dragged upright. The app is held landscape,
## and a desktop window still shows the whole game, letterboxed.
var notice_applies := OS.has_feature("web")
## The device's safe area when the layout was last made, to notice it moving.
var _device_safe := Rect2i()
## What the layout was last made for; a window drag that changes none of it changes nothing.
var _layout_key := []
## Active play time of the game in progress.
var clock = PlayClock.new()
var _started_at := 0
## Whether the game in progress has been recorded; a game is recorded once.
var _recorded := false
var _focused := true
## The screen the Leaderboard or History was opened from: "title", "dragons",
## "rules", "ending" or "game".
var _records_from := "title"
## The record the last game left, and where it placed.
var _last_record := {}
var _placing := {}


func _ready() -> void:
	theme = UI.build_theme()
	Settings.load_all()
	if _owns_window():
		WindowSizer.apply(Settings.window_mode)
	HistoryStore.load_all()
	menu = Settings.last_options.duplicate()
	# Options remembered from an older version may name a dragon or difficulty that is gone.
	if not db.dragon_ids().has(menu.get("dragon")):
		menu.dragon = Settings.DEFAULT_OPTIONS.dragon
	if not Game.DIFFICULTY.has(menu.get("difficulty")):
		menu.difficulty = Settings.DEFAULT_OPTIONS.difficulty
	# The system back gesture steps back through setup; elsewhere it still quits.
	get_tree().quit_on_go_back = false
	UI.reduced_motion = Settings.reduced_motion()
	var backdrop := _backdrop
	backdrop.material = ShaderMaterial.new()
	backdrop.material.shader = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	add_child(backdrop_layer)
	backdrop_layer.setup(backdrop.material)
	for layer in [_screen_host, _flight, _overlays]:
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(layer)
		if layer == _screen_host:
			add_child(title_bar)
	# Cards rise over the rest of the screen by z_index (held 1, dragged 2, played 5),
	# which outranks the order the layers are added in, so the overlays sit higher still.
	_overlays.z_index = 10
	title_bar.intent.connect(dispatch)
	# Cards under an overlay hold still, so only what can be seen is animated.
	_overlays.child_entered_tree.connect(func(_n):
		_fields_live.call_deferred()
		_save_marker.call_deferred())
	_overlays.child_exiting_tree.connect(func(_n): _fields_live.call_deferred())
	animator.flight = _flight
	animator.show_banner = _banner
	animator.respond = _respond
	animator.finished.connect(_on_sequence_done)
	add_child(animator)
	get_window().size_changed.connect(_on_resize)
	# Turning a phone end over end moves its notch to the other side without changing
	# the window's size, and the safe area can settle after launch, so watch it too.
	if OS.has_feature("mobile"):
		var watch := Timer.new()
		watch.wait_time = 0.25
		watch.timeout.connect(_check_safe_area)
		add_child(watch)
		watch.start()
	_show_title()
	_on_resize.call_deferred()


# ---------------------------------------------------------------- layout

## Whether the game sizes its own window: on a desktop, when it is the running scene
## (tools that load it size the window themselves).
func _owns_window() -> bool:
	return WindowSizer.applies() and is_inside_tree() and get_tree().current_scene == self


## The window's size in pixels.
func _window_px() -> Vector2:
	if window_override != Vector2.ZERO:
		return window_override
	return Vector2(DisplayServer.window_get_size())


## The part of the viewport clear of notches and the home indicator, in design units.
## A letterbox round the play area is outside the view, so whatever of the unsafe
## edge falls in it is left out already; a view that fills the screen has none.
func _safe_rect(view: Vector2) -> Rect2:
	if safe_override.size != Vector2.ZERO:
		return safe_override
	if not OS.has_feature("mobile"):
		return Rect2(Vector2.ZERO, view)
	var window := _window_px()
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if window.x <= 0 or safe.size.x <= 0:
		return Rect2(Vector2.ZERO, view)
	safe = Solver.clear_corners(safe, window, _corner_radii())
	return Solver.safe_in_view(window, safe, view)


## The screen's corner radii in pixels (top left, top right, bottom right, bottom
## left), which the safe area leaves out. Only Android 12 and later reports them; on
## iOS the safe area already keeps clear of the corners in landscape.
func _corner_radii() -> Array:
	var none := [0, 0, 0, 0]
	if OS.get_name() != "Android" or OS.get_version().to_int() < 12 or not Engine.has_singleton("AndroidRuntime"):
		return none
	var activity = Engine.get_singleton("AndroidRuntime").getActivity()
	var insets = activity.getWindow().getDecorView().getRootWindowInsets() if activity != null else null
	if insets == null:
		return none
	var out := []
	for position in 4:
		var corner = insets.getRoundedCorner(position)
		out.append(float(corner.getRadius()) if corner != null else 0.0)
	return out


func _check_safe_area() -> void:
	if DisplayServer.get_display_safe_area() != _device_safe:
		_on_resize()


func _points_per_unit(view: Vector2) -> float:
	var window := _window_px()
	var scale := DisplayServer.screen_get_scale()
	if window.x <= 0 or scale <= 0:
		return 0.5
	return Solver.stage_for_window(window, view).size.x / view.x / scale


func _on_resize() -> void:
	# The OS can take the window in or out of full screen itself; the setting follows.
	if _owns_window() and WindowSizer.current_mode() != Settings.window_mode:
		Settings.window_mode = WindowSizer.current_mode()
		Settings.save_all()
		_refresh_menu()
	var view := get_viewport_rect().size
	_device_safe = DisplayServer.get_display_safe_area()
	var safe := _safe_rect(view)
	var count: int = vs.hand.size() if not vs.is_empty() and vs.has("hand") else 4
	var places: int = Solver.place_count(vs)
	var final: bool = Solver.is_final(vs)
	var ppu := _points_per_unit(view)
	var window := _window_px()
	var upright := window.y > window.x
	var key := [view, safe, ppu, upright, count, places, final]
	if key == _layout_key:
		_update_notice()
		return
	_layout_key = key
	animator.skip()
	plan = Solver.solve(view, safe, count, places, ppu, upright, final)
	plan["safe"] = safe
	plan["undersized_upright"] = upright
	plan["for"] = [count, places, final]
	if screen != null:
		if screen == play:
			play.apply_layout(plan)
		else:
			screen.apply_layout(plan.body)
	_place_title_bar()
	for o in _overlays.get_children():
		if o.has_method("close") and o.get_script() == InspectOverlay:
			o.close()
		elif o.get_script() == RulebookOverlay and not o.is_queued_for_deletion():
			o.relayout(plan.content.grow(-T.M))
	_update_notice()


## Show an open settings menu the window mode as it is now.
func _refresh_menu() -> void:
	for o in _overlays.get_children():
		if o.get_script() == MenuOverlay:
			o._refresh()


func _update_notice() -> void:
	var under: bool = notice_applies and plan.get("undersized", false)
	if not under:
		_notice_dismissed = false
	if under and _notice == null and not _notice_dismissed:
		_notice = SizeNotice.new()
		_notice.dismissed.connect(func():
			_notice_dismissed = true
			_notice.queue_free()
			_notice = null)
		add_child(_notice)
	if _notice != null:
		if not under:
			_notice.queue_free()
			_notice = null
		else:
			var c: Rect2 = plan.content
			_notice.reset_size()
			_notice.size.x = minf(c.size.x, 1100.0)
			_notice.position = Vector2(c.position.x + (c.size.x - _notice.size.x) / 2.0, c.position.y)


# ---------------------------------------------------------------- screens

func _switch(to: Control) -> void:
	var old := screen
	screen = to
	# Feature 006: every screen stands on the same ground.
	backdrop_layer.set_stone(true)
	_screen_host.add_child(to)
	to.set_anchors_preset(Control.PRESET_FULL_RECT)
	if old != null:
		if UI.reduced_motion or not is_inside_tree():
			old.queue_free()
		else:
			var tw := create_tween()
			tw.tween_property(old, "modulate:a", 0.0, T.BASE)
			tw.tween_callback(old.queue_free)
			to.modulate.a = 0.0
			create_tween().tween_property(to, "modulate:a", 1.0, T.BASE)
	if not plan.is_empty():
		if to == play:
			play.apply_layout(plan)
		else:
			to.apply_layout(plan.body)
	_place_title_bar()


## The title bar shows the screen's name, where the play screen's header would be.
func _place_title_bar() -> void:
	title_bar.visible = screen != null and screen != play
	if not title_bar.visible:
		return
	title_bar.set_title(screen.heading, screen.has_method("back"))
	if not plan.is_empty():
		title_bar.position = plan.regions.header.position
		title_bar.size = plan.regions.header.size


func _show_title() -> void:
	game = null
	vs = {}
	play = null
	var t := TitleScreen.new()
	t.setup(db, menu)
	t.intent.connect(dispatch)
	_switch(t)


func _show_dragons() -> void:
	game = null
	vs = {}
	play = null
	var d := DragonScreen.new()
	d.setup(db, menu)
	d.intent.connect(dispatch)
	_switch(d)


func _show_rules() -> void:
	game = null
	vs = {}
	play = null
	var r := RulesScreen.new()
	r.setup(db, menu)
	r.intent.connect(dispatch)
	_switch(r)


## The Leaderboard or History opens on the difficulty last chosen. The game, if one
## is in progress or has just ended, is kept so it can be shown again on the way back.
func _show_records(page: String) -> void:
	var r := RecordsScreen.new()
	r.setup(db, menu.difficulty, page)
	r.intent.connect(dispatch)
	_switch(r)


## Back to the game in progress, as it was left.
func _resume_play() -> void:
	play = PlayScreen.new()
	play.flight = _flight
	play.intent.connect(dispatch)
	_switch(play)
	_refresh(false)


## The screen showing now, by the name the records pages go back to.
func _screen_name() -> String:
	if play != null and screen == play:
		return "game"
	match screen.get_script() if screen != null else null:
		EndingScreen:
			return "ending"
		DragonScreen:
			return "dragons"
		RulesScreen:
			return "rules"
		RecordsScreen:
			return "records"
	return "title"


func _show_ending() -> void:
	var e := EndingScreen.new()
	e.intent.connect(dispatch)
	_switch(e)
	e.render(vs)
	_place_title_bar()


func start_game(opts: Dictionary) -> void:
	menu = opts.duplicate()
	menu.erase("seed")
	Settings.last_options = menu.duplicate()
	Settings.save_all()
	var with_seed := opts.duplicate()
	if not with_seed.has("seed"):
		with_seed["seed"] = randi()
	var empty := {"phase": "setup", "region": 1, "deck": [], "hand": [], "discard": [], "trash": [], "levels": {}, "offer": []}
	# A game still in progress is left for the new one.
	if game != null and game.phase != "won" and game.phase != "lost":
		_record("abandoned")
	game = Game.new(db, with_seed)
	clock.reset()
	_started_at = int(Time.get_unix_time_from_system())
	_recorded = false
	_last_record = {}
	_placing = {}
	_save_marker()
	_lost_at = ""
	_undo.clear()
	_reset_draft()
	play = PlayScreen.new()
	play.flight = _flight
	play.intent.connect(dispatch)
	_switch(play)
	_refresh(false)
	if game.phase == "challenge":
		for id in game.cards:
			empty.levels[id] = game.cards[id].level
		var after := ViewState.snapshot(game)
		var steps := Sequencer.build(empty, {"kind": "start", "cards": []}, {}, after)
		# Start from an empty Hand so the first one is dealt.
		var bare: Dictionary = vs.duplicate()
		bare.hand = []
		play.render(bare)
		# The Deck starts zoomed out on the Region Card, for the first reveal.
		play.deck.show_card()
		animator.play(steps, play, vs)


## Rebuild the view state and show it. `animate` lets cards glide to new places.
func _refresh(animate := true, show := true) -> void:
	if game == null:
		return
	var previous = vs.get("preview") if not vs.is_empty() else null
	var placing: Array = PlayHistory.placing_lines(_placing, _last_record) if not _placing.is_empty() else []
	if draft.held == null:
		_key_target = null
	vs = ViewState.build(game, draft, db, {"previous_preview": previous, "lost_at": _lost_at, "undo": _undo.size(), "placing": placing, "key_target": _key_target})
	if show and play != null and screen == play and not animator.is_playing():
		play.render(vs, animate)
		_tint_backdrop(vs)


# ---------------------------------------------------------------- intents

## Every press arrives here as {type, ...}.
func dispatch(intent: Dictionary) -> void:
	if animator.is_playing():
		animator.skip()
		return
	match intent.type:
		"start":
			start_game(intent.options)
		"play_again":
			start_game(menu)
		"to_title":
			if intent.has("options"):
				menu = intent.options.duplicate()
			_show_title()
		"setup_rules":
			menu = intent.options.duplicate()
			_show_rules()
		"setup_dragon":
			menu = intent.options.duplicate()
			_show_dragons()
		"records":
			var from: String = intent.get("from", "title")
			if from == "menu":
				from = _screen_name()
			# From one records page to the other, Back still goes where the first came from.
			if from != "records":
				_records_from = from
			_show_records(intent.get("page", "leaderboard"))
		"records_clear":
			var c := ConfirmDialog.new()
			_overlays.add_child(c)
			c.setup("Clear every recorded game? This cannot be undone.", "Clear records", "Keep them")
			c.confirmed.connect(func():
				HistoryStore.clear_all()
				_close_overlays()
				if screen != null and screen.get_script() == RecordsScreen:
					screen.refresh())
		"records_back":
			if _records_from == "ending" and game != null:
				_show_ending()
			elif _records_from == "game" and game != null:
				_resume_play()
			elif _records_from == "dragons":
				_show_dragons()
			elif _records_from == "rules":
				_show_rules()
			else:
				_show_title()
		"back":
			if screen != null and screen.has_method("back"):
				screen.back()
		"ground":
			backdrop_layer.refresh_ground()
		"menu":
			_open_menu(play != null and screen == play)
		"glossary":
			var g := GlossaryPopover.new()
			_overlays.add_child(g)
			g.show_all(plan.content.grow(-T.M))
			_return_to_menu(g, intent)
		"rulebook":
			var r := RulebookOverlay.new()
			_overlays.add_child(r)
			r.intent.connect(dispatch)
			r.open(plan.content.grow(-T.M), intent.get("section", ""), db)
			_return_to_menu(r, intent)
		"leave":
			var c := ConfirmDialog.new()
			_overlays.add_child(c)
			c.setup("Abandon this run? It cannot be resumed.", "Abandon run", "Keep playing")
			c.confirmed.connect(func():
				_record("abandoned")
				_close_overlays()
				_show_title())
		"help":
			var source: Control = intent.get("source")
			var anchor: Rect2 = source.get_global_rect() if source != null else Rect2(plan.content.get_center(), Vector2.ZERO)
			var g := GlossaryPopover.new()
			_overlays.add_child(g)
			g.show_entry(intent.id, anchor, plan.content)
		"inspect_key":
			_inspect_key()
		"inspect":
			_inspect(intent.id)
		"card":
			_last_card = intent.id
			_on_card(intent.id)
		"pick":
			_last_card = intent.id
			var err: String = draft.pick(intent.id)
			_refresh()
			if err != "":
				_refuse(err, intent.id)
		"put":
			_put(intent.target)
		"drag_put":
			draft.held = null
			var err: String = draft.pick(intent.id)
			if err != "":
				_refresh()
				_refuse(err, intent.id)
			else:
				_put(intent.target)
		"put_down":
			draft.put_down()
			_refresh()
		"toggle_give_up_reserve":
			draft.give_up_reserve = not draft.give_up_reserve
			_refresh()
		"set_boost_to":
			draft.set_boost_to(intent.set, intent.to)
			_refresh()
		"toggle_boost_to":
			draft.toggle_boost_to(intent.set)
			_refresh()
		"fuse_element":
			draft.choose_fuse_element(intent.element)
			draft.settle(game.hand)
			_refresh(true)
			_respond("fuse", intent.element)
		"action":
			_on_action(intent.id)
		"primary":
			_on_primary()


func _on_card(id: String) -> void:
	if game == null:
		return
	match game.phase:
		"setup":
			if draft.picks.has(id) or draft.picks.size() < game.setup_picks:
				draft.toggle_pick(id)
				_refresh()
			else:
				_refuse("You have chosen %d. Tap a chosen card to swap it." % game.setup_picks, id)
		"penalty", "poison", "final_soak":
			var card: Dictionary = vs.cards.get(id, {})
			if draft.picks.has(id) or card.get("eligible", false):
				draft.toggle_pick(id)
				_refresh()
				if draft.picks.has(id):
					_respond("soak")
			else:
				_refuse("That card cannot Soak: %s." % card.get("reason", "").to_lower(), id)
		"upgrade":
			var entry := Undo.record(game, id)
			_undo.append(entry)
			var level: int = game.cards[id].level
			_act({"kind": "upgrade", "cards": [id], "id": id}, func(): return game.upgrade(id))
			if game.cards[id].level == level:
				_undo.erase(entry)
				_refresh(false)
		"challenge", "final_journey", "final_enemy":
			match draft.mode:
				"divert":
					_respond("divert")
					_act({"kind": "divert", "cards": [id], "id": id}, func(): return game.divert(id))
				"regroup":
					_respond("regroup")
					_act({"kind": "regroup", "cards": [id], "id": id}, func(): return game.regroup(id))
				"fuse_pick":
					var err: String = draft.pick_for_fuse(id, db)
					_refresh()
					if err != "":
						_refuse(err, id)
				"fuse_element":
					_refuse("Choose the Ether for the fused card.", id)
				_:
					# A card is picked up, then another tapped: the two trade places.
					if draft.held != null and draft.held != id:
						_put({"card": id})
						return
					var err: String = draft.pick(id)
					_refresh()
					if err != "":
						_refuse(err, id)


## Put the held card at `target` ([set, role], "reserve", or {"card": id} for that
## card's place) and answer on the board: the card it displaced, if any, moves too.
func _put(target: Variant) -> void:
	var id = draft.held
	if id == null or game == null:
		return
	var before: Dictionary = {}
	for other in game.hand:
		before[other] = draft.place_of(other, game.hand)
	var err: String = draft.put(target, game.hand)
	_refresh()
	if err != "":
		_refuse(err, id)
		return
	var moved := 0
	for other in game.hand:
		var now = draft.place_of(other, game.hand)
		if typeof(now) == typeof(before[other]) and now == before[other]:
			continue
		if moved == 0:
			_respond("place", db.mage(other).element, other)
		else:
			var later: String = other
			get_tree().create_timer(T.STAGGER).timeout.connect(func(): _respond("place", db.mage(later).element, later))
		moved += 1


func _on_action(id: String) -> void:
	match id:
		"fuse":
			if draft.fuse != null or draft.mode.begins_with("fuse"):
				draft.unfuse()
				draft.settle(game.hand)
			else:
				draft.begin_mode("fuse_pick")
		"divert", "regroup":
			draft.begin_mode(id)
		"give_up_reserve":
			draft.give_up_reserve = not draft.give_up_reserve
		"undo":
			if not _undo.is_empty():
				var entry: Dictionary = _undo.pop_back()
				_act({"kind": "upgrade", "cards": [entry.id], "id": entry.id}, func():
					Undo.undo(game, entry)
					return "")
				return
		"cancel":
			draft.cancel_mode()
	_refresh()


func _on_primary() -> void:
	if game == null or vs.is_empty():
		return
	if not vs.prompt.primary.enabled:
		# Play pressed too soon: say what is still missing.
		var reason: String = vs.prompt.primary.reason
		if reason != "":
			_refuse(reason)
		return
	match game.phase:
		"setup":
			var picks: Array = draft.picks.duplicate()
			_act({"kind": "setup", "cards": picks}, func(): return game.choose_setup_cards(picks))
		"challenge":
			var a: Dictionary = draft.to_action()
			_act({"kind": "play", "cards": _played(a)}, func(): return game.play(a))
		"final_journey", "final_enemy":
			var a: Dictionary = draft.to_action()
			_lost_at = "the Final Journey" if game.phase == "final_journey" else "the Final Enemy"
			_act({"kind": "play_final", "cards": _played(a)}, func(): return game.play_final(a))
		"penalty", "poison", "final_soak":
			var picks: Array = draft.picks.duplicate()
			_act({"kind": "soak", "cards": picks}, func(): return game.soak(picks))
		"upgrade":
			var affordable := false
			for id in vs.hand:
				affordable = affordable or vs.cards[id].get("eligible", false)
			if Settings.warn_unspent_xp and game.xp > 0 and affordable:
				_confirm_unspent_xp()
				return
			_finish_upgrade()


## Before leaving the Upgrade step with XP that could still Upgrade a card: ask, with
## a box to stop asking.
func _confirm_unspent_xp() -> void:
	var c := ConfirmDialog.new()
	_overlays.add_child(c)
	c.setup("You have %d XP left, enough to Upgrade a card. Unspent XP is lost. Continue anyway?" % game.xp,
		"Continue anyway", "Keep upgrading", "Don't show this again")
	c.confirmed.connect(_finish_upgrade)
	c.tree_exiting.connect(func():
		if c.opted_out:
			Settings.warn_unspent_xp = false
			Settings.save_all())


func _finish_upgrade() -> void:
	if game == null or game.phase != "upgrade":
		return
	var spent: Array = game._action.cards.values()
	if game._action.fuse != null:
		spent.append(game._action.fuse.bottom)
	if game._discard_reserve and game._action.reserve != null:
		spent.append(game._action.reserve)
	_act({"kind": "finish", "cards": spent}, func(): return game.finish())


func _played(a: Dictionary) -> Array:
	var out := []
	for s in a.get("sets", [a]):
		for role in Draft.ROLES:
			if s.get(role) != null:
				out.append(s[role])
	return out


## Apply an action to the game, then show what it did.
func _act(action: Dictionary, call: Callable) -> void:
	var before := ViewState.snapshot(game)
	var phase_before: String = game.phase
	var err: String = call.call()
	if err != "":
		_refuse(err, action.get("id", ""))
		return
	if game.phase == "won" or game.phase == "lost":
		_record(game.phase)
	else:
		_save_marker()
	var after := ViewState.snapshot(game)
	if game.phase != "upgrade":
		_undo.clear()
	match action.kind:
		"divert":
			draft.drop(action.id)
			draft.cancel_mode()
			draft.settle(game.hand)
		"upgrade":
			pass
		_:
			_reset_draft()
	if game.phase != phase_before and (game.phase == "challenge" or game.phase.begins_with("final")):
		_reset_draft()
	var steps := Sequencer.build(before, action, game.result, after)
	_refresh(false, false)
	if steps.is_empty():
		play.render(vs, true)
		_tint_backdrop(vs)
		return
	animator.play(steps, play, vs)


## A new draft for the game's current step. Building a set starts from the Hand dealt
## into its places in draw order.
func _reset_draft() -> void:
	draft.reset(2 if game.phase == "final_journey" or game.phase == "final_enemy" else 1, game.phase != "final_enemy")
	if game.phase == "challenge" or game.phase == "final_journey" or game.phase == "final_enemy":
		draft.deal(game.hand)


func _on_sequence_done() -> void:
	if game != null and (game.phase == "won" or game.phase == "lost"):
		_show_ending()


func _refuse(text: String, card_id := "") -> void:
	if play == null:
		return
	play.refuse(text)
	Haptics.refuse()
	var view: Control = play.hand.card(card_id) if card_id != "" else null
	if view != null:
		UI.shake(view)


## The backdrop takes on a little of the Encounter's Ether behind it.
func _tint_backdrop(state: Dictionary) -> void:
	var enc = state.get("encounter")
	var ether: String = str(enc.element) if enc != null and enc.element != null else ""
	if ether == _backdrop_ether:
		return
	_backdrop_ether = ether
	var m: ShaderMaterial = _backdrop.material
	var to := 1.0 if ether != "" else 0.0
	if ether != "":
		m.set_shader_parameter("ether_tint", T.ether_shade(ether, "deep").lightened(0.2))
	if Settings.reduced_motion() or not is_inside_tree():
		m.set_shader_parameter("tint_amount", to)
		return
	var set = m.get_shader_parameter("tint_amount")
	var from: float = set if set != null else 0.0
	create_tween().tween_method(func(v): m.set_shader_parameter("tint_amount", v), from, to, T.BASE)


## Cards' Ether fields move only while no overlay covers the play screen.
func _fields_live() -> void:
	var live := _overlays.get_child_count() == 0
	if play != null and is_instance_valid(play):
		play.set_fields_live(live)


## The board answers an event (contracts/board-life.md) at a zone's rim on the
## play screen. `ether` colours it where the table says so.
func _respond(event: String, ether = null, card_id := "") -> void:
	if play == null or screen != play or not BoardResponse.TABLE.has(event):
		return
	var r: Dictionary = BoardResponse.TABLE[event]
	var colour: Color
	match r.colour:
		"ether":
			colour = T.ether_shade(ether, "lit") if ether != null and ether != "" else T.RESPONSE_NEUTRAL
		"focus":
			colour = T.FOCUS
		"gold":
			colour = T.GOLD
		"bad":
			colour = T.BAD
		_:
			colour = T.RESPONSE_NEUTRAL
	play.flare(r.target, colour, r.motion.kind, r.motion.duration, card_id)


# ---------------------------------------------------------------- overlays

func _banner(values: Dictionary, duration: float) -> void:
	var b := StageBanner.new()
	_overlays.add_child(b)
	if values.phase == "final_journey" or values.phase == "final_enemy":
		var d: Dictionary = game.dragon
		var art_name: String = Art.dragon(d.id)
		b.show_banner("%s, %s" % [d.name, d.title], "The Final Journey" if values.phase == "final_journey" else "The Final Enemy",
			UI.art_crop(art_name, Art.head(art_name)), T.ether(d.early_damage.element), duration)
	else:
		b.show_banner("Region %d" % values.region, db.region(values.region).name, "sigil_region", T.GOLD, duration)


## The Key Card that named the Encounter on show, at its Levels, its Key Card part
## lifted: what pressing the Encounter face opens.
func _inspect_key() -> void:
	var enc = vs.get("encounter") if not vs.is_empty() else null
	if enc == null or not enc.has("key_card") or not enc.key_card.has("id"):
		return
	var top := _top_overlay()
	if top != null and top.get_script() == InspectOverlay:
		return
	var o := InspectOverlay.new()
	_overlays.add_child(o)
	o.setup(db, {"id": enc.key_card.id, "level": enc.key_card.level}, plan.content, true)


func _inspect(id: String) -> void:
	if vs.is_empty() or not vs.cards.has(id):
		return
	var o := InspectOverlay.new()
	_overlays.add_child(o)
	o.setup(db, vs.cards[id], plan.content)


## An overlay opened from the Settings menu reopens it when closed, as the X or
## Escape leaves it; one opened any other way just closes.
func _return_to_menu(o: Control, intent: Dictionary) -> void:
	if intent.get("from", "") == "menu":
		var in_game := play != null and screen == play
		o.closed.connect(func(): _open_menu(in_game))


func _open_menu(in_game: bool) -> void:
	var m := MenuOverlay.new()
	_overlays.add_child(m)
	m.setup(in_game, plan.content)
	m.intent.connect(dispatch)


func _close_overlays() -> void:
	for o in _overlays.get_children():
		o.queue_free()


func _top_overlay() -> Control:
	var n := _overlays.get_child_count()
	for i in range(n - 1, -1, -1):
		var o := _overlays.get_child(i)
		if not o.is_queued_for_deletion() and o.get_script() != StageBanner:
			return o
	return null


# ---------------------------------------------------------------- play records

func _process(_delta: float) -> void:
	clock.tick(Time.get_ticks_msec(), _clock_active())


## Whether the game counts as being played: in front, focused, and not under the
## menu, rulebook, glossary or a dialog. Looking at a card and the game's own
## banners are part of playing.
func _clock_active() -> bool:
	if game == null or game.phase == "won" or game.phase == "lost" or screen != play or not _focused:
		return false
	var top := _top_overlay()
	return top == null or top.get_script() == InspectOverlay or top.get_script() == SizeNotice


## Keep the game in progress, so it is recorded even if the app does not live to
## see it end.
func _save_marker() -> void:
	if game == null or _recorded or game.phase == "won" or game.phase == "lost":
		return
	HistoryStore.save_marker(PlayHistory.marker_for(game, clock.elapsed_ms, _started_at, int(Time.get_unix_time_from_system())))


## Record the game in progress as won, lost or abandoned; once only.
func _record(outcome: String) -> void:
	if game == null or _recorded:
		return
	_recorded = true
	var now := int(Time.get_unix_time_from_system())
	_last_record = HistoryStore.append(PlayHistory.record_for(game, outcome, clock.elapsed_ms, _started_at, now))
	HistoryStore.clear_marker()
	_placing = PlayHistory.placing(HistoryStore.records, _last_record)


# ---------------------------------------------------------------- keyboard and skipping

## The frame of the last press that hurried a sequence on (_input).
var _pressed_frame := -1


func _input(event: InputEvent) -> void:
	# Before anything else: Alt+Enter must not reach a focused button as Enter, and
	# F11 must not also skip a sequence.
	if _owns_window() and event.is_action_pressed("toggle_fullscreen") and not event.is_echo():
		WindowSizer.toggle()
		_refresh_menu()
		get_viewport().set_input_as_handled()
		return
	# While a sequence plays, a press of anything hurries it on and does nothing else:
	# to the Key Card waiting with its Encounter lit, or from there on (specs/014).
	# One tap is one press: on a touch screen the touch also arrives as an emulated
	# mouse click, which would otherwise go on from the Key Card and then skip the zoom.
	if animator.is_playing():
		var press: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventScreenTouch and event.pressed)
		if press:
			var echo: bool = (event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION) \
				or Engine.get_process_frames() == _pressed_frame
			if not echo:
				_pressed_frame = Engine.get_process_frames()
				animator.press()
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.keycode
	var top := _top_overlay()
	if key == KEY_ESCAPE:
		if top != null:
			top.close()
		elif screen != null and (screen.get_script() in [RulesScreen, RecordsScreen, DragonScreen]):
			screen.back()
		elif play != null and screen == play and draft.held != null:
			dispatch({"type": "put_down"})
		elif play != null and screen == play and draft.mode != "none":
			dispatch({"type": "action", "id": "cancel"})
		elif play != null and screen == play:
			dispatch({"type": "menu"})
		get_viewport().set_input_as_handled()
		return
	if top != null:
		return
	if key == KEY_QUESTION or (key == KEY_SLASH and event.shift_pressed):
		dispatch({"type": "glossary"})
	elif key == KEY_H:
		dispatch({"type": "rulebook"})
	elif play == null or screen != play:
		return
	elif key >= KEY_1 and key <= KEY_9:
		# Cards count as they sit on screen: the places from the left, then any card
		# in no place (setup and Soak).
		var order: Array = []
		for p in vs.get("places", []):
			if p.card_id != null:
				order.append(p.card_id)
		for id in vs.get("unplaced", vs.hand):
			if not order.has(id):
				order.append(id)
		var i := key - KEY_1
		if i < order.size():
			dispatch({"type": "card", "id": order[i]})
	elif key == KEY_TAB and draft.held != null:
		# Move the target across the places that can take the held card.
		var targets: Array = []
		for p in vs.get("places", []):
			if p.state == "target" and p.tap != null and p.tap.type == "put":
				targets.append(p.tap.target)
		if targets.is_empty():
			return
		var at: int = targets.find(_key_target)
		var step := -1 if event.shift_pressed else 1
		_key_target = targets[(at + step + targets.size()) % targets.size()] if at >= 0 else targets[0 if step > 0 else targets.size() - 1]
		_refresh(false)
	elif key == KEY_SPACE and draft.held != null and _key_target != null:
		dispatch({"type": "put", "target": _key_target})
	elif key == KEY_R:
		if vs.get("secondary", []).any(func(a): return a != null and a.id == "give_up_reserve"):
			dispatch({"type": "toggle_give_up_reserve"})
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		dispatch({"type": "primary"})
	elif key == KEY_B:
		# The keyboard's aim: the held Boost's set, else the first unaimed, Attack
		# first and then back and forth.
		var i: int = draft.boost_target_set(draft.held)
		if not vs.sets.is_empty() and vs.sets[0].show_boost_to:
			if i < 0:
				_refuse("Pick up a Boost card, then press B.")
			else:
				dispatch({"type": "toggle_boost_to", "set": i})
	elif key == KEY_I:
		var id: String = _last_card if vs.cards.has(_last_card) else (vs.hand[0] if not vs.hand.is_empty() else "")
		if id != "":
			_inspect(id)
	else:
		return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_save_marker()
		if animator != null:
			animator.skip()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_record("abandoned")
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var top := _top_overlay()
		if top != null:
			top.close()
		elif screen != null and (screen.get_script() in [RulesScreen, RecordsScreen, DragonScreen]):
			screen.back()
		else:
			_record("abandoned")
			get_tree().quit()
