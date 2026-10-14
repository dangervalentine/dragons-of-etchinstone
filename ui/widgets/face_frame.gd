extends Control
## The framed, Ether-coloured face shared by Encounters and dragons: a dark title
## band over a patterned field, edged in the Ether colour. Subclasses fill the band
## and the field.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const FIELD_SHADER = preload("res://ui/fx/shaders/ether_field.gdshader")

const BAND_H := 56
const EDGE := 3

var element = null
var sigil := ""

var band := HBoxContainer.new()
var body := VBoxContainer.new()
var _field := ColorRect.new()
var _sigil := TextureRect.new()
var _edge := Control.new()


func _init() -> void:
	_field.material = ShaderMaterial.new()
	_field.material.shader = FIELD_SHADER
	_field.material.set_shader_parameter("centre", Vector2(0.72, 0.55))
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_field)
	_sigil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sigil.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sigil.modulate = Color(1, 1, 1, 0.13)
	_sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sigil)
	band.add_theme_constant_override("separation", T.S)
	band.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(band)
	body.add_theme_constant_override("separation", 6)
	add_child(body)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.draw.connect(func(): _edge.draw_style_box(_frame(false), Rect2(Vector2.ZERO, size)))
	add_child(_edge)
	resized.connect(_fit)


func set_look(ether, sigil_name: String) -> void:
	element = ether
	sigil = sigil_name
	_field.material.set_shader_parameter("tint", T.ether(ether) if ether != null and ether != "" else T.LINE_SOFT.lightened(0.2))
	_sigil.texture = UI.icon(sigil_name) if sigil_name != "" else null
	queue_redraw()
	_edge.queue_redraw()


func clear() -> void:
	for box in [band, body]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()


## Global point that effects aim at.
func centre() -> Vector2:
	return global_position + size / 2.0


func _fit() -> void:
	var field := Rect2(EDGE, BAND_H, size.x - 2 * EDGE, size.y - BAND_H - EDGE)
	_field.position = field.position
	_field.size = field.size
	_field.material.set_shader_parameter("size", field.size)
	var s := minf(field.size.x * 0.7, field.size.y * 0.95)
	_sigil.size = Vector2(s, s)
	_sigil.position = Vector2(field.end.x - s * 0.82, field.get_center().y - s / 2.0)
	band.position = Vector2(T.M, 0)
	band.size = Vector2(size.x - 2 * T.M, BAND_H)
	body.position = Vector2(T.M - 4, BAND_H + T.S)
	body.size = Vector2(size.x - 2 * (T.M - 4), size.y - BAND_H - T.S - T.S - EDGE)
	_edge.size = size
	_edge.queue_redraw()


func _draw() -> void:
	draw_style_box(_frame(true), Rect2(Vector2.ZERO, size))


func _frame(filled: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = T.BG_BAND
	s.draw_center = filled
	s.border_color = T.ether(element) if element != null and element != "" else T.LINE_SOFT
	s.set_border_width_all(EDGE)
	s.set_corner_radius_all(T.RADIUS_CARD)
	s.anti_aliasing_size = 0.6
	if filled:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 8
		s.shadow_offset = Vector2(0, 3)
	return s
