extends "res://ui/overlays/overlay.gd"
## The menu, opened only from the menu button in the title bar: the settings (Motion,
## on a desktop the Window, and the Rules: Classic or House rules, for new games), two
## to a row, each its name beside one button that steps to the next choice, so the
## card has room to breathe on the shortest screen; then How to Play, the Glossary and Clear records, then the History,
## the Leaderboard and, in a game, Abandon run. The X closes it.

const Settings = preload("res://ui/model/settings.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const WindowSizer = preload("res://ui/model/window_sizer.gd")
const HistoryStore = preload("res://ui/model/history_store.gd")

## The widest the card grows, and the width of the column naming each setting.
const WIDTH_MAX := 1040.0
const NAME_W := 110.0
## Each setting's choices in the order its button steps through them, with the line
## under each saying what it means.
const MOTION_CHOICES := {"system": ["Follow device", "Device setting"], "reduced": ["Reduced", "Fades only"], "full": ["Full", "All animation"]}
const WINDOW_CHOICES := {"windowed": ["Windowed", "Resizable · F11"], "fullscreen": ["Full screen", "F11"]}
## The editions (editions.gd), keyed by Settings.house_rules.
const RULES_CHOICES := {false: ["Classic", "The rulebook as printed"], true: ["House rules", "Adds Persistent XP"]}
## The marks on a setting's button, one per choice, the current one lit.
const PIP := 14.0
## Taps on the title this close together count toward the triple tap that, in
## development, unlocks every dragon.
const TAP_GAP_MS := 500

signal intent(data: Dictionary)

## The buttons that step through Motion and, on a desktop, the Window.
var motion_button: Button
var window_button: Button
## The button that steps between Classic and House rules.
var rules_button: Button
## The card, to check that it fits.
var panel: Control
var _title: Label
var _taps := 0
var _last_tap_ms := 0


## `area` is the room the card has; it is never wider. `window_row` shows the
## Window setting, which only a desktop with a real window has.
func setup(in_game: bool, area := Rect2(16, 16, 1248, 688), window_row := WindowSizer.applies()) -> void:
	var p := UI.slab(Color(T.SHADE, 0), T.SPACE_5)
	panel = p
	p.custom_minimum_size.x = minf(WIDTH_MAX, area.size.x)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := UI.vbox(T.SPACE_4)
	var top := UI.hbox(T.SPACE_3)
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
	# Two to a row, in columns of equal width.
	var settings := GridContainer.new()
	settings.columns = 2
	settings.add_theme_constant_override("h_separation", T.SPACE_5)
	settings.add_theme_constant_override("v_separation", T.SPACE_4)
	motion_button = _cycle_button(MOTION_CHOICES.size())
	motion_button.pressed.connect(_next_motion)
	settings.add_child(_setting("Motion", motion_button))
	if window_row:
		window_button = _cycle_button(WINDOW_CHOICES.size())
		window_button.pressed.connect(_next_window)
		settings.add_child(_setting("Window", window_button))
	rules_button = _cycle_button(RULES_CHOICES.size())
	rules_button.pressed.connect(_next_rules)
	settings.add_child(_setting("Rules", rules_button))
	col.add_child(settings)
	_refresh()
	# The ways to read up on the rules and clearing the games played, then reading
	# back over them and, in a game, the way out at the bottom right.
	var pages := UI.hbox(T.SPACE_3)
	var games := UI.hbox(T.SPACE_3)
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


## A setting's name, then the button that steps through its choices.
func _setting(name: String, button: Button) -> Control:
	var row := UI.hbox(T.SPACE_3)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := UI.label(name, UI.restyle(T.BODY_STRONG, T.BODY.size), T.PARCHMENT)
	label.custom_minimum_size.x = NAME_W
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	row.add_child(button)
	return row


## A plinth showing the current choice, its line, and a mark per choice; pressing it
## goes to the next. Never rimmed in brass: it is one control, not a choice among
## several (specs/019 contracts/brass-and-states.md).
func _cycle_button(count: int) -> Button:
	var b: Button = ChoiceTile.make(" ", " ")
	b.custom_minimum_size.y = T.TAP_MIN
	b.tooltip_text = "Press for the next choice"
	var pips := UI.hbox(T.SPACE_2)
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in count:
		# A diamond, drawn: a container would undo a rotated square.
		var pip := Control.new()
		pip.custom_minimum_size = Vector2(PIP, PIP)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.set_meta("lit", false)
		pip.draw.connect(func():
			var h := PIP / 2.0
			pip.draw_colored_polygon(PackedVector2Array([Vector2(h, 0), Vector2(PIP, h), Vector2(h, PIP), Vector2(0, h)]),
					T.PARCHMENT if pip.get_meta("lit") else T.EDGE))
		pips.add_child(pip)
	UI.ignore_mouse(pips)
	b._row.add_child(pips)
	b.set_meta("pips", pips)
	return b


## Shows `choice` (a [name, line] pair), the `index`th of its setting's choices.
func _show(b: Button, choice: Array, index: int) -> void:
	b._title.text = choice[0]
	b._title.add_theme_color_override("font_color", T.PARCHMENT)
	b._desc.text = choice[1]
	var pips: Control = b.get_meta("pips")
	for i in pips.get_child_count():
		pips.get_child(i).set_meta("lit", i == index)
		pips.get_child(i).queue_redraw()


func _next_motion() -> void:
	var keys := MOTION_CHOICES.keys()
	Settings.motion = keys[(keys.find(Settings.motion) + 1) % keys.size()]
	Settings.save_all()
	UI.reduced_motion = Settings.reduced_motion()
	_refresh()


## Classic or House rules, for the games started from now on; a game in progress
## keeps the rules it began with.
func _next_rules() -> void:
	Settings.house_rules = not Settings.house_rules
	Settings.save_all()
	_refresh()


func _next_window() -> void:
	WindowSizer.toggle()
	_refresh()


func _refresh() -> void:
	var keys := MOTION_CHOICES.keys()
	_show(motion_button, MOTION_CHOICES[Settings.motion], keys.find(Settings.motion))
	_show(rules_button, RULES_CHOICES[Settings.house_rules], int(Settings.house_rules))
	if window_button != null:
		keys = WINDOW_CHOICES.keys()
		_show(window_button, WINDOW_CHOICES[Settings.window_mode], keys.find(Settings.window_mode))


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
