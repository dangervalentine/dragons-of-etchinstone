# Research: Local Play History and Leaderboard

Decisions made while planning, each with what was weighed. Nothing in the Technical
Context was left open.

## R1. Where and how records are stored

**Decision**: One JSON file, `user://history.json`, holding
`{"version": 1, "next_id": N, "records": [...]}`. The game in progress is kept in a
second small file, `user://in_progress.json` (R3).

**Rationale**: `ui/model/settings.gd` already keeps its options in `user://` with
`ConfigFile`, so `user://` is proven on every target (desktop, Android, iOS, and on
the web, where Godot backs `user://` with IndexedDB). JSON over `ConfigFile` because
the records are a list of plain dictionaries that will gain fields over time, JSON
reads them back with no type surprises from `var_to_str`, and the file can be read
by eye when checking a bug report. 500 records of about 250 bytes each is about
125 KB, which loads in a few milliseconds.

**Alternatives considered**: `ConfigFile` with one section per record (awkward for
a growing list, no ordering); Godot `Resource` files (binary, versioned by the
engine, harder to repair); SQLite add-on (a new dependency for a few hundred rows).

## R2. Writing safely

**Decision**: Write the whole file to `<path>.tmp`, then rename it over the real
file. On load, if the main file is missing or does not parse but the `.tmp` parses,
use the `.tmp`. A file that does not parse at all is renamed to
`history.bad.json` (kept once, overwritten next time) and the history starts
empty. Every read and write failure is swallowed and logged with `push_warning`;
none reaches the player (FR-009).

**Rationale**: A crash or kill during a write must not lose earlier records
(SC-005). Rename is atomic on desktop and mobile file systems; on the web the
virtual file system makes both steps in memory before it syncs. Keeping the bad
file once means a player's history is not silently destroyed by a bug.

**Alternatives considered**: Appending one line per record (needs its own repair
logic for a torn last line, and clearing still rewrites); writing in place (a
torn write loses everything).

## R3. Games interrupted by the app closing

**Decision**: When a game starts, write `in_progress.json` with everything an
Abandoned record needs (options, dragon name, stage, active time so far, start
time). Rewrite it after every action the engine accepts, when the stage changes,
and whenever the clock pauses (app to background, an overlay opening). When the
game ends normally (won, lost, left) the record is appended and the marker deleted.
At startup, before the title screen, a marker left behind becomes an Abandoned
record with the marker's last saved values, and is deleted.

The close request (`NOTIFICATION_WM_CLOSE_REQUEST`, and the back gesture that quits
from the play screen) records the game as Abandoned straight away; the marker only
matters when the app is killed without warning, which is common on mobile and when
a browser tab is closed.

**Rationale**: Nothing runs reliably when a phone kills a backgrounded app or a tab
is closed, so the record has to be recoverable from what was already saved (FR-007).
Saving on pause catches the usual path to being killed: going to the background.

**Alternatives considered**: Saving the marker on a timer (writes when nothing has
changed; pause and action saves already cover the gaps); recording nothing for
killed games (the spec asks for every attempt).

## R4. Measuring active play time

**Decision**: A pure `PlayClock` that is advanced from `main.gd`'s `_process` by the
real time between frames, measured with `Time.get_ticks_msec()`, **capped at 1000
ms per frame**, and only while the game counts as active (R5). It holds elapsed
milliseconds and nothing else.

**Rationale**: Summing capped frame time means any stretch in which the game is not
running frames (app suspended on mobile, tab hidden on the web, a debugger break)
adds at most one second, without depending on every platform delivering a
focus-out notification. Ticks rather than `delta` because `delta` is scaled by
`Engine.time_scale` and smoothed. Being pure, it is tested with made-up frame
times. The 1 s cap keeps error within SC-002's 5 seconds even with several
suspends.

**Alternatives considered**: Wall-clock start and end with pauses subtracted (one
missed resume notification corrupts the whole figure); `_process` delta uncapped
(a 10-minute background stretch arrives as one huge frame on some platforms).

## R5. What counts as active

**Decision**: The clock runs while all of these hold: a game exists and is not won
or lost; the play screen is the current screen; the app has focus (tracked from
`NOTIFICATION_APPLICATION_FOCUS_IN/OUT` and `PAUSED/RESUMED`); and the top overlay is
not the menu, the rulebook, the glossary or a confirm dialog. The inspect overlay
(enlarged card), stage banners and the size notice do not pause it: looking at a
card is part of playing, and banners are part of the game's own sequence. Card
animations count as play.

**Rationale**: Matches FR-005's list. `main.gd` already watches overlays opening and
closing (`_fields_live`), so one `_clock_active()` check covers both.

## R6. When the end record is written

**Decision**: In `main._act`, straight after the engine accepts the action, if the
phase is now `won` or `lost`. The ending screen is shown later, after the
sequence; the record is already safe by then, and its placing is computed at the
same moment and handed to the ending screen through the view state.

**Rationale**: Recording before the closing animation means a kill during the
animation does not turn a win into an Abandoned game.

## R7. Furthest point reached

**Decision**: A stage key derived from the game: `region_1` … `region_4` while
`phase` is a Region phase (`setup`, `challenge`, `penalty`, `upgrade`, `poison`)
using `game.region`; `final_journey` for `final_journey`; `final_enemy` for
`final_enemy`, `final_soak` and `won`; for `lost`, `final_journey` if the losing
result has a `move` figure, otherwise `final_enemy` (the same test the ending
screen uses for its wording).

**Rationale**: Play only moves forward, so the current stage is the furthest one.
The engine sets `region = 4` when the deck runs short and jumps to the Final
Battle, so phase, not region, decides the final stages (spec edge case). A loss
is only possible in the Final Battle (`engine/game.gd`, `play_final` and
`final_soak`).

## R8. Ranking and placing

**Decision**: A board is the Won records of one difficulty (optionally one dragon),
sorted by score descending, then active time ascending, then end time ascending,
then id ascending; the first 10 are shown. A new win's placing is its 1-based
position in its difficulty's sorted list if 10 or less, else none; it is the best
against its dragon if it is first on its difficulty-and-dragon board. The ending
screen shows "New best on X" for rank 1, "Nth on X" for ranks 2–10, and adds "Best
against <dragon> on X" only when the dragon best is true and the overall rank is
not 1 (otherwise it would say the same thing twice).

**Rationale**: FR-011, FR-012, FR-016 and spec scenario US3-4. The id tie-break makes
the order total, so tests and the ending screen always agree.

## R9. Where the screens live and how they are reached

**Decision**: A new `RecordsScreen` (`ui/screens/records_screen.gd`) with two tabs,
Leaderboard and History, and a difficulty rail shared by both. Reached by a
"Records" button on the title screen's bottom row and a "Leaderboard" button on the
ending screen. Back returns to the screen it was opened from (title or ending), by
button and by the system back gesture. Long lists are paged, not scrolled (6 games a page, two lines each).

**Rationale**: The title screen is the hub (SC-003: Records, then a difficulty, is two
taps; the screen opens on the last difficulty played, so it is often one).
`tools/ui_check.gd` fails any screen that scrolls, and the rulebook already pages,
so the history pages too. One screen with tabs keeps the summary next to the list it
summarises.

**Alternatives considered**: An overlay over the title screen (the screen needs the
full content area for the rail, board and summary); separate leaderboard and history
screens (more navigation for the same data).

## R10. Keeping tests and tools out of the player's records

**Decision**: The store's directory is a static variable, `HistoryStore.dir`,
defaulting to `user://`. Tests set it to `user://test_history/` and delete that
folder before and after; `tools/ui_check.gd`, `tools/shot.gd` and
`tools/design_shots.gd` set it to `user://tool_history/` and clear it at start, so
running the checks never adds games to a developer's own leaderboard, and the
screenshots get a known, seeded sample history.

## R11. Records from other versions

**Decision**: Records carry `v: 1`. On load, a record missing a required field or
with the wrong type is skipped (counted in a warning), not fatal. Unknown extra
fields are kept and written back. The dragon's display name is stored in the record,
so a record for a dragon that is no longer in the card data still shows its name.
Records whose difficulty is unknown are left off the six boards but appear in the
history under an "Other" rail entry, shown only when such records exist.

**Rationale**: Spec edge cases on unreadable stores and removed dragons or
difficulties; the same tolerance `main.gd` already shows for remembered options.

## R12. Showing times and dates

**Decision**: Active time as `m:ss` under an hour and `h:mm:ss` from an hour.
End time stored as Unix seconds (`Time.get_unix_time_from_system()`), shown as a
local date, "15 Oct 2026", using the system time zone bias. Clock changes only
affect the date shown and ordering by date (spec edge case); active time is
measured separately (R4).
