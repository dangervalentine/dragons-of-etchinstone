extends "res://ui/overlays/overlay.gd"
## The in-game menu (Resume, Settings, How to Play, Glossary, Leave game), or just the settings
## when opened from the title screen. The settings are Motion and the Ground the board
## stands on.

const Settings = preload("res://ui/model/settings.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Stone = preload("res://ui/theme/stone.gd")

## The ground patterns, by number, as the menu names them.
const GROUND_NAMES := ["Lattice", "Ripples", "Columns", "Rain"]

signal intent(data: Dictionary)

var _motion_tiles := {}
var _ground_tiles := {}


func setup(in_game: bool) -> void:
	var p := UI.slab(T.GOLD, 24)
	p.custom_minimum_size.x = 720
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := UI.vbox(T.M)
	col.add_child(UI.label("MENU" if in_game else "SETTINGS", T.HEADING, T.GOLD))
	col.add_child(UI.label("Motion", ["body_bold", T.BODY[1]], T.INK))
	var row := UI.hbox(T.S)
	row.custom_minimum_size.y = T.TAP_MIN
	for entry in [["system", "Follow device", ""], ["reduced", "Reduced", "Fades only"], ["full", "Full", "All animation"]]:
		var tile: Button = ChoiceTile.make(entry[1], entry[2])
		tile.pressed.connect(_set_motion.bind(entry[0]))
		row.add_child(tile)
		_motion_tiles[entry[0]] = tile
	col.add_child(row)
	col.add_child(UI.label("Ground", ["body_bold", T.BODY[1]], T.INK))
	var grounds := UI.hbox(T.S)
	grounds.custom_minimum_size.y = T.TAP_MIN
	for n in range(1, Settings.GROUNDS + 1):
		var tile: Button = ChoiceTile.make(GROUND_NAMES[n - 1], "", "", T.GOLD, null, 56.0, _swatch(n))
		tile.tooltip_text = "Stand the board on the %s pattern" % GROUND_NAMES[n - 1].to_lower()
		tile.pressed.connect(_set_ground.bind(n))
		grounds.add_child(tile)
		_ground_tiles[n] = tile
	col.add_child(grounds)
	_refresh()
	var buttons := UI.hbox(T.S)
	if in_game:
		# The ways to read up on the rules, then the ways out.
		var learn_row := UI.hbox(T.S)
		var learn := UI.button("How to Play", "quiet", "book")
		learn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		learn.pressed.connect(func():
			close()
			intent.emit({"type": "rulebook"}))
		learn_row.add_child(learn)
		var help := UI.button("Glossary", "quiet", "help")
		help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		help.pressed.connect(func():
			close()
			intent.emit({"type": "glossary"}))
		learn_row.add_child(help)
		col.add_child(learn_row)
		var leave := UI.button("Leave game", "quiet", "close")
		leave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		leave.pressed.connect(func(): intent.emit({"type": "leave"}))
		buttons.add_child(leave)
	var resume := UI.button("Resume" if in_game else "Done", "primary")
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume.pressed.connect(close)
	buttons.add_child(resume)
	col.add_child(buttons)
	p.add_child(col)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(p)
	resume.grab_focus.call_deferred()
	appear()


func _set_motion(value: String) -> void:
	Settings.motion = value
	Settings.save_all()
	UI.reduced_motion = Settings.reduced_motion()
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
