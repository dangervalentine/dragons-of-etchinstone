extends Control
## The first setup step: choose a dragon. Four tiles on the right show each
## dragon's head, name, title and a line of flavour; on the left, as tall as they
## are, lies the chosen dragon's Dragon Card as the Final Battle shows it, the only
## one shown, so one dragon is read at a time, each figure on it explaining itself
## on hover. The page opens with none chosen and an empty place where the card will
## lie; Continue, to the difficulty and alternate rules, waits for a choice. Back
## returns to the landing page.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const ChoiceTile = preload("res://ui/widgets/choice_tile.gd")
const Art = preload("res://ui/model/art.gd")
const DragonCard = preload("res://ui/widgets/dragon_card.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const Flavor = preload("res://ui/model/flavor.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")

signal intent(data: Dictionary)

## The cards' order, top to bottom and left to right, by each dragon's Ether.
const ETHER_ORDER := ["fire", "lightning", "water", "shadow"]

var heading := "Hunt a Dragon"
var db
var options := {}
var _tiles := {}
## The chosen dragon's Dragon Card, rebuilt with the side on each choice.
var card: Control
## Where the card lies: an empty place before a choice, the card after.
var _side: Control
var _card: PanelContainer
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
	var row := UI.hbox(T.S)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	# Left: the chosen dragon's card, as tall as the four tiles beside it.
	var place := PanelContainer.new()
	place.custom_minimum_size.x = 380
	place.size_flags_stretch_ratio = 0.6
	place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(place)
	_card = place
	_side = Control.new()
	_side.resized.connect(_fit_card)
	place.add_child(_side)
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
		# The head alone, still; the whole of the chosen one lies on its card beside.
		var tile: Button = ChoiceTile.make(d.name, d.title, UI.art_crop(Art.head_art(art), Art.head(art, UI.is_painted(Art.head_art(art)))), T.ether(d.early_damage.element), null, 80.0, flavour)
		tile.custom_minimum_size.y = 160
		tile.pressed.connect(_choose.bind(id))
		dragons.add_child(tile)
		_tiles["dragon:" + id] = tile
	row.add_child(dragons)

	# Continue at the screen's bottom right, where the next step keeps Set out. Back
	# is in the title bar.
	var bottom := UI.hbox(T.S)
	bottom.custom_minimum_size.y = T.TAP_MIN
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
		_tiles["dragon:" + options.dragon].grab_focus.call_deferred(true)


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


## The chosen dragon's Dragon Card, as large as the side holds it, centred.
func _fill_side() -> void:
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	card = null
	_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if options.dragon == "":
		_fill_empty()
		return
	card = DragonCard.new()
	card.explain = true
	_side.add_child(card)
	_fit_card()
	card.render(ViewState.dragon_card_model(db.dragon(options.dragon)))


## Before any choice: an empty place the card's shape, a prompt at its middle.
func _fill_empty() -> void:
	var stone := StoneStyle.new("plinth", 0.6)
	stone.edge = Color(0, 0, 0, 0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		stone.set_content_margin(side, T.M)
	var place := PanelContainer.new()
	place.add_theme_stylebox_override("panel", stone)
	_side.add_child(place)
	var prompt := UI.vbox(T.XS)
	prompt.alignment = BoxContainer.ALIGNMENT_CENTER
	place.add_child(prompt)
	var hint := UI.label("Choose a dragon", T.HEADING, T.INK_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_child(hint)
	var more := UI.label("Its Dragon Card, with its Armor, Initiative and the tiers of the Final Battle, shows here.", T.LABEL, Color(T.INK_MUTED, 0.8), true)
	more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_child(more)
	_fit_card()


## The card, or the empty place, at the card's printed shape, as large as fits the
## side, centred in it.
func _fit_card() -> void:
	if _side.get_child_count() == 0:
		return
	var s: Vector2 = DragonCard.card_size(_side.size.x)
	if s.y > _side.size.y:
		s = DragonCard.card_size(_side.size.y * s.x / s.y)
	var c: Control = _side.get_child(0)
	c.size = s
	c.position = ((_side.size - s) / 2.0).round()


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
