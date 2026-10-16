extends Control
## The second setup step: the chosen dragon, a difficulty and any alternate rules,
## each saying what it changes, then set out or go back to the dragons.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Game = preload("res://engine/game.gd")
const Art = preload("res://ui/model/art.gd")
const Creature = preload("res://ui/fx/creature.gd")

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


## Back to the dragons, keeping every choice made here.
func back() -> void:
	intent.emit({"type": "setup_dragon", "options": options.duplicate()})


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

	# Left: the dragon being hunted.
	var d: Dictionary = db.dragon(options.dragon)
	var ether: String = d.early_damage.element
	var left := UI.vbox(T.M)
	left.custom_minimum_size.x = 380
	left.size_flags_stretch_ratio = 0.6
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var crest := Creature.new()
	crest.custom_minimum_size = Vector2(170, 170)
	crest.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	crest.setup(Art.dragon(options.dragon), T.ether(ether).lightened(0.15), ether)
	left.add_child(crest)
	left.add_child(UI.label(d.name.to_upper(), ["display_bold", 54], T.GOLD))
	left.add_child(UI.label(d.title, T.BODY, T.INK, true))
	left.add_child(UI.label("Initiative %d · early damage %d" % [d.initiative, d.early_damage.value], T.LABEL, T.INK_MUTED, true))
	left.add_child(UI.spacer())
	root.add_child(left)

	# Right: the choices, as the elders' proclamation on a slab of stone.
	var slab := UI.slab(T.GOLD, 14)
	slab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := UI.vbox(T.S)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slab.add_child(right)
	var decree := UI.hbox(T.S)
	decree.add_child(UI.icon_rect("orn_tower", 34, T.muted(T.GOLD)))
	var by_order := UI.carved_label("BY ORDER OF THE TOWER", ["display", 24], T.GOLD)
	by_order.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	decree.add_child(by_order)
	right.add_child(decree)
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
	var divider := UI.icon_rect("orn_divider", 24, T.muted(T.GOLD))
	divider.size_flags_horizontal = Control.SIZE_FILL
	divider.custom_minimum_size = Vector2(0, 16)
	right.add_child(divider)
	right.add_child(_heading("Alternate rules"))
	var rules := UI.hbox(T.S)
	rules.custom_minimum_size.y = T.TAP_MIN
	var cav: Button = ChoiceTile.make("Cavalier", "No Fusing")
	cav.pressed.connect(_choose.bind("cavalier", null))
	rules.add_child(cav)
	_tiles["cavalier"] = cav
	var glass: Button = ChoiceTile.make("Glass Cannon", "Matching Armor Soaks only +1")
	glass.pressed.connect(_choose.bind("glass_cannon", null))
	rules.add_child(glass)
	_tiles["glass_cannon"] = glass
	right.add_child(rules)
	var bottom := UI.hbox(T.S)
	bottom.custom_minimum_size.y = T.TAP_MIN
	var back_button := UI.button("Back", "quiet")
	back_button.custom_minimum_size.x = 200
	back_button.pressed.connect(back)
	bottom.add_child(back_button)
	bottom.add_child(UI.spacer())
	var start := UI.button("Set out", "primary", "orn_seal")
	start.custom_minimum_size.x = 240
	start.pressed.connect(func(): intent.emit({"type": "start", "options": options.duplicate()}))
	bottom.add_child(start)
	right.add_child(bottom)
	root.add_child(slab)
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
	_refresh()


func _refresh() -> void:
	for entry in DIFFICULTIES:
		_tiles["difficulty:" + entry[0]].selected = options.difficulty == entry[0]
	_tiles["cavalier"].selected = options.cavalier
	_tiles["glass_cannon"].selected = options.glass_cannon
