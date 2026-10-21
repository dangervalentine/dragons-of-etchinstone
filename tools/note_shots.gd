extends SceneTree
## A screenshot of every note the Deck shows (specs/015), each alone on the Deck as
## its reference card: the Deck being prepared, each step (Fuse, Divert, Regroup), a
## refused move, the result of a Play, the Soak and the XP to spend. A seeded game is
## played into each state; for each note the rest of the pile is hidden, so the card
## is seen whole and square. Saves one image of the Deck per note and a contact sheet
## of them all, per window size.
## godot --path . -s tools/note_shots.gd -- <out dir> [size name ...]
## (sizes from layout_solver.gd MATRIX; "desktop" when none are named)

const Solver = preload("res://ui/model/layout_solver.gd")
const Settings = preload("res://ui/model/settings.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")

## Games tried, in order, until one reaches the Soak after its first Play.
const SEEDS := [3, 2, 4, 5, 7, 9, 12]

var out := "."
var ui
var _shots: Array = []


func _initialize() -> void:
	# Games played here are recorded in their own folder, never the player's records.
	HistoryStore.use_empty("user://tool_history/")
	Settings.use_for_tools()
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var names: Array = Array(args.slice(1)) if args.size() > 1 else ["desktop"]
	_run(names)


func _run(names: Array) -> void:
	for name in names:
		if not Solver.MATRIX.has(name):
			push_error("No window size named %s: %s" % [name, Solver.MATRIX.keys()])
			continue
		DirAccess.make_dir_recursive_absolute("%s/%s" % [out, name])
		_shots = []
		await _size(name)
		await _game(name)
		_sheet(name)
	quit()


## Size the window as the matrix entry's device and start the game afresh in it.
func _size(name: String) -> void:
	var m: Array = Solver.MATRIX[name]
	var view: Vector2 = Solver.matrix_view(name)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if m[3] else Window.CONTENT_SCALE_ASPECT_KEEP
	DisplayServer.window_set_size(Vector2i(view))
	root.size = Vector2i(view)
	for i in 3:
		await process_frame
	if ui != null:
		ui.queue_free()
	ui = load("res://scenes/main.tscn").instantiate()
	ui.window_override = m[0]
	if m[1] != [0, 0, 0, 0]:
		ui.safe_override = Solver.matrix_safe(name, false)
	root.add_child(ui)
	for i in 3:
		await process_frame


func _game(name: String) -> void:
	for game_seed in SEEDS:
		ui.start_game({"seed": game_seed, "dragon": "rodving", "difficulty": "casual", "cavalier": false, "glass_cannon": false})
		await _settle()
		if _shots.is_empty():
			await _note(name, "setup", "01_prepare_your_deck")
		for id in ui.game.setup_offer.slice(0, ui.game.setup_picks):
			ui.dispatch({"type": "card", "id": id})
		ui.dispatch({"type": "primary"})
		await _settle()
		if _shots.size() == 1:
			for step in ["fuse", "divert", "regroup"]:
				ui.dispatch({"type": "action", "id": step})
				await _note(name, "mode", "02_%s" % step)
				ui.dispatch({"type": "action", "id": "cancel"})
			# Play pressed with nothing placed: the move is refused and says why.
			ui.dispatch({"type": "primary"})
			await _note(name, "refusal", "03_not_allowed")
			ui.play.deck.clear_refusal()
		_play_first_three()
		await _settle()
		if ui.game.phase != "penalty":
			continue
		await _note(name, "result", "04_result")
		for id in ui.game.hand.duplicate():
			if not ui.vs.soak.covered and ui.vs.cards[id].eligible:
				ui.dispatch({"type": "card", "id": id})
		await _note(name, "soak", "05_soak_the_damage")
		ui.dispatch({"type": "primary"})
		await _settle()
		if ui.game.phase == "upgrade":
			for id in ui.game.hand:
				if ui.vs.cards[id].get("eligible", false):
					ui.dispatch({"type": "card", "id": id})
					break
			await _note(name, "upgrade", "06_upgrade")
		return
	push_warning("No seed reached the Soak; the result, Soak and Upgrade notes are missing.")


## The first three cards of the Hand as Spell, Element and Boost, the Boost to Attack.
func _play_first_three() -> void:
	var g = ui.game
	var roles := ["spell", "element", "boost"]
	for i in 3:
		ui.dispatch({"type": "card", "id": g.hand[i]})
		ui.dispatch({"type": "put", "target": [0, roles[i]]})
	ui.dispatch({"type": "set_boost_to", "set": 0, "to": "attack"})
	ui.dispatch({"type": "primary"})


## Every sequence and every note's flight done.
func _settle() -> void:
	for i in 2:
		await process_frame
	ui.animator.skip()
	if ui.play != null:
		ui.play.deck.pile.finish()
	for i in 3:
		await process_frame


## The note of `kind` alone on the Deck and square, saved as `file`.
func _note(name: String, kind: String, file: String) -> void:
	await _settle()
	var pile = ui.play.deck.pile
	var card: Control = pile.refusal_card if kind == "refusal" else pile.card(kind)
	if card == null:
		push_warning("%s: no %s note to shoot (pile %s)" % [name, kind, pile.kinds()])
		return
	var hidden := []
	for c in pile.cards + ([pile.refusal_card] if pile.refusal_card != null else []):
		if c != card and c.visible:
			c.visible = false
			hidden.append(c)
	var tilt: float = card.rotation
	card.rotation = 0.0
	# Long enough for the Ether behind the setup text and any count to settle.
	await create_timer(0.4).timeout
	await process_frame
	var path := "%s/%s/%s.png" % [out, name, file]
	var img := _deck_image()
	img.save_png(path)
	_shots.append(img)
	print("saved ", path)
	card.rotation = tilt
	for c in hidden:
		c.visible = true


## The left of the screen round the Deck, at the window's own pixels.
func _deck_image() -> Image:
	var img: Image = root.get_texture().get_image()
	var k: float = float(img.get_width()) / root.get_visible_rect().size.x
	var r: Rect2 = ui.play.deck.get_global_rect().grow(12)
	var px := Rect2i(Vector2i((r.position * k).floor()), Vector2i((r.size * k).ceil())).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	return img.get_region(px)


## Every shot side by side in one image.
func _sheet(name: String) -> void:
	if _shots.is_empty():
		return
	var w := 0
	var h := 0
	for s in _shots:
		w += s.get_width() + 16
		h = maxi(h, s.get_height())
	var sheet := Image.create(w + 16, h + 32, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("0d0b12"))
	var x := 16
	for s in _shots:
		var shot: Image = s
		shot.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(x, 16))
		x += shot.get_width() + 16
	var path := "%s/%s/sheet.png" % [out, name]
	sheet.save_png(path)
	print("saved ", path)
