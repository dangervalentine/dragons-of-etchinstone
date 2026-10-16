extends "res://ui/widgets/face_frame.gd"
## The face of the current Region Encounter: what the Key Card asks for.
## An enemy shows HP, Initiative, Attack and Armor; a Journey shows MP and its Time
## Penalty; either may carry a Hardship, an Ability or a Peril.

const StatChip = preload("res://ui/widgets/stat_chip.gd")
const Glossary = preload("res://ui/model/glossary.gd")

signal intent(data: Dictionary)

## The pale grey of the printed hourglass.
const STEEL := Color("aaa6b8")

var _shown := {}
var _enemy := false

## Room left around an enemy's figure when it fills the panel, in its 512 units.
const ENEMY_PAD := 10.0
## Each figure's outline in its 512 units, measured once from its art.
static var _bounds := {}


func render(enc: Dictionary) -> void:
	if enc == _shown:
		return
	_shown = enc.duplicate(true)
	clear()
	var enemy: bool = enc.kind == "enemy"
	_enemy = enemy
	var d: Dictionary = enc.data
	set_look(enc.element, "sigil_" + str(enc.element), enc.get("art", ""))

	band.add_child(UI.icon_rect("enemy" if enemy else "journey", 34, T.ether_ink(enc.element)))
	# Long names step down a size so they fit the band.
	var text: String = enc.title.to_upper()
	var room := (size.x if size.x > 0.0 else 400.0) - 80.0
	var fs: int = T.HEADING[1]
	while fs > T.TEXT_MIN and UI.font(T.HEADING[0]).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		fs -= 1
	var title := UI.label(text, [T.HEADING[0], fs], T.INK)
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	band.add_child(title)

	# As printed: the figures in a column of shaped badges down the left, the art in
	# a framed panel beside them, XP on the panel's corner and any Hardship, Ability
	# or Peril on its top edge.
	var row := UI.hbox(T.M)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_column = UI.vbox(T.XS)
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	if enemy:
		_column.add_child(_chip({"icon": "hp", "text": str(d.hp), "color": T.HP, "glossary_id": "hp"}))
		_column.add_child(_chip({"icon": "initiative", "text": str(d.initiative), "color": T.BG_BAND, "glossary_id": "initiative"}))
		_column.add_child(_chip({"icon": "attack_badge", "text": str(d.attack.value), "color": T.ether(d.attack.element),
			"ink": T.ether_shade(d.attack.element, "plate_ink"), "element": d.attack.element, "glossary_id": "attack"}))
		var shields := UI.hbox(T.XS)
		for a in d.armor:
			shields.add_child(_chip({"icon": "armor", "text": str(a.value), "color": T.ether(a.element),
				"ink": T.ether_shade(a.element, "plate_ink"), "element": a.element, "glossary_id": "armor"}))
		_column.add_child(shields)
	else:
		# As printed: a dark mountain in a box of the MP's Ether, and a pale hourglass.
		_column.add_child(_chip({"icon": "mp_badge", "text": str(d.mp.value), "color": T.BG_BAND, "backing": T.ether(d.mp.element),
			"element": d.mp.element, "glossary_id": "mp"}))
		_column.add_child(_chip({"icon": "time_badge", "text": str(d.time_penalty), "color": STEEL, "inset": T.BG_BAND,
			"glossary_id": "time"}))
	row.add_child(_column)
	_art_slot = Control.new()
	_art_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_slot.resized.connect(_place_art)
	_xp = _chip({"icon": "xp", "text": str(d.xp), "color": T.GOLD, "ink": T.BG_BASE, "glossary_id": "xp"})
	_art_slot.add_child(_xp)
	_effects.clear()
	for effect in enc.effects:
		var e: Dictionary = Glossary.entry(effect)
		var disc := _chip({"icon": e.icon, "text": "", "color": T.INK, "glossary_id": effect})
		_art_slot.add_child(disc)
		_effects.append(disc)
	row.add_child(_art_slot)
	body.add_child(row)

	var key: Dictionary = enc.key_card
	var caption := UI.label("%s · Key Card %s, Level %d" % [enc.subtitle, key.name, key.level], T.LABEL, Color(T.INK, 0.8))
	caption.clip_text = true
	body.add_child(caption)
	_fit()


var _column: VBoxContainer
var _art_slot: Control
var _xp: Control
var _effects := []
var _art_rect := Rect2()


func _init() -> void:
	super._init()
	_edge.draw.connect(_draw_art_frame)


## Sizes the badges to the face: as large as the column's height allows.
func _fit() -> void:
	super._fit()
	if _column == null or not is_instance_valid(_column):
		return
	var rows := _column.get_child_count()
	var room := body.size.y - 36.0 - T.XS * (rows - 1)
	var b := clampf(room / maxf(1.0, rows), 52.0, 84.0)
	for c in _column.get_children():
		if c is HBoxContainer:
			for shield in c.get_children():
				shield.custom_minimum_size = Vector2(b * 0.92, b * 0.92)
		else:
			c.custom_minimum_size = Vector2(b, b)
	_place_art.call_deferred()


## The part of an enemy's art that fills a panel of `panel` size: the figure's full
## width (with a little room) from just above its top down, as far as the panel's
## shape allows, so its feet run off the bottom. Centred on the figure.
static func enemy_crop(name: String, panel: Vector2) -> Rect2:
	var b := figure_bounds(name).grow(ENEMY_PAD)
	var w := b.size.x
	var h := w * panel.y / maxf(panel.x, 1.0)
	# A figure taller than wide keeps the panel's shape by widening, centred.
	if h > b.size.y:
		h = b.size.y
		w = h * panel.x / maxf(panel.y, 1.0)
	return Rect2(b.get_center().x - w / 2.0, b.position.y, w, h)


## Where a figure's art is drawn within its 512-unit square: the box round every
## pixel that is not see-through. Measured once per art and kept.
static func figure_bounds(name: String) -> Rect2:
	if _bounds.has(name):
		return _bounds[name]
	var full := Art.FULL
	var tex: Texture2D = UI.art(name)
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty():
		_bounds[name] = full
		return full
	if img.is_compressed():
		img.decompress()
	var lo := Vector2i(img.get_width(), img.get_height())
	var hi := Vector2i(-1, -1)
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			if img.get_pixel(x, y).a > 0.2:
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	if hi.x < 0:
		_bounds[name] = full
		return full
	var k := full.size.x / img.get_width()
	var r := Rect2(Vector2(lo) * k, Vector2(hi - lo) * k)
	_bounds[name] = r
	return r


## The art fills the panel beside the badges; XP and the effect discs sit on its
## corners and top edge.
func _place_art() -> void:
	if _art_slot == null or not is_instance_valid(_art_slot) or _art_slot.size.x <= 0.0:
		return
	_art_rect = Rect2(_art_slot.global_position - global_position, _art_slot.size).grow(-2)
	# Only the art panel carries the Ether pattern; the badges sit on the dark face.
	_field.position = _art_rect.position
	_field.size = _art_rect.size
	_field.material.set_shader_parameter("size", _art_rect.size)
	if art != "" and _enemy:
		# An enemy fills the panel's width: the art is cropped from the top of the
		# figure down, as wide as the figure, and its feet run off the bottom.
		_creature.position = _art_rect.position
		_creature.size = _art_rect.size
		_creature.crop = enemy_crop(art, _art_rect.size)
	elif art != "":
		var a := minf(_art_rect.size.x, _art_rect.size.y) * 0.96
		_creature.size = Vector2(a, a)
		_creature.position = Vector2(_art_rect.end.x - a - 4, _art_rect.end.y - a - 2)
	var x := minf(84.0, _art_rect.size.y * 0.32)
	_xp.custom_minimum_size = Vector2(x, x)
	_xp.size = Vector2(x, x)
	_xp.position = _art_slot.size - Vector2(x * 0.92, x * 0.86)
	var e := 52.0
	for i in _effects.size():
		_effects[i].custom_minimum_size = Vector2(e, e)
		_effects[i].size = Vector2(e, e)
		_effects[i].position = Vector2(T.S + i * (e + T.XS), T.S)
	_edge.queue_redraw()


func _draw_art_frame() -> void:
	if _art_rect.size.x <= 0.0 or _column == null or not is_instance_valid(_column):
		return
	var s := StyleBoxFlat.new()
	s.draw_center = false
	s.border_color = Color(T.INK, 0.35)
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	_edge.draw_style_box(s, _art_rect.grow(1))


func _chip(opts: Dictionary) -> Control:
	var c: Control = StatChip.make(opts)
	c.help.connect(func(id, source): intent.emit({"type": "help", "id": id, "source": source}))
	return c
