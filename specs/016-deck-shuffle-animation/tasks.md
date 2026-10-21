---

description: "Task list for 016 — Shuffling the Deck Under the Card on Top"
---

# Tasks: Shuffling the Deck Under the Card on Top

**Input**: Design documents from `specs/016-deck-shuffle-animation/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/deck-shuffle.md](contracts/deck-shuffle.md), [quickstart.md](quickstart.md)

**Tests**: The plan and the quickstart call for headless tests. The project's convention is that pure models and Sequencer placement are tested in `tests/` and that screens are checked at every `MATRIX` shape. Test tasks are included.

**Organization**: Tasks are grouped by user story. The shared riffle and step plumbing are foundational. Each story then puts the `shuffle` step at its own moment, with its own tests.

**Working tree note**: there are unrelated uncommitted edits (Upgrade stepping) in `ui/model/sequencer.gd`, `ui/main.gd`, `ui/model/view_state.gd`, `ui/model/turn_draft.gd`, `tools/ui_check.gd`, `tests/test_sequencer.gd` and `tests/test_view_state.gd`. Build on them, and never revert them. In `tools/ui_check.gd`, only add to the file. Do not commit unless asked.

**Revision (2026-10-20, during implementation)**: the riffle first built per T005–T007 split the plain edge stack up to 35% of the card's height out from under it. The user rejected it ("pulls the cards too far out and exposes a blank stone colored side") and asked for NextQuest's riffle. T005–T007, T009, T014 and T024 were redone as research R4 (revised) describes: real Mage Cards, face up, peel out from under the card on top one after another, `T.SHUFFLE_PEEL` of a Key Card's rise. `shuffle_offsets`, `shuffle_spread` and `T.SHUFFLE_SPREAD` became `peel_lift`, `peel_at`, `peel_count` and `T.SHUFFLE_PEELS/ARC/PEEL/TILT/SCALE`. `shuffle(d)` became `shuffle(models, d)`, with the faces attached in `ui/main.gd` `_show_faces`. The test the plan called `test_a_whole_game_shuffles_four_times` lives in the whole-game replay test, and the count is 5, not 4: setup plus the ends of Regions 1–4.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: The task can run in parallel with others: it touches a different file and depends on no incomplete task.
- **[Story]**: US1 is between Regions, US2 the Dragon Card, US3 setup and start, US4 reduced motion and pace.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Tokens that every later task reads.

- [X] T001 Add the motion tokens in `ui/theme/tokens.gd`, after `TURN` in the `# Motion, in seconds` block, each with a `##` comment in the file's style:
  - `const SHUFFLE := 0.9`: the Deck riffled under the card on top (feature 016).
  - `const SHUFFLE_SPREAD := 0.35`: how far, as a share of the card's width, each packet slides out from under it.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The `shuffle` step exists end to end: the Sequencer knows it, the Animator plays it, and the Deck draws the riffle. No action emits it yet.

**⚠️ CRITICAL**: No user story can be placed until this phase is complete.

- [X] T002 Make the `shuffle` step known to the Sequencer in `ui/model/sequencer.gd`:
  - Add `"shuffle": T.SHUFFLE` to `DURATION`.
  - Add `"shuffle"` to `OWN_TIME`, so `_fit_time` never squeezes it (research R5).
  - In `apply()`, make `"shuffle"` a deliberate no-op (`pass`, with a comment that the gather's `values.deck` already holds the engine's order, FR-013).
  - Add `static func _shuffle_step(steps: Array, count: int) -> void`. It appends `_step("shuffle", [], {"count": count}, "deck")` only when `count > 0`. Give it a `##` comment citing specs/016.
- [X] T003 [P] Add `"shuffle"` to `QUIET_STEPS` in `ui/model/board_response.gd`.
- [X] T004 [P] Add `"shuffle"` to the `STEPS` list in `tests/test_board_responses.gd`, so `test_every_sequence_step_is_answered_or_quiet` covers it.
- [X] T005 [P] Add the pure geometry to `ui/widgets/deck_stack.gd`, beside `edge_rects()` in the `geometry (pure)` section:
  - `static func shuffle_offsets(n: int, t: float, spread: float) -> Array`, one `Vector2` per edge, deepest first (data-model.md):
    - It is ZERO at t = 0 and t = 1, and ZERO for every t when n < 2.
    - Split (0–0.3): even-index edges ease to `x = -spread`, odd-index edges to `+spread`. Each lifts by at most `EDGE_STEP`, with `y <= 0` meaning up.
    - Riffle (0.3–0.8): the edges return one at a time, alternating sides, deepest first. Each one's return is its own slice of the interval.
    - Square (0.8–1): every residual eases to ZERO.
    - Throughout, `|x| <= spread` and the edges never drop below their resting place.
  - `static func shuffle_spread(deck_size: Vector2, card: Rect2) -> float`: `T.SHUFFLE_SPREAD * card.size.x`, capped so that `card` grown by that much on both sides stays inside `Rect2(Vector2.ZERO, deck_size)`. It never goes below 0.
- [X] T006 [P] Add tests for T005 in `tests/test_deck_stack.gd`, in the file's style (`eq`/`ok`, one `test_…` per claim):
  - `test_the_shuffle_starts_and_ends_square`: ZERO at t = 0 and t = 1 for n in [2, 5, 8].
  - `test_the_shuffle_splits_to_both_sides`: at t = 0.3, the even edges are at `-spread` and the odd edges at `+spread`.
  - `test_the_shuffle_stays_within_its_spread`: sample t in steps of 0.05 and check `|x| <= spread` and `y <= 0`.
  - `test_a_single_card_is_not_riffled`: n = 0 and n = 1 give all ZERO.
  - `test_the_riffle_stays_on_the_deck_at_every_shape`: for every `Solver.MATRIX` name, use `_plan(name)` and `DeckStack.card_rect(deck_size, "card", true)` (plus the dragon variant), and check that the card grown by `shuffle_spread` lies inside the Deck's rect (FR-012).
- [X] T007 Add the riffle to `DeckStack` in `ui/widgets/deck_stack.gd` (depends on T005):
  - `var _shuffle_t := -1.0`, with a `##` comment.
  - `func shuffle(d: float) -> void`, documented as in [contracts/deck-shuffle.md](contracts/deck-shuffle.md). It emits `reveal_beat.emit("shuffle")` once at its start. With motion, it keeps a tween (`_keep`) that drives `_shuffle_t` from 0 to 1 over `d` with `_edges.queue_redraw()` on each step, then sets `_shuffle_t = -1.0` and redraws.
  - In `_draw_edges()`, while `_shuffle_t >= 0`, offset each rect from `edge_rects(_stack_rect, count)` by `shuffle_offsets(rects.size(), _shuffle_t, shuffle_spread(size, _stack_rect))[i]`. The shadow is drawn under the deepest rect's resting place. The edges stay plain card stock, `T.CARD_EDGE` with its `T.CARD_EDGE_LINE` border, so no face shows (FR-003).
  - In `finish()`, reset `_shuffle_t = -1.0` and redraw the edges.
  - Never touch `top_node()`'s position, scale or modulate in `shuffle` (contract guarantee 1).
- [X] T008 Play the step in `ui/fx/animator.gd` `_run()`: add a `"shuffle":` branch that calls `screen.deck.shuffle(d)` and does nothing else (no ghost, no header bump). Add `"shuffle"` to the keep-its-time list in `reduced_duration()`, and update its `##` comment to mention the shuffle.
- [X] T009 Add a `shuffle()` + `finish()` test in `tests/test_deck_stack.gd`, `test_finishing_a_shuffle_squares_the_deck`. Build a `DeckStack`, size it, and render a minimal state with a Region top card (follow how existing node-level tests in `tests/` build widgets, or `tools/ui_check.gd` if none do). Call `shuffle(0.9)`, then `finish()`. Check that `_shuffle_t == -1.0` and that the top node's position equals its position before the call.

**Checkpoint**: `tools/test.sh` passes, and nothing on screen has changed yet, because no action emits `shuffle`.

---

## Phase 3: User Story 1 - The Deck is shuffled under the next Region Card between Regions (Priority: P1) 🎯 MVP

**Goal**: At each End of Regions 1–3, after the card turns and the Discard comes back, the stack riffles under the next Region's card before the banner and the new Hand.

**Independent Test**: Play to the End of Region 1. Between the card turning to Region 2 and the first draw, the riffle plays under the Region 2 card. No Mage Card face shows.

- [X] T010 [US1] In `ui/model/sequencer.gd` `build()`, in the `"finish"` branch inside `if _gathered(before, after):`, call `_shuffle_step(steps, back.values.deck.size())` directly after `steps.append(back)` (the `gather_shuffle {from: "discard"}`) and before the `stage_banner`. This one call also serves the Final Battle (US2), since the branch covers both.
- [X] T011 [US1] Extend `_check_deck_steps` in `tests/test_sequencer.gd`. For a Region-change `finish` (`after.region != before.region`), assert that `kinds.count("shuffle") == 1`, and that the shuffle comes after both `kinds.find("turn_card")` and `kinds.find("gather_shuffle")` and before `kinds.find("stage_banner")` and the first `draw`. Assert that `steps[shuffle].values.count == steps[gather].values.deck.size()`.
- [X] T012 [US1] In `tests/test_sequencer.gd`, add `"shuffle"` to the `kinds_seen` list at the end of `test_steps_replay_to_the_engine_state_for_whole_games`, so the replay still reaches every after snapshot with the no-op step in place.
- [X] T013 [US1] In `tests/test_sequencer.gd` `_check_deck_steps`, assert that no `shuffle` appears for `divert`, `regroup`, `play`, `play_final`, `soak`, `upgrade` or a `finish` that keeps the Region and phase (FR-008).
- [X] T014 [US1] Add to `tools/ui_check.gd` (append only). Next to the existing reveal-beat checks, connect `deck.reveal_beat` across an End of Region 1 at every `MATRIX` shape, and `_ok` that `"shuffle"` fires once and before `"key_lit"`. Mid-shuffle (a few frames after the beat), `_ok` that the Deck's rect still does not overlap the Hand, the header or the action row, reusing that file's overlap helper.

**Checkpoint**: The MVP. Region changes show the riffle, and the tests pass.

---

## Phase 4: User Story 2 - The Deck is shuffled under the Dragon Card before the Final Battle (Priority: P1)

**Goal**: After Region 4, the riffle plays under the Dragon Card before the Final Journey's seven cards are drawn.

**Independent Test**: Play to the end of Region 4. The Dragon Card goes on top, the riffle plays under it, and then the seven cards come and the view zooms into the MP Tiers.

- [X] T015 [US2] Confirm that T010's call covers `after.phase == "final_journey"`, since `_gathered()` is true there. Then extend `_check_deck_steps` in `tests/test_sequencer.gd` so that the Region-change assertions from T011 also run for `finish` into `final_journey`. Also assert that `steps[turn_card].values.to == "dragon"` comes before the shuffle.
- [X] T016 [US2] Add a test in `tests/test_sequencer.gd`, `test_a_whole_game_shuffles_five_times`. Count `shuffle` steps across every action of one seeded game that reaches `final_journey`, and assert exactly 5: setup or start, plus Regions 1→2, 2→3, 3→4 and 4→dragon (SC-001). Reuse the whole-game loop's action dispatch, or factor it into a helper that both tests call. This passes only after US3 (T018/T019). Until then, mark it expected to fail, or write it in Phase 5.
- [X] T017 [P] [US2] Add a `"shuffle"` mode to `tools/design_shots.gd`, beside `"deck"` and `"notes"` (`-- <out dir> shuffle`). Drive a game to the End of Region 1 and to the End of Region 4. When `deck.reveal_beat` emits `"shuffle"`, wait about half of `T.SHUFFLE`, then save `shuffle_region2.png` and `shuffle_dragon.png` to the out dir. Document the mode in the file's `##` header.

**Checkpoint**: The Final Battle shows the riffle under the Dragon Card.

---

## Phase 5: User Story 3 - The Deck is shuffled under Region 1's card after setup (Priority: P2)

**Goal**: The first shuffle plays under the Region 1 card once it is laid down, after setup, or at the start of a game with no setup to choose.

**Independent Test**: Start a new Normal game and confirm setup. The cards fly back, the note is thrown off, the Region 1 card is laid down, the riffle plays, then the banner and the first Hand. On a difficulty with no setup offer, the riffle still plays once before the first Hand.

- [X] T018 [US3] In `ui/model/sequencer.gd` `build()`, in the `"setup"` branch, call `_shuffle_step(steps, back.values.deck.size())` directly after `steps.append(_step("turn_card", [], {"from": 0, "to": after.region}, "deck"))` and before the `stage_banner` (research R3, FR-007).
- [X] T019 [US3] In `ui/model/sequencer.gd` `build()`, in the `"start"` branch, call `_shuffle_step(steps, after.hand.size() + after.deck.size())` before the `stage_banner`. The Region 1 card is already on via `DeckStack.show_card()` in `ui/main.gd` `start_game`.
- [X] T020 [US3] In `tests/test_sequencer.gd` `_check_deck_steps`, add assertions for `what == "setup"` and `what == "start"`:
  - `kinds.count("shuffle") == 1`.
  - For setup, the shuffle comes after `turn_card`. That makes it after the `gather_shuffle {undraw}` too.
  - For both, it comes before `stage_banner` and the first `draw`.
  - The existing assertion `turn > gather_shuffle and turn < stage_banner` still holds.
- [X] T021 [US3] Add a `"start"` case to `tests/test_sequencer.gd`. Find a seeded game whose engine phase is `challenge` right after `Game.new` (no setup offer), or build the `start` steps as `ui/main.gd` `start_game` does, from the empty snapshot. Assert that exactly one `shuffle` comes before the first `draw`, with `values.count == after.hand.size() + after.deck.size()`. If no difficulty has an empty offer, test the `start` steps from the snapshot directly.
- [X] T022 [US3] Make T016's count of 5 pass, removing any expected-fail marker.

**Checkpoint**: Every real shuffle in a game is shown, 5 per full game.

---

## Phase 6: User Story 4 - The shuffle respects reduced motion and the pace of play (Priority: P3)

**Goal**: Under reduced motion, nothing moves and "Deck shuffled" is shown briefly. A press during the riffle hurries on as it does through any other step before the Key Card.

**Independent Test**: With reduced motion on, play to the End of Region 1: there is no movement, and the caption shows on the Region 2 card. With it off, tap during the riffle: the Key Card is up, waiting, and the stack is squared.

- [X] T023 [US4] Add the reduced-motion caption to `ui/widgets/deck_stack.gd`:
  - `var _shuffle_label := Label.new()`, added under `_table` above `_tops` in `_init()`. The text is "Deck shuffled", at body size ≥ 22, `T.INK` on the card-stock chip style the Deck already uses for captions (or `UI.box(T.CARD_EDGE, T.CARD_EDGE_LINE, …)`). It is hidden by default, with `mouse_filter` set to ignore.
  - In `shuffle(d)`, under `UI.reduced_motion`, apply no offsets (leave `_shuffle_t` at -1). Centre the label on `top_rect()`'s lower third, and tween its `modulate.a` 0 → 1 over `d * 0.2`, hold, then 1 → 0 over `d * 0.2`, kept in `_tweens`.
  - In `finish()`, hide the label and reset its alpha.
  - In `_place()`, reposition it if it is visible (resize during the step).
- [X] T024 [US4] Add a test in `tests/test_deck_stack.gd`, `test_reduced_motion_shuffles_still`, following `tests/test_creature.gd`'s save and restore of `UI.reduced_motion`. With reduced motion on, call `shuffle(0.9)`. Assert that `_shuffle_t == -1.0` (nothing offset), that `_shuffle_label.visible`, and that the label's font size is ≥ 22. After `finish()`, assert the label is hidden.
- [X] T025 [US4] Add `"shuffle"` to the `at` list in `_skip_walk` in `tools/ui_check.gd` (append only), so a tap mid-riffle is checked to land on the Key Card waiting. After the tap, `_ok` that `ui.play.deck._shuffle_t == -1.0`.
- [X] T026 [US4] Add a timing test in `tests/test_sequencer.gd`, `test_the_shuffle_keeps_its_own_time`. For a Region-change `finish`, check that the `shuffle` step's duration is `T.SHUFFLE` after `_fit_time`, and that `T.SHUFFLE <= 1.5`. Check that the sum of the durations of every step except `shuffle` is unchanged from the same build without the shuffle, so the sequence grows by exactly `T.SHUFFLE <= 1.0` (SC-002). Compute the second build by filtering `shuffle` out of the steps and recomputing; do not add any flag to production code.

**Checkpoint**: All four stories are done.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T027 [P] Update the header comment of `ui/widgets/deck_stack.gd` (the back-to-front layer list) to say that the edges riffle under the top card while the Deck is shuffled (specs/016).
- [X] T028 [P] Update the header comment of `ui/model/sequencer.gd`, or the `build()` doc, to list `shuffle` among the steps. Note the steps whose time is their own, next to `OWN_TIME`.
- [X] T029 Run `tools/test.sh` and fix any failure. Report the outcome faithfully.
- [X] T030 Run `godot --path . -s tools/design_shots.gd -- <scratchpad out dir> shuffle`. Look at both shots: the top card is whole and on top, plain edges fan out to both sides, and no Mage face shows.
- [ ] T031 Walk the quickstart's "By hand" steps 1–6 on desktop, or with the `install-on-emulators` skill, and note any deviation.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (T001)** blocks everything.
- **Foundational (T002–T009)** blocks every story. T005 → T007. T006 depends on T005. T009 depends on T007. T008 depends on T007's `shuffle()` existing.
- **US1 (T010–T014)** depends on Foundational only.
- **US2 (T015–T017)** depends on T010, because the same call covers it. T016 also needs US3.
- **US3 (T018–T022)** depends on Foundational only, and can run beside US1. T022 needs T016.
- **US4 (T023–T026)** depends on T007. T025 depends on US1 producing a riffle to tap through.
- **Polish (T027–T031)** comes after the stories wanted.

### Parallel Opportunities

- After T001: T003, T004 and T005 run in parallel (different files). T002 and T005 are in different files too.
- After T005: T006 runs beside T007.
- US1 (sequencer `finish` branch) and US3 (sequencer `setup` and `start` branches) touch the same file, so they are not [P] with each other. Their test tasks are in the same test file, so they are serial too.
- T017 (`tools/design_shots.gd`) runs beside any sequencer or test task.
- T027 and T028 run in parallel.

### Parallel Example: Foundational

```text
Task: "T003 Add shuffle to QUIET_STEPS in ui/model/board_response.gd"
Task: "T004 Add shuffle to STEPS in tests/test_board_responses.gd"
Task: "T005 shuffle_offsets / shuffle_spread in ui/widgets/deck_stack.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. T001 → T002–T009: the riffle exists and is tested, and nothing emits it yet.
2. T010–T014: Region changes riffle. Validate with quickstart "By hand" step 2.
3. Stop, and show it to the user before going on.

### Incremental Delivery

1. Add US2 (the Dragon Card; the call is already in, so this is tests and shots).
2. Add US3 (setup and start). The count of 5 per game now holds.
3. Add US4 (reduced motion caption, skip check, timing test).
4. Polish: comments, the full `tools/test.sh`, shots and a walk-through.

---

## Notes

- `shuffle` must never be emitted with `count == 0` (`_shuffle_step` guards this).
- Do not touch Regroup's `gather_shuffle {keep_discard}` path or its gold ghost (spec Assumptions; research R1).
- Do not rename `gather_shuffle` (research R2).
- Commit only when the user asks, with no Claude attribution lines (project memory).
