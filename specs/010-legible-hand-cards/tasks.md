---

description: "Task list for 010 Legible Hand Cards"
---

# Tasks: Legible Hand Cards

**Input**: Design documents from `specs/010-legible-hand-cards/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/board-layout.md](contracts/board-layout.md), [quickstart.md](quickstart.md)

**Tests**: Included. The project tests every pure model headless and every screen in `ui_check` (plan, Constitution Check). Research R9 lists the tests.

**Organization**: Tasks are grouped by user story (spec.md US1–US5). Every figure is in design units. Run `tools/test.sh` after each phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story the task belongs to (US1–US5)

---

## Phase 1: Setup

- [X] T001 Run `tools/test.sh` on the unchanged tree and confirm it is green, so later failures are this feature's.
- [X] T002 Record the 009 card size at every `layout_solver.MATRIX` shape (Region 4 cards, Final Journey 7, Final Enemy 9) from the current `Solver.solve(...).card_size`, and add them as a `const SIZE_009 := {shape: {stage: Vector2}}` table at the top of `tests/test_layout_solver.gd`. FR-013 is checked against it. Phone-tall Region must read 138 × 194.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: The draft model (research R1–R3) and the one-row solver (R6). Every story depends on these.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Draft model

- [X] T003 Write failing tests in `tests/test_turn_draft.gd`:
  - `deal(hand)`, 4 cards: hand[0]→`reserve`, hand[1]→element, hand[2]→spell, hand[3]→boost.
  - `deal` with 3, 2 and 1 cards: fills spell, then element, then boost, and leaves the Reserve empty.
  - `deal` on the Final Journey (`reset(2, true)`, 7 cards): Reserve, then E1 S1 B1 E2 S2 B2.
  - `deal` on the Final Enemy (`reset(2, false)`, 9 cards): E1 S1 B1 E2 S2 B2, and the last 3 returned by `extras(hand)` in Hand order.
  - `settle` after `drop()` of the Spell in a 4-card Hand: the Reserve card moves to spell and `reserve` is null.
  - `settle` after a Fuse whose bottom was the Boost in a 4-card Hand: the Reserve moves to boost.
  - `unfuse()` then `settle`: the freed card fills the first empty position (spell, element, boost, then the Reserve).
  - `swap(a, b)` between two roles, between a role and the Reserve, and between a role and an extra.
  - `boost_target_set(held)`, Region: returns 0. Final Enemy: returns the held Boost card's set; otherwise the first set whose `boost_to` is null; otherwise -1.
  - `to_action()` after `deal`: equals the dictionary built by setting the same roles by hand.
- [X] T004 Implement `deal(hand)`, `settle(hand)`, `swap(a, b)`, `extras(hand)` (renamed from `floating`) and `boost_target_set(held)` in `ui/model/turn_draft.gd`, per research R2 and R3 and data-model.md:
  - Remove the `"floating"` put target.
  - Extend `put(target, hand)` to accept `{"card": id}` (swap with that card).
  - `deal` and `settle` must never place the tucked Fuse card.
  - `reserve` may only be non-null when `reserve_offered(hand)` is true.
  - Keep `to_action()` and `duplicate_draft()` behaviour; `duplicate_draft` copies nothing new.
- [X] T005 In `ui/main.gd`, call `draft.deal(game.hand)` after every `draft.reset(...)` while `game.phase` is `challenge`, `final_journey` or `final_enemy` (`start_game` and both reset sites in `_act`). Call `draft.settle(game.hand)` after `draft.drop(action.id)` (Divert), after the `fuse_element` intent's `choose_fuse_element`, and after `unfuse()` in `_on_action`.

### One-row solver

- [X] T006 [P] Write failing tests in `tests/test_layout_solver.gd`. For `solve(view, safe, hand_count, place_count, ..., action_cells)`:
  - `plan.positions` has one `{label, card}` per position; each label is `LABEL_H` = 36 tall directly over its card.
  - Every rect lies inside `regions.hand`, and `regions.hand` spans from `body_y` to `actions.y − GAP`.
  - There is no `regions.slots` key.
  - Phone-tall Region is 220 × 308 in 1 row; baseline Region is 197 × 275.
  - Baseline Final Journey (7) is 2 rows, 4 + 3; the row break is at the set divider (FR-001 allows wrapping only in the Final Battle).
  - Every shape and stage is ≥ `SIZE_009` (T002).
  - Setup and Soak (`place_count` 0) have `label` height 0.
- [X] T007 Rewrite the card side of `ui/model/layout_solver.gd` per research R6:
  - Delete `STRIP_H`, `PLACE_EMPTY_H`, `card_size_for`, `_stages_fit`, `floating_rects`, `outline_height` and the `slots` region.
  - Add `LABEL_H := 36.0`, plus a `_positions(band, n, label_h, breaks)` that tries 1, 2 and 3 rows (`cols = ceil(n / rows)`; `w = min(CARD_MAX_W, (band.x − (cols − 1)·gap) / cols)`; `h = floor(w / CARD_ASPECT)`, reduced so `rows·(label_h + h) + (rows − 1)·GAP ≤ band.y`).
  - Keep the widest card; on a tie, prefer the row count whose breaks fall on a set boundary.
  - Fill rows left to right, top to bottom, centred.
  - `n` = max(hand_count, place_count).
  - Return `positions` and `card_size`; `hand` runs from `body_y` to `actions.y − GAP`.
  - Add an `action_cells := 3` parameter to `solve`. Store it in the plan; the row stays ¼ · ¼ · ½ until T024 lays it out by cell count.

**Checkpoint**: The draft deals and repairs positions, and the solver returns one-row positions. The screens are not wired yet, so `ui_check` may fail until US1.

---

## Phase 3: User Story 1 - Card names readable on a phone (Priority: P1) 🎯 MVP

**Goal**: The Hand renders in the solver's one-row positions at full size. Names are ≥ 17 at phone-tall.

**Independent Test**: At phone-tall, a Region Hand's cards are ≥ 291 tall (1.5 × 194) and the longest name draws at ≥ 17 (spec US1).

- [X] T008 [P] [US1] Add a test to `tests/test_card_face_layout.gd`: at a card of 220 × 308, `CardFace.name_size(...)` on the name rect from `region_rect("name")` is ≥ 17 for "MOTIVATED FLIGHT" and "DETERMINED MARCH".
- [X] T009 [US1] In `ui/widgets/hand_tray.gd`, place every card at its position's `card` rect:
  - `_home_of` takes `plan.positions[place.index].card` for placed cards and the next position for an extra.
  - Delete `_sync_outlines`, outline drawing and every use of `floating_rects` and `outline_height`.
  - In setup, Soak and Upgrade, cards take `positions[i]` in Hand order.
- [X] T010 [US1] In `ui/screens/play_screen.gd`:
  - Remove the `slots` region `_fill` and `slots.set_columns(...)`.
  - Make the hand panel rect (around line 214) the union of `plan.positions` rects grown by 6.
  - Pass `action_cells` (3 until T027) to `Solver.solve` in the re-solve path (around line 398), and add it to the `q["for"]` cache key.
- [X] T011 [P] [US1] Update `ui/fx/flight_layer.gd`, `ui/widgets/card_view.gd` and `ui/widgets/ether_picker.gd` so no reference to `place_rects`, `floating` or `role_slots` remains (grep). Each should read card rects from `plan.positions`.
- [X] T012 [US1] Add a check to `tools/ui_check.gd` (`_cards_on_screen` or a new `_card_size(where)`): at every MATRIX shape, in a Region Encounter, every Hand card view is ≥ `SIZE_009` for that shape, and at phone-tall ≥ 291 tall.
- [X] T013 [US1] Run `godot --path . -s tools/design_shots.gd` and check the phone-tall Region shot shows one row of four full-size cards with readable names (quickstart Screenshots 1–2).

**Checkpoint**: Cards are large and legible. The strip is gone and labels arrive in US2. The dealt arrangement can be played as-is, and swapping uses 009's tap/drag paths.

---

## Phase 4: User Story 2 - One row where position is role (Priority: P1)

**Goal**: Labels over each card replace the role strip. The player rearranges by swapping (tap, drag, keyboard).

**Independent Test**: A dealt Hand reads Reserve · Element · Spell · Boost under labels, with no strip and no floating area. Tapping Element then Boost swaps them, and the preview updates (spec US2).

- [X] T014 [P] [US2] Write failing tests in `tests/test_view_state.gd`:
  - `places` entries have no `number`, `counts_to`, `choices`, `toggle_tap`, `boost_to` or `ether` keys.
  - Each has `index` matching its order.
  - `state` is never `"next"`.
  - Final Enemy extras have `role == "extra"`.
  - The view state has `extras`, not `floating`.
  - With a card held, every other position's `tap` is `{type: "put", target: ...}`; a card position's target is `{"card": id}`.
- [X] T015 [US2] Rewrite `ViewState.places` in `ui/model/view_state.gd` (lines 386–495) per data-model.md:
  - Drop the number, `counts_to`, choices, toggle and boost fields from `_place`, and add `index`.
  - Remove the `next` state and the `select_slot` tap.
  - Filled positions tap `pick` when idle and `put {card: id}` when another card is held.
  - Append extras (Final Enemy) with role `"extra"`.
  - Rename the `floating` field to `extras`.
- [X] T016 [P] [US2] Create `ui/widgets/place_labels.gd` from `ui/widgets/role_slots.gd` (research R7):
  - One label Button per `vs.places` entry at `plan.positions[index].label`.
  - Each label shows the role icon and name (`T.LABEL_BOLD`, ≥ 22), muted for `empty` and dimmer for `inactive`.
  - `target` glows in `T.FOCUS`; `given_up` strikes the Reserve through; recap marks for `played`, `kept` and `discarded`.
  - Set 2's first label draws the divider; the Reserve label carries the Steep or Freeze mark.
  - Pressing a label emits the place's `tap`.
  - No numbers, no card names (the tooltip has the name).
  - Delete `ui/widgets/role_slots.gd` and rename `tests/test_role_slots.gd` to `tests/test_place_labels.gd`, rewritten for these states.
- [X] T017 [US2] Wire `PlaceLabels` into `ui/screens/play_screen.gd` in place of `RoleSlots`: render it with `vs` and `plan.positions`, and hide it in setup, Soak and Upgrade.
- [X] T018 [US2] In `ui/main.gd`:
  - In `_on_card`, while a card is held, tapping another Hand card dispatches `_put({"card": id})`.
  - Remove the `select_slot` and `take_back` intents and their keyboard paths (the `KEY_TAB` branch at around line 1008 that cycles `select_slot`).
  - Keep `Tab`/`Shift+Tab` moving `_key_target` over positions while a card is held, and `Space` putting there.
  - `_put` events: a move is always `place`, never `take_back`.
- [X] T019 [US2] In `ui/widgets/hand_tray.gd` `_drop_target(at)`, return `{"card": id}` when the drop lands on another card's rect and the position target when it lands on a label rect; anywhere else returns null (glide home). Keep the 12-unit drag threshold and the Fuse partners following (`_partners`).
- [X] T020 [P] [US2] Update `ui/model/emphasis.gd` and `tests/test_emphasis.gd`: drop the "next place" hint; keep target highlighting while a card is held.
- [X] T021 [P] [US2] Update `ui/model/board_response.gd` and `tests/test_board_responses.gd`: the `place` number flight ends at the preview row total (`preview_panel` total label for the role's sum) instead of `role_slots.number_rect`; remove `take_back` responses tied to the floating row.
- [X] T022 [US2] Update `tools/ui_check.gd` `_place`, `_arrange_walk` and `_play` to build sets by swaps (`pick` then `put {card}`/position) from the dealt arrangement instead of placing floating cards; assert no `RoleSlots` node exists and every label is ≥ 22 text and inside the screen.

**Checkpoint**: The board shows the one-row, position-is-role Hand, and building works by tap, drag and keyboard.

---

## Phase 5: User Story 3 - One action row that makes room for more buttons (Priority: P2)

**Goal**: The row splits by cell count (research R5), and Give up Reserve joins as a cell.

**Independent Test**: Against a non-Ranged Enemy the row reads Fuse ¼ · Divert ¼ · Play ½. Against a Ranged Enemy it reads four quarters, with Play rightmost (spec US3).

- [X] T023 [P] [US3] Write failing tests:
  - In `tests/test_layout_solver.gd`, for `action_cells` 3, 4 and 5, `regions.secondary` has 2, 3 and 4 rects. Play (`regions.commit`) is ½, ¼ and ⅕ of `regions.actions` within 2%, with `commit.end.x == actions.end.x`.
  - In `tests/test_view_state.gd`, `secondary` is `[fuse, divert]` against a plain Enemy, `[fuse, divert, give_up_reserve]` against a Ranged Enemy with a Reserve, and `[fuse, divert]` after a Divert to 3 cards. `action_cells` is 3, 4 and 3 respectively. In the Upgrade phase, Undo takes cell 0.
- [X] T024 [US3] In `ui/model/layout_solver.gd` `solve`, using the `action_cells` parameter added in T007, lay out `actions`, `secondary` and `commit` from `action_cells` per contracts/board-layout.md (≤ 3: two quarters plus Play ½; 4: four quarters; 5: five fifths), separated by `T.S`.
- [X] T025 [US3] In `ui/model/view_state.gd` `_secondary` (line 726):
  - Return Fuse or Undo, then Divert or Regroup, then a `give_up_reserve` toggle entry (`{"id": "give_up_reserve", "label": "Give up Reserve", "icon": "reserve", "active": draft.give_up_reserve, ...}`). It is present only when the Encounter is an Enemy with `ability == "ranged"` and `draft.reserve_card(game.hand) != null`.
  - Keep the Cancel-in-place rule.
  - Add `vs.action_cells = max(3, secondary.size() + 1)`.
- [X] T026 [US3] In `ui/widgets/action_bar.gd`, build one button per `vs.secondary` entry (null stays a blank cell) at `regions.secondary[i]`, with Play at `regions.commit`. In `ui/main.gd` `_on_action`, handle `"give_up_reserve"` by toggling `draft.give_up_reserve` (the `R` key keeps dispatching `toggle_give_up_reserve`; update the `KEY_R` condition to read `vs.secondary` instead of `vs.places[0].toggle_tap`).
- [X] T027 [US3] In `ui/screens/play_screen.gd`, pass `vs.action_cells` to the solver (replacing T010's default of 3).

**Checkpoint**: The action row holds Fuse, Divert, Give up Reserve and Play as the cell rule says.

---

## Phase 6: User Story 4 - Choosing where the Boost goes (Priority: P2)

**Goal**: The Attack and Initiative rows in the preview panel aim the Boost (research R4).

**Independent Test**: Against an Enemy, tapping Initiative then Attack moves the Boost term and changes both totals. Play waits until the Boost is aimed (spec US4).

- [X] T028 [P] [US4] Write failing tests:
  - In `tests/test_view_state.gd`, against an Enemy while building, `math.sums` for attack and initiative carry `aim = {to, on: [...], open}`. `open` is true while `boost_to` is null, and `on` lists the sets aimed there. On a Journey and outside building, `aim` is null.
  - In `tests/test_turn_draft.gd`, the FR-018b case: a swap that changes the Boost card keeps `boost_to`.
- [X] T029 [US4] In `ui/model/view_state.gd` `math`, add `aim` to the attack and initiative sums per data-model.md, from `vs.sets[i].boost_to` and `show_boost_to`.
- [X] T030 [US4] In `ui/widgets/preview_panel.gd`:
  - Add `const ROW_H_AIM := 88.0`. A sum with `aim` renders as a Button (min height 88, full row width) holding the row's cells, and emits `intent {type: "aim_boost", to: aim.to}`.
  - While `aim.open`, add a dimmed "Boost?" cell and a `T.GOLD` edge.
  - Draw the Initiative note inside its row under the cells, instead of `_note` on its own line, when the row is an aim row.
  - Drop the Region "Playing this ends the game in defeat." line (lines 83–86).
  - Update `needed_height` so an Enemy (Region) uses `[88, 88]` with no note line or warning line, and the Final Enemy uses `[88, 88]`.
- [X] T031 [US4] In `ui/main.gd`, add the `aim_boost` intent: `var i := draft.boost_target_set(draft.held)`.
  - If `i < 0`, `_refuse("Pick up a Boost card, then tap where it goes.")`.
  - Otherwise `draft.set_boost_to(i, intent.to)`, put the held card down if it was that set's Boost, `_refresh()`, and play an aim flare on the row (add `"aim"` to `ui/model/board_response.gd`).
  - Keep `KEY_B` as the keyboard aim (`toggle_boost_to` on `draft.active[0]`); add no new keys.
  - `KEY_I` stays card inspect (line 1022); do not rebind it.
- [X] T032 [US4] Add to `tools/ui_check.gd`: against an Enemy at every MATRIX shape, both aim rows are ≥ 88 tall, the preview panel fits its region (`needed_height ≤ regions.preview.size.y`), and pressing each row moves the Boost (the Attack and Initiative totals change).

**Checkpoint**: The Boost is aimed from the preview, and the panel fits at phone-tall.

---

## Phase 7: User Story 5 - The Final Battle keeps the same scheme (Priority: P3)

**Goal**: The Final Journey and Final Enemy use the same labelled positions, with a set divider and a row break at the set boundary.

**Independent Test**: The Final Journey (7) and the Final Enemy (9) show every card and label, the divider between sets, and Regroup in Divert's cell (spec US5).

- [X] T033 [P] [US5] Extend `tests/test_layout_solver.gd`: baseline Final Journey is 2 rows, row 1 = 4 positions and row 2 = 3; Final Enemy with 9 cards fits every card; every Final card ≥ `SIZE_009`.
- [X] T034 [US5] In `ui/model/layout_solver.gd` `_positions`, pass set-boundary break indexes from `solve` when `final` (Final Journey: after index 3; Final Enemy: after index 2 and after index 5) for the tie-break in T007.
- [X] T035 [US5] In `ui/model/view_state.gd`, make the Final Enemy extras carry `set_start = false` and no label state other than `filled`. In `ui/widgets/place_labels.gd`, draw no role name for `role == "extra"` (an empty, muted label band keeps the row aligned).
- [X] T036 [US5] Extend `tools/ui_check.gd` `_play` to reach the Final Journey and Final Enemy at every MATRIX shape. Assert every card and label is on screen, the divider is drawn, Regroup is in `regions.secondary[1]`, and the two Boosts aim in turn with row taps (FR-018c).

**Checkpoint**: Every story works at every stage.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T037 [P] Grep the repo (excluding `specs/`) for `STRIP_H`, `PLACE_EMPTY_H`, `floating_rects`, `outline_height`, `place_rects`, `role_slots`, `select_slot`, `take_back` and `"floating"`, and remove every leftover use.
- [X] T038 [P] Update the in-game help text that says "Tap a card, then the place it goes in" (`ui/widgets/preview_panel.gd`, lines 75 and 329) to "Tap two cards to swap their roles. Hold a card to inspect it.", and check `ui/model/glossary.gd` and `ui/model/rulebook.gd` for wording about the role strip or floating cards.
- [X] T039 Run `tools/test.sh` and fix any failures; then `godot --path . -s tools/design_shots.gd` and walk quickstart.md "By hand" steps 1–8 on desktop, recording any deviation in this file.
- [X] T040 [P] Add a note at the top of `specs/009-ordered-hand-layout/contracts/board-layout.md` that 010 replaces its card-side bands and action row (link to `specs/010-legible-hand-cards/contracts/board-layout.md`).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → user stories.
- **US1 (Phase 3)** needs T004–T007. It is the MVP: big cards in one dealt row, before labels arrive.
- **US2 (Phase 4)** needs US1 (positions rendered by `hand_tray`).
- **US3 (Phase 5)** needs Foundational only (solver and view state), plus T010's solver call site.
- **US4 (Phase 6)** needs Foundational only. It shares `ui/main.gd` and `ui/model/view_state.gd` with US2 and US3, so it runs after them.
- **US5 (Phase 7)** needs US2 (labels) and US3 (Regroup cell).
- **Polish (Phase 8)** comes after every story.

### Within Each Story

Tests first (they must fail), then models (`turn_draft`, `view_state`, `layout_solver`), then widgets, then `main`, then `ui_check`.

### Parallel Opportunities

- T006 runs alongside T003–T005 (different files).
- US1: T008 and T011 run alongside T009 and T010.
- US2: T014, T016, T020 and T021 run in parallel; T015 before T017 and T022.
- US3: T023 runs alongside T024 and T025.
- US4: T028 runs alongside T029 and T030.
- Polish: T037, T038 and T040 run in parallel.

## Parallel Example: User Story 2

```text
Task: "T014 view_state places tests in tests/test_view_state.gd"
Task: "T016 place_labels widget in ui/widgets/place_labels.gd"
Task: "T020 emphasis without the next hint in ui/model/emphasis.gd"
Task: "T021 number flight to the preview row in ui/model/board_response.gd"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phases 1–2: draft dealing and the one-row solver.
2. Phase 3: cards render at full size. **Stop and check on the phone build**: are names readable?
3. If they are, continue. If not, the card face's name band is the next lever (spec Assumptions).

### Incremental Delivery

US1 (big cards) → US2 (labels and swapping) → US3 (action row) → US4 (Boost aim) → US5 (Final Battle) → Polish. Run `tools/test.sh` at each checkpoint.

## Implementation Notes (2026-10-17)

- **Baseline (T001)**: `tools/test.sh` exited 1 before any change: 408 "Lambda capture was freed" errors from the 009 role strip during `ui_check`. They are gone with the strip; the script now exits 0 (305 tests, 83,776 UI checks).
- **Measured 009 sizes (T002)**: phone-tall Region cards were 140 × 196, not the 138 × 194 estimated from the screenshot. The 50% target is therefore ≥ 294; 010 gives 220 × 308.
- **One row in the Regions**: the solver only wraps in the Final Battle, setup and Soak. On the tablet a 2 × 2 grid gave wider cards, but FR-001 keeps building a Region set in one row. Tablet Region cards stay at 009's 197 wide.
- **Labels are not buttons**: a 36-tall Button would fail the 88 tap minimum, so a label forwards its tap to its place, and an empty place's outline is the button.
- **Number flight (T021)**: the strip's number flight has no target any more. A placed card now flashes in its Ether instead. No number flies to the math box, and there is no aim flare.
- **Hint text (T038)**: while only the Boost's aim is missing, the math box shows a single line ("Tap Attack or Initiative to add the Boost there.") so the aim rows fit on the long phone.
- **Not regressions**: at the Pixel 9 Pro size, the Region Enemy face's Key Card line is clipped and the Final Enemy's verdict sits on the box's bottom edge. 009 already did both (compared against 009's own `design_shots`).
- **Device review fixes (2026-10-17)**:
  - The card row's labels now start level with the top of the left column instead of being centred.
  - The aim rows have 10 units of inner padding.
  - To keep the Region Enemy preview inside its box on the phone:
    - the Initiative note shares the Initiative row's 88;
    - the verdict is in sentence case;
    - the separate aiming hint is gone, and the rows' "? Add Boost" cell asks instead, in place of "Still needed: Boost target".
- **Second device review (2026-10-17)**:
  - The card row starts `HAND_PAD` (10) below the Hand region's top, so the well's top is level with the enemy panel. It keeps the full width, which keeps the tablet at 009's 197.
  - `ENCOUNTER_MIN` is 334, not 316: a badge's figure and icon need about 54, and 316 clipped the Key Card line.
  - The encounter face sizes its badges from its own height, so they can shrink again.
  - The Region verdict is in bold body type, so the verdict and its pills share one line.
  - The rulebook figure keeps its own 300.
  - Final Battle grid (`set_rows`): one row per Action Set under a single row of labels, a gold rule between the rows, the Reserve leading Set 1's row, and extras in columns to the right.
