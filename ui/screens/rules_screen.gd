extends Control
## The second setup step: a difficulty and any alternate rules, each saying what
## it changes, then set out or go back to the dragons.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Game = preload("res://engine/game.gd")

signal intent(data: Dictionary)

const DIFFICULTIES := [
	["casual", "Casual"], ["easy", "Easy"], ["normal", "Normal"],
	["hard", "Hard"], ["impossible", "Impossible"], ["dont_even_try", "Don't Even Try It"],
]

var heading := "Difficulty and Rules"
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
	var root := UI.vbox(T.SPACE_2)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(root)

	# The choices, as the elders' proclamation on a slab of stone across the screen.
	var slab := UI.slab(Color(T.SHADE, 0), 14)
	slab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var right := UI.vbox(T.SPACE_2)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slab.add_child(right)
	var decree := UI.hbox(T.SPACE_2)
	decree.add_child(UI.icon_rect("orn_tower", 34, T.EDGE))
	var by_order := UI.carved_label("By order of the Tower", T.LABEL, T.PARCHMENT_MUTED)
	by_order.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	decree.add_child(by_order)
	right.add_child(decree)
	right.add_child(_heading("Difficulty"))
	var diffs := GridContainer.new()
	diffs.columns = 3
	diffs.add_theme_constant_override("h_separation", T.SPACE_2)
	diffs.add_theme_constant_override("v_separation", T.SPACE_2)
	diffs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for entry in DIFFICULTIES:
		var tile: Button = ChoiceTile.make(entry[1], _difficulty_text(entry[0]))
		tile.pressed.connect(_choose.bind("difficulty", entry[0]))
		diffs.add_child(tile)
		_tiles["difficulty:" + entry[0]] = tile
	right.add_child(diffs)
	var divider := UI.icon_rect("orn_divider", 24, T.EDGE)
	divider.size_flags_horizontal = Control.SIZE_FILL
	divider.custom_minimum_size = Vector2(0, 16)
	right.add_child(divider)
	right.add_child(_heading("Alternate rules"))
	var rules := UI.hbox(T.SPACE_2)
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
	root.add_child(slab)
	# Set out where the dragon screen keeps Continue. Back is in the title bar.
	var bottom := UI.hbox(T.SPACE_2)
	bottom.custom_minimum_size.y = T.TAP_MIN
	bottom.add_child(UI.spacer())
	var start := UI.button("Set out", "primary")
	start.custom_minimum_size.x = 240
	start.pressed.connect(func(): intent.emit({"type": "start", "options": options.duplicate()}))
	bottom.add_child(start)
	root.add_child(bottom)
	_refresh()
	start.grab_focus.call_deferred(true)


func _heading(text: String) -> Label:
	return UI.label(text, T.LABEL, T.PARCHMENT_MUTED)


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
