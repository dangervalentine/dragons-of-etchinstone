extends Control
## One Encounter as the Region Card prints it (specs/013 contracts/region-card-face.md).
## An Enemy is a framed picture with its figures in a column of badges down the left,
## its Ability at the top right and its XP Reward in a star at the bottom right. A
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
const STEEL := Color("aaa6b8")

var panel := {}
## The Key Card's Hardship on this Encounter, shown beside the Ability or Peril once
## the Deck has zoomed in.
var hardship = null
## Whether its badges explain themselves when pressed: on the zoomed-in panel, not
## on the whole card, which takes no input.
var interactive := false
var _creature := Creature.new()
## A Journey's painted map, or null.
var _map: Texture2D
var _chips := {}
var _discs := []
## The number plate's text size as last laid out.
var number_size := 0
## How much of the number plate shows, 0 to 1: on the whole card, to match the Key
## Card's number to; faded out as the Deck zooms in on the panel (specs/014).
var number_alpha := 1.0:
	set(v):
		number_alpha = clampf(v, 0.0, 1.0)
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_creature.held = true
	add_child(_creature)
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
	# A Journey with a painted map (art/painted/journeys/, a preview of the feature 008
	# art) shows it, drawn under the frame, in place of its silhouette.
	var map_path := "res://art/painted/journeys/%s.png" % p.art
	_map = load(map_path) if p.kind == "journey" and p.art != "" and ResourceLoader.exists(map_path) else null
	_creature.visible = p.art != "" and _map == null
	if p.art != "" and _creature.art_name != p.art:
		_creature.setup(p.art, Color(tint.lightened(0.45), 0.55), p.element, false)
	if p.kind == "enemy":
		var e: Dictionary = p.enemy
		_add("hp", {"icon": "hp", "text": str(e.hp), "color": T.HP, "glossary_id": "hp"})
		_add("initiative", {"icon": "initiative", "text": str(e.initiative), "color": T.BG_BAND, "glossary_id": "initiative"})
		_add("attack", {"icon": "attack_badge", "text": str(e.attack.value), "color": T.ether(e.attack.element),
			"ink": T.ether_shade(e.attack.element, "plate_ink"), "element": e.attack.element, "glossary_id": "attack"})
		for i in e.armor.size():
			var a: Dictionary = e.armor[i]
			_add("armor%d" % i, {"icon": "armor", "text": str(a.value), "color": T.ether(a.element),
				"ink": T.ether_shade(a.element, "plate_ink"), "element": a.element, "glossary_id": "armor"})
	else:
		var j: Dictionary = p.journey
		# As printed: a dark mountain in a box of the MP's Ether, and a pale hourglass.
		_add("mp", {"icon": "mp_badge", "text": str(j.mp.value), "color": T.BG_BAND, "backing": T.ether(j.mp.element),
			"element": j.mp.element, "glossary_id": "mp"})
		_add("time", {"icon": "time_badge", "text": str(j.time_penalty), "color": STEEL, "inset": T.BG_BAND, "glossary_id": "time"})
	_add("xp", {"icon": "xp", "text": str(p.xp), "color": T.GOLD, "ink": T.BG_BASE, "glossary_id": "xp"})
	# The Hardship sits nearer the middle, the Encounter's own Ability or Peril at the corner.
	for id in [hardship_id, p.effect]:
		if id != null:
			var disc := _make({"icon": Glossary.entry(id).icon, "text": "", "color": T.INK, "glossary_id": id})
			_discs.append(disc)
	_fit()
	queue_redraw()


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
	var out := {"frame": Rect2(Vector2.ZERO, size)}
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
		var star := h * 0.22
		out["xp"] = Rect2(w - star - h * 0.03, h - star - h * 0.03, star, star)
		var d := h * 0.18
		out["discs"] = Rect2(w - d - h * 0.03, h * 0.03, d, d)
		var n := h * 0.16
		out["number"] = Rect2(out.art.position.x + h * 0.03, h * 0.03, n, n)
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
	_creature.position = art.position
	_creature.size = art.size
	_creature.crop = _crop(art.size)
	var rows: Array = at.badges
	var names := ["hp", "initiative", "attack"] if panel.kind == "enemy" else ["mp", "time"]
	for i in names.size():
		_put(_chips[names[i]], rows[i][0])
	if panel.kind == "enemy":
		for k in armor:
			_put(_chips["armor%d" % k], rows[3][k])
	_put(_chips.xp, at.xp)
	var d: Rect2 = at.discs
	for i in _discs.size():
		# Right to left from the corner: the Encounter's own effect at the corner.
		var k := _discs.size() - 1 - i
		_put(_discs[i], Rect2(d.position - Vector2(k * d.size.x * 1.08, 0), d.size))
	queue_redraw()


func _put(c: Control, r: Rect2) -> void:
	c.position = r.position
	c.size = r.size


## An Enemy is cropped as its face crops it; a landscape is cut to fill its panel.
func _crop(art: Vector2) -> Rect2:
	if panel.art == "":
		return Art.FULL
	if panel.kind == "enemy":
		return load("res://ui/widgets/encounter_face.gd").enemy_crop(panel.art, art)
	var ratio := art.x / maxf(art.y, 1.0)
	var full := Art.FULL
	if ratio < 1.0:
		var w := full.size.y * ratio
		return Rect2(full.get_center().x - w / 2.0, 0, w, full.size.y)
	var h := full.size.x / ratio
	return Rect2(0, full.get_center().y - h / 2.0, full.size.x, h)


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
	draw_rect(at.frame, Color(tint, 0.18))
	if panel.kind == "journey":
		# The printed strip along the top, in the dark of the card's band.
		draw_rect(Rect2(0, 0, size.x, at.art.position.y), Color(T.BG_BAND, 0.92))
		if _map != null:
			draw_texture_rect_region(_map, at.art, cover_region(_map.get_size(), at.art.size))
	draw_rect(at.frame.grow(-edge / 2.0), T.muted(tint), false, edge)
	if number_alpha <= 0.0:
		return
	var n: Rect2 = at.number
	draw_style_box(UI.box(Color(T.BG_BASE, 0.72 * number_alpha), Color.TRANSPARENT, 0, int(n.size.y * 0.2), 0), n)
	var font := UI.font(T.LABEL_BOLD[0])
	number_size = maxi(8, roundi(n.size.y * 0.78))
	var text := str(panel.index)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
	var base := n.get_center().y + (font.get_ascent(number_size) - font.get_descent(number_size)) / 2.0
	draw_string(font, Vector2(n.get_center().x - tw / 2.0, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color(T.INK, number_alpha))
