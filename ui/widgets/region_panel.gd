extends Control
## One Encounter as the Region Card prints it (specs/013 contracts/region-card-face.md).
## An Enemy is a framed picture with its figures in a column of badges down the left,
## its Ability beside the HP badge and its XP Reward in a star at the bottom right. A
## Journey is a tall panel with its MP and Time Penalty in a strip along the top, the
## landscape below, its Peril at the top right of the landscape and its star at the
## foot. Every part is placed as a share of the panel's own size (parts()), so the
## same panel reads alike small on the card and large once the Deck zooms into it.
## The game adds one thing to the print: a small plate with the Encounter's number,
## since the Key Card names a number and the card only says it by position.

signal intent(data: Dictionary)

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Creature = preload("res://ui/fx/creature.gd")
const Art = preload("res://ui/model/art.gd")
const Glossary = preload("res://ui/model/glossary.gd")
const StatChip = preload("res://ui/widgets/stat_chip.gd")

## The pale grey of the printed hourglass.
const STEEL := T.METAL_LIGHT
## The printed hourglass's glass, a shade darker than its bars.
const GLASS := T.GLASS_LIGHT

var panel := {}
## The Key Card's Hardship on this Encounter, shown beside the Ability or Peril once
## the Deck has zoomed in.
var hardship = null
## Whether its badges explain themselves when pressed: on the zoomed-in panel, not
## on the whole card, which takes no input.
var interactive := false
var _creature := Creature.new()
## Holds the creature and clips it, and its drifting Ether, to the art's part of the
## frame; the creature cuts the frame's corners from itself (Creature.set_cut()),
## as clipping children would not hold inside the Deck's own clipping.
var _clip := Control.new()
## A Journey's painted map, or null.
var _map: Texture2D
## An Enemy's backdrop (art/painted/backdrops/), behind its figure, or null.
var _backdrop: Texture2D
## The soft round light drawn behind an Enemy's figure, made once.
static var _glow: GradientTexture2D
## Over the art and under the badges: the frame's edge and the number plate.
var _over := Control.new()
var _chips := {}
var _discs := []
## The number plate's text size as last laid out.
var number_size := 0
## How much of the number plate shows, 0 to 1: on the whole card, to match the Key
## Card's number to; faded out as the Deck zooms in on the panel (specs/014).
var number_alpha := 1.0:
	set(v):
		number_alpha = clampf(v, 0.0, 1.0)
		_over.queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The panel does not clip its badges and discs; the art is clipped to the frame by
	# _clip.
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.clip_contents = true
	add_child(_clip)
	_creature.held = true
	_clip.add_child(_creature)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.draw.connect(_draw_over)
	add_child(_over)
	resized.connect(_fit)


func render(p: Dictionary, hardship_id = null, live_badges := false) -> void:
	if p == panel and hardship_id == hardship and live_badges == interactive:
		return
	panel = p.duplicate(true)
	hardship = hardship_id
	interactive = live_badges
	for c in _chips.values() + _discs:
		remove_child(c)
		c.queue_free()
	_chips = {}
	_discs = []
	var tint: Color = T.ether(p.element)
	# A Journey shows its painted map (art/painted/journeys/), drawn under the frame;
	# an Enemy stands in its panel.
	_map = UI.painted("journeys/" + p.art) if p.kind == "journey" and p.art != "" else null
	_backdrop = UI.painted("backdrops/" + p.art) if p.kind == "enemy" and p.art != "" else null
	# Inked round to stand off the bare panel; a backdrop sets the figure off without.
	_creature.outlined = _backdrop == null
	_creature.visible = p.kind == "enemy" and p.art != ""
	if _creature.visible and _creature.art_name != p.art:
		_creature.setup(p.art, Color(tint.lightened(0.45), 0.55), p.element, false)
	if p.kind == "enemy":
		var e: Dictionary = p.enemy
		_add("hp", {"icon": "hp", "text": str(e.hp), "color": T.STAT_HP, "glossary_id": "hp"})
		_add("initiative", {"icon": "initiative", "text": str(e.initiative), "color": T.STAT_PLATE, "glossary_id": "initiative"})
		_add("attack", {"icon": "attack_badge", "text": str(e.attack.value), "color": T.ether(e.attack.element),
			"ink": T.ether_shade(e.attack.element, "plate_ink"), "element": e.attack.element, "glossary_id": "attack"})
		for i in e.armor.size():
			var a: Dictionary = e.armor[i]
			_add("armor%d" % i, {"icon": "armor", "text": str(a.value), "color": T.ether(a.element),
				"ink": T.ether_shade(a.element, "plate_ink"), "element": a.element, "glossary_id": "armor"})
	else:
		var j: Dictionary = p.journey
		# As printed: a dark mountain in a box of the MP's Ether, and a pale hourglass.
		_add("mp", {"icon": "mp_badge", "text": str(j.mp.value), "color": T.STAT_PLATE, "backing": T.ether(j.mp.element),
			"element": j.mp.element, "glossary_id": "mp"})
		_add("time", {"icon": "time_badge", "text": str(j.time_penalty), "color": STEEL, "inset": GLASS, "inset_icon": "time_badge_glass", "glossary_id": "time"})
	_add("xp", {"icon": "xp", "text": str(p.xp), "color": T.BRASS_BRIGHT, "ink": T.ON_BRASS, "glossary_id": "xp"})
	# The Encounter's own Ability or Peril where it is printed, the Hardship beside it.
	for id in [p.effect, hardship_id]:
		if id != null:
			var disc := _make({"icon": Glossary.entry(id).icon, "text": "", "color": T.PARCHMENT, "ring": T.STAT_PLATE, "glossary_id": id})
			_discs.append(disc)
	_fit()
	queue_redraw()
	_over.queue_redraw()


## Let the creature move, or keep it still.
func set_live(on: bool) -> void:
	_creature.held = not on


func chip(name: String) -> Control:
	return _chips.get(name)


func discs() -> Array:
	return _discs


## Where each part sits on a panel of `size`: "art", "frame", "badges" (an Array of
## Rect2, one per badge row; an Enemy's two Armor shields share the last row),
## "xp", "discs" (the corner for the discs, laid right to left), "number".
static func parts(size: Vector2, kind: String, armor_count := 1) -> Dictionary:
	var w := size.x
	var h := size.y
	# The printed frame's corners are cut on the right, top and bottom.
	var out := {"frame": Rect2(Vector2.ZERO, size), "bevel": bevel(size)}
	if kind == "enemy":
		out["art"] = Rect2(w * 0.17, 0, w * 0.83, h)
		var top := h * 0.04
		var room := h * 0.92
		var row := room / 4.0
		var side := row * 0.94
		var badges := []
		for i in 4:
			var y := top + i * row + (row - side) / 2.0
			if i < 3:
				badges.append([Rect2(w * 0.02, y, side, side)])
			else:
				var s := side * (0.92 if armor_count > 1 else 1.0)
				var shields := []
				for k in armor_count:
					shields.append(Rect2(w * 0.02 + k * s * 0.98, y + (side - s) / 2.0, s, s))
				badges.append(shields)
		out["badges"] = badges
		# The star in the bottom right, the Ability beside the HP heart and level with
		# its centre, inside the frame (further discs to its right).
		var star := h * 0.22
		out["xp"] = Rect2(w - star - h * 0.03, h - star - h * 0.03, star, star)
		var d := h * 0.18
		out["discs"] = Rect2(w * 0.02 + side + h * 0.02, top + row / 2.0 - d / 2.0, d, d)
		var n := h * 0.16
		out["number"] = Rect2(w - n - h * 0.05, h * 0.05, n, n)
	else:
		var strip := h * 0.25
		out["art"] = Rect2(0, strip, w, h - strip)
		var side := minf(strip * 0.88, w * 0.46)
		var y := (strip - side) / 2.0
		out["badges"] = [[Rect2(w * 0.25 - side / 2.0, y, side, side)], [Rect2(w * 0.75 - side / 2.0, y, side, side)]]
		var star := minf(h * 0.16, w * 0.36)
		out["xp"] = Rect2((w - star) / 2.0, h - star - h * 0.02, star, star)
		var d := minf(h * 0.11, w * 0.26)
		out["discs"] = Rect2(w - d - w * 0.04, strip + w * 0.04, d, d)
		var n := minf(h * 0.1, w * 0.24)
		out["number"] = Rect2(w * 0.04, strip + w * 0.04, n, n)
	return out


## How far the frame's corners are cut: about as on the print.
static func bevel(size: Vector2) -> float:
	return minf(size.x, size.y) * 0.07


## The printed frame round `r`: a box with its right-hand corners cut by `c`.
static func outline(r: Rect2, c: float) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x - c, r.position.y), Vector2(r.end.x, r.position.y + c),
		Vector2(r.end.x, r.end.y - c), Vector2(r.end.x - c, r.end.y), Vector2(r.position.x, r.end.y)])


## The part of the frame from `top` down, its corners cut as the frame's are.
static func _below(size: Vector2, top: float, c: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, top), Vector2(size.x, top), Vector2(size.x, size.y - c),
		Vector2(size.x - c, size.y), Vector2(0, size.y)])


func _add(name: String, opts: Dictionary) -> void:
	_chips[name] = _make(opts)


func _make(opts: Dictionary) -> Control:
	var o := opts.duplicate()
	if not interactive:
		o.erase("glossary_id")
	var c: Control = StatChip.make(o)
	c.custom_minimum_size = Vector2.ZERO
	if interactive:
		c.help.connect(func(id, source): intent.emit({"type": "help", "id": id, "source": source}))
	add_child(c)
	return c


func _fit() -> void:
	if panel.is_empty():
		return
	var armor: int = panel.enemy.armor.size() if panel.kind == "enemy" else 1
	var at := parts(size, panel.kind, armor)
	var art: Rect2 = at.art
	_clip.position = art.position
	_clip.size = art.size
	_creature.position = Vector2.ZERO
	_creature.size = art.size
	_creature.crop = _crop(art.size)
	# The frame's right-hand corners cut from the art: both on an Enemy, whose art
	# runs the frame's height; on a Journey only the bottom, its top under the strip.
	var c: float = at.bevel
	_creature.set_cut(Rect2(Vector2.ZERO, art.size), c if panel.kind == "enemy" else 0.0, c)
	var rows: Array = at.badges
	var names := ["hp", "initiative", "attack"] if panel.kind == "enemy" else ["mp", "time"]
	for i in names.size():
		_put(_chips[names[i]], rows[i][0])
	if panel.kind == "enemy":
		for k in armor:
			_put(_chips["armor%d" % k], rows[3][k])
	_put(_chips.xp, at.xp)
	var d: Rect2 = at.discs
	# The Encounter's own effect first, where it is printed: an Enemy's to the right
	# of it, a Journey's to the left, from its corner.
	var step := d.size.x * 1.08 * (1.0 if panel.kind == "enemy" else -1.0)
	for i in _discs.size():
		_put(_discs[i], Rect2(d.position + Vector2(i * step, 0), d.size))
	queue_redraw()
	_over.queue_redraw()


## A chip in its printed place; one that explains itself when pressed is grown about
## its centre to a help target's least size as it shows on screen, however small the
## panel is drawn (specs/019: the left card keeps the Hand's shape).
func _put(c: Control, r: Rect2) -> void:
	if interactive and c.has_meta("help_target"):
		var k: float = maxf(0.01, get_global_transform().get_scale().x)
		var least: float = T.HELP_MIN / k
		r = r.grow_individual(maxf(0.0, (least - r.size.x) / 2.0), maxf(0.0, (least - r.size.y) / 2.0),
			maxf(0.0, (least - r.size.x) / 2.0), maxf(0.0, (least - r.size.y) / 2.0))
	c.position = r.position
	c.size = r.size


## An Enemy is cropped as its face crops it.
func _crop(art: Vector2) -> Rect2:
	if panel.kind != "enemy" or panel.art == "":
		return Art.FULL
	return load("res://ui/widgets/encounter_face.gd").enemy_crop(art)


## Where the light behind a figure falls, in the art's part of the panel: round the
## figure's box (`figure`, in its 512 units, drawn into `art`, its square), reaching
## past it by T.CREATURE_BACKLIGHT_REACH of its size on every side.
static func backlight_rect(art: Rect2, figure: Rect2) -> Rect2:
	var k := art.size.x / Art.FULL.size.x
	var box := Rect2(art.position + figure.position * k, figure.size * k)
	return box.grow_individual(box.size.x * T.CREATURE_BACKLIGHT_REACH, box.size.y * T.CREATURE_BACKLIGHT_REACH,
		box.size.x * T.CREATURE_BACKLIGHT_REACH, box.size.y * T.CREATURE_BACKLIGHT_REACH)


static func _backlight() -> GradientTexture2D:
	if _glow == null:
		var g := Gradient.new()
		g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CUBIC
		g.set_color(0, Color.WHITE)
		g.set_color(1, Color(T.SHEEN, 0))
		_glow = GradientTexture2D.new()
		_glow.gradient = g
		_glow.fill = GradientTexture2D.FILL_RADIAL
		_glow.fill_from = Vector2(0.5, 0.5)
		_glow.fill_to = Vector2(0.5, 0.0)
		_glow.width = 128
		_glow.height = 128
	return _glow


## The part of a texture of `tex` size that covers `area`, centred, the rest cut off.
static func cover_region(tex: Vector2, area: Vector2) -> Rect2:
	var k := maxf(area.x / tex.x, area.y / tex.y)
	var shown := area / k
	return Rect2((tex - shown) / 2.0, shown)


func _draw() -> void:
	if panel.is_empty():
		return
	var armor: int = panel.enemy.armor.size() if panel.kind == "enemy" else 1
	var at := parts(size, panel.kind, armor)
	var tint: Color = T.ether(panel.element)
	var edge := maxf(1.5, size.y * 0.012)
	var c: float = at.bevel
	draw_colored_polygon(outline(at.frame, c), Color(tint, 0.18))
	if _backdrop != null:
		# The backdrop fills the whole frame, the badges standing on its plain left.
		var pts := outline(at.frame, c)
		var src := cover_region(_backdrop.get_size(), at.frame.size)
		var uvs := PackedVector2Array()
		for pt in pts:
			uvs.append((src.position + (pt - at.frame.position) / at.frame.size * src.size) / _backdrop.get_size())
		draw_colored_polygon(pts, Color.WHITE, uvs, _backdrop)
	if panel.kind == "enemy" and _creature.visible and panel.art != "":
		# A soft light behind the figure, so its edge reads against the ground.
		var glow := backlight_rect(_creature.art_rect(), load("res://ui/widgets/encounter_face.gd").figure_bounds(panel.art))
		draw_texture_rect(_backlight(), Rect2(glow.position + at.art.position, glow.size), false,
			Color(T.ether_shade(panel.element, "lit"), T.CREATURE_BACKLIGHT))
	if panel.kind == "journey":
		# The printed strip along the top, in the dark of the card's band.
		var strip: float = at.art.position.y
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x - c, 0), Vector2(size.x, c),
			Vector2(size.x, strip), Vector2(0, strip)]), Color(T.STAT_PLATE, 0.92))
		if _map != null:
			# The map covers the landscape, cut at the frame's corner like it.
			var pts := _below(size, strip, c)
			var src := cover_region(_map.get_size(), at.art.size)
			var uvs := PackedVector2Array()
			for pt in pts:
				uvs.append((src.position + (pt - at.art.position) / at.art.size * src.size) / _map.get_size())
			draw_colored_polygon(pts, Color.WHITE, uvs, _map)


## The frame's edge and the number plate, over the art so a figure standing to the
## panel's foot goes behind the edge, and under the badges.
func _draw_over() -> void:
	if panel.is_empty():
		return
	var armor: int = panel.enemy.armor.size() if panel.kind == "enemy" else 1
	var at := parts(size, panel.kind, armor)
	var tint: Color = T.ether(panel.element)
	var edge := maxf(1.5, size.y * 0.012)
	var line := outline(at.frame.grow(-edge / 2.0), at.bevel)
	line.append(line[0])
	_over.draw_polyline(line, tint, edge, true)
	if number_alpha <= 0.0:
		return
	var n: Rect2 = at.number
	_over.draw_style_box(UI.box(Color(T.GROUND, 0.72 * number_alpha), Color.TRANSPARENT, 0, int(n.size.y * 0.2), 0), n)
	var font := UI.font(T.LABEL)
	number_size = maxi(T.TEXT_MIN, roundi(n.size.y * 0.78))
	var text := str(panel.index)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
	var base := n.get_center().y + (font.get_ascent(number_size) - font.get_descent(number_size)) / 2.0
	_over.draw_string(font, Vector2(n.get_center().x - tw / 2.0, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color(T.PARCHMENT, number_alpha))
	UI.drew_text(self, "number", number_size)

