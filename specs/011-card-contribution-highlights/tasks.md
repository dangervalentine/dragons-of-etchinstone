---

description: "Task list for 011 Card Contribution Highlights"
---

# Tasks: Card Contribution Highlights

**Input**: Design documents from `specs/011-card-contribution-highlights/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/card-marks.md](contracts/card-marks.md), [contracts/left-box.md](contracts/left-box.md), [quickstart.md](quickstart.md)

**Tests**: Included. The project tests every pure model headless and every screen in `ui_check` (plan, Constitution Check). Research R8 lists the tests to change.

**Organization**: Tasks are grouped by user story (spec.md US1–US5).
- **Order:** the three P1 stories run in dependency order, not spec order: US3 (aim on the card), then US2 (what counts), then US1 (free the box). Emptying the box before the aim and the lift live on the cards would remove the only Boost aim and the only view of what counts, a regression FR-006 forbids.
- **Units:** every figure is in design units.
- **Check:** run `tools/test.sh` after each phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story the task belongs to (US1–US5)

---

## Phase 1: Setup

- [X] T001 Run `tools/test.sh` on the unchanged tree and confirm it is green, so later failures are this feature's.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: The focus model gains the inputs and fields every story uses (data-model.md "Card focus"), and the card face gains a way to draw marks beside a region (research R3).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 In `ui/model/emphasis.gd`, extend `context(game, draft)` with:
  - `terms`: the `terms` array of the explain dictionary;
  - `effects`: the Encounter's effects list;
  - `give_up_reserve`: `draft.give_up_reserve`;
  - `boost_to`: `draft.boost_to.duplicate()`;
  - `enemy`: true when phase is `final_enemy`, or phase is `challenge` with an Enemy encounter.

  Pass the explain and the effects in through a new optional parameter, `context(game, draft, e := {}, effects := [])`, so the existing callers and tests keep working. Extend `focus(...)`'s return dictionary to always include `"impacts": []` and `"aim": null`.
- [X] T003 In `ui/model/view_state.gd`, call `Emphasis.context(game, draft, vs.explain, vs.encounter.effects if vs.encounter != null else [])` at the existing call site (around line 80), after `vs.explain` is set.
- [X] T004 [P] In `ui/widgets/card_face.gd`, add `func mark_rects(region: String, count: int) -> Array`. It returns `count` squares of side `roundf(row * 0.72)`, vertically centred on `region_rect(region)`, set left to right from `region_rect(region).end.x + gap`, `gap` apart, clamped inside the field (research R3).
- [X] T005 In `ui/widgets/card_face.gd`, draw `_focus.marks`, a list of `{region, icon, colour}` built from the focus's `aim` and `impacts`: aim first, then impacts, per region. Each mark is a disc of `T.BG_BASE` at 0.85 alpha and the icon inside it at 70% of the disc. Store `aim` and `impacts` in `set_focus` alongside `regions`, so a change fades with the existing `_focus_t`. Draw nothing when both are empty.
- [X] T006 [P] Add a test to `tests/test_card_face_layout.gd`: for every `layout_solver.MATRIX` shape's Region and Final Battle card sizes, two `mark_rects` beside `boost`, one beside `initiative` and one beside `enhanced` lie inside the card, overlap no `region_rect` of the stat column (`initiative`, `basic`, `enhanced`, `boost`, `armor`), and are each ≥ 16 on a side.

**Checkpoint**: `tools/test.sh` is green. Nothing visible has changed yet.

---

## Phase 3: User Story 3 — Aiming the Boost on its card (Priority: P1) 🎯 MVP part 1

**Goal**: Against an Enemy, each Boost card carries an aim mark and an 88-tall aim zone along its bottom edge. A tap there cycles unset → Attack → Initiative → Attack (research R4). Play waits until every Boost is aimed.

**Independent Test**: Against a Region Enemy and in the Final Enemy, aim each Boost by tapping its card's bottom band and by `B`. Check the mark, `draft.boost_to`, and Play's gating. Then tap the card's top half and drag it, and check that it swaps without changing the aim.

### Tests for User Story 3

- [X] T007 [P] [US3] In `tests/test_turn_draft.gd`, add `test_cycle_boost_to`: null → "attack" → "initiative" → "attack", per set, without touching the other set's `boost_to`. Replace `test_which_boost_a_row_tap_aims` with `test_keyboard_aims_the_held_or_first_unaimed_boost` (`boost_target_set` unchanged). Keep `test_a_swap_keeps_the_boost_aim`.
- [X] T008 [P] [US3] In `tests/test_emphasis.gd`, add `test_boost_card_carries_its_aim`:
  - against a Region Enemy, the card in the Boost position has `focus.aim == {"to": null}`, then `{"to": "attack"}` after `cycle_boost_to(0)`;
  - in the Final Enemy, each set's Boost card carries its own set's aim;
  - on a Journey and the Final Journey, `aim == null`;
  - during `fuse_pick`, `aim == null`.

### Implementation for User Story 3

- [X] T009 [US3] In `ui/model/turn_draft.gd`, add `cycle_boost_to(set_index)`. It sets `boost_to[set_index]` to "attack" when null or "initiative", else "initiative". Make `toggle_boost_to` call it.
- [X] T010 [US3] In `ui/model/emphasis.gd` `focus(...)`, set `aim = {"to": ctx.boost_to[i]}` when `ctx.enemy`, `ctx.mode == "none"`, and the card's `role` is `[i, "boost"]`.
- [X] T011 [US3] In `ui/widgets/card_face.gd`, build the aim mark for region `boost`:
  - icon `attack` or `initiative` in `T.INK` when aimed;
  - while unaimed, a `?` glyph in `T.GOLD` drawn with the face's numeral font on the same disc, so the unset state is a shape, not only a colour.
- [X] T012 [US3] In `ui/widgets/card_view.gd`:
  - add `signal aim_tapped(id: String)`;
  - add `func aim_rect() -> Rect2`, which returns `Rect2(0, size.y - T.TAP_MIN, size.x, T.TAP_MIN)` when `model.get("focus", {}).get("aim") != null`, else `Rect2()`;
  - in `_gui_input`, record whether the press was inside `aim_rect()`. On a release that is neither a drag nor a hold, emit `aim_tapped(id)` instead of `tapped(id)` when both press and release are inside it;
  - leave drags, holds and right-clicks unchanged;
  - in `part_icon`/`part_help`, give the zone the tooltip "Tap to aim the Boost at Attack or Initiative.".
- [X] T013 [US3] In `ui/screens/play_screen.gd`, forward each hand card's `aim_tapped` the way `tapped` is forwarded (as an intent `{"type": "aim_card", "id": id}`). In `ui/main.gd`, handle `aim_card`:
  - `var slot = draft.slot_of(id)`; if `slot != null and slot[1] == "boost"`, call `draft.cycle_boost_to(slot[0])`;
  - put down any held card, `Haptics.tap()`, `_refresh()`.

  Make the `KEY_B` branch call `cycle_boost_to` (via `toggle_boost_to`).
- [X] T014 [US3] In `tools/ui_check.gd`, replace the math-box aim-row checks (around lines 934–969) with aim-zone checks at every `MATRIX` shape, Region Enemy and Final Enemy:
  - each Boost card's `aim_rect()` is ≥ `T.TAP_MIN` tall, inside the card, ≤ 50% of card height, and contains the `boost` plate's centre;
  - simulated taps in the zone give attack, then initiative;
  - a simulated tap above the zone picks the card up, and `boost_to` is unchanged;
  - Play is disabled until every Boost is aimed.

  Change the `_press({"type": "aim_boost", ...})` calls (around lines 259 and 306) to `{"type": "aim_card", "id": <the Boost card>}`.

**Checkpoint**: the Boost can be aimed from its card. The box's aim rows still work too, until US1 removes them.

---

## Phase 4: User Story 2 — The cards show what counts (Priority: P1) 🎯 MVP part 2

**Goal**: Building cards lift exactly the regions the engine counts, read from the explain terms (research R1, contracts/card-marks.md "Lift").

**Independent Test**: The emphasis table test passes for every row of contracts/card-marks.md "Lift", against `game.explain` / `game.explain_final`.

### Tests for User Story 2

- [X] T015 [P] [US2] In `tests/test_emphasis.gd`, add `test_lift_matches_the_engine_terms`, a table test over arrangements that covers every row of contracts/card-marks.md "Lift":
  - Region Enemy, Slow Enemy, Region Journey (Reserve counting and not), Final Journey and Final Enemy;
  - a Spell enhanced, basic, and "counts as 1";
  - a Boost aimed at Attack and at Initiative;
  - a Boost card of value 0;
  - an unplaced Element.

  For each placed card, assert `focus.regions` equals the regions derived by hand from the terms (data-model.md table). Update `test_placed_cards_focus_on_their_role` and `test_placed_spell_shows_the_action_in_effect` to the new rules: an Element on a Journey lifts only `ether`. Keep `test_reserve_boost_only_when_it_counts` passing.

### Implementation for User Story 2

- [X] T016 [US2] In `ui/model/emphasis.gd`, rewrite `_building` for cards with a `role` (and for the Reserve) to read `ctx.terms`, per data-model.md "regions, from the explain terms":
  - **Spell** term (label "Spell" or "Spell N"): `enhanced` when its note starts with "enhanced"; `basic` when the term exists and its note does not start with "counts as 1"; none otherwise. With no Element placed in that set, return `["basic", "enhanced"]`.
  - **Element**: `["ether"]`, plus `initiative` when an `Element` term for its set has `sum == "initiative"`.
  - **Boost**: `["boost"]` when a `Boost` term for its set exists, else `[]`.
  - **Reserve**: `["boost"]` when a term with `source == "reserve"` exists.

  Match set indices from the label suffix, as `game._note_cards` does. When `ctx.terms` is empty (the engine refused the set), keep today's role table, so a blocked set still shows its roles. Leave the `fuse_pick`, `fuse_element`, `divert`, `regroup` and unplaced-card branches unchanged. Remove `reserve_counts` from `context` once nothing reads it.
- [X] T017 [US2] In `ui/widgets/card_view.gd`, keep the Reserve's dashed outline gold and its "+N" ribbon only when the Reserve's `focus.regions` has `boost`. Set `reserve_boosts` in `ui/model/view_state.gd` from that, not from the old flag.

**Checkpoint**: the lift matches the engine everywhere. The box still shows its rows.

---

## Phase 5: User Story 1 — The math box space is freed (Priority: P1) 🎯 MVP part 3

**Goal**: Before Play the box shows only a step tip. Play never warns. At Play the box shows the sum and verdict as the post-Play summary (research R5, R6; contracts/left-box.md).

**Independent Test**: In each encounter type, with a winning and a losing Hand, the box holds only the tip and Play looks the same. Press Play: the rows appear and count up, then the verdict, then the Upgrade recap.

### Tests for User Story 1

- [X] T018 [P] [US1] In `tests/test_view_state.gd`:
  - add `test_play_never_warns`: with a Hand that Knocks Out the dragon, `vs.prompt.primary.kind` is not `"warning"`;
  - add `test_the_tip_names_the_step`: the `prompt.text` per contracts/left-box.md "Before Play" for Journey, Enemy unaimed and Enemy aimed;
  - replace `test_the_boost_is_aimed_from_the_math_box` and `test_a_journey_has_no_aim` with assertions that `vs.math.sums` carry no `aim` key;
  - keep `test_preview_figures_are_the_engines_and_knock_out_is_predicted`, `test_final_battle_preview_matches_engine_and_flags_defeat` and `test_the_math_box_sums_come_from_the_engine`: `vs.preview` and `vs.math` still feed the summary.
- [X] T019 [P] [US1] Add `tests/test_preview_panel.gd` (`tests/run.gd` picks up every `tests/test_*.gd` itself):
  - `render(vs)` for a ready Region Enemy set adds no total labels, no verdict and no red edge (the panel's stylebox edge is not `T.BAD`), and shows the prompt text;
  - after `reveal(vs.math, vs.preview)`, the rows, totals and verdict exist, and the totals equal `vs.math` totals once `settle()` runs;
  - `needed_height(w)` is the same before and after `reveal`.

### Implementation for User Story 1

- [X] T020 [US1] In `ui/model/view_state.gd`:
  - delete `_aim` and its call;
  - delete `if pv.fatal: p.primary.kind = "warning"`;
  - set `p.text` for the building phases per contracts/left-box.md "Before Play": Enemy with an unaimed Boost → "Tap the bottom of the Boost card to aim it at Attack or Initiative."; otherwise keep today's text;
  - keep the primary `reason` strings.
- [X] T021 [US1] In `ui/widgets/preview_panel.gd`:
  - make `render(vs)` always take the `_prompt` path (eyebrow, text, hint) with the neutral stylebox, and drop the "Still needed" pills and the red edge;
  - remember `vs.math` and `vs.preview` on the panel;
  - add `func reveal(m: Dictionary = {}, p: Dictionary = {}) -> void`, which clears `_box` and builds the summary with today's `_row`, `_note`, `_target_sum` and `_outcome_row` code (fatal colours allowed: it is after Play), using the remembered values when no arguments are given;
  - delete `_aim_row`, `ROW_H_AIM`, `NOTE_H`, `AIM_PAD` and the `aim_boost` intent;
  - set the `HINT` text per contracts/left-box.md;
  - keep `needed_height` sizing for the summary, so the height is unchanged (research R6), including the `_needed` memo;
  - make `play_tally`, `reveal_verdict` and `settle` act only on what `reveal` built.
- [X] T022 [US1] In `ui/fx/animator.gd` `"tally"`: call `screen.preview.reveal()` before `play_tally(d)` while `screen.preview.visible`.
- [X] T023 [US1] In `ui/main.gd`, delete `_aim_boost` and the `aim_boost` intent branch that calls it.
- [X] T024 [US1] In `tools/ui_check.gd` `_check_space` (around lines 121–150), measure the preview zone after calling `play.preview.reveal()` (the summary state, research R6). Restore the tip with `play.preview.render(ui.vs)` afterwards. Add a check that in the tip state the preview shows no `Label` whose text is a total from `vs.math`. In `tools/space_audit.gd` (around line 123), measure the preview after `reveal()`.

**Checkpoint**: MVP. The box is free before Play, and the aim and the lift live on the cards. This is shippable on its own.

---

## Phase 6: User Story 4 — Hardships and Enemy abilities shown where they bite (Priority: P2)

**Goal**: Impact icons beside the affected badges, per contracts/card-marks.md "Impact marks" (research R2).

**Independent Test**: `test_impacts_match_the_contract` passes, and the design shots show each effect's marks.

### Tests for User Story 4

- [X] T025 [P] [US4] In `tests/test_emphasis.gd`, add `test_impacts_match_the_contract`, one case per row of contracts/card-marks.md "Impact marks":
  - Night Travel on Boost `boost` and Element `initiative`, Region and Final Battle;
  - Steep on Reserve `boost`;
  - Ranged on Reserve `boost`, gone once `give_up_reserve` is true;
  - Freeze on Reserve `boost`;
  - Armor on Spell `enhanced` only when an `Armor` term is in the explain.

  Add negative cases: Poison, Ambush, Hazards, Storm and Treacherous give no impacts; an empty Reserve gives none; after a swap the marks are on the incoming card.

### Implementation for User Story 4

- [X] T026 [US4] In `ui/model/emphasis.gd` `focus(...)`, while building with `mode == "none"`, set `impacts` from `ctx.effects`, `ctx.give_up_reserve` and `ctx.terms`, per the contract table:
  - `night_travel` → `{region: "boost", icon: "night_travel"}` on Boost-role cards and `{region: "initiative", icon: "night_travel"}` on Element-role cards;
  - `steep`, `freeze` → `{region: "boost", icon: <effect>}` on the Reserve card;
  - `ranged` → the same, unless `give_up_reserve`;
  - an `Armor` term (label "Armor", `sum == "attack"`) for the card's set → `{region: "enhanced", icon: "armor"}` on that set's Spell.
- [X] T027 [US4] In `ui/widgets/card_face.gd`, include `impacts` in the marks drawn by T005, in `T.INK` on the disc, after the aim mark for the same region.
- [X] T028 [US4] In `tools/ui_check.gd`, for each `MATRIX` shape, open one Encounter per effect (Night Travel, Steep, Ranged, Freeze, Armor). Assert:
  - each affected card's `focus.impacts` matches the contract;
  - every mark rect lies inside its card and overlaps no stat-column `region_rect`.
- [X] T029 [P] [US4] In `tools/design_shots.gd`, add shots `marks_night_travel`, `marks_steep`, `marks_ranged`, `marks_freeze`, `marks_armor` and `aim_unset_attack_initiative`.

**Checkpoint**: every effect that works against a card value is visible on the card and at its source.

---

## Phase 7: User Story 5 — XP spent visibly flows into the card (Priority: P3)

**Goal**: Stars fly from the XP number to each levelled card, undo restores the number with no flight, and leftover XP fades at the end (research R7; contracts/left-box.md "Upgrade").

**Independent Test**: The sequencer tests pass. With 8 XP, a level-up costing 3 flies 3 stars and the number reads 5. Undo reads 8. Finishing with XP left shows the fade.

### Tests for User Story 5

- [X] T030 [P] [US5] In `tests/test_sequencer.gd`, add:
  - `test_an_upgrade_step_carries_the_xp_spent`: the `upgrade` step's `values.spent` equals the XP before minus after;
  - `test_undo_is_a_downgrade_with_no_spend`;
  - `test_finish_with_unspent_xp_adds_xp_lost` (`values.amount` = XP left), and none when XP is 0.

### Implementation for User Story 5

- [X] T031 [US5] In `ui/model/sequencer.gd`:
  - give `_level_steps` the before and after XP and add `spent` to `upgrade` step values;
  - add `"xp_lost": 0.5` to `DURATION`;
  - in the `finish` sequence, append `_step("xp_lost", [], {"amount": before.xp}, "xp")` first when `before.xp > 0`.

  Add `xp` to the snapshots if it is not already in them.
- [X] T032 [P] [US5] In `ui/widgets/xp_purse.gd`, add:
  - `func count_to(n: int, d: float)`: tween the `amount` label's number to `n`, or set it at once under `UI.reduced_motion`;
  - `func fade_out(d: float)`: tween `amount` and its icon to alpha 0.
- [X] T033 [US5] In `ui/fx/animator.gd`:
  - in `"downgrade", "upgrade"`, when `st.kind == "upgrade"` and `st.values.get("spent", 0) > 0`, fly `spent` ghosts `flight.ghost("xp", screen.xp_purse.point(), <card centre>, d, T.GOLD, 28, i * d * 0.08)`, and call `screen.xp_purse.count_to(screen.vs.xp - spent, d)`;
  - add `"xp_lost"`: `screen.xp_purse.fade_out(d)` and `flight.float_text("−%d XP" % st.values.amount, screen.xp_purse.point(), T.INK_MUTED, 30, d * 2.0, "xp")`.

  `screen.vs.xp` is the pre-step value.

**Checkpoint**: all stories work independently.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T034 [P] Update `README.md` lines 28–30. Replace "a preview of the outcome (your totals against the targets, the verdict, and what it will earn and cost)" with a description of:
  - the cards' lifted parts;
  - the Hardship and ability marks;
  - aiming the Boost on its card;
  - the summary shown after Play.
- [X] T035 [P] Add a dated "Superseded in part by 011 (2026-10-17)" note:
  - `specs/001-ui-polish/spec.md`: at the outcome-preview story and SC-002;
  - `specs/006-etched-stone-polish/contracts/math-box.md`: the before-Play display; the box now shows its rows only after Play;
  - `specs/010-legible-hand-cards/spec.md`: at FR-004, FR-010, FR-018–FR-018c, and the assumption that values are read in the preview panel.
- [X] T036 Run `tools/test.sh` and confirm all suites and `ui_check` pass (SC-008). Run `godot --path . -s tools/design_shots.gd -- build/screenshots/011` and review the shots for the tip, the summary, each effect's marks and the aim states.
- [ ] T037 Walk the manual checks in `specs/011-card-contribution-highlights/quickstart.md` on desktop, then on the Android emulator and iOS simulator with the install-on-emulators skill. Watch especially for aim-zone taps landing when a pick-up was meant (plan, Risks).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none.
- **Foundational (Phase 2)**: needs Setup. Blocks every story.
- **US3 (Phase 3)**: needs Foundational.
- **US2 (Phase 4)**: needs Foundational. Independent of US3 and can run alongside it, except that both edit `emphasis.gd` (`focus` vs `_building`), so sequence those two files' tasks.
- **US1 (Phase 5)**: needs US3 and US2. Removing the box's aim rows and predictions before the card aim and the lift exist would regress (FR-006).
- **US4 (Phase 6)**: needs Foundational (marks drawing). Independent of US1–US3.
- **US5 (Phase 7)**: needs only Setup. Independent of every other story (sequencer, purse, animator `upgrade` branch).
- **Polish (Phase 8)**: needs every story it describes.

### Within Each Story

Tests are written first and must fail. Then the model (`emphasis`, `turn_draft`, `sequencer`), then widgets, then wiring (`play_screen`, `main`, `animator`), then tools.

### Parallel Opportunities

- **Phase 2:** T004 and T006 run alongside T002/T003 (different files).
- **US3:** T007 and T008 run in parallel.
- **US2:** T015 can be written while US3's implementation proceeds.
- **US1:** T018 and T019 run in parallel.
- **US4:** T025 and T029 run in parallel.
- **US5:** T030 and T032 run in parallel. The whole of US5 can run alongside US2–US4.
- **Polish:** T034 and T035 run in parallel.

---

## Parallel Example: User Story 1

```text
Task: "T018 [US1] view-state tests: Play never warns, the tip names the step, no aim on sums"
Task: "T019 [US1] preview-panel tests: tip-only render, reveal builds the summary, height unchanged"
```

## Parallel Example: User Story 5 alongside User Story 4

```text
Task: "T030 [US5] sequencer tests for spent and xp_lost"
Task: "T032 [US5] XpPurse.count_to and fade_out"
Task: "T025 [US4] impact table test"
```

---

## Implementation Strategy

### MVP (Phases 1–5)

1. Setup and Foundational.
2. US3: the aim lives on the card. The box still works.
3. US2: the lift matches the engine.
4. US1: free the box. **Stop and validate**: `tools/test.sh`, then quickstart checks 1–3. This is the owner's goal (free the space without breaking anything) and can ship.

### Incremental Delivery

5. US4: marks on the cards. Validate with quickstart check 4.
6. US5: XP stars. Validate with quickstart check 5. It can be done at any point after Setup.
7. Polish: docs, the full suite, design shots, the emulators.

---

## Notes

- `vs.preview` and `vs.math` stay in the view state: they feed the post-Play summary. Only their display before Play goes.
- The engine (`engine/*.gd`) must not change (FR-024). If a task seems to need it, stop and re-check research R1/R2.
- Commit only when the owner asks.
