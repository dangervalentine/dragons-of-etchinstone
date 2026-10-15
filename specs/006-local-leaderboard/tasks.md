---

description: "Task list for Local Play History and Leaderboard"
---

# Tasks: Local Play History and Leaderboard

**Input**: Design documents from `/specs/006-local-leaderboard/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. The plan names three new headless test files (clock, history model, store) and `ui_check` extensions as the gates for FR-001–FR-020 and SC-001/002/004/005; each is written before the code it checks.

**Organization**: Tasks are grouped by user story (US1 recording P1, US2 leaderboard P1, US3 ending placing P2, US4 history P3, US5 clearing P3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Paths are relative to the repository root. Run all tests with `./tools/test.sh`.

## Conventions every task follows

- `engine/` and `data/cards.json` are never edited.
- GDScript style: tabs, `##` doc comments on every file and function, typed locals,
  preload constants named like `const PlayHistory = preload("res://ui/model/play_history.gd")`.
  Match the surrounding file.
- Test files extend `"res://tests/base.gd"` (which already preloads `CardDB`) and use
  `eq()` / `ok()`; every `test_*` method is picked up by `tests/run.gd`. Build games as
  `Game.new(db, {"seed": 3, "dragon": "rodving", "difficulty": "normal"})` with
  `var db = CardDB.new()` and `const Game = preload("res://engine/game.gd")`.
- Records are plain Dictionaries with exactly the fields in `data-model.md` → Play Record:
  `v` (=1), `id`, `outcome` (`"won"`, `"lost"` or `"abandoned"`), `difficulty`, `dragon`,
  `dragon_name`, `cavalier`, `glass_cannon`, `stage` (`region_1`–`region_4`,
  `final_journey`, `final_enemy`), `score`, `active_ms`, `started_at`, `ended_at`, `seed`.
  Invariants: `outcome == "lost"` ⇒ `stage` is `final_journey` or `final_enemy`;
  `outcome == "won"` ⇒ `stage == "final_enemy"`; `outcome != "won"` ⇒ `score == 0`.
- Screens are built in code with the helpers in `ui/theme/theme.gd` (`UI.label`,
  `UI.button(text, kind, icon)`, `UI.panel`, `UI.hbox`, `UI.vbox`, `UI.spacer`,
  `UI.icon_rect`) and `ChoiceTile.make(title, desc, ...)` from `ui/widgets/choice_tile.gd`.
  Minimum text `T.TEXT_MIN` (22), tap target `T.TAP_MIN` (88), nothing scrolls.
- Never write to the player's real `user://history.json` from a test or tool: set
  `HistoryStore.dir` first (research R10).

---

## Phase 1: Setup

**Purpose**: The one asset the screens need.

- [X] T001 Add a `trophy` icon to the `ICONS` dict in `tools/gen_icons.py` (a cup on a short stem and foot with two side handles, in the same 48-unit white style as `crown`, built from the existing `poly`/`path`/`ring` helpers), run `python tools/gen_icons.py`, and confirm `art/icons/trophy.svg` is written and imports in Godot (open the project headless once: `godot --headless --path . --import`)

---

## Phase 2: Foundational (record model, clock and store)

**Purpose**: The pure model and the file store every story reads. Blocks all stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 [P] Write `tests/test_play_clock.gd` per `contracts/play-history.md` → PlayClock: active ticks add the gap between calls; inactive ticks add nothing; a gap of 600000 ms adds at most 1000; the first tick after `reset()` adds nothing; after `reset(5000)` `elapsed_ms == 5000`; pause (inactive ticks for 10 s of fake time) then resume does not count the pause. Confirm it fails (file missing)
- [X] T003 [P] Create `ui/model/play_clock.gd` (`extends RefCounted`): `var elapsed_ms := 0`, `var _last := -1`, `func tick(now_ms: int, active: bool)` adding `mini(now_ms - _last, 1000)` when `_last >= 0 and active`, then `_last = now_ms`; `func reset(from_ms := 0)` sets `elapsed_ms = from_ms` and `_last = -1`. Run `./tools/test.sh`; T002 passes
- [X] T004 Write the record-building tests in `tests/test_play_history.gd`: `stage_of` returns `region_N` for phases `setup`/`challenge`/`penalty`/`upgrade`/`poison` using `game.region`; `final_journey` for phase `final_journey` even when the game jumped there early (set `g.region = 2; g.phase = "final_journey"`); `final_enemy` for `final_enemy`, `final_soak` and `won`; for `lost`, `final_journey` when `g.result` has `"move"`, else `final_enemy`. `record_for(g, "won", 1234, 100, 200)` has `score == g.score()` (set `g.phase = "won"` first) and every field in the conventions list with the right types; `record_for(g, "abandoned", ...)` and `"lost"` have `score == 0`. `marker_for` → `record_from_marker` gives an `abandoned` record whose `ended_at` is the marker's `saved_at` and whose `active_ms`/`stage` are the marker's. `is_valid` rejects records missing `id`, with `outcome == "draw"`, or with `score` as a String, and accepts a record from `record_for` plus an `id`
- [X] T005 Create `ui/model/play_history.gd` (`extends RefCounted`, static only) with `OUTCOMES`, `STAGES`, `BOARD_SIZE := 10`, `PAGE_SIZE := 8`, and `stage_of(game)`, `record_for(game, outcome, active_ms, started_at, ended_at)`, `marker_for(game, active_ms, started_at, saved_at)`, `record_from_marker(marker)`, `is_valid(r)` exactly as in `contracts/play-history.md` and research R7. Read difficulty and rules from `game.options` (`difficulty` default `"normal"`, `cavalier`/`glass_cannon` default `false`, `seed`), dragon id from `game.options.get("dragon")` falling back to `game.dragon.id` if present, `dragon_name` from `game.dragon.name`. Marker fields per data-model → Game in Progress Marker (`v`, `difficulty`, `dragon`, `dragon_name`, `cavalier`, `glass_cannon`, `seed`, `stage`, `active_ms`, `started_at`, `saved_at`). Run tests; T004 passes
- [X] T006 Write `tests/test_history_store.gd`: each test sets `HistoryStore.dir = "user://test_history/"` and deletes that folder's files first and last (a helper `_clean()` using `DirAccess`). Cases: append two records, reset `HistoryStore.records = []`, `load_all()`, both back in order with ids 1 and 2; ids keep increasing after reload; main file holds `not json` and `.tmp` holds a valid history → recovered from `.tmp`; main file `not json` with no `.tmp` → `records` empty and `history.bad.json` exists; a file with one invalid record among two valid → two loaded; a leftover `in_progress.json` → after `load_all()` there is exactly one extra `abandoned` record and the marker file is gone; `clear_all()` then `load_all()` → empty and no marker
- [X] T007 Create `ui/model/history_store.gd` (`extends RefCounted`, static): `static var dir := "user://"`, `static var records: Array = []`, `static var _next_id := 1`; `load_all()`, `append(record) -> Dictionary`, `save_marker(marker)`, `clear_marker()`, `clear_all()` per `contracts/play-history.md` and research R2/R11. Files: `history.json` = `{"version": 1, "next_id": N, "records": [...]}`; `in_progress.json` = the marker. Every write: `FileAccess.open(path + ".tmp", WRITE)`, `store_string(JSON.stringify(data, "\t"))`, close, then `DirAccess.rename_absolute(tmp, path)` (remove the old file first if rename fails on the platform). Load: parse main file, fall back to `.tmp`, otherwise copy the unreadable main file to `history.bad.json` and start empty; skip records failing `PlayHistory.is_valid` with one `push_warning`; recompute `_next_id = max(next_id, max id + 1)`; JSON numbers come back as floats, so convert `id`, `score`, `active_ms`, `started_at`, `ended_at`, `seed` with `int()`. Then recover a leftover marker via `PlayHistory.record_from_marker` + `append` + `clear_marker`. Never raise; failures `push_warning` only (FR-009). Run tests; T006 passes

**Checkpoint**: `./tools/test.sh` green; model, clock and store ready.

---

## Phase 3: User Story 1 - Every attempt is recorded (Priority: P1) 🎯 MVP

**Goal**: Every started game leaves exactly one record (won, lost or abandoned) with the right stage, score and active time, surviving restarts and kills.

**Independent Test**: Win, lose and leave one game each, kill a fourth; after relaunch `user://history.json` has four records with the right outcomes and stages (quickstart steps 2–6).

### Tests for User Story 1

- [X] T008 [US1] In `tools/ui_check.gd`, at the top of `_initialize()` set `HistoryStore.dir = "user://tool_history/"` (preload `res://ui/model/history_store.gd`) and delete its files; in `_play()` record `HistoryStore.records.size()` before the game and assert after it ends (won or lost) that exactly one record was added, its `outcome` matches `ui.game.phase`, its `difficulty` matches the one played, and its `active_ms > 0`. Confirm the check fails before T009–T012

### Implementation for User Story 1

- [X] T009 [US1] In `ui/main.gd` preload `PlayClock`, `PlayHistory`, `HistoryStore`; add `var clock = PlayClock.new()`, `var _started_at := 0`, `var _recorded := false`, `var _focused := true`, `var _placing := {}`; call `HistoryStore.load_all()` in `_ready()` right after `Settings.load_all()`; in `start_game()` after creating the game: `clock.reset()`, `_started_at = int(Time.get_unix_time_from_system())`, `_recorded = false`, `_placing = {}`, then `_save_marker()`. Add `_save_marker()` (no-op when `game == null or _recorded`) calling `HistoryStore.save_marker(PlayHistory.marker_for(game, clock.elapsed_ms, _started_at, now))`
- [X] T010 [US1] In `ui/main.gd` add `_clock_active() -> bool` per research R5: `game != null`, phase not `won`/`lost`, `screen == play`, `_focused`, and `_top_overlay()` is null or one of `InspectOverlay`, `StageBanner`, `SizeNotice` (compare `get_script()`); add `_process(_delta)` calling `clock.tick(Time.get_ticks_msec(), _clock_active())`; in `_notification` set `_focused = false` and `_save_marker()` on `NOTIFICATION_APPLICATION_FOCUS_OUT`/`NOTIFICATION_APPLICATION_PAUSED`, `_focused = true` on `NOTIFICATION_APPLICATION_FOCUS_IN`/`NOTIFICATION_APPLICATION_RESUMED`; in the existing `_overlays.child_entered_tree` handler also call `_save_marker()` (deferred)
- [X] T011 [US1] In `ui/main.gd` add `_record(outcome: String)`: return if `game == null or _recorded`; `var r = HistoryStore.append(PlayHistory.record_for(game, outcome, clock.elapsed_ms, _started_at, now))`; `HistoryStore.clear_marker()`; `_recorded = true`; if `outcome == "won"` set `_placing = PlayHistory.placing(HistoryStore.records, r)` (until T026 lands, set `_placing = {}`). In `_act()`, right after the engine accepts (`err == ""`): if `game.phase == "won" or game.phase == "lost"` call `_record(game.phase)`, else `_save_marker()`
- [X] T012 [US1] In `ui/main.gd` record abandoned games: in the `"leave"` confirm callback call `_record("abandoned")` before `_close_overlays()`; in `_notification` handle `NOTIFICATION_WM_CLOSE_REQUEST` with `_record("abandoned")` when a game is in progress (phase not won/lost); in the `NOTIFICATION_WM_GO_BACK_REQUEST` branch that calls `get_tree().quit()`, call `_record("abandoned")` first when a game is in progress. `_record` is a no-op once recorded, so a won game is never re-recorded as abandoned
- [X] T013 [P] [US1] In `tools/shot.gd` and `tools/design_shots.gd`, set `HistoryStore.dir = "user://tool_history/"` at the top of `_initialize()` and clear its files, so screenshots never add to the player's records
- [X] T014 [US1] Run `./tools/test.sh` (T008 now passes); then run quickstart steps 2–6 by hand on desktop and note the results in the PR description

**Checkpoint**: Every game is recorded; nothing visible yet.

---

## Phase 4: User Story 2 - Leaderboard by difficulty and dragon (Priority: P1)

**Goal**: A Records screen, reached from the title, ranking wins per difficulty with a dragon filter.

**Independent Test**: With seeded wins on two difficulties and two dragons, the board lists only that difficulty's wins in order, the filter narrows to one dragon, and an empty board says so (spec US2 scenarios 1–8).

### Tests for User Story 2

- [X] T015 [US2] In `tests/test_play_history.gd` add board tests with a helper `_won(id, difficulty, dragon, score, active_ms, ended_at)` building a record: US2-1 scores 31, 27, 35 on Normal → ranks 1–3 are 35, 31, 27; US2-2 Hard and Normal wins → Hard board has only the Hard one; US2-3 equal scores → shorter `active_ms` first, then earlier `ended_at`, then lower `id`; US2-5 twelve wins → 10 entries, ranks 1–10; US2-6 Rodving 33, 28 and Helsang 30 → 33, 30, 28; US2-7 filtered to `helsang` → one entry, rank 1; lost and abandoned records never appear

### Implementation for User Story 2

- [X] T016 [US2] In `ui/model/play_history.gd` add `board(records, difficulty, dragon := "") -> Array` returning `[{"rank": int, "record": Dictionary}]` per data-model → Board (won only; order score ↓, `active_ms` ↑, `ended_at` ↑, `id` ↑; first `BOARD_SIZE`), plus `_sorted_wins(records, difficulty, dragon)` (uncapped, reused by `placing`); add `attempts(records, difficulty, dragon := "") -> int` counting every outcome; add text helpers `stage_name`, `outcome_name`, `duration_text` (`m:ss` under an hour, `h:mm:ss` from an hour), `date_text` (local `"15 Oct 2026"` using `Time.get_datetime_dict_from_unix_time(unix + Time.get_time_zone_from_system().bias * 60)`), `rank_text` (`1st`, `2nd`, `3rd`, `4th`…`10th`, `11th`–`13th` with `th`), `rules_text(record)` (`"Cavalier"`, `"Glass Cannon"`, `"Cavalier, Glass Cannon"`, or `"—"`). Add tests for `duration_text(425000) == "7:05"`, `duration_text(3729000) == "1:02:09"`, and `rank_text` 1, 2, 3, 4, 11, 12, 13. Run tests; T015 passes
- [X] T017 [US2] Create `ui/screens/records_screen.gd` (`extends Control`, `signal intent(data)`, `apply_layout(content: Rect2)` like `ui/screens/title_screen.gd`, `setup(card_db, difficulty: String)`): header row (`T.TAP_MIN` tall) with a "Back" quiet button emitting `{"type": "records_back"}`, the title `RECORDS` (`["display", 24]`, `T.GOLD`), a two-tile tab switch (Leaderboard / History, `ChoiceTile`), and a spacer where Clear records goes later; a left rail of the six difficulties in `Game.DIFFICULTY` key order named by `ViewState.DIFFICULTY_NAMES`, each a `ChoiceTile` at least `T.TAP_MIN` tall, the current one selected; state vars `_tab := "leaderboard"`, `_difficulty`, `_dragon := ""`, `_page := 0`; `_build()` rebuilds on every change, as title_screen does. Implement only the Leaderboard tab now (History tab shows nothing until US4)
- [X] T018 [US2] In `ui/screens/records_screen.gd` build the Leaderboard tab per `contracts/records-screen.md`: a filter row of `ChoiceTile`s "All" + each dragon in `db.dragon_ids()` order (named by `db.dragon(id).name`), selected one highlighted; then a column header row (`#`, Score, Dragon, Rules, Time, Date in `T.LABEL`, `T.INK_MUTED`) and up to 10 text rows from `PlayHistory.board(HistoryStore.records, _difficulty, _dragon)`; rank 1 in `T.GOLD` with `UI.icon_rect("crown", 28, T.GOLD)`; dragon name from the record's `dragon_name`. Empty state (FR-015): `"No game won on %s yet."` (All) or `"%s has not been beaten on %s yet."` (one dragon), then `"%d attempts so far."` / `"1 attempt so far."` / `"No attempts yet."` from `PlayHistory.attempts`
- [X] T019 [US2] In `ui/screens/title_screen.gd` add a "Records" button (`UI.button("Records", "normal", "trophy")`, width 220) to the bottom row right after "How to Play", emitting `{"type": "records", "from": "title"}`
- [X] T020 [US2] In `ui/main.gd` preload `RecordsScreen`; add `var _records_from := "title"`; handle intent `"records"`: store `intent.from`, create the screen with `setup(db, menu.difficulty)`, connect `intent` to `dispatch`, `_switch()` to it; handle `"records_back"`: `_show_ending()` if `_records_from == "ending" and game != null`, else `_show_title()`; in the `NOTIFICATION_WM_GO_BACK_REQUEST` branch, when no overlay is open and the screen is a `RecordsScreen`, dispatch `{"type": "records_back"}` instead of quitting. Make sure `_show_title()` (which sets `game = null`) is not called on the way into Records from the ending screen
- [X] T021 [US2] In `tools/ui_check.gd` `_screens_and_overlays()`: seed `HistoryStore.records` with 60 generated records (all six difficulties, all four dragons, every outcome, 12 wins on Normal) via `HistoryStore.append`, then from the title dispatch `{"type": "records", "from": "title"}`, run `_inspect_screen("%s records leaderboard" % where)`, select each dragon filter tile and a difficulty with no wins and inspect again, then `{"type": "records_back"}` and assert the title screen is back; clear the tool history afterwards so `_play()`'s count check (T008) still holds
- [X] T022 [US2] Run `./tools/test.sh`; fix any bounds, tap-size, text-size or scroll failure on the Records screen at every matrix size

**Checkpoint**: US1 + US2 is a usable leaderboard.

---

## Phase 5: User Story 3 - New best on the ending screen (Priority: P2)

**Goal**: A placing win is announced on the ending screen, with a way to the leaderboard.

**Independent Test**: Spec US3 scenarios 1–4 in `tests/test_play_history.gd`; a won seeded game in `ui_check` shows the placing line and the Leaderboard button.

### Tests for User Story 3

- [X] T023 [US3] In `tests/test_play_history.gd` add placing tests: US3-1 best Normal 30, new win 33 → `{rank: 1, dragon_best: true}` and `placing_lines` == `["New best on Normal"]`; US3-2 ten Normal wins all > 25, new win 20 → `rank 0` and `[]`; US3-3 a lost record → `{0, false}` and `[]`; US3-4 Rodving 35 and Helsang 25 on Normal, new Helsang win 29 → `{rank: 2, dragon_best: true}` and `["2nd on Normal", "Best against Helsang on Normal"]`; a 4th place that is not a dragon best → `["4th on Normal"]`

### Implementation for User Story 3

- [X] T024 [US3] In `ui/model/play_history.gd` add `placing(records, record) -> Dictionary` (rank = 1-based position of `record.id` in `_sorted_wins(records, difficulty)` if ≤ 10, else 0; `dragon_best` = first in `_sorted_wins(records, difficulty, dragon)`; non-won → `{"rank": 0, "dragon_best": false}`) and `placing_lines(placing, record) -> Array` per research R8 (difficulty named by `ViewState.DIFFICULTY_NAMES`: preload `res://ui/model/view_state.gd` in `play_history.gd`; `view_state.gd` must not preload `play_history.gd`, since `main.gd` hands it the finished lines). Run tests; T023 passes
- [X] T025 [US3] In `ui/model/view_state.gd` have `_ending()` take the placing lines: change the call in `build()` to `_ending(game, extra.get("lost_at", ""), extra.get("placing", []))` and add `"placing": placing` to both the won and lost dictionaries (always `[]` for lost); in `ui/main.gd` `_refresh()` pass `"placing": PlayHistory.placing_lines(_placing, _last_record)` (keep `_last_record` from `_record()`; `[]` when `_placing` is empty)
- [X] T026 [US3] In `ui/main.gd` `_record()`, set `_placing = PlayHistory.placing(HistoryStore.records, r)` for wins (replacing the T011 placeholder) and keep `_last_record = r`
- [X] T027 [US3] In `ui/screens/ending_screen.gd` under the score table (won) or the "A lost hunt scores nothing." label (lost): for each line of `e.placing`, an `hbox` with `UI.icon_rect("crown", 32, T.GOLD)` on the first line only and `UI.label(line, ["body_bold", T.BODY[1]], T.GOLD)`; then a quiet `UI.button("Leaderboard", "quiet", "trophy")` (full width) emitting `{"type": "records", "from": "ending"}`
- [X] T028 [US3] In `tools/ui_check.gd` `_play()`, when the game is won assert the ending screen holds a Label whose text starts with `"New best on"` or ends with an ordinal placing (the tool history starts empty, so the first win is always a new best), press the Leaderboard button, `_inspect_screen()` the Records screen, press Back and assert the ending screen returned with the same score; run `./tools/test.sh`

**Checkpoint**: Wins are celebrated with their rank.

---

## Phase 6: User Story 4 - Play history (Priority: P3)

**Goal**: Every attempt listed per difficulty, newest first, with a per-dragon summary.

**Independent Test**: Spec US4 scenarios 1–3 in model tests; the History tab passes `ui_check` on its first and last page with 60 seeded records.

### Tests for User Story 4

- [X] T029 [US4] In `tests/test_play_history.gd` add: US4-1 five records → `page(records, "normal", 0)` lists them newest first (`ended_at` ↓, then `id` ↓), `pages == 1`; 17 records → 3 pages of 8, 8, 1, index clamped (index 9 → last page); `difficulty == "other"` selects only records whose difficulty is not a key of `Game.DIFFICULTY`; US4-2 Rodving 4 attempts / 3 wins (30, 27, 24) and Helsang 4 / 1 (22) on Normal → Rodving `win_rate 0.75`, `best 30`, `average 27.0`; Helsang `0.25`, `22`, `22.0`; Grimroch and Vuurhast present with 0 attempts and `best == -1`; US4-3 4 attempts on Easy with 1 win → `attempts 4`, `wins 1`, `win_rate 0.25`; total `active_ms` is the sum over all outcomes; a dragon found only in records (id `"oldwyrm"`) is listed after the known ones with its saved `dragon_name`

### Implementation for User Story 4

- [X] T030 [US4] In `ui/model/play_history.gd` add `summary(records, difficulty, dragon_ids) -> Dictionary` and `page(records, difficulty, index, size := PAGE_SIZE) -> Dictionary` per data-model → Difficulty Summary and History page (`win_rate` 0 when no attempts; `best`/`average` -1 when no wins; `average` rounded to one decimal; `pages >= 1`). Run tests; T029 passes
- [X] T031 [US4] In `ui/screens/records_screen.gd` build the History tab per `contracts/records-screen.md`: left, up to 6 two-line rows (PAGE_SIZE) from `PlayHistory.page(HistoryStore.records, _difficulty, _page)` (outcome coloured Won `T.GOLD` / Lost `T.BAD` / Abandoned `T.INK_MUTED`, stage name, score or `"—"` when not won, dragon name, rules, time, date) and a pager row: "‹ Prev" and "Next ›" buttons (`T.TAP_MIN` tall, disabled at the ends) around `"Page %d of %d"`; right, a summary panel (`UI.panel`) with attempts, wins, win rate as a whole percent, total time (`duration_text`), then one row per dragon: name, attempts, wins, rate, best, average (`"—"` when no wins). Empty difficulty: `"No games played on %s yet."`. Add the "Other" rail tile (History tab only) when any record has an unknown difficulty. Changing tab or difficulty resets `_page` to 0
- [X] T032 [US4] In `tools/ui_check.gd` extend the T021 walk: switch to the History tab, `_inspect_screen()` the first page, press Next until disabled and `_inspect_screen()` the last page, switch back to Leaderboard; run `./tools/test.sh`

**Checkpoint**: All attempts visible, with the dragon comparison.

---

## Phase 7: User Story 5 - Clearing records (Priority: P3)

**Goal**: The player can wipe all records after confirming.

**Independent Test**: Clear → Keep them changes nothing; Clear → Clear records empties both tabs and stays empty after reload (store test from T006 plus `ui_check`).

- [X] T033 [US5] In `ui/screens/records_screen.gd` add a "Clear records" quiet button (icon `"close"`) at the right of the header, disabled when `HistoryStore.records` is empty, emitting `{"type": "records_clear"}`; in `ui/main.gd` handle `"records_clear"` by opening `ConfirmDialog` with `setup("Clear every recorded game? This cannot be undone.", "Clear records", "Keep them")`; on `confirmed`: `HistoryStore.clear_all()`, `_close_overlays()`, rebuild the Records screen (call its `_build()` or re-dispatch `records` with the same `from`)
- [X] T034 [US5] In `tools/ui_check.gd` after the T032 walk: press Clear records, inspect the dialog, cancel, assert the record count is unchanged; press again, confirm, assert `HistoryStore.records.is_empty()` and the Leaderboard shows the empty state; run `./tools/test.sh`

**Checkpoint**: All five stories complete.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T035 [P] In `tools/design_shots.gd` add `_records()`: seed `HistoryStore` (tool dir) with a fixed sample (about 30 records across difficulties and dragons, fixed `ended_at` dates), open Records and shoot `records_leaderboard.png` (Normal, All), `records_history.png` (Normal, page 1), and win a seeded game (reuse `_best_final()` path) or render the ending screen with a placing to shoot `ending_placing.png`; review the three images against `contracts/records-screen.md`
- [X] T036 [P] In `ui/model/rulebook.gd`, in the scoring section's paragraphs (around the "A loss scores 0" lines), add one paragraph: "Every game you play is kept in Records, on the title screen: your best wins for each difficulty, which you can narrow to one dragon, and every attempt with how far it got." Run `./tools/test.sh` (rulebook tests and `ui_check` walk every page)
- [X] T037 Performance check for SC-004: in a scratchpad script (not the repo), append 500 generated records with `HistoryStore.dir` set to a scratch folder, then time `HistoryStore.load_all()` and building the Records screen on both tabs; confirm each is well under 1 s and note the timings in the PR description
- [ ] T038 Run the whole of `quickstart.md` (automated checks, manual steps 1–10, and steps 2 and 5 in the web build) and record any failures as follow-up tasks

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none. Only US2–US4 need the icon, so it can also run alongside Phase 2.
- **Foundational (Phase 2)**: blocks every story.
- **US1 (Phase 3)**: after Phase 2. Needed by US3 (the ending screen places the record US1 writes).
- **US2 (Phase 4)**: after Phase 2; works on seeded records without US1, but is only meaningful to a player with US1.
- **US3 (Phase 5)**: after US1 (recording in `_act`) and US2 (the `records` intent and screen).
- **US4 (Phase 6)**: after US2 (it adds a tab to the Records screen).
- **US5 (Phase 7)**: after US2 (button in the Records screen header).
- **Polish (Phase 8)**: after the stories it shows.

### Within Each Story

- The test task comes first and must fail before the implementation.
- Model (`play_history.gd`) before screen; screen before `main.gd` wiring; `ui_check` last.

### Parallel Opportunities

- T002 ∥ T003 are a pair (test, then code) but independent of T004–T007; the clock pair can run alongside the history-model pair (T004/T005).
- T013 (tools) ∥ T009–T012 (`main.gd`).
- After US2: US4 (`play_history.gd` summary/page + History tab) and US5 (clear button and dialog) touch different functions; US5 can go alongside US4 if `records_screen.gd` edits are coordinated.
- T035 ∥ T036.

---

## Parallel Example: Foundational

```text
Task: "T002/T003 PlayClock tests and module in tests/test_play_clock.gd, ui/model/play_clock.gd"
Task: "T004/T005 PlayHistory record tests and functions in tests/test_play_history.gd, ui/model/play_history.gd"
```

## Parallel Example: User Story 1

```text
Task: "T009–T012 recording hooks in ui/main.gd"
Task: "T013 tool history directory in tools/shot.gd and tools/design_shots.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2)

1. Phase 1–2: icon, clock, model, store.
2. Phase 3 (US1): every game recorded; check with quickstart steps 2–6.
3. Phase 4 (US2): Records screen with the leaderboard. **Stop and validate**: this is the feature the user asked for.

### Incremental Delivery

1. + US3: ending-screen placing.
2. + US4: history and per-dragon summary (the "does the dragon matter" view).
3. + US5: clearing.
4. Polish: design shots, rulebook line, performance, full quickstart.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks.
- Do not commit unless the user asks.
- `tools/test.sh` must be green at every checkpoint.
