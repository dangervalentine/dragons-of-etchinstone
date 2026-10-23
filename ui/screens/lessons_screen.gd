extends Control
## The lesson list (specs/017, contracts/tutorial-flow.md "Lesson list"): the six
## lessons in order, each marked Done once finished. Lessons are played in order the
## first time, so a lesson opens only once the one before it is finished; a finished
## lesson can be played again at any time. Continue starts the first one not yet
## finished. Learn to Play opens here once a lesson is finished; before that it starts
## the first lesson at once.

const T = preload("res://ui/theme/tokens.gd")
const UI = preload("res://ui/theme/theme.gd")
const Settings = preload("res://ui/model/settings.gd")
const Lessons = preload("res://ui/model/lessons.gd")
const Tutorial = preload("res://ui/model/tutorial.gd")

signal intent(data: Dictionary)

const COLUMN_MAX := 820.0

var heading := "Learn to Play"
var db
## For the checks that read every screen's tiles: each lesson's row button, by index.
var _tiles := {}
var continue_button: Button
var _layout := Control.new()
var _column: VBoxContainer
var _content := Rect2(16, 16, 1248, 688)


func setup(card_db, _opts := {}) -> void:
	db = card_db
	_build()


func apply_layout(content: Rect2) -> void:
	_content = content
	_layout.position = content.position
	_layout.size = content.size
	if _column != null:
		_column.custom_minimum_size.x = minf(COLUMN_MAX, content.size.x)


func back() -> void:
	intent.emit({"type": "to_title"})


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tiles = {}
	_layout = Control.new()
	add_child(_layout)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout.add_child(centre)
	_column = UI.vbox(T.SPACE_4)
	centre.add_child(_column)
	# Two columns of three, so the six fit the shortest window with Continue below.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", T.SPACE_2)
	grid.add_theme_constant_override("v_separation", T.SPACE_2)
	_column.add_child(grid)

	var done: Array = Settings.lessons
	var first := Tutorial.first_unfinished(done)
	for i in Lessons.count():
		var l: Dictionary = Lessons.lesson(i)
		var finished := done.has(l.id)
		var open := Tutorial.is_open(i, done)
		# Done in a word and a mark, never colour alone; a lesson not yet open says why.
		var state := "Done" if finished else ("Finish Lesson %d first" % (first + 1) if not open else "Not yet played")
		var b := UI.button("%d. %s" % [i + 1, l.title] + "\n" + state, "normal", "victory" if finished else "")
		UI.align_left(b)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not open
		var index := i
		b.pressed.connect(func(): intent.emit({"type": "lesson", "index": index}))
		grid.add_child(b)
		_tiles["lesson:%d" % i] = b

	var bottom := UI.hbox(T.SPACE_2)
	bottom.add_child(UI.spacer())
	var label := "Start again" if first == -1 else "Continue: Lesson %d" % (first + 1)
	continue_button = UI.button(label, "primary")
	continue_button.custom_minimum_size = Vector2(320, T.TAP_MIN)
	var start := 0 if first == -1 else first
	continue_button.pressed.connect(func(): intent.emit({"type": "lesson", "index": start}))
	bottom.add_child(continue_button)
	_column.add_child(bottom)
	apply_layout(_content)
	continue_button.grab_focus.call_deferred()
