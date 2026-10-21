# Research: Guided Tutorial (Learn to Play)

Phase 0 for [plan.md](plan.md). Each item: Decision, Rationale, Alternatives considered.

## R1: The lesson tables, found and checked against the engine

**Decision**: Six lessons. Lesson 1 is a staged setup; Lessons 2–6 are staged Region 1
Encounters. Every card is at Level 2 (the normal starting Level) except where noted. Card
ids are the printed codes in `data/cards.json`. The Hand is listed in dealt order, which
is also the order of its places (Reserve, Element, Spell, Boost; see R7).

| # | Lesson | Key Card → Encounter | Hand (dealt order) | Guided play | Result (engine) |
|---|---|---|---|---|---|
| 1 | Setting out | — | Setup offer: A03 Destruction, A06 Fleet Footed, A12 Fleet Footed, A15 Burning Bridges, A16 Motivated Flight (Destruction is the only card in the offer whose actions are Attacks); 1 pick to Level 3 | Pick **A03 Destruction** | Destruction at Level 3 |
| 2 | Victory | A05 Rain of Blood → Enemy 2 (HP 11, Init 4, Atk 2 fire, Armor fire 1, XP 7) | A10, A14, A06, **A03 (L3)** (Spell and Boost dealt swapped, R7) | Spell A03 Destruction (enhanced Attack 10, fire), Element A14 Frostfire Wall (fire, Init 5), Boost A06 Fleet Footed (2) on Attack; Reserve A10. Upgrade A10 (cost 3) | Victory: 10 + 2 − 1 (fire Armor) = 11 vs HP 11; no Early Damage (5 beats 4); XP 7 |
| 3 | Narrow Victory | A08 River Swiftness → Journey 1 (MP 12 lightning, Time 2, XP 5) | A05, A01, A09, A13 | Spell A09 River Swiftness (enhanced Move 6, water), Element A01 Brute Force (water), Boost A13 Adapt (3); Reserve A05 | Narrow Victory: 6 + 3 = 9 vs MP 12 (half is 6); the Reserve adds nothing (water is not the MP's lightning); XP 5; 2 cards paid from the Deck |
| 4 | Loss | A07 Adapt → Enemy 4 (HP 13, Init 2, Atk 3 shadow, Armor shadow 3, XP 8) | A09, A06, A13, A01 | Spell A13 Adapt (basic 3), Element A06 Fleet Footed (Init 5), Boost A01 (3) → Attack; Reserve A09. Soak with A06 (Armor 3) | Loss: 3 (basic, Ether does not match) + 3 = 6 vs HP 13 (half is 7); 3 shadow damage; Soaked by one Downgrade |
| 5 | Fuse | A01 Brute Force → Enemy 3 (HP 9, Init 6, Atk 2 water, Armor water 2, XP 5) | A03, A02, A05, A09 | Fuse A02 Sword of Light (top) with A03 Destruction (bottom), both water, as **fire**; Spell A05 Rain of Blood (enhanced Attack 8, fire), Element A02, Boost A09 (2) → Attack | Victory: 8 + 2 = 10 vs HP 9 (its water Armor does not touch a fire Attack); no Early Damage (Init 6 is not beaten by 6); without a Fuse the best is a Narrow Victory |
| 6 | Region end | A09 River Swiftness → Journey 2 (MP 8 water, Time 1, XP 3) | A05, A10, A13, A01; the Deck holds the Key Card and A16 (two cards: one left would show the disabled Divert's long reason, which outgrows its cell on a tablet, a layout bug outside this feature), the other 10 cards are in the discard pile | Spell A13 Adapt (enhanced 5, shadow), Element A10 Rain of Blood (shadow), Boost A01 (3); Reserve A05 | Victory: 5 + 3 = 8 vs MP 8; at Cleanup Hand 1 + Deck 2 < 5, so Region 1 ends and Region 2 is dealt (Hand 4, Deck 12) |

**Verified figures** (a throwaway planning script run against `engine/game.gd`, every
Action Set and every Fuse enumerated with `Game.preview`):

```
victory    enemy2   best_plain=complete best_fuse=complete  guided: complete xp=7 dmg=0 early=false
narrow     journey1 best_plain=narrow   best_fuse=narrow    guided: narrow   xp=5 time=2
loss       enemy4   best_plain=loss     best_fuse=loss      guided: loss     dmg=3 (A06 Soaks 3)
fuse       enemy3   best_plain=narrow   best_fuse=complete  guided: complete xp=5 dmg=0
region_end journey2 best_plain=complete                      guided: complete; finish → region 2, hand 4, deck 12
```

The lesson test (R9) asserts each of these outcomes, so a change to the card data that
moves a figure fails a test instead of a lesson.

Searching (a Python port of `rules.gd` over all 16 Key Cards × 1,365 Hands) also showed:

- Lesson 2 could not be built with every card at Level 2 if it must be a unique,
  enhanced-only Victory with the Element faster than the enemy and the Boost on Attack.
  With the Spell at Level 3 it can, which ties the lesson to Lesson 1's pick: the card
  the player raised is the card that wins the first fight.
- Lesson 2's winning set is the only one in its Hand; Lesson 5's Fuse is the only Fuse
  that wins; Lesson 4 has no set better than a Loss, with or without a Fuse; Lesson 3
  has nothing better than a Narrow Victory.
- None of the tables carries a Hardship, and Region 1 has no enemy Abilities or Journey
  Perils, so nothing in the lessons is outside what the lessons explain.

**Rationale**: Staged tables (the second clarification) make each outcome a property
that a test can prove exhaustively, not a hope about a long fixed Deck order.

**Alternatives considered**: One continuous game from a fixed Deck order (the spec's
first draft): needs four Hands in a row to line up through Cleanup draws and a Time
Penalty, and any card-data change breaks all of them at once. Raising more cards to
Level 3: unnecessary once one raised Spell sufficed.

## R2: Staging a table in the engine

**Decision**: Add `Game.stage(table: Dictionary) -> String` to `engine/game.gd`. It sets
`cards[*].level`, `deck`, `hand`, `discard`, `trash`, `region`, `phase`, and for a setup
table `setup_offer`, `setup_picks`, `setup_level`; it resets `xp`, `diverts`,
`damage_due`, `damage_element`, `downgraded`, `result`, `faced`, `_action`,
`_pending_poison`, `_regrouped`, `carried_damage`. It returns "" or a message (every
card exactly once across the piles, a Key Card present in `challenge`, a Hand of at most
four, Region 1–4).

**Rationale**: The engine is the only judge of rules (project convention). Tests already
stage games by assigning fields (`test_game.gd`, `test_emphasis.gd`); `stage()` makes that
one checked, documented entry point, so the UI never writes engine fields. The lesson
data stays outside the engine (R3), which keeps `engine/` free of tutorial content.

**Alternatives considered**: Seeds that happen to deal the right cards: impossible to
find for exact Hands and brittle. Assigning fields from `ui/`: breaks the rule that only
`view_state.gd` reads engine internals, and nothing would validate the table.

## R3: Where the lessons live

**Decision**: A new pure model `ui/model/lessons.gd` holds the six lessons as a `const`
array, in the style of `ui/model/rulebook.gd`: each lesson's table, its guided moves and
its ordered steps, with message text in Rulebook markup (`[[term]]` links, `{icon:…}`,
`{n:…}`) expanded through `Rulebook.expand()`.

**Rationale**: The text is this project's own writing, like How to Play, and benefits
from the same markup, Glossary links and the same test that every `[[term]]` exists. A
`.gd` const is preloaded with no file parsing and is easy to diff.

**Alternatives considered**: `data/tutorial.json`: needs a loader and loses the
Rulebook markup tooling; JSON also cannot hold the `Game` constants `{n:…}` refers to.

## R4: The tutorial's state and its gate

**Decision**: A new pure `RefCounted`, `ui/model/tutorial.gd`, owns one lesson run: the
lesson, the step index, and the history of read steps for Back. Its API:

- `step()` → the current step dictionary.
- `next()` / `back()` for read steps; `can_back()` is false across an action already
  taken (a game cannot be rewound).
- `check(kind, payload) -> String`: "" when the move matches the step's guided move,
  otherwise the hint to show. Kinds: `dragon`, `setup`, `play`, `soak`, `upgrade`,
  `divert`, `fuse_begin`, `fuse_element`. `upgrade` is the Upgrade Phase's one confirm
  press, which in `main` both applies the Upgrades and runs Cleanup (`_finish_upgrade`),
  so a lesson has one step for both.
- `acted(kind, phase)`: called after a successful `_act`; moves past an action step.
- `finished()` once the last step is reached.

`ui/main.gd` calls `check()` at the four commit points it already has:
`_on_primary` (setup, play, soak, and before the unspent-XP dialog in upgrade),
`_finish_upgrade`, `_confirm_mode` (Divert) and `_on_action("fuse")`. A refusal goes
through the existing `_refuse(text, id, title)` with the title "Lesson", so it lands on
the Deck as a refusal card exactly like a rules refusal.

**Rationale**: Gating at commit lets the player arrange the Hand freely (tap, swap,
drag, keyboard), which is itself part of what is taught; only the commit is held back
(FR-013, FR-014). Comparing `draft.to_action()` with the guided action ignores
`ranged_discard` and treats a missing `boost_to` as `attack`, as `to_action()` does.

**Alternatives considered**: Filtering every `dispatch` intent: would block the very
arranging the lesson asks for, and forces a script for each tap. A separate tutorial
play screen: duplicates the play screen the player will actually use (spec assumption:
the tutorial runs on the existing screens).

## R5: Lighting part of the screen

**Decision**: A new layer, `CoachMark` (`ui/overlays/coach_mark.gd`), added by `main`
between `_flight` and `_overlays`, so a glossary popover, How to Play, the menu or the
inspect view opens above it and the coach mark simply waits underneath (edge case: the
lesson resumes on the same message).

- The dimming is four `ColorRect`s round the lit rect (no shader), coloured
  `Color(T.BG_BASE, T.COACH_DIM)`; the lit rect gets a `T.FOCUS` rim, `T.COACH_PAD` larger
  than the target.
- The message is a bubble built from `UI.tooltip_box()` with a `RichTextLabel` (text ≥
  `T.TEXT_MIN`), placed beside the lit rect and clamped to `plan.content` the way
  `glossary_popover.show_entry` places its panel. Its buttons (Back, Next, Skip) are
  `UI.button` at `T.TAP_MIN`.
- Read steps: the dimming stops input outside the bubble (`MOUSE_FILTER_STOP`).
  Action steps (changed in implementation, after the owner tried it): no dimming at
  all, so nothing that must be pressed looks shut; the button that makes the move
  (Continue, Confirm, Play) is rimmed with the target and kept clear of the bubble,
  which offers only Skip; the gate (R4) holds back a wrong commit.
- The bubble and rim follow `main`'s relayout, so a resize or rotation keeps the mark on
  its target (edge case).
- Reduced motion: the dimming and bubble appear and move without tweening.

**Rationale**: Overlays in `_overlays` stop the play clock, mark the fields not live and
are closed by Esc; the coach mark must do none of that. Four rects cost nothing and need
no shader for the GL Compatibility renderer.

**Alternatives considered**: A hole-punch shader: more work for the same look.
Putting the mark in `_overlays`: would pause and close like an overlay.

## R6: Naming what to light

**Decision**: Steps name a target as a string; `play_screen.coach_rect(target) -> Rect2`
resolves it to a global rect from getters that already exist:

| Target | Resolved from |
|---|---|
| `deck` | `deck.top_rect()` |
| `key` | the Key Card strip: `deck._peek.region_rect("key")` while risen; falls back to `deck.raised_rect()` |
| `encounter` | `deck.landed.panel` |
| `chip:<name>` | `deck.landed.panel.chip(name)` (`hp`, `initiative`, `attack`, `armor0`, `mp`, `time`, `xp`) |
| `card:<id>` | `hand.card(id)` |
| `ether:<id>` | the card face's name sigil, `sigil_rects()[0]` offset by the face's position |
| `place:<key>` | `labels.label_rect(key)` (`0/spell`, `0/element`, `0/boost`, `reserve`) |
| `aim` | `aims.buttons(0)` |
| `primary` | `actions.primary` |
| `action:<id>` | the secondary button with that id (`fuse`, `divert`) |
| `picker` | the Fuse Ether picker |
| `soak` / `xp` | `soak_meter` / `xp_purse` |
| `hand` | The Hand well (a public getter for `play._hand_panel`'s global rect) |
| `screen` | no light: the bubble alone, centred |

Private nodes it needs (`deck._peek`, a face's sigil rect) get small public getters on
their widgets rather than being read from `play_screen`.

**Rationale**: Reuses the geometry the UI check already trusts (`ui_check.gd` reads the
same nodes), and keeps lesson data free of node paths.

**Alternatives considered**: Node paths in the lesson data: break whenever a widget is
rebuilt.

## R7: Getting into a lesson

**Decision**:

- **Landing page.** A "Learn to Play" button joins the How to Play / Leaderboard /
  Glossary row of `title_screen.gd` and emits `{"type": "lessons"}`.
- **Learn to Play.** With no lesson finished, it starts Lesson 1 straight away.
  Otherwise it opens a new `ui/screens/lessons_screen.gd`: the six lessons with a
  finished mark, a primary "Continue: Lesson N" (the first unfinished lesson; "Start
  again" once all are done), finished lessons replayable, later ones shown as not yet
  open (FR-003, FR-003a).
- **Lesson 1.** It opens `dragon_screen.gd` in a lesson mode: Rodving chosen, the other
  three locked through the screen's existing lock path with the line "The lessons are
  played against Rodving." (FR-008). This is a screen flag, not `Settings.unlocked`,
  which is saved. Continue skips the difficulty screen (FR-009) and opens the play screen
  on Lesson 1's staged setup.
- **Lessons 2–6.** They open the play screen on the staged table. `main.start_lesson(n)`
  is `start_game` with `game.stage(lesson.table)` after `Game.new`, the same start
  sequence (deal), and the tutorial attached.
- **Dealt order.** The Hand's dealt order is its order of places, so Lesson 2 deals its
  Spell and Boost swapped: the player's first act is one swap, as the step asks.

**Rationale**: Re-using the dragon screen and the play screen keeps the tutorial
honest: what is learned is the real screen.

**Alternatives considered**: A list screen every time, even the first: one extra press
before a new player sees anything. A "skip to lesson N" for unfinished lessons:
rejected in clarification (in order the first time).

## R8: Progress, records and the first-launch offer

**Decision**:

- `Settings` gains, under `progress`:
  - `lessons` (the ids finished);
  - `tutorial_done`;
  - `tutorial_offered` (the first-launch offer has been shown once).
- A lesson is marked finished when its last step is reached. `tutorial_done` is set
  when the summary shows after Lesson 6 (FR-018).
- **No records.** While a tutorial is attached, `main._save_marker()` and
  `main._record()` do nothing (FR-019). Starting a lesson while a real game is in memory
  records that game as abandoned, exactly as starting a new game does today.
- **First-launch offer.** On pressing Play when `HistoryStore.records` is empty, no lesson
  is finished and `tutorial_offered` is false, a `ConfirmDialog` offers "Learn to Play"
  or "Play". Either answer sets `tutorial_offered` (FR-002).
- **Tools.** `Settings` gains a path override, used by the same tools that call
  `HistoryStore.use_empty`, so the UI check never touches the player's lesson progress.

**Rationale**: Settings already keeps `progress.unlocked`; lesson progress is the same
kind of fact. `_save_marker`/`_record` are the only two writers of play history.

**Alternatives considered**: A separate progress file: one more file for three values.
Offering the tutorial at launch before the landing page: interrupts a player who
already knows the game; the Play button is where the choice matters.

## R9: Tests and checks

**Decision**:

- **`tests/test_game.gd`.** `stage()` accepts a valid table and refuses a card missing
  or doubled, a challenge table with no Key Card, and a Hand of five.
- **`tests/test_lessons.gd`** (new) proves FR-007 and FR-020 against the real engine for
  every lesson:
  - the staged table is accepted;
  - the guided moves give the intended outcome;
  - exhaustively over every Action Set and Fuse: nothing better in Lessons 3 and 4, no
    Victory without a Fuse in Lesson 5, and a single winning set in Lesson 2;
  - the Soak and Upgrade picks are accepted;
  - Lesson 6 reaches Region 2.

  It also checks every step: its target is in R6's vocabulary, every `[[term]]` exists
  in the Glossary, and every FR-012 concept is named by at least one step (SC-004).
- **`tests/test_tutorial.gd`** (new) covers the gate and the steps:
  - `check()` passes the guided move and refuses others with the step's hint;
  - Back stops at an action;
  - the first unfinished lesson, and which lessons are open.
- **`tools/ui_check.gd`** gets a new `lessons` walk. It plays all six lessons through
  the real screens by pressing what a player would press:
  - one wrong commit per Encounter lesson, which must show a refusal card;
  - the lit rect must sit inside the view and contain its target node's rect;
  - every bubble must pass the existing text and tap checks;
  - reduced motion;
  - HistoryStore's record count and marker must be unchanged.

  Quick mode runs it at phone-16x9; full mode at every size in the layout matrix.

**Rationale**: SC-001 and FR-020 are exactly what an exhaustive engine test can prove;
the UI walk proves FR-011, FR-016 and FR-019 on the real screens.

## R10: Documents

**Decision**: README: a line on Learn to Play under Status. CLAUDE.md: the `lessons`
walk in the walk table, and `lessons tutorial` in the unit table for
`ui/model/lessons.gd` and `tutorial.gd`. No rules interpretation changes.
