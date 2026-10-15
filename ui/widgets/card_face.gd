extends Control
## Draws the face of a Mage Card at any size, in the style of the printed card: a
## near-black frame; the Level crown, Ether pip and name across the top; the bronze
## Key Card strip under it, torn where it meets the field; then the living Ether
## field, with the stat column hanging off a sword down its left edge: Initiative
## pennant, basic and enhanced action plates, Boost, and the Armor shield. Only the
## current Level is drawn.
##
## A focus (the parts of the card the current step uses) lifts those parts with a
## rim and quietens the rest; every figure stays readable either way.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Settings = preload("res://ui/model/settings.gd")
const FIELD_SHADER = preload("res://ui/fx/shaders/ether_card.gdshader")

## How far a quietened plate's fill moves toward the band colour; tests/test_card_contrast.gd checks it.
const QUIET := 0.75
const STEEL := Color("8f8aa0")

var model := {}
## Greyed out, for a card that cannot be chosen.
var dimmed := false: set = set_dimmed
## Figures to ring, such as those an Upgrade or Downgrade would change.
var changed: Array = []
var glow: Color = T.GOLD
## Whether the Ether field moves. Off under reduced motion whatever this says.
var motion := true: set = set_motion

var _field := ColorRect.new()
var _ink := Control.new()
## The focus being drawn, and the one it is fading from: {regions, mark, damage_element}.
var _focus := {}
var _focus_from := {}
var _focus_t := 1.0
var _focus_tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.material = ShaderMaterial.new()
	_field.material.shader = FIELD_SHADER
	add_child(_field)
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.draw.connect(_draw_ink)
	add_child(_ink)
	resized.connect(_layout)


func set_model(m: Dictionary, ring: Array = [], ring_colour: Color = T.GOLD) -> void:
	model = m
	changed = ring
	glow = ring_colour
	set_motion(motion)
	_layout()


func set_dimmed(value: bool) -> void:
	dimmed = value
	_field.material.set_shader_parameter("dim", 0.85 if dimmed else 0.0)
	_apply_focus_to_field()
	_ink.queue_redraw()


func set_motion(value: bool) -> void:
	motion = value
	_field.material.set_shader_parameter("motion", 1.0 if motion and not Settings.reduced_motion() else 0.0)


## Which parts of the card matter in this step: {"regions": [...], "mark": ""}.
## An empty focus draws the card normally. A change fades over a moment.
func set_focus(f: Dictionary) -> void:
	var next := {"regions": f.get("regions", []), "mark": f.get("mark", ""),
		"damage_element": f.get("damage_element", "")}
	if next == _focus:
		return
	_focus_from = _focus
	_focus = next
	if _focus_tween != null:
		_focus_tween.kill()
	if not is_inside_tree() or Settings.reduced_motion() or _focus_from.is_empty():
		_set_focus_t(1.0)
		return
	_focus_t = 0.0
	_focus_tween = create_tween()
	_focus_tween.tween_method(_set_focus_t, 0.0, 1.0, T.FAST)


func _set_focus_t(v: float) -> void:
	_focus_t = v
	_apply_focus_to_field()
	_ink.queue_redraw()


## How strongly a region is lifted (0 to 1), through any fade in progress.
func _lift(key: String) -> float:
	if dimmed:
		return 0.0
	return lerpf(_has(_focus_from, key), _has(_focus, key), _focus_t)


## How strongly a region is quietened (0 to 1).
func _hush(key: String) -> float:
	if dimmed:
		return 0.0
	return lerpf(_lacks(_focus_from, key), _lacks(_focus, key), _focus_t)


static func _has(f: Dictionary, key: String) -> float:
	return 1.0 if f.get("regions", []).has(key) else 0.0


static func _lacks(f: Dictionary, key: String) -> float:
	var r: Array = f.get("regions", [])
	return 1.0 if not r.is_empty() and not r.has(key) else 0.0


func _apply_focus_to_field() -> void:
	_field.material.set_shader_parameter("focus_dim", _hush("ether"))
	_field.material.set_shader_parameter("glow", _lift("ether"))


# ---------------------------------------------------------------- geometry

## Where everything sits on a card of this size. Pure geometry: no drawing state.
func _geo() -> Dictionary:
	var w := size.x
	var h := size.y
	var b := maxf(2.0, roundf(w * 0.016))
	var pad := roundf(w * 0.045)
	var band := roundf(h * 0.155)
	var strip := roundf(h * 0.09)
	var field := Rect2(b, band + strip, w - 2 * b, h - band - strip - b)
	var gap := maxf(2.0, roundf(field.size.y * 0.014))
	var row := floorf((field.size.y - pad - 3 * gap) / 5.3)
	var plate_w := roundf(w * 0.44)
	var x := pad
	var y := field.position.y + pad * 0.5
	var g := {"b": b, "pad": pad, "band": band, "strip": strip, "field": field, "gap": gap, "row": row}
	g.initiative = Rect2(x, y, row, row)
	y += row + gap
	g.basic = Rect2(x, y, plate_w, row)
	y += row
	g.arrow = Rect2(x, y, plate_w, row * 0.3)
	y += row * 0.3
	g.enhanced = Rect2(x, y, plate_w + roundf(row * 0.45), row)
	y += row + gap
	g.boost = Rect2(x, y, roundf(plate_w * 0.72), row)
	y += row + gap
	g.armor = Rect2(x, y, roundf(row * 1.75), row)
	var crown := roundf(band * 0.8)
	g.level = Rect2(pad, (band - crown) / 2.0, crown, crown)
	var name_x: float = g.level.end.x + pad * 0.5
	g.name = Rect2(name_x, 2, w - name_x - pad * 0.6, band - 4)
	g.key = Rect2(b, band, roundf(w * 0.5), strip)
	g.cost = Rect2(roundf(w * 0.62), band, w - roundf(w * 0.62) - b, strip)
	g.ether = field
	return g


## The rectangle of one part of the card: level, name, key, cost, initiative,
## basic, enhanced, boost, armor or ether.
func region_rect(key: String) -> Rect2:
	return _geo()[key]


## The size of the main stat numerals on this card.
func numeral_size() -> float:
	return minf(_geo().row * 0.88, T.NUMERAL[1] * 1.15)


func _layout() -> void:
	_ink.position = Vector2.ZERO
	_ink.size = size
	var f: Rect2 = _geo().field
	_field.position = f.position
	_field.size = f.size
	var m := _field.material
	if not model.is_empty():
		var e = model.element
		m.set_shader_parameter("ether", T.ETHER_ID.get(e, 1))
		m.set_shader_parameter("tint", T.ether_shade(e, "base"))
		m.set_shader_parameter("deep", T.ether_shade(e, "deep"))
		m.set_shader_parameter("lit", T.ether_shade(e, "lit"))
		m.set_shader_parameter("phase", float(absi(hash(model.get("id", ""))) % 97) / 9.7)
	m.set_shader_parameter("size", f.size)
	_apply_focus_to_field()
	queue_redraw()
	_ink.queue_redraw()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var s := _frame_box(true)
	draw_style_box(s, Rect2(Vector2.ZERO, size))


func _frame_box(filled: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = T.CARD_FRAME
	s.draw_center = filled
	s.border_color = T.CARD_FRAME
	s.set_border_width_all(int(_geo().b) + 1)
	s.set_corner_radius_all(int(size.x * 0.075))
	s.anti_aliasing_size = 0.6
	if filled:
		s.shadow_color = Color(0, 0, 0, 0.5)
		s.shadow_size = maxi(4, int(size.x * 0.04))
		s.shadow_offset = Vector2(0, maxf(2.0, size.x * 0.018))
	return s


func _draw_ink() -> void:
	if model.is_empty() or size.x < 8:
		return
	var g := _geo()
	var lv: Dictionary = model.stats
	var e = model.element
	var num := numeral_size()

	_draw_strip(g, lv)
	_draw_tears(g)
	_draw_sigil(g, e)
	_draw_sword(g)

	# Initiative, on its pennant.
	var r: Rect2 = g.initiative
	_ring("initiative", r)
	var ink := _ink_for("initiative", T.INK)
	_raised(_pennant(r), _fill_for("initiative", T.BG_BAND), "initiative")
	_number(Rect2(r.position.x, r.position.y - r.size.y * 0.07, r.size.x, r.size.y), str(lv.initiative), num * 0.8, ink)

	# The basic action, the arrow down to the enhanced action, and the enhanced action.
	r = g.basic
	_ring("basic", r)
	_raised(_octagon(r), _fill_for("basic", T.BG_BAND), "basic")
	_action(r, lv.basic, _ink_for("basic", T.INK), "", num)
	var a: Rect2 = g.arrow
	var ax: float = a.position.x + a.size.x * 0.32
	var ah: float = a.size.y * 0.9
	_ink.draw_colored_polygon(PackedVector2Array([Vector2(ax - ah, a.position.y + a.size.y * 0.05),
		Vector2(ax + ah, a.position.y + a.size.y * 0.05), Vector2(ax, a.position.y + a.size.y * 0.05 + ah)]),
		Color(T.INK_MUTED, 0.9))
	r = g.enhanced
	var enh = lv.enhanced.element
	_ring("enhanced", r)
	var enh_fill := T.ether_shade(enh, "plate")
	var enh_ink := T.ether_shade(enh, "plate_ink")
	if dimmed:
		enh_fill = T.INK_MUTED.darkened(0.55)
		enh_ink = T.INK_MUTED
	_raised(_octagon(r), _fill_for("enhanced", enh_fill), "enhanced")
	_action(r, lv.enhanced, _ink_for("enhanced", enh_ink), enh, num)
	_pip(enh, Vector2(r.end.x - r.size.y * 0.12, r.position.y + r.size.y * 0.1), r.size.y * 0.42)

	# Boost.
	r = g.boost
	_ring("boost", r)
	_raised(_octagon(r, 0.12), _fill_for("boost", T.BG_BAND), "boost")
	_number(r, "+%d" % lv.boost, num, _ink_for("boost", T.INK))

	# Armor, on its shield: filled with the Armor's Ether when it has one.
	r = g.armor
	var armored: bool = lv.armor.element != null
	var shield := Rect2(r.position, Vector2(r.size.y, r.size.y))
	_ring("armor", Rect2(r.position, Vector2(r.size.y * (1.7 if armored else 1.0), r.size.y)))
	var shield_fill := T.ether_shade(lv.armor.element, "plate") if armored and not dimmed else T.BG_BAND
	_raised(_shield(shield), _fill_for("armor", shield_fill), "armor")
	_number(Rect2(shield.position.x, shield.position.y - shield.size.y * 0.06, shield.size.x, shield.size.y),
		str(lv.armor.value), num * 0.8, _ink_for("armor", UI.best_ink(shield_fill) if armored and not dimmed else T.INK))
	if armored:
		_pip(lv.armor.element, Vector2(shield.end.x + shield.size.y * 0.32, shield.get_center().y), shield.size.y * 0.5)
	if _focus.get("mark", "") == "soaks_more" and not dimmed:
		_chip("×2", Vector2(r.position.x + r.size.y * (1.7 if armored else 1.05) + 3, shield.get_center().y),
			shield.size.y * 0.62, T.ether_shade(_focus.get("damage_element", ""), "lit"), _focus_t)

	_draw_top_band(g, e)
	# The frame again, over the field's square corners, and its faint Ether rim.
	_ink.draw_style_box(_frame_box(false), Rect2(Vector2.ZERO, size))
	var rim := StyleBoxFlat.new()
	rim.draw_center = false
	rim.border_color = Color(T.ether_shade(e, "lit") if not dimmed else T.LINE_SOFT, 0.3)
	rim.set_border_width_all(1)
	rim.set_corner_radius_all(int(size.x * 0.075) - int(g.b))
	_ink.draw_style_box(rim, Rect2(Vector2.ZERO, size).grow(-g.b))
	if model.get("downgraded", false):
		_crack()


## The Level crown, the Ether pip and the name, on the black top band.
func _draw_top_band(g: Dictionary, e) -> void:
	var band: float = g.band
	_ink.draw_line(Vector2(g.b + 2, 1.5), Vector2(size.x - g.b - 2, 1.5), Color(1, 1, 1, 0.08), 1.0)
	var c: Rect2 = g.level
	_ring("level", c)
	_glow_rim(_rect_pts(c.grow(1), c.size.y * 0.2), _lift("level"))
	_icon("crown", c, _ink_for("level", T.INK) if not dimmed else T.INK_MUTED)
	_number(Rect2(c.position + Vector2(0, c.size.y * 0.12), c.size), str(model.level), c.size.y * 0.56, T.BG_BASE)
	if model.get("downgraded", false):
		var a: float = c.size.y * 0.5
		_icon("down_arrow", Rect2(c.end - Vector2(a * 0.8, a * 0.8), Vector2(a, a)), T.BAD)
	var n: Rect2 = g.name
	var pip: float = band * 0.36
	var pip_c := Vector2(n.position.x + pip * 0.5, band / 2.0)
	var lift := _lift("ether")
	if lift > 0.0:
		_ink.draw_circle(pip_c, pip * 0.9, Color(T.FOCUS, 0.3 * lift))
	_icon(e, Rect2(pip_c - Vector2(pip, pip) / 2.0, Vector2(pip, pip)), T.ether_shade(e, "lit") if not dimmed else T.INK_MUTED)
	var text_x: float = n.position.x + pip + g.pad * 0.3
	_name(Rect2(text_x, n.position.y, n.end.x - text_x, n.size.y), model.name.to_upper(),
		_ink_for("name", T.INK) if not dimmed else T.INK_MUTED)


## The bronze Key Card strip: the Encounter this card asks for, its Hardship, and
## the Upgrade cost.
func _draw_strip(g: Dictionary, lv: Dictionary) -> void:
	var band: float = g.band
	var strip: float = g.strip
	var b: float = g.b
	var w := size.x
	var tab := strip * 0.45
	var pts := PackedVector2Array([Vector2(b + tab, band), Vector2(w - b, band), Vector2(w - b, band + strip),
		Vector2(b + tab, band + strip), Vector2(b, band + strip / 2.0)])
	var bronze := T.BRONZE if not dimmed else T.BG_RAISED
	_ink.draw_colored_polygon(pts, bronze)
	_ink.draw_line(Vector2(b + tab, band + 1), Vector2(w - b, band + 1), Color(T.BRONZE_LIGHT, 0.45), 1.0)
	_ink.draw_line(Vector2(b + tab, band + strip - 1), Vector2(w - b, band + strip - 1), Color(T.BRONZE_DARK, 0.9), 1.5)

	var si := roundf(strip * 0.72)
	var key: Dictionary = lv.encounter
	var kr: Rect2 = g.key
	if changed.has("encounter") or changed.has("hardship"):
		_ring("encounter" if changed.has("encounter") else "hardship", kr.grow(-2))
	_glow_rim(_rect_pts(kr.grow(-1), strip * 0.3), _lift("key"))
	var ink := _ink_for("key", T.INK) if not dimmed else T.INK_MUTED
	var x: float = b + tab + g.pad * 0.2
	_icon(key.type, Rect2(x, band + (strip - si) / 2.0, si, si), ink)
	x += si + 2
	x += _text(Vector2(x, band), strip, str(key.index), strip * 0.8, ink) + g.pad * 0.5
	if lv.hardship != null:
		_icon(lv.hardship, Rect2(x, band + (strip - si) / 2.0, si, si), _ink_for("key", T.BAD) if not dimmed else T.INK_MUTED)

	# The Upgrade cost, its colour saying whether it can be paid now.
	var mark: String = _focus.get("mark", "")
	var cost: String = str(lv.upgrade_cost) if lv.upgrade_cost != null else "max"
	var colour := T.GOLD
	match mark:
		"unaffordable":
			colour = T.BAD
		"max_level":
			cost = "MAX"
			colour = T.INK_MUTED
	if dimmed:
		colour = T.INK_MUTED
	colour = colour.lerp(T.INK_MUTED, _hush("cost"))
	var cr: Rect2 = g.cost
	var font := UI.font("display_bold")
	var cost_w := font.get_string_size(cost, HORIZONTAL_ALIGNMENT_LEFT, -1, int(strip * 0.8)).x
	var cx: float = cr.end.x - g.pad * 0.4 - si
	var rim_rect := Rect2(cx - cost_w - 6, band + 2, cost_w + si + 9, strip - 4)
	_ring("upgrade_cost", rim_rect)
	if mark == "" or mark == "affordable":
		_glow_rim(_rect_pts(rim_rect, rim_rect.size.y * 0.4), _lift("cost"))
	_icon("xp", Rect2(cx, band + (strip - si) / 2.0, si, si), colour)
	_text(Vector2(cx - cost_w - 3, band), strip, cost, strip * 0.8, colour)
	# The thin rule running from the cost to the card's edge, as printed.
	_ink.draw_line(Vector2(cx + si + 2, band + strip / 2.0), Vector2(w - b, band + strip / 2.0), Color(T.BRONZE_LIGHT, 0.7), 1.0)


## Ragged edges where the bands meet: between the name and the strip, and where the
## strip meets the field. Always torn the same way for the same card.
func _draw_tears(g: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(model.get("id", ""))
	var b: float = g.b
	var w := size.x
	var step := maxf(3.0, w * 0.022)
	for edge in [[g.band, 0.10], [g.band + g.strip, 0.22]]:
		var y0: float = edge[0]
		var depth: float = g.strip * edge[1]
		var pts := PackedVector2Array([Vector2(b, y0 - 1)])
		var x := b
		while x < w - b:
			pts.append(Vector2(x, y0 + rng.randf_range(0.0, depth)))
			x += step * rng.randf_range(0.6, 1.4)
		pts.append(Vector2(w - b, y0 + rng.randf_range(0.0, depth)))
		pts.append(Vector2(w - b, y0 - 1))
		_ink.draw_colored_polygon(pts, T.CARD_FRAME)


## The large, faint Ether emblem right of centre in the field.
func _draw_sigil(g: Dictionary, e) -> void:
	var f: Rect2 = g.field
	var sig := minf(f.size.x * 0.62, f.size.y * 0.7)
	var rect := Rect2(f.end.x - sig - g.pad * 0.3, f.get_center().y - sig / 2.0, sig, sig)
	var lift := _lift("ether")
	var alpha := 0.3 + 0.25 * lift - 0.1 * _hush("ether")
	_icon("sigil_" + str(e), rect, Color(T.ether_shade(e, "lit") if not dimmed else T.INK_MUTED, alpha))
	if lift > 0.0:
		_icon("sigil_" + str(e), rect.grow(sig * 0.03), Color(T.FOCUS, 0.18 * lift))


## The sword the stat column hangs from: blade, crossguard at the actions, pommel at the Armor.
func _draw_sword(g: Dictionary) -> void:
	var row: float = g.row
	var cx: float = g.initiative.position.x + row * 0.5
	var blade := maxf(2.0, roundf(size.x * 0.016))
	var top: float = g.initiative.get_center().y
	var bottom: float = g.armor.end.y + row * 0.12
	var steel := STEEL if not dimmed else T.LINE_SOFT
	_ink.draw_rect(Rect2(cx - blade / 2.0 + 1, top + 1, blade, bottom - top), Color(0, 0, 0, 0.4))
	_ink.draw_rect(Rect2(cx - blade / 2.0, top, blade, bottom - top), steel.darkened(0.15))
	_ink.draw_line(Vector2(cx - blade / 2.0 + 0.5, top), Vector2(cx - blade / 2.0 + 0.5, bottom), steel.lightened(0.35), 1.0)
	var guard_y: float = g.arrow.get_center().y
	var guard := Rect2(g.b + 1, guard_y - blade * 0.8, cx - g.b + blade * 2.5, blade * 1.6)
	_ink.draw_rect(Rect2(guard.position + Vector2(1, 1), guard.size), Color(0, 0, 0, 0.4))
	_ink.draw_rect(guard, steel.darkened(0.1))
	_ink.draw_line(guard.position + Vector2(0, 0.5), Vector2(guard.end.x, guard.position.y + 0.5), steel.lightened(0.35), 1.0)
	_ink.draw_circle(Vector2(cx, bottom), blade * 1.5, steel.darkened(0.2))
	_ink.draw_circle(Vector2(cx, bottom - blade * 0.4), blade * 0.7, steel.lightened(0.3))


## Jagged cracks from the top right corner: this card was Downgraded this Encounter.
func _crack() -> void:
	var w := size.x
	var o := Vector2(w - 2, 2)
	var lines := [
		[o, o + Vector2(-w * 0.12, w * 0.1), o + Vector2(-w * 0.16, w * 0.24), o + Vector2(-w * 0.27, w * 0.31)],
		[o + Vector2(-w * 0.12, w * 0.1), o + Vector2(-w * 0.26, w * 0.12), o + Vector2(-w * 0.33, w * 0.06)],
		[o, o + Vector2(-w * 0.03, w * 0.2), o + Vector2(-w * 0.08, w * 0.34)],
	]
	for pts in lines:
		_ink.draw_polyline(PackedVector2Array(pts), Color(T.BG_BASE, 0.9), maxf(3.0, w * 0.024))
		_ink.draw_polyline(PackedVector2Array(pts), T.BAD, maxf(1.5, w * 0.01))


# ---------------------------------------------------------------- treatments

## A plate's fill as the focus leaves it: full, or drawn back toward the band colour.
func _fill_for(key: String, fill: Color) -> Color:
	if dimmed:
		return fill if fill == T.BG_BAND else T.INK_MUTED.darkened(0.55)
	return fill.lerp(T.BG_BAND, QUIET * _hush(key))


func _ink_for(key: String, ink: Color) -> Color:
	if dimmed:
		return T.INK_MUTED
	return ink.lerp(T.INK_MUTED, _hush(key))


## A raised piece lit from the top: shadow, focus glow, body, top highlight, bottom
## shade, then the focus rim if the part is in focus.
func _raised(pts: PackedVector2Array, fill: Color, key: String) -> void:
	var lift := _lift(key)
	var drop := maxf(1.0, size.x * 0.01) + lift * 1.5
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(0, drop))
	_ink.draw_colored_polygon(shadow, Color(0, 0, 0, 0.4))
	if lift > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		var wd := maxf(2.0, size.x * 0.012)
		_ink.draw_polyline(closed, Color(T.FOCUS, 0.1 * lift), wd * 6.0, true)
		_ink.draw_polyline(closed, Color(T.FOCUS, 0.22 * lift), wd * 3.0, true)
	var body := pts
	if lift > 0.0:
		body = PackedVector2Array()
		for p in pts:
			body.append(p - Vector2(0, lift * 1.5))
	_ink.draw_colored_polygon(body, fill)
	var centre := Vector2.ZERO
	for p in body:
		centre += p
	centre /= body.size()
	var hush := _hush(key)
	for i in body.size():
		var p1: Vector2 = body[i]
		var p2: Vector2 = body[(i + 1) % body.size()]
		var mid := (p1 + p2) / 2.0
		if mid.y < centre.y - 1.0:
			_ink.draw_line(p1, p2, Color(fill.lightened(0.35), 0.7 * (1.0 - hush)), 1.0, true)
		elif mid.y > centre.y + 1.0:
			_ink.draw_line(p1, p2, Color(fill.darkened(0.5), 0.9), 1.0, true)
	_glow_rim(body, lift)


## The focus rim around a part of the card, at a given strength.
func _glow_rim(pts: PackedVector2Array, amount: float) -> void:
	if amount <= 0.0:
		return
	var closed := pts.duplicate()
	closed.append(pts[0])
	_ink.draw_polyline(closed, Color(T.FOCUS, amount), maxf(2.0, size.x * 0.012), true)


## A ring behind a figure that would change.
func _ring(key: String, rect: Rect2) -> void:
	if not changed.has(key):
		return
	var s := StyleBoxFlat.new()
	s.bg_color = Color(glow, 0.35)
	s.border_color = glow
	s.set_border_width_all(maxi(2, int(size.x * 0.016)))
	s.set_corner_radius_all(int(rect.size.y * 0.3))
	_ink.draw_style_box(s, rect.grow(maxf(3.0, size.x * 0.018)))


## A small round mark with text, fading in with the focus.
func _chip(text: String, centre: Vector2, h: float, bg: Color, alpha: float) -> void:
	var font := UI.font("display_bold")
	var fs := int(h * 0.72)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var rect := Rect2(centre.x, centre.y - h / 2.0, tw + h * 0.6, h)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(bg, alpha)
	s.set_corner_radius_all(int(h / 2.0))
	s.border_color = Color(0, 0, 0, 0.5 * alpha)
	s.set_border_width_all(1)
	_ink.draw_style_box(s, rect)
	_number(rect, text, fs, Color(UI.best_ink(bg), alpha))


## An Ether icon on a small dark disc.
func _pip(element, centre: Vector2, d: float) -> void:
	if element == null:
		return
	_ink.draw_circle(centre, d / 2.0, T.CARD_FRAME)
	var i := d * 0.68
	_icon(element, Rect2(centre - Vector2(i, i) / 2.0, Vector2(i, i)), T.ether_shade(element, "lit") if not dimmed else T.INK_MUTED)


# ---------------------------------------------------------------- shapes

func _octagon(r: Rect2, cut_share := 0.28) -> PackedVector2Array:
	return _rect_pts(r, r.size.y * cut_share)


func _rect_pts(r: Rect2, cut: float) -> PackedVector2Array:
	var c := minf(cut, minf(r.size.x, r.size.y) / 2.0)
	return PackedVector2Array([
		r.position + Vector2(c, 0), Vector2(r.end.x - c, r.position.y), Vector2(r.end.x, r.position.y + c),
		Vector2(r.end.x, r.end.y - c), Vector2(r.end.x - c, r.end.y), Vector2(r.position.x + c, r.end.y),
		Vector2(r.position.x, r.end.y - c), Vector2(r.position.x, r.position.y + c)])


## A banner with a notched point at the bottom, for Initiative.
func _pennant(r: Rect2) -> PackedVector2Array:
	var x := r.position.x
	var y := r.position.y
	var s := r.size.x
	return PackedVector2Array([Vector2(x, y), Vector2(x + s, y), Vector2(x + s, y + s),
		Vector2(x + s / 2.0, y + s * 0.8), Vector2(x, y + s)])


## A heater shield, for Armor.
func _shield(r: Rect2) -> PackedVector2Array:
	var x := r.position.x
	var y := r.position.y
	var s := r.size.x
	return PackedVector2Array([Vector2(x + s * 0.5, y), Vector2(x + s, y + s * 0.12), Vector2(x + s, y + s * 0.52),
		Vector2(x + s * 0.82, y + s * 0.8), Vector2(x + s * 0.5, y + s), Vector2(x + s * 0.18, y + s * 0.8),
		Vector2(x, y + s * 0.52), Vector2(x, y + s * 0.12)])


# ---------------------------------------------------------------- ink

## A number with the icons for its action type; `element` adds its Ether icon.
func _action(rect: Rect2, action: Dictionary, ink: Color, element, num: float) -> void:
	var icons := []
	if action.type != "move":
		icons.append("attack")
	if action.type != "attack":
		icons.append("move")
	if element != null and element != "":
		icons.append(element)
	var i := rect.size.y * 0.6
	var text := str(action.value)
	var font := UI.font("display_bold")
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(num)).x
	var total := tw + icons.size() * (i + 2)
	var x := rect.position.x + maxf(4.0, (rect.size.x - total) / 2.0)
	_text(Vector2(x, rect.position.y), rect.size.y, text, num, ink)
	x += tw + 3
	for name in icons:
		_icon(name, Rect2(x, rect.position.y + (rect.size.y - i) / 2.0, i, i), ink)
		x += i + 2


func _icon(name: String, rect: Rect2, color: Color) -> void:
	_ink.draw_texture_rect(UI.icon(name), rect, false, color)


## Text centred in a rectangle.
func _number(rect: Rect2, text: String, font_size: float, color: Color) -> void:
	var font := UI.font("display_bold")
	var fs := int(font_size)
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var base := rect.get_center().y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	_ink.draw_string(font, Vector2(rect.get_center().x - sz.x / 2.0, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)


## Left-aligned text centred vertically in a row; returns its width.
func _text(pos: Vector2, row_h: float, text: String, font_size: float, color: Color) -> float:
	var font := UI.font("display_bold")
	var fs := int(font_size)
	var base := pos.y + row_h / 2.0 + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	_ink.draw_string(font, Vector2(pos.x, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


## The name on one or two lines, at the largest size that fits.
func _name(rect: Rect2, text: String, color: Color) -> void:
	var font := UI.font("display")
	var words := text.split(" ")
	var lines := [text]
	if words.size() > 1:
		# Break where the two lines are closest in length.
		var best := 100000.0
		for i in range(1, words.size()):
			var a := " ".join(words.slice(0, i))
			var b := " ".join(words.slice(i))
			var worst := maxf(a.length(), b.length())
			if worst < best:
				best = worst
				lines = [a, b]
	# One line if it fits at a good size.
	var one := int(minf(T.CARD_NAME[1] * size.x / 190.0, rect.size.y * 0.62))
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, one).x <= rect.size.x:
		lines = [text]
	var fs := int(minf(T.CARD_NAME[1] * size.x / 190.0, rect.size.y / (lines.size() * 1.3)))
	while fs > 9:
		var fits := true
		for line in lines:
			if font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > rect.size.x:
				fits = false
		if fits:
			break
		fs -= 1
	var line_h := font.get_height(fs) * 0.9
	var y := rect.position.y + (rect.size.y - line_h * lines.size()) / 2.0 + font.get_ascent(fs) * 0.9
	for line in lines:
		_ink.draw_string(font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
		y += line_h
