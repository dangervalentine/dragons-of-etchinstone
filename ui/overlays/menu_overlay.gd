extends "res://ui/overlays/overlay.gd"
## The menu, opened only from the menu button in the title bar: the settings (Motion
## and, on a desktop, the Window), each a row with
## its name beside its choices so the whole card fits on the shortest screen, then
## How to Play, the Glossary and Clear records, then the History, the Leaderboard
## and, in a game, Abandon run. The X closes it.

const Settings = preload("res://ui/model/settings.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const WindowSizer = preload("res://ui/model/window_sizer.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")

## The widest the card grows, and the width of the column naming each setting.
const WIDTH_MAX := 1040.0
const NAME_W := 150.0
## Taps on the title this close together count toward the triple tap that, in
## development, unlocks every dragon.
const TAP_GAP_MS := 500

signal intent(data: Dictionary)

var _motion_tiles := {}
var _window_tiles := {}
## The card, to check that it fits.
var panel: Control
var _title: Label
var _taps := 0
var _last_tap_ms := 0


## `area` is the room the card has; it is never wider. `window_row` shows the
## Window setting, which only a desktop with a real window has.
func setup(in_game: bool, area := Rect2(16, 16, 1248, 688), window_row := WindowSizer.applies()) -> void:
	var p := UI.slab(Color(T.SHADE, 0), 24)
	panel = p
	p.custom_minimum_size.x = minf(WIDTH_MAX, area.size.x)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := UI.vbox(T.SPACE_4)
	var top := UI.hbox(T.SPACE_2)
	var title := UI.label("Settings", T.TITLE, T.PARCHMENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	title.gui_input.connect(_on_title_input)
	_title = title
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
	var pages := UI.hbox(T.SPACE_2)
	var games := UI.hbox(T.SPACE_2)
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
			leave.add_theme_color_override(c, T.DANGER)
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
	var row := UI.hbox(T.SPACE_4)
	var label := UI.label(name, UI.restyle(T.BODY_STRONG, T.BODY.size), T.PARCHMENT)
	label.custom_minimum_size.x = NAME_W
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var choices := UI.hbox(T.SPACE_2)
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


func _refresh() -> void:
	for key in _motion_tiles:
		_motion_tiles[key].selected = Settings.motion == key
	for key in _window_tiles:
		_window_tiles[key].selected = Settings.window_mode == key


## For development: three quick taps on the title unlock every dragon.
func _on_title_input(event: InputEvent) -> void:
	# A touch arrives as the mouse press it is emulated as; counting both would
	# count it twice.
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var now := Time.get_ticks_msec()
	_taps = _taps + 1 if now - _last_tap_ms <= TAP_GAP_MS else 1
	_last_tap_ms = now
	if _taps < 3:
		return
	_taps = 0
	Settings.unlock_all()
	intent.emit({"type": "dragons_unlocked"})
	_title.text = "All Dragons Unlocked"
	if is_inside_tree():
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(_title):
				_title.text = "Settings")
