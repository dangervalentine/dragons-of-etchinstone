extends RefCounted
## One run through a lesson (specs/017, research R4, data-model.md "Tutorial"): which
## step is shown, how far Back may go, and whether a move the player commits is the
## one the lesson guides. Pure: main asks it before every commit and tells it what
## happened after.

const Lessons = preload("res://ui/model/lessons.gd")

const NOT_IN_LESSON := "Not in this lesson."

var lesson: Dictionary
var index := 0
## The lowest step Back can return to: the one after the last move made, since a move
## in the game cannot be taken back.
var floor_index := 0


func _init(lesson_dict: Dictionary) -> void:
	lesson = lesson_dict


func step() -> Dictionary:
	return lesson.steps[index] if index < lesson.steps.size() else {}


func reading() -> bool:
	return step().get("wait", "") == "next"


func waiting_for(kind: String) -> bool:
	return step().get("wait", "") == kind


func next() -> void:
	if reading():
		index += 1


func back() -> void:
	if can_back():
		index -= 1


func can_back() -> bool:
	return index > floor_index


func finished() -> bool:
	return index >= lesson.steps.size()


## "" when the move is the one this step guides; otherwise what to say instead.
## kind: dragon, setup, play, soak, upgrade, divert, fuse_begin or fuse_element.
func check(kind: String, payload = null) -> String:
	var s := step()
	if s.get("wait", "") != kind:
		if kind == "divert" or kind.begins_with("fuse"):
			return NOT_IN_LESSON
		return "Not yet: " + _plain(s.get("text", ""))
	var expect: Dictionary = s.get("expect", {})
	var ok := true
	match kind:
		"dragon":
			ok = payload == expect.get("dragon")
		"setup", "soak":
			ok = _same_set(payload, expect.get("picks", []))
		"upgrade":
			ok = not expect.has("picks") or _same_multiset(payload, expect.picks)
		"play":
			ok = _play_key(payload) == _play_key(expect)
		"fuse_element":
			ok = payload is Dictionary and _fuse_key(payload) == _fuse_key(expect)
	return "" if ok else s.get("hint", "Not that: " + _plain(s.get("text", "")))


## After a move this step waited for was made: on to the next, and Back stops here.
func acted(kind: String) -> void:
	if waiting_for(kind):
		index += 1
		floor_index = index


## The animator has finished: a step that waited for it moves on.
func sequence_done() -> void:
	if waiting_for("sequence"):
		index += 1
		floor_index = index


## The draft changed: an arrange step moves on once its places hold the cards it
## names. places: {"0/spell": id, …, "reserve": id}, as the play screen labels them.
func draft_changed(places: Dictionary) -> void:
	if not waiting_for("arrange"):
		return
	var want: Dictionary = step().get("expect", {}).get("places", {})
	for key in want:
		if places.get(key) != want[key]:
			return
	index += 1
	floor_index = index


## The index of the first lesson not finished, or -1 when every one is.
static func first_unfinished(done: Array) -> int:
	for i in Lessons.count():
		if not done.has(Lessons.lesson(i).id):
			return i
	return -1


## Whether lesson i may be played: every one before it is finished, or all are.
static func is_open(i: int, done: Array) -> bool:
	var first := first_unfinished(done)
	return first == -1 or i <= first


static func _same_set(a, b: Array) -> bool:
	if not a is Array or a.size() != b.size():
		return false
	for id in b:
		if not a.has(id):
			return false
	return true


static func _same_multiset(a, b: Array) -> bool:
	if not a is Array or a.size() != b.size():
		return false
	for id in b:
		if a.count(id) != b.count(id):
			return false
	return true


static func _play_key(a) -> String:
	if not a is Dictionary:
		return ""
	var fuse = a.get("fuse")
	return "%s|%s|%s|%s|%s" % [a.get("spell"), a.get("element"), a.get("boost"),
		a.get("boost_to", "attack") if a.get("boost_to") != null else "attack",
		_fuse_key(fuse) if fuse is Dictionary else ""]


static func _fuse_key(f: Dictionary) -> String:
	return "%s/%s/%s" % [f.get("top"), f.get("bottom"), f.get("element")]


static func _plain(text: String) -> String:
	var re := RegEx.create_from_string("\\[\\[[a-z_]+\\|([^\\]]+)\\]\\]")
	var out := re.sub(text, "$1", true)
	re = RegEx.create_from_string("\\[\\[([a-z_]+)\\]\\]")
	out = re.sub(out, "$1", true)
	re = RegEx.create_from_string("\\{icon:[a-z_]+\\} ?")
	return re.sub(out, "", true)
