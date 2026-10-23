extends RefCounted
## Play records: one per game played on this device, won, lost or abandoned. Makes
## them from a game, and the leaderboards, placings, summaries and pages shown from
## them. Pure: the files are kept by history_store.gd.

const Game = preload("res://engine/game.gd")
const ViewState = preload("res://ui/model/view_state.gd")

const VERSION := 1
const OUTCOMES := ["won", "lost", "abandoned"]
const STAGES := ["region_1", "region_2", "region_3", "region_4", "final_journey", "final_enemy"]
const BOARD_SIZE := 10
const PAGE_SIZE := 6
const REGION_PHASES := ["setup", "challenge", "penalty", "upgrade", "poison"]
## The fields every record must have, and their types (numbers may read back as floats).
const FIELDS := {"id": TYPE_INT, "outcome": TYPE_STRING, "difficulty": TYPE_STRING, "dragon": TYPE_STRING,
	"stage": TYPE_STRING, "score": TYPE_INT, "active_ms": TYPE_INT, "ended_at": TYPE_INT}


# ---------------------------------------------------------------- records

## The furthest point the game has reached. Play only moves forward, so it is where
## the game is now; the phase, not the Region, says when the Final Battle has begun,
## since a deck that runs short jumps there from any Region.
static func stage_of(game) -> String:
	match game.phase:
		"final_journey":
			return "final_journey"
		"final_enemy", "final_soak", "won":
			return "final_enemy"
		"lost":
			# A hunt is only lost in the Final Battle: on the Journey if the Move fell short.
			return "final_journey" if game.result.has("move") else "final_enemy"
	return "region_%d" % clampi(game.region, 1, 4)


## A record for a game that has ended now, or is being left (outcome "abandoned").
## The store gives it its id.
static func record_for(game, outcome: String, active_ms: int, started_at: int, ended_at: int) -> Dictionary:
	var r := _options(game)
	r.outcome = outcome
	r.stage = stage_of(game)
	r.score = game.score() if outcome == "won" else 0
	r.active_ms = active_ms
	r.started_at = started_at
	r.ended_at = ended_at
	return r


## What a game in progress needs kept, so it can be recorded if the app dies.
static func marker_for(game, active_ms: int, started_at: int, saved_at: int) -> Dictionary:
	var m := _options(game)
	m.stage = stage_of(game)
	m.active_ms = active_ms
	m.started_at = started_at
	m.saved_at = saved_at
	return m


## The Abandoned record an interrupted game leaves: it ended when last saved.
static func record_from_marker(marker: Dictionary) -> Dictionary:
	var r := {"v": VERSION, "outcome": "abandoned", "score": 0}
	for key in ["difficulty", "dragon", "dragon_name", "cavalier", "glass_cannon", "seed", "stage", "active_ms", "started_at"]:
		r[key] = marker.get(key)
	r.persistent_xp = marker.get("persistent_xp", false)
	r.ended_at = marker.get("saved_at", marker.get("started_at", 0))
	return r


## Whether a dictionary read back from the file is a usable record.
static func is_valid(r) -> bool:
	if not r is Dictionary:
		return false
	for key in FIELDS:
		var t := typeof(r.get(key))
		if FIELDS[key] == TYPE_INT:
			if t != TYPE_INT and t != TYPE_FLOAT:
				return false
		elif t != FIELDS[key]:
			return false
	return OUTCOMES.has(r.outcome)


static func _options(game) -> Dictionary:
	var o: Dictionary = game.options
	return {"v": VERSION, "difficulty": o.get("difficulty", "normal"), "dragon": game.dragon.id,
		"dragon_name": game.dragon.name, "cavalier": o.get("cavalier", false),
		"glass_cannon": o.get("glass_cannon", false), "persistent_xp": o.get("persistent_xp", false), "seed": o.get("seed", 0)}


# ---------------------------------------------------------------- boards

## A difficulty's leaderboard, or one dragon's on it: the wins, best first, at most
## BOARD_SIZE of them, each as {rank, record}.
static func board(records: Array, difficulty: String, dragon := "") -> Array:
	var out := []
	var wins := _sorted_wins(records, difficulty, dragon)
	for i in mini(wins.size(), BOARD_SIZE):
		out.append({"rank": i + 1, "record": wins[i]})
	return out


## Every game played on a difficulty, or against one dragon on it, whatever its end.
static func attempts(records: Array, difficulty: String, dragon := "") -> int:
	return records.filter(func(r): return r.difficulty == difficulty and (dragon == "" or r.dragon == dragon)).size()


## The wins in board order: score, then the quicker game, then the earlier, then the
## first recorded, so the order is the same every time.
static func _sorted_wins(records: Array, difficulty: String, dragon := "") -> Array:
	var wins := records.filter(func(r): return r.outcome == "won" and r.difficulty == difficulty and (dragon == "" or r.dragon == dragon))
	wins.sort_custom(_ranks_before)
	return wins


static func _ranks_before(a: Dictionary, b: Dictionary) -> bool:
	if a.score != b.score:
		return a.score > b.score
	if a.active_ms != b.active_ms:
		return a.active_ms < b.active_ms
	if a.ended_at != b.ended_at:
		return a.ended_at < b.ended_at
	return a.id < b.id


# ---------------------------------------------------------------- text

static func difficulty_name(key: String) -> String:
	return ViewState.DIFFICULTY_NAMES.get(key, key.capitalize())


static func stage_name(stage: String) -> String:
	match stage:
		"final_journey":
			return "Final Journey"
		"final_enemy":
			return "Final Enemy"
	return "Region " + stage.trim_prefix("region_")


static func outcome_name(outcome: String) -> String:
	return outcome.capitalize()


## "7:05" under an hour, "1:02:09" from an hour.
static func duration_text(ms: int) -> String:
	var s := ms / 1000
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, s / 60 % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]


## "15 Oct 2026", in local time.
static func date_text(unix: int) -> String:
	var bias: int = Time.get_time_zone_from_system().get("bias", 0)
	var d := Time.get_datetime_dict_from_unix_time(unix + bias * 60)
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%d %s %d" % [d.day, months[d.month - 1], d.year]


static func rank_text(rank: int) -> String:
	var suffix := "th"
	if rank % 100 < 11 or rank % 100 > 13:
		suffix = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th"][rank % 10]
	return "%d%s" % [rank, suffix]


static func rules_text(r: Dictionary) -> String:
	var rules := []
	if r.get("cavalier", false):
		rules.append("Cavalier")
	if r.get("glass_cannon", false):
		rules.append("Glass Cannon")
	if r.get("persistent_xp", false):
		rules.append("Persistent XP")
	return ", ".join(rules) if not rules.is_empty() else "—"


# ---------------------------------------------------------------- placing

## Where a won record placed: its rank on its difficulty's board (0 when beyond it)
## and whether it is the best yet against its dragon on that difficulty.
static func placing(records: Array, record: Dictionary) -> Dictionary:
	if record.get("outcome") != "won":
		return {"rank": 0, "dragon_best": false}
	var at := _sorted_wins(records, record.difficulty).map(func(r): return r.id).find(record.id)
	var mine := _sorted_wins(records, record.difficulty, record.dragon)
	return {"rank": at + 1 if at >= 0 and at < BOARD_SIZE else 0,
		"dragon_best": not mine.is_empty() and mine[0].id == record.id}


## What the ending screen says of a placing: nothing off the board; a first place is
## a new best, which says everything; otherwise the rank, and the dragon's best too.
static func placing_lines(p: Dictionary, record: Dictionary) -> Array:
	var rank: int = p.get("rank", 0)
	if rank == 0:
		return []
	var on := difficulty_name(record.difficulty)
	if rank == 1:
		return ["New best on " + on]
	var lines := ["%s on %s" % [rank_text(rank), on]]
	if p.get("dragon_best", false):
		lines.append("Best against %s on %s" % [record.get("dragon_name", record.dragon), on])
	return lines


# ---------------------------------------------------------------- history

## How a difficulty has gone: attempts, wins, win rate (0 to 1) and time played,
## and the same for each dragon, with its best and average winning score (-1 when
## never beaten). Every dragon in `dragon_ids` is listed, in that order, then any
## found only in the records.
static func summary(records: Array, difficulty: String, dragon_ids: Array) -> Dictionary:
	var games := _on(records, difficulty)
	var ids := dragon_ids.duplicate()
	for r in games:
		if not ids.has(r.dragon):
			ids.append(r.dragon)
	var dragons := []
	for id in ids:
		var mine := games.filter(func(r): return r.dragon == id)
		var scores: Array = mine.filter(func(r): return r.outcome == "won").map(func(r): return r.score)
		var line := _tally(mine)
		line.dragon = id
		line.dragon_name = mine[0].get("dragon_name", id.capitalize()) if not mine.is_empty() else id.capitalize()
		line.best = scores.max() if not scores.is_empty() else -1
		line.average = snappedf(float(scores.reduce(func(a, b): return a + b, 0)) / scores.size(), 0.1) if not scores.is_empty() else -1.0
		dragons.append(line)
	var s := _tally(games)
	s.active_ms = games.reduce(func(a, r): return a + r.active_ms, 0)
	s.dragons = dragons
	return s


## One page of a difficulty's games, newest first; "other" is the difficulties
## this version no longer has. `index` is kept within the pages there are.
static func page(records: Array, difficulty: String, index: int, size := PAGE_SIZE) -> Dictionary:
	var games := _on(records, difficulty)
	games.sort_custom(func(a, b): return a.ended_at > b.ended_at if a.ended_at != b.ended_at else a.id > b.id)
	var pages := maxi(1, ceili(games.size() / float(size)))
	var at := clampi(index, 0, pages - 1)
	return {"records": games.slice(at * size, (at + 1) * size), "index": at, "pages": pages}


static func _on(records: Array, difficulty: String) -> Array:
	if difficulty == "other":
		return records.filter(func(r): return not Game.DIFFICULTY.has(r.difficulty))
	return records.filter(func(r): return r.difficulty == difficulty)


static func _tally(games: Array) -> Dictionary:
	var wins := games.filter(func(r): return r.outcome == "won").size()
	return {"attempts": games.size(), "wins": wins, "win_rate": float(wins) / games.size() if not games.is_empty() else 0.0}
