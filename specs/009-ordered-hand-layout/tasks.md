---

description: "Task list for the ordered Hand and play-board layout"
---

# Tasks: Ordered Hand and Play-Board Layout

**Input**: Design documents from `specs/009-ordered-hand-layout/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/board-layout.md, quickstart.md

**Tests**: Included. Every earlier feature tests its pure models headless, and research R9 lists the suites this change touches. Write each test task before the implementation task that follows it, and confirm it fails first.

**Organization**: Tasks are grouped by user story (spec.md US1–US4).

**Conventions for every task**:
- GDScript in the style of the surrounding file: `##` doc comments, tabs, typed vars where the file uses them.
- Run `./tools/test.sh` from the repo root to check.
- Do not touch `engine/` (FR-026, research R1).
- Figures are design units at 1280 × 720.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: The user story the task belongs to (US1–US4)

---

## Phase 1: Setup

**Purpose**: Record the baseline before anything moves.

- [X] T001 Run `./tools/test.sh` and record the pass count. Then run `godot --path . -s tools/design_shots.gd -- build/shots-009-before` to keep before-shots of the play screen. Both are baselines only; write nothing under `specs/`.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: The draft fields, the new layout bands and the `places` view list that every story builds on.

**⚠️ No user story work starts until this phase is complete.**

### Tests

- [X] T002 [P] Add failing tests to `tests/test_turn_draft.gd` for the new draft state:
  - `reset()` and `duplicate_draft()` carry `held` and `reserve` (both start null);
  - `drop(id)` clears `held` and `reserve` when they name `id`;
  - `floating(hand)` returns Hand cards that are in no Role, not `reserve`, and not the tucked `fuse.bottom`, in Hand order;
  - `place_of(id)` returns `[set, role]`, `"reserve"`, or null;
  - `reserve_card(hand)` returns `reserve` if set; otherwise the single floating card, when every role place is filled and the Reserve place is offered (`set_count == 1` with a four-card Hand, or the Final Journey); otherwise null.
- [X] T003 [P] Add failing tests to `tests/test_layout_solver.gd` for the new bands:
  - `solve()` returns regions `strip`, `places`, `floating`, `actions`, `commit` and `secondary` (an Array of 2 Rect2);
  - the regions `hand` and `slots` are gone;
  - at 1280 × 720 with `set_count = 1`:
    - every band spans the card side's full width;
    - top to bottom: strip, places, floating, actions;
    - `strip.size.y == 88`, at most half of the old band 184 (FR-018);
    - `actions.size.y == 88` and `actions.end.y == content.end.y`;
    - each secondary cell is within 2% of `(actions.size.x − 2·T.S) / 4` wide and `commit` within 2% of half (SC-003);
    - `commit` is the rightmost cell.
  - Replace the old "Hand cards no smaller than before" assertion with: every card rect from `place_rects` and `floating_rects` lies inside `content`, and no two overlap.

### Implementation

- [X] T004 Add `held: Variant = null` and `reserve: Variant = null` to `ui/model/turn_draft.gd`:
  - include them in `reset()` and `duplicate_draft()`;
  - add `floating(hand: Array) -> Array`, `place_of(id) -> Variant` and `reserve_card(hand: Array) -> Variant` exactly as data-model.md § TurnDraft describes;
  - extend `drop(id)` to clear `held` and `reserve` naming `id`;
  - keep `sets`, `slot_of`, `empty_slots`, `is_filled` and `to_action()` behaviour unchanged.

  Invariants (data-model.md): "A card id appears at most once across `sets[*]` values and `reserve`." and "A tucked Fuse card is never in `sets`, `reserve` or `held`." Makes T002 pass.
- [X] T005 Rework `solve()` in `ui/model/layout_solver.gd` to the bands in research R4:
  - Add constants `STRIP_H := 88`, `PLACE_EMPTY_H := 56`, `ACTION_ROW_H := float(T.TAP_MIN)` and `FINAL_LEFT_W := 340.0`. The last is used only when the new parameter `final := false` is true.
  - Remove `SLOT_BAND_H`, `SLOT_BAND_MAX`, `ACTION_CELL_W`, `ACTION_COLS*`, `PLAY_IN_COLUMN`, `action_width()` and the band arithmetic.
  - New signature: `solve(view, safe, hand_count := 4, place_count := 4, points_per_unit := 0.5, preview_needed := 0.0, encounter_min := T.ENCOUNTER_MIN, upright := false, final := false)`. `place_count` is 0 for setup and Soak (no strip or places).
  - The card side runs from `right_x` to `c.end.x`.
  - `actions` is the bottom `ACTION_ROW_H`, split into `secondary[0]`, `secondary[1]` (each `(w − 2·T.S) / 4`) and `commit` (`(w − 2·T.S) / 2`, rightmost), separated by `T.S`.
  - Above it, separated by `GAP`: `floating`, then `places`, then `strip`. The places and strip are omitted when `place_count == 0`.
  - Return `card_size`, `place_rects` (one Rect2 per place column, left to right, full card height, lined up under equal strip sections), `place_empty_h`, `left_w`, and a static `floating_rects(plan, count) -> Array` that lays `count` cards centred in the floating band, wrapping to a second row only when one row cannot hold them at `card_size`.
  - Keep `card_rects()` only if something still calls it after T011; otherwise delete it.
  - Makes T003 pass.
  - *Done note*: the region keys stayed `slots` (the strip) and `hand` (the band of cards) to keep callers unchanged; `cards` from the task text is `hand`.
- [X] T006 Add `card_size_for(right_w, body_h, hand_count, place_count) -> Vector2` to `ui/model/layout_solver.gd` (research R4/R6) and call it from `solve()`:
  - Try widths from `min(CARD_MAX_W, width bound)` down in steps of 1.
  - Keep the first width for which every stage `k = 0…min(place_count, hand_count)` fits in the body height:
    - strip;
    - places row (`PLACE_EMPTY_H` when `k == 0`, else the card height);
    - `ceil((hand_count − k) / cols)` floating rows;
    - the action row;
    - `GAP` between bands;
    - places-row width `place_count·w + (place_count − 1)·CARD_GAP_MIN` within the card side.
  - Height is `floor(w / T.CARD_ASPECT)`.
  - Expected at 1280 × 720: ≈ 148 × 207 for 4 cards and 4 places. Add that case to `tests/test_layout_solver.gd`.
- [X] T007 Add `places(vs, game, draft)` to `ui/model/view_state.gd`, replacing `role_slots()` (research R3; data-model.md § Place):
  - Build the ordered list. Region: reserve, element, spell, boost. A Region place list exists only while `vs.sets` is non-empty, or for the recap when `vs.played != null`.
  - Each entry is `{key, set, role, card_id, state, number, counts_to, ether, boost_to, tap, toggle_tap, tooltip, set_start}`.
  - Port today's numbers, tooltips and recap states from `role_slots()` unchanged.
  - The Reserve's `card_id` is `draft.reserve_card(vs.hand)`; in the recap it is `played.reserve`. Its `number` is that card's Boost only while `vs.cards[id].reserve_boosts`, else null.
  - Its state is `filled`, or `empty`. It is `inactive` when the Hand has under four cards in a Region.
  - Set `vs.places`, `vs.floating = draft.floating(vs.hand)` and `vs.held = draft.held`, and add `place` (place key or null) to each `vs.cards[id]`.
  - Leave the `tap` intents as today's (`select_slot`, `take_back`, `inspect`) for now. US1 changes them.
  - Update the callers of `vs.slots` in `ui/screens/play_screen.gd` and `ui/widgets/role_slots.gd` to read `vs.places`.
- [X] T008 Update `ui/screens/play_screen.gd` `_replan()`, `_place_regions()` and `_place_hand_panel()` for the new solver:
  - pass `place_count = vs.places.size()` and `final = vs.phase in ["final_journey", "final_enemy", "final_soak"]`;
  - fill `_regions.slots` from `plan.regions.strip`;
  - call `actions.apply_layout(plan.regions.actions, plan.regions.commit)`;
  - draw the hand panel round `places` + `floating`;
  - make `point("hand")` use the union of `places` and `floating`.
- [X] T009 Update `ui/widgets/action_bar.gd` so it lays out on the fixed row:
  - `apply_layout(actions, commit, secondary := [])` stores the two secondary rects;
  - `_place()` puts the n-th secondary button in `secondary[n]`, keeps `primary` in `commit` in every phase (no "alone takes all": FR-021), and hides buttons beyond two;
  - delete `_cells()`.

  Pass `plan.regions.secondary` from `play_screen.gd`.
- [X] T010 Update `tests/test_role_slots.gd`, `tests/test_view_state.gd`, `tests/test_emphasis.gd` and `tests/test_board_responses.gd` for the rename from `slots` to `places`. In Region order the Reserve now leads. Then run `./tools/test.sh` and fix any breakage until the counts are no lower than in T001.

**Checkpoint**: The board renders with the new bands and an always-visible Reserve. Tap behaviour is still today's.

---

## Phase 3: User Story 1 — Hand laid out in rulebook order (Priority: P1) 🎯 MVP

**Goal**: Dealt cards float unplaced. The player taps a card, then a place. Placed cards sit in Reserve · Element · Spell · Boost order under a labelled strip, and the last card goes to the Reserve on its own.

**Independent Test**: In a Region Encounter:
- nothing is placed and the preview shows no outcome;
- tap a card, then the Spell outline: it moves to the third place and the strip shows its number;
- fill Element and Boost the same way: the fourth card is shown in the Reserve.

(quickstart rows 1–3, 5)

### Tests for User Story 1

- [X] T011 [P] [US1] Add failing tests to `tests/test_turn_draft.gd`:
  - `pick(id)` sets `held`, and picking it again clears it;
  - `pick` of `fuse.bottom` returns "That card is tucked behind another. Unfuse to use it." and leaves `held` null;
  - `put([0, "spell"])` with a floating held card sets `sets[0].spell`, clears `held` and recomputes `active` as the first empty of spell, element, boost;
  - `put("floating")` with a placed held card removes it from `sets` and `reserve`;
  - `put("reserve")` sets `reserve`, and is refused (returns a message, no change) when the Region Hand has under four cards or `set_count == 2` in the Final Enemy;
  - `put_down()` only clears `held`;
  - after filling three Roles with four cards, `reserve_card` returns the fourth;
  - `to_action()` for the same Roles equals the dictionary today's `tap()` sequence produced.
- [X] T012 [P] [US1] Add failing tests to `tests/test_role_slots.gd`:
  - with a card held, every place that accepts it has state `target` and `tap == {"type": "put", "target": key}`;
  - with nothing held, a filled place's `tap == {"type": "pick", "id": card_id}`;
  - with nothing held and no cards placed, the preview status is `incomplete`.

### Implementation for User Story 1

- [X] T013 [US1] Implement `pick(id) -> String`, `put(target) -> String` and `put_down()` in `ui/model/turn_draft.gd` per data-model.md § Operations.
  - Swap rule: "If `target` holds a card, that card goes to `held`'s old place, or to floating if `held` was floating."
  - Make `begin_mode()` clear `held` (invariant: "`held` is null whenever `mode != "none"`").
  - Re-implement `take_back(id)` as `pick(id)` then `put("floating")`.
  - Remove `tap()` once T015 no longer calls it.
  - Makes T011 pass.
  - *Done note*: `tap()` is kept as a test helper (fills the hinted Role); the game no longer calls it.
- [X] T014 [US1] In `ui/model/view_state.gd` `places()`, set the states `next` (the hinted `draft.active`, nothing held, `mode == "none"`) and `target` (held card can go there), and the `tap` intents from data-model.md § Place `tap`. Add `held` to card `state` when `draft.held == id`. Makes T012 pass.
- [X] T015 [US1] In `ui/main.gd` `dispatch()`:
  - add the intents `pick {id}`, `put {target}` and `put_down {}`;
  - in `_on_card()`, for the building phases with `draft.mode == "none"`: if a card is held and the tapped card is placed, `put(place_of(tapped))` (a swap); if the tapped card is the held one, `put_down()`; if a different floating card is tapped, `pick` it instead;
  - otherwise `pick(id)`.

  Keep every other phase and mode branch as is. Play the board response `place` after a put onto a role place and `take_back` after a put to floating, through the existing `_respond()`.
- [X] T016 [US1] Rework `ui/widgets/hand_tray.gd` `sync()` to position by place, not by Hand index:
  - a card with `place != null` gets `plan.place_rects[index of that key in vs.places]`;
  - floating cards get `Solver.floating_rects(plan, vs.floating.size())` in order;
  - the held card lifts by `Solver.CARD_LIFT` and is drawn on top;
  - the tucked fuse card keeps today's offset behind its partner's new home.

  Keep `_glide()` and reduced-motion snapping (FR-009).
- [X] T017 [US1] Add a floating-band hit area in `ui/widgets/hand_tray.gd`: a transparent Control over `plan.regions.floating` that emits `{"type": "put", "target": "floating"}` when a card is held, and `put_down` otherwise.
  - Make each empty place outline (drawn by the tray at `place_empty_h` under its strip section) tappable with that place's `tap`.
  - Draw outlines as a 3-unit stroke in `T.muted(T.FOCUS)`, glowing (`T.FOCUS`) when `target`.
- [X] T018 [US1] Turn `ui/widgets/role_slots.gd` into the role strip:
  - one section per `vs.places` entry, each exactly over its place column (use `plan.place_rects[i].position.x` / `size.x`, not an HBoxContainer split);
  - `STRIP_H` tall;
  - each section shows the role icon and name (icon only under `NAME_MIN_W`), the large number (≥ `T.NUMERAL`, 32) when filled, and its `counts_to` icon;
  - states as in contracts/board-layout.md § Strip section, including the `target` glow;
  - tapping a section sends its `tap`; the Boost target icon sends `toggle_tap`.

  Keep `flare()`, `slot_rect()`, `number_rect()` and `number_label()` keyed `"set/role"` (and `"reserve"`) so `play_screen._answer_slots()` number flights still land.
- [X] T019 [US1] Update `ui/model/emphasis.gd` so that `next_role` comes from `draft.active` only when nothing is held. While a card is held, emphasise that card's parts for every `target` role. Update `tests/test_emphasis.gd` to match.
- [X] T020 [US1] Update the prompt text in `ui/model/view_state.gd` `_prompt()` from "Tap a card to place it." to "Tap a card, then the place it goes in. Hold a card to inspect it." While a card is held: "Tap a place for {card name}."

**Checkpoint**: US1 works by taps alone in a Region. Run `./tools/test.sh` and quickstart rows 1–3 and 5.

---

## Phase 4: User Story 2 — Rearrange by moving cards between places (Priority: P1)

**Goal**: Swap two placed cards in one move by tap-then-tap, drag, or keyboard. Every arrangement can be reached without dragging.

**Independent Test**: With all Roles filled, tap the Boost card and then the Element place: they swap and the preview updates. Drag does the same. Keys `2`, `Tab`, `Space` place a card (quickstart rows 4 and 6).

### Tests for User Story 2

- [X] T021 [P] [US2] Add failing tests to `tests/test_turn_draft.gd` for swaps:
  - placed↔placed swaps Roles;
  - reserve↔placed: the former Spell becomes `reserve`;
  - floating→filled place: the displaced card becomes floating;
  - a fused top card moved to another place keeps `fuse` intact and the tucked card stays out of `sets` and `reserve`.

### Implementation for User Story 2

- [X] T022 [US2] Handle every swap case from T021 in `put()` in `ui/model/turn_draft.gd`, including a fused top card (the `fuse` dict is unchanged; only `sets` and `reserve` move). Makes T021 pass.
- [X] T023 [US2] Add the drag gesture to `ui/widgets/card_view.gd`:
  - add `const DRAG_START := 12.0`;
  - emit new signals `drag_started(id)`, `dragged(id, global_pos)` and `dropped(id, global_pos)` once the pointer moves more than `DRAG_START` with the button down;
  - starting a drag cancels the hold timer, so `held` (inspect) does not fire;
  - a release without a drag still emits `tapped`.
- [X] T024 [US2] In `ui/widgets/hand_tray.gd`, follow `dragged` by moving the card (and its tucked partner) to the pointer on top. On `dropped`, hit-test `plan.place_rects` (only places present in `vs.places`) and `plan.regions.floating`:
  - on a hit, emit `{"type": "drag_put", "id": id, "target": key or "floating"}`;
  - on a miss, glide home.

  In `ui/main.gd`, handle `drag_put` as `draft.pick(id)` then `draft.put(target)`, plus the same `_respond()` as T015.
- [X] T025 [US2] Update the keyboard in `ui/main.gd` `_unhandled_key_input` (research R8):
  - `1`–`9` dispatch `card` for the card at that index in on-screen order: the place cards left to right, then `vs.floating`;
  - while `draft.held != null`, `Tab`/`Shift+Tab` cycle a `_key_target` across the place keys then `"floating"`, shown through the place's `target` glow (add `vs.key_target`), `Space` dispatches `put {target: _key_target}`, and `Esc` dispatches `put_down` before any mode cancel;
  - with nothing held, `Tab` keeps today's behaviour.
- [X] T026 [US2] Add board responses for a swap in `ui/model/board_response.gd`: `place` for both moved cards, the second delayed by `T.STAGGER`. Add a case to `tests/test_board_responses.gd`.
  - *Done note*: the stagger lives in `main._put()`, which answers each moved card with `place` or `take_back`, the second after `T.STAGGER`; `board_response.gd` needed no new entry.

**Checkpoint**: US1 + US2 complete. Quickstart rows 1–6 pass.

---

## Phase 5: User Story 3 — One row of actions under the cards (Priority: P2)

**Goal**: Fuse ¼ · Divert ¼ · Play ½ under the cards, with a shorter strip above. Give up Reserve moves onto the Reserve place.

**Independent Test**: At 1280 × 720, the right side reads strip, places, floating, action row. The cells are ¼ ¼ ½. Against a Ranged enemy the toggle sits on the Reserve and the row has no Give up button (quickstart rows 1 and 7).

### Tests for User Story 3

- [X] T027 [P] [US3] Add failing tests to `tests/test_view_state.gd`:
  - `_secondary` never contains `give_up_reserve`;
  - against a Ranged enemy the Reserve place has `toggle_tap == {"type": "toggle_give_up_reserve"}`, and state `given_up` when `draft.give_up_reserve`;
  - the cells per phase match research R5: challenge = [fuse, divert], final_journey = [fuse, regroup], final_enemy = [fuse], upgrade with undo = [undo];
  - Cavalier drops Fuse to a blank first cell, so Divert stays in cell 2.

### Implementation for User Story 3

- [X] T028 [US3] In `ui/model/view_state.gd`, remove `give_up_reserve` from `_secondary()` and add the Reserve's `toggle_tap` and `given_up` state in `places()`. Return the secondary list with a fixed cell index per action: fuse → 0; divert/regroup → 1; undo → 0; Cancel takes its action's index. Under Cavalier, cell 0 is null. Makes T027 pass.
- [X] T029 [US3] In `ui/widgets/action_bar.gd`, render secondary entries by cell index: null leaves the cell blank, and Play never stretches (FR-021). In `ui/main.gd`, handle `toggle_give_up_reserve` by flipping `draft.give_up_reserve`, add key `R` for it, and remove the `give_up_reserve` action branch.
- [X] T030 [US3] Draw the Give up toggle in `ui/widgets/role_slots.gd` on the Reserve section: a ≥ 44 hit area like the Boost target icon, using icon `reserve` struck through when on.
  - The `given_up` state shows the Reserve number struck through.
  - Tooltip: "Give up your Reserve to ignore this enemy's Ranged strike".
- [X] T031 [US3] Point the Reserve-related emphasis at the Reserve place in `ui/screens/play_screen.gd` / `ui/widgets/role_slots.gd`: Steep, Freeze, and the Journey Reserve Boost (`reserve_boosts`) flare the Reserve section rather than the card alone (FR-012).

**Checkpoint**: US1–US3 complete in the Regions.

---

## Phase 6: User Story 4 — The Final Battle follows the same order (Priority: P3)

**Goal**: The Final Journey shows Reserve · Set 1 ‖ Set 2 and the Final Enemy shows Set 1 ‖ Set 2, with the left side narrowed so every card (up to 9) is on screen at once.

**Independent Test**: Reach the Final Journey: 7 places in one row with a divider, and all 7 cards visible. Reach a 9-card Final Enemy: no Reserve place, and all cards visible at every stage (quickstart rows 11–12).

### Tests for User Story 4

- [X] T032 [P] [US4] Add failing tests to `tests/test_role_slots.gd`:
  - Final Journey order is reserve, 0/element, 0/spell, 0/boost, 1/element, 1/spell, 1/boost, with `set_start` true only on 1/element;
  - Final Enemy has the six role places and no reserve.
- [X] T033 [P] [US4] Add failing tests to `tests/test_layout_solver.gd` with `final = true`:
  - `left_w == FINAL_LEFT_W`;
  - for `(hand, places)` in `[(7, 7), (8, 6), (9, 6)]`, every stage k fits with all rects inside `content` and no overlap;
  - card widths ≈ 117 for (7, 7) and (8, 6), ≈ 101 for (9, 6), within ±3;
  - the same at every `MATRIX` window via `matrix_safe()`.

### Implementation for User Story 4

- [X] T034 [US4] Extend `places()` in `ui/model/view_state.gd` for `set_count == 2`:
  - add the reserve place only in `final_journey`;
  - set `set_start` on Set 2's first place;
  - `reserve_card` is offered only in `final_journey`.

  Make `TurnDraft.put("reserve")` refuse in the Final Enemy. Makes T032 pass.
- [X] T035 [US4] In `ui/model/layout_solver.gd`, use `FINAL_LEFT_W` when `final` is true, and make sure `card_size_for()` handles 7–9 cards (one places row; floating wrap). Makes T033 pass.
- [X] T036 [US4] Draw the set divider in `ui/widgets/role_slots.gd` between the sections where `set_start` is true (a 2-unit `T.GOLD` rule spanning the strip), and label the set numbers on the role names ("Spell 1", "Spell 2") using the existing `_tip` wording.
- [X] T037 [US4] Check the left side at `FINAL_LEFT_W`:
  - run `godot --path . -s tools/design_shots.gd -- build/shots-009` and `godot --path . -s tools/space_audit.gd`;
  - inspect the Final Journey and Final Enemy shots for clipping in `ui/widgets/dragon_face.gd`, `ui/widgets/dragon_stats.gd` and `ui/widgets/preview_panel.gd` (rows `ROW_H_FINAL`);
  - if anything clips or text drops under 22, raise `FINAL_LEFT_W` in steps of 20, re-run, and update research.md R6 with the final value and card sizes.
  - *Done note*: 340 and 360 clipped the dragon face; `FINAL_LEFT_W` is 380 (research R6 updated).

**Checkpoint**: All four stories work.

---

## Phase 7: Polish & cross-cutting

- [X] T038 [P] Add `Vector2(148, 207)`, `Vector2(117, 164)` and `Vector2(101, 141)` to `SIZES` in `tests/test_card_face_layout.gd`, and make sure every region stays inside and apart (research R4).
- [X] T039 Update `tools/ui_check.gd`:
  - build Action Sets through `pick`/`put` intents in `_play()` and `_press()`, not the old `card` taps that filled slots in order;
  - keep `_check_space()` and the overlap checks at every window;
  - add a pass that, at each window, places cards one at a time and asserts every card rect stays inside the viewport (SC-004a, SC-005).
- [X] T040 [P] Check the rules UI text in `ui/model/rulebook.gd` and `ui/model/glossary.gd`. Update lines that say "tap a card to place it" or describe the slot band, and add one rulebook line under Action Phase: "Your Hand is kept in the rulebook's order: Reserve, Element, Spell, Boost."
- [X] T041 Run `./tools/test.sh`. The pass count must be at least T001's plus the new tests, and `tests/test_rules.gd` and `tests/test_playthrough.gd` must be unchanged (SC-006). Then walk quickstart.md "By hand" rows 1–13, including reduced motion (row 10).
  - *Done note*: automated part done (290 tests, UI check 0 failed; the only flagged errors are the 402 "Lambda capture … was freed" lines that predate this feature, 410 on `main`). The "By hand" rows were checked through screenshots and the UI check's arrange walk, not in an interactive window: real-mouse and touch dragging still need a hands-on try.

---

## Dependencies & Execution Order

- **Setup (T001)** → **Foundational (T002–T010)** → user stories.
- **US1 (T011–T020)**: needs Foundational. It is the MVP.
- **US2 (T021–T026)**: needs US1's `pick`/`put` and tray positions.
- **US3 (T027–T031)**: needs Foundational (fixed row) and US1's Reserve place. It is independent of US2.
- **US4 (T032–T037)**: needs US1. T035 depends on T006.
- **Polish (T038–T041)**: after the stories it covers. T039 needs US1 and US2.

Within a story: tests, then the model (`turn_draft`, `view_state`), then widgets, then `main.gd`.

## Parallel Opportunities

- T002 ∥ T003 (different test files).
- After Foundational: US2 and US3 can proceed side by side once US1 is in. Their files overlap only in `ui/main.gd` (separate functions; merge with care).
- T011 ∥ T012; T027, T032 ∥ T033; T038 ∥ T040.

```text
# Foundational tests together
T002 tests/test_turn_draft.gd   ∥   T003 tests/test_layout_solver.gd

# US4 tests together
T032 tests/test_role_slots.gd   ∥   T033 tests/test_layout_solver.gd
```

## Implementation Strategy

1. **MVP**: Phases 1–3. Cards float, tap-then-place, ordered places with the Reserve, and the new bands. Validate with quickstart rows 1–3 and 5.
2. Add **US2** (swap, drag, keyboard).
3. Add **US3** (the action row's fixed cells; Give up Reserve on the Reserve).
4. Add **US4** (Final Battle order and width). T037 may move `FINAL_LEFT_W`.
5. **Polish**: card-face sizes, `ui_check`, rules text, and the full quickstart walk.
