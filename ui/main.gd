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
const PlayScreen = preload("res://ui/screens/play_screen.gd")
const TitleScreen = preload("res://ui/screens/title_screen.gd")
const EndingScreen = preload("res://ui/screens/ending_screen.gd")
const Animator = preload("res://ui/fx/animator.gd")
const FlightLayer = preload("res://ui/fx/flight_layer.gd")
const BACKDROP = preload("res://ui/fx/shaders/backdrop.gdshader")
const InspectOverlay = preload("res://ui/overlays/inspect_overlay.gd")
const GlossaryPopover = preload("res://ui/overlays/glossary_popover.gd")
const StageBanner = preload("res://ui/overlays/stage_banner.gd")
const ConfirmDialog = preload("res://ui/overlays/confirm_dialog.gd")
const MenuOverlay = preload("res://ui/overlays/menu_overlay.gd")
const SizeNotice = preload("res://ui/overlays/size_notice.gd")

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
var _flight := FlightLayer.new()
var _overlays := Control.new()
var _notice: Control = null
var _notice_dismissed := false
var _lost_at := ""
var _last_card := ""
## Upgrades made in this Upgrade step, newest last, so they can be taken back.
var _undo: Array = []
## For tools: pretend the device has these safe-area insets (design units).
var safe_override := Rect2()


func _ready() -> void:
	theme = UI.build_theme()
	Settings.load_all()
	menu = Settings.last_options.duplicate()
	UI.reduced_motion = Settings.reduced_motion()
	var backdrop := ColorRect.new()
	backdrop.material = ShaderMaterial.new()
	backdrop.material.shader = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	for layer in [_screen_host, _flight, _overlays]:
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(layer)
	animator.flight = _flight
	animator.show_banner = _banner
	animator.finished.connect(_on_sequence_done)
	add_child(animator)
	get_window().size_changed.connect(_on_resize)
	_show_title()
	_on_resize.call_deferred()


# ---------------------------------------------------------------- layout

## The part of the viewport clear of notches and the home indicator, in design units.
func _safe_rect(view: Vector2) -> Rect2:
	if safe_override.size != Vector2.ZERO:
		return safe_override
	if not OS.has_feature("mobile"):
		return Rect2(Vector2.ZERO, view)
	var window := Vector2(DisplayServer.window_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if window.x <= 0 or safe.size.x <= 0:
		return Rect2(Vector2.ZERO, view)
	var k := view.x / window.x
	return Rect2(safe.position * k, safe.size * k).intersection(Rect2(Vector2.ZERO, view))


func _points_per_unit(view: Vector2) -> float:
	var window := Vector2(DisplayServer.window_get_size())
	var scale := DisplayServer.screen_get_scale()
	if window.x <= 0 or scale <= 0:
		return 0.5
	return window.x / view.x / scale


func _on_resize() -> void:
	animator.skip()
	var view := get_viewport_rect().size
	var safe := _safe_rect(view)
	var count: int = vs.hand.size() if not vs.is_empty() and vs.has("hand") else 4
	var sets: int = maxi(1, vs.sets.size()) if not vs.is_empty() else 1
	plan = Solver.solve(view, safe, count, sets, _points_per_unit(view))
	plan["safe"] = safe
	plan["for"] = [count, sets]
	if screen != null:
		if screen == play:
			play.apply_layout(plan)
		else:
			screen.apply_layout(plan.content)
	for o in _overlays.get_children():
		if o.has_method("close") and o.get_script() == InspectOverlay:
			o.close()
	_update_notice()


func _update_notice() -> void:
	var under: bool = plan.get("undersized", false)
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
			var view := get_viewport_rect().size
			_notice.reset_size()
			_notice.size.x = minf(view.x - 2 * T.M, 1100.0)
			_notice.position = Vector2((view.x - _notice.size.x) / 2.0, maxf(T.M, plan.content.position.y - _notice.size.y - T.M))


# ---------------------------------------------------------------- screens

func _switch(to: Control) -> void:
	var old := screen
	screen = to
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
			to.apply_layout(plan.content)


func _show_title() -> void:
	game = null
	vs = {}
	play = null
	var t := TitleScreen.new()
	t.setup(db, menu)
	t.intent.connect(dispatch)
	_switch(t)


func _show_ending() -> void:
	var e := EndingScreen.new()
	e.intent.connect(dispatch)
	_switch(e)
	e.render(vs)


func start_game(opts: Dictionary) -> void:
	menu = opts.duplicate()
	menu.erase("seed")
	Settings.last_options = menu.duplicate()
	Settings.save_all()
	var with_seed := opts.duplicate()
	if not with_seed.has("seed"):
		with_seed["seed"] = randi()
	var empty := {"phase": "setup", "region": 1, "deck": [], "hand": [], "discard": [], "trash": [], "levels": {}, "offer": []}
	game = Game.new(db, with_seed)
	_lost_at = ""
	_undo.clear()
	draft.reset(1)
	play = PlayScreen.new()
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
		animator.play(steps, play, vs)


## Rebuild the view state and show it. `animate` lets cards glide to new places.
func _refresh(animate := true, show := true) -> void:
	if game == null:
		return
	var previous = vs.get("preview") if not vs.is_empty() else null
	vs = ViewState.build(game, draft, db, {"previous_preview": previous, "lost_at": _lost_at, "undo": _undo.size()})
	if show and play != null and screen == play and not animator.is_playing():
		play.render(vs, animate)


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
			_show_title()
		"settings":
			_open_menu(false)
		"menu":
			_open_menu(true)
		"glossary":
			var g := GlossaryPopover.new()
			_overlays.add_child(g)
			g.show_all(plan.content.grow(-T.M))
		"leave":
			var c := ConfirmDialog.new()
			_overlays.add_child(c)
			c.setup("Leave this game? It cannot be resumed.", "Leave game", "Keep playing")
			c.confirmed.connect(func():
				_close_overlays()
				_show_title())
		"help":
			var source: Control = intent.get("source")
			var anchor: Rect2 = source.get_global_rect() if source != null else Rect2(plan.content.get_center(), Vector2.ZERO)
			var g := GlossaryPopover.new()
			_overlays.add_child(g)
			g.show_entry(intent.id, anchor, plan.content)
		"inspect":
			_inspect(intent.id)
		"card":
			_last_card = intent.id
			_on_card(intent.id)
		"select_slot":
			draft.select_slot(intent.set, intent.role)
			_refresh()
		"take_back":
			draft.take_back(intent.id)
			_refresh()
		"toggle_boost_to":
			draft.toggle_boost_to(intent.set)
			_refresh()
		"fuse_element":
			draft.choose_fuse_element(intent.element)
			_refresh(true)
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
					_act({"kind": "divert", "cards": [id], "id": id}, func(): return game.divert(id))
				"regroup":
					_act({"kind": "regroup", "cards": [id], "id": id}, func(): return game.regroup(id))
				"fuse_pick":
					var err: String = draft.pick_for_fuse(id, db)
					_refresh()
					if err != "":
						_refuse(err, id)
				"fuse_element":
					_refuse("Choose the Ether for the fused card.", id)
				_:
					var err: String = draft.tap(id)
					_refresh()
					if err != "":
						_refuse(err, id)


func _on_action(id: String) -> void:
	match id:
		"fuse":
			if draft.fuse != null or draft.mode.begins_with("fuse"):
				draft.unfuse()
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
	if game == null or vs.is_empty() or not vs.prompt.primary.enabled:
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
	var after := ViewState.snapshot(game)
	if game.phase != "upgrade":
		_undo.clear()
	match action.kind:
		"divert":
			draft.drop(action.id)
			draft.cancel_mode()
		"upgrade":
			pass
		_:
			draft.reset(2 if game.phase.begins_with("final") and game.phase != "final_soak" else 1)
	if game.phase != phase_before and (game.phase == "challenge" or game.phase.begins_with("final")):
		draft.reset(2 if game.phase == "final_journey" or game.phase == "final_enemy" else 1)
	var steps := Sequencer.build(before, action, game.result, after)
	_refresh(false, false)
	if steps.is_empty():
		play.render(vs, true)
		return
	animator.play(steps, play, vs)


func _on_sequence_done() -> void:
	if game != null and (game.phase == "won" or game.phase == "lost"):
		_show_ending()


func _refuse(text: String, card_id := "") -> void:
	if play == null:
		return
	play.toast(text)
	var view: Control = play.hand.card(card_id) if card_id != "" else null
	if view != null:
		UI.shake(view)


# ---------------------------------------------------------------- overlays

func _banner(values: Dictionary, duration: float) -> void:
	var b := StageBanner.new()
	_overlays.add_child(b)
	if values.phase == "final_journey" or values.phase == "final_enemy":
		var d: Dictionary = game.dragon
		b.show_banner("%s, %s" % [d.name, d.title], "The Final Journey" if values.phase == "final_journey" else "The Final Enemy",
			"sigil_" + d.id, T.ether(d.early_damage.element), duration)
	else:
		b.show_banner("Region %d" % values.region, db.region(values.region).name, "sigil_region", T.GOLD, duration)


func _inspect(id: String) -> void:
	if vs.is_empty() or not vs.cards.has(id):
		return
	var o := InspectOverlay.new()
	_overlays.add_child(o)
	o.setup(db, vs.cards[id], plan.content)


func _open_menu(in_game: bool) -> void:
	var m := MenuOverlay.new()
	_overlays.add_child(m)
	m.setup(in_game)
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


# ---------------------------------------------------------------- keyboard and skipping

func _input(event: InputEvent) -> void:
	# While a sequence plays, the first press of anything finishes it and does nothing else.
	if animator.is_playing():
		var press: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventScreenTouch and event.pressed)
		if press:
			animator.skip()
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.keycode
	var top := _top_overlay()
	if key == KEY_ESCAPE:
		if top != null:
			top.close()
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
	elif play == null or screen != play:
		return
	elif key >= KEY_1 and key <= KEY_7:
		var i := key - KEY_1
		if i < vs.hand.size():
			dispatch({"type": "card", "id": vs.hand[i]})
	elif key == KEY_ENTER or key == KEY_KP_ENTER:
		dispatch({"type": "primary"})
	elif key == KEY_TAB:
		var slots: Array = draft.empty_slots() if not draft.empty_slots().is_empty() else []
		if not vs.sets.is_empty():
			var all := []
			for i in vs.sets.size():
				for role in Draft.ROLES:
					all.append([i, role])
			var at: int = all.find(draft.active)
			var step := -1 if event.shift_pressed else 1
			var next: Array = all[(at + step + all.size()) % all.size()]
			dispatch({"type": "select_slot", "set": next[0], "role": next[1]})
	elif key == KEY_B:
		if not vs.sets.is_empty() and vs.sets[draft.active[0]].show_boost_to:
			dispatch({"type": "toggle_boost_to", "set": draft.active[0]})
	elif key == KEY_I:
		var id: String = _last_card if vs.cards.has(_last_card) else (vs.hand[0] if not vs.hand.is_empty() else "")
		if id != "":
			_inspect(id)
	else:
		return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if animator != null:
			animator.skip()
