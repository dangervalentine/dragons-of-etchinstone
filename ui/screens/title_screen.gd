extends Control
## The landing page: the game's name cut into a lintel of stone, the story in a
## line, and the ways in: How to Play, Records and Play, with Settings, the
## Glossary and the fan-made notice beneath. Play leads on to the choice of dragon
## (dragon_screen.gd). A flat woodcut tear, The Tear of the story, sits faint behind.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const Flavor = preload("res://ui/model/flavor.gd")

signal intent(data: Dictionary)

## The widest the column grows, so it stays a column on wide screens.
const COLUMN_MAX := 720.0

var db
var options := {}
## No choices are made here; kept empty for the checks that read every screen's tiles.
var _tiles := {}
var _layout := Control.new()
var _column: VBoxContainer
var _content := Rect2(16, 16, 1248, 688)


func setup(card_db, opts: Dictionary) -> void:
	db = card_db
	options = opts.duplicate()
	_build()


func apply_layout(content: Rect2) -> void:
	_content = content
	_layout.position = content.position
	_layout.size = content.size
	if _column != null:
		_column.custom_minimum_size.x = minf(COLUMN_MAX, content.size.x)


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_layout = Control.new()
	add_child(_layout)
	# The Tear: drawn flat and faint behind, never lit or moving.
	var tear := UI.icon_rect("orn_rift", 10, Color(T.muted(T.GOLD), 0.12))
	tear.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tear.custom_minimum_size = Vector2.ZERO
	_layout.add_child(tear)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(centre)
	_column = UI.vbox(T.M)
	centre.add_child(_column)

	var lintel := PanelContainer.new()
	var stone := StoneStyle.new("lintel", 0.4)
	stone.edge = T.GOLD
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		stone.set_content_margin(side, T.M)
	for side in [SIDE_TOP, SIDE_BOTTOM]:
		stone.set_content_margin(side, T.S)
	lintel.add_theme_stylebox_override("panel", stone)
	var name := UI.carved_label("DRAGONS OF\nETCHINSTONE", ["display_bold", 50], T.GOLD)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lintel.add_child(name)
	_column.add_child(lintel)
	var subtitle := UI.label(Flavor.subtitle(), T.BODY, T.INK, true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(subtitle)

	# The three ways in, side by side, Play the widest and last, where Continue
	# sits on the setup steps after it.
	var ways := UI.hbox(T.S)
	var learn := UI.button("How to Play", "normal", "book")
	learn.pressed.connect(func(): intent.emit({"type": "rulebook"}))
	var records := UI.button("Records", "normal", "trophy")
	records.pressed.connect(func(): intent.emit({"type": "records", "from": "title"}))
	var play := UI.button("Play", "primary")
	play.pressed.connect(_play)
	for b in [learn, records, play]:
		b.custom_minimum_size.y = T.TAP_MIN
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ways.add_child(b)
	play.size_flags_stretch_ratio = 1.3
	_column.add_child(ways)

	# Settings and the Glossary, small and quiet so they do not compete with the three.
	var tools := UI.hbox(T.S)
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	var settings := UI.button("Settings", "quiet", "settings")
	settings.pressed.connect(func(): intent.emit({"type": "settings"}))
	var help := UI.button("Glossary", "quiet", "help")
	help.pressed.connect(func(): intent.emit({"type": "glossary"}))
	for b in [settings, help]:
		b.custom_minimum_size = Vector2(180, T.TAP_MIN)
		tools.add_child(b)
	_column.add_child(tools)
	var notice := UI.label("Fan-made digital version. Game by Joe Klipfel, published by Chip Theory Games. Not affiliated with or endorsed by Chip Theory Games. Creature and landscape art made for this project.", T.LABEL, T.INK_MUTED, true)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(notice)
	apply_layout(_content)
	play.grab_focus.call_deferred()


## Play opens the choice of dragon with none chosen; the difficulty and rules
## from last time stay.
func _play() -> void:
	var o := options.duplicate()
	o.dragon = ""
	intent.emit({"type": "setup_dragon", "options": o})
