extends SceneTree
## One screenshot of each main screen, at the Pixel 9 Pro's landscape resolution.
## godot --path . -s tools/design_shots.gd -- <out dir>

const WINDOW := Vector2i(2142, 960)

const HistoryStore = preload("res://ui/model/history_store.gd")

var out := "."
var ui
var n := 0


func _initialize() -> void:
	# Games played here are recorded in their own folder, never the player's records.
	HistoryStore.use_empty("user://tool_history/")
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func _run() -> void:
	DisplayServer.window_set_size(WINDOW)
	for i in 5:
		await process_frame
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await _game()
	await _marks()
	await _records()
	await _ethers()
	quit()


## The marks each effect puts beside the figures it works against (specs/011
## contracts/card-marks.md): an opening Hand facing each, in whichever Region has it.
func _marks() -> void:
	var Game = load("res://engine/game.gd")
	for effect in ["night_travel", "steep", "ranged", "freeze"]:
		var found := []
		for game_seed in range(1, 200):
			var g = Game.new(ui.db, {"seed": game_seed, "dragon": "rodving", "difficulty": "normal"})
			if g.phase != "challenge":
				continue
			for region in range(1, 4):
				g.region = region
				var enc: Dictionary = g.encounter()
				if found.is_empty() and [enc.hardship, enc.data.get("ability"), enc.data.get("peril")].has(effect):
					found = [game_seed, region]
			if not found.is_empty():
				break
		if found.is_empty():
			continue
		ui.start_game({"seed": found[0], "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
		ui.animator.skip()
		ui.game.region = found[1]
		ui._refresh(false)
		await _shot("marks_" + effect)


## One Mage Card of each Ether at Hand size, held still, and the same in greyscale:
## each Ether should be recognisable by its field and sigil alone.
func _ethers() -> void:
	root.remove_child(ui)
	ui.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("100e17")
	bg.size = Vector2(4000, 4000)
	root.add_child(bg)
	var db = load("res://engine/card_db.gd").new()
	var seen := {}
	for id in db.mage_ids():
		var e: String = db.mage(id).element
		if seen.has(e):
			continue
		seen[e] = true
		var m: Dictionary = db.mage(id)
		var face = load("res://ui/widgets/card_face.gd").new()
		face.size = Vector2(220, 308)
		face.position = Vector2(110 + (seen.size() - 1) * 270, 130)
		face.set_model({"id": id, "name": m.name, "element": e, "level": 2, "stats": db.mage_level(id, 2)})
		face.motion = false
		bg.add_child(face)
	for i in 5:
		await process_frame
	await create_timer(0.3).timeout
	var img := root.get_texture().get_image()
	img.save_png("%s/ethers.png" % out)
	img.convert(Image.FORMAT_L8)
	img.save_png("%s/ethers_grey.png" % out)
	print("ethers %s" % img.get_size())


## The Leaderboard and History over a fixed sample history: the Normal leaderboard, all
## dragons and one, and the History with its summary.
func _records() -> void:
	HistoryStore.records = []
	var dragons := ["rodving", "helsang", "grimroch", "vuurhast"]
	var diffs := ["normal", "normal", "hard", "easy", "casual", "normal", "impossible"]
	var stages := ["region_1", "region_2", "region_3", "region_4", "final_journey"]
	for i in 34:
		var outcome: String = ["won", "lost", "won", "abandoned", "won"][i % 5]
		var dragon: String = dragons[(i * 3) % 4]
		HistoryStore.append({"v": 1, "outcome": outcome, "difficulty": diffs[i % diffs.size()], "dragon": dragon,
			"dragon_name": dragon.capitalize(), "cavalier": i % 9 == 4, "glass_cannon": i % 13 == 6,
			"stage": "final_enemy" if outcome == "won" else ("final_journey" if outcome == "lost" else stages[i % 5]),
			"score": 18 + (i * 11) % 21 if outcome == "won" else 0, "active_ms": 640000 + (i * 97000) % 1500000,
			"started_at": 1789000000 + i * 86000, "ended_at": 1789000000 + i * 86000 + 1500, "seed": i})
	ui.menu.difficulty = "normal"
	ui.dispatch({"type": "records", "page": "leaderboard", "from": "title"})
	await _shot("records_leaderboard")
	ui.screen._tiles["dragon:helsang"].pressed.emit()
	await _shot("records_leaderboard_helsang")
	ui.screen._tiles["difficulty:dont_even_try"].pressed.emit()
	await _shot("records_leaderboard_empty")
	ui.screen._tiles["difficulty:normal"].pressed.emit()
	ui.dispatch({"type": "records", "page": "history", "from": "menu"})
	await _shot("records_history")
	ui.screen.back()
	await _shot("title_records_button")
	# A win that places second overall and best against its dragon.
	ui.start_game({"seed": 8, "dragon": "vuurhast", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	for i in 5:
		await process_frame
	ui.animator.skip()
	ui.game.phase = "won"
	ui._record("won")
	ui._refresh(false, false)
	ui._show_ending()
	await create_timer(1.5).timeout
	await _shot("ending_placing")


func _shot(name: String, skip := true) -> void:
	for i in 3:
		await process_frame
	if skip:
		ui.animator.skip()
	await create_timer(0.6).timeout
	n += 1
	var img := root.get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [out, n, name])
	print("%02d_%s %s" % [n, name, img.get_size()])


func _press(intent: Dictionary) -> void:
	ui.dispatch(intent)
	ui.animator.skip()


func _hover(id: String) -> void:
	var v = ui.play.hand.card(id)
	v._set_hover(true)
	ui.play._on_hover(id, true)
	ui.play._show_detail()


func _unhover(id: String) -> void:
	var v = ui.play.hand.card(id)
	v._set_hover(false)
	ui.play._on_hover(id, false)


## Bring a card whose Encounter is of this kind to the top of the deck.
func _key_of_kind(kind: String) -> bool:
	var g = ui.game
	for i in g.deck.size():
		if g.level_data(g.deck[i]).encounter.type == kind:
			var id = g.deck[i]
			g.deck.remove_at(i)
			g.deck.insert(0, id)
			ui._refresh(false)
			return true
	return false


## Every ordering of k cards from ids.
func _perms(ids: Array, k: int) -> Array:
	if k == 0:
		return [[]]
	var out := []
	for id in ids:
		var rest: Array = ids.duplicate()
		rest.erase(id)
		for p in _perms(rest, k - 1):
			out.append([id] + p)
	return out


## The best single Action Set by the engine's own preview: a complete victory with the most XP.
func _best_single() -> Array:
	var g = ui.game
	var best := []
	var score := -1
	for p in _perms(g.hand, 3):
		var r: Dictionary = g.preview({"spell": p[0], "element": p[1], "boost": p[2], "boost_to": "attack"})
		if r.has("error"):
			continue
		var v: int = {"complete": 1000, "narrow": 500}.get(r.outcome, 0) + r.get("xp", 0)
		if v > score:
			score = v
			best = p
	return best


## The best two Action Sets in the Final Battle: the highest tier reached.
func _best_final() -> Array:
	var g = ui.game
	var best := []
	var score := -1000
	for p in _perms(g.hand, 6):
		var r: Dictionary = g.preview_final({"sets": [
			{"spell": p[0], "element": p[1], "boost": p[2], "boost_to": "attack"},
			{"spell": p[3], "element": p[4], "boost": p[5], "boost_to": "attack"}]})
		if r.has("error"):
			continue
		var v: int = r.tier * 10 + (5 if r.get("survivable", true) else 0)
		if v > score:
			score = v
			best = p
	return best


## Place a card as a player does: tap it, then its place.
func _place_card(id: String, target: Array) -> void:
	_press({"type": "card", "id": id})
	_press({"type": "put", "target": target})


## Place cards given as Spell, Element, Boost for each set in turn.
func _place_set(ids: Array, sets: int, choose := true) -> void:
	var roles := ["spell", "element", "boost"]
	for i in mini(ids.size(), sets * 3):
		_place_card(ids[i], [i / 3, roles[i % 3]])
	if choose:
		for i in sets:
			_press({"type": "set_boost_to", "set": i, "to": "attack"})


func _game() -> void:
	await _shot("title")
	ui.dispatch({"type": "setup_rules", "options": ui.menu})
	await _shot("rules")
	ui.start_game({"seed": 3, "dragon": "rodving", "difficulty": "casual", "cavalier": false, "glass_cannon": false})
	for id in ui.game.setup_offer.slice(0, 3):
		_press({"type": "card", "id": id})
	await _shot("setup_choose_cards")
	_press({"type": "card", "id": ui.game.setup_offer[3]})
	_press({"type": "primary"})
	await create_timer(0.2).timeout
	ui.animator.skip()
	_key_of_kind("enemy")
	await _shot("enemy_encounter")
	_press({"type": "inspect_key"})
	await _shot("enemy_key_card")
	ui._close_overlays()
	var g = ui.game
	_place_card(g.hand[0], [0, "spell"])
	_place_card(g.hand[1], [0, "element"])
	_press({"type": "card", "id": g.hand[2]})
	await _shot("enemy_assigning_cards")
	_press({"type": "put_down"})
	_hover(g.hand[2])
	await create_timer(0.4).timeout
	await _shot("card_detail_hover")
	_unhover(g.hand[2])

	# Fuse: find two cards sharing an Ether.
	ui.draft.reset(1)
	ui._refresh(false)
	var pair := []
	for a in g.hand:
		for b in g.hand:
			if a != b and pair.is_empty() and ui.db.mage(a).element == ui.db.mage(b).element:
				pair = [a, b]
	if not pair.is_empty():
		_press({"type": "action", "id": "fuse"})
		_press({"type": "card", "id": pair[0]})
		_press({"type": "card", "id": pair[1]})
		await _shot("fuse_choose_ether")
		_press({"type": "fuse_element", "element": ui.db.mage(pair[0]).element})
		await _shot("fused")
	ui.draft.reset(1)
	ui._refresh(false)

	_place_set(_best_single(), 1, false)
	await _shot("enemy_boost_unchosen")
	# The Boost is aimed on its card (specs/011): Attack, then Initiative.
	var boost = ui.draft.sets[0].get("boost")
	if boost != null:
		_press({"type": "aim_card", "id": boost})
		await _shot("aim_attack")
		_press({"type": "aim_card", "id": boost})
		await _shot("aim_initiative")
	_press({"type": "set_boost_to", "set": 0, "to": "attack"})
	await _shot("enemy_ready_tip_only")
	ui.dispatch({"type": "primary"})
	for i in 25:
		await process_frame
	n += 1
	root.get_texture().get_image().save_png("%s/%02d_battle_animation.png" % [out, n])
	# Once the totals have counted up: the sum and the verdict in the box (specs/011).
	for i in 45:
		await process_frame
	n += 1
	root.get_texture().get_image().save_png("%s/%02d_battle_summary.png" % [out, n])
	ui.animator.skip()
	if g.phase == "penalty":
		await _shot("soak_choose")
		var first: String = ""
		for id in g.hand.duplicate():
			if ui.vs.cards[id].eligible and first == "":
				first = id
		if first != "":
			_hover(first)
			await create_timer(0.4).timeout
			await _shot("soak_hover_preview")
			_unhover(first)
		for id in g.hand.duplicate():
			if not ui.vs.soak.covered and ui.vs.cards[id].eligible:
				_press({"type": "card", "id": id})
		await _shot("soak_covered")
		# The damage flies from the Soak meter to the cards taking it.
		ui.dispatch({"type": "primary"})
		for i in 12:
			await process_frame
		n += 1
		root.get_texture().get_image().save_png("%s/%02d_soak_damage_flight.png" % [out, n])
		ui.animator.skip()
	if g.phase == "upgrade":
		await _shot("after_battle_upgrade")
		var up: String = g.hand[0]
		for id in g.hand:
			if ui.vs.cards[id].get("eligible", false):
				up = id
				break
		_hover(up)
		await create_timer(0.4).timeout
		await _shot("upgrade_hover_preview")
		_unhover(up)
		# The XP spent flies from the purse to the card as stars (specs/011 R7).
		ui.dispatch({"type": "card", "id": up})
		for i in 8:
			await process_frame
		n += 1
		root.get_texture().get_image().save_png("%s/%02d_upgrade_stars.png" % [out, n])
		ui.animator.skip()
		await _shot("upgraded_with_undo")
		_press({"type": "inspect", "id": g.hand[0]})
		await _shot("inspect_card")
		ui._close_overlays()
		_press({"type": "primary"})
		var top = ui._top_overlay()
		if top != null and top.has_signal("confirmed"):
			await _shot("unspent_xp_warning", false)
			top.confirmed.emit()
			top.close()
	await create_timer(0.2).timeout
	ui.animator.skip()
	ui._close_overlays()
	ui._reset_draft()
	ui.play._toast.modulate.a = 0.0
	if _key_of_kind("journey"):
		await _shot("journey_encounter")
	_press({"type": "help", "id": "ambush", "source": ui.play.encounter_face})
	await _shot("glossary_entry")
	ui._close_overlays()
	_press({"type": "glossary"})
	await _shot("glossary_full")
	ui._close_overlays()

	# Region banner.
	ui._banner({"phase": "challenge", "region": 2}, 3.0)
	await create_timer(0.5).timeout
	await _shot("region_banner", false)
	ui._close_overlays()

	# Final Battle.
	g.phase = "final_journey"
	g.region = 4
	g.deck.append_array(g.hand)
	g.deck.append_array(g.discard)
	g.hand = []
	g.discard = []
	g._draw(7)
	ui.draft.reset(2)
	ui._refresh(false)
	await _shot("final_journey")
	_place_set(_best_final(), 2)
	await _shot("final_journey_ready")
	_press({"type": "primary"})
	await create_timer(0.2).timeout
	ui.animator.skip()
	if g.phase == "final_enemy":
		await _shot("final_enemy")
		_place_set(_best_final(), 2)
		await _shot("final_enemy_ready")
		_press({"type": "primary"})
		await create_timer(0.2).timeout
		ui.animator.skip()
		if g.phase == "final_soak":
			await _shot("final_soak")
			for id in g.hand.duplicate():
				if not ui.vs.soak.covered and ui.vs.cards[id].eligible:
					_press({"type": "card", "id": id})
			_press({"type": "primary"})
			await create_timer(0.2).timeout
			ui.animator.skip()
	for i in 30:
		await process_frame
	await create_timer(1.0).timeout
	await _shot("ending_lost")
	g.phase = "won"
	ui._refresh(false, false)
	ui._show_ending()
	await create_timer(1.5).timeout
	await _shot("ending_won")
	_press({"type": "menu"})
	await _shot("menu_settings")
	ui._close_overlays()
