extends "res://ui/overlays/overlay.gd"
## A banner across the screen announcing a new Region, a stage of the Final Battle, a
## victory or a defeat (specs/019 contracts/components.md "Banner"): a stone lintel
## over the scrim, rimmed in the stage's own colour (a Region's tint, the lair's, or
## danger), its sigil in a ring of that colour, a muted kicker and the headline in
## capitals. It slides in, holds and slides out; in reduced motion it appears and
## clears in place.

const StoneStyle = preload("res://ui/theme/stone_style.gd")

## The sigil's side, and its ring round it.
const SIGIL := 120.0
const RING := 150.0
## How far the banner's contents slide in and out.
const SLIDE := 60.0


## sigil: an icon name, drawn in parchment; a texture (a dragon's painted head), drawn
## in its own colours; or "" for none. `colour` rims the banner and rings the sigil;
## `headline` colours the title: bright brass, or parchment for a defeat.
func show_banner(eyebrow: String, title: String, sigil, colour: Color, duration: float, headline: Color = T.BRASS_BRIGHT) -> void:
	close_outside = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var band := PanelContainer.new()
	var lintel := StoneStyle.new("lintel")
	lintel.edge = colour
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		lintel.set_content_margin(side, T.SPACE_5 / 2)
	band.add_theme_stylebox_override("panel", lintel)
	band.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	band.anchor_right = 1.0
	band.offset_top = -100
	band.offset_bottom = 100
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UI.hbox(T.SPACE_5)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if sigil is Texture2D or sigil != "":
		row.add_child(_medallion(sigil, colour))
	var col := UI.vbox(0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(UI.label(eyebrow, T.LABEL, T.PARCHMENT_MUTED))
	col.add_child(UI.label(title, T.BANNER, headline))
	row.add_child(col)
	band.add_child(row)
	add_child(band)
	var tw := create_tween()
	if UI.reduced_motion:
		tw.tween_interval(duration * 0.9)
		tw.tween_callback(close)
		return
	band.modulate.a = 0.0
	row.position.x = -SLIDE
	tw.tween_property(band, "modulate:a", 1.0, duration * 0.2)
	tw.parallel().tween_property(row, "position:x", 0.0, duration * 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(duration * 0.5)
	tw.tween_property(row, "position:x", SLIDE, duration * 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(band, "modulate:a", 0.0, duration * 0.2)
	tw.tween_callback(close)


## The sigil in a ring of the stage's colour.
func _medallion(sigil, colour: Color) -> Control:
	var ring := PanelContainer.new()
	ring.custom_minimum_size = Vector2(RING, RING)
	ring.add_theme_stylebox_override("panel", UI.box(T.WELL, colour, T.BORDER_SELECT, int(RING / 2.0), 0))
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art: Control = UI.texture_rect(sigil, SIGIL, Color.WHITE) if sigil is Texture2D else UI.icon_rect(sigil, SIGIL * 0.7, T.PARCHMENT)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.add_child(art)
	return ring
