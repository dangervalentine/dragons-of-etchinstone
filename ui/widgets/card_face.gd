extends Control
## Draws the face of a Mage Card at any size, in the style of the printed card: a
## near-black frame; the Level crown, Ether pip and name across the top; the bronze
## Key Card strip under it, torn where it meets the field; then the living Ether
## field, with the stat column hanging off a sword down its left edge: Initiative
## pennant, basic and enhanced action plates, Boost, and the Armor shield. Only the
## current Level is drawn.
##
## A focus (the parts of the card the current step uses) lifts those parts with a
## rim; the rest of the card keeps its brightness (owner, feature 006: the same
## brightness whatever the selection, only the part it affects highlighted). For the
## Ether that part is the pip beside the name, not the whole field.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Settings = preload("res://ui/model/settings.gd")
const FIELD_SHADER = preload("res://ui/fx/shaders/ether_card.gdshader")

## How far a quietened plate's fill moves toward the band colour; tests/test_card_contrast.gd checks it.
const QUIET := 0.75
## How far a placed card's unused figures step back: part of the way to quiet,
## and a little see-through, so even the near-black plates recede.
const HUSH := 0.6
const FADE := 0.6
## How far a dark plate in focus warms toward the focus colour.
const LIT := 0.3
const STEEL := Color("8f8aa0")
## The widest line any Mage Card name needs in capitals, a single unbreakable word;
## every name is set at the size that fits it.
const LONGEST_LINE := "DESTRUCTION"

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
		"damage_element": f.get("damage_element", ""), "impacts": f.get("impacts", []), "aim": f.get("aim"),
		"quiet": f.get("quiet", [])}
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


## How strongly a region is quietened (0 to 1), through any fade in progress: a
## placed card's figures that play no part step back a little (owner, specs/011),
## so the lifted and marked ones stand out.
func _hush(key: String) -> float:
	if dimmed:
		return 0.0
	var q := func(f: Dictionary) -> float: return 1.0 if f.get("quiet", []).has(key) else 0.0
	return HUSH * lerpf(q.call(_focus_from), q.call(_focus), _focus_t)


static func _has(f: Dictionary, key: String) -> float:
	return 1.0 if f.get("regions", []).has(key) else 0.0


## The field keeps one brightness whatever the step: the Ether's focus shows on the
## pip beside the name instead.
func _apply_focus_to_field() -> void:
	_field.material.set_shader_parameter("focus_dim", 0.0)
	_field.material.set_shader_parameter("glow", 0.0)


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
	var row := floorf((field.size.y - pad - 3 * gap) / 5.08)
	var plate_w := roundf(w * 0.44)
	var x := pad
	var y := field.position.y + pad * 0.5
	var g := {"b": b, "pad": pad, "band": band, "strip": strip, "field": field, "gap": gap, "row": row}
	g.initiative = Rect2(x, y, row, row)
	y += row + gap
	g.basic = Rect2(x, y, plate_w, row)
	y += row
	# The plates nearly touch, as printed; the arrow sits in their notches.
	g.arrow = Rect2(x, y, plate_w, row * 0.08)
	y += row * 0.08
	g.enhanced = Rect2(x, y, plate_w, row)
	y += row + gap
	g.boost = Rect2(x, y, roundf(plate_w * 0.72), row)
	y += row + gap
	g.armor = Rect2(x, y, roundf(row * 1.75), row)
	var crown := roundf(band * 0.68)
	g.level = Rect2(pad * 0.55, (band - crown) / 2.0, crown, crown)
	var name_x: float = g.level.end.x + pad * 0.15
	g.name = Rect2(name_x, 2, w - name_x - pad * 0.3, band - 4)
	g.key = Rect2(b, band, roundf(w * 0.5), strip)
	g.cost = Rect2(roundf(w * 0.62), band, w - roundf(w * 0.62) - b, strip)
	g.ether = field
	return g


## The rectangle of one part of the card: level, name, key, cost, initiative,
## basic, enhanced, boost, armor or ether.
func region_rect(key: String) -> Rect2:
	return _geo()[key]


## Where the small Ether sigils sit: beside the name, on the enhanced plate's corner
## and, when the Armor has an Ether, on the shield's corner.
func sigil_rects() -> Array:
	var g := _geo()
	var out := []
	var pip: float = g.band * 0.3
	out.append(_square(Vector2(g.name.position.x + pip * 0.5, g.band / 2.0), pip))
	var r: Rect2 = g.enhanced
	out.append(_square(Vector2(r.end.x - r.size.y * 0.06, r.end.y - r.size.y * 0.06), r.size.y * 0.42))
	if not model.is_empty() and model.stats.armor.element != null:
		var a: Rect2 = g.armor
		var shield := Rect2(a.position, Vector2(a.size.y, a.size.y))
		out.append(_square(Vector2(shield.end.x - shield.size.x * 0.12, shield.end.y - shield.size.y * 0.1), shield.size.y * 0.42))
	return out


## The Ether each of sigil_rects() shows, in the same order: the card's own, the
## enhanced action's and the Armor's.
func sigil_ethers() -> Array:
	if model.is_empty():
		return []
	var out: Array = [model.element, model.stats.enhanced.element]
	if model.stats.armor.element != null:
		out.append(model.stats.armor.element)
	return out


## Where `count` marks sit beside a part of the stat column (specs/011 research R3):
## squares a little smaller than the row, centred on the part's height, set left to
## right just past its plate (and past the enhanced plate's corner sigil).
func mark_rects(region: String, count: int) -> Array:
	var g := _geo()
	var r: Rect2 = g[region]
	var side := roundf(g.row * 0.72)
	var gap := maxf(3.0, roundf(g.row * 0.2))
	var x := r.end.x + gap
	var out := []
	for i in count:
		out.append(Rect2(x, r.get_center().y - side / 2.0, side, side))
		x += side + gap
	return out


## The marks beside each part: the Boost's aim first, then each effect working
## against the figure (specs/011 contracts/card-marks.md), as {region: [mark]} where a
## mark is {"icon": name} or {"glyph": text, "colour": c}.
func marks() -> Dictionary:
	var out := {}
	var aim = _focus.get("aim")
	if aim != null:
		out["boost"] = [{"icon": aim.to} if aim.to != null else {"glyph": "?", "colour": T.GOLD}]
	for m in _focus.get("impacts", []):
		if not out.has(m.region):
			out[m.region] = []
		out[m.region].append({"icon": m.icon})
	return out


static func _square(centre: Vector2, d: float) -> Rect2:
	return Rect2(centre - Vector2(d, d) / 2.0, Vector2(d, d))


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

	_strip_glows.clear()
	_rings.clear()
	_draw_strip(g, lv)
	_draw_tears(g)
	_draw_sigil(g, e)
	_draw_sword(g)

	# Initiative, on its pennant.
	var r: Rect2 = g.initiative
	_ring("initiative", _pennant(r))
	var ink := _ink_for("initiative", T.INK)
	_raised(_pennant(r), _fill_for("initiative", T.BG_BAND), "initiative")
	_number(Rect2(r.position.x, r.position.y - r.size.y * 0.07, r.size.x, r.size.y), str(lv.initiative), num * 0.8, ink)

	# The basic action, the arrow down to the enhanced action, and the enhanced action.
	r = g.basic
	_ring("basic", _twin_octagon(r))
	_raised(_twin_octagon(r), _fill_for("basic", T.BG_BAND), "basic")
	_action(r, lv.basic, _ink_for("basic", T.INK), num)
	r = g.enhanced
	var enh = lv.enhanced.element
	_ring("enhanced", _twin_octagon(r))
	var enh_fill := T.ether_shade(enh, "plate")
	var enh_ink := T.ether_shade(enh, "plate_ink")
	if dimmed:
		enh_fill = T.INK_MUTED.darkened(0.55)
		enh_ink = T.INK_MUTED
	_raised(_twin_octagon(r), _fill_for("enhanced", enh_fill), "enhanced")
	_action(r, lv.enhanced, _ink_for("enhanced", enh_ink), num)
	_corner_sigil(enh, Vector2(r.end.x - r.size.y * 0.06, r.end.y - r.size.y * 0.06), r.size.y * 0.42)
	_down_arrow(g)

	# Boost.
	r = g.boost
	_ring("boost", _notched(r))
	_raised(_notched(r), _fill_for("boost", T.BG_BAND), "boost")
	_number(r, "+%d" % lv.boost, num, _ink_for("boost", T.INK))

	# Armor, on its shield: filled with the Armor's Ether when it has one.
	r = g.armor
	var armored: bool = lv.armor.element != null
	var shield := Rect2(r.position, Vector2(r.size.y, r.size.y))
	_ring("armor", _shield(shield))
	var shield_fill := T.ether_shade(lv.armor.element, "plate") if armored and not dimmed else T.BG_BAND
	_raised(_shield(shield), _fill_for("armor", shield_fill), "armor")
	_number(Rect2(shield.position.x, shield.position.y - shield.size.y * 0.06, shield.size.x, shield.size.y),
		str(lv.armor.value), num * 0.8, _ink_for("armor", UI.best_ink(shield_fill) if armored and not dimmed else T.INK))
	if armored:
		_corner_sigil(lv.armor.element, Vector2(shield.end.x - shield.size.x * 0.12, shield.end.y - shield.size.y * 0.1), shield.size.y * 0.42)
	if _focus.get("mark", "") == "soaks_more" and not dimmed:
		_chip("×2", Vector2(r.position.x + r.size.y * (1.2 if armored else 1.05) + 3, shield.get_center().y),
			shield.size.y * 0.62, T.ether_shade(_focus.get("damage_element", ""), "lit"), _focus_t)

	_draw_marks()
	_draw_top_band(g, e)
	# The strip's glows go over the torn edge and the band, which would hide their top.
	for sg in _strip_glows:
		_glow_rim(sg[0], sg[1])
	_draw_rings()
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
	_ring("level", _rect_pts(c.grow(1), c.size.y * 0.2))
	_glow_rim(_rect_pts(c.grow(1), c.size.y * 0.2), _lift("level"))
	_icon("crown", c, _ink_for("level", T.INK) if not dimmed else T.INK_MUTED)
	_number(Rect2(c.position + Vector2(0, c.size.y * 0.06), c.size), str(model.level), c.size.y * 0.5, T.BG_BASE)
	if model.get("downgraded", false):
		var a: float = c.size.y * 0.5
		_icon("down_arrow", Rect2(c.end - Vector2(a * 0.8, a * 0.8), Vector2(a, a)), T.BAD)
	var n: Rect2 = g.name
	var pip: float = band * 0.3
	var pip_c := Vector2(n.position.x + pip * 0.5, band / 2.0)
	# The Ether in focus (an Element, a Fuse) rings this pip, as the plates are rimmed.
	var lift := _lift("ether")
	if lift > 0.0:
		_ink.draw_arc(pip_c, pip * 0.78, 0.0, TAU, 32, Color(T.muted(T.FOCUS), lift), maxf(2.0, size.x * 0.012), true)
	_icon(e, Rect2(pip_c - Vector2(pip, pip) / 2.0, Vector2(pip, pip)), T.ether_shade(e, "lit") if not dimmed else T.INK_MUTED)
	var text_x: float = n.position.x + pip + g.pad * 0.1
	_name(Rect2(text_x, n.position.y, n.end.x - text_x, n.size.y), model.name.to_upper(),
		_ink_for("name", T.INK) if not dimmed else T.INK_MUTED)


## Where the Hardship icon sits on the Key Card strip: after the Encounter icon
## and its number.
func hardship_rect() -> Rect2:
	if model.is_empty() or model.stats.hardship == null:
		return Rect2()
	var g := _geo()
	var strip: float = g.strip
	var si := roundf(strip * 0.72)
	var fs := int(strip * 0.8)
	var x: float = g.b + strip * 0.45 + g.pad * 0.2 + si + 2
	x += UI.font("display_bold").get_string_size(str(model.stats.encounter.index), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + g.pad * 0.5
	return Rect2(x, g.band + (strip - si) / 2.0, si, si)


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
		_ring("encounter" if changed.has("encounter") else "hardship", _rect_pts(kr.grow(-1), strip * 0.3))
	_strip_glows.append([_rect_pts(kr.grow(-1), strip * 0.3), _lift("key")])
	var ink := _ink_for("key", T.INK) if not dimmed else T.INK_MUTED
	var x: float = b + tab + g.pad * 0.2
	_icon(key.type, Rect2(x, band + (strip - si) / 2.0, si, si), ink)
	x += si + 2
	x += _text(Vector2(x, band), strip, str(key.index), strip * 0.8, ink) + g.pad * 0.5
	if lv.hardship != null:
		_icon(lv.hardship, hardship_rect(), _ink_for("key", T.INK) if not dimmed else T.INK_MUTED)

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
	# Wide enough that the rim's cut corners clear the number.
	var rim_rect := Rect2(cx - cost_w - 3 - strip * 0.42, band + 2, cost_w + si + 6 + strip * 0.42, strip - 4)
	_ring("upgrade_cost", _rect_pts(rim_rect, rim_rect.size.y * 0.4))
	if mark == "" or mark == "affordable":
		_strip_glows.append([_rect_pts(rim_rect, rim_rect.size.y * 0.4), _lift("cost")])
	_icon("upgrade", Rect2(cx, band + (strip - si) / 2.0, si, si), colour)
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
	# The same whatever the step: the Ether's focus shows on the pip by the name.
	_icon("sigil_" + str(e), rect, Color(T.ether_shade(e, "lit") if not dimmed else T.INK_MUTED, 0.3))


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
	_ink.draw_circle(Vector2(cx, bottom), blade * 1.5, steel.darkened(0.2))
	_ink.draw_circle(Vector2(cx, bottom - blade * 0.4), blade * 0.7, steel.lightened(0.3))


## The card is broken: it was Downgraded this Encounter. A point of impact near the
## top right, a spider of short cracks round it, and one fissure that runs down and
## across the face, tapering, with two thinner branches. Each crack is a dark split
## with a lit edge on one side and a faint ember core, so it reads as cut into the
## card rather than scribbled on it. The pattern follows from the card's id, so each
## card breaks its own way and always the same way.
func _crack() -> void:
	var w := size.x
	var h := size.y
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(model.get("id", "")))
	var hit := Vector2(w * rng.randf_range(0.66, 0.8), h * rng.randf_range(0.27, 0.33))
	# The fissure keeps to the art, right of the number plates, so every figure stays
	# readable through it.
	var main := _fissure(rng, hit, Vector2(w * rng.randf_range(0.5, 0.6), h * rng.randf_range(0.84, 0.92)), 7, w * 0.05)
	var cracks := [[main, w * 0.06]]
	# Branches leave the fissure partway down and thin out sooner.
	cracks.append([_fissure(rng, main[2], Vector2(w * 0.97, h * rng.randf_range(0.42, 0.52)), 4, w * 0.03), w * 0.03])
	cracks.append([_fissure(rng, main[4], Vector2(w * rng.randf_range(0.5, 0.56), h * rng.randf_range(0.58, 0.66)), 3, w * 0.02), w * 0.026])
	# The spider round the point of impact.
	for i in 5:
		var a := TAU * i / 5.0 + rng.randf_range(-0.35, 0.35)
		var reach := w * rng.randf_range(0.06, 0.12)
		cracks.append([_fissure(rng, hit, hit + Vector2.from_angle(a) * reach, 2, w * 0.012), w * 0.014])
	for c in cracks:
		_split(c[0], c[1])
	# Chips knocked out at the point of impact.
	for i in 3:
		var at := hit + Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * w * 0.025
		var r := w * rng.randf_range(0.008, 0.016)
		var chip := PackedVector2Array()
		for k in 3:
			chip.append(at + Vector2.from_angle(TAU * k / 3.0 + rng.randf() * 1.5) * r)
		_ink.draw_colored_polygon(chip, Color(0.02, 0.01, 0.03, 0.85))
	_ink.draw_circle(hit, w * 0.014, Color(T.BAD, 0.55))


## A jagged path from `from` to `to` in `steps` legs, each bend pushed aside by up to
## `jitter`, the bends nearer the start pushed less so the crack fans out.
func _fissure(rng: RandomNumberGenerator, from: Vector2, to: Vector2, steps: int, jitter: float) -> PackedVector2Array:
	var pts := PackedVector2Array([from])
	var side := (to - from).orthogonal().normalized()
	for i in range(1, steps):
		var t := float(i) / steps
		var along := from.lerp(to, t + rng.randf_range(-0.3, 0.3) / steps)
		pts.append(along + side * rng.randf_range(-1.0, 1.0) * jitter * (0.4 + t))
	pts.append(to)
	return pts


## One crack along `pts`, `width` wide at its start and tapering to a hair: the dark
## split, its lit lower edge, and a thin ember core.
func _split(pts: PackedVector2Array, width: float) -> void:
	var n := pts.size()
	if n < 2:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n:
		var dir := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var half := maxf(0.4, width * (1.0 - float(i) / (n - 1)) * 0.5)
		left.append(pts[i] + dir.orthogonal() * half)
		right.append(pts[i] - dir.orthogonal() * half)
	var body := left.duplicate()
	for i in range(n - 1, -1, -1):
		body.append(right[i])
	if Geometry2D.triangulate_polygon(body).is_empty():
		_ink.draw_polyline(pts, Color(0.02, 0.01, 0.03, 0.9), maxf(1.5, width))
	else:
		_ink.draw_colored_polygon(body, Color(0.02, 0.01, 0.03, 0.9))
	# Light catches the lower lip of the break.
	_ink.draw_polyline(right, Color(1, 1, 1, 0.38), maxf(1.0, width * 0.2), true)
	if width > size.x * 0.018:
		_ink.draw_polyline(pts, Color(T.BAD, 0.45), maxf(1.0, width * 0.14), true)


# ---------------------------------------------------------------- treatments

## A plate's fill as the focus leaves it: full, or drawn back toward the band colour.
func _fill_for(key: String, fill: Color) -> Color:
	if dimmed:
		return fill if fill == T.BG_BAND else T.INK_MUTED.darkened(0.55)
	# A dark plate in focus takes a warm glow of its own: on the near-black plates a
	# rim alone barely shows (owner, specs/011).
	var lift := _lift(key)
	if lift > 0.0 and fill.get_luminance() < 0.2:
		fill = fill.lerp(T.FOCUS, LIT * lift)
	var hush := _hush(key)
	var out := fill.lerp(T.BG_BAND, QUIET * hush)
	out.a = 1.0 - FADE * hush
	return out


func _ink_for(key: String, ink: Color) -> Color:
	if dimmed:
		return T.INK_MUTED
	var hush := _hush(key)
	var out := ink.lerp(T.INK_MUTED, hush)
	out.a = 1.0 - FADE * hush
	return out


## A raised piece lit from the top: shadow, focus glow, body, top highlight, bottom
## shade, then the focus rim if the part is in focus.
func _raised(pts: PackedVector2Array, fill: Color, key: String) -> void:
	var lift := _lift(key)
	var drop := maxf(1.0, size.x * 0.01) + lift * 1.5
	var shadow := PackedVector2Array()
	for p in pts:
		shadow.append(p + Vector2(0, drop))
	_ink.draw_colored_polygon(shadow, Color(0, 0, 0, 0.4 * fill.a))
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
	# A soft halo outside, then the rim itself at full focus colour.
	_ink.draw_polyline(closed, Color(T.FOCUS, 0.22 * amount), maxf(6.0, size.x * 0.045), true)
	_ink.draw_polyline(closed, Color(T.FOCUS, amount), maxf(2.0, size.x * 0.016), true)


## Marks a figure that would change. The outline follows the figure's own shape and
## is drawn once the card is done, so neighbours and the title band never cover it.
func _ring(key: String, pts: PackedVector2Array) -> void:
	if changed.has(key):
		_rings.append(pts)


func _draw_rings() -> void:
	var wd := maxf(2.0, size.x * 0.012)
	for pts in _rings:
		var closed: PackedVector2Array = pts.duplicate()
		closed.append(pts[0])
		_ink.draw_polyline(closed, glow, wd, true)


## Each mark on a dark disc, so it reads over any Ether's field: the effect's or the
## aim's icon, or the unaimed Boost's "?" (a glyph, not a colour alone).
func _draw_marks() -> void:
	if dimmed:
		return
	var all := marks()
	for region in all:
		var list: Array = all[region]
		var rects := mark_rects(region, list.size())
		for i in list.size():
			var r: Rect2 = rects[i]
			var m: Dictionary = list[i]
			_ink.draw_circle(r.get_center(), r.size.x / 2.0, Color(T.BG_BASE, 0.85))
			_ink.draw_arc(r.get_center(), r.size.x / 2.0, 0.0, TAU, 24, Color(T.LINE_SOFT, 0.6), 1.0, true)
			if m.has("glyph"):
				_number(r, m.glyph, r.size.y * 0.72, m.colour)
			else:
				_icon(m.icon, Rect2(r.get_center() - r.size * 0.35, r.size * 0.7), T.INK)


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


## A bare Ether icon, a shade brighter than its plate, on a soft drop shadow that lifts it off
## the plate, at the printed card's enhanced plate corner.
func _corner_sigil(element, centre: Vector2, d: float) -> void:
	if element == null:
		return
	var colour: Color = T.ether_shade(element, "plate").lerp(T.ether_shade(element, "lit"), 0.5) if not dimmed else T.INK_MUTED
	var r := Rect2(centre - Vector2(d, d) / 2.0, Vector2(d, d))
	var w := maxf(1.0, d * 0.08)
	for k in 8:
		var off := Vector2.RIGHT.rotated(k * PI / 4.0) * w + Vector2(w * 0.4, w * 1.2)
		_icon(element, Rect2(r.position + off, r.size), Color(0, 0, 0, 0.22))
	_icon(element, r, colour)


# ---------------------------------------------------------------- shapes

func _octagon(r: Rect2, cut_share := 0.28) -> PackedVector2Array:
	return _rect_pts(r, r.size.y * cut_share)


## An action plate as printed: two octagons pushed together, leaving a V notch
## top and bottom where they meet.
func _twin_octagon(r: Rect2) -> PackedVector2Array:
	var c := r.size.y * 0.22
	var d := c * 0.6
	var m := r.get_center().x
	var x0 := r.position.x
	var y0 := r.position.y
	return PackedVector2Array([
		Vector2(x0 + c, y0), Vector2(m - c, y0), Vector2(m, y0 + d), Vector2(m + c, y0),
		Vector2(r.end.x - c, y0), Vector2(r.end.x, y0 + c), Vector2(r.end.x, r.end.y - c), Vector2(r.end.x - c, r.end.y),
		Vector2(m + c, r.end.y), Vector2(m, r.end.y - d), Vector2(m - c, r.end.y), Vector2(x0 + c, r.end.y),
		Vector2(x0, r.end.y - c), Vector2(x0, y0 + c)])


## The Boost plate as printed: a block with a square step cut from each corner.
func _notched(r: Rect2) -> PackedVector2Array:
	var n := r.size.y * 0.14
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x
	var y1 := r.end.y
	return PackedVector2Array([
		Vector2(x0 + n, y0), Vector2(x1 - n, y0), Vector2(x1 - n, y0 + n), Vector2(x1, y0 + n),
		Vector2(x1, y1 - n), Vector2(x1 - n, y1 - n), Vector2(x1 - n, y1), Vector2(x0 + n, y1),
		Vector2(x0 + n, y1 - n), Vector2(x0, y1 - n), Vector2(x0, y0 + n), Vector2(x0 + n, y0 + n)])


func _rect_pts(r: Rect2, cut: float) -> PackedVector2Array:
	var c := minf(cut, minf(r.size.x, r.size.y) / 2.0)
	return PackedVector2Array([
		r.position + Vector2(c, 0), Vector2(r.end.x - c, r.position.y), Vector2(r.end.x, r.position.y + c),
		Vector2(r.end.x, r.end.y - c), Vector2(r.end.x - c, r.end.y), Vector2(r.position.x + c, r.end.y),
		Vector2(r.position.x, r.end.y - c), Vector2(r.position.x, r.position.y + c)])


## The arrow from the basic plate down to the enhanced one, in the gap where the
## plates' notches meet, as printed.
func _down_arrow(g: Dictionary) -> void:
	var row: float = g.row
	var cx: float = g.basic.get_center().x
	var top: float = g.basic.end.y - row * 0.1
	var bottom: float = g.enhanced.position.y + row * 0.12
	var shaft := row * 0.06
	var head := row * 0.14
	var neck := bottom - head * 0.9
	var pts := PackedVector2Array([Vector2(cx - shaft, top), Vector2(cx + shaft, top), Vector2(cx + shaft, neck),
		Vector2(cx + head, neck), Vector2(cx, bottom), Vector2(cx - head, neck), Vector2(cx - shaft, neck)])
	var closed := pts.duplicate()
	closed.append(pts[0])
	_ink.draw_polyline(closed, Color(T.BG_BASE, 0.9), maxf(2.0, row * 0.06), true)
	_ink.draw_colored_polygon(pts, STEEL if not dimmed else T.LINE_SOFT)


## Glows around parts of the Key Card strip, drawn once the band above is down.
var _strip_glows := []
## Outlines of the figures that would change, drawn last.
var _rings := []


## The Initiative banner as printed: sides curving in between flared top corners
## and flared tails, with a shallow notch between the tails.
func _pennant(r: Rect2) -> PackedVector2Array:
	return _shape(r, [[0, 0], [1, 0], [0.955, 0.2], [0.935, 0.4], [0.94, 0.6], [0.96, 0.8], [1, 1], [0.5, 0.82],
		[0, 1], [0.04, 0.8], [0.06, 0.6], [0.065, 0.4], [0.045, 0.2]])


## The Armor shield as printed: a peak at the top where the blade meets it, sharp
## shoulders, straight sides, then curving in to a point.
func _shield(r: Rect2) -> PackedVector2Array:
	return _shape(r, [[0.5, 0], [1, 0.2], [0.98, 0.55], [0.92, 0.72], [0.8, 0.85], [0.5, 1],
		[0.2, 0.85], [0.08, 0.72], [0.02, 0.55], [0, 0.2]])


## Points given as fractions of a rectangle.
func _shape(r: Rect2, uv: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in uv:
		pts.append(r.position + Vector2(p[0] * r.size.x, p[1] * r.size.y))
	return pts


# ---------------------------------------------------------------- ink

## A number with the icons for its action type; `element` adds its Ether icon.
## The number in the plate's left octagon and the action in its right, as printed.
func _action(rect: Rect2, action: Dictionary, ink: Color, num: float) -> void:
	var half := Vector2(rect.size.x / 2.0, rect.size.y)
	_number(Rect2(rect.position, half), str(action.value), num, ink)
	var right := Rect2(rect.position + Vector2(half.x, 0), half)
	if action.type == "attack" or action.type == "move":
		var i := rect.size.y * 0.6
		_icon(action.type, Rect2(right.get_center() - Vector2(i, i) / 2.0, Vector2(i, i)), ink)
		return
	# Either action: Attack over Move in the one octagon, split by a thin rule.
	var s := rect.size.y * 0.39
	var cx := right.get_center().x
	var mid := rect.position.y + rect.size.y / 2.0
	_icon("attack", Rect2(cx - s / 2.0, rect.position.y + rect.size.y * 0.06, s, s), ink)
	_ink.draw_line(Vector2(cx - s * 0.6, mid), Vector2(cx + s * 0.6, mid), ink, maxf(1.0, rect.size.y * 0.04))
	_icon("move", Rect2(cx - s / 2.0, rect.end.y - rect.size.y * 0.06 - s, s, s), ink)


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
	var fs := name_size(rect.size)
	var font := _name_font(fs)
	var lines := name_lines(text, fs, rect.size.x)
	var line_h := fs * 1.06
	var cap := fs * 0.72
	var y := rect.position.y + (rect.size.y - line_h * (lines.size() - 1) + cap) / 2.0
	for line in lines:
		_ink.draw_string(font, Vector2(rect.position.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
		y += line_h


## A name on one line if it fits, or else on two broken where the longer line is
## shortest.
static func name_lines(text: String, fs: int, width: float) -> Array:
	var font := _name_font(fs)
	var words := text.split(" ")
	var lines := [text]
	var best := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if best <= width:
		return lines
	for i in range(1, words.size()):
		var a := " ".join(words.slice(0, i))
		var b := " ".join(words.slice(i))
		var wide := maxf(font.get_string_size(a, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x,
			font.get_string_size(b, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		if wide < best:
			best = wide
			lines = [a, b]
	return lines


## The one name size for every card of this size: two lines' worth of the band, at
## most, and no wider than the widest line any name breaks into, so all names match.
static func name_size(area: Vector2) -> int:
	var fs := int(area.y * 0.43)
	while fs > 6 and _name_font(fs).get_string_size(LONGEST_LINE, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > area.x:
		fs -= 1
	return fs


static var _name_fonts := {}


## The display face, heavy enough to read at small sizes, with its letters drawn a
## little closer in step with the size, as on the printed card's title. Built on the
## font file itself: a variation of a variation drops the weight back to Regular.
static func _name_font(fs: int) -> Font:
	var squeeze := -roundi(fs * 0.05)
	if not _name_fonts.has(squeeze):
		var v := FontVariation.new()
		v.base_font = load("res://art/fonts/Cinzel.ttf")
		v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 800}
		v.spacing_glyph = squeeze
		_name_fonts[squeeze] = v
	return _name_fonts[squeeze]