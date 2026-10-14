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

const HELP_MIN := 44.0

var failures := 0
var checks := 0
var ui
var db = CardDB.new()


func _initialize() -> void:
	_run()


func _run() -> void:
	for name in Solver.MATRIX:
		await _open(name)
		await _play(name, 11, "casual", false)
	await _open("phone-16x9")
	await _play("phone-16x9 animated", 5, "normal", true)
	await _open("desktop")
	await _resize_mid_turn()
	print("ui check: %d checks, %d failed" % [checks, failures])
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
	if name == "upright-browser":
		view = Vector2(720, 1280)
	root.size = Vector2i(view)
	await process_frame
	if ui != null:
		ui.free()
	ui = load("res://scenes/main.tscn").instantiate()
	var real: Vector2 = root.get_visible_rect().size
	var k: float = real.x / m[0].x
	var inset: Array = m[1]
	if name == "phone-tall-flipped":
		inset = [inset[2], inset[1], inset[0], inset[3]]
	if inset != [0, 0, 0, 0]:
		ui.safe_override = Rect2(inset[0] * k, inset[1] * k, real.x - (inset[0] + inset[2]) * k, real.y - (inset[1] + inset[3]) * k)
	root.add_child(ui)
	await process_frame
	await process_frame
	_ok(ui.plan.undersized == (name == "upright-browser"), "%s: undersized is %s" % [name, ui.plan.undersized])
	_ok(ui._notice != null if name == "upright-browser" else ui._notice == null, "%s: size notice" % name)


func _settle() -> void:
	ui.animator.skip()
	await process_frame
	await process_frame


## Everything a player can press or must read, checked against the screen.
## Skipped while a sequence is moving things about.
func _inspect_screen(where: String) -> void:
	if ui.animator.is_playing():
		return
	var safe: Rect2 = ui.plan.safe.grow(1.0)
	var view := Rect2(Vector2.ZERO, root.get_visible_rect().size).grow(1.0)
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
	if ui.screen != null and ui.screen != ui.play:
		_inspect_screen("%s ending" % where)


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
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	_ok(ui.draft.to_action() == before, "resize keeps the placed cards")
	_ok(ui.play.hand.ids().size() == g.hand.size(), "resize keeps every card on screen")
	_inspect_screen("after resize")
