# Data Model: Local Play History and Leaderboard

## Play Record

One finished, lost or abandoned game. Written once, never changed.

| Field | Type | Rules |
|---|---|---|
| `v` | int | Record format, `1` |
| `id` | int | Unique, increasing; from the store's `next_id` |
| `outcome` | String | `won`, `lost` or `abandoned` |
| `difficulty` | String | A key of `Game.DIFFICULTY` when written (`casual` … `dont_even_try`) |
| `dragon` | String | Dragon id (`grimroch`, `helsang`, `rodving`, `vuurhast`, …) |
| `dragon_name` | String | The dragon's name when written, shown if the id is no longer known |
| `cavalier` | bool | Alternate rule in play |
| `glass_cannon` | bool | Alternate rule in play |
| `stage` | String | Furthest point: `region_1`–`region_4`, `final_journey`, `final_enemy` (research R7) |
| `score` | int | `game.score()` for `won`; `0` otherwise. ≥ 0 |
| `active_ms` | int | Active play time in milliseconds (research R4, R5). ≥ 0 |
| `started_at` | int | Unix seconds when the game started |
| `ended_at` | int | Unix seconds when it ended; for a recovered game, the marker's last save |
| `seed` | int | The game's seed, for reproducing a reported game |

Validation on load (research R11): `id`, `score`, `active_ms`, `ended_at` must be
numbers; `outcome` one of the three; `difficulty`, `dragon`, `stage` strings.
Anything else invalid → the record is skipped.

Invariants:
- `outcome == "lost"` ⇒ `stage` is `final_journey` or `final_enemy`.
- `outcome == "won"` ⇒ `stage == "final_enemy"`.
- `outcome != "won"` ⇒ `score == 0`.

## History file — `user://history.json`

```json
{"version": 1, "next_id": 42, "records": [ {Play Record}, ... ]}
```

Records in the order written. `next_id` is at least one more than the largest `id`
(recomputed on load if not).

## Game in Progress Marker — `user://in_progress.json`

Everything needed to write an Abandoned record if the app dies.

| Field | Type | Notes |
|---|---|---|
| `v` | int | `1` |
| `difficulty`, `dragon`, `dragon_name`, `cavalier`, `glass_cannon`, `seed` | as Play Record | Fixed at start |
| `stage` | String | Updated as play moves on |
| `active_ms` | int | Clock value at the last save |
| `started_at` | int | Unix seconds |
| `saved_at` | int | Unix seconds of the last save; becomes `ended_at` on recovery |

Lifecycle:

```text
start_game ──► marker written
   │  action accepted / stage changes / clock pauses ──► marker rewritten
   ├─ won or lost (in _act) ──► record appended, marker deleted
   ├─ Leave game confirmed ──► abandoned record appended, marker deleted
   ├─ close request ──► abandoned record appended, marker deleted
   └─ app killed ──► marker stays ──► next launch: abandoned record appended, marker deleted
```

## Play Clock (in memory)

| Field | Type | Notes |
|---|---|---|
| `elapsed_ms` | int | Active time so far |
| `last_tick` | int | `Time.get_ticks_msec()` at the previous frame, or -1 |

`tick(now_ms, active)`: if `last_tick >= 0` and `active`, add
`min(now_ms - last_tick, 1000)`; then `last_tick = now_ms`. A paused frame still
moves `last_tick`, so a resume never counts the paused stretch.

## Derived views (not stored)

**Board** — `board(records, difficulty, dragon = "")`: Won records of that difficulty
(and dragon, if given), ordered score ↓, `active_ms` ↑, `ended_at` ↑, `id` ↑; first 10,
each with its `rank` (1-based).

**Placing** — `placing(records, record)`: `{rank: 1–10 or 0, dragon_best: bool}`
for a Won record already in `records`; `{rank: 0, dragon_best: false}` otherwise.

**Difficulty Summary** — `summary(records, difficulty)`:

```text
{attempts, wins, win_rate (0–1, 0 when no attempts), active_ms (total),
 dragons: [{dragon, dragon_name, attempts, wins, win_rate, best (or -1), average (or -1)}]}
```

`dragons` lists every dragon in the card data in its order, plus any dragon found
only in records, so a dragon never played shows `0` attempts. `average` is the mean
winning score, rounded to one decimal.

**History page** — `page(records, difficulty, index, size = 6)`: that difficulty's
records, newest first (`ended_at` ↓, `id` ↓), page `index`, plus `pages` (≥ 1).
`difficulty == "other"` selects records whose difficulty is not a known key.
