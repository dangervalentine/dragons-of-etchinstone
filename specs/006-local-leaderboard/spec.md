# Feature Specification: Local Play History and Leaderboard

**Feature Branch**: `006-local-leaderboard`

**Created**: 2026-10-15

**Status**: Draft

**Input**: User description: "Add a leaderboard which tracks local plays to the game - both difficulty and score. Keep track of each attempt, whether completed or lost, what region they made it to, how long the active game was played, their difficulty. All should be tracked, but the leaderboard would be for score, based on difficulty"

## Context

A game ends in one of two ways today: the dragon is defeated and the ending screen
shows a score (the total Level of every card not Trashed), or the hunt is lost and
scores nothing. A player can also leave a game from the in-game menu. Once the
ending screen is dismissed, nothing about the game is kept.

This feature keeps a record of every game played on the device and ranks the
winning games by score, separately for each difficulty, so a player can see their
best results and how their play has gone over time.

## Clarifications

### Session 2026-10-15

- Q: Should the leaderboard be split by dragon as well as difficulty? → A: Yes, as a
  filter: each difficulty's board can show all dragons together (each entry naming
  its dragon) or one dragon at a time. A per-dragon breakdown (attempts, wins, win
  rate, best and average winning score) lets the player see whether the choice of
  dragon matters.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Every attempt is recorded (Priority: P1)

Each game the player starts on this device is recorded when it ends, whether it is
won, lost or left unfinished. The record says how the game ended, the difficulty,
the dragon, any alternate rules in play, how far the player got (which Region, or
the Final Journey or Final Enemy), the score, how long the game was actively
played, and when it was played.

**Why this priority**: The leaderboard and history both read from these records.
Without them there is nothing to show; with them alone, the data is already being
gathered for every later view.

**Independent Test**: Play one game to a win, one to a loss and leave a third
partway through; confirm three records exist with the correct outcome, difficulty,
furthest point reached, score and active play time, and that they survive closing
and reopening the app.

**Acceptance Scenarios**:

1. **Given** a game in progress on Hard, **When** the player defeats the dragon,
   **Then** a record is kept with outcome Won, difficulty Hard, furthest point Final
   Enemy, the score shown on the ending screen, and the game's active play time.
2. **Given** a game on the Final Journey, **When** the Move falls short and the hunt
   is lost, **Then** a record is kept with outcome Lost, furthest point Final
   Journey and score 0.
3. **Given** a game in progress in Region 3, **When** the player chooses Leave game,
   **Then** a record is kept with outcome Abandoned, furthest point Region 3 and
   score 0.
4. **Given** a game in progress, **When** the app is closed or killed, **Then** the
   game is recorded as Abandoned no later than the next time the app starts.
5. **Given** a game in which the player spent 10 minutes with the app in the
   background and 5 minutes in the menu or rulebook, **When** it ends, **Then**
   neither period counts toward its active play time.
6. **Given** records kept earlier, **When** the app is closed and reopened, **Then**
   all of them are still there.

---

### User Story 2 - Leaderboard by difficulty and dragon (Priority: P1)

From the title screen the player opens a leaderboard. It shows one difficulty at a
time, with a way to switch between all six. Each difficulty lists the player's
highest-scoring winning games, best first, each with its score, dragon, alternate
rules, active play time and date. A dragon filter narrows the board to one dragon,
or shows all dragons together. It opens on the difficulty the player last chose to
play, with the filter on All dragons.

**Why this priority**: This is the feature the player asked for: a place to see and
chase their best scores, compared fairly against games of the same difficulty.

**Independent Test**: With winning games recorded on two difficulties and against
two dragons, open the leaderboard, confirm each difficulty lists only its own wins
in score order, confirm the dragon filter narrows the list to that dragon's wins,
and confirm an empty board says so.

**Acceptance Scenarios**:

1. **Given** wins on Normal scoring 31, 27 and 35, **When** the player views Normal,
   **Then** they are listed 35, 31, 27.
2. **Given** a win on Hard and a win on Normal, **When** the player views Hard,
   **Then** only the Hard win is listed.
3. **Given** two wins on the same difficulty with the same score, **When** listed,
   **Then** the one with the shorter active play time ranks higher; if those are
   equal too, the earlier game ranks higher.
4. **Given** a difficulty with no wins, **When** viewed, **Then** the leaderboard
   says no game has been won on it yet, and how many attempts have been made on it.
5. **Given** more than 10 wins on one difficulty, **When** viewed, **Then** the top
   10 are listed.
6. **Given** Normal wins against Rodving (33, 28) and Helsang (30), **When** the
   player views Normal with All dragons, **Then** the list is 33 Rodving, 30
   Helsang, 28 Rodving, each entry naming its dragon.
7. **Given** the same wins, **When** the player filters Normal to Helsang, **Then**
   only the 30 is listed, ranked 1st.
8. **Given** a dragon never beaten on the chosen difficulty, **When** filtered to it,
   **Then** the board says it has not been beaten on that difficulty yet, with the
   number of attempts against it.

---

### User Story 3 - New best on the ending screen (Priority: P2)

When a win places on its difficulty's leaderboard, the ending screen says so and
gives its rank (for example "New best on Hard" or "3rd on Hard"). If it is the best
score yet against that dragon on that difficulty, it says that too (for example
"Best against Helsang on Hard"). The leaderboard can be opened from there.

**Why this priority**: It ties the leaderboard to the moment of winning, which is
when the player cares most, but the leaderboard is useful without it.

**Independent Test**: Win a game that beats every recorded score on its difficulty
and confirm the ending screen announces a new best; win one that does not reach the
top 10 and confirm nothing is announced.

**Acceptance Scenarios**:

1. **Given** a best Normal score of 30, **When** the player wins on Normal with 33,
   **Then** the ending screen announces a new best on Normal.
2. **Given** ten Normal wins all scoring above 25, **When** the player wins on
   Normal with 20, **Then** no placing is announced.
3. **Given** the ending screen of a loss, **When** shown, **Then** no placing is
   announced.
4. **Given** a best Normal score of 35 (against Rodving) and a best against Helsang
   on Normal of 25, **When** the player beats Helsang on Normal with 29, **Then**
   the ending screen announces 2nd on Normal and best against Helsang on Normal.

---

### User Story 4 - Play history (Priority: P3)

Alongside the leaderboard, the player can see a history of every attempt, newest
first: outcome, difficulty, dragon, furthest point reached, score, active play time
and date. A short summary per difficulty gives attempts, wins, win rate and total
time played, broken down by dragon (attempts, wins, win rate, best and average
winning score against each) so the player can see whether the dragon they pick
makes a difference.

**Why this priority**: The user wants every attempt tracked; this is where losses
and abandoned games become visible. It adds insight but is not needed to rank scores.

**Independent Test**: With a mix of won, lost and abandoned games recorded, open the
history and confirm every game appears with correct details and the per-difficulty
summary matches.

**Acceptance Scenarios**:

1. **Given** five recorded games, **When** the history is opened, **Then** all five
   are listed newest first, each showing its outcome and furthest point reached.
2. **Given** on Normal 4 attempts against Rodving with 3 wins (scores 30, 27, 24) and
   4 against Helsang with 1 win (score 22), **When** the Normal summary is shown,
   **Then** Rodving shows 75% win rate, best 30, average 27, and Helsang shows 25%
   win rate, best 22, average 22.
3. **Given** 4 attempts on Easy with 1 win, **When** the summary is shown, **Then**
   Easy shows 4 attempts, 1 win, 25% win rate.

---

### User Story 5 - Clearing records (Priority: P3)

The player can clear all records, after confirming, to start their leaderboard and
history afresh.

**Why this priority**: A housekeeping need (handing the device on, starting over)
rather than a core part of the feature.

**Independent Test**: Clear records, confirm the leaderboard and history are empty
and stay empty after restarting the app.

**Acceptance Scenarios**:

1. **Given** recorded games, **When** the player chooses to clear them and confirms,
   **Then** the leaderboard and history are empty.
2. **Given** the confirmation is shown, **When** the player cancels, **Then** nothing
   is removed.

---

### Edge Cases

- A game left during setup, before the first Hand is drawn: recorded as Abandoned
  at Region 1 with the time spent so far.
- A game that skips straight from an early Region to the Final Battle because the
  deck ran short: the furthest point is the Final Journey or Final Enemy, not the
  last Region entered.
- A hunt can only be lost in the Final Battle, so every Lost record's furthest point
  is the Final Journey or the Final Enemy, matching the ending screen; Region 1–4 as
  a furthest point belongs to Abandoned games.
- A win in which every card was Trashed, scoring 0: still a win and still eligible
  for the leaderboard.
- The record store is missing, unreadable or from an older version: the app starts
  normally with whatever can be read (or an empty history) and never blocks play.
- A record from an older version names a dragon or difficulty that no longer
  exists: it stays in the history with its saved name, and is left off any
  leaderboard for a difficulty that no longer exists.
- The device clock is changed: ordering by date may look odd, but active play time
  is unaffected because it measures time played, not wall-clock span.
- Very long histories (hundreds of games): the leaderboard and history still open
  promptly.

## Requirements *(mandatory)*

### Functional Requirements

**Recording**

- **FR-001**: The game MUST keep one record per started game, created when the game
  is won, lost or abandoned.
- **FR-002**: A game MUST count as started once the player begins it from the setup
  screens (including the difficulty's setup choice, if any).
- **FR-003**: Each record MUST hold: outcome (Won, Lost, Abandoned); difficulty;
  dragon; which alternate rules were on; furthest point reached (Region 1, 2, 3 or
  4, Final Journey, or Final Enemy); score; active play time; and the date and time
  the game ended.
- **FR-004**: The score MUST be the score the game reports at its end: the ending
  screen's score for a win, and 0 for a loss or an abandoned game.
- **FR-005**: Active play time MUST count only time the game is on screen and
  playable; it MUST exclude time with the app in the background, and time with the
  menu, rulebook or glossary open.
- **FR-006**: Leaving a game from the menu MUST record it as Abandoned.
- **FR-007**: A game interrupted by the app closing, crashing or being killed MUST be
  recorded as Abandoned, with the furthest point and active play time known at the
  last point it was saved, no later than the next app start.
- **FR-008**: Records MUST be kept on the device and survive the app being closed,
  updated or the device restarted.
- **FR-009**: A failure to read or write records MUST NOT stop the player starting
  or playing a game.

**Leaderboard**

- **FR-010**: The player MUST be able to open the leaderboard from the title screen.
- **FR-011**: The leaderboard MUST rank only Won games, separately for each of the
  six difficulties, highest score first.
- **FR-012**: Ties MUST be broken by shorter active play time, then by the earlier
  date.
- **FR-013**: Each difficulty MUST show its top 10 wins, each with rank, score,
  dragon, alternate rules, active play time and date.
- **FR-014**: The leaderboard MUST open on the difficulty the player last chose and
  let the player switch to any of the six.
- **FR-014a**: The leaderboard MUST offer a dragon filter: All dragons (the default)
  or any one dragon. With one dragon chosen, only Won games against that dragon are
  ranked, using the same order and top 10 limit.
- **FR-015**: A board with no wins (a difficulty, or a difficulty and dragon) MUST
  show an empty state saying so, with the number of attempts made on it.

**Ending screen**

- **FR-016**: When a win places in its difficulty's top 10, the ending screen MUST
  say so and give its rank, calling a first place a new best. When the win is also
  the best yet against that dragon on that difficulty, the ending screen MUST say so.
- **FR-017**: The ending screen MUST offer a way to open the leaderboard.

**History**

- **FR-018**: The player MUST be able to see every recorded game, newest first, with
  all the details in FR-003.
- **FR-019**: The player MUST be able to see, per difficulty, the number of attempts,
  wins, win rate and total active play time.
- **FR-019a**: For each difficulty, the player MUST be able to see the same figures
  for each dragon, plus the best and average winning score against it.

**Clearing**

- **FR-020**: The player MUST be able to remove all records, only after confirming.

### Key Entities

- **Play Record**: One game played on this device. Outcome, difficulty, dragon,
  alternate rules, furthest point reached, score, active play time, end date and
  time. Never changed once written.
- **Game in Progress Marker**: The details of the game being played (difficulty,
  dragon, rules, furthest point, active time so far), kept up to date while it is
  played, so an interrupted game can be recorded as Abandoned later.
- **Leaderboard**: A view, not stored separately: per difficulty, optionally narrowed
  to one dragon, the Won records in ranked order, top 10.
- **Difficulty Summary**: A view: per difficulty, attempts, wins, win rate, total
  active play time, and per dragon within it: attempts, wins, win rate, best and
  average winning score.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of games started are recorded with the correct outcome, whether
  they end in a win, a loss, leaving from the menu, or the app being closed.
- **SC-002**: Recorded active play time is within 5 seconds of the actual time spent
  playing, with background and menu time excluded.
- **SC-003**: A player can go from the title screen to their best score on any
  difficulty in 2 taps or fewer.
- **SC-004**: The leaderboard and history open in under 1 second with 500 recorded
  games.
- **SC-005**: No record is lost across app restarts and updates in normal use.
- **SC-006**: A player who has just won can tell from the ending screen alone whether
  the score placed on the leaderboard and at what rank.
- **SC-007**: From the summary alone, a player can tell which dragon they win most
  often against, and score best against, on any difficulty.

## Assumptions

- One player per device: records are not tied to a name or profile, and there is no
  online or shared leaderboard.
- Losses and abandoned games score 0 under the game's rules, so the leaderboard holds
  wins only; losses and abandoned games appear in the history and summaries.
- Boards are split by difficulty, with dragon as a filter within each difficulty
  rather than 36 fixed boards. Alternate rules (Cavalier, Glass Cannon) are not a
  filter; each entry shows them so the player can compare.
- Top 10 per board is enough; all records are kept regardless.
- The leaderboard and history share one screen reached from the title screen; the
  exact arrangement is a design decision for planning.
- There is no save and resume of a game in progress, so an interrupted game is
  recorded as Abandoned rather than continued.
- Records are not exported or synced; clearing app data removes them.
