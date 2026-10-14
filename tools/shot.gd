extends SceneTree
## Drives the real screen through a short scripted game and saves screenshots.
## godot --path . -s tools/shot.gd -- <output dir>

var out := "."
var ui


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	_run()


func _shot(name: String) -> void:
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	await _shot("01_menu")
	ui.menu.difficulty = "casual"
	ui.start_game({"seed": 3, "dragon": "rodving", "difficulty": "casual"})
	for id in ui.game.setup_offer.slice(0, 3):
		ui._on_pick_card(id)
	await _shot("02_setup")
	ui._on_pick_card(ui.game.setup_offer[3])
	ui._on_confirm_setup()
	await _shot("03_challenge_empty")
	for id in ui.game.hand.slice(0, 3):
		ui._on_hand_card(id)
	await _shot("04_challenge_assigned")
	ui._on_play()
	await _shot("05_after_play")
	if ui.game.phase == "penalty":
		for id in ui.game.hand.duplicate():
			ui._on_pick_card(id)
		await _shot("06_soak")
		ui._on_confirm_soak()
	await _shot("07_upgrade")
	ui._on_finish()
	await _shot("08_next")
	# Jump to the Final Battle to check the two-set layout.
	ui.game.phase = "final_journey"
	ui.game.deck.append_array(ui.game.hand)
	ui.game.deck.append_array(ui.game.discard)
	ui.game.hand = []
	ui.game.discard = []
	ui.game._draw(7)
	ui._reset_turn()
	for id in ui.game.hand.slice(0, 6):
		ui._on_hand_card(id)
	ui._refresh()
	await _shot("09_final_journey")
	quit()
