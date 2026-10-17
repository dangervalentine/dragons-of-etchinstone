extends Control
## The first setup step: choose a dragon. Four cards show each dragon's head, name,
## title and a line of flavour; beside them, on a card as tall as theirs, the
## chosen dragon stands whole and moving over its figures, the only ones shown, so
## one dragon is read at a time, each figure explaining itself on hover. The page
## opens with none chosen and the card empty; Continue, to the difficulty and
## alternate rules, waits for a choice. Back returns to the landing page.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Art = preload("res://ui/model/art.gd")
const Creature = preload("res://ui/fx/creature.gd")
const DragonStats = preload("res://ui/widgets/dragon_stats.gd")
const Flavor = preload("res://ui/model/flavor.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const FIELD_SHADER = preload("res://ui/fx/shaders/ether_field.gdshader")
## How strongly the Ether field shows behind the chosen dragon: faint, so the dragon
## reads first.
const FIELD_ALPHA := 0.35

signal intent(data: Dictionary)

## The cards' order, top to bottom and left to right, by each dragon's Ether.
const ETHER_ORDER := ["fire", "lightning", "water", "shadow"]

var db
var options := {}
var _tiles := {}
## The chosen dragon's figures, rebuilt with the side on each choice.
var stats: Control
## The chosen dragon: its crest, name, title and figures.
var _side: VBoxContainer
var _card: PanelContainer
var _name: Label
var _next: Button
var _layout := Control.new()
var _content := Rect2(16, 16, 1248, 688)


func setup(card_db, opts: Dictionary) -> void:
	db = card_db
	options = opts.duplicate()
	if not db.dragon_ids().has(options.get("dragon", "")):
		options.dragon = ""
	_build()


func apply_layout(content: Rect2) -> void:
	_content = content
	_layout.position = content.position
	_layout.size = content.size


## Back to the landing page, keeping the dragon chosen.
func back() -> void:
	intent.emit({"type": "to_title", "options": options.duplicate()})


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tiles = {}
	_layout = Control.new()
	add_child(_layout)
	apply_layout(_content)
	var root := UI.vbox(T.S)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(root)
	root.add_child(UI.label("HUNT A DRAGON", ["display", 24], T.GOLD))
	var row := UI.hbox(T.S)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	# Left: the chosen dragon on a card as tall as the four beside it.
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 380
	card.size_flags_stretch_ratio = 0.6
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(card)
	_card = card
	_side = UI.vbox(T.XS)
	card.add_child(_side)
	_fill_side()

	# Right: the four dragons.
	var dragons := GridContainer.new()
	dragons.columns = 2
	dragons.add_theme_constant_override("h_separation", T.S)
	dragons.add_theme_constant_override("v_separation", T.S)
	dragons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dragons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for id in ordered_ids():
		var d: Dictionary = db.dragon(id)
		var art := Art.dragon(id)
		var line := Flavor.line(id)
		var flavour: Control = UI.label(line, T.LABEL, T.INK_MUTED, true) if line != "" else null
		# The head alone, still; the whole of the chosen one moves on the card beside.
		var tile: Button = ChoiceTile.make(d.name, d.title, UI.art_crop(Art.head_art(art), Art.head(art)), T.ether(d.early_damage.element), null, 80.0, flavour)
		tile.custom_minimum_size.y = 160
		tile.tooltip_text = DragonStats.ladder_text(d)
		tile.pressed.connect(_choose.bind(id))
		dragons.add_child(tile)
		_tiles["dragon:" + id] = tile
	row.add_child(dragons)

	# Back at the screen's bottom left and Continue at its right, where the next
	# step keeps Back and Set out.
	var bottom := UI.hbox(T.S)
	bottom.custom_minimum_size.y = T.TAP_MIN
	var back_button := UI.button("Back", "normal")
	back_button.custom_minimum_size.x = 200
	back_button.pressed.connect(back)
	bottom.add_child(back_button)
	bottom.add_child(UI.spacer())
	_next = UI.button("Continue", "primary")
	_next.custom_minimum_size.x = 240
	_next.pressed.connect(func(): intent.emit({"type": "setup_rules", "options": options.duplicate()}))
	bottom.add_child(_next)
	root.add_child(bottom)
	_refresh()
	# With none chosen no card takes focus, so none looks chosen; the first arrow
	# or Tab press focuses the first card.
	if options.dragon != "":
		_tiles["dragon:" + options.dragon].grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if get_viewport().gui_get_focus_owner() != null:
		return
	for action in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_focus_next", "ui_focus_prev"]:
		if event.is_action_pressed(action):
			_tiles["dragon:" + ordered_ids()[0]].grab_focus()
			get_viewport().set_input_as_handled()
			return


## The dragons by their Ether: Fire, Lightning, Water, Shadow.
func ordered_ids() -> Array:
	var ids: Array = db.dragon_ids().duplicate()
	ids.sort_custom(func(a, b): return _rank(a) < _rank(b))
	return ids


func _rank(id: String) -> int:
	var at := ETHER_ORDER.find(db.dragon(id).early_damage.element)
	return at if at >= 0 else ETHER_ORDER.size()


## The chosen dragon whole and moving, filling the card above its name, title and
## figures, which sit at the foot where the cards beside it end.
func _fill_side() -> void:
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	stats = null
	_name = null
	if options.dragon == "":
		_fill_empty()
		return
	var d: Dictionary = db.dragon(options.dragon)
	var ether: String = d.early_damage.element
	var stone := StoneStyle.new("plinth", 0.35)
	stone.edge = T.muted(T.ether(ether))
	stone.edge_width = 2.0
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		stone.set_content_margin(side, T.S)
	_card.add_theme_stylebox_override("panel", stone)
	# The dragon stands over a faint field of its Ether, the moving woodcut the
	# Encounters stand on.
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(120, 120)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side.add_child(stage)
	var field := ColorRect.new()
	field.material = ShaderMaterial.new()
	field.material.shader = FIELD_SHADER
	field.material.set_shader_parameter("tint", T.ether(ether))
	field.material.set_shader_parameter("ether", T.ETHER_ID.get(ether, -1))
	field.material.set_shader_parameter("motion", 0.0 if UI.reduced_motion else 1.0)
	field.modulate.a = FIELD_ALPHA
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.resized.connect(func(): field.material.set_shader_parameter("size", field.size))
	stage.add_child(field)
	var crest := Creature.new()
	crest.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	crest.setup(Art.dragon(options.dragon), T.ether(ether).lightened(0.15), ether)
	stage.add_child(crest)
	_name = UI.label(d.name.to_upper(), ["display_bold", 40], T.GOLD)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side.add_child(_name)
	var title := UI.label(d.title, T.BODY, T.INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side.add_child(title)
	stats = DragonStats.make(d, true)
	# Held in from the card's edge, clear of the stone's rail.
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_left", T.S)
	inset.add_theme_constant_override("margin_right", T.S)
	inset.add_child(stats)
	_side.add_child(inset)


## Before any choice: the card stands empty, a prompt at its middle.
func _fill_empty() -> void:
	var stone := StoneStyle.new("plinth", 0.6)
	stone.edge = Color(0, 0, 0, 0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		stone.set_content_margin(side, T.S)
	_card.add_theme_stylebox_override("panel", stone)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.add_child(gap)
	var hint := UI.label("Choose a dragon", ["display", 28], T.INK_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side.add_child(hint)
	var more := UI.label("Its Armor, Initiative and the tiers of the Final Battle show here.", T.LABEL, Color(T.INK_MUTED, 0.8), true)
	more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side.add_child(more)
	var below := Control.new()
	below.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.add_child(below)


## Choosing a card changes only the marks and the side, so focus stays on the card.
func _choose(id: String) -> void:
	if id == options.dragon:
		return
	options.dragon = id
	_refresh()
	_fill_side()


func _refresh() -> void:
	for id in db.dragon_ids():
		_tiles["dragon:" + id].selected = options.dragon == id
	_next.disabled = options.dragon == ""
