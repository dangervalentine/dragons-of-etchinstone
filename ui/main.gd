extends Control
## The whole playable screen, built in code and rebuilt after every action.
## All rules live in engine/; this file only shows state and collects choices.

const CardDB = preload("res://engine/card_db.gd")
const Game = preload("res://engine/game.gd")

const COLUMN_WIDTH := 720
const BG := Color("14121c")
const PANEL := Color("231f30")
const PANEL_HI := Color("342d47")
const TEXT := Color("ece8f5")
const MUTED := Color("a39db5")
const ACCENT := Color("f2d16b")
const WARN := Color("ff8a7a")
const CHIP := Color("57507a")
const HP_COLOR := Color("d2536a")
const ELEMENT_COLORS := {
	"fire": Color("e2543a"), "water": Color("4a9cf0"),
	"lightning": Color("e8ad2a"), "shadow": Color("a56cf0"),
}
const ROLES := ["spell", "element", "boost"]
const TYPE_NAMES := {"attack": "Attack", "move": "Move", "flex": "Atk/Mov"}
const OUTCOMES := {"complete": "Complete victory", "narrow": "Narrow victory", "loss": "Loss"}
const DIFFICULTIES := {
	"casual": "Casual", "easy": "Easy", "normal": "Normal", "hard": "Hard",
	"impossible": "Impossible", "dont_even_try": "Don't Even Try It",
}
const HARDSHIPS := {
	"ambush": "Ambush: early damage is doubled.",
	"hazards": "Hazards: lose 1 time for early damage and 1 for combat damage.",
	"night_travel": "Night Travel: your Boost is reduced by your Initiative.",
	"storm": "Storm: time penalties also deal that much damage.",
}
const ABILITIES := {
	"freeze": "Freeze: if it deals early damage, you discard your Reserve.",
	"poison": "Poison: damage taken adds 1 damage to your next Hand (2 if hit early and in combat).",
	"ranged": "Ranged: deals early damage whatever your Initiative, unless you give up your Reserve.",
	"slow": "Slow: you may use Move instead of Attack.",
}
const PERILS := {
	"steep": "Steep: MP rises by your Reserve card's Boost.",
	"treacherous": "Treacherous: 1 damage unless you win outright.",
}

var db = CardDB.new()
var game: Variant = null
var menu := {"dragon": "rodving", "difficulty": "normal", "cavalier": false, "glass_cannon": false}

# Choices being built for the current phase.
var sets: Array = [{}, {}]
var active: Array = [0, "spell"]
var boost_to: Array = ["attack", "attack"]
var fuse: Variant = null   # {top, bottom, element}
var fuse_pick: Array = []
var mode := ""              # "", "divert", "regroup", "fuse", "fuse_element"
var ranged_discard := false
var picks: Array = []       # ordered picks for setup and soaking
var message := ""
var last_summary := ""

var root: VBoxContainer
var _icons := {}


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	# A phone-width column, centred when the window is wider.
	var centre := HBoxContainer.new()
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(centre)
	var margin := MarginContainer.new()
	margin.custom_minimum_size.x = COLUMN_WIDTH
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	if OS.has_feature("mobile"):
		# Keep clear of the notch and the home indicator.
		var window := Vector2(DisplayServer.window_get_size())
		var safe := DisplayServer.get_display_safe_area()
		var scale := get_viewport_rect().size.y / window.y
		margin.add_theme_constant_override("margin_top", 16 + int(safe.position.y * scale))
		margin.add_theme_constant_override("margin_bottom", 16 + int(maxf(0.0, window.y - safe.end.y) * scale))
	centre.add_child(margin)
	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	get_window().size_changed.connect(_fit_window)
	_fit_window()
	_refresh()


## The project scales the 720x1280 design to fit the whole window, which makes a
## portrait layout tiny in a landscape browser or desktop window. Scale by width
## instead (up to the display's own pixel scale) and let the page scroll.
func _fit_window() -> void:
	var window := get_window()
	var pixels := Vector2(window.size)
	var fitted := minf(pixels.x / COLUMN_WIDTH, pixels.y / 1280.0)
	var wanted := minf(pixels.x / COLUMN_WIDTH, maxf(fitted, DisplayServer.screen_get_scale()))
	window.content_scale_factor = wanted / fitted


func start_game(opts: Dictionary) -> void:
	game = Game.new(db, opts)
	last_summary = ""
	_reset_turn()
	_refresh()


# ---------------------------------------------------------------- screens

func _refresh() -> void:
	for c in root.get_children():
		root.remove_child(c)
		c.queue_free()
	if game == null:
		_build_menu()
		return
	_build_header()
	match game.phase:
		"setup":
			_build_setup()
		"challenge":
			_build_challenge()
		"penalty", "poison", "final_soak":
			_build_soak()
		"upgrade":
			_build_upgrade()
		"final_journey", "final_enemy":
			_build_final()
		"won", "lost":
			_build_end()
	if message != "":
		root.add_child(_label(message, 16, WARN, true))


func _build_menu() -> void:
	root.add_child(_label("Dragons of Etchinstone", 34, ACCENT))
	root.add_child(_label("Fan-made digital version. Game by Joe Klipfel, published by Chip Theory Games.", 14, MUTED, true))
	root.add_child(_label("Hunt a dragon", 20))
	var dragons := _grid(2)
	for id in db.dragon_ids():
		var d = db.dragon(id)
		var b := _button("%s\n%s" % [d.name, d.title], _set_menu.bind("dragon", id), true, menu.dragon == id)
		_tint(b, ELEMENT_COLORS[d.early_damage.element], menu.dragon == id)
		dragons.add_child(b)
	root.add_child(dragons)
	root.add_child(_label("Difficulty", 20))
	var diffs := _grid(3)
	for key in DIFFICULTIES:
		diffs.add_child(_button(DIFFICULTIES[key], _set_menu.bind("difficulty", key), true, menu.difficulty == key))
	root.add_child(diffs)
	root.add_child(_label("Alternate rules", 20))
	var alts := _grid(2)
	alts.add_child(_button("Cavalier\nno Fusing", _set_menu.bind("cavalier", not menu.cavalier), true, menu.cavalier))
	alts.add_child(_button("Glass Cannon\nmatching armor +1, not double",
		_set_menu.bind("glass_cannon", not menu.glass_cannon), true, menu.glass_cannon))
	root.add_child(alts)
	var start := _button("Start the adventure", _on_start, true, true)
	start.custom_minimum_size.y = 72
	root.add_child(start)


func _build_header() -> void:
	var title := ""
	if game.phase.begins_with("final") or game.phase == "won" or game.phase == "lost":
		title = "Final Battle · %s, %s" % [game.dragon.name, game.dragon.title]
	else:
		title = "Region %d · %s" % [game.region, db.region(game.region).name]
	root.add_child(_label(title, 22, ACCENT))
	root.add_child(_label("Deck %d   Discard %d   Trashed %d" % [game.deck.size(), game.discard.size(), game.trash.size()], 15, MUTED))


func _build_setup() -> void:
	var verb := "start at Level %d" % game.setup_level
	root.add_child(_label("%s: choose %d of these cards to %s." % [DIFFICULTIES[menu.difficulty], game.setup_picks, verb], 18, TEXT, true))
	_add_cards(game.setup_offer, _on_pick_card, func(id): return {"badge": "CHOSEN" if picks.has(id) else ""})
	root.add_child(_button("Confirm (%d/%d)" % [picks.size(), game.setup_picks], _on_confirm_setup,
		picks.size() == game.setup_picks, true))


func _build_challenge() -> void:
	if last_summary != "":
		root.add_child(_label(last_summary, 14, MUTED, true))
	var enc: Dictionary = game.encounter()
	root.add_child(_encounter_panel(enc))
	var p: Dictionary = game.preview(_current_action())
	root.add_child(_label(p.error if p.has("error") else _preview_text(p, enc), 17, MUTED if p.has("error") else TEXT))
	_add_slots(1, enc.kind == "enemy")

	var opts := _grid(3)
	if game.options.get("cavalier", false) == false and game.hand.size() == 4:
		opts.add_child(_button("Unfuse" if fuse != null else "Fuse", _on_fuse, true, fuse != null or mode.begins_with("fuse")))
	opts.add_child(_button("Divert (%d left)" % (Game.MAX_DIVERTS - game.diverts), _on_mode.bind("divert"),
		game.diverts < Game.MAX_DIVERTS and game.deck.size() >= 2, mode == "divert"))
	if enc.kind == "enemy" and enc.data.ability == "ranged":
		opts.add_child(_button("Give up Reserve", _on_ranged, true, ranged_discard))
	root.add_child(opts)
	_add_mode_hint()
	_add_cards(game.hand, _on_hand_card, _hand_info)
	root.add_child(_button("Play", _on_play, not p.has("error"), true))


func _build_final() -> void:
	if last_summary != "":
		root.add_child(_label(last_summary, 14, MUTED, true))
	var journey: bool = game.phase == "final_journey"
	root.add_child(_dragon_panel(journey))
	var p: Dictionary = game.preview_final(_current_action())
	root.add_child(_label(p.error if p.has("error") else _final_text(p, journey), 17, MUTED if p.has("error") else TEXT))
	_add_slots(2, not journey)
	var opts := _grid(3)
	if not game.options.get("cavalier", false):
		opts.add_child(_button("Unfuse" if fuse != null else "Fuse", _on_fuse, true, fuse != null or mode.begins_with("fuse")))
	if journey:
		opts.add_child(_button("Regroup", _on_mode.bind("regroup"), not game._regrouped, mode == "regroup"))
	root.add_child(opts)
	_add_mode_hint()
	_add_cards(game.hand, _on_hand_card, _hand_info)
	root.add_child(_button("Play", _on_play, not p.has("error"), true))


func _build_soak() -> void:
	if last_summary != "":
		root.add_child(_label(last_summary, 15, TEXT, true))
	var total := 0
	for id in picks:
		total += game._soak_value(id)
	var kind: String = (game.damage_element + " ") if game.damage_element != "" else ""
	var title := "Poison: soak %d damage." if game.phase == "poison" else "Soak %d " + kind + "damage."
	root.add_child(_label(title % game.damage_due, 20, WARN))
	root.add_child(_label("Tap cards to Downgrade them. Each soaks its Armor; matching Armor soaks more. Soaked so far: %d." % total, 15, MUTED, true))
	_add_cards(game.hand, _on_pick_card, func(id):
		var order := picks.find(id)
		return {"badge": "DOWNGRADE %d" % (order + 1) if order >= 0 else "",
			"note": "Soaks %d" % game._soak_value(id), "disabled": game.downgraded.has(id)})
	root.add_child(_button("Take the damage", _on_confirm_soak, total >= game.damage_due, true))


func _build_upgrade() -> void:
	root.add_child(_label(last_summary, 15, TEXT, true))
	root.add_child(_label("XP to spend: %d" % game.xp, 22, ACCENT))
	if game.xp > 0:
		root.add_child(_label("Tap a card to Upgrade it. Unspent XP is lost.", 15, MUTED))
	_add_cards(game.hand, _on_upgrade_card, func(id):
		var cost = game.level_data(id).upgrade_cost
		var blocked: bool = game.downgraded.has(id) or cost == null or cost > game.xp
		return {"note": "Downgraded" if game.downgraded.has(id) else "", "disabled": blocked})
	root.add_child(_button("Continue", _on_finish, true, true))


func _build_end() -> void:
	root.add_child(_label(last_summary, 15, MUTED, true))
	if game.phase == "won":
		root.add_child(_label("%s is defeated!" % game.dragon.name, 32, ACCENT))
		root.add_child(_label("Score: %d" % game.score(), 26))
	else:
		root.add_child(_label("You have perished.", 32, WARN))
		root.add_child(_label("Score: 0", 26))
	root.add_child(_button("New game", _on_new_game, true, true))


# ---------------------------------------------------------------- pieces

func _encounter_panel(enc: Dictionary) -> Control:
	var d: Dictionary = enc.data
	var enemy: bool = enc.kind == "enemy"
	var color: Color = ELEMENT_COLORS[d.attack.element if enemy else d.mp.element]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, color, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var head := _hbox(8)
	head.add_child(_icon("enemy" if enemy else "journey", 28, color))
	head.add_child(_label("%s %d" % ["Enemy" if enemy else "Journey", enc.index], 22, color))
	box.add_child(head)

	var stats := _hbox(10)
	if enemy:
		stats.add_child(_chip("hp", str(d.hp), 46, HP_COLOR))
		stats.add_child(_chip("initiative", str(d.initiative), 44, CHIP))
		stats.add_child(_pill([_label(str(d.attack.value), 22, BG), _icon("attack", 22, BG), _icon(d.attack.element, 18, BG)], color))
		for a in d.armor:
			stats.add_child(_chip("armor", str(a.value), 44, ELEMENT_COLORS[a.element], BG))
	else:
		stats.add_child(_pill([_icon("mp", 22, BG), _label(str(d.mp.value), 22, BG), _icon(d.mp.element, 18, BG)], color))
		stats.add_child(_pill([_icon("time", 20), _label(str(d.time_penalty), 22)], CHIP))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(gap)
	stats.add_child(_chip("xp", str(d.xp), 48, ACCENT, BG))
	box.add_child(stats)

	if enemy and d.ability != null:
		box.add_child(_icon_line(d.ability, ABILITIES[d.ability], ACCENT))
	if not enemy and d.peril != null:
		box.add_child(_icon_line(d.peril, PERILS[d.peril], ACCENT))
	if enc.hardship != null:
		box.add_child(_icon_line(enc.hardship, HARDSHIPS[enc.hardship], WARN))
	box.add_child(_label("Key Card: %s" % db.mage(game.key_card()).name, 13, MUTED))
	return panel


func _dragon_panel(journey: bool) -> Control:
	var d: Dictionary = game.dragon
	var color: Color = ELEMENT_COLORS[d.early_damage.element]
	var lines := []
	if journey:
		lines.append(["The Final Journey", 22, color])
		lines.append(["Add the Move of two Action Sets. Reach a tier to pay its time penalty; miss the first and you lose.", 15, MUTED])
		for t in d.mp_tiers:
			lines.append(["Move %d %s  →  time penalty %d" % [t.mp.value, t.mp.element, t.time_penalty], 17, TEXT])
	else:
		lines.append(["The Final Enemy", 22, color])
		lines.append(["Initiative %d    Early damage %d %s" % [d.initiative, d.early_damage.value, d.early_damage.element], 17, TEXT])
		var armor := []
		for a in d.armor:
			armor.append("%d vs %s" % [a.value, a.element])
		lines.append(["Armor %s" % ", ".join(armor), 16, TEXT])
		for t in d.hp_tiers:
			lines.append(["Attack %d  →  take %d damage" % [t.hp, t.attack.value], 17, TEXT])
		if game.carried_damage > 0:
			lines.append(["Plus %d damage carried from the journey." % game.carried_damage, 15, WARN])
	return _text_panel(lines, color)


func _preview_text(r: Dictionary, enc: Dictionary) -> String:
	var lines := []
	if enc.kind == "enemy":
		lines.append("Attack %d vs HP %d: %s" % [r.attack, enc.data.hp, OUTCOMES[r.outcome]])
		lines.append("Initiative %d vs %d: %s" % [r.initiative, enc.data.initiative,
			("early damage %d" % r.early_damage) if r.early else "no early damage"])
	else:
		lines.append("Move %d vs MP %d: %s" % [r.move, r.mp, OUTCOMES[r.outcome]])
	var tail := ["XP +%d" % r.xp]
	if r.damage > 0:
		tail.append("Damage %d" % r.damage)
	if r.time_penalty > 0:
		tail.append("Time penalty %d" % r.time_penalty)
	if r.get("poison", 0) > 0:
		tail.append("Poison %d" % r.poison)
	if r.get("discard_reserve", false):
		tail.append("Reserve discarded")
	lines.append("   ".join(tail))
	return "\n".join(lines)


func _final_text(r: Dictionary, journey: bool) -> String:
	if journey:
		if r.tier < 0:
			return "Total Move %d: below the first tier. You would lose." % r.move
		return "Total Move %d: tier %d, time penalty %d." % [r.move, r.tier + 1, r.time_penalty]
	if r.tier < 0:
		return "Total Attack %d: below the first tier. You would lose." % r.attack
	var early := "early damage" if r.early else "no early damage"
	var fate := "You can survive this." if r.survivable else "Your Hand cannot soak this. You would lose."
	return "Total Attack %d: tier %d.\nInitiative %d vs %d: %s.\nDamage to soak: %d. %s" % [
		r.attack, r.tier + 1, r.initiative, game.dragon.initiative, early, r.damage, fate]


func _add_slots(count: int, show_boost_target: bool) -> void:
	for i in count:
		var row := _grid(4 if show_boost_target else 3)
		for role in ROLES:
			var id = sets[i].get(role)
			var name: String = db.mage(id).name if id != null else "tap a card"
			var head: String = role.capitalize() + (" %d" % (i + 1) if count > 1 else "")
			row.add_child(_button("%s\n%s" % [head, name], _on_slot.bind(i, role), true, active == [i, role]))
		if show_boost_target:
			row.add_child(_button("Boost adds to\n%s" % boost_to[i].capitalize(), _on_boost_to.bind(i)))
		root.add_child(row)


func _add_mode_hint() -> void:
	var hints := {
		"divert": "Divert: tap the Hand card to discard along with the Key Card.",
		"regroup": "Regroup: tap one card to discard. The rest are shuffled back and you draw again.",
		"fuse": "Fuse: tap the card you will play, then the card to tuck behind it.",
		"fuse_element": "Choose the Ether element the fused card counts as:",
	}
	if not hints.has(mode):
		return
	root.add_child(_label(hints[mode], 16, ACCENT, true))
	if mode == "fuse_element":
		var row := _grid(4)
		for e in ELEMENT_COLORS:
			var b := _button(e.capitalize(), _on_fuse_element.bind(e))
			_tint(b, ELEMENT_COLORS[e], false)
			row.add_child(b)
		root.add_child(row)


func _hand_info(id: String) -> Dictionary:
	var slot = _slot_of(id)
	var badge := ""
	if slot != null:
		badge = slot[1].to_upper() + (" %d" % (slot[0] + 1) if _set_count() > 1 else "")
	elif fuse != null and fuse.bottom == id:
		badge = "TUCKED"
	elif fuse_pick.has(id):
		badge = "FUSING"
	elif _filled() and game._reserve(sets.slice(0, _set_count()), fuse) == id:
		badge = "RESERVE"
	var note := ""
	if fuse != null and fuse.top == id:
		note = "Fused: counts as %s" % fuse.element
	return {"badge": badge, "note": note}


func _add_cards(ids: Array, on_press: Callable, info: Callable) -> void:
	var grid := _grid(4)
	for id in ids:
		var extra: Dictionary = info.call(id)
		grid.add_child(_card(id, on_press, extra.get("badge", ""), extra.get("note", ""), extra.get("disabled", false)))
	root.add_child(grid)


## A card face laid out like the printed cards: Level and name across the top,
## then Initiative, basic action, enhanced action, Boost and Armor down the left edge.
func _card(id: String, on_press: Callable, badge: String, note: String, disabled: bool) -> Button:
	var m: Dictionary = db.mage(id)
	var lv: Dictionary = game.level_data(id)
	var color: Color = ELEMENT_COLORS[m.element]
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 306)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = disabled
	b.pressed.connect(on_press.bind(id))
	var chosen := badge != ""
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, _box(PANEL_HI if chosen else PANEL, ACCENT if chosen else color, 4 if chosen else 2))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	box.add_theme_constant_override("separation", 5)
	box.modulate.a = 0.45 if disabled else 1.0
	b.add_child(box)

	var head := _hbox(4)
	head.add_child(_chip("crown", str(game.cards[id].level), 30, ACCENT, BG))
	head.add_child(_icon(m.element, 18, color))
	var name := _label(m.name, 14, TEXT, true)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.custom_minimum_size.y = 40
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(name)
	box.add_child(head)

	# What this card asks for when it is the Key Card.
	var key := _hbox(3)
	key.add_child(_icon(lv.encounter.type, 15, MUTED))
	key.add_child(_label(str(lv.encounter.index), 13, MUTED))
	if lv.hardship != null:
		key.add_child(_icon(lv.hardship, 15, WARN))
	box.add_child(key)

	var body := _hbox(0)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 5)
	stats.add_child(_chip("initiative", str(lv.initiative), 34, CHIP))
	stats.add_child(_action_pill(lv.basic, CHIP))
	stats.add_child(_action_pill(lv.enhanced, ELEMENT_COLORS[lv.enhanced.element]))
	stats.add_child(_pill([_icon("boost", 15), _label("+%d" % lv.boost, 17)], CHIP))
	if lv.armor.element != null:
		stats.add_child(_chip("armor", str(lv.armor.value), 36, ELEMENT_COLORS[lv.armor.element], BG))
	else:
		stats.add_child(_chip("armor", str(lv.armor.value), 36, CHIP))
	body.add_child(stats)
	var emblem := _icon(m.element, 56, Color(color, 0.2))
	emblem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	emblem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(emblem)
	box.add_child(body)

	var foot := _hbox(3)
	foot.add_child(_icon("xp", 15, MUTED))
	foot.add_child(_label(str(lv.upgrade_cost) if lv.upgrade_cost != null else "max", 13, MUTED))
	box.add_child(foot)
	if note != "":
		box.add_child(_label(note, 12, WARN, true))
	if badge != "":
		box.add_child(_label(badge, 13, ACCENT))
	_ignore_mouse(box)
	return b


## A number with the icons for its action type, on a rounded background.
func _action_pill(action: Dictionary, bg: Color) -> Control:
	var fg := TEXT if bg == CHIP else BG
	var items: Array = [_label(str(action.value), 17, fg)]
	if action.type != "move":
		items.append(_icon("attack", 16, fg))
	if action.type != "attack":
		items.append(_icon("move", 16, fg))
	return _pill(items, bg)


func _pill(items: Array, bg: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(7)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := _hbox(3)
	for item in items:
		row.add_child(item)
	panel.add_child(row)
	return panel


## A number drawn on top of an icon shape (shield, banner, heart, star, crown).
func _chip(icon: String, text: String, side: int, color: Color, text_color := TEXT) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(side, side)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var shape := _icon(icon, side, color)
	shape.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(shape)
	var l := _label(text, int(side * 0.46), text_color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	if icon == "crown" or icon == "hp":
		l.offset_top = side * 0.12
	c.add_child(l)
	return c


func _icon(icon: String, side: int, color := TEXT) -> TextureRect:
	if not _icons.has(icon):
		_icons[icon] = load("res://art/icons/%s.svg" % icon)
	var t := TextureRect.new()
	t.texture = _icons[icon]
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(side, side)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.modulate = color
	return t


func _icon_line(icon: String, text: String, color: Color) -> HBoxContainer:
	var row := _hbox(6)
	row.add_child(_icon(icon, 20, color))
	var l := _label(text, 15, color, true)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	return row


func _hbox(separation: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	return row


## Card contents must not swallow the tap meant for the card.
func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_ignore_mouse(child)


func _text_panel(lines: Array, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(PANEL, border, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	for l in lines:
		box.add_child(_label(l[0], l[1], l[2], l[1] <= 15))
	return panel


func _label(text: String, font_size := 16, color := TEXT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, on_press: Callable, enabled := true, highlighted := false) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = not enabled
	b.custom_minimum_size.y = 56
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_disabled_color", Color(MUTED, 0.5))
	b.pressed.connect(on_press)
	_tint(b, ACCENT if highlighted else MUTED, highlighted)
	return b


func _tint(b: Button, border: Color, highlighted: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, _box(PANEL_HI if highlighted else PANEL, border, 3 if highlighted else 1))
	b.add_theme_stylebox_override("disabled", _box(BG, Color(MUTED, 0.3), 1))


func _box(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(10)
	return s


func _grid(columns: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	return g


# ---------------------------------------------------------------- choices

func _set_count() -> int:
	return 2 if game.phase.begins_with("final") else 1


func _slot_of(id: String) -> Variant:
	for i in sets.size():
		for role in ROLES:
			if sets[i].get(role) == id:
				return [i, role]
	return null


func _filled() -> bool:
	for i in _set_count():
		if sets[i].size() < ROLES.size():
			return false
	return true


func _advance() -> void:
	for i in _set_count():
		for role in ROLES:
			if not sets[i].has(role):
				active = [i, role]
				return


func _unassign(id: String) -> void:
	var slot = _slot_of(id)
	if slot != null:
		sets[slot[0]].erase(slot[1])


func _current_action() -> Dictionary:
	if _set_count() == 1:
		var a: Dictionary = sets[0].duplicate()
		a["boost_to"] = boost_to[0]
		a["ranged_discard"] = ranged_discard
		if fuse != null:
			a["fuse"] = fuse
		return a
	var out := {"sets": []}
	for i in 2:
		var s: Dictionary = sets[i].duplicate()
		s["boost_to"] = boost_to[i]
		out.sets.append(s)
	if fuse != null:
		out["fuse"] = fuse
	return out


func _reset_turn() -> void:
	sets = [{}, {}]
	active = [0, "spell"]
	boost_to = ["attack", "attack"]
	fuse = null
	fuse_pick = []
	mode = ""
	ranged_discard = false
	picks = []
	message = ""


# ---------------------------------------------------------------- handlers

func _set_menu(key: String, value) -> void:
	menu[key] = value
	_refresh()


func _on_start() -> void:
	var opts := menu.duplicate()
	opts["seed"] = randi()
	start_game(opts)


func _on_new_game() -> void:
	game = null
	_refresh()


func _on_pick_card(id: String) -> void:
	message = ""
	if picks.has(id):
		picks.erase(id)
	elif game.phase == "setup":
		if picks.size() < game.setup_picks:
			picks.append(id)
	else:
		var total := 0
		for p in picks:
			total += game._soak_value(p)
		if total >= game.damage_due:
			message = "The damage is already covered."
		else:
			picks.append(id)
	_refresh()


func _on_confirm_setup() -> void:
	var err: String = game.choose_setup_cards(picks)
	_reset_turn()
	message = err
	_refresh()


func _on_confirm_soak() -> void:
	var err: String = game.soak(picks)
	if err == "":
		_reset_turn()
	message = err
	_refresh()


func _on_slot(i: int, role: String) -> void:
	active = [i, role]
	_refresh()


func _on_boost_to(i: int) -> void:
	boost_to[i] = "initiative" if boost_to[i] == "attack" else "attack"
	_refresh()


func _on_ranged() -> void:
	ranged_discard = not ranged_discard
	_refresh()


func _on_mode(m: String) -> void:
	mode = "" if mode == m else m
	message = ""
	_refresh()


func _on_fuse() -> void:
	message = ""
	fuse_pick = []
	if fuse != null or mode.begins_with("fuse"):
		fuse = null
		mode = ""
	else:
		mode = "fuse"
	_refresh()


func _on_fuse_element(element: String) -> void:
	fuse = {"top": fuse_pick[0], "bottom": fuse_pick[1], "element": element}
	_unassign(fuse.bottom)
	_advance()
	fuse_pick = []
	mode = ""
	_refresh()


func _on_hand_card(id: String) -> void:
	message = ""
	match mode:
		"divert":
			message = game.divert(id)
			mode = ""
			if message == "":
				_unassign(id)
				_advance()
				if fuse != null:
					fuse = null
		"regroup":
			var err: String = game.regroup(id)
			_reset_turn()
			message = err
		"fuse":
			if not fuse_pick.has(id):
				fuse_pick.append(id)
			if fuse_pick.size() == 2:
				if db.mage(fuse_pick[0]).element == db.mage(fuse_pick[1]).element:
					mode = "fuse_element"
				else:
					message = "Fused cards must share an Ether element."
					fuse_pick = []
					mode = ""
		"fuse_element":
			pass
		_:
			var slot = _slot_of(id)
			if slot != null:
				sets[slot[0]].erase(slot[1])
				active = slot
			elif fuse != null and fuse.bottom == id:
				message = "That card is tucked behind another. Unfuse to use it."
			else:
				sets[active[0]][active[1]] = id
				_advance()
	_refresh()


func _on_play() -> void:
	var a := _current_action()
	var summary := ""
	var err := ""
	if game.phase == "challenge":
		var enc: Dictionary = game.encounter()
		var p: Dictionary = game.preview(a)
		err = game.play(a)
		if err == "":
			summary = "%s %d\n%s" % [enc.kind.capitalize(), enc.index, _preview_text(p, enc)]
			if game.result.knocked_out:
				summary += "\nKnocked Out! Every card was Downgraded and four cards were lost from the deck."
	else:
		var journey: bool = game.phase == "final_journey"
		var p: Dictionary = game.preview_final(a)
		err = game.play_final(a)
		if err == "":
			summary = _final_text(p, journey).replace("would lose", "lose").replace("can survive this", "must survive this")
	if err == "":
		_reset_turn()
		last_summary = summary
	message = err
	_refresh()


func _on_upgrade_card(id: String) -> void:
	message = game.upgrade(id)
	_refresh()


func _on_finish() -> void:
	var err: String = game.finish()
	if err == "":
		_reset_turn()
		if game.phase == "challenge" or game.phase == "poison":
			last_summary = ""
	message = err
	_refresh()
