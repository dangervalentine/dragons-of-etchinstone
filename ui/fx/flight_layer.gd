extends Control
## A layer above the play screen for things that only exist while something is
## happening: card backs travelling between piles, XP motes, floating numbers and
## the brief tint when damage lands. Everything here is temporary.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## An icon that travels from one global point to another and fades as it lands.
func ghost(icon: String, from: Vector2, to: Vector2, duration: float, colour: Color = T.PARCHMENT, side := 44.0, delay := 0.0) -> Tween:
	var g := UI.icon_rect(icon, side, colour)
	g.size = Vector2(side, side)
	g.position = from - global_position - g.size / 2.0
	g.modulate.a = 0.0
	add_child(g)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(g, "modulate:a", 1.0, duration * 0.15)
	if UI.reduced_motion:
		tw.tween_callback(func(): g.position = to - global_position - g.size / 2.0)
		tw.tween_interval(duration * 0.6)
	else:
		tw.tween_property(g, "position", to - global_position - g.size / 2.0, duration * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(g, "modulate:a", 0.0, duration * 0.15)
	tw.tween_callback(g.queue_free)
	return tw


## Words or a number that rise from a point and fade.
func float_text(text: String, at: Vector2, colour: Color, font_size := 40, duration := 0.8, icon := "") -> Tween:
	var row := UI.hbox(6)
	if icon != "":
		row.add_child(UI.icon_rect(icon, font_size * 0.9, colour))
	var l := UI.label(text, UI.restyle(T.NUMERAL, font_size), colour)
	l.add_theme_color_override("font_outline_color", T.GROUND)
	l.add_theme_constant_override("outline_size", 8)
	row.add_child(l)
	add_child(row)
	row.reset_size()
	row.position = at - global_position - row.size / 2.0
	row.pivot_offset = row.size / 2.0
	var tw := create_tween().set_parallel(true)
	if not UI.reduced_motion:
		row.scale = Vector2(0.6, 0.6)
		tw.tween_property(row, "scale", Vector2.ONE, duration * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(row, "position:y", row.position.y - 40, duration).set_ease(Tween.EASE_OUT)
	tw.tween_property(row, "modulate:a", 0.0, duration * 0.35).set_delay(duration * 0.65)
	tw.chain().tween_callback(row.queue_free)
	return tw


## A number that travels from one global point to another and is gone when it
## lands, where the thing it flew to shows it (a card's figure rising to its role
## slot). Nothing happens under reduced motion: the destination shows it at once.
func fly_text(text: String, from: Vector2, to: Vector2, colour: Color, font_size := 44, duration := T.MOVE) -> Tween:
	if UI.reduced_motion:
		return null
	var l := UI.label(text, UI.restyle(T.NUMERAL, font_size), colour)
	l.add_theme_color_override("font_outline_color", T.GROUND)
	l.add_theme_constant_override("outline_size", 8)
	add_child(l)
	l.reset_size()
	l.pivot_offset = l.size / 2.0
	l.position = from - global_position - l.size / 2.0
	l.scale = Vector2(1.25, 1.25)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position", to - global_position - l.size / 2.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(l.queue_free)
	return tw


## A brief tint over everything, such as red when damage lands.
func tint(colour: Color, duration: float) -> Tween:
	var r := ColorRect.new()
	r.color = colour
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, duration).from(1.0)
	tw.tween_callback(r.queue_free)
	return tw


func clear() -> void:
	for c in get_children():
		c.queue_free()
