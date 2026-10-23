extends Control
## The back every card chosen to be Trashed turns to while the Soak is being
## chosen: the same for all of them, with no figures and no Ether, only the
## Trash mark and its name in the card's frame.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x < 8:
		return
	var radius := UI.card_radius(size.x)
	UI.draw_card_shadow(self, Rect2(Vector2.ZERO, size), radius)
	var frame := StyleBoxFlat.new()
	frame.bg_color = T.CARD_FRAME
	frame.set_corner_radius_all(radius)
	frame.anti_aliasing_size = 0.6
	draw_style_box(frame, Rect2(Vector2.ZERO, size))
	# A plain grey panel inside the frame, and a fine line inset from its edge.
	var b := maxf(4.0, size.x * 0.035)
	var panel := StyleBoxFlat.new()
	panel.bg_color = T.STONE
	panel.set_corner_radius_all(maxi(2, radius - int(b)))
	draw_style_box(panel, Rect2(Vector2.ZERO, size).grow(-b))
	var line := StyleBoxFlat.new()
	line.draw_center = false
	line.border_color = T.EDGE
	line.set_border_width_all(maxi(1, int(size.x * 0.008)))
	line.set_corner_radius_all(maxi(2, radius - int(b * 2.2)))
	draw_style_box(line, Rect2(Vector2.ZERO, size).grow(-b * 2.2))
	var icon := size.x * 0.34
	var at := Vector2((size.x - icon) / 2.0, size.y * 0.5 - icon * 0.75)
	draw_texture_rect(UI.icon("trash"), Rect2(at, Vector2(icon, icon)), false, T.PARCHMENT_MUTED)
	var font := UI.font(T.NUMERAL)
	var fs := int(clampf(size.x * 0.11, 14.0, 30.0))
	var text := "TRASHED"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2((size.x - w) / 2.0, at.y + icon + fs * 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, T.PARCHMENT_MUTED)
	UI.drew_text(self, "trashed", fs)
