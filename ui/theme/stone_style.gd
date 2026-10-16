extends StyleBox
## A block of stone (feature 006, research R6): chamfered corners, a flat face, a
## bevel and a flat edge line. A well, plinth, slab or lintel stands proud of the
## ground and casts a hard shadow; an inset (a chip, the Boost switch) is cut in.
## The zone that waits on the player, or answers an event, changes its edge colour:
## a flat line, with nothing glowing and nothing reaching inside where the text is.

const T = preload("res://ui/theme/tokens.gd")
const Stone = preload("res://ui/theme/stone.gd")

## None of the edge colour reaches the face under the text (it did in revision 1).
const GLOW_MAX_UNDER_TEXT := 0.0
const RECESSED := ["inset"]

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
## How strongly the edge takes `glow_colour`, 0 to 1 (the waiting zone breathes
## between 0.85 and 1).
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
	# A raised block casts a hard shadow straight down onto the ground; no blur.
	if not recessed:
		var drop := Vector2(0, 8) if kind == "slab" else Vector2(0, 6)
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + drop)
		rs.canvas_item_add_polygon(ci, shadow, PackedColorArray([Color(0, 0, 0, 0.5)]))
	# The face: flat, so the boxes read as solid against the patterned ground. A
	# raised block is BG_RAISED, a cut-in chip BG_SURFACE; depth only darkens a cut.
	var floor_colour: Color = T.BG_SURFACE.darkened(depth * 0.25) if recessed else T.BG_RAISED
	rs.canvas_item_add_polygon(ci, pts, PackedColorArray([floor_colour]))
	if face.a > 0.0:
		rs.canvas_item_add_polygon(ci, pts, PackedColorArray([face]))
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
	# The edge: a flat line. A zone that waits on the player or answers an event
	# changes its edge colour (and widens it a little); nothing glows.
	var closed := pts.duplicate()
	closed.append(pts[0])
	# Edges are drawn muted (T.muted), so they sit with the ground.
	if glow > 0.0:
		rs.canvas_item_add_polyline(ci, closed, PackedColorArray([Color(T.muted(glow_colour), 0.6 + 0.4 * glow)]), 3.0, true)
	elif edge.a > 0.0:
		rs.canvas_item_add_polyline(ci, closed, PackedColorArray([T.muted(edge)]), edge_width, true)
	else:
		rs.canvas_item_add_polyline(ci, closed, PackedColorArray([Color(0, 0, 0, 0.6)]), 2.0, true)
