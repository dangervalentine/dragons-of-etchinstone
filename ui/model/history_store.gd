extends RefCounted
## The files that keep play records on the device: every finished game in
## history.json, and the game in progress in in_progress.json so a game the app
## did not live to finish is still recorded, as Abandoned, at the next start.
## Every write goes to a temporary file that is then renamed over the real one, so
## a write cut short never loses what was there. Nothing here ever stops play: a
## failure is a warning, and the records in memory stay usable.

const PlayHistory = preload("res://ui/model/play_history.gd")

const HISTORY := "history.json"
const MARKER := "in_progress.json"
const BAD := "history.bad.json"
const NUMBERS := ["v", "id", "score", "active_ms", "started_at", "ended_at", "seed"]

## Where the files live. Tests and tools point this elsewhere.
static var dir := "user://"
## Every valid record, in the order written.
static var records: Array = []
static var _next_id := 1


## Read the history, then record any game left in progress as Abandoned.
static func load_all() -> void:
	records = []
	_next_id = 1
	var data = _read(HISTORY)
	if data == null:
		data = _read(HISTORY + ".tmp")
		if data == null and FileAccess.file_exists(dir + HISTORY):
			push_warning("Play history could not be read; kept aside as " + BAD)
			DirAccess.copy_absolute(dir + HISTORY, dir + BAD)
	if data is Dictionary and data.get("records") is Array:
		var skipped := 0
		for r in data.records:
			if PlayHistory.is_valid(r):
				records.append(_whole(r))
				_next_id = maxi(_next_id, r.id + 1)
			else:
				skipped += 1
		if skipped > 0:
			push_warning("%d unreadable play records skipped" % skipped)
		var next = data.get("next_id", 1)
		if typeof(next) == TYPE_INT or typeof(next) == TYPE_FLOAT:
			_next_id = maxi(_next_id, int(next))
	var marker = _read(MARKER)
	if marker is Dictionary:
		append(_whole(PlayHistory.record_from_marker(marker)))
	clear_marker()


## Add a record, giving it the next id, and save. Returns it with its id.
static func append(record: Dictionary) -> Dictionary:
	var r := record.duplicate()
	r.id = _next_id
	_next_id += 1
	records.append(r)
	_save()
	return r


## For tests and tools: keep records in this folder instead, starting empty.
static func use_empty(folder: String) -> void:
	dir = folder
	DirAccess.make_dir_recursive_absolute(folder)
	for f in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder + f)
	load_all()


## Keep the game in progress.
static func save_marker(marker: Dictionary) -> void:
	_write(MARKER, marker)


static func clear_marker() -> void:
	for f in [MARKER, MARKER + ".tmp"]:
		if FileAccess.file_exists(dir + f):
			DirAccess.remove_absolute(dir + f)


## Forget every record.
static func clear_all() -> void:
	records = []
	_next_id = 1
	clear_marker()
	_save()


static func _save() -> void:
	_write(HISTORY, {"version": PlayHistory.VERSION, "next_id": _next_id, "records": records})


## JSON reads every number back as a float; the records hold whole numbers.
static func _whole(r: Dictionary) -> Dictionary:
	for key in NUMBERS:
		if typeof(r.get(key)) == TYPE_FLOAT:
			r[key] = int(r[key])
	return r


static func _read(file: String) -> Variant:
	if not FileAccess.file_exists(dir + file):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(dir + file)) != OK:
		return null
	return json.data


static func _write(file: String, data: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var path := dir + file
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		push_warning("Could not write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		# Some file systems will not rename over an existing file.
		DirAccess.remove_absolute(path)
		if DirAccess.rename_absolute(path + ".tmp", path) != OK:
			push_warning("Could not save " + path)
