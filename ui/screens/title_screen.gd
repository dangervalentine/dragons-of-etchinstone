extends Control
## The landing page: the game's name cut into a lintel of stone and the story in a
## line, and below them the ways in: Play across the column, then Learn to Play
## (the lessons, specs/017), the Leaderboard and the Glossary. How to Play is in the
## menu. It has no title bar, so it takes the whole height; only the menu button
## stands where the bar keeps it (owner, 2026-10-23). Settings and the History are
## in the menu. Play leads on to the choice of dragon (dragon_screen.gd). A flat
## woodcut tear, The Tear of the story, sits faint behind.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const StoneStyle = preload("res://ui/theme/stone_style.gd")
const Flavor = preload("res://ui/model/flavor.gd")
const HeaderBar = preload("res://ui/widgets/header_bar.gd")

signal intent(data: Dictionary)

## The widest the column grows, so it stays a column on wide screens.
const COLUMN_MAX := 720.0

## The title bar's heading: none, as the lintel below carries the name.
var heading := ""
var db
var options := {}
## No choices are made here; kept empty for the checks that read every screen's tiles.
var _tiles := {}
var _layout := Control.new()
var _column: VBoxContainer
var _ways: VBoxContainer
var _content := Rect2(16, 16, 1248, 688)
## The menu, where every other screen's title bar keeps it (place_menu()).
var menu_button: Button
var _menu_at := Rect2()
var _menu_face := Rect2(0, 0, T.TAP_MIN, 44)


func setup(card_db, opts: Dictionary) -> void:
	db = card_db
	options = opts.duplicate()
	_build()


func apply_layout(content: Rect2) -> void:
	_content = content
	_layout.position = content.position
	_layout.size = content.size
	for c in [_column, _ways]:
		if c != null:
			c.custom_minimum_size.x = minf(COLUMN_MAX, content.size.x)


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_layout = Control.new()
	add_child(_layout)
	# The Tear: drawn flat and faint behind, never lit or moving.
	var tear := UI.icon_rect("orn_rift", 10, Color(T.EDGE, 0.12))
	tear.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tear.custom_minimum_size = Vector2.ZERO
	_layout.add_child(tear)
	# The name and story above, the ways in below, with the same space above the
	# one, between the two and below the other.
	var page := UI.vbox(0)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(page)
	_column = UI.vbox(T.SPACE_4)
	_ways = UI.vbox(T.SPACE_4)
	for part in [_column, _ways]:
		page.add_child(_gap())
		part.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		page.add_child(part)
	page.add_child(_gap())

	var lintel := PanelContainer.new()
	var stone := StoneStyle.new("lintel", 0.4)
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		stone.set_content_margin(side, T.SPACE_4)
	lintel.add_theme_stylebox_override("panel", stone)
	var name := UI.carved_label("DRAGONS OF\nETCHINSTONE", T.BANNER, T.BRASS_BRIGHT)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_space_lines(name, stone, T.SPACE_2)
	lintel.add_child(name)
	_column.add_child(lintel)
	var subtitle := UI.label(Flavor.subtitle(), T.BODY, T.PARCHMENT, true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_column.add_child(subtitle)

	# Play across the column, then the other ways in side by side beneath it.
	var play := UI.button("Play", "primary")
	play.custom_minimum_size.y = T.TAP_MIN
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.pressed.connect(_play)
	_ways.add_child(play)
	var ways := UI.hbox(T.SPACE_2)
	var learn := UI.button("Learn to Play", "normal", "book")
	learn.pressed.connect(func(): intent.emit({"type": "lessons"}))
	var board := UI.button("Leaderboard", "normal", "trophy")
	board.pressed.connect(func(): intent.emit({"type": "records", "page": "leaderboard", "from": "title"}))
	var help := UI.button("Glossary", "normal", "glossary")
	help.pressed.connect(func(): intent.emit({"type": "glossary"}))
	for b in [learn, board, help]:
		b.custom_minimum_size.y = T.TAP_MIN
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ways.add_child(b)
	_ways.add_child(ways)
	menu_button = HeaderBar.menu_button_alone()
	menu_button.pressed.connect(func(): intent.emit({"type": "menu"}))
	add_child(menu_button)
	apply_layout(_content)
	place_menu(_menu_at)
	play.grab_focus.call_deferred(true)


## The menu button at `at`, a global rectangle, its slab at `face` on it: where and
## as the title bar keeps them.
func place_menu(at: Rect2, face := Rect2()) -> void:
	_menu_at = at
	if face.size != Vector2.ZERO:
		_menu_face = face
	if menu_button == null or at.size == Vector2.ZERO:
		return
	menu_button.size = at.size
	menu_button.global_position = at.position if is_inside_tree() else at.position - position
	var slab: Control = menu_button.get_node("Face")
	slab.position = _menu_face.position
	slab.size = _menu_face.size


## A stretch of empty height, sharing what the column leaves with the others.
func _gap() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Space the name's two lines so the stone shows the same gap above the capitals,
## between the lines and below them: `gap` past the font's own room above the
## capitals, which the stone's top margin leaves as it is.
func _space_lines(name: Label, stone: StyleBox, gap: float) -> void:
	var font := name.get_theme_font("font")
	var size := name.get_theme_font_size("font_size")
	var above := font.get_ascent(size) - _cap_height(font, size)
	var space := gap + above
	stone.set_content_margin(SIDE_TOP, gap)
	stone.set_content_margin(SIDE_BOTTOM, maxf(0.0, space - font.get_descent(size)))
	name.add_theme_constant_override("line_spacing", roundi(space - font.get_descent(size) - above))


## The height of the font's capitals above the baseline, from the glyph of a D.
func _cap_height(font: Font, size: int) -> float:
	var ts := TextServerManager.get_primary_interface()
	for rid in font.get_rids():
		var glyph := ts.font_get_glyph_index(rid, size, "D".unicode_at(0), 0)
		if glyph != 0:
			return -ts.font_get_glyph_offset(rid, Vector2i(size, 0), glyph).y
	return font.get_ascent(size)


## Play opens the choice of dragon with none chosen; the difficulty and rules
## from last time stay.
func _play() -> void:
	var o := options.duplicate()
	o.dragon = ""
	intent.emit({"type": "setup_dragon", "options": o, "from": "title"})
