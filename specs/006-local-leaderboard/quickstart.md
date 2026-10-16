# Quickstart: Validating Local Play History and Leaderboard

## Prerequisites

- Godot 4.7.2 on the PATH as `godot` (see the dev environment notes).
- Run from the repository root.

## Automated checks

```sh
tools/test.sh
```

Expect `N tests, 0 failed` and `ui check: N checks, 0 failed`. The new tests are
`tests/test_play_clock.gd`, `tests/test_play_history.gd` and
`tests/test_history_store.gd` (see [contracts/play-history.md](contracts/play-history.md)).
They write only under `user://test_history/`; `ui_check` only under
`user://tool_history/` (research R10).

Screenshots of the new screens:

```sh
godot --path . -s tools/design_shots.gd
```

Look at `records_leaderboard.png`, `records_history.png` and `ending_placing.png`.

## Manual checks in the running game

The player's own records are in `user://history.json` (on Windows,
`%APPDATA%\Godot\app_userdata\<project name>\`). Note the record count first, or
start from Clear records.

| # | Do | Expect | Spec |
|---|---|---|---|
| 1 | Records on the title screen | Opens on the last difficulty played, Leaderboard tab, filter All | US2, SC-003 |
| 2 | Win a game on Casual | Ending screen announces a placing; Leaderboard opens it; the record shows Won, Final Enemy, the ending score, a plausible time | US1-1, US3-1 |
| 3 | Lose on the Final Journey (play a weak Move) | History shows Lost, Final Journey, score — | US1-2 |
| 4 | Start a game, play into Region 2, Menu → Leave game | History shows Abandoned, Region 2 | US1-3 |
| 5 | Start a game, then kill the app (close the terminal running Godot, or swipe it away on a phone) and relaunch | One new Abandoned record, at the stage reached | US1-4, FR-007 |
| 6 | Start a game, time 60 s of play, open the rulebook for 60 s, background the app for 60 s, play 60 s more, then leave | Time shows about 2:00 (within 5 s) | US1-5, SC-002 |
| 7 | With wins against two dragons on one difficulty, switch the filter | Only that dragon's wins, ranked from 1st; an unbeaten dragon shows the empty message with its attempts | US2-6, 7, 8 |
| 8 | History tab, that difficulty | Summary per dragon: attempts, wins, rate, best, average | US4-2 |
| 9 | Clear records → Keep them, then Clear records → Clear records; relaunch | First leaves everything; second empties both tabs, still empty after relaunch | US5 |
| 10 | Replace `history.json` with `not json`, launch | Game starts normally, history empty, `history.bad.json` kept | FR-009 |

Web build: repeat 2 and 5 (closing the tab), then reload the page; the records are
still there (IndexedDB-backed `user://`).
