extends Node
## Plays the steps of a resolution sequence on the play screen, one after another.
## The game has already changed when a sequence starts; the screen is catching up.
## skip() stops everything and shows the final state at once, so how a sequence
## ends never depends on the animation code. In reduced motion the same steps
## play as short fades with no travel or shaking.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const BoardResponse = preload("res://ui/model/board_response.gd")

signal started
signal finished
## Each step as it begins, for the checks that follow a sequence (tools/ui_check.gd).
signal step_started(kind: String)
## The reveal has paused with the Key Card up and its Encounter lit, until the
## player goes on (specs/014): resume(), or any press (main.gd _input).
signal waiting

var screen: Control
var flight: Control
## Called with (values, duration) to show a stage banner.
var show_banner: Callable
## Called with (event, ether) so the board answers a step (contracts/board-life.md).
var respond: Callable

var _after := {}
## Whether this sequence plays a set (it has a tally), so its result is laid on the
## Deck even when the sequence is skipped before the tally.
var _tallies := false
var _master: Tween
var _tweens: Array = []
var _playing := false
var _steps: Array = []
## Waiting on the player with the Key Card up (resume() goes on).
var _waiting := false
## The step the sequence waits after (a key_peek), until it has been reached.
var _wait_at := -1


func is_playing() -> bool:
	return _playing


func is_waiting() -> bool:
	return _waiting


func play(steps: Array, play_screen: Control, after_vs: Dictionary) -> void:
	if _playing:
		skip()
	screen = play_screen
	screen.detail.hide_card()
	_after = after_vs
	_tallies = steps.any(func(st): return st.kind == "tally")
	_playing = true
	started.emit()
	# A sequence that reveals the next Encounter holds the Deck's view until its zoom
	# lands, whatever renders on the way (specs/012 research R8).
	if steps.any(func(st): return st.kind == "zoom_in"):
		screen.deck.hold_card(true)
	_steps = steps
	_waiting = false
	_wait_at = steps.find_custom(func(st): return st.kind == "key_peek")
	_master = _build(0)


## The steps from `from` on, the sequence waiting on the player once the Key Card
## is up and its Encounter lit.
func _build(from: int) -> Tween:
	var tw := create_tween()
	for i in range(from, _steps.size()):
		var st: Dictionary = _steps[i]
		var d: float = reduced_duration(st) if UI.reduced_motion else st.duration
		tw.tween_callback(_run.bind(st, d))
		tw.tween_interval(d)
		if i == _wait_at:
			tw.tween_callback(_wait)
	tw.tween_callback(_finish)
	return tw


func _wait() -> void:
	_waiting = true
	_wait_at = -1
	_master.pause()
	var st: Dictionary = _steps[_steps.find_custom(func(s): return s.kind == "key_peek")]
	screen.actions.show_confirm("Face %s %d" % [st.values.kind.capitalize(), st.values.index])
	waiting.emit()


## Go on from the Key Card: it slides back down and the Deck zooms in.
func resume() -> void:
	if not _waiting:
		return
	_waiting = false
	screen.actions.set_ready(false)
	screen.actions.render(_after)
	_master.play()


## The player's press while a sequence plays: waiting, it goes on; before the Key
## Card has risen, everything up to it is done at once and it waits there, so the
## Encounter is always seen and confirmed; after, the rest is done at once.
func press() -> void:
	if not _playing:
		return
	if _waiting:
		resume()
	elif _wait_at >= 0:
		_to_wait()
	else:
		skip()


## Everything before the Key Card done at once, and the Key Card up with its
## number and Encounter lit, waiting.
func _to_wait() -> void:
	var peek: Dictionary = _steps[_wait_at]
	var from := _wait_at + 1
	if _master != null and _master.is_valid():
		_master.kill()
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens = []
	flight.clear()
	screen.deck.finish()
	screen.render(_after)
	screen.deck.show_reveal(_after.key_face, peek.values.get("target", _after.zoom))
	_master = _build(from)
	_wait_at = -1
	_master.pause()
	_waiting = true
	screen.actions.show_confirm("Face %s %d" % [peek.values.kind.capitalize(), peek.values.index])
	waiting.emit()


## How long a step plays in reduced motion: a short fade, but the stage banner
## keeps its time to be read, and so does the Key Card, its number and its panel
## lighting up one after the other (specs/012 FR-011, specs/014 FR-010).
static func reduced_duration(st: Dictionary) -> float:
	match st.kind:
		"stage_banner", "key_peek":
			return st.duration
	return minf(st.duration, T.FAST * 2.0)


func skip() -> void:
	if _playing:
		_finish()


func _finish() -> void:
	if not _playing:
		return
	_playing = false
	_waiting = false
	_wait_at = -1
	if _master != null and _master.is_valid():
		_master.kill()
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens = []
	flight.clear()
	screen.deck.finish()
	# Skipped before its tally, a Play's result still comes onto the Deck, built from
	# the state it was played in, which the screen still shows.
	if _tallies and not screen.deck.result_held:
		screen.deck.show_result()
	_tallies = false
	screen.render(_after)
	screen.settle()
	finished.emit()


func _keep(tw: Tween) -> Tween:
	_tweens.append(tw)
	return tw


func _run(st: Dictionary, d: float) -> void:
	step_started.emit(st.kind)
	if respond.is_valid():
		var enc = screen.vs.get("encounter") if screen.vs != null else null
		var event := BoardResponse.for_step(st.kind, st.get("values", {}), enc.kind if enc != null else "")
		if event != "":
			var ether = st.get("values", {}).get("element", "") if st.kind == "damage" else (enc.element if enc != null else null)
			respond.call(event, ether)
	match st.kind:
		"play_cards":
			_strike(st.cards, d)
		"tally":
			# The sum of the set just played comes onto the note laid on the Deck in
			# the card's place (specs/013 contracts/left-column.md).
			screen.deck.show_result()
			if screen.preview.visible:
				screen.preview.reveal()
				screen.preview.play_tally(d)
		"verdict":
			if screen.preview.visible:
				screen.preview.reveal_verdict(d)
			var look: Dictionary = T.VERDICT.get(st.values.outcome, {})
			if not look.is_empty():
				_keep(flight.float_text(look.text, screen.point("encounter"), look.color, 40, d * 2.2, look.icon))
		"gain_xp":
			var to: Vector2 = screen.point("preview")
			for i in 5:
				_keep(flight.ghost("xp", screen.point("encounter"), to, d, T.GOLD, 34, i * d * 0.08))
			_keep(flight.float_text("+%d XP" % st.values.amount, to, T.GOLD, 36, d * 2.0))
		"damage":
			var amount: int = st.values.amount
			if amount > 0:
				var e: String = st.values.element
				var icon := e if e != "" else "hp"
				_keep(flight.float_text("−%d" % amount, screen.point("hand"), T.BAD, 52, d * 2.2, icon))
			_keep(flight.tint(Color(T.BAD, 0.16), d))
			for id in screen.hand.ids():
				UI.shake(screen.hand.card(id), 10.0)
		"pay_time":
			var n: int = st.cards.size()
			for i in n:
				var delay := d * 0.6 * i / maxf(1.0, n)
				_keep(flight.ghost("card_back", screen.point("deck"), screen.point("discard"), d * 0.5, T.INK_MUTED, 40, delay))
				_keep(_later(delay + d * 0.4, func():
					screen.header.bump("deck", -1)
					screen.deck.bump(-1)
					screen.header.bump("discard", 1)))
			_keep(flight.float_text("−%d time" % n, screen.point("deck") + Vector2(0, 50), T.BAD, 30, d * 2.0, "time"))
		"poison_pending":
			_keep(flight.ghost("poison", screen.point("encounter"), screen.point("deck"), d, T.GOOD, 44))
		"knock_out":
			_keep(flight.float_text("KNOCKED OUT", screen.point("hand") + Vector2(0, -60), T.BAD, 48, d * 2.5, "down_arrow"))
			for id in st.cards:
				var v: Control = screen.hand.card(id)
				if v != null:
					UI.shake(v, 14.0)
		"downgrade", "upgrade":
			for id in st.cards:
				_level(id, st, d)
			if st.kind == "upgrade" and st.values.get("spent", 0) > 0:
				_stars(st.cards[0], st.values.spent, d)
		"soak_damage":
			_soak_damage(st.cards, st.values.due, d)
		"xp_lost":
			if screen.xp_purse.visible:
				screen.xp_purse.fade_out(d)
				_keep(flight.float_text("\u2212%d XP" % st.values.amount, screen.xp_purse.point(), T.INK_MUTED, 30, d * 2.0, "xp"))
		"trash":
			for id in st.cards:
				_away(id, "trash", d, true)
		"discard":
			for id in st.cards:
				if st.values.from == "deck":
					_keep(flight.ghost("card_back", screen.point("deck"), screen.point("discard"), d, T.INK_MUTED, 44))
					screen.header.bump("deck", -1)
					screen.deck.bump(-1)
					screen.header.bump("discard", 1)
				else:
					_away(id, "discard", d, false)
		"gather_shuffle":
			for id in st.cards:
				var v: Control = screen.hand.card(id)
				if v != null:
					_fly(v, screen.point("deck"), d, 0.15)
			if not UI.reduced_motion:
				_keep(flight.ghost("deck", screen.point("deck"), screen.point("deck") + Vector2(0, 30), d, T.GOLD, 60))
			# The Deck fills up to the reshuffled cards before the next Hand is drawn.
			var gathered: int = st.values.deck.size()
			_keep(_later(d * 0.8, func(): screen.deck.set_count(gathered)))
		"stage_banner":
			if show_banner.is_valid():
				show_banner.call(st.values, d)
		"draw":
			# Each card leaves the top card at its size, from under it (specs/014 R1).
			var n: int = maxi(1, st.cards.size())
			screen.deck.cover_draw(T.STAGGER * (n - 1) + T.DRAW_FLY)
			screen.render(_after, true, screen.deck.top_rect())
		"zoom_out":
			screen.deck.zoom_out(d)
		"turn_card":
			screen.deck.turn_to(_after.top_card, d)
		"key_peek":
			screen.deck.peek(_after.key_face, st.values.get("target", _after.zoom), d)
		"zoom_in":
			screen.deck.zoom_in(st.values.target, d)
		"ending":
			_keep(flight.tint(Color(T.GOLD if st.values.won else T.BAD, 0.2), d))


## Played cards lunge at the Encounter and come back.
func _strike(ids: Array, d: float) -> void:
	var target: Vector2 = screen.point("encounter")
	for i in ids.size():
		var v: Control = screen.hand.card(ids[i])
		if v == null:
			continue
		v.z_index = 5
		if UI.reduced_motion:
			_keep(_pulse(v, d))
			continue
		var home: Vector2 = v.position
		var towards: Vector2 = home + (target - (v.global_position + v.size / 2.0)) * 0.35
		var tw := _keep(create_tween().set_trans(Tween.TRANS_QUAD))
		tw.tween_interval(i * 0.04)
		tw.tween_property(v, "position", towards, d * 0.45).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(v, "rotation", deg_to_rad(-4.0 + 4.0 * i), d * 0.45)
		tw.tween_property(v, "position", home, d * 0.45).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(v, "rotation", 0.0, d * 0.45)
	var face: Control = screen.encounter_node()
	_keep(_later(d * 0.45, func(): UI.shake(face, 9.0)))


## A card changes Level where it stands: given its new Level, it turns over to
## show it (card_view.gd), unless it already shows it, turned when it was chosen.
func _level(id: String, st: Dictionary, d: float) -> void:
	var v: Control = screen.hand.card(id)
	if v == null:
		return
	var up: bool = st.kind == "upgrade"
	var m: Dictionary = _after.cards.get(id, {}).duplicate(true)
	if not m.is_empty():
		v.set_model(m)
	if UI.reduced_motion:
		_keep(_pulse(v, d))
	var c: Color = T.GOLD if up else T.BAD
	_keep(flight.float_text("Level %d" % st.values.level, v.global_position + Vector2(v.size.x / 2.0, v.size.y * 0.2), c, 30, d * 2.0,
		"crown" if up else "down_arrow"))


## The XP an Upgrade spent leaves the purse as that many stars, one per XP, and
## lands on the card; the purse's figure counts down as they go (specs/011 R7).
func _stars(id: String, spent: int, d: float) -> void:
	var v: Control = screen.hand.card(id)
	if v == null or not screen.xp_purse.visible:
		return
	var from: Vector2 = screen.xp_purse.point()
	var to: Vector2 = v.global_position + v.size / 2.0
	for i in spent:
		_keep(flight.ghost("xp", from, to, d, T.GOLD, 28, i * d * 0.08))
	screen.xp_purse.count_to(int(screen.vs.xp) - spent, d)


## While Upgrades are chosen: the XP a card takes flies from the purse to it as
## stars, and back to the purse when the Upgrade is taken back; the purse counts
## from `from_xp` to what is left.
func spend(play_screen: Control, id: String, from_xp: int, to_xp: int) -> void:
	screen = play_screen
	var v: Control = screen.hand.card(id)
	if v == null or not screen.xp_purse.is_visible_in_tree() or from_xp == to_xp:
		return
	var purse: Vector2 = screen.xp_purse.point()
	var card: Vector2 = v.global_position + v.size / 2.0
	var a: Vector2 = purse if to_xp < from_xp else card
	var b: Vector2 = card if to_xp < from_xp else purse
	for i in absi(from_xp - to_xp):
		flight.ghost("xp", a, b, T.TURN, T.GOLD, 28, i * T.TURN * 0.08)
	screen.xp_purse.amount.text = str(from_xp)
	screen.xp_purse.count_to(to_xp, T.TURN)


## The damage due leaves the Soak meter for the cards chosen to take it: each card
## gets one mark per point it Soaks, in the order chosen, until the damage is all
## taken, as the XP an Upgrade spends flies to its card.
func _soak_damage(ids: Array, due: int, d: float) -> void:
	if not screen.soak_meter.visible:
		return
	var soak: Dictionary = screen.vs.get("soak", {}) if screen.vs.get("soak") != null else {}
	var element: String = soak.get("element", "")
	var icon: String = "poison" if soak.get("poison", false) else (element if element != "" else "hp")
	var from: Vector2 = screen.soak_meter.point()
	var left := due
	var k := 0
	for id in ids:
		var v: Control = screen.hand.card(id)
		var n: int = mini(left, int(screen.vs.cards.get(id, {}).get("soaks", 0)))
		left -= n
		if v == null:
			continue
		var to: Vector2 = v.global_position + v.size / 2.0
		for i in n:
			_keep(flight.ghost(icon, from, to, d, T.BAD, 28, k * d * minf(0.08, 0.6 / maxf(1.0, due))))
			k += 1


## A card leaves the Hand for a pile.
func _away(id: String, pile: String, d: float, shatter: bool) -> void:
	var v: Control = screen.hand.card(id)
	if v == null:
		return
	_fly(v, screen.point(pile), d, 0.1)
	if shatter and not UI.reduced_motion:
		_keep(create_tween()).tween_property(v, "rotation", deg_to_rad(25.0), d)
	_keep(_later(d * 0.8, func(): screen.header.bump(pile, 1)))


func _fly(v: Control, to: Vector2, d: float, end_scale: float) -> void:
	v.z_index = 5
	var tw := _keep(create_tween().set_parallel(true))
	if UI.reduced_motion:
		tw.tween_property(v, "modulate:a", 0.0, d)
		return
	var target := to - (v.get_parent() as Control).global_position - v.size / 2.0
	tw.tween_property(v, "position", target, d).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(v, "scale", Vector2(end_scale, end_scale), d).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(v, "modulate:a", 0.2, d).set_delay(d * 0.5)


func _pulse(v: Control, d: float) -> Tween:
	v.pivot_offset = v.size / 2.0
	var tw := create_tween()
	if UI.reduced_motion:
		tw.tween_property(v, "modulate", Color(1.4, 1.4, 1.4), d * 0.5)
		tw.tween_property(v, "modulate", Color.WHITE, d * 0.5)
		return tw
	tw.tween_property(v, "scale", Vector2(1.1, 1.1), d * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(v, "scale", Vector2.ONE, d * 0.6)
	return tw


func _later(delay: float, f: Callable) -> Tween:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(f)
	return tw
