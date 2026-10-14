extends SceneTree
## Drives the real screens through a short scripted game and saves screenshots,
## at every window size in the layout matrix or the ones named.
## godot --path . -s tools/shot.gd -- <output dir> [size name ...]

const Solver = preload("res://ui/model/layout_solver.gd")
const Rulebook = preload("res://ui/model/rulebook.gd")

var out := "."
var ui


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var names: Array = Array(args.slice(1)) if args.size() > 1 else Solver.MATRIX.keys()
	_run(names)


func _run(names: Array) -> void:
	for name in names:
		await _size(name)
		DirAccess.make_dir_recursive_absolute("%s/%s" % [out, name])
		await _game("%s/%s" % [out, name])
	quit()


## Size the window so the viewport has the design size this matrix entry would have.
func _size(name: String) -> void:
	var m: Array = Solver.MATRIX[name]
	var view: Vector2 = Solver.view_for_window(m[0])
	if name == "upright-browser":
		view = Vector2(720, 1280)
	DisplayServer.window_set_size(Vector2i(view))
	root.size = Vector2i(view)
	for i in 3:
		await process_frame
	if ui != null:
		ui.queue_free()
	ui = load("res://scenes/main.tscn").instantiate()
	var k: float = view.x / m[0].x
	var inset: Array = m[1]
	if name == "phone-tall-flipped":
		inset = [inset[2], inset[1], inset[0], inset[3]]
	if inset != [0, 0, 0, 0]:
		ui.safe_override = Rect2(inset[0] * k, inset[1] * k, view.x - (inset[0] + inset[2]) * k, view.y - (inset[1] + inset[3]) * k)
	root.add_child(ui)


func _shot(path: String) -> void:
	for i in 3:
		await process_frame
	ui.animator.skip()
	await create_timer(0.35).timeout
	root.get_texture().get_image().save_png(path + ".png")


func _press(intent: Dictionary) -> void:
	ui.dispatch(intent)


func _game(dir: String) -> void:
	await _shot(dir + "/01_title")
	await _rulebook(dir)
	ui.start_game({"seed": 3, "dragon": "rodving", "difficulty": "casual", "cavalier": false, "glass_cannon": false})
	for id in ui.game.setup_offer.slice(0, 3):
		_press({"type": "card", "id": id})
	await _shot(dir + "/02_setup")
	_press({"type": "card", "id": ui.game.setup_offer[3]})
	_press({"type": "primary"})
	ui.animator.skip()
	await _shot(dir + "/03_challenge_empty")
	_press({"type": "card", "id": ui.game.hand[0]})
	await _shot(dir + "/04_challenge_one")
	for id in ui.game.hand.slice(1, 3):
		_press({"type": "card", "id": id})
	await _shot(dir + "/05_challenge_assigned")
	_press({"type": "primary"})
	for i in 20:
		await process_frame
	root.get_texture().get_image().save_png(dir + "/06_mid_sequence.png")
	ui.animator.skip()
	if ui.game.phase == "penalty":
		await _shot(dir + "/07_soak_empty")
		for id in ui.game.hand.duplicate():
			if not ui.vs.soak.covered:
				_press({"type": "card", "id": id})
		await _shot(dir + "/07_soak")
		_press({"type": "primary"})
		ui.animator.skip()
	await _shot(dir + "/08_upgrade")
	_press({"type": "inspect", "id": ui.game.hand[0]})
	await _shot(dir + "/09_inspect")
	ui._close_overlays()
	_press({"type": "primary"})
	ui.animator.skip()
	await _shot(dir + "/10_next")
	_press({"type": "help", "id": "ambush", "source": ui.play.encounter_face})
	await _shot(dir + "/11_help")
	ui._close_overlays()
	# Jump to the Final Battle to check the two-set layout.
	var g = ui.game
	g.phase = "final_journey"
	g.deck.append_array(g.hand)
	g.deck.append_array(g.discard)
	g.hand = []
	g.discard = []
	g._draw(7)
	ui.draft.reset(2)
	for id in g.hand.slice(0, 6):
		_press({"type": "card", "id": id})
	ui._refresh(false)
	await _shot(dir + "/12_final_journey")
	_press({"type": "primary"})
	ui.animator.skip()
	if g.phase == "final_enemy":
		for id in g.hand.slice(0, 6):
			_press({"type": "card", "id": id})
		await _shot(dir + "/13_final_enemy")
		_press({"type": "primary"})
		ui.animator.skip()
		if g.phase == "final_soak":
			for id in g.hand.duplicate():
				if not ui.vs.soak.covered:
					_press({"type": "card", "id": id})
			_press({"type": "primary"})
			ui.animator.skip()
	for i in 20:
		await process_frame
	await _shot(dir + "/14_ending")
	_press({"type": "menu"})
	await _shot(dir + "/15_menu")
	ui._close_overlays()
	ui.dispatch({"type": "to_title"})


## How to Play: its first page, the contents, a page with an example card and one with a table.
func _rulebook(dir: String) -> void:
	Rulebook.position = {"section": 0, "page": 0}
	_press({"type": "rulebook"})
	var book = ui._top_overlay()
	await _shot(dir + "/01a_rulebook")
	book.toggle_contents()
	await _shot(dir + "/01b_rulebook_contents")
	book.show_page(Rulebook.find("mage_cards"), 0, false)
	await _shot(dir + "/01c_rulebook_figure")
	book.show_page(Rulebook.find("enemies"), 0, false)
	await _shot(dir + "/01d_rulebook_table")
	ui._close_overlays()
