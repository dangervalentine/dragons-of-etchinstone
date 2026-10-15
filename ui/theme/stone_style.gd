extends StyleBox
## A place cut into the carved stone: chamfered corners, a stone floor and a bevel.
## A well, inset or rail token is cut in: shadow on the upper and left inner edges,
## light on the lower and right. A plinth, slab or lintel stands proud: the other
## way round, and a slab casts a shadow. A glowing rim marks the zone that waits on
## the player; it is drawn on the edge, and only a faint wash of it reaches inside,
## where the text is.

const T = preload("res://ui/theme/tokens.gd")
const Stone = preload("res://ui/theme/stone.gd")

## The most of the rim's colour that reaches the floor under the text.
const GLOW_MAX_UNDER_TEXT := 0.06
const RECESSED := ["well", "inset"]

## "well", "plinth", "slab", "inset" or "lintel".
var kind := "well":
	set(v):
		kind = v
		emit_changed()
## How deep the cut reads, 0 to 1: a darker floor and a stronger bevel.
var depth := 0.5:
	set(v):
		depth = v
		emit_changed()
## The rim light, 0 to 1.
var glow := 0.0:
	set(v):
		glow = v
		emit_changed()
var glow_colour := T.FOCUS:
	set(v):
		glow_colour = v
		emit_changed()
## An edge colour that means something (an Encounter's Ether, damage owed); clear for none.
var edge := Color(0, 0, 0, 0):
	set(v):
		edge = v
		emit_changed()
var edge_width := 2.0
## A face colour laid over the stone (a gold primary button); clear for bare stone.
var face := Color(0, 0, 0, 0):
	set(v):
		face = v
		emit_changed()
## Where in the grain this zone's floor starts, so neighbours do not repeat.
var fill_offset := Vector2.ZERO
## A plinth pressed in sits flush.
var pressed := false


func _init(p_kind := "well", p_depth := 0.5) -> void:
	kind = p_kind
	depth = p_depth
	var m: int = T.S if p_kind == "inset" else (T.M if p_kind == "slab" else 12)
	content_margin_left = m
	content_margin_right = m
	content_margin_top = m
	content_margin_bottom = m
	fill_offset = Vector2(randi() % 256, randi() % 256)


func chamfer() -> float:
	match kind:
		"inset":
			return T.CHAMFER_S
		"slab", "lintel":
			return T.CHAMFER_L
	return T.CHAMFER_M


## The cut-cornered outline of `rect`, `inset` units in from its edge.
func outline(rect: Rect2, inset := 0.0) -> PackedVector2Array:
	var r := rect.grow(-inset)
	var c := minf(chamfer(), minf(r.size.x, r.size.y) * 0.3)
	return PackedVector2Array([
		Vector2(r.position.x + c, r.position.y), Vector2(r.end.x - c, r.position.y),
		Vector2(r.end.x, r.position.y + c), Vector2(r.end.x, r.end.y - c),
		Vector2(r.end.x - c, r.end.y), Vector2(r.position.x + c, r.end.y),
		Vector2(r.position.x, r.end.y - c), Vector2(r.position.x, r.position.y + c),
	])


func _draw(ci: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	var recessed: bool = RECESSED.has(kind) or pressed
	var pts := outline(rect)
	if kind == "slab":
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + Vector2(0, 8))
		rs.canvas_item_add_polygon(ci, shadow, PackedColorArray([Color(0, 0, 0, 0.45)]))
	elif not recessed:
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + Vector2(0, 3))
		rs.canvas_item_add_polygon(ci, shadow, PackedColorArray([Color(0, 0, 0, 0.35)]))
	# The floor: the grain, darker the deeper the cut, lighter for a raised block.
	var tex: Texture2D = Stone.grain()
	var side := float(tex.get_width())
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append((p - rect.position + fill_offset) / side)
	var k: float = 1.0 - depth * 0.35 if recessed else 1.0 + 0.12 * (1.0 - depth)
	var tint := Color(k, k, k)
	rs.canvas_item_set_default_texture_repeat(ci, RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_ENABLED)
	rs.canvas_item_add_polygon(ci, pts, PackedColorArray([tint]), uvs, tex.get_rid())
	if face.a > 0.0:
		rs.canvas_item_add_polygon(ci, pts, PackedColorArray([face]))
	if glow > 0.0:
		rs.canvas_item_add_polygon(ci, pts, PackedColorArray([Color(glow_colour, glow * GLOW_MAX_UNDER_TEXT)]))
	# The bevel: two edges in light and two in shadow, a couple of units inside.
	var b := outline(rect, 1.5)
	var strength := 0.6 + depth * 0.8
	var lit := Color(T.BEVEL_LIGHT, T.BEVEL_LIGHT.a * strength)
	var dark := Color(T.BEVEL_SHADOW, T.BEVEL_SHADOW.a * strength)
	# Upper-left run: from the lower-left corner up and across to the upper right.
	var upper := PackedVector2Array([b[6], b[7], b[0], b[1], b[2]])
	var lower := PackedVector2Array([b[2], b[3], b[4], b[5], b[6]])
	var w := 2.0 + depth * 2.0
	rs.canvas_item_add_polyline(ci, upper, PackedColorArray([dark if recessed else lit]), w, true)
	rs.canvas_item_add_polyline(ci, lower, PackedColorArray([lit if recessed else dark]), w, true)
	var closed := pts.duplicate()
	closed.append(pts[0])
	if edge.a > 0.0:
		rs.canvas_item_add_polyline(ci, closed, PackedColorArray([edge]), edge_width, true)
	else:
		rs.canvas_item_add_polyline(ci, closed, PackedColorArray([Color(0, 0, 0, 0.55)]), 1.0, true)
	if glow > 0.0:
		rs.canvas_item_add_polyline(ci, closed, PackedColorArray([Color(glow_colour, 0.25 * glow)]), 8.0, true)
		rs.canvas_item_add_polyline(ci, closed, PackedColorArray([Color(glow_colour, 0.9 * glow)]), 2.5, true)
