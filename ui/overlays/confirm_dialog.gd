extends "res://ui/overlays/overlay.gd"
## A question with two answers. Escape or a press outside means no. With `opt_out`
## it also offers a "don't ask again" box, read from `opted_out` once it closes.

signal confirmed

var opted_out := false


func setup(message: String, yes: String, no := "Cancel", opt_out := "") -> void:
	var p := UI.slab(T.GOLD, 24)
	p.custom_minimum_size.x = 560
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := UI.vbox(T.L)
	col.add_child(UI.label(message, T.BODY, T.INK, true))
	if opt_out != "":
		var box := CheckBox.new()
		box.text = opt_out
		box.custom_minimum_size.y = 44
		box.set_meta("help_target", true)
		box.add_theme_font_size_override("font_size", T.LABEL[1])
		box.add_theme_color_override("font_color", T.INK_MUTED)
		box.toggled.connect(func(on):
			opted_out = on
			box.queue_redraw())
		# The box itself, drawn plainly enough to see on the slab: an outlined square,
		# filled gold with a tick once ticked. The theme's own box is only room for it.
		var blank := ImageTexture.create_from_image(Image.create(30, 26, false, Image.FORMAT_RGBA8))
		for icon in ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]:
			box.add_theme_icon_override(icon, blank)
		box.draw.connect(func():
			var r := Rect2(2, (box.size.y - 24) / 2.0, 24, 24)
			if box.button_pressed:
				box.draw_rect(r, T.GOLD)
				box.draw_polyline(PackedVector2Array([r.position + Vector2(5, 12), r.position + Vector2(10, 18), r.position + Vector2(19, 6)]), T.BG_BASE, 3.0, true)
			else:
				box.draw_rect(r, T.INK_MUTED, false, 2.0))
		col.add_child(box)
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
	cancel.grab_focus.call_deferred(true)
	appear()
