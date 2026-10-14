extends PanelContainer
## Shown when the window does not suit the landscape layout: taller than it is
## wide, or too small to read. The game stays playable underneath.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")

signal dismissed


func _init() -> void:
	add_theme_stylebox_override("panel", UI.box(Color(T.BG_RAISED, 0.97), T.GOLD, 2, T.RADIUS_M, 16))
	var row := UI.hbox(T.M)
	row.add_child(UI.icon_rect("regroup", 48, T.GOLD))
	var touch := DisplayServer.is_touchscreen_available()
	var col := UI.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label("Turn your device sideways" if touch else "Widen the window", ["display_bold", 40], T.INK))
	var why := UI.label("Dragons of Etchinstone is laid out for a landscape screen.", ["body", 34], T.INK_MUTED, true)
	why.custom_minimum_size.x = 640
	col.add_child(why)
	row.add_child(col)
	var ok := UI.button("Dismiss", "normal")
	ok.custom_minimum_size = Vector2(200, 110)
	ok.pressed.connect(func(): dismissed.emit())
	row.add_child(ok)
	add_child(row)
