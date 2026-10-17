extends "res://ui/overlays/overlay.gd"
## The menu, opened only from the menu button in the title bar: the settings (Motion,
## the Ground the board stands on and, on a desktop, the Window), each a row with
## its name beside its choices so the whole card fits on the shortest screen, then
## How to Play, the Glossary and Clear records, then the History, the Leaderboard
## and, in a game, Abandon run. The X closes it.

const Settings = preload("res://ui/model/settings.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Stone = preload("res://ui/theme/stone.gd")
const WindowSizer = preload("res://ui/model/window_sizer.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")

## The ground patterns, by number, as the menu names them.
const GROUND_NAMES := ["Lattice", "Ripples", "Columns", "Rain"]
## The widest the card grows, and the width of the column naming each setting.
const WIDTH_MAX := 1040.0
const NAME_W := 150.0

signal intent(data: Dictionary)

var _motion_tiles := {}
var _ground_tiles := {}
var _window_tiles := {}
## The card, to check that it fits.
var panel: Control


## `area` is the room the card has; it is never wider. `window_row` shows the
## Window setting, which only a desktop with a real window has.
func setup(in_game: bool, area := Rect2(16, 16, 1248, 688), window_row := WindowSizer.applies()) -> void:
	var p := UI.slab(T.GOLD, 24)
	panel = p
	p.custom_minimum_size.x = minf(WIDTH_MAX, area.size.x)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := UI.vbox(T.M)
	var top := UI.hbox(T.S)
	var title := UI.label("SETTINGS", T.HEADING, T.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	var close_button := make_close_button()
	top.add_child(close_button)
	col.add_child(top)
	var motion := []
	for entry in [["system", "Follow device", ""], ["reduced", "Reduced", "Fades only"], ["full", "Full", "All animation"]]:
		var tile: Button = ChoiceTile.make(entry[1], entry[2])
		tile.pressed.connect(_set_motion.bind(entry[0]))
		motion.append(tile)
		_motion_tiles[entry[0]] = tile
	col.add_child(_setting("Motion", motion))
	var grounds := []
	for n in range(1, Settings.GROUNDS + 1):
		var tile: Button = ChoiceTile.make(GROUND_NAMES[n - 1], "", "", T.GOLD, null, 56.0, _swatch(n))
		tile.tooltip_text = "Stand the board on the %s pattern" % GROUND_NAMES[n - 1].to_lower()
		tile.pressed.connect(_set_ground.bind(n))
		grounds.append(tile)
		_ground_tiles[n] = tile
	col.add_child(_setting("Ground", grounds))
	if window_row:
		var windows := []
		for entry in [["windowed", "Windowed", "Resizable"], ["fullscreen", "Full screen", "F11"]]:
			var tile: Button = ChoiceTile.make(entry[1], entry[2])
			tile.pressed.connect(_set_window.bind(entry[0]))
			windows.append(tile)
			_window_tiles[entry[0]] = tile
		col.add_child(_setting("Window", windows))
	_refresh()
	# The ways to read up on the rules and clearing the games played, then reading
	# back over them and, in a game, the way out at the bottom right.
	var pages := UI.hbox(T.S)
	var games := UI.hbox(T.S)
	# How to Play and the Glossary come back here when closed.
	for entry in [[pages, "How to Play", "book", {"type": "rulebook", "from": "menu"}], [pages, "Glossary", "glossary", {"type": "glossary", "from": "menu"}],
			[games, "History", "time", {"type": "records", "page": "history", "from": "menu"}],
			[games, "Leaderboard", "trophy", {"type": "records", "page": "leaderboard", "from": "menu"}]]:
		var b := UI.button(entry[1], "quiet", entry[2])
		var data: Dictionary = entry[3]
		b.pressed.connect(func():
			close()
			intent.emit(data))
		entry[0].add_child(b)
	var clear := UI.button("Clear records", "quiet", "trash")
	clear.disabled = HistoryStore.records.is_empty()
	clear.pressed.connect(func(): intent.emit({"type": "records_clear"}))
	pages.add_child(clear)
	if in_game:
		# Lettered in red: a run abandoned cannot be resumed. The dialog that asks
		# first is the red plinth.
		var leave := UI.button("Abandon run", "quiet", "close")
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color",
				"icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			leave.add_theme_color_override(c, T.BAD)
		leave.pressed.connect(func(): intent.emit({"type": "leave"}))
		games.add_child(leave)
	for row in [pages, games]:
		col.add_child(row)
		for b in row.get_children():
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_child(col)
	# Centred in the room it has, not the whole window, which takes in the title bar.
	var room := CenterContainer.new()
	room.position = area.position
	room.size = area.size
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(p)
	add_child(room)
	appear()


## A setting's name, then its choices side by side.
func _setting(name: String, tiles: Array) -> Control:
	var row := UI.hbox(T.M)
	var label := UI.label(name, ["body_bold", T.BODY[1]], T.INK)
	label.custom_minimum_size.x = NAME_W
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var choices := UI.hbox(T.S)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.custom_minimum_size.y = T.TAP_MIN
	for tile in tiles:
		choices.add_child(tile)
	row.add_child(choices)
	return row


func _set_motion(value: String) -> void:
	Settings.motion = value
	Settings.save_all()
	UI.reduced_motion = Settings.reduced_motion()
	_refresh()


func _set_window(value: String) -> void:
	if value != Settings.window_mode:
		WindowSizer.toggle()
	_refresh()


func _set_ground(n: int) -> void:
	Settings.ground = n
	Settings.save_all()
	Stone.reset()
	_refresh()
	intent.emit({"type": "ground"})


## A strip of ground `n`, brightened so the pattern shows at menu size.
func _swatch(n: int) -> Control:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.custom_minimum_size = Vector2(0, 32)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.stretch_mode = TextureRect.STRETCH_TILE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(Stone.ground_file(n)):
		t.texture = load(Stone.ground_file(n))
	t.modulate = Color(4, 4, 4)
	return t


func _refresh() -> void:
	for key in _motion_tiles:
		_motion_tiles[key].selected = Settings.motion == key
	for n in _ground_tiles:
		_ground_tiles[n].selected = Settings.ground == n
	for key in _window_tiles:
		_window_tiles[key].selected = Settings.window_mode == key
