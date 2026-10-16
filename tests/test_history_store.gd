extends "res://tests/base.gd"
## The record files: kept across restarts, recovered after a torn write or a killed
## app, never fatal. Works in its own folder, never the player's records.

const HistoryStore = preload("res://ui/model/history_store.gd")
const PlayHistory = preload("res://ui/model/play_history.gd")
const Game = preload("res://engine/game.gd")

const DIR := "user://test_history/"

var db = CardDB.new()


func _clean() -> void:
	HistoryStore.use_empty(DIR)


func _done() -> void:
	_clean()
	HistoryStore.dir = "user://"


func _write(file: String, text: String) -> void:
	var f := FileAccess.open(DIR + file, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _record(outcome := "abandoned") -> Dictionary:
	var g = Game.new(db, {"seed": 5, "dragon": "rodving", "difficulty": "normal"})
	return PlayHistory.record_for(g, outcome, 1000, 10, 20)


func _reload() -> void:
	HistoryStore.records = []
	HistoryStore.load_all()


func test_records_survive_a_reload_in_order() -> void:
	_clean()
	var a := HistoryStore.append(_record())
	var b := HistoryStore.append(_record())
	eq(a.id, 1, "first id")
	eq(b.id, 2, "second id")
	_reload()
	eq(HistoryStore.records.size(), 2, "both back")
	eq(HistoryStore.records.map(func(r): return r.id), [1, 2], "in order")
	eq(typeof(HistoryStore.records[0].score), TYPE_INT, "numbers are whole again")
	eq(HistoryStore.records[0], a, "unchanged")
	_done()


func test_ids_keep_increasing_after_a_reload() -> void:
	_clean()
	HistoryStore.append(_record())
	HistoryStore.append(_record())
	_reload()
	eq(HistoryStore.append(_record()).id, 3, "next id")
	_done()


func test_a_torn_write_recovers_from_the_temporary_file() -> void:
	_clean()
	HistoryStore.append(_record())
	var good := FileAccess.get_file_as_string(DIR + "history.json")
	_write("history.json", "not json")
	_write("history.json.tmp", good)
	_reload()
	eq(HistoryStore.records.size(), 1, "recovered")
	_done()


func test_an_unreadable_file_starts_empty_and_is_kept_aside() -> void:
	_clean()
	_write("history.json", "not json")
	_reload()
	eq(HistoryStore.records.size(), 0, "empty")
	ok(FileAccess.file_exists(DIR + "history.bad.json"), "the bad file is kept")
	eq(HistoryStore.append(_record()).id, 1, "and recording still works")
	_done()


func test_an_invalid_record_is_skipped() -> void:
	_clean()
	var a := _record()
	a.id = 1
	var b := _record()
	b.id = 2
	_write("history.json", JSON.stringify({"version": 1, "next_id": 4, "records": [a, {"id": 3, "outcome": "draw"}, b]}))
	_reload()
	eq(HistoryStore.records.size(), 2, "two good records")
	eq(HistoryStore.append(_record()).id, 4, "ids carry on past the skipped one")
	_done()


func test_a_leftover_marker_becomes_an_abandoned_record() -> void:
	_clean()
	HistoryStore.append(_record("lost"))
	var g = Game.new(db, {"seed": 5, "dragon": "helsang", "difficulty": "hard"})
	g.region = 3
	HistoryStore.save_marker(PlayHistory.marker_for(g, 42000, 100, 900))
	_reload()
	eq(HistoryStore.records.size(), 2, "one more record")
	var r: Dictionary = HistoryStore.records[1]
	eq(r.outcome, "abandoned", "abandoned")
	eq(r.stage, "region_3", "where it got to")
	eq(r.active_ms, 42000, "time played")
	eq(r.ended_at, 900, "when last saved")
	ok(not FileAccess.file_exists(DIR + "in_progress.json"), "the marker is gone")
	_reload()
	eq(HistoryStore.records.size(), 2, "and is not recorded twice")
	_done()


func test_clearing_removes_everything() -> void:
	_clean()
	HistoryStore.append(_record())
	HistoryStore.save_marker({"v": 1})
	HistoryStore.clear_all()
	eq(HistoryStore.records.size(), 0, "empty now")
	_reload()
	eq(HistoryStore.records.size(), 0, "and after a reload")
	ok(not FileAccess.file_exists(DIR + "in_progress.json"), "no marker")
	_done()
