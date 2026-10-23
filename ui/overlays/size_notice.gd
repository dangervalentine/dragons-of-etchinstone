extends PanelContainer
## Shown on the web when the browser does not suit the landscape layout: taller than
## it is wide, so the 16:9 play area is a thin strip between the letterbox, or too
## small to read. A browser cannot always be made to turn landscape, so the player
## is asked to. The game stays playable underneath.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal dismissed


func _init() -> void:
	add_theme_stylebox_override("panel", UI.stone_slab(Color(T.SHADE, 0), 16))
	var row := UI.hbox(T.SPACE_4)
	row.add_child(UI.icon_rect("regroup", 48, T.PARCHMENT))
	var touch := DisplayServer.is_touchscreen_available()
	var col := UI.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label("Turn your device sideways" if touch else "Widen the window", T.TITLE, T.PARCHMENT))
	var why := UI.label("Dragons of Etchinstone is laid out for a landscape screen.", T.BODY, T.PARCHMENT_MUTED, true)
	why.custom_minimum_size.x = 640
	col.add_child(why)
	row.add_child(col)
	var ok := UI.button("Dismiss", "normal")
	ok.custom_minimum_size = Vector2(200, 110)
	ok.pressed.connect(func(): dismissed.emit())
	row.add_child(ok)
	add_child(row)
