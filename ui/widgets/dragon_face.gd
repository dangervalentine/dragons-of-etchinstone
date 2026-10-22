extends "res://ui/widgets/face_frame.gd"
## The dragon in the Final Battle. On the Final Journey only the road to its lair
## shows (art/painted/roads/), the ladder of Move totals and the Time Penalty each
## leaves laid over it. When the Final Enemy begins the road gives way to the lair
## and the dragon comes up whole in its upper half, its battle figures and the ladder
## of Attack totals laid over the lower.

const StatChip = preload("res://ui/widgets/stat_chip.gd")
const DragonStats = preload("res://ui/widgets/dragon_stats.gd")

signal intent(data: Dictionary)

## How far the figures may grow past their own size to fill their room.
const GROW_MAX := 1.8
## How much taller than their figures the rungs may stretch into spare height.
const RUNG_STRETCH := 1.6
const CROSSING := 0.9
## The smallest the band's name and title step down to.
const NAME_MIN := 16
## How far the figures keep in from the face's sides.
const INSET := 2 * T.M
## How strongly the silhouette road shows in battle, where there is no painted one.
const FAINT := 0.35

var _shown := {}
var _kind := ""
var _rungs: Array = []
var _reached := -2
var _stage := Control.new()
var _scene := Control.new()
var _road := Creature.new()
var _beast := Creature.new()
## Painted behind the whole field: the road to this dragon's lair on the Final Journey
## (art/painted/roads/), and the lair itself once the dragon is faced
## (art/painted/lairs/, the Dragon Card's). Where there is no road picture the
## silhouette road stands in.
var _approach := _backdrop_rect()
var _lair := _backdrop_rect()
var _panel := VBoxContainer.new()
## The lines the panel can do without, in the order they go when it runs short.
var _spare: Array = []
var _room := INF
var _scale := 1.0
var _tween: Tween


func _init() -> void:
	super._init()
	# Over the Ether pattern, under everything drawn on the face.
	for b in [_lair, _approach]:
		add_child(b)
		move_child(b, _field.get_index() + 1)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene.add_child(_road)
	_scene.add_child(_beast)
	_stage.add_child(_scene)
	_panel.add_theme_constant_override("separation", 6)
	_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_stage.add_child(_panel)
	_panel.sort_children.connect(_trim)
	_stage.resized.connect(func(): _place(false))


func render(enc: Dictionary) -> void:
	if enc == _shown:
		return
	var crossing: bool = _kind == "final_journey" and enc.kind != "final_journey" and is_inside_tree()
	_shown = enc.duplicate(true)
	_reached = -2
	_build(enc)
	_place(crossing and not UI.reduced_motion)


## Light every rung the current Action Sets reach, since reaching one tier meets
## the easier ones too; -1 for none.
func set_reached(tier: int) -> void:
	if tier == _reached:
		return
	_reached = tier
	for i in _rungs.size():
		var on: bool = i <= tier
		var rung: PanelContainer = _rungs[i]
		var box := UI.box(Color(T.GOLD, 0.92) if on else Color(T.BG_BAND, 0.85),
			T.GOLD if on else Color(T.INK, 0.25), 2 if on else 1, T.RADIUS_S, 4 if _kind == "final_journey" else 2)
		# Room inside each end of the rung, so its figures keep off its edge.
		box.content_margin_left = T.M
		box.content_margin_right = T.M
		rung.add_theme_stylebox_override("panel", box)
		for l in rung.find_children("*", "Label", true, false):
			l.add_theme_color_override("font_color", T.BG_BASE if on else T.INK)
		for t in rung.find_children("*", "TextureRect", true, false):
			if not t.has_meta("keep_colour"):
				t.modulate = T.BG_BASE if on else T.INK


func _build(enc: Dictionary) -> void:
	var d: Dictionary = enc.dragon
	var journey: bool = enc.kind == "final_journey"
	var colour: Color = T.ether(enc.element)
	var first := _kind == ""
	_kind = enc.kind
	if first or band.get_child_count() == 0:
		clear()
		set_look(enc.element)
		# The name over the dragon's title, centred between its sigil at each end; both
		# step down in size to fit a long name or title (_fit_names).
		band.add_child(UI.icon_rect("sigil_" + d.id, 44, T.ether_ink(enc.element)))
		var names := UI.vbox(-8)
		names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		names.alignment = BoxContainer.ALIGNMENT_CENTER
		for line in [[d.name.to_upper(), T.SUBHEAD, T.INK], [d.title, T.LABEL, T.INK_MUTED]]:
			var l := UI.label(line[0], line[1], line[2])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.clip_text = true
			l.set_meta("base_font", line[1][1])
			names.add_child(l)
		names.resized.connect(_fit_names.bind(names))
		band.add_child(names)
		band.add_child(UI.icon_rect("sigil_" + d.id, 44, T.ether_ink(enc.element)))
		body.add_child(_stage)
		_road.setup(enc.scene, Color(colour.lightened(0.75), 1.0), "", false)
		# The full-body picture, whole and uncut (the ending screen's).
		var whole: String = enc.art + "-full"
		_beast.setup(whole if UI.is_painted(whole) else enc.art, Color(colour.lightened(0.4), 0.9), enc.element, false)
		_approach.texture = UI.painted("roads/" + enc.art)
		_lair.texture = UI.painted("lairs/" + enc.art)
	_road.visible = _approach.texture == null

	for c in _panel.get_children():
		_panel.remove_child(c)
		c.queue_free()
	_rungs = []
	_spare = []
	# The battle shares the column with a taller math box: its lines sit closer.
	_panel.add_theme_constant_override("separation", 6 if journey else 3)
	if journey:
		var intro := UI.label("THE FINAL JOURNEY", T.EYEBROW, T.GOLD)
		intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_panel.add_child(intro)
		var how := UI.label("Add the Move of both sets. Each tier reached costs less time.", T.LABEL, T.INK, true)
		how.custom_minimum_size.x = 200
		how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_panel.add_child(how)
		_spare = [how]
	else:
		var eyebrow := UI.label("THE FINAL ENEMY", T.EYEBROW, T.GOLD)
		eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_panel.add_child(eyebrow)
		# One row of figures, named once underneath; each explains itself when pressed.
		var stats := HFlowContainer.new()
		stats.alignment = FlowContainer.ALIGNMENT_CENTER
		stats.add_theme_constant_override("h_separation", T.M)
		stats.add_theme_constant_override("v_separation", 2)
		stats.add_child(_chip({"icon": "initiative", "text": str(d.initiative), "color": T.BG_BAND,
			"glossary_id": "initiative", "min_size": Vector2(44, 44)}))
		# The Early Damage as printed: its number on the Attack badge in its Ether's
		# colour, the Ether's sigil on the badge's corner.
		var ed: Dictionary = d.early_damage
		stats.add_child(_chip({"icon": "attack_badge", "text": str(ed.value), "color": T.ether(ed.element),
			"ink": T.ether_shade(ed.element, "plate_ink"), "element": ed.element, "glossary_id": "early_damage",
			"min_size": Vector2(44, 44)}))
		for a in d.armor:
			stats.add_child(_chip({"icon": "armor", "text": str(a.value), "color": T.ether(a.element), "ink": T.ether_shade(a.element, "plate_ink"),
				"element": a.element, "glossary_id": "armor", "min_size": Vector2(44, 44)}))
		_panel.add_child(stats)
		var names := "Initiative · early · Armor"
		if enc.carried_damage > 0:
			names += " · %d carried" % enc.carried_damage
		var caption := UI.label(names, T.LABEL, T.INK, true)
		caption.custom_minimum_size.x = 200
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_panel.add_child(caption)
		# The chips explain themselves when pressed, and the band names the dragon.
		_spare = [caption, eyebrow]
	var tiers: Array = d.mp_tiers if journey else d.hp_tiers
	var rows := []
	for i in tiers.size():
		rows.append(_rung(tiers[i], journey, enc.element))
	# The journey ladder runs from the easiest Move down to the hardest; the
	# battle ladder puts the hardest Attack on top.
	if not journey:
		rows.reverse()
	for r in rows:
		_panel.add_child(r)
	# The lines laid straight on the painted road or lair, edged dark so a pale sky
	# never swallows them; the rungs carry their own dark boxes.
	for c in _panel.get_children():
		if c is Label:
			c.add_theme_color_override("font_outline_color", Color(T.BG_BASE, 0.9))
			c.add_theme_constant_override("outline_size", 8)
	# Every size in the panel as built, for _grow() to scale from.
	for c in _sized(_panel):
		c.set_meta("base_min", c.custom_minimum_size)
		if c is Label:
			c.set_meta("base_font", c.get_theme_font_size("font_size"))
	_scale = 1.0
	set_reached(-1)


## Each line of the band's name and title at its own size, or smaller until it fits
## across, down to NAME_MIN.
func _fit_names(names: Control) -> void:
	for l in names.get_children():
		var font: Font = l.get_theme_font("font")
		var fs: int = l.get_meta("base_font")
		while fs > NAME_MIN and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > names.size.x:
			fs -= 1
		l.add_theme_font_size_override("font_size", fs)


## The figures in the panel that carry a size of their own: the row of figures and
## the rungs, with their labels and icons, but not the parts a figure draws for
## itself. The panel's lines of text keep their size.
func _sized(root: Control) -> Array:
	var out := []
	for c in root.get_children():
		if not c is Control or (root == _panel and c is Label):
			continue
		if c is Label or c is TextureRect or c is StatChip or c is PanelContainer:
			out.append(c)
		if not c is StatChip:
			out.append_array(_sized(c))
	return out


## Scale every figure in the panel by `s` from its size as built.
func _grow(s: float) -> void:
	if is_equal_approx(s, _scale):
		return
	_scale = s
	for c in _sized(_panel):
		if c.has_meta("base_min"):
			c.custom_minimum_size = (c.get_meta("base_min") * s).round()
		if c.has_meta("base_font"):
			c.add_theme_font_size_override("font_size", roundi(c.get_meta("base_font") * s))


## The figures grow, together, as far as `room` holds them across and down (to
## GROW_MAX); any height still spare goes to the rungs, up to RUNG_STRETCH times
## their own. The panel then centres it all in the room.
func _fill(room: Rect2) -> void:
	var s := GROW_MAX
	for c in _spare:
		c.visible = true
	while s > 1.0:
		_grow(s)
		if _panel.get_combined_minimum_size().x <= room.size.x and UI.stack_height(_panel, room.size.x) <= room.size.y:
			break
		s = maxf(1.0, s - 0.05)
	_grow(s)
	if _rungs.is_empty():
		return
	var spare := room.size.y - UI.stack_height(_panel, room.size.x)
	var rung_h: float = _rungs[0].custom_minimum_size.y
	var extra := clampf(spare / _rungs.size(), 0.0, rung_h * (RUNG_STRETCH - 1.0))
	for r in _rungs:
		r.custom_minimum_size.y = roundf(rung_h + extra)


## Lay out the picture and the figures; `crossing` animates the turn from the road to
## the dragon. The dragon has the top half and the figures lie over the other: the
## Move ladder over the road's sky, with no dragon yet, then the battle figures
## below the dragon once it is faced. The silhouette road, where there is no painted
## one, has the bottom half and fades in battle.
func _place(crossing: bool) -> void:
	var w := _stage.size.x
	var h := _stage.size.y
	if w <= 0:
		return
	var journey := _kind == "final_journey"
	var half := floorf(h / 2.0)
	var top := Rect2(0, 0, w, half)
	var bottom := Rect2(0, half, w, h - half)
	var beast := _square_in(top)
	var road := _square_in(bottom)
	var panel := (top if journey else bottom).grow_individual(-INSET, -T.S, -INSET, -T.S)
	_fill(panel)
	_fit_ladder(panel)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_scene.position = Vector2.ZERO
	_scene.size = Vector2(w, h)
	_road.position = road.position
	_road.size = road.size
	_road.visible = _approach.texture == null
	_beast.position = beast.position
	_beast.size = beast.size
	_beast.crop = Art.FULL
	_panel.size = panel.size
	if not crossing:
		_panel.position = panel.position
		_beast.modulate.a = 0.0 if journey else 1.0
		_road.modulate.a = 1.0 if journey else FAINT
		_approach.modulate.a = 1.0 if journey else 0.0
		_lair.modulate.a = 0.0 if journey else 1.0
		_panel.modulate.a = 1.0
		return
	# The dragon is faced: the figures fade off the road, the road gives way to the
	# lair, the dragon comes up in it, and the battle figures settle below.
	_panel.modulate.a = 0.0
	_panel.position = panel.position
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_beast, "modulate:a", 1.0, CROSSING)
	_tween.tween_property(_road, "modulate:a", FAINT, CROSSING * 0.6)
	# The road gives way to the lair.
	_tween.tween_property(_lair, "modulate:a", 1.0, CROSSING)
	_tween.tween_property(_approach, "modulate:a", 0.0, CROSSING)
	_tween.tween_property(_panel, "modulate:a", 1.0, CROSSING * 0.5).set_delay(CROSSING * 0.6)


## The largest square centred in `r`: the art is square and shown whole.
static func _square_in(r: Rect2) -> Rect2:
	var side := minf(r.size.x, r.size.y)
	return Rect2(r.position + (r.size - Vector2(side, side)) / 2.0, Vector2(side, side))


## On short screens the ladder would run out of the frame; drop the line that
## explains the panel first, since each rung and figure explains itself.
## Wrapped text and figures only know their height once laid out, so this
## checks after each sort of the panel.
func _fit_ladder(panel: Rect2) -> void:
	# The stage can run on under the frame's foot; only what the frame shows counts.
	var shown := size.y - (_stage.global_position.y - global_position.y) - T.M
	_room = minf(panel.size.y, shown) if size.y > 0.0 else panel.size.y
	for c in _spare:
		c.visible = true


func _trim() -> void:
	if _panel.get_child_count() == 0:
		return
	var last: Control = _panel.get_child(-1)
	if last.position.y + last.size.y <= _room:
		return
	for c in _spare:
		if c.visible:
			c.visible = false
			return


func _rung(tier: Dictionary, journey: bool, element: String) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size.y = 36
	var row := UI.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var need: int = tier.mp.value if journey else tier.hp
	var cost: int = tier.time_penalty if journey else tier.attack.value
	row.add_child(UI.icon_rect("move" if journey else "attack", 24))
	row.add_child(UI.label(str(need), T.NUMERAL_S))
	if journey:
		var e := UI.icon_rect(element, 20, T.ether_ink(element))
		e.set_meta("keep_colour", true)
		row.add_child(e)
	var arrow := UI.label("→", T.NUMERAL_S, T.INK)
	arrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(arrow)
	row.add_child(UI.icon_rect("time" if journey else "hp", 24))
	row.add_child(UI.label(str(cost), T.NUMERAL_S))
	# A rung stretched into spare height keeps its figures on its middle.
	for l in row.get_children():
		if l is Label:
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.tooltip_text = DragonStats.rung_text({"need": need, "cost": cost}, journey)
	p.mouse_default_cursor_shape = Control.CURSOR_HELP
	p.add_child(row)
	UI.ignore_mouse(p)
	_rungs.append(p)
	return p


func _chip(opts: Dictionary) -> Control:
	var c: Control = StatChip.make(opts)
	c.help.connect(func(id, source): intent.emit({"type": "help", "id": id, "source": source}))
	return c


static func _backdrop_rect() -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## The painted backdrops cover the field under the band.
func _fit() -> void:
	super._fit()
	var field := Rect2(EDGE, BAND_H, size.x - 2 * EDGE, size.y - BAND_H - EDGE)
	for b in [_approach, _lair]:
		b.position = field.position
		b.size = field.size
