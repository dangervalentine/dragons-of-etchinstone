extends Control
## The title screen: choose a dragon, a difficulty and any alternate rules, each
## saying what it changes, then set out.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Game = preload("res://engine/game.gd")

signal intent(data: Dictionary)

const DIFFICULTIES := [
	["casual", "Casual"], ["easy", "Easy"], ["normal", "Normal"],
	["hard", "Hard"], ["impossible", "Impossible"], ["dont_even_try", "Don't Even Try It"],
]

var db
var options := {}
var _tiles := {}
var _layout := Control.new()
var _content := Rect2(16, 16, 1248, 688)


func setup(card_db, opts: Dictionary) -> void:
	db = card_db
	options = opts.duplicate()
	_build()


func apply_layout(content: Rect2) -> void:
	_content = content
	_layout.position = content.position
	_layout.size = content.size


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tiles = {}
	_layout = Control.new()
	add_child(_layout)
	apply_layout(_content)
	var root := UI.hbox(T.XL)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(root)

	# Left: the name of the game and the way out to settings and help.
	var left := UI.vbox(T.M)
	left.custom_minimum_size.x = 380
	left.size_flags_stretch_ratio = 0.6
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var crest := UI.icon_rect("sigil_" + options.dragon, 132, T.ether(db.dragon(options.dragon).early_damage.element))
	crest.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(crest)
	left.add_child(UI.label("DRAGONS OF\nETCHINSTONE", ["display_bold", 54], T.GOLD))
	left.add_child(UI.label("A solo card game of four Regions and one dragon.", T.BODY, T.INK, true))
	left.add_child(UI.spacer())
	var tools := UI.hbox(T.S)
	var settings := UI.button("Settings", "quiet", "settings")
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(func(): intent.emit({"type": "settings"}))
	tools.add_child(settings)
	var help := UI.button("Glossary", "quiet", "help")
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help.pressed.connect(func(): intent.emit({"type": "glossary"}))
	tools.add_child(help)
	left.add_child(tools)
	left.add_child(UI.label("Fan-made digital version. Game by Joe Klipfel, published by Chip Theory Games. Not affiliated with or endorsed by Chip Theory Games.", T.LABEL, T.INK_MUTED, true))
	root.add_child(left)

	# Right: the choices.
	var right := UI.vbox(T.S)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(_heading("Hunt a dragon"))
	var dragons := GridContainer.new()
	dragons.columns = 2
	dragons.add_theme_constant_override("h_separation", T.S)
	dragons.add_theme_constant_override("v_separation", T.S)
	dragons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for id in db.dragon_ids():
		var d: Dictionary = db.dragon(id)
		var desc := "%s\nInitiative %d · early damage %d" % [d.title, d.initiative, d.early_damage.value]
		var colour: Color = T.ether(d.early_damage.element)
		var tile: Button = ChoiceTile.make(d.name, desc, "sigil_" + id, colour)
		tile.custom_minimum_size.y = 104
		tile.pressed.connect(_choose.bind("dragon", id))
		dragons.add_child(tile)
		_tiles["dragon:" + id] = tile
	right.add_child(dragons)
	right.add_child(_heading("Difficulty"))
	var diffs := GridContainer.new()
	diffs.columns = 3
	diffs.add_theme_constant_override("h_separation", T.S)
	diffs.add_theme_constant_override("v_separation", T.S)
	diffs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for entry in DIFFICULTIES:
		var tile: Button = ChoiceTile.make(entry[1], _difficulty_text(entry[0]))
		tile.pressed.connect(_choose.bind("difficulty", entry[0]))
		diffs.add_child(tile)
		_tiles["difficulty:" + entry[0]] = tile
	right.add_child(diffs)
	right.add_child(_heading("Alternate rules"))
	var bottom := UI.hbox(T.S)
	bottom.custom_minimum_size.y = T.TAP_MIN
	var cav: Button = ChoiceTile.make("Cavalier", "No Fusing")
	cav.pressed.connect(_choose.bind("cavalier", null))
	bottom.add_child(cav)
	_tiles["cavalier"] = cav
	var glass: Button = ChoiceTile.make("Glass Cannon", "Matching Armor Soaks only +1")
	glass.pressed.connect(_choose.bind("glass_cannon", null))
	bottom.add_child(glass)
	_tiles["glass_cannon"] = glass
	var start := UI.button("Set out", "primary")
	start.custom_minimum_size.x = 240
	start.pressed.connect(func(): intent.emit({"type": "start", "options": options.duplicate()}))
	bottom.add_child(start)
	right.add_child(bottom)
	root.add_child(right)
	_refresh()
	start.grab_focus.call_deferred()


func _heading(text: String) -> Label:
	return UI.label(text.to_upper(), ["display", 24], T.GOLD)


func _difficulty_text(key: String) -> String:
	var d: Array = Game.DIFFICULTY[key]
	if d[1] == 0:
		return "Every card starts at Level %d" % d[2]
	if d[1] >= d[0]:
		return "%d random cards start at Level %d" % [d[1], d[2]]
	return "Choose %d of %d to start at Level %d" % [d[1], d[0], d[2]]


func _choose(key: String, value) -> void:
	if value == null:
		options[key] = not options[key]
	else:
		options[key] = value
	if key == "dragon":
		_build()
		return
	_refresh()


func _refresh() -> void:
	for id in db.dragon_ids():
		_tiles["dragon:" + id].selected = options.dragon == id
	for entry in DIFFICULTIES:
		_tiles["difficulty:" + entry[0]].selected = options.difficulty == entry[0]
	_tiles["cavalier"].selected = options.cavalier
	_tiles["glass_cannon"].selected = options.glass_cannon
