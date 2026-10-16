extends "res://ui/overlays/overlay.gd"
## A banner across the screen announcing a new Region or a stage of the Final Battle:
## a lintel of stone, edged in the stage's (muted) colour.

const StoneStyle = preload("res://ui/theme/stone_style.gd")

## sigil: an icon name, a texture, or "" for none.
func show_banner(eyebrow: String, title: String, sigil, colour: Color, duration: float) -> void:
	close_outside = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_dim(0.45)
	var band := PanelContainer.new()
	var lintel := StoneStyle.new("lintel", 0.4)
	lintel.edge = colour
	lintel.edge_width = 3.0
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		lintel.set_content_margin(side, 18)
	band.add_theme_stylebox_override("panel", lintel)
	band.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	band.anchor_right = 1.0
	band.offset_top = -100
	band.offset_bottom = 100
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UI.hbox(T.L)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if sigil is Texture2D:
		row.add_child(UI.texture_rect(sigil, 140, colour))
	elif sigil != "":
		row.add_child(UI.icon_rect(sigil, 140, colour))
	var col := UI.vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(UI.label(eyebrow.to_upper(), ["display", 30], T.INK_MUTED))
	col.add_child(UI.label(title.to_upper(), ["display_bold", 64], colour))
	row.add_child(col)
	band.add_child(row)
	add_child(band)
	var line_top := ColorRect.new()
	var line_bottom := ColorRect.new()
	for l in [line_top, line_bottom]:
		l.color = T.muted(colour)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		l.anchor_right = 1.0
		add_child(l)
	line_top.offset_top = -102
	line_top.offset_bottom = -99
	line_bottom.offset_top = 99
	line_bottom.offset_bottom = 102
	var tw := create_tween()
	if UI.reduced_motion:
		modulate.a = 0.0
		tw.tween_property(self, "modulate:a", 1.0, T.FAST)
	else:
		band.modulate.a = 0.0
		row.position.x = -60
		tw.tween_property(band, "modulate:a", 1.0, duration * 0.2)
		tw.parallel().tween_property(row, "position:x", 0.0, duration * 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(duration * 0.55)
	tw.tween_property(self, "modulate:a", 0.0, duration * 0.2)
	tw.tween_callback(close)
