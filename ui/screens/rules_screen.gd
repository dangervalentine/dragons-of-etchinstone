extends Control
## The second setup step: a difficulty and any alternate rules, each saying what
## it changes, then set out or go back to the dragons.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Game = preload("res://engine/game.gd")
const Editions = preload("res://ui/model/editions.gd")
const DragonScreen = preload("res://ui/screens/dragon_screen.gd")

signal intent(data: Dictionary)

const DIFFICULTIES := [
	["casual", "Casual"], ["easy", "Easy"], ["normal", "Normal"],
	["hard", "Hard"], ["impossible", "Impossible"], ["dont_even_try", "Don't Even Try It"],
]

## The room inside each cell round its choices.
const CELL_PAD := T.SPACE_3

var heading := "Difficulty and Rules"
var db
var options := {}
var _tiles := {}
var _layout := Control.new()
var _frame: Control
var _content := Rect2(16, 16, 1248, 688)


func setup(card_db, opts: Dictionary) -> void:
	db = card_db
	# Under Classic no house rule is offered, so none may be carried in (editions.gd).
	options = Editions.apply(opts)
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

	# A table as the dragon screen's, the same size and place (owner, 2026-10-23):
	# its rules showing between a cell for the difficulty and one for the alternate
	# rules, each holding its choices well in from its edges.
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UI.box(T.LINE, T.LINE, DragonScreen.RULE, DragonScreen.TABLE_RADIUS, DragonScreen.RULE))
	_frame = frame
	var table := UI.vbox(DragonScreen.RULE)
	frame.add_child(table)
	root.add_child(UI.spacer())
	root.add_child(frame)
	root.add_child(UI.spacer())
	_layout.resized.connect(_fit_table)

	var top := UI.vbox(T.SPACE_2)
	var decree := UI.hbox(T.SPACE_2)
	decree.add_child(UI.icon_rect("orn_tower", 34, T.EDGE))
	var by_order := UI.carved_label("By order of the Tower", T.LABEL, T.PARCHMENT_MUTED)
	by_order.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	decree.add_child(by_order)
	decree.add_child(UI.spacer())
	decree.add_child(_heading("Difficulty"))
	top.add_child(decree)
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
	top.add_child(diffs)
	var top_cell := _cell(top, true)
	top_cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.add_child(top_cell)

	var foot := UI.vbox(T.SPACE_2)
	foot.add_child(_heading("Alternate rules"))
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
	# The house rule beside the rulebook's two, under House rules only.
	if Editions.offers("persistent_xp"):
		var keep: Button = ChoiceTile.make("Persistent XP", "Unspent XP carries over")
		keep.pressed.connect(_choose.bind("persistent_xp", null))
		rules.add_child(keep)
		_tiles["persistent_xp"] = keep
	foot.add_child(rules)
	table.add_child(_cell(foot, false))
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
	_fit_table()
	start.grab_focus.call_deferred(true)


## A cell of the table holding `content`, held well in from its rules (CELL_PAD);
## the top cell takes the table's top corners, the other its foot's.
func _cell(content: Control, first: bool) -> PanelContainer:
	var cell := PanelContainer.new()
	var face := UI.box(T.STONE, Color.TRANSPARENT, 0, 0, CELL_PAD)
	var r := DragonScreen.TABLE_RADIUS - DragonScreen.RULE
	face.corner_radius_top_left = r if first else 0
	face.corner_radius_top_right = face.corner_radius_top_left
	face.corner_radius_bottom_left = 0 if first else r
	face.corner_radius_bottom_right = face.corner_radius_bottom_left
	cell.add_theme_stylebox_override("panel", face)
	cell.add_child(content)
	return cell


## As tall as the dragon screen's table on this layout, or as the choices need.
func _fit_table() -> void:
	if _frame != null and is_instance_valid(_frame):
		_frame.custom_minimum_size.y = DragonScreen.table_height(_layout.size)


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
		options[key] = not options.get(key, false)
	else:
		options[key] = value
	_refresh()


func _refresh() -> void:
	for entry in DIFFICULTIES:
		_tiles["difficulty:" + entry[0]].selected = options.difficulty == entry[0]
	_tiles["cavalier"].selected = options.cavalier
	_tiles["glass_cannon"].selected = options.glass_cannon
	if _tiles.has("persistent_xp"):
		_tiles["persistent_xp"].selected = options.get("persistent_xp", false)
