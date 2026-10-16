extends "res://ui/overlays/overlay.gd"
## A question with two answers. Escape or a press outside means no.

signal confirmed


func setup(message: String, yes: String, no := "Cancel") -> void:
	var p := UI.slab(T.GOLD, 24)
	p.custom_minimum_size.x = 560
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := UI.vbox(T.L)
	col.add_child(UI.label(message, T.BODY, T.INK, true))
	var row := UI.hbox(T.S)
	var cancel := UI.button(no, "quiet")
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(close)
	var ok := UI.button(yes, "warning")
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.pressed.connect(func():
		confirmed.emit()
		close())
	row.add_child(cancel)
	row.add_child(ok)
	col.add_child(row)
	p.add_child(col)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(p)
	cancel.grab_focus.call_deferred()
	appear()
