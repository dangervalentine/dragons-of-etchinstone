extends SceneTree
## One screenshot of each main screen, at the Pixel 9 Pro's landscape resolution.
## godot --path . -s tools/design_shots.gd -- <out dir>
## With "deck", "notes" or "shuffle" after the out dir, only those shots.

const WINDOW := Vector2i(2142, 960)
const Settings = preload("res://ui/model/settings.gd")

const HistoryStore = preload("res://ui/model/history_store.gd")

var out := "."
var ui
var n := 0


func _initialize() -> void:
	# Games played here are recorded in their own folder, never the player's records.
	HistoryStore.use_empty("user://tool_history/")
	Settings.use_for_tools()
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	if args.size() > 1 and args[1] == "scan":
		_scan()
		return
	if args.size() > 1 and args[1] == "notes":
		_run_notes()
		return
	if args.size() > 1 and args[1] == "shuffle":
		_run_shuffle()
		return
	_run(args.size() > 1 and args[1] == "deck")


## With "deck" after the out dir, only the Deck's shots (specs/012).
func _run(deck_only := false) -> void:
	DisplayServer.window_set_size(WINDOW)
	for i in 5:
		await process_frame
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	# Let the window take its size first: a layout change skips any sequence playing.
	for i in 5:
		await process_frame
	await _deck()
	if deck_only:
		quit()
		return
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


## The Deck on the left side (specs/012 quickstart.md): the first reveal frame by
## frame, a Divert's, the Region Card turned for each Region, the half-turn and the
## swap mid-way, and the Dragon Card, zoomed out and zoomed in.
func _deck() -> void:
	var ViewState = load("res://ui/model/view_state.gd")
	ui.start_game({"seed": 5, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	# The start sequence (specs/014 contracts/deck-motion.md): the whole Region Card,
	# a card halfway from it to the Hand, the Key Card up with its number and its
	# panel lit, the zoom, and the face settled.
	await create_timer(0.8).timeout
	_grab("deck_zoomed_out")
	await _until(ui.animator.step_started, "draw")
	await create_timer(T.STAGGER + T.DRAW_FLY * 0.5).timeout
	_grab("deck_draw_mid")
	await _until(ui.play.deck.reveal_beat, "panel_lit")
	await create_timer(T.PANEL_LIT).timeout
	_grab("deck_reveal")
	# The reveal waits on the player with the Key Card up (specs/014).
	while not ui.animator.is_waiting():
		await process_frame
	_grab("deck_waiting")
	ui.animator.resume()
	await _until(ui.play.deck.reveal_beat, "zoom")
	await create_timer(T.ZOOM * 0.4).timeout
	_grab("deck_zooming_in")
	await _shot("deck_settled")
	await _notes()
	# A Divert: out to the card, the Key Card leaving, the next one rising.
	var id: String = ui.game.hand[0]
	ui._act({"kind": "divert", "cards": [id], "id": id}, func(): return ui.game.divert(id))
	await create_timer(0.7).timeout
	_grab("deck_divert_zoomed_out")
	await create_timer(0.9).timeout
	_grab("deck_divert_next_key_card")
	ui.animator.skip()
	# Each Region's side of the cards, and the Dragon Card.
	var deck = ui.play.deck
	for region in range(1, 5):
		deck.hold_card(true)
		deck.view = "card"
		deck._show_top(ViewState.region_card_model(ui.db, region))
		deck._place()
		await _shot("deck_region_%d" % region, false)
	deck._show_top(ViewState.region_card_model(ui.db, 1))
	deck._place()
	# The pile full and nearly spent (specs/014 contracts/deck-pile.md).
	var was: int = deck.count
	deck.set_count(16)
	await _shot("deck_pile_full", false)
	deck.set_count(3)
	await _shot("deck_pile_low", false)
	deck.set_count(was)
	deck.turn_to(ViewState.region_card_model(ui.db, 2), T_TURN)
	await create_timer(T_TURN * 0.3).timeout
	_grab("deck_half_turn")
	await create_timer(T_TURN).timeout
	deck.turn_to(ViewState.region_card_model(ui.db, 3), T_TURN)
	await create_timer(T_TURN * 0.7).timeout
	_grab("deck_card_swap")
	await create_timer(T_TURN).timeout
	deck.turn_to(ViewState.dragon_card_model(ui.game.dragon), T_TURN)
	await create_timer(T_TURN * 1.5).timeout
	await _shot("deck_dragon_card", false)
	deck.finish()
	ui._refresh(false)


const T_TURN := 0.5


## With "notes" after the out dir, only the notes' shots (specs/015): a game is
## started and its reveal skipped, so no shot waits on the player.
func _run_notes() -> void:
	DisplayServer.window_set_size(WINDOW)
	for i in 5:
		await process_frame
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	for i in 5:
		await process_frame
	ui.start_game({"seed": 5, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await create_timer(0.5).timeout
	ui.animator.skip()
	await _shot("deck_settled")
	await _notes()
	quit()


## The notes as cards (specs/015): a result, a step and a refused move dealt on one
## over another from the left, piled up askew, and the pile thrown off together.
func _notes() -> void:
	var deck = ui.play.deck
	deck.show_result()
	deck.pile.deal("mode", ui.vs, {}, true)
	deck.show_refusal("Choose where the Boost goes before you Play.")
	await create_timer(T.NOTE_DEAL * 0.5).timeout
	_grab("deck_note_dealt_mid")
	await create_timer(T.NOTE_DEAL).timeout
	_grab("deck_notes_piled")
	deck.pile.throw_all(true)
	await create_timer(T.NOTE_DISCARD * 0.5).timeout
	_grab("deck_notes_thrown_mid")
	deck.pile.finish()
	deck.clear_result(0.0)
	ui._refresh(false)
const T = preload("res://ui/theme/tokens.gd")


## With "shuffle" after the out dir, the Deck shuffled under the card on top
## (specs/016): at a game's start under Region 1's, at the end of Region 1 under
## Region 2's and after Region 4 under the Dragon Card, each early, midway and late.
func _run_shuffle() -> void:
	DisplayServer.window_set_size(WINDOW)
	for i in 5:
		await process_frame
	ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	for i in 5:
		await process_frame
	ui.start_game({"seed": 5, "dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false})
	await _shuffle_shots("shuffle_region1")
	for to in [2, 5]:
		await create_timer(0.3).timeout
		ui.animator.skip()
		var g = ui.game
		if to == 5:
			g.region = 4
		g.discard.append_array(g.deck)
		g.deck = []
		g.phase = "upgrade"
		g._action = {"cards": {}, "fuse": null, "reserve": null}
		ui._refresh(false)
		ui._act({"kind": "finish", "cards": []}, func(): return ui.game.finish())
		await _shuffle_shots("shuffle_dragon" if to == 5 else "shuffle_region2")
	quit()


func _shuffle_shots(name: String) -> void:
	await _until(ui.play.deck.reveal_beat, "shuffle")
	var at := 0.0
	for share in [0.2, 0.45, 0.7]:
		await create_timer(T.SHUFFLE * (share - at)).timeout
		at = share
		_grab("%s_%d" % [name, int(share * 100)])


## Wait until `sig` carries `what`.
func _until(sig: Signal, what: String) -> void:
	var got := [false]
	var on := func(v: String):
		if v == what:
			got[0] = true
	sig.connect(on)
	var until := Time.get_ticks_msec() + 10000
	while not got[0] and Time.get_ticks_msec() < until:
		await process_frame
	sig.disconnect(on)


## The printed cards laid over the drawn ones at half strength (specs/013 SC-001):
## with "scan" after the out dir. Each card is drawn at the scan's own size so their
## panels and badges can be lined up by eye.
func _scan() -> void:
	DisplayServer.window_set_size(WINDOW)
	for i in 5:
		await process_frame
	var ViewState = load("res://ui/model/view_state.gd")
	var RegionCard = load("res://ui/widgets/region_card.gd")
	var db = load("res://engine/card_db.gd").new()
	var sheet: Texture2D = load("res://reference/sheets-official/o5.png")
	var back := ColorRect.new()
	back.color = Color("100e17")
	back.size = Vector2(WINDOW)
	root.add_child(back)
	# Jade Mountains is the top right card of the sheet, Burning Basin the top left.
	for at in [[1, Rect2(512, 0, 498, 695)], [3, Rect2(4, 0, 498, 695)]]:
		var card = RegionCard.new()
		back.add_child(card)
		card.position = Vector2(40, 40)
		card.size = RegionCard.card_size(at[1].size.x)
		card.render(ViewState.region_card_model(db, at[0]))
		var over := TextureRect.new()
		var crop := AtlasTexture.new()
		crop.atlas = sheet
		crop.region = at[1]
		over.texture = crop
		over.position = Vector2(40, 40)
		over.size = at[1].size
		over.modulate.a = 0.5
		back.add_child(over)
		# Side by side to the right: the drawn card alone.
		var bare = RegionCard.new()
		back.add_child(bare)
		bare.position = Vector2(600, 40)
		bare.size = card.size
		bare.render(ViewState.region_card_model(db, at[0]))
		for i in 30:
			await process_frame
		_grab("scan_region_%d" % at[0])
		for c in [card, over, bare]:
			c.queue_free()
	# Grimroch is the bottom left card of the sheet.
	var DragonCard = load("res://ui/widgets/dragon_card.gd")
	var where := Rect2(4, 702, 498, 695)
	var dcard = DragonCard.new()
	var dbare = DragonCard.new()
	for c in [dcard, dbare]:
		back.add_child(c)
		c.size = DragonCard.card_size(where.size.x)
		c.render(ViewState.dragon_card_model(db.dragon("grimroch")))
	dcard.position = Vector2(40, 40)
	dbare.position = Vector2(600, 40)
	var dover := TextureRect.new()
	var dcrop := AtlasTexture.new()
	dcrop.atlas = sheet
	dcrop.region = where
	dover.texture = dcrop
	dover.position = Vector2(40, 40)
	dover.size = where.size
	dover.modulate.a = 0.5
	back.add_child(dover)
	for i in 30:
		await process_frame
	_grab("scan_dragon_grimroch")
	quit()


## A shot of this very frame, for something in motion.
func _grab(name: String) -> void:
	n += 1
	var img := root.get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [out, n, name])
	print("%02d_%s %s" % [n, name, img.get_size()])


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
	# The Boost is aimed in its column after the row: Attack, then Initiative.
	_press({"type": "set_boost_to", "set": 0, "to": "attack"})
	await _shot("aim_attack")
	_press({"type": "set_boost_to", "set": 0, "to": "initiative"})
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
		for id in g.hand.duplicate():
			if not ui.vs.soak.covered and ui.vs.cards[id].eligible:
				_press({"type": "card", "id": id})
		await _shot("soak_covered")
		# The cards taking the damage Downgrade.
		ui.dispatch({"type": "primary"})
		for i in 12:
			await process_frame
		n += 1
		root.get_texture().get_image().save_png("%s/%02d_soak_downgrading.png" % [out, n])
		ui.animator.skip()
	if g.phase == "upgrade":
		await _shot("after_battle_upgrade")
		var up: String = g.hand[0]
		for id in g.hand:
			if ui.vs.cards[id].get("eligible", false):
				up = id
				break
		# Chosen, the card turns to its next Level as the purse's bar empties.
		ui.dispatch({"type": "card", "id": up})
		for i in 8:
			await process_frame
		n += 1
		root.get_texture().get_image().save_png("%s/%02d_upgrade_spending.png" % [out, n])
		await create_timer(0.6).timeout
		await _shot("upgrade_chosen")
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
	ui.play.deck.clear_refusal()
	if _key_of_kind("journey"):
		await _shot("journey_encounter")
	_press({"type": "help", "id": "ambush", "source": ui.play.landed})
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
	ui._reset_draft()
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
