extends Control
## The first setup step: choose a dragon. A table of two rows: the four Dragon
## Cards side by side, as the Final Battle shows them, and under each its line of
## flavour, which stays still when its card is pressed. The player taps a card to
## choose it: the chosen one is edged in its Ether's colour,
## the others dimmed but still read. Each figure on a card explains itself on
## hover. The page opens with none chosen; Continue, to the difficulty and
## alternate rules, waits for a choice. Back returns to the landing page.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const DragonPick = preload("res://ui/widgets/dragon_pick.gd")
const DragonCard = preload("res://ui/widgets/dragon_card.gd")
const ViewState = preload("res://ui/model/view_state.gd")
const Flavor = preload("res://ui/model/flavor.gd")
const Settings = preload("res://ui/model/settings.gd")

signal intent(data: Dictionary)

## The cards' order, left to right, by each dragon's Ether.
const ETHER_ORDER := ["fire", "lightning", "water", "shadow"]
## Lines kept for each dragon's flavour.
const FLAVOUR_LINES := 3
## The table's rules between cells, and its outer border.
const RULE := 2
const TABLE_RADIUS := 8
## How bright the flavour of a dragon not chosen is.
const DIM := Color(0.5, 0.5, 0.55)

var heading := "Hunt a Dragon"
var db
var options := {}
var _tiles := {}
## Each dragon's line of flavour, under its card, by id.
var _flavours := {}
## The chosen dragon's Dragon Card, or null before a choice.
var card: Control
var _next: Button
var _table: GridContainer
var _bottom: Control
var _layout := Control.new()
var _content := Rect2(16, 16, 1248, 688)


func setup(card_db, opts: Dictionary) -> void:
	db = card_db
	options = opts.duplicate()
	if not db.dragon_ids().has(options.get("dragon", "")) or Settings.is_locked(options.dragon):
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
	_flavours = {}
	_layout = Control.new()
	add_child(_layout)
	apply_layout(_content)
	var root := UI.vbox(T.S)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(root)

	# A table: the four cards, each the thing to tap, over their lines of flavour,
	# centred down the screen. The frame shows through the gaps between the cells
	# as the table's rules.
	var frame := PanelContainer.new()
	var rules := UI.box(T.LINE_SOFT, T.LINE_SOFT, RULE, TABLE_RADIUS, RULE)
	frame.add_theme_stylebox_override("panel", rules)
	var table := GridContainer.new()
	table.columns = 4
	table.add_theme_constant_override("h_separation", RULE)
	table.add_theme_constant_override("v_separation", RULE)
	frame.add_child(table)
	root.add_child(UI.spacer())
	root.add_child(frame)
	root.add_child(UI.spacer())
	_layout.resized.connect(_fit_cards)
	_table = table
	var ids := ordered_ids()
	for id in ids:
		var d: Dictionary = db.dragon(id)
		var tile: Button = DragonPick.make(ViewState.dragon_card_model(d), T.ether(d.early_damage.element))
		tile.locked = Settings.is_locked(id)
		tile.pressed.connect(_choose.bind(id))
		table.add_child(_cell(tile, ids.find(id), 0, 0))
		_tiles["dragon:" + id] = tile
	for id in ids:
		# A locked dragon says instead what unlocks it.
		var line := UI.label(Flavor.unlock(id) if Settings.is_locked(id) else Flavor.line(id), T.LABEL, T.INK_MUTED, true)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.custom_minimum_size.y = UI.font(T.LABEL[0]).get_height(T.LABEL[1]) * FLAVOUR_LINES
		table.add_child(_cell(line, ids.find(id), 1, T.S))
		_flavours[id] = line
		# Its height follows its width; the cards make room for it.
		line.resized.connect(_fit_cards)

	# Continue at the screen's bottom right, where the next step keeps Set out. Back
	# is in the title bar.
	var bottom := UI.hbox(T.S)
	_bottom = bottom
	bottom.custom_minimum_size.y = T.TAP_MIN
	bottom.add_child(UI.spacer())
	_next = UI.button("Continue", "primary")
	_next.custom_minimum_size.x = 240
	_next.pressed.connect(func(): intent.emit({"type": "setup_rules", "options": options.duplicate()}))
	bottom.add_child(_next)
	root.add_child(bottom)
	_refresh()
	_fit_cards.call_deferred()
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


## A cell of the table at `column` and `row` holding `content`, held `margin` in
## from its rules; the table's corner cells take its rounding.
func _cell(content: Control, column: int, row: int, margin: int) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var face := UI.box(T.BG_SURFACE, Color.TRANSPARENT, 0, 0, margin)
	var r := TABLE_RADIUS - RULE
	face.corner_radius_top_left = r if row == 0 and column == 0 else 0
	face.corner_radius_top_right = r if row == 0 and column == 3 else 0
	face.corner_radius_bottom_left = r if row == 1 and column == 0 else 0
	face.corner_radius_bottom_right = r if row == 1 and column == 3 else 0
	cell.add_theme_stylebox_override("panel", face)
	cell.add_child(content)
	return cell


## The row of cards as tall as a card at the table's column width, or as the
## screen leaves room for under it, beside the flavour and Continue.
func _fit_cards() -> void:
	if _table == null or not is_instance_valid(_table):
		return
	# Measured on the layout, which keeps its size, not on the column, which grows
	# when the cards outgrow it.
	var cols := float(_table.columns)
	var width := (_layout.size.x - (cols + 1.0) * RULE) / cols - 2.0 * DragonPick.GLOW
	var lines := 0.0
	for line in _flavours.values():
		lines = maxf(lines, line.get_combined_minimum_size().y)
	var room := _layout.size.y - _bottom.custom_minimum_size.y - lines - 2.0 * T.S - 3.0 * RULE - 3.0 * T.S
	var h := minf(DragonCard.card_size(maxf(1.0, width)).y + 2.0 * DragonPick.GLOW, room)
	for tile in _tiles.values():
		tile.custom_minimum_size.y = maxf(tile.get_minimum_size().y, floorf(h))


## The dragons by their Ether: Fire, Lightning, Water, Shadow.
func ordered_ids() -> Array:
	var ids: Array = db.dragon_ids().duplicate()
	ids.sort_custom(func(a, b): return _rank(a) < _rank(b))
	return ids


func _rank(id: String) -> int:
	var at := ETHER_ORDER.find(db.dragon(id).early_damage.element)
	return at if at >= 0 else ETHER_ORDER.size()


## Choosing a card changes only the marks, so focus stays on the card.
func _choose(id: String) -> void:
	if Settings.is_locked(id):
		return
	if id == options.dragon:
		return
	options.dragon = id
	_refresh()


func _refresh() -> void:
	var chosen: bool = options.dragon != ""
	for id in db.dragon_ids():
		var tile = _tiles["dragon:" + id]
		tile.selected = options.dragon == id
		tile.any_chosen = chosen
		var line: Label = _flavours[id]
		line.add_theme_color_override("font_color", T.INK if options.dragon == id else T.INK_MUTED)
		line.modulate = Color.WHITE if options.dragon == id or not chosen else DIM
	card = _tiles["dragon:" + options.dragon].card if chosen else null
	_next.disabled = not chosen
