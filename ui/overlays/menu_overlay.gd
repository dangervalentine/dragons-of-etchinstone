extends "res://ui/overlays/overlay.gd"
## The in-game menu (Resume, Settings, Glossary, Leave game), or just the settings
## when opened from the title screen.

const Settings = preload("res://ui/model/settings.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")

signal intent(data: Dictionary)

var _motion_tiles := {}


func setup(in_game: bool) -> void:
	var p := UI.panel(T.BG_SURFACE, T.LINE_SOFT, 2, T.RADIUS_M, 24)
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
	_refresh()
	var buttons := UI.hbox(T.S)
	if in_game:
		var leave := UI.button("Leave game", "quiet", "close")
		leave.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		leave.pressed.connect(func(): intent.emit({"type": "leave"}))
		buttons.add_child(leave)
		var help := UI.button("Glossary", "quiet", "help")
		help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		help.pressed.connect(func():
			close()
			intent.emit({"type": "glossary"}))
		buttons.add_child(help)
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


func _refresh() -> void:
	for key in _motion_tiles:
		_motion_tiles[key].selected = Settings.motion == key
