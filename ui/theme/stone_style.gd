extends StyleBox
## A block of carved stone (specs/019 contracts/materials-and-ground.md, after feature
## 006): chamfered corners, a flat face, an etched rim with a faint light line inside
## its top edge, a dark bevel along its foot and a hard drop onto the table. A slab
## (panels, trays, dialogs) and a lintel (banners) are stone; a plinth (buttons, tabs)
## is the raised stone you press, or brass for the one primary action; a well (slots,
## chips) is cut in. Selected and target things take a brass rim, focus a jade one;
## nothing glows.

const T = preload("res://ui/theme/tokens.gd")

## "well", "plinth", "slab" or "lintel".
var kind := "well":
	set(v):
		kind = v
		emit_changed()
## Kept for the callers that still pass it; the depth of a cut no longer changes
## its look (specs/019: one stone, one bevel).
var depth := 0.5
## A rim that lights something up (the old glow), drawn as a selected rim in
## `glow_colour` at this strength; 0 for none.
var glow := 0.0:
	set(v):
		glow = v
		emit_changed()
var glow_colour := T.PARCHMENT:
	set(v):
		glow_colour = v
		emit_changed()
## A rim colour that means something (damage owed, a Region's tint); clear for the
## etched edge.
var edge := Color(T.SHADE, 0):
	set(v):
		edge = v
		emit_changed()
var edge_width := float(T.BORDER_EDGE)
## A face colour instead of the stone's (brass for the primary action); clear for stone.
var face := Color(T.SHADE, 0):
	set(v):
		face = v
		emit_changed()
## Selected, or the target slot: a brass rim (specs/019 contracts/brass-and-states.md).
var selected := false:
	set(v):
		selected = v
		emit_changed()
## Keyboard or controller focus: a jade rim.
var focus := false:
	set(v):
		focus = v
		emit_changed()
## Disabled: flat stone, a hairline rim, no bevel and no drop.
var disabled := false:
	set(v):
		disabled = v
		emit_changed()
## Only the rim, over another style's face: the focus ring.
var ring_only := false
## A plinth pressed in: the bevel collapses, the drop shrinks and the slab, with its
## words, sits PRESS_DROP lower (specs/019 "Pressed").
var pressed := false:
	set(v):
		pressed = v
		var shift := T.PRESS_DROP if v else 0
		content_margin_top = _margin + shift
		content_margin_bottom = maxf(0.0, _margin - shift)
		emit_changed()
var _margin := 0.0
## The corner cut: "sm" (chips, tabs, wells), "md" (buttons, panels) or "lg" (the
## tray, dialogs, banners); "" for the kind's own.
var size := "":
	set(v):
		size = v
		emit_changed()
## Round corners of this radius instead of the chamfer: paper and cards only (a card
## is cut paper, specs/019 FR-016). 0 keeps the chamfer.
var round_radius := 0.0:
	set(v):
		round_radius = v
		emit_changed()

## Whether a raised block casts its drop. A card that clips to its own bounds leaves
## it off, or the shadow shows only in the corners outside its rounding.
var casts_shadow := true:
	set(v):
		casts_shadow = v
		emit_changed()

## The points along each rounded corner.
const ARC := 8


func _init(p_kind := "well", p_depth := 0.5) -> void:
	kind = p_kind
	depth = p_depth
	var m: int = T.SPACE_3 if p_kind in ["slab", "lintel"] else T.SPACE_2
	_margin = m
	content_margin_left = m
	content_margin_right = m
	content_margin_top = m
	content_margin_bottom = m


func chamfer() -> float:
	match size:
		"sm":
			return T.CHAMFER_SM
		"md":
			return T.CHAMFER_MD
		"lg":
			return T.CHAMFER_LG
	match kind:
		"well":
			return T.CHAMFER_SM
		"lintel":
			return T.CHAMFER_LG
	return T.CHAMFER_MD


## The cut-cornered outline of `rect`, `inset` units in from its edge; with a
## `round_radius`, rounded instead, each corner an arc of ARC + 1 points from the
## top left round clockwise.
func outline(rect: Rect2, inset := 0.0) -> PackedVector2Array:
	var r := rect.grow(-inset)
	if round_radius > 0.0:
		var rr := minf(maxf(round_radius - inset, 0.0), minf(r.size.x, r.size.y) / 2.0)
		var out := PackedVector2Array()
		var centres := [r.position + Vector2(rr, rr), Vector2(r.end.x - rr, r.position.y + rr), r.end - Vector2(rr, rr),
			Vector2(r.position.x + rr, r.end.y - rr)]
		for c in 4:
			for i in ARC + 1:
				var a := PI + (c + float(i) / ARC) * PI / 2.0
				out.append(centres[c] + Vector2(cos(a), sin(a)) * rr)
		return out
	return _chamfered(r)


## The part of the outline of `rect` inside `inside`: a band or a tint laid on the
## stone that keeps its corners.
func part(rect: Rect2, inside: Rect2) -> PackedVector2Array:
	var box := PackedVector2Array([inside.position, Vector2(inside.end.x, inside.position.y), inside.end,
		Vector2(inside.position.x, inside.end.y)])
	var got := Geometry2D.intersect_polygons(outline(rect), box)
	return got[0] if not got.is_empty() else PackedVector2Array()


func _chamfered(r: Rect2) -> PackedVector2Array:
	var c := minf(chamfer(), minf(r.size.x, r.size.y) * 0.3)
	return PackedVector2Array([
		Vector2(r.position.x + c, r.position.y), Vector2(r.end.x - c, r.position.y),
		Vector2(r.end.x, r.position.y + c), Vector2(r.end.x, r.end.y - c),
		Vector2(r.end.x - c, r.end.y), Vector2(r.position.x + c, r.end.y),
		Vector2(r.position.x, r.end.y - c), Vector2(r.position.x, r.position.y + c),
	])


## The stone's own face colour.
func face_colour() -> Color:
	if face.a > 0.0 and not disabled:
		return face
	if disabled:
		return T.STONE
	match kind:
		"plinth":
			return T.STONE_RAISED
		"well":
			return T.WELL
	return T.STONE


## The rim's colour and width: focus, then selected (or lit), then a meaningful edge,
## then the etched edge (a hairline on wells and disabled things).
func rim() -> Array:
	if focus:
		return [T.JADE, float(T.BORDER_SELECT)]
	if selected:
		return [T.BRASS, float(T.BORDER_SELECT)]
	if glow > 0.0:
		return [Color(glow_colour, 0.6 + 0.4 * glow), float(T.BORDER_SELECT)]
	if edge.a > 0.0:
		return [edge, edge_width]
	if disabled or kind == "well":
		return [T.LINE, float(T.BORDER_ETCH)]
	if face.a > 0.0 and face.is_equal_approx(T.BRASS):
		return [T.BRASS_DEEP, float(T.BORDER_EDGE)]
	return [T.EDGE, float(T.BORDER_EDGE)]


func _draw(ci: RID, rect: Rect2) -> void:
	var rs := RenderingServer
	if ring_only:
		var ring: Array = rim()
		var loop := outline(rect, ring[1] / 2.0)
		loop.append(loop[0])
		rs.canvas_item_add_polyline(ci, loop, PackedColorArray([ring[0]]), ring[1], true)
		return
	var raised := kind != "well" and not disabled
	if pressed and raised:
		# Pressed in: the slab sits lower on the same footprint, its drop nearly gone.
		rect = Rect2(rect.position + Vector2(0, T.PRESS_DROP), rect.size - Vector2(0, T.PRESS_DROP))
	var pts := outline(rect)
	var brass := face.a > 0.0 and face.is_equal_approx(T.BRASS) and not disabled
	# The drop: a hard shadow straight down onto the table, shallower when pressed.
	if raised and casts_shadow:
		var d: float = (T.SHADOW_SLAB_PRESSED.drop if pressed else T.SHADOW_SLAB.drop)
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + Vector2(0, d))
		rs.canvas_item_add_polygon(ci, shadow, PackedColorArray([T.SHADOW_DROP]))
	rs.canvas_item_add_polygon(ci, pts, PackedColorArray([face_colour()]))
	var top_band := func(h: float) -> PackedVector2Array:
		return part(rect, Rect2(rect.position, Vector2(rect.size.x, h)))
	if kind == "well":
		# Cut in: the shadow falls inside, from the top edge down.
		var w: Dictionary = T.SHADOW_WELL
		_fill(ci, top_band.call(w.offset), Color(w.colour, w.colour.a * 0.8))
		_fill(ci, top_band.call(w.offset + w.blur * 0.5), Color(w.colour, w.colour.a * 0.3))
	elif pressed:
		var p: Dictionary = T.SHADOW_SLAB_PRESSED
		_fill(ci, top_band.call(p.inset), p.inset_colour)
	elif raised:
		# The bevel along the foot, and the faint light line inside the top edge.
		var s: Dictionary = T.SHADOW_BRASS if brass else T.SHADOW_SLAB
		_fill(ci, part(rect, Rect2(rect.position.x, rect.end.y - s.bevel, rect.size.x, s.bevel)), s.bevel_colour)
		var r: Array = rim()
		var inner := outline(rect, r[1] + s.etch / 2.0)
		# Along the top: the top edge and the cuts (or the arcs' upper halves) either side.
		var top := PackedVector2Array([inner[7], inner[0], inner[1], inner[2]])
		if round_radius > 0.0:
			top = inner.slice(ARC / 2, ARC + 1 + ARC / 2 + 1)
		rs.canvas_item_add_polyline(ci, top, PackedColorArray([s.etch_colour]), s.etch, true)
	# The rim: a flat line inside the outline.
	var rim_now: Array = rim()
	var line := outline(rect, rim_now[1] / 2.0)
	line.append(line[0])
	rs.canvas_item_add_polyline(ci, line, PackedColorArray([rim_now[0]]), rim_now[1], true)


func _fill(ci: RID, poly: PackedVector2Array, colour: Color) -> void:
	if poly.size() >= 3:
		RenderingServer.canvas_item_add_polygon(ci, poly, PackedColorArray([colour]))
