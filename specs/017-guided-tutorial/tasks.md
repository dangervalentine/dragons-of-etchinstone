---

description: "Task list for 017 Guided Tutorial (Learn to Play)"
---

# Tasks: Guided Tutorial (Learn to Play)

**Input**: Design documents from `specs/017-guided-tutorial/`

**Prerequisites**:
- [plan.md](plan.md)
- [spec.md](spec.md)
- [research.md](research.md)
- [data-model.md](data-model.md)
- [contracts/lessons.md](contracts/lessons.md)
- [contracts/coach-mark.md](contracts/coach-mark.md)
- [contracts/tutorial-flow.md](contracts/tutorial-flow.md)
- [quickstart.md](quickstart.md)

**Tests**: Included. FR-020 requires an automated check of every lesson, and the project tests every pure model headless and every screen in `ui_check` (plan, Constitution Check; research R9).

**Organization**: Tasks are grouped by user story (spec.md US1–US8). A story's lesson steps, its test rows and its UI-walk segment ship together.

**Card ids**: `A03` means `DOE-A03` and so on. The tables are research.md R1's, which a planning run against `engine/game.gd` verified.

**Check**: run the narrowest tier that covers each task (CLAUDE.md), and `tools/test.sh` at the end of each phase.

**Commits**: do not commit. The user commits only when asked.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story the task belongs to (US1–US8)

---

## Phase 1: Setup

- [X] T001 Run `tools/test.sh` on the current tree and confirm it is green, so that later failures belong to this feature. Record the unit and UI-check counts, and any failure that was already there, under "Notes" at the end of this file.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: everything every lesson needs:
- the engine's `stage()`;
- saved progress, with the tool redirect;
- the lesson data shape and the tutorial model;
- the target rects;
- the coach-mark layer;
- `main`'s lesson plumbing;
- the UI walk's scaffold.

After this phase a lesson can be started from code, shows its steps, and gates commits, but no lesson has its full script yet.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] In `ui/theme/tokens.gd`, add the coach-mark tokens (data-model.md "Changes to existing state"), each with a one-line `##` comment citing specs/017 in the file's style:
  - `COACH_DIM := 0.72` (dimming alpha on read steps);
  - `COACH_DIM_ACT := 0.35` (dimming alpha on action steps);
  - `COACH_PAD := 8.0` (rim grown past the target);
  - `COACH_RIM := 3.0` (rim width);
  - `COACH_GAP := 16.0` (bubble to rim);
  - `COACH_MAX_W := 560.0` (bubble width cap);
  - `COACH_FADE := 0.2`.
- [X] T003 [P] In `tests/test_game.gd`, add `stage()` tests (they fail until T004):
  - a valid challenge table (Lesson 2's: deck `[A05, …rest]`, hand `[A10, A14, A06, A03]`, `levels {A03: 3}`) returns "" and sets `deck[0] == "DOE-A05"`, `hand`, `cards["DOE-A03"].level == 3`, `phase == "challenge"`, `region == 1`, `xp == 0`, `diverts == 0`;
  - a valid setup table (5 offered, 1 pick, Level 3) sets `phase == "setup"`, `setup_offer`, `setup_picks == 1`, `setup_level == 3`;
  - refused, each leaving the game unchanged:
    - a card missing from every pile;
    - a card in two piles;
    - a challenge table with an empty `deck`;
    - a Hand of five;
    - Region 5;
    - a setup offer containing a card not in `deck`;
  - `discard: "rest"` places every card not otherwise placed, in id order.
- [X] T004 In `engine/game.gd`, add `func stage(table: Dictionary) -> String` below `_finish_setup`, with a `##` comment (specs/017, research R2) and the validation and resets listed in data-model.md "Table" (verbatim rules: "every Mage Card id appears exactly once across `deck`, `hand`, `discard` and `trash`"; "for `setup`, every card is in `deck` and `setup_offer` is a subset of it"; "for `challenge`, `deck` has a Key Card"; Hand at most `HAND_SIZE`; Region 1–4).
  - Validate everything before changing any field.
  - `levels` defaults every unlisted card to 2.
  - `discard: "rest"` expands to the unplaced ids, sorted.
  - Add the `stage` line to the header comment's list of actions.
  - Run `tools/test.sh unit game rules playthrough`.
- [X] T005 [P] In `ui/model/settings.gd`:
  - add `static var lessons: Array = []`, `static var tutorial_done := false` and `static var tutorial_offered := false`;
  - load them in `load_all` from section `progress`, filtering `lessons` to known lesson ids via a `const LESSON_IDS := ["setting_out", "victory", "narrow", "loss", "fuse", "region_end"]` (keep this list in step with `lessons.gd`; T009's test checks it);
  - save them in `save_all`;
  - add `static var path := PATH` and use `path` in `load_all`/`save_all`, with `static func use_path(p: String)`, documented as the tools' redirect (research R8), mirroring `HistoryStore.use_empty`;
  - update the header comment.
- [X] T006 [P] Write `tests/test_tutorial.gd` (extends `res://tests/base.gd`; preloads `res://ui/model/tutorial.gd` and `res://ui/model/lessons.gd`). Build a small two-lesson fixture in the test, not the real lessons. The tests fail until T008:
  - `first_unfinished([], ids) == 0`, `([ids[0]]) == 1`, and every id gives -1;
  - `is_open(0, [])`, `not is_open(1, [])`, `is_open(1, [ids[0]])`, and `is_open(i, all)` for every `i`;
  - on a read step, `next()` advances, and `back()` returns but never below `floor`;
  - after `acted()`, `can_back()` is false;
  - `check("play", guided)` is ""; a different spell, element, boost, `boost_to` or fuse returns the step's `hint`; a missing `boost_to` matches `attack`; `ranged_discard` is ignored;
  - `check("soak", [b, a])` matches `[a, b]` (a set); `check("upgrade", …)` compares as a multiset when the step has `picks`, and passes any picks, including none, when its `expect` is `{}`;
  - `acted("upgrade")` advances an `upgrade` step (one call covers the Upgrades and Cleanup);
  - a kind the step does not wait for returns a string starting "Not yet";
  - `check("divert", …)` and `check("fuse_begin", …)` on a step that does not wait for them return "Not in this lesson.";
  - an `arrange` step advances on `draft_changed` once its places match, and never refuses;
  - a `sequence` step advances on `sequence_done()`;
  - `finished()` after the last step.
- [X] T007 Create `ui/model/lessons.gd` (`extends RefCounted`, `##` header citing specs/017 contracts/lessons.md):
  - `const CONCEPTS` with the 23 ids of contracts/lessons.md "Concept ids";
  - `const TARGET_PREFIXES` with the vocabulary of contracts/coach-mark.md "Target vocabulary";
  - `const LESSONS`, six entries in order with `id`, `title`, `outcome` and `table` exactly as research.md R1 / data-model.md "Table":
    - **`setting_out`**: phase `setup`, deck all 16 cards with `A03, A06, A12, A15, A16` first, `setup_offer [A03, A06, A12, A15, A16]`, `setup_picks 1`, `setup_level 3`, hand `[]`.
    - **`victory`**: deck `[A05]` + the rest, hand `[A10, A14, A06, A03]`, `levels {A03: 3}`.
    - **`narrow`**: deck `[A08]` + the rest, hand `[A05, A01, A09, A13]`.
    - **`loss`**: deck `[A07]` + the rest, hand `[A09, A06, A13, A01]`.
    - **`fuse`**: deck `[A01]` + the rest, hand `[A03, A02, A05, A09]`.
    - **`region_end`**: deck `[A09]`, hand `[A05, A10, A13, A01]`, `discard "rest"`.

    For the challenge tables, "the rest" is written as `"deck_rest": true`; `lessons.gd` expands it, not `stage()`.
  - `steps: []` for now. Each story phase fills its lesson's steps.
  - static helpers:
    - `count()`;
    - `lesson(i)`;
    - `index_of(id)`;
    - `table(i)`, which returns the expanded table dictionary for `Game.stage`;
    - `text(step)`, which returns `Rulebook.expand(step.text)`.
- [X] T008 Create `ui/model/tutorial.gd` (`extends RefCounted`, `##` header citing specs/017 research R4 and data-model.md "Tutorial"):
  - fields `lesson`, `index` and `floor`;
  - methods `step()`, `next()`, `back()`, `can_back()`, `check(kind, payload) -> String`, `acted(kind)`, `sequence_done()`, `draft_changed(draft)` and `finished()`;
  - statics `first_unfinished(done: Array) -> int` and `is_open(i, done) -> bool`, from `Lessons`;
  - `check()` normalises a play payload: drop `ranged_discard`; `boost_to` defaults to `"attack"`; compare `fuse` by `top`/`bottom`/`element`;
  - `check("upgrade", picks)` follows data-model.md's `upgrade` row: a multiset match with `picks`, anything with `{}`. There is no separate `finish` kind;
  - `draft_changed` reads only `draft.sets[0]` and the draft's reserve, through public TurnDraft fields.

  Run `tools/test.sh unit tutorial`.
- [X] T009 Write `tests/test_lessons.gd` (extends `res://tests/base.gd`; preloads `Game`, `CardDB`, `Lessons`, `Glossary`). This phase builds the reusable harness; each story adds its lesson's assertions:
  - `_stage(i) -> Game`: `Game.new(db, {"dragon": "rodving", "difficulty": "normal", "seed": 0})`, then `stage(Lessons.table(i))`. It asserts "".
  - `_all_actions(g) -> Array`: every Spell/Element/Boost permutation of the Hand × `boost_to` attack/initiative, plus every Fuse whose top is the Element and whose bottom fills no Role, × the four Ethers. This is the same enumeration as the planning script (research R1).
  - `_best(g, with_fuse) -> String` over `g.preview`, ignoring errors.
  - `_follow(i) -> Game`: stage the lesson, then for each step whose `wait` is `setup`/`play`/`soak`/`upgrade`, apply its `expect` to the engine directly. An `upgrade` step calls `g.upgrade(id)` once per entry of `picks` (none for `{}`) and then `g.finish()`, as `main._finish_upgrade` does. Each call must return "".
  - `test_tables_stage`: every lesson's table stages.
  - `test_step_shape`: every step has `text`, `target` and `wait` from the data-model.md lists, its target starts with a `TARGET_PREFIXES` entry, and every `[[term]]` in its text is `Glossary.has()`.
  - `test_settings_ids`: `Settings.LESSON_IDS` equals the `id`s of `Lessons.LESSONS`.
- [X] T010 [P] Add public getters, each with a `##` comment citing specs/017 research R6:
  - in `ui/widgets/deck_stack.gd`: `func key_strip_rect() -> Rect2`, the global rect of the raised Key Card's Encounter strip (`_peek.region_rect("key")` offset by `_peek`'s global position), or `Rect2()` when not raised;
  - in `ui/widgets/card_view.gd`: `func ether_rect() -> Rect2`, the global rect of the name sigil (`_face.sigil_rects()[0]` offset by `_face.global_position`, as `part_help` does).
- [X] T011 In `ui/screens/play_screen.gd`, add `func coach_rect(target: String) -> Rect2` resolving every target of contracts/coach-mark.md "Target vocabulary" from the getters in research.md R6:
  - `card:a+b` is the merged rect;
  - `hand` is the Hand well's global rect (add a public `hand_rect()` getter rather than reading `_hand_panel` from outside);
  - `dragon:` is not handled here (the dragon screen handles it, T018);
  - an unknown target or an absent node returns `Rect2()`.
- [X] T012 Create `ui/overlays/coach_mark.gd` (`extends Control`, full rect, `MOUSE_FILTER_IGNORE` at the root; `##` header citing specs/017 contracts/coach-mark.md):
  - signals `next`, `back`, `skip`, `term(id, anchor)` and `chosen(id)` (for the lesson-complete and summary buttons);
  - parts as the contract's "Parts" table: four dimming `ColorRect`s, a rim drawn in `_draw`, and a bubble from `UI.tooltip_box()` holding a `RichTextLabel` (BBCode from `Lessons.text`, `meta_clicked` emits `term`) and a button row;
  - `show_step(text, rect, reading, can_back)`;
  - `show_choice(text, buttons: Array)` for lesson complete and the summary;
  - `hide_mark()`;
  - `relayout(content: Rect2, rect: Rect2)`, which places the bubble by the contract's "Placement" rules;
  - dimming input: `MOUSE_FILTER_STOP` when reading or showing a choice, `IGNORE` on action steps;
  - motion: fade `T.COACH_FADE` and move `T.MOVE` unless `Settings.reduced_motion()`, in which case no tween.
- [X] T013 Wire the tutorial into `ui/main.gd` (contracts/tutorial-flow.md):
  - fields `tutorial` (null when no lesson) and `_coach`, a CoachMark added in `_ready` between `_flight` and `_overlays`;
  - `start_lesson(i)` for lessons with a challenge table, as "start_lesson(i)" in the contract (Lesson 1's dragon screen arrives in T018);
  - `_show_coach()`:
    - when `tutorial` is set, the animator is idle and no lesson is finished: compute the rect via `play.coach_rect(step.target)`, then call `_coach.show_step`;
    - call it after `_on_sequence_done`, after every `dispatch` that changes the draft (also call `tutorial.draft_changed(draft)` there), and from `apply_layout`;
  - gate calls before each engine commit:
    - `_on_primary`: setup, play, soak, and `upgrade` (with `draft.picks`) before `_confirm_unspent_xp`. This is the only Upgrade gate: `_finish_upgrade` applies the picks and runs `_act(finish)` without a second check;
    - `_confirm_mode` for divert;
    - `_on_action("fuse")` as `fuse_begin`;
    - the `fuse_element` intent as `fuse_element` with `draft.fuse`.

    A non-empty answer calls `_refuse(hint, "", "Lesson")` and returns.
  - after a successful `_act`, call `tutorial.acted(kind)`, where an `_act` of kind `finish` reports `upgrade` (the Upgrade Phase's confirm is one step); on `_on_sequence_done`, call `tutorial.sequence_done()`;
  - `_save_marker()` and `_record()` return at once while `tutorial` is set (FR-019);
  - `_coach` signals:
    - `next`/`back` call the tutorial and `_show_coach()`;
    - `skip` dispatches `lesson_leave`;
    - `term` opens the glossary popover through the existing `help` path;
  - intents `lesson_leave` (detach the tutorial, `_coach.hide_mark()`, `_show_title()`), `lesson_next` and `lesson_list` (stubs until US8);
  - the in-game menu's Leave during a lesson dispatches `lesson_leave` with no confirm dialog;
  - lesson complete: when `tutorial.finished()`, append the id to `Settings.lessons` if absent, call `Settings.save_all()`, and show `_coach.show_choice("Lesson N complete", [Next lesson, Leave])`.
- [X] T014 In `tools/ui_check.gd`:
  - at start, call `Settings.use_path("user://tool_settings.cfg")` beside the existing `HistoryStore.use_empty`;
  - include `ui._coach`'s visible descendants in `_inspect_screen`;
  - add `_coach_checks(where)`: the bubble is inside the view and the safe area; the rim contains `play.coach_rect(step.target)` unless it is empty; the bubble does not overlap the rim;
  - add the scaffold of a new `lessons` walk, registered in `_run` as `if _want("lessons")` at phone-16x9 in quick mode and at every size in full mode, plus reduced motion at phone-16x9;
  - add a helper `_play_lesson(i, where, wrong := true)`. It starts the lesson with `ui.start_lesson(i)` and follows the steps:
    - Next for read steps;
    - for action steps, the presses a player makes (`card` taps, `put`, `set_boost_to`, `action`, `fuse_element`, `primary`) built from `expect`;
    - after `_settle()` at each step, `_coach_checks`;
    - with `wrong`, once per lesson, a deliberately wrong commit first, asserting a refusal card titled "Lesson" (`deck.pile.kinds()` contains `"refusal"`);
  - at the end of the walk, assert the HistoryStore record count and marker are unchanged.

  Add `lessons` to the walk lists in the header comments of `tools/ui_check.gd` and `tools/test.sh`.

**Checkpoint**: run `tools/test.sh unit game tutorial lessons` and `tools/test.sh ui lessons` (the walk has no lessons with steps yet, so it only starts and leaves one).

---

## Phase 3: User Story 1 - Lesson 1: set out with Rodving (Priority: P1) 🎯 MVP

**Goal**: Learn to Play on the landing page leads to the dragon screen with only Rodving open, then to the setup table, where only Destruction is accepted (FR-001–FR-003, FR-008–FR-010).

**Independent Test**: Press Learn to Play on a fresh install. Only Rodving can be chosen, Continue skips the difficulty screen, the same five cards are offered, Destruction is lit, another pick is refused, and Destruction completes the lesson.

- [X] T015 [P] [US1] In `tests/test_lessons.gd`, add `test_setting_out`: `_follow(0)` ends with `phase == "challenge"`, `cards["DOE-A03"].level == 3`, and every other card at Level 2; `setup_offer == [A03, A06, A12, A15, A16]` sorted.
- [X] T016 [US1] In `ui/model/lessons.gd`, write Lesson 1's steps from contracts/lessons.md "Lesson 1", in this project's own words with `[[term]]` links. Step 4's `expect` is `{"picks": ["DOE-A03"]}`, with the hint "Choose Destruction: it is the one that fights." Step 2's target is `dragon:rodving` and its `wait` is `dragon`.
- [X] T017 [P] [US1] In `ui/screens/title_screen.gd`, add a "Learn to Play" `UI.button(…, "normal", icon)` to the How to Play / Leaderboard / Glossary row. It emits `{"type": "lessons"}`. If the row does not fit at phone-small with `T.TAP_MIN` and `T.TEXT_MIN` (the `screens` walk decides), give Learn to Play its own full-width row under Play instead.
- [X] T018 [US1] In `ui/screens/dragon_screen.gd`, add `var lesson := false`, set through `setup(db, menu, lesson := false)`:
  - in lesson mode, `options.dragon = "rodving"`;
  - every other tile is locked through the existing `tile.locked` path, its flavour line replaced by "The lessons are played against Rodving.";
  - `_choose` ignores them;
  - Continue emits `{"type": "lesson_setup"}`;
  - `back()` emits `lesson_leave`;
  - add `func coach_rect(target)` for `dragon:<id>` (the tile's global rect) and `screen`.

  Do not touch `Settings.unlocked`.
- [X] T019 [US1] In `ui/main.gd`:
  - `start_lesson(0)` shows the dragon screen in lesson mode with the tutorial attached;
  - `_show_coach` resolves rects from the current screen's `coach_rect`;
  - the `dragon` gate passes on Continue with Rodving, and the `lesson_setup` handler calls `tutorial.acted("dragon")`;
  - the `lessons` intent calls `start_lesson(0)` when `Settings.lessons` is empty (FR-003). The list for later visits comes in US8; until then it calls `start_lesson(Tutorial.first_unfinished(Settings.lessons))`;
  - the `lesson_setup` intent builds the Game, stages Lesson 1's table, and opens the play screen in setup with no start sequence (as `start_game` does when the phase is `setup`).
- [X] T020 [US1] In `ui/main.gd`, add the first-launch offer (contracts/tutorial-flow.md "First-launch offer").
  - On the title's Play intent, when `HistoryStore.records.is_empty() and Settings.lessons.is_empty() and not Settings.tutorial_offered`, open a `ConfirmDialog` with the text "New to Etchinstone? Learn to Play takes about ten minutes." and the buttons **Learn to Play** / **Play**.
  - Either answer, or closing the dialog, sets `Settings.tutorial_offered = true` and calls `Settings.save_all()`.
- [X] T021 [US1] In `tools/ui_check.gd`:
  - in the `lessons` walk, play Lesson 1 through `ui.dispatch({"type": "lessons"})`;
  - assert the three other dragon tiles are locked and their line is the lesson line;
  - assert Continue lands on the play screen in `setup` with the offer above;
  - make a wrong pick, which must be refused;
  - make the right pick, and assert `Settings.lessons == ["setting_out"]` in the tool settings;
  - FR-009: assert the rules (difficulty) screen was never shown, that `ui.game.options` has no alternate rule on, and that `Settings.last_options` is unchanged;
  - in the `screens` walk, assert the first-launch dialog appears on Play with empty records and progress, and not a second time.

  Run `tools/test.sh ui lessons screens`.

**Checkpoint**: run `tools/test.sh`. US1 is the MVP: a new player can enter the tutorial and set out.

---

## Phase 4: User Story 2 - Learn the table: Key Card, Ether, the Encounter and the Deck (Priority: P1)

**Goal**: Lesson 2 opens with a lit tour of the play screen, with Back and Glossary links (FR-011, FR-012, FR-015).

**Independent Test**: Open Lesson 2 and step through the first eight messages. Each lights its target with the rest dimmed, Back returns the previous message and light, and a `[[term]]` opens the Glossary with the message still there when it closes.

- [X] T022 [US2] In `ui/model/lessons.gd`, write Lesson 2's steps 1–8 from contracts/lessons.md "Lesson 2" (targets `deck`, `key`, `encounter`, `ether:DOE-A03`, `place:0/spell`, `place:reserve`, `chip:initiative`, `aim`). Step 5 is `arrange` with `expect {"places": {"0/spell": "DOE-A03", "0/boost": "DOE-A06"}}`.
- [X] T023 [US2] Make the `key` target lightable. When a step's target is `key`, `main._show_coach` raises the Key Card through the Deck's existing look/raise path (deck_stack.gd's reveal raise) and lowers it when the step changes. `deck_stack.key_strip_rect()` (T010) then returns a non-empty rect. If raising cannot be held cleanly, follow plan.md "Risks": change step 2's target to `deck`, and record that in Notes.
- [X] T024 [US2] In `tools/ui_check.gd`'s `lessons` walk, play Lesson 2's steps 1–8 and check:
  - each step's rim contains its target node's rect (`_coach_checks`);
  - Back from step 3 shows step 2's text and target;
  - pressing the coach bubble's first meta link opens a glossary popover in `_overlays`, and closing it leaves the same step shown;
  - during a read step a tap on a Hand card changes nothing (the draft is unchanged).

  Run `tools/test.sh ui lessons`.

---

## Phase 5: User Story 3 - Lesson 2: win a fight (Priority: P1)

**Goal**: The guided Victory, the Upgrade and Cleanup (FR-007 Lesson 2, FR-013, FR-014).

**Independent Test**: Follow Lesson 2 to the end: an unswapped commit is refused, the swap and commit give Victory 11 against 11 with no damage, Rain of Blood is Upgraded, and Cleanup leaves four cards in Hand.

- [X] T025 [P] [US3] In `tests/test_lessons.gd`, add `test_victory`:
  - the guided action previews as `outcome == "complete"`, `attack == 11`, `early == false` and `damage == 0`;
  - it is the only complete Action Set over `_all_actions` (count of complete results == 1, counting `boost_to` variants of the same cards as distinct only if both win);
  - `_follow(1)` ends in `challenge` with `hand.size() == 4`, `cards["DOE-A10"].level == 3`, and `hand` containing A10.
- [X] T026 [US3] In `ui/model/lessons.gd`, write Lesson 2's steps 9–13 from contracts/lessons.md:
  - the `play` expect `{"spell": "DOE-A03", "element": "DOE-A14", "boost": "DOE-A06", "boost_to": "attack"}`, with hint "Spell: Destruction. Element: Frostfire Wall. Boost: Fleet Footed, on Attack.";
  - a `sequence` step;
  - a read step on `card:DOE-A10` explaining the Upgrade and unspent XP;
  - `upgrade` `{"picks": ["DOE-A10"]}` on `primary` (the confirm runs the Upgrade and Cleanup), with hint "Upgrade Rain of Blood, once, then confirm.";
  - a `sequence` step for the draw, then the closing read step.

  Quote the figures 10, 2, 1 and 11 as the result line shows them.
- [X] T027 [US3] In `tools/ui_check.gd`, extend the `lessons` walk through Lesson 2:
  - the wrong commit (unswapped) is refused;
  - the swap is done by the `put` intent;
  - in the Upgrade Phase, tap Frostfire Wall and confirm: refused by the gate; tap Frostfire Wall again until its Level is taken back, tap A10 once (Level 3), confirm: accepted;
  - assert `Settings.lessons` gains `"victory"`.

  Run `tools/test.sh ui lessons arrange`.

---

## Phase 6: User Story 4 - Lesson 3: a Narrow Victory on a Journey (Priority: P2)

**Goal**: The Journey compared with a fight, the Narrow Victory, and the Time Penalty shown as the Deck's clock (FR-007 Lesson 3).

**Independent Test**: Follow Lesson 3. It is a Journey, the result is a Narrow Victory 9 against 12, two cards leave the Deck with the clock message lit on it, and the lesson completes.

- [X] T028 [P] [US4] In `tests/test_lessons.gd`, add `test_narrow`:
  - the encounter is a `journey` with index 1;
  - the guided preview is `outcome == "narrow"`, `move == 9`, `time_penalty == 2`;
  - `_best(g, true) == "narrow"`;
  - after `play`, `deck.size()` dropped by exactly 2.
- [X] T029 [US4] In `ui/model/lessons.gd`, write Lesson 3's steps from contracts/lessons.md "Lesson 3" (the `play` expect `{"spell": "DOE-A09", "element": "DOE-A01", "boost": "DOE-A13", "boost_to": "attack"}`). The `deck` step after the play is `sequence` (it waits for the Time Penalty to be paid) and covers `time_penalty` and `deck_clock`. Its closing step is `upgrade` with `expect {}`, which accepts any Upgrade or none (data-model.md `upgrade` row).
- [X] T030 [US4] In `tools/ui_check.gd`, extend the `lessons` walk through Lesson 3, with one wrong commit (Boost and Element swapped). Assert the Deck shows two fewer cards after the play settles, and that the step lit on the Deck is shown after the sequence. Run `tools/test.sh ui lessons`.

---

## Phase 7: User Story 5 - Lesson 4: a Loss, and Soaking the damage (Priority: P2)

**Goal**: An unwinnable Encounter, Soak, Armor, Downgrade, Trash, and that Divert exists (FR-007 Lesson 4, FR-014).

**Independent Test**: Follow Lesson 4. The result is a Loss 6 against 13 with 3 damage, Soaking with Brute Force is refused, and Soaking with Fleet Footed settles it and Downgrades Fleet Footed to Level 1.

- [X] T031 [P] [US5] In `tests/test_lessons.gd`, add `test_loss`:
  - the encounter is an `enemy` with index 4;
  - `_best(g, true) == "loss"`;
  - the guided preview is `attack == 6`, `damage == 3`, `early == false`;
  - after `play`, `phase == "penalty"` and `damage_due == 3`;
  - `soak(["DOE-A01"])` is refused (Armor 2 < 3);
  - `soak(["DOE-A06"])` returns "" and leaves `cards["DOE-A06"].level == 1`;
  - `_follow(3)` ends in `challenge`.
- [X] T032 [US5] In `ui/model/lessons.gd`, write Lesson 4's steps from contracts/lessons.md "Lesson 4":
  - the `play` expect `{"spell": "DOE-A13", "element": "DOE-A06", "boost": "DOE-A01", "boost_to": "attack"}`;
  - a read step on the `hand` target that names each card's Armor (River Swiftness 2, Fleet Footed 3, Adapt 2, Brute Force 2) and says Armor of the damage's Ether counts double (US5 scenario 3);
  - `soak` `{"picks": ["DOE-A06"]}`, with hint "Soak with Fleet Footed.";
  - a closing `upgrade` `{}` step;
  - concepts `outcomes`, `divert`, `soak`, `armor`, `downgrade` and `trash`.

  Divert stays refused by the gate ("Not in this lesson.").
- [X] T033 [US5] In `tools/ui_check.gd`, extend the `lessons` walk through Lesson 4:
  - pressing Divert is refused with "Not in this lesson.";
  - a Soak pick of Brute Force is refused by the gate;
  - Fleet Footed is accepted;
  - the Soak meter is lit on the `soak` step and the Hand well on the Armor step (`_coach_checks`).

  Run `tools/test.sh ui lessons divert`.

---

## Phase 8: User Story 6 - Lesson 5: Fuse two cards to win (Priority: P2)

**Goal**: The guided Fuse wins what no plain Action Set can (FR-007 Lesson 5, FR-013).

**Independent Test**: Follow Lesson 5. Committing without a Fuse is refused, Fusing as water is refused, and Fusing Sword of Light over Destruction as fire gives Victory 10 against 9. After Cleanup both Fused cards are in the discard pile.

- [X] T034 [P] [US6] In `tests/test_lessons.gd`, add `test_fuse`:
  - the encounter is an `enemy` with index 3;
  - `_best(g, false) == "narrow"` and `_best(g, true) == "complete"`;
  - the only complete actions over `_all_actions` all carry `fuse == {top: A02, bottom: A03, element: fire}` with Spell A05;
  - the guided preview is `attack == 10`, `early == false`;
  - after `_follow(4)`, `discard` contains both A02 and A03.
- [X] T035 [US6] In `ui/model/lessons.gd`, write Lesson 5's steps from contracts/lessons.md "Lesson 5":
  - the `card:DOE-A02+DOE-A03` read step;
  - `fuse_begin` on `action:fuse`;
  - `fuse_element` on `picker`, `{"top": "DOE-A02", "bottom": "DOE-A03", "element": "fire"}`, with hint "Fuse Sword of Light over Destruction, as fire.";
  - the `play` expect with that `fuse`;
  - a `sequence` step for the result, then an `upgrade` `{}` step covering `cleanup`, whose text says both Fused cards are discarded.
- [X] T036 [US6] In `ui/main.gd`, make the Fuse gate exact:
  - `_on_action("fuse")` while `tutorial` is set calls `check("fuse_begin", {})`;
  - the `fuse_element` intent calls `check("fuse_element", {top, bottom, element})` before it is applied;
  - a refusal leaves `draft.mode` as it was, so the player can choose again;
  - outside Lesson 5 the Fuse button is refused by the gate.
- [X] T037 [US6] In `tools/ui_check.gd`, extend the `lessons` walk through Lesson 5:
  - commit without a Fuse: refused;
  - Fuse the right pair as water: refused;
  - Fuse as fire, then commit: the result settles to Victory;
  - assert the picker is lit on its step.

  Run `tools/test.sh ui lessons`.

---

## Phase 9: User Story 7 - Lesson 6: the Deck runs low and the Region ends (Priority: P2)

**Goal**: A staged late-Region table where Cleanup ends Region 1 and Region 2 is dealt (FR-007 Lesson 6).

**Independent Test**: Follow Lesson 6. The Deck shows one card, the Victory is 8 against 8, Finish ends the Region, and Region 2 is set out with four cards in Hand, twelve in the Deck, and Levels kept.

- [X] T038 [P] [US7] In `tests/test_lessons.gd`, add `test_region_end`:
  - the staged `deck.size() == 1` and `discard.size() == 11`;
  - the guided preview is `outcome == "complete"`, `move == 8`;
  - after `play` and `finish()`: `region == 2`, `hand.size() == 4`, `deck.size() == 12`, `discard.is_empty()`, and every card's Level unchanged.
- [X] T039 [US7] Make a staged start with a partly used Deck draw correctly (plan.md "Risks"). Start Lesson 6 in `tools/ui_check.gd` and call `_settle()`, then compare the Deck's drawn count and the header's discard pile with the staged table.
  - If the start sequence assumes a full Deck, fix it in `ui/model/sequencer.gd`'s `start` build: deal from the staged `deck`, and show the staged `discard` without animating it in.
  - Cover the fix in `tests/test_sequencer.gd`, with a `start` step built from a snapshot whose discard is non-empty.

  Run `tools/test.sh unit sequencer deck_stack` and `tools/test.sh ui lessons skip`.
- [X] T040 [US7] In `ui/model/lessons.gd`, write Lesson 6's steps from contracts/lessons.md "Lesson 6" (the `play` expect `{"spell": "DOE-A13", "element": "DOE-A10", "boost": "DOE-A01", "boost_to": "attack"}`). Its confirm is an `upgrade` `{}` step. The `deck` step after it is `sequence`: it waits for the Region change and covers `region_end`.
- [X] T041 [US7] In `tools/ui_check.gd`, extend the `lessons` walk through Lesson 6. Assert the Region Card shows Region 2 after the change settles, that the coach mark is shown only after the Region change sequence ends, and that `Settings.lessons` holds all six ids. Run `tools/test.sh ui lessons`.

---

## Phase 10: User Story 8 - Finish the tutorial (Priority: P3)

**Goal**: Lesson-complete choices, the summary, the lesson list, resuming at the first unfinished lesson, and replaying finished ones (FR-003, FR-003a, FR-017, FR-018).

**Independent Test**: Finish Lesson 6, then:
- the summary shows, and Leave marks the tutorial completed;
- Learn to Play opens the list with all six Done, and any can be replayed;
- leaving a replay half way keeps its mark.

With only some lessons done, Learn to Play's Continue opens the first unfinished lesson, and later lessons are not yet open.

- [X] T042 [P] [US8] Create `ui/screens/lessons_screen.gd` (built in code like `records_screen.gd`; `signal intent(data)`, `heading`, `apply_layout(rect)`, `back()`; `##` header citing specs/017 contracts/tutorial-flow.md "Lesson list"):
  - one row per lesson: its number and title, a Done mark (icon + the word), and either a button (open) emitting `{"type": "lesson", "index": i}` or a dimmed row with "Finish Lesson N first";
  - a primary button "Continue: Lesson N", or "Start again" when all are done, emitting the matching `lesson` intent;
  - every control at least `T.TAP_MIN` and every text at least `T.TEXT_MIN`;
  - it reads `Settings.lessons` and `Tutorial.is_open`, and nothing else.
- [X] T043 [US8] In `ui/main.gd`:
  - the `lessons` intent starts Lesson 1 when no lesson is finished, otherwise shows `lessons_screen`;
  - the `lesson` intent calls `start_lesson(i)` only if `Tutorial.is_open(i, Settings.lessons)`;
  - `lesson_list` shows the list;
  - `lesson_next` calls `start_lesson(i + 1)`, or after the sixth lesson shows the summary through `_coach.show_choice` (text from `Lessons.SUMMARY`, buttons Leave and Lessons) and sets `Settings.tutorial_done = true` and saves;
  - the lesson-complete choice gains a **Lessons** button and reads **Finish** after the sixth;
  - replaying a finished lesson never removes it from `Settings.lessons`.
- [X] T044 [P] [US8] In `ui/model/lessons.gd`, add `const SUMMARY`: what the lessons covered, and what a full game holds (four Regions, then the Final Journey and the Final Enemy, the dragon), with `[[term]]` links. Add `test_summary_terms` to `tests/test_lessons.gd`, checking every `[[term]]` in it is `Glossary.has()`.
- [X] T045 [US8] In `tools/ui_check.gd`:
  - in the `lessons` walk, after Lesson 6, press Finish: the summary shows and `Settings.tutorial_done` is true;
  - press Leave, then `lessons`: the list shows six Done marks;
  - replay Lesson 4, then `lesson_leave` half way: still six Done;
  - with the tool settings reset to `["setting_out", "victory"]`, `lessons` shows the list, Continue is Lesson 3, and the rows of Lessons 4–6 are not open;
  - in the `screens` walk, `_inspect_screen` the lesson list at every size.

  Run `tools/test.sh ui lessons screens` and `tools/test.sh ui full lessons screens`.

**Checkpoint**: run `tools/test.sh`. Every story is done.

---

## Phase 11: Polish & Cross-Cutting Concerns

- [X] T046 In `tests/test_lessons.gd`, add `test_concepts_covered`: the union of every step's `concepts` equals `Lessons.CONCEPTS` (SC-004). Fill any gap with a step or a concept tag in `ui/model/lessons.gd`.
- [X] T047 [P] In `tools/shot.gd`, add lesson shots at every size: Lesson 2 step 2 (the Key Card, a read step), Lesson 2 step 9 (an action step), Lesson 4's Soak step, Lesson 5's picker step, the summary and the lesson list. Look at them with `godot --path . -s tools/shot.gd -- build/screenshots/matrix`, and split any message that crowds the smallest phone into two steps.
- [X] T048 [P] Update `README.md`:
  - add a Status bullet for Learn to Play: six lessons on the real screens, Rodving only, never recorded;
  - add `lessons` to the list of UI check walks.
- [X] T049 [P] Update `CLAUDE.md`:
  - add a `lessons` row to the "UI check walks" table ("The six lessons through the screens: the coach mark, the gate's refusals, the list, no records");
  - add a "Tutorial lessons, coach mark" row to the "Unit tests by area" table, running `lessons tutorial game`;
  - add `lessons` to the "Pick the walks" sentence for changes to `ui/model/lessons.gd`, `tutorial.gd` or `coach_mark.gd`.
- [X] T050 Run `tools/test.sh full`. Then walk quickstart.md "By eye" in `godot --path .` on a fresh `user://`, and record anything that reads badly under Notes, with the step it applies to.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on Setup and blocks every story.
  - T004 depends on T003.
  - T008 depends on T006 and T007.
  - T009 depends on T004 and T007.
  - T011 depends on T010.
  - T013 depends on T004, T005, T008, T011 and T012.
  - T014 depends on T013.
- **US1 (Phase 3)**: depends on Foundational.
- **US2 (Phase 4)**: depends on Foundational. Its steps live in Lesson 2, which also holds US3's steps, so write US2's steps first.
- **US3 (Phase 5)**: depends on US2's steps (T022).
- **US4, US5, US6, US7**: each depends only on Foundational and can be done in any order, or in parallel by lesson. T036 (the Fuse gate) belongs to US6 alone. T039 (staged start with a discard pile) belongs to US7 alone.
- **US8 (Phase 10)**: depends on Foundational. Its walk (T045) runs after the other lessons' walks exist.
- **Polish (Phase 11)**: after the stories wanted.

### Within Each Story

The test row ([P]) comes first, then the lesson's steps in `lessons.gd`, then any `main.gd` or widget change, then the walk segment.

### Parallel Opportunities

- Phase 2: T002, T003, T005, T006 and T010 touch different files.
- Each story's `tests/test_lessons.gd` row is written before its steps. Two people on two stories both edit `lessons.gd` and `test_lessons.gd`, so either take turns on those files or merge by lesson block.
- T042 and T044 (US8) run alongside T043's main changes.
- Phase 11: T047, T048 and T049.

---

## Parallel Example: Foundational

```text
Task: "T002 Coach tokens in ui/theme/tokens.gd"
Task: "T003 stage() tests in tests/test_game.gd"
Task: "T005 Settings progress and path override in ui/model/settings.gd"
Task: "T006 Tutorial model tests in tests/test_tutorial.gd"
Task: "T010 Key strip and Ether getters in deck_stack.gd and card_view.gd"
```

## Parallel Example: Lessons 3–6 after Foundational

```text
Task: "T028 [US4] test_narrow"      then T029, T030
Task: "T031 [US5] test_loss"        then T032, T033
Task: "T034 [US6] test_fuse"        then T035, T036, T037
Task: "T038 [US7] test_region_end"  then T039, T040, T041
```

---

## Implementation Strategy

### MVP first (User Story 1)

1. Phase 1 and Phase 2.
2. Phase 3 (US1): Learn to Play, Rodving only, the guided setup.
3. **Stop and validate**: `tools/test.sh`, and the US1 independent test by eye.

### Incremental delivery

1. US2 + US3 (Lesson 2): the table tour and the first Victory. This is the core of the tutorial.
2. US4, US5, US6, US7: one lesson each, each shippable on its own.
3. US8: the list, the summary and resuming.
4. Polish: concept coverage, shots, documents, the full run.

---

## Notes

- **T001 baseline** (2026-10-21): 381 unit tests, 1 failing before this feature: `test_glossary.gd::test_every_game_icon_has_an_entry` (the `lock` icon, from the dragon-unlock commit, has no Glossary entry). UI check quick: 38277 checks, 0 failed. Left as found.
- **T023**: the Key Card is not held raised. `key` lights the reading strip under the landed Encounter, which names the Encounter and its Hardship (contracts/coach-mark.md updated).
- **T039**: no Sequencer change was needed: a staged start with cards in the discard pile settles to the staged table in the `lessons` walk.
- **Lesson 1's offer** changed from research R1's first draft: A10 Rain of Blood (Attack 11 at Level 3) is replaced by A16 Motivated Flight, so Destruction is the only card on offer that fights and the recommendation is plainly right.
- **Lesson 6** stages two cards in the Deck, not one: with one, the disabled Divert's reason "No other Key Card" wraps and the button outgrows its cell on a tablet. That is a layout bug outside this feature (a real game reaches it at a Region's end); it is reported, not fixed here.
- **Sequence steps** show no mark while their animation plays, so what is said about it is a read step after (contracts/lessons.md).
- **Owner review mid-implementation**: on action steps the dimming covered the button to press while the bubble showed Skip and Back. Action steps now dim nothing, rim the target and the button that makes the move, and offer only Skip (contracts/coach-mark.md).
- **Fuse uniqueness** (T034): Destruction on top as the fire Element also wins, but takes Early Damage; the guided Fuse is the only one that wins unhurt, which is what the test asserts.
- **Tools**: every tool that loads the main scene now calls `Settings.use_for_tools()`, so none meets the first-launch offer or writes the player's settings.
- **Owner report after implementation**: replaying Lesson 1 from the list showed no message and Continue could not be pressed. The step was shown twice in one frame; the second show's glide killed the first's fade in, leaving the mark see-through while its dimming still caught presses. Fade and glide are now separate tweens, a step already shown is not shown again, and the `lessons` walk replays Lesson 1 in real time (it fails on the old code).
- **Line endings**: files edited by script were checked for CRLF and kept LF.
