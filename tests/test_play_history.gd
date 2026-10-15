extends "res://tests/base.gd"
## Play records: what a game leaves behind, and the boards, placings, summaries and
## pages made from them.

const Game = preload("res://engine/game.gd")
const PlayHistory = preload("res://ui/model/play_history.gd")

var db = CardDB.new()


func _game(extra := {}):
	var opts := {"seed": 3, "dragon": "rodving", "difficulty": "normal"}
	opts.merge(extra, true)
	return Game.new(db, opts)


## A record as the store keeps it, built directly.
func _rec(id: int, outcome: String, difficulty := "normal", dragon := "rodving", score := 0, active_ms := 600000, ended_at := 1000) -> Dictionary:
	return {"v": 1, "id": id, "outcome": outcome, "difficulty": difficulty, "dragon": dragon,
		"dragon_name": dragon.capitalize(), "cavalier": false, "glass_cannon": false,
		"stage": "final_enemy" if outcome != "abandoned" else "region_2",
		"score": score if outcome == "won" else 0, "active_ms": active_ms,
		"started_at": ended_at - 600, "ended_at": ended_at, "seed": 1}


func _won(id: int, difficulty: String, dragon: String, score: int, active_ms := 600000, ended_at := -1) -> Dictionary:
	return _rec(id, "won", difficulty, dragon, score, active_ms, ended_at if ended_at >= 0 else 1000 + id)


func _scores(board: Array) -> Array:
	return board.map(func(e): return e.record.score)


# ---------------------------------------------------------------- records

func test_stage_in_the_regions_follows_the_region() -> void:
	var g = _game()
	for phase in ["setup", "challenge", "penalty", "upgrade", "poison"]:
		g.phase = phase
		g.region = 3
		eq(PlayHistory.stage_of(g), "region_3", phase)


func test_stage_in_the_final_battle_follows_the_phase() -> void:
	var g = _game()
	g.region = 2
	g.phase = "final_journey"
	eq(PlayHistory.stage_of(g), "final_journey", "a deck that ran short jumps straight to the Final Journey")
	for phase in ["final_enemy", "final_soak", "won"]:
		g.phase = phase
		eq(PlayHistory.stage_of(g), "final_enemy", phase)


func test_a_loss_is_on_the_journey_or_to_the_enemy() -> void:
	var g = _game()
	g.phase = "lost"
	g.result = {"move": 3, "tier": -1}
	eq(PlayHistory.stage_of(g), "final_journey", "Move fell short")
	g.result = {"attack": 4, "tier": -1}
	eq(PlayHistory.stage_of(g), "final_enemy", "Attack fell short")
	g.result = {"tier": 1, "damage": 30}
	eq(PlayHistory.stage_of(g), "final_enemy", "too much damage to Soak")


func test_a_won_record_keeps_the_score_and_every_field() -> void:
	var g = _game({"difficulty": "hard", "dragon": "helsang", "cavalier": true})
	g.phase = "won"
	var r: Dictionary = PlayHistory.record_for(g, "won", 1234, 100, 200)
	eq(r.v, 1, "format")
	eq(r.outcome, "won", "outcome")
	eq(r.difficulty, "hard", "difficulty")
	eq(r.dragon, "helsang", "dragon")
	eq(r.dragon_name, db.dragon("helsang").name, "dragon name")
	eq(r.cavalier, true, "cavalier")
	eq(r.glass_cannon, false, "glass cannon")
	eq(r.stage, "final_enemy", "stage")
	eq(r.score, g.score(), "score")
	ok(r.score > 0, "a win scores")
	eq(r.active_ms, 1234, "active time")
	eq(r.started_at, 100, "started")
	eq(r.ended_at, 200, "ended")
	eq(r.seed, 3, "seed")
	ok(not r.has("id"), "the store gives the id")


func test_only_a_win_scores() -> void:
	var g = _game()
	g.region = 2
	var r: Dictionary = PlayHistory.record_for(g, "abandoned", 10, 1, 2)
	eq(r.score, 0, "abandoned")
	eq(r.stage, "region_2", "stage")
	g.phase = "lost"
	g.result = {"move": 1, "tier": -1}
	eq(PlayHistory.record_for(g, "lost", 10, 1, 2).score, 0, "lost")


func test_a_marker_becomes_an_abandoned_record() -> void:
	var g = _game({"difficulty": "easy", "glass_cannon": true})
	g.region = 3
	var m: Dictionary = PlayHistory.marker_for(g, 90000, 500, 800)
	var r: Dictionary = PlayHistory.record_from_marker(m)
	eq(r.outcome, "abandoned", "outcome")
	eq(r.ended_at, 800, "ended when last saved")
	eq(r.started_at, 500, "started")
	eq(r.active_ms, 90000, "active time")
	eq(r.stage, "region_3", "stage")
	eq(r.difficulty, "easy", "difficulty")
	eq(r.glass_cannon, true, "rules")
	eq(r.score, 0, "score")
	r.id = 1
	ok(PlayHistory.is_valid(r), "valid")


func test_validity() -> void:
	var g = _game()
	var r: Dictionary = PlayHistory.record_for(g, "abandoned", 10, 1, 2)
	ok(not PlayHistory.is_valid(r), "no id")
	r.id = 4
	ok(PlayHistory.is_valid(r), "with an id")
	var bad := r.duplicate()
	bad.outcome = "draw"
	ok(not PlayHistory.is_valid(bad), "unknown outcome")
	bad = r.duplicate()
	bad.score = "12"
	ok(not PlayHistory.is_valid(bad), "score as text")
	ok(not PlayHistory.is_valid("record"), "not a dictionary")
	bad = r.duplicate()
	bad.id = 4.0
	ok(PlayHistory.is_valid(bad), "numbers read back from JSON as floats are fine")


# ---------------------------------------------------------------- boards

func test_a_board_ranks_by_score() -> void:
	var rs := [_won(1, "normal", "rodving", 31), _won(2, "normal", "rodving", 27), _won(3, "normal", "rodving", 35)]
	var b: Array = PlayHistory.board(rs, "normal")
	eq(_scores(b), [35, 31, 27], "best first")
	eq(b.map(func(e): return e.rank), [1, 2, 3], "ranks")


func test_a_board_holds_only_its_difficulty() -> void:
	var rs := [_won(1, "hard", "rodving", 20), _won(2, "normal", "rodving", 30)]
	eq(_scores(PlayHistory.board(rs, "hard")), [20], "Hard only")


func test_ties_go_to_the_quicker_then_the_earlier_game() -> void:
	var rs := [_won(1, "normal", "rodving", 30, 900000, 50), _won(2, "normal", "rodving", 30, 600000, 60),
		_won(3, "normal", "rodving", 30, 600000, 40), _won(4, "normal", "rodving", 30, 600000, 40)]
	eq(PlayHistory.board(rs, "normal").map(func(e): return e.record.id), [3, 4, 2, 1], "time, then date, then id")


func test_a_board_shows_ten() -> void:
	var rs := []
	for i in 12:
		rs.append(_won(i + 1, "normal", "rodving", 10 + i))
	var b: Array = PlayHistory.board(rs, "normal")
	eq(b.size(), 10, "ten")
	eq(b[9].rank, 10, "ranked to ten")
	eq(b[0].record.score, 21, "the best")


func test_all_dragons_together_or_one_at_a_time() -> void:
	var rs := [_won(1, "normal", "rodving", 33), _won(2, "normal", "rodving", 28), _won(3, "normal", "helsang", 30)]
	var all: Array = PlayHistory.board(rs, "normal")
	eq(_scores(all), [33, 30, 28], "all dragons")
	eq(all.map(func(e): return e.record.dragon), ["rodving", "helsang", "rodving"], "each names its dragon")
	var one: Array = PlayHistory.board(rs, "normal", "helsang")
	eq(_scores(one), [30], "Helsang only")
	eq(one[0].rank, 1, "ranked first")


func test_only_wins_are_ranked_but_every_game_is_an_attempt() -> void:
	var rs := [_rec(1, "lost"), _rec(2, "abandoned"), _won(3, "normal", "helsang", 12), _rec(4, "lost", "normal", "helsang")]
	eq(_scores(PlayHistory.board(rs, "normal")), [12], "the win")
	eq(PlayHistory.attempts(rs, "normal"), 4, "attempts")
	eq(PlayHistory.attempts(rs, "normal", "helsang"), 2, "attempts against Helsang")
	eq(PlayHistory.attempts(rs, "hard"), 0, "none on Hard")


func test_texts() -> void:
	eq(PlayHistory.duration_text(425000), "7:05", "minutes")
	eq(PlayHistory.duration_text(3729000), "1:02:09", "hours")
	eq(PlayHistory.duration_text(0), "0:00", "nothing")
	eq([1, 2, 3, 4, 10, 11, 12, 13, 21, 22].map(func(n): return PlayHistory.rank_text(n)),
		["1st", "2nd", "3rd", "4th", "10th", "11th", "12th", "13th", "21st", "22nd"], "ordinals")
	eq(PlayHistory.stage_name("region_3"), "Region 3", "region")
	eq(PlayHistory.stage_name("final_journey"), "Final Journey", "journey")
	eq(PlayHistory.outcome_name("abandoned"), "Abandoned", "outcome")
	var r := _rec(1, "won")
	eq(PlayHistory.rules_text(r), "—", "no rules")
	r.cavalier = true
	eq(PlayHistory.rules_text(r), "Cavalier", "one rule")
	r.glass_cannon = true
	eq(PlayHistory.rules_text(r), "Cavalier, Glass Cannon", "both")
	ok(PlayHistory.date_text(1792071474).ends_with("2026"), "a date")
	eq(PlayHistory.difficulty_name("dont_even_try"), "Don't Even Try It", "difficulty")
	eq(PlayHistory.difficulty_name("legendary"), "Legendary", "an unknown one")


# ---------------------------------------------------------------- placing

func test_a_new_best() -> void:
	var rs := [_won(1, "normal", "rodving", 30)]
	var r := _won(2, "normal", "rodving", 33)
	rs.append(r)
	var p: Dictionary = PlayHistory.placing(rs, r)
	eq(p, {"rank": 1, "dragon_best": true}, "first, and so the dragon's best")
	eq(PlayHistory.placing_lines(p, r), ["New best on Normal"], "said once")


func test_off_the_board() -> void:
	var rs := []
	for i in 10:
		rs.append(_won(i + 1, "normal", "helsang", 26 + i))
	var r := _won(11, "normal", "rodving", 20)
	rs.append(r)
	var p: Dictionary = PlayHistory.placing(rs, r)
	eq(p, {"rank": 0, "dragon_best": true}, "eleventh is off the board, though the best against Rodving")
	eq(PlayHistory.placing_lines(p, r), [], "nothing is said for a win off the board")


func test_a_loss_does_not_place() -> void:
	var r := _rec(1, "lost")
	var p: Dictionary = PlayHistory.placing([r], r)
	eq(p, {"rank": 0, "dragon_best": false}, "no placing")
	eq(PlayHistory.placing_lines(p, r), [], "nothing said")


func test_second_overall_but_best_against_the_dragon() -> void:
	var rs := [_won(1, "normal", "rodving", 35), _won(2, "normal", "helsang", 25)]
	var r := _won(3, "normal", "helsang", 29)
	rs.append(r)
	var p: Dictionary = PlayHistory.placing(rs, r)
	eq(p, {"rank": 2, "dragon_best": true}, "second, best against Helsang")
	eq(PlayHistory.placing_lines(p, r), ["2nd on Normal", "Best against Helsang on Normal"], "both said")


func test_a_placing_that_is_not_the_dragons_best() -> void:
	var rs := [_won(1, "normal", "rodving", 35), _won(2, "normal", "rodving", 34), _won(3, "normal", "rodving", 33)]
	var r := _won(4, "normal", "rodving", 30)
	rs.append(r)
	eq(PlayHistory.placing_lines(PlayHistory.placing(rs, r), r), ["4th on Normal"], "rank only")


# ---------------------------------------------------------------- history

func test_pages_are_newest_first() -> void:
	var rs := []
	for i in 5:
		rs.append(_rec(i + 1, ["won", "lost", "abandoned"][i % 3], "normal", "rodving", 20, 600000, 1000 + i * 10))
	rs.append(_rec(6, "lost", "hard"))
	var p: Dictionary = PlayHistory.page(rs, "normal", 0)
	eq(p.records.map(func(r): return r.id), [5, 4, 3, 2, 1], "newest first, Normal only")
	eq(p.pages, 1, "one page")
	eq(p.index, 0, "first")
	eq(PlayHistory.page([], "normal", 0).pages, 1, "an empty history still has a page")


func test_pages_of_six() -> void:
	var rs := []
	for i in 17:
		rs.append(_rec(i + 1, "lost", "normal", "rodving", 0, 600000, 1000 + i))
	eq(PlayHistory.page(rs, "normal", 0).records.size(), 6, "first page")
	eq(PlayHistory.page(rs, "normal", 1).records.size(), 6, "second page")
	var last: Dictionary = PlayHistory.page(rs, "normal", 9)
	eq(last.index, 2, "clamped to the last page")
	eq(last.records.size(), 5, "the last five")
	eq(last.pages, 3, "three pages")
	eq(PlayHistory.page(rs, "normal", 1).records[0].id, 11, "the seventh newest heads the second page")


func test_other_holds_difficulties_this_version_lacks() -> void:
	var rs := [_rec(1, "lost", "legendary"), _rec(2, "lost", "normal")]
	eq(PlayHistory.page(rs, "other", 0).records.map(func(r): return r.id), [1], "only the unknown one")


func test_summary_by_dragon() -> void:
	var rs := [_won(1, "normal", "rodving", 30), _won(2, "normal", "rodving", 27), _won(3, "normal", "rodving", 24),
		_rec(4, "lost", "normal", "rodving"), _won(5, "normal", "helsang", 22), _rec(6, "lost", "normal", "helsang"),
		_rec(7, "abandoned", "normal", "helsang"), _rec(8, "lost", "normal", "helsang"), _won(9, "hard", "helsang", 40)]
	var s: Dictionary = PlayHistory.summary(rs, "normal", db.dragon_ids())
	eq(s.attempts, 8, "attempts on Normal")
	eq(s.wins, 4, "wins on Normal")
	eq(s.win_rate, 0.5, "half")
	eq(s.active_ms, 8 * 600000, "every game's time")
	var by := {}
	for d in s.dragons:
		by[d.dragon] = d
	eq(by.rodving.attempts, 4, "Rodving attempts")
	eq(by.rodving.win_rate, 0.75, "Rodving rate")
	eq(by.rodving.best, 30, "Rodving best")
	eq(by.rodving.average, 27.0, "Rodving average")
	eq(by.helsang.win_rate, 0.25, "Helsang rate")
	eq(by.helsang.best, 22, "Helsang best, Normal only")
	eq(by.helsang.average, 22.0, "Helsang average")
	eq(by.grimroch.attempts, 0, "a dragon not played")
	eq(by.grimroch.best, -1, "no best")
	eq(s.dragons.map(func(d): return d.dragon).slice(0, 4), db.dragon_ids(), "in the card data's order")


func test_summary_on_easy() -> void:
	var rs := [_won(1, "easy", "rodving", 30), _rec(2, "lost", "easy"), _rec(3, "lost", "easy"), _rec(4, "abandoned", "easy")]
	var s: Dictionary = PlayHistory.summary(rs, "easy", db.dragon_ids())
	eq([s.attempts, s.wins, s.win_rate], [4, 1, 0.25], "4 attempts, 1 win, 25%")
	eq(PlayHistory.summary([], "easy", db.dragon_ids()).win_rate, 0.0, "no attempts, no rate")


func test_a_dragon_only_in_the_records_is_listed_last() -> void:
	var r := _rec(1, "lost", "normal", "oldwyrm")
	r.dragon_name = "Old Wyrm"
	var s: Dictionary = PlayHistory.summary([r], "normal", db.dragon_ids())
	eq(s.dragons[-1].dragon, "oldwyrm", "listed")
	eq(s.dragons[-1].dragon_name, "Old Wyrm", "with its saved name")
	eq(s.dragons.size(), db.dragon_ids().size() + 1, "after the known ones")
