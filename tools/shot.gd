extends SceneTree
## Drives the real screens through a short scripted game and saves screenshots,
## at every window size in the layout matrix or the ones named.
## godot --path . -s tools/shot.gd -- <output dir> [size name ...]

const Solver = preload("res://ui/model/layout_solver.gd")
const Rulebook = preload("res://ui/model/rulebook.gd")

const HistoryStore = preload("res://ui/model/history_store.gd")

var out := "."
var ui


func _initialize() -> void:
	# Games played here are recorded in their own folder, never the player's records.
	HistoryStore.use_empty("user://tool_history/")
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


## Size the window to the view this matrix entry's device gets, and have the game
## take it for that entry's window.
func _size(name: String) -> void:
	var m: Array = Solver.MATRIX[name]
	var view: Vector2 = Solver.matrix_view(name)
	# Run here on a desktop, the project is locked to 16:9; a phone's or tablet's
	# row stretches as the mobile app does.
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
		ui.safe_override = Solver.matrix_safe(name, name == "phone-tall-flipped")
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
	ui.screen._play()
	await _shot(dir + "/01e_dragons_none")
	ui.screen._choose("vuurhast")
	await _shot(dir + "/01e_dragons")
	_press({"type": "setup_rules", "options": ui.screen.options})
	await _shot(dir + "/01f_rules")
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
