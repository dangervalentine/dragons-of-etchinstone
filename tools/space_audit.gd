extends SceneTree
## Measures how the play screen spends its space, for feature 006: the share of
## the screen the role display takes, and how empty each zone is. A zone is the
## panel drawn on screen (for the Hand, the panel round its cards).
## Needs a window, so the viewport takes each size (headless keeps one size).
## godot --path . -s tools/space_audit.gd -- [--baseline <file> | --compare <file>]

const Solver = preload("res://ui/model/layout_solver.gd")

## The window sizes SC-002 is judged at: the minimum ones.
const SIZES := ["phone-16x9", "phone-small"]
const MAX_EMPTY := 1.0 / 3.0

var ui
var results := {}


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for name in SIZES:
		await _open(name)
		await _game(name)
	var failed := false
	if args.size() >= 2 and args[0] == "--baseline":
		var f := FileAccess.open(args[1], FileAccess.WRITE)
		f.store_string(JSON.stringify(results, "\t"))
		print("baseline written to " + args[1])
	elif args.size() >= 2 and args[0] == "--compare":
		failed = _compare(JSON.parse_string(FileAccess.get_file_as_string(args[1])))
	ui.free()
	quit(1 if failed else 0)


func _open(name: String) -> void:
	var m: Array = Solver.MATRIX[name]
	var view := Vector2i(Solver.matrix_view(name))
	# Locked to 16:9 on a desktop; a phone's row stretches as the mobile app does.
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if m[3] else Window.CONTENT_SCALE_ASPECT_KEEP
	DisplayServer.window_set_size(view)
	root.size = view
	for i in 3:
		await process_frame
	if ui != null:
		ui.free()
	ui = load("res://scenes/main.tscn").instantiate()
	ui.window_override = m[0]
	root.add_child(ui)
	await process_frame
	await process_frame


func _settle() -> void:
	ui.animator.skip()
	for i in 3:
		await process_frame


func _press(intent: Dictionary) -> void:
	ui.dispatch(intent)


## The same seeded game as tools/shot.gd.
func _game(size: String) -> void:
	ui.start_game({"seed": 3, "dragon": "rodving", "difficulty": "casual", "cavalier": false, "glass_cannon": false})
	for id in ui.game.setup_offer.slice(0, 4):
		_press({"type": "card", "id": id})
	_press({"type": "primary"})
	await _settle()
	await _measure(size, "challenge_empty")
	_press({"type": "card", "id": ui.game.hand[0]})
	await _settle()
	await _measure(size, "challenge_one")
	for id in ui.game.hand.slice(1, 3):
		_press({"type": "card", "id": id})
	await _settle()
	await _measure(size, "challenge_assigned")
	_press({"type": "primary"})
	await _settle()
	if ui.game.phase == "penalty":
		await _measure(size, "soak")
		for id in ui.game.hand.duplicate():
			if not ui.vs.soak.covered:
				_press({"type": "card", "id": id})
		_press({"type": "primary"})
		await _settle()
	await _measure(size, "upgrade")
	_press({"type": "primary"})
	await _settle()
	await _measure(size, "next")
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
	await _settle()
	await _measure(size, "final_journey")
	_press({"type": "primary"})
	await _settle()
	if g.phase == "final_enemy":
		for id in g.hand.slice(0, 6):
			_press({"type": "card", "id": id})
		await _settle()
		await _measure(size, "final_enemy")


## The zones that draw a panel, as [global rect, the node whose descendants are its
## content]. The header and the action bar draw none: their buttons are the panels,
## and what lies between them is the stone, not an empty zone.
func _zones() -> Dictionary:
	var play = ui.play
	var out := {}
	out["encounter"] = [play._regions.encounter.get_global_rect(), play.encounter_node()]
	for panel in [play.preview, play.soak_meter, play.xp_purse]:
		if panel.visible:
			out["preview"] = [panel.get_global_rect(), panel]
	# Since feature 010 the Roles are labels on the places, inside the Hand's zone.
	out["hand"] = [play._hand_panel.get_global_rect(), play.hand]
	return out


func _measure(size: String, state: String) -> void:
	var play = ui.play
	var content: Rect2 = play.plan.content
	# The box's room is for the sum it shows once Play is pressed (specs/011 R6).
	if play.preview.visible and play.preview.has_sum():
		play.preview.reveal()
		await process_frame
	# The role display: the labels over the places (feature 010).
	var role := Rect2()
	for pos in play.plan.get("positions", []):
		role = pos.label if role.size == Vector2.ZERO else role.merge(pos.label)
	var role_area: float = role.size.x * role.size.y
	var zones := {}
	var worst := ["", 0.0]
	var all := _zones()
	for key in all:
		var z: Array = all[key]
		var e: float = Solver.empty_fraction(z[0], z[1])
		zones[key] = snappedf(e, 0.01)
		if e > worst[1]:
			worst = [key, e]
	var row := {"role_size": [role.size.x, role.size.y], "role_share": snappedf(role_area / (content.size.x * content.size.y), 0.001),
		"zones": zones, "max_empty": [worst[0], snappedf(worst[1], 0.01)]}
	results["%s/%s" % [size, state]] = row
	print("view %s " % str(play.plan.view) + "%s/%s role %dx%d (%.1f%%) emptiest %s %.0f%% %s" % [size, state, role.size.x, role.size.y, row.role_share * 100.0, worst[0], worst[1] * 100.0, str(zones)])


## FAILs when any zone is over a third empty. The role display's share of the
## baseline band is reported only: revision 1 held it under half, but revision 2
## (the owner's stage 2 review) replaced the compact rail with full-size role slots
## that carry the numbers, and the Hand keeps its size instead (SC-004).
func _compare(base) -> bool:
	var failed := false
	for key in results:
		var row: Dictionary = results[key]
		if row.max_empty[1] > MAX_EMPTY:
			print("FAIL %s: %s is %.0f%% empty" % [key, row.max_empty[0], row.max_empty[1] * 100.0])
			failed = true
		if base != null and base.has(key):
			var b: Array = base[key].role_size
			var now: Array = row.role_size
			var ratio: float = (now[0] * now[1]) / maxf(1.0, b[0] * b[1])
			print("%s: role display %.0f%% of the baseline band" % [key, ratio * 100.0])
	print("space audit: %s" % ("FAIL" if failed else "PASS"))
	return failed
