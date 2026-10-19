extends Control
## The framed, Ether-coloured face shared by Encounters and dragons: a title band
## over a patterned field, on a raised block of stone edged in the Ether colour. Subclasses fill the band and the field.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const FIELD_SHADER = preload("res://ui/fx/shaders/ether_field.gdshader")
const Creature = preload("res://ui/fx/creature.gd")
const Art = preload("res://ui/model/art.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

const BAND_H := 56
const EDGE := 3

var element = null
var sigil := ""
var art := ""

var band := HBoxContainer.new()
var body := VBoxContainer.new()
var _field := ColorRect.new()
var _sigil := TextureRect.new()
var _creature := Creature.new()
var _edge := Control.new()
## A raised block of stone, like the board's other zones, under the band and round
## the field.
var _stone := StoneStyle.new("well", 0.5)


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
	add_child(_creature)
	_creature.visible = false
	band.add_theme_constant_override("separation", T.S)
	band.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(band)
	body.add_theme_constant_override("separation", 6)
	add_child(body)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.draw.connect(_draw_edge)
	add_child(_edge)
	resized.connect(_fit)
	_stone.changed.connect(queue_redraw)


## The Ether colours the face; `art_name`, a creature from art/creatures/, stands in
## the field, showing `crop` of it, or else the faint `sigil_name` emblem does.
func set_look(ether, sigil_name: String, art_name := "", crop := Art.FULL) -> void:
	element = ether
	sigil = sigil_name
	art = art_name
	var tint: Color = T.ether(ether) if ether != null and ether != "" else T.LINE_SOFT.lightened(0.2)
	_field.material.set_shader_parameter("tint", tint)
	_field.material.set_shader_parameter("ether", T.ETHER_ID.get(ether, -1) if ether != null else -1)
	_field.material.set_shader_parameter("motion", 0.0 if UI.reduced_motion else 1.0)
	_creature.visible = art_name != ""
	_sigil.visible = art_name == ""
	if art_name != "":
		if _creature.art_name != art_name:
			_creature.setup(art_name, Color(tint.lightened(0.45), 0.55), ether if ether != null else "")
		_creature.crop = crop
	else:
		_sigil.texture = UI.icon(sigil_name) if sigil_name != "" else null
		_sigil.modulate = Color(1, 1, 1, 0.13)
	_fit()
	queue_redraw()
	_edge.queue_redraw()


## Keep the creature still (or let it move again), whatever the motion setting.
func set_held(on: bool) -> void:
	_creature.held = on


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
	if art != "":
		# The creature stands in the lower right, clear of the figures along the top.
		# Keep below the row of figures at the top of the field.
		var a := minf(field.size.x * 0.62, field.size.y - 92.0)
		_creature.size = Vector2(a, a)
		_creature.position = Vector2(field.end.x - a - 6, field.end.y - a - 4)
	else:
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
	draw_style_box(_stone, Rect2(Vector2.ZERO, size))


## The Ether edge along the cut outline, over the field's corners.
func _draw_edge() -> void:
	var pts := _stone.outline(Rect2(Vector2.ZERO, size), EDGE / 2.0)
	pts.append(pts[0])
	var colour: Color = T.muted(T.ether(element)) if element != null and element != "" else T.LINE_SOFT
	_edge.draw_polyline(pts, colour, EDGE, true)
