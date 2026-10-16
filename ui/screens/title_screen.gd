extends Control
## The title screen and first setup step: choose a dragon, then continue to the
## difficulty and alternate rules.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Art = preload("res://ui/model/art.gd")
const Creature = preload("res://ui/fx/creature.gd")
const DragonStats = preload("res://ui/widgets/dragon_stats.gd")

signal intent(data: Dictionary)

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
	var ether: String = db.dragon(options.dragon).early_damage.element
	var crest := Creature.new()
	crest.custom_minimum_size = Vector2(170, 170)
	crest.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	crest.setup(Art.dragon(options.dragon), T.ether(ether).lightened(0.15), ether)
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
	left.add_child(UI.label("Fan-made digital version. Game by Joe Klipfel, published by Chip Theory Games. Not affiliated with or endorsed by Chip Theory Games. Creature and landscape art made for this project.", T.LABEL, T.INK_MUTED, true))
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
		var colour: Color = T.ether(d.early_damage.element)
		var tile: Button = ChoiceTile.make(d.name, d.title, "../creatures/" + Art.dragon(id), colour, null, 80.0, DragonStats.make(d))
		tile.custom_minimum_size.y = 160
		tile.tooltip_text = DragonStats.ladder_text(d)
		tile.pressed.connect(_choose.bind(id))
		dragons.add_child(tile)
		_tiles["dragon:" + id] = tile
	right.add_child(dragons)
	var bottom := UI.hbox(T.S)
	bottom.custom_minimum_size.y = T.TAP_MIN
	# New players meet the rules beside their first choice.
	var learn := UI.button("How to Play", "normal", "book")
	learn.custom_minimum_size.x = 260
	learn.pressed.connect(func(): intent.emit({"type": "rulebook"}))
	bottom.add_child(learn)
	var records := UI.button("Records", "normal", "trophy")
	records.custom_minimum_size.x = 220
	records.pressed.connect(func(): intent.emit({"type": "records", "from": "title"}))
	bottom.add_child(records)
	bottom.add_child(UI.spacer())
	var next := UI.button("Continue", "primary")
	next.custom_minimum_size.x = 240
	next.pressed.connect(func(): intent.emit({"type": "setup_rules", "options": options.duplicate()}))
	bottom.add_child(next)
	right.add_child(bottom)
	root.add_child(right)
	_refresh()
	next.grab_focus.call_deferred()


func _heading(text: String) -> Label:
	return UI.label(text.to_upper(), ["display", 24], T.GOLD)


func _choose(id: String) -> void:
	options.dragon = id
	_build()


func _refresh() -> void:
	for id in db.dragon_ids():
		_tiles["dragon:" + id].selected = options.dragon == id
