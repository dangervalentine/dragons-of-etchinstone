extends Node
## Plays the steps of a resolution sequence on the play screen, one after another.
## The game has already changed when a sequence starts; the screen is catching up.
## skip() stops everything and shows the final state at once, so how a sequence
## ends never depends on the animation code. In reduced motion the same steps
## play as short fades with no travel or shaking.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal finished

var screen: Control
var flight: Control
## Called with (values, duration) to show a stage banner.
var show_banner: Callable

var _after := {}
var _master: Tween
var _tweens: Array = []
var _playing := false


func is_playing() -> bool:
	return _playing


func play(steps: Array, play_screen: Control, after_vs: Dictionary) -> void:
	if _playing:
		skip()
	screen = play_screen
	screen.detail.hide_card()
	_after = after_vs
	_playing = true
	_master = create_tween()
	for st in steps:
		var d: float = st.duration
		if UI.reduced_motion:
			d = minf(d, T.FAST * 2.0) if st.kind != "stage_banner" else d
		_master.tween_callback(_run.bind(st, d))
		_master.tween_interval(d)
	_master.tween_callback(_finish)


func skip() -> void:
	if _playing:
		_finish()


func _finish() -> void:
	if not _playing:
		return
	_playing = false
	if _master != null and _master.is_valid():
		_master.kill()
	for tw in _tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens = []
	flight.clear()
	screen.render(_after)
	screen.settle()
	finished.emit()


func _keep(tw: Tween) -> Tween:
	_tweens.append(tw)
	return tw


func _run(st: Dictionary, d: float) -> void:
	match st.kind:
		"play_cards":
			_strike(st.cards, d)
		"tally":
			if screen.preview.visible:
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
		"trash":
			for id in st.cards:
				_away(id, "trash", d, true)
		"discard":
			for id in st.cards:
				if st.values.from == "deck":
					_keep(flight.ghost("card_back", screen.point("deck"), screen.point("discard"), d, T.INK_MUTED, 44))
					screen.header.bump("deck", -1)
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
		"stage_banner":
			if show_banner.is_valid():
				show_banner.call(st.values, d)
		"draw":
			screen.render(_after, true, screen.point("deck"))
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


## A card changes Level where it stands.
func _level(id: String, st: Dictionary, d: float) -> void:
	var v: Control = screen.hand.card(id)
	if v == null:
		return
	var up: bool = st.kind == "upgrade"
	var m: Dictionary = _after.cards.get(id, {}).duplicate(true)
	if not m.is_empty():
		_keep(_later(d * 0.35, func(): v.set_model(m)))
	_keep(_pulse(v, d))
	var c: Color = T.GOLD if up else T.BAD
	_keep(flight.float_text("Level %d" % st.values.level, v.global_position + Vector2(v.size.x / 2.0, v.size.y * 0.2), c, 30, d * 2.0,
		"crown" if up else "down_arrow"))


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
