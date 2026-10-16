# Contract: Play History Model and Store

Three modules. The first two are pure and tested headless; the store is the only one
that touches files. Field meanings are in [data-model.md](../data-model.md).

## `ui/model/play_clock.gd` — pure

```gdscript
extends RefCounted
var elapsed_ms := 0
## Advance by the time since the previous call, capped at 1000 ms, if active.
func tick(now_ms: int, active: bool) -> void
## Start again from 0 (or from a saved value).
func reset(from_ms := 0) -> void
```

Tests (`tests/test_play_clock.gd`): active frames add up; inactive frames add
nothing; a 600 000 ms gap adds at most 1000; the first tick after `reset` adds
nothing; resuming after a pause does not count the pause.

## `ui/model/play_history.gd` — pure, static functions only

```gdscript
const OUTCOMES := ["won", "lost", "abandoned"]
const STAGES := ["region_1", "region_2", "region_3", "region_4", "final_journey", "final_enemy"]
const BOARD_SIZE := 10
const PAGE_SIZE := 6

## The furthest point the game has reached (research R7).
static func stage_of(game) -> String
## A record for a game that has ended now, or is being left (outcome "abandoned").
static func record_for(game, outcome: String, active_ms: int, started_at: int, ended_at: int) -> Dictionary
## The marker for a game in progress.
static func marker_for(game, active_ms: int, started_at: int, saved_at: int) -> Dictionary
## The Abandoned record an interrupted game leaves (marker → record).
static func record_from_marker(marker: Dictionary) -> Dictionary
## Whether a loaded dictionary is a usable record (data-model validation).
static func is_valid(r) -> bool

static func board(records: Array, difficulty: String, dragon := "") -> Array
    # → [{rank, record}], at most BOARD_SIZE
static func placing(records: Array, record: Dictionary) -> Dictionary
    # → {rank: int (0 = off the board), dragon_best: bool}
static func summary(records: Array, difficulty: String, dragon_ids: Array) -> Dictionary
static func page(records: Array, difficulty: String, index: int, size := PAGE_SIZE) -> Dictionary
    # → {records: Array, index: int (clamped), pages: int >= 1}

## Display text.
static func stage_name(stage: String) -> String      # "Region 3", "Final Journey", "Final Enemy"
static func outcome_name(outcome: String) -> String  # "Won", "Lost", "Abandoned"
static func duration_text(ms: int) -> String         # "7:05", "1:02:09"
static func date_text(unix: int) -> String           # "15 Oct 2026", local time
static func rank_text(rank: int) -> String           # "1st", "2nd", "3rd", "4th", … "10th"
## The ending screen's lines for a placing, [] when it did not place (research R8):
## ["New best on Hard"] / ["3rd on Hard", "Best against Helsang on Hard"].
static func placing_lines(placing: Dictionary, record: Dictionary) -> Array
```

Normative behaviour (tests in `tests/test_play_history.gd`, one per spec scenario
where it applies):

- `board` keeps only `outcome == "won"` and the given difficulty (and dragon); order
  score ↓, `active_ms` ↑, `ended_at` ↑, `id` ↑. Spec US2-1, 2, 3, 5, 6, 7.
- `placing` gives the record's position on `board(records, difficulty)` computed
  without the size cap, or 0 if beyond 10; `dragon_best` is position 1 on the
  difficulty-and-dragon board. A non-won record → `{0, false}`. Spec US3-1, 2, 3, 4.
- `summary` counts every outcome as an attempt; wins only for `won`; `best` and
  `average` over wins (‑1 when none). Spec US4-2, 3.
- `stage_of` per research R7, including the deck-runs-short jump (`region` 2, phase
  `final_journey` → `final_journey`) and both kinds of loss.
- `record_for` sets `score = game.score()` only for `won`; otherwise 0.

## `ui/model/history_store.gd` — file access, static

```gdscript
static var dir := "user://"            # tests and tools point this elsewhere (research R10)
static var records: Array = []         # loaded, valid records in written order

## Read history.json (with .tmp fallback and bad-file quarantine, research R2), then
## turn any leftover in_progress.json into an Abandoned record. Never fails.
static func load_all() -> void
## Append a record (assigning its id), save, and return it with its id.
static func append(record: Dictionary) -> Dictionary
static func save_marker(marker: Dictionary) -> void
static func clear_marker() -> void
## Remove every record and the marker, and save the empty history.
static func clear_all() -> void
```

Rules:
- Every write goes to `<file>.tmp` and is renamed over `<file>`.
- No function raises or returns an error to callers; failures `push_warning` and the
  in-memory `records` stay usable for this session (FR-009).
- `load_all` is called once from `main._ready()`, after `Settings.load_all()`.

Tests (`tests/test_history_store.gd`, `dir = "user://test_history/"`): round trip;
ids increase across reloads; a corrupt main file with a good `.tmp` recovers; a
corrupt file with no `.tmp` starts empty and leaves `history.bad.json`; an invalid
record among valid ones is skipped; a leftover marker becomes one Abandoned record
and is deleted; `clear_all` leaves nothing after reload.

## Integration in `ui/main.gd`

| Moment | Call |
|---|---|
| `_ready` | `HistoryStore.load_all()` |
| `start_game` | `clock.reset()`, `_started_at = now`, `save_marker(marker_for(...))` |
| `_process` | `clock.tick(Time.get_ticks_msec(), _clock_active())` |
| `_act`, engine accepted, phase now `won`/`lost` | `append(record_for(...))`, `clear_marker()`, keep the placing for the view state |
| `_act`, otherwise | `save_marker(...)` |
| focus out / paused, overlay opens that pauses the clock | `save_marker(...)` |
| Leave game confirmed | `append(record_for(game, "abandoned", ...))`, `clear_marker()` |
| `NOTIFICATION_WM_CLOSE_REQUEST`, back gesture quitting a game | as Leave game, then quit |

A game is recorded at most once: `main` keeps `_recorded := true` after the first
`append` for the current game, and every later path checks it.

`_clock_active()` is research R5. `ViewState.build` takes `opts.placing` and puts
`placing_lines` into `vs.ending.placing` (an Array of Strings, empty when none).
