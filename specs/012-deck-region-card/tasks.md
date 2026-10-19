---

description: "Task list for 012 The Deck and Region Card on the Playfield"
---

# Tasks: The Deck and Region Card on the Playfield

**Input**: Design documents from `specs/012-deck-region-card/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/reveal-sequence.md](contracts/reveal-sequence.md), [contracts/deck-stack.md](contracts/deck-stack.md), [quickstart.md](quickstart.md)

**Tests**: Included. The project tests every pure model headless and every screen in `ui_check` (plan, Constitution Check). Research R10 lists the tests.

**Organization**: Tasks are grouped by user story (spec.md US1–US4).
- **US1 owns the zoom.** The Region Card is only seen zoomed out (contracts/deck-stack.md), so the zoom between the tile and the face is how it becomes visible at all.
- **US2 adds the Key Card peek** and the creature waiting for the zoom.
- **Units:** every figure is in design units.
- **Check:** run `tools/test.sh` after each phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story the task belongs to (US1–US4)

---

## Phase 1: Setup

- [X] T001 Run `tools/test.sh` on the unchanged tree and confirm it is green, so later failures are this feature's.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: The tokens, the view-state fields and the empty `DeckStack` host that every story builds on. After this phase the screen looks as it does today, with the faces inset by the stack margin.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 In `ui/theme/tokens.gd`, add:
  - `DECK_EDGE := 24` (research R2);
  - `ZOOM := 0.55`;
  - `TURN := 0.5`;
  - `PEEK_RISE := 0.25`, `PEEK_HOLD := 0.4`, `PEEK_FALL := 0.2` (research R3, R4, R6).

  Raise `ENCOUNTER_MIN` from 316 to 340 and `DRAGON_MIN` from 276 to 300 (each `+ DECK_EDGE`), with a comment saying why.
- [X] T003 [P] In `ui/model/view_state.gd` `build()`, add `top_card`, `key_face` and `zoom` per data-model.md "View state additions" and the "`zoom` rules" table:
  - **`top_card`**: null in `setup`. Otherwise `RegionCard.model(db, game.region)` in a Region, or `DragonCard.model(game.dragon)` once `game.phase` begins with `final` or is `won`/`lost` after the Final Battle. Preload `RegionCard` once T011 adds its static `model`. Until then, `top_card` is `{kind: "region", region: game.region}`. Preload `DragonCard` once T029 exists; until then, the Final Battle branch returns `{kind: "dragon"}`.
  - **`key_face`**:
    - `_card(game, draft, db, id, vs)` for `id = game.deck[0]` in `challenge` **and `poison`**. `poison` follows the Cleanup draw, so the new Key Card is on top, and the reveal before the poison damage must lift it;
    - `game.faced.key` in `penalty`/`upgrade` only;
    - otherwise null.
  - **`zoom`**, exactly per data-model.md "`zoom` rules":
    - `"%s:%d" % [kind, index]` of `game.encounter()` in `challenge`/`poison`, and of `game.faced.encounter` in `penalty`/`upgrade`;
    - `"mp"` in `final_journey`;
    - `"hp"` in `final_enemy`/`final_soak` and `won`;
    - in `lost`, `"mp"` if `extra.lost_at == "the Final Journey"`, else `"hp"`;
    - `""` in `setup`.
- [X] T004 [P] Add to `tests/test_view_state.gd`:
  - `zoom` equals `"enemy:N"`/`"journey:N"` from `game.encounter()` in `challenge`, and stays the faced Encounter in `upgrade`;
  - `key_face.id == game.deck[0]` in `challenge` and in `poison` (drive a seeded game into `poison` as `test_game.gd` does), and `== game.faced.key` in `upgrade`;
  - `zoom == "hp"` when `won`; in `lost`, `zoom == "mp"` with `lost_at = "the Final Journey"` and `"hp"` otherwise;
  - `top_card == null` in `setup`;
  - `top_card.kind == "region"` in a Region.
- [X] T005 Create `ui/widgets/deck_stack.gd` (`extends Control`, `clip_contents = true`, mouse filter IGNORE) with a header comment describing the four layers in contracts/deck-stack.md "Layers, back to front". Add:
  - **Static `edges(count: int) -> int`**: `0` for `count <= 0`, else `clampi(ceili(count / 2.0), 1, 8)`.
  - **Static `face_rect(size: Vector2) -> Rect2`**: `Rect2(0, 0, size.x - T.DECK_EDGE, size.y - T.DECK_EDGE)`.
  - **Children**: an `_edges` Control that draws `edges(count)` outlines of `face_rect` offset 3 units down-right each, in `T.BG_RAISED` with a `T.BRONZE_DARK` 1.5 rim, deepest first. It also has three empty slots in order: `_peek_slot`, `_top_slot`, `_face_slot`.
  - **`var encounter_face`, `dragon_face`, `setup_face`**, moved here from `ui/screens/play_screen.gd`: created in `_init`, added to `_face_slot`, placed at `face_rect(size)` on `resized`.
  - **`render(vs)`**:
    - sets `count = vs.piles.deck` (16 in `setup`) and redraws the edges;
    - shows exactly one face, with the logic of `play_screen._render_encounter()` / `_render_setup_face()` moved here unchanged, including `dragon_face.set_reached(-1)`;
    - `view = "face"`.
  - **`face_node() -> Control`**: the visible face.
- [X] T006 In `ui/screens/play_screen.gd`:
  - fill `_regions.encounter` with one `DeckStack` (`var deck := DeckStack.new()`) instead of the three faces;
  - replace `_render_encounter()` with `deck.render(vs)`;
  - make `encounter_node()` return `deck.face_node()`;
  - make `encounter_face`, `dragon_face` and `setup_face` forward to `deck.encounter_face` etc., so `_replan`, `flare` and `ui/main.gd` keep working;
  - connect the faces' `intent` through `deck`;
  - update the file's header comment to say the left side is the Deck.

  Run `tools/test.sh`. Every existing suite and `ui_check` stays green with the faces inset by `DECK_EDGE`.
- [X] T007 [P] Create `tests/test_deck_stack.gd` (register it in `tests/run.gd` as the other suites are) testing:
  - `edges` at 0→0, 1→1, 2→1, 3→2, 5→3, 15→8, 16→8;
  - `face_rect(Vector2(500, 400)) == Rect2(0, 0, 476, 376)`.

**Checkpoint**: The left side is a stack of edges with today's face on it. The depth follows the Deck count.

---

## Phase 3: User Story 1 — The left side is the Deck, with the Region Card on top (Priority: P1) 🎯 MVP

**Goal**: The current Region Card lies on top of the Deck. At each new Encounter the view is zoomed out to the whole Region Card, then zooms into the Encounter's tile until it is the face.

**Independent Test**: Start a game. When Region 1's first Encounter begins, the whole Jade Mountains Region Card shows on the stack (band, eight tiles), then zooms into the chosen tile, which becomes today's face. The stack thins as the header's Deck count falls (spec US1).

### Tests for User Story 1

- [X] T008 [P] [US1] Create `tests/test_region_card.gd` (register in `tests/run.gd`) for `RegionCard.model(db, region)`:
  - it has exactly 8 tiles, in the order Enemies 1–4 then Journeys 1–4;
  - each `key` is `"enemy:N"`/`"journey:N"`;
  - each Enemy tile's `stat` is `{icon: "hp", value: data.hp}`, and each Journey's is `{icon: "mp_badge", value: data.mp.value, element: data.mp.element}`;
  - `effect` is the Ability/Peril or null, never a Hardship;
  - `code` is `"DOE-R01"` for Regions 1 and 2 and `"DOE-R02"` for 3 and 4;
  - `side` is 0, 1, 0, 1 for Regions 1–4.
- [X] T009 [P] [US1] Add to `tests/test_deck_stack.gd`:
  - for each `layout_solver.MATRIX` shape's solved `regions.encounter` size, `DeckStack.card_rect(size, "card", peek_h)` lies inside the region;
  - every `RegionCard.tile_rect(card_rect, key)` has the aspect ratio of `face_rect(size)` within 2%;
  - `DeckStack.zoom_scale(face, tile)` equals `face.size.x / tile.size.x`, and gives the same value from `y`, within 2%.

  Use `peek_h = 0` until T017 adds the peek.
- [X] T010 [P] [US1] Add to `tests/test_sequencer.gd`, per contracts/reveal-sequence.md "Per action":
  - `start`, `setup`, `finish` (same Region and next Region) and `divert` all end (before `ending`) in `zoom_in` with `values.target` equal to `ViewState.build(...).zoom` of the after state;
  - `finish` and `divert` contain `zoom_out` before their first `discard`;
  - `play`, `upgrade` and `soak` contain neither;
  - `setup` emits `turn_card {from: 0, to: 1}` after `gather_shuffle` and before `stage_banner` (the Region Card is placed on top, as in rulebook Setup step 4);
  - the existing replay test still passes with the new steps (invariants 2, 3 and 5).

### Implementation for User Story 1

- [X] T011 [US1] Create `ui/widgets/region_card.gd` (`extends "res://ui/widgets/face_frame.gd"`). Add a static `model(db, region)` returning the dictionary in data-model.md "Region Card model" and "Tile":
  - `code` comes from `db.region(region).card`;
  - `side = (region - 1) % 2`;
  - tiles are built with `db.encounter`, `Art.encounter_name`, `Art.encounter`.

  `render(model)` draws:
  - **The band**: the `sigil_region` icon, `"REGION %d" % region` and the name upper-cased (`T.HEADING`, stepping down to `T.TEXT_MIN` to fit, as `encounter_face.gd` does), with `code` in `T.LABEL`/`T.INK_MUTED` at the right.
  - **The body**: two rows of four tiles, gaps `T.XS`.
  - **Each tile**:
    - the Encounter icon (`"enemy"`/`"journey"`) and its number with `Numerals` at ≥ 22;
    - a held-still `Creature` of `tile.art`, cropped with `EncounterFace.enemy_crop` for Enemies or `Art.FULL` for Journeys;
    - one `StatChip` for `tile.stat`;
    - the effect's `Glossary` icon if any.

  Add `tile_rect(card_rect, key) -> Rect2` (static, pure) that lays tiles out with each tile's aspect equal to `DeckStack.face_rect` aspect. Shrink the tiles to fit and centre them. Make T008/T009 pass.
- [X] T012 [US1] In `ui/widgets/deck_stack.gd`, add:
  - a `RegionCard` in `_top_slot`, rendered from `vs.top_card`;
  - `view` (`"card"` or `"face"`) and `held`;
  - static `card_rect(size, view, peek_h)` and `zoom_scale(face, tile)` per data-model.md "Derived geometry".

  `render(vs)`: when `held` is false, set `view = "face"` if `vs.zoom != ""`, else `"card"`. In `"face"` the top card is hidden under the face; in `"card"` the face is hidden and the top card shows at `card_rect`. When `held` is true, update the count and the face's contents but leave `view` **and the shown top card** unchanged (data-model.md "Transitions"). Keep the previous `top_card` model on screen until `turn_to` or `finish()` applies the new one, so a `draw` step's `render(_after)` can't swap or reveal the top card early. Also add `show_card()`: `view = "card"` at once, no tween.
- [X] T013 [US1] In `ui/widgets/deck_stack.gd`, implement:
  - **`hold_card(on)`**.
  - **`zoom_out(d)`**: the face shrinks from `face_rect` to the tile rect of `vs.zoom` and fades out over its last 40%. The Region Card starts scaled by `zoom_scale` about that tile's centre (`pivot_offset`) and returns to scale 1 at `card_rect`, fading in over its first 40%. Use `TRANS_CUBIC`, `EASE_IN_OUT`; then `view = "card"`.
  - **`zoom_in(target, d)`**: the exact reverse into `target`'s tile, then `view = "face"`, `held = false`.
  - **`finish()`**: kill this widget's tweens, reset scales, pivots and alpha, set `held = false`, and re-apply `render(vs)`.
  - **`turn_to(top_card, d)`**, first case only (`from: 0`, setup): with no top card shown, the Region Card drops onto the stack from `DECK_EDGE` above `card_rect` and fades in over `d`. Then it becomes the shown top card. US4 (T031) adds the half-turn and the swap.
  - **Reduced motion** (`UI.reduced_motion`): both zooms and the drop are a cross-fade of `2 × T.FAST` with no scale or travel (research R3).

  Keep every tween in an array, as `animator.gd` `_keep` does.
- [X] T014 [US1] In `ui/model/sequencer.gd`:
  - add `zoom_out` and `zoom_in` (`T.ZOOM`) and `turn_card` (`T.TURN`) to `DURATION`;
  - in `setup`, emit `turn_card {from: 0, to: 1}` after `gather_shuffle` and before `stage_banner`;
  - emit the zooms where contracts/reveal-sequence.md "Per action" puts them (for now without `key_peek`, which arrives in US2, and the Region-change `turn_card`s, which arrive in US4):
    - **`zoom_out`**: first in `finish` after `xp_lost`, first in `divert`, first in `regroup`, and in `play_final` Final Journey → Final Enemy after `gain_xp`;
    - **`zoom_in`** with `values.target`: last before `ending` in `start`, `setup`, `finish` (unless the game ended), `divert`, `regroup` and that `play_final` case;
  - work out the target from `after` with a static `zoom_for(snapshot) -> String` helper that applies data-model.md's "`zoom` rules" to the snapshot's `phase` and `encounter`. `ViewState.snapshot` has no Encounter today, so add `"encounter": {kind, index, hardship}` to it in `ui/model/view_state.gd`: `game.encounter()` in `challenge`, `game.faced.encounter` in `penalty`/`upgrade`/`poison`, else null. US2's `key_peek` reads the same field.
  - `apply()` passes both through unchanged.
  - `_fit_time` scales only the steps before the first reveal step (`key_peek` or `zoom_in`) to `T.SEQUENCE_MAX` (research R8).

  Make T010 pass.
- [X] T015 [US1] In `ui/fx/animator.gd`:
  - **`play()`**: if any step is `zoom_in`, call `screen.deck.hold_card(true)`.
  - **`_run`**: add `"zoom_out"` → `screen.deck.zoom_out(d)`, `"zoom_in"` → `screen.deck.zoom_in(st.values.target, d)` and `"turn_card"` → `screen.deck.turn_to(_after.top_card, d)`.
  - **`_finish()`**: call `screen.deck.finish()` before `screen.render(_after)`.
  - **`ui/main.gd` start-of-game**: the bare render sits zoomed out. After `play.render(bare)`, call `play.deck.hold_card(true)` and make the deck show `"card"` (a `show_card()` on DeckStack that sets `view = "card"` without tweening) before `animator.play`.
- [X] T016 [US1] In `tools/ui_check.gd`, during the animated seeded games at every `MATRIX` shape:
  - after each settle, assert `ui.play.deck._edges` draws `DeckStack.edges(vs.piles.deck)` edges (SC-004) and `ui.play.deck.view == "face"` (except in `setup`);
  - assert `ui.play.encounter_face._shown == vs.encounter` when a Region Encounter shows (SC-005);
  - between a `draw` step and the `zoom_in` step, assert `view == "card"` (plan Risks);
  - assert every Region Card tile number/stat label is ≥ 22 and every tile rect lies inside the deck region.

  Run `tools/test.sh`.

**Checkpoint**: US1 works:
- On Begin, the Region 1 card drops onto the stack.
- Every new Encounter zooms out to the Region Card and into the chosen tile, and skipping lands on the face.
- Until US4, a Region change swaps the card in at once when the sequence settles.

---

## Phase 4: User Story 2 — The Key Card under the Region Card picks the Encounter (Priority: P1)

**Goal**: Once the Hand settles, the Key Card rises from beneath the Region Card just far enough to show its Encounter number and any Hardship, then slides back. The zoom follows, and the Encounter's creature starts moving when it lands.

**Independent Test**: At any Region Encounter, a Mage Card's title band and bronze strip (e.g. "Enemy 2" plus Storm) rise above the Region Card, slide back, and Enemy 2's tile zooms into the face, whose creature then moves. With reduced motion on, the strip fades in and out and the face appears with no zoom (spec US2).

### Tests for User Story 2

- [X] T017 [P] [US2] Add to `tests/test_deck_stack.gd`: `DeckStack.peek_h(card_w)` equals `band + strip` of a `CardFace` laid out at width `card_w`. For each `MATRIX` shape's Hand card width (`plan.positions[0].card.size.x`), `card_rect(size, "card", peek_h)` still lies inside the region and its top is ≥ `peek_h`.
- [X] T018 [P] [US2] Add to `tests/test_sequencer.gd` (contracts/reveal-sequence.md invariants 1, 4 and 6):
  - every Region `zoom_in` is directly preceded by `key_peek`;
  - `key_peek.values.key == after.deck[0]`, and `{kind, index, hardship}` equal the engine's `encounter()` after the action, including after each of two Diverts in a row;
  - `key_peek` never appears once the phase begins with `final`;
  - the reveal (`key_peek` + `zoom_in`) totals ≤ 1.4 s and is not scaled by `_fit_time` even when a Region change pushes the rest past `T.SEQUENCE_MAX`;
  - `Animator.reduced_duration(step)` (T023) returns ≥ 0.6 for `key_peek` and `minf(d, 2 × T.FAST)` for every other step except `stage_banner` (FR-011).
- [X] T019 [P] [US2] Add to `tests/test_creature.gd`: setting `held = true` makes `_apply_motion()` set the shader `amount` to 0 and stop particles, and clearing it restores them unless `UI.reduced_motion`.

### Implementation for User Story 2

- [X] T020 [P] [US2] In `ui/fx/creature.gd`, add `var held := false` (setter calls `_apply_motion()`). `_apply_motion()` makes the creature still when `UI.reduced_motion or held`, and `_process` re-applies when either changes. In `ui/widgets/face_frame.gd`, add `set_held(on)` → `_creature.held = on`. Make T019 pass.
- [X] T021 [US2] In `ui/widgets/deck_stack.gd`, add the Key Card peek in `_peek_slot`: a `CardFace` (`ui/widgets/card_face.gd`) given `vs.key_face`, sized to the Hand's card size. `play_screen.gd` passes `plan.positions[0].card.size` to `deck.set_card_size()` in `render`. The peek is centred horizontally on the top card and hidden at rest behind it. Then:
  - add static `peek_h(card_w)` per data-model.md;
  - make `card_rect(size, "card", peek_h)` move the top card down by `peek_h` and scale it to fit, keeping its aspect ratio;
  - implement `peek(key_face, d)`: rise until the peek's bottom is `peek_h` above the top card's top edge (`T.PEEK_RISE`, `EASE_OUT`), hold `T.PEEK_HOLD` with the strip's Encounter and Hardship ringed (call the card face's existing ring for `"encounter"` and, if `lv.hardship != null`, `"hardship"`), then fall back (`T.PEEK_FALL`, `EASE_IN`);
  - **reduced motion**: fade in already raised, hold, fade out.

  `finish()` hides the peek at rest. Make T017 pass.
- [X] T022 [US2] In `ui/widgets/deck_stack.gd`, hold the face's creature (`face.set_held(true)`) whenever the face is hidden or zooming. Release it only when `zoom_in` lands or `finish()` runs (FR-005a). The Region Card tiles' creatures are always held (research R7).
- [X] T023 [US2] In `ui/model/sequencer.gd`, add `key_peek` (duration `T.PEEK_RISE + T.PEEK_HOLD + T.PEEK_FALL`, values `{key: after.deck[0], kind, index, hardship}` from the after snapshot's encounter) directly before every Region `zoom_in`: `start`, `setup`, `finish` without a Region change, `finish` with one into Regions 2–4, and `divert`.
  - In `finish` → `poison`, put the reveal before the poison `damage` step.
  - In `ui/fx/animator.gd` `_run`, add `"key_peek"` → `screen.deck.peek(_after.key_face, d)`.
  - **Exempt `key_peek` from the reduced-motion clamp.** `play()` today shortens every step but `stage_banner` to `minf(d, T.FAST × 2.0)` (0.3 s), which leaves no time to read the strip. Move that rule into a static `reduced_duration(step) -> float`, used by `play()`. It returns `maxf(0.6, T.FAST × 2.0)` for `key_peek` (a `T.FAST` fade in, a ≥ 0.3 hold, a `T.FAST` fade out), `step.duration` for `stage_banner`, and `minf(step.duration, T.FAST × 2.0)` otherwise.
  - In `deck_stack.gd` `peek()`, the reduced-motion path splits `d` as fade in `T.FAST`, hold `d − 2 × T.FAST`, fade out `T.FAST`.
  - Make T018 pass.

**Checkpoint**: US1 and US2 together give the full Region reveal: the Hand is drawn, the Key Card rises and slides back, the view zooms in and the creature wakes.

---

## Phase 5: User Story 3 — The Hand is drawn from the Deck (Priority: P2)

**Goal**: Drawn cards visibly leave from under the top card, and discarded and trashed cards and Time Penalties go to the back of the stack.

**Independent Test**: Finish an Encounter. The Action Set flies to the stack's bottom-right, and replacements fly from under the Region Card into the Hand. The stack thins by the number drawn (spec US3).

- [X] T024 [US3] In `ui/widgets/deck_stack.gd`, add `top_point() -> Vector2` (global: the centre of the top card's top edge at its current rect) and `back_point() -> Vector2` (global: the bottom-right corner of the deepest edge). In `ui/screens/play_screen.gd` `point()`:
  - map `"deck"` → `deck.top_point()`;
  - map `"discard"` and `"trash"` → `deck.back_point()`;
  - keep `header.bump()` calls as they are (research R9, contracts/deck-stack.md "Anchors").

  `hand.sync(..., arrive_from)` and every animator flight already go through `point()`.
- [X] T025 [US3] In `ui/widgets/deck_stack.gd`, add `bump(delta)`, which changes the drawn `count` by `delta` and redraws the edges. In `ui/fx/animator.gd`, wherever `screen.header.bump("deck", n)` is called (`pay_time`, `discard` from deck), also call `screen.deck.bump(n)`. In the `draw` step, the stack thins through `render(_after)` already.

  **Refill before the draw (FR-009).** Add `set_count(n)` to `DeckStack` (data-model.md "Transitions"). In `animator.gd`'s `gather_shuffle` branch, once the gathered cards have flown in (after `d × 0.8`), call `screen.deck.set_count(st.values.deck.size())`. The stack then visibly refills to the reshuffled Deck before `turn_card` and `draw`. Because the stack is held during the sequence, the later `draw` step's `render(_after)` then thins it by the Hand drawn.

  Add a check to `tools/ui_check.gd`'s animated games: at the first `turn_card` or `draw` step after a `gather_shuffle`, the drawn count equals that step's `values.deck.size()`.
- [X] T026 [US3] In `tools/ui_check.gd`, assert `ui.play.point("deck")` and `ui.play.point("discard")` both lie inside `plan.regions.encounter` at every shape. Run `tools/test.sh`.

**Checkpoint**: The two sides are joined: cards come from and go to the stack.

---

## Phase 6: User Story 4 — Region changes and the Final Battle (Priority: P3)

**Goal**:
- The Region Card half-turns between Regions on the same card (1→2, 3→4) and swaps between cards (2→3).
- The Dragon Card replaces it for the Final Battle and is zoomed into at its MP Tiers, then its HP Tiers.

**Independent Test**: At the end of Region 1 the card half-turns to Region 2. At the end of Region 2 it swaps for Region 3. After Region 4 the Dragon Card arrives and the view zooms into its MP Tiers. After the Final Journey's Play it zooms out and back into its HP Tiers (spec US4).

### Tests for User Story 4

- [X] T027 [P] [US4] Add to `tests/test_sequencer.gd`:
  - **`finish` across a Region**: emits `turn_card` after `gather_shuffle` and before `stage_banner`, with `{from: before.region, to: after.region}`.
  - **`finish` from Region 4**: emits `{from: 4, to: "dragon"}` followed by `zoom_in {target: "mp"}` with no `key_peek`.
  - **`play_final`** (Final Journey → Final Enemy): emits `zoom_out` … `zoom_in {target: "hp"}`.
  - **`regroup`**: emits `zoom_out` … `zoom_in {target: "mp"}`.
- [X] T028 [P] [US4] Add to `tests/test_deck_stack.gd`: `DragonCard.target_rect(card_rect, "mp")` and `(…, "hp")` lie inside the card rect, don't overlap, and each has the aspect ratio of `face_rect` within 2%.

### Implementation for User Story 4

- [X] T029 [US4] Create `ui/widgets/dragon_card.gd` (`extends "res://ui/widgets/face_frame.gd"`):
  - static `model(dragon)` per data-model.md "Dragon Card model" (`code` from `dragon.card`);
  - `render(model)`: a band with the dragon's name and title (and the code at the right, as on the Region Card) over `ui/widgets/dragon_stats.gd`'s two ladders, the MP Tiers column then the HP Tiers column;
  - static `target_rect(card_rect, target)`: the column's rect, padded to the face aspect.

  In `ui/model/view_state.gd`, remove the T003 guard so `top_card` is the Dragon Card model in the Final Battle. Make T028 pass.
- [X] T030 [US4] In `ui/widgets/deck_stack.gd`, add a `DragonCard` beside the `RegionCard` in `_top_slot`, shown when `vs.top_card.kind == "dragon"`. Make `zoom_out`/`zoom_in` use `DragonCard.target_rect` for `"mp"`/`"hp"` and `RegionCard.tile_rect` otherwise. The zoomed face for `"mp"`/`"hp"` is `dragon_face`.
- [X] T031 [US4] In `ui/widgets/deck_stack.gd`, extend `turn_to(top_card, d)` from T013 (view must be `"card"`) with the two remaining cases:
  - **Same `code`**: a half-turn. Tween `scale.y` 1→0 (`d/2`), re-render the RegionCard from the new model, then 0→1 (`d/2`).
  - **Different `code`, or to the dragon**: the old card slides `+DECK_EDGE` down-right and fades over `d`. The new card (re-rendered, or the DragonCard) rises from that offset to `card_rect` and fades in.
  - **Reduced motion**: a cross-fade of `2 × T.FAST`.
- [X] T032 [US4] In `ui/model/sequencer.gd`, emit `turn_card` at every Region change where contracts/reveal-sequence.md puts it (`setup`'s already comes from T014), then:
  - in `finish` from Region 4, emit `zoom_in {target: "mp"}` with no `key_peek`;
  - make sure `play_final` (Final Journey → Final Enemy) and `regroup` carry their zooms from T014 with targets `"hp"`/`"mp"`;
  The animator already runs `turn_card` (T015). Make T027 pass.

**Checkpoint**: The whole game plays on the Deck, from Region 1 to the dragon.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T033 [P] In `tools/ui_check.gd`, at every `MATRIX` shape and during a sequence:
  - the peek's global rect and the top card's rect lie inside `plan.regions.encounter` and never intersect the header, the Hand panel or the action row (SC-006);
  - in reduced-motion runs, no `DeckStack` tween changes `scale` or `position`.
- [X] T034 [P] In `tools/design_shots.gd`, add shots to `build/screenshots/012` (quickstart.md) at 1280 × 720 and one phone shape:
  - the zoomed-out Region Card for Regions 1–4;
  - the peek held, with and without a Hardship;
  - a half-turn and a card swap mid-way;
  - the Dragon Card;
  - the settled faces.
- [X] T035 Run `godot --headless --path . -s tools/space_audit.gd` and the layout-solver suite. If any shape's preview falls below `T.PREVIEW_MIN` with the raised minimums, set `DECK_EDGE` to 16 for that shape as plan.md "Risks" allows: a `DeckStack.edge_for(view_size)` used by `face_rect` and the minimums. Record which shapes in a comment.
- [X] T036 [P] Update the documents:
  - **`README.md`** (play screen paragraph near line 28): the left side is the Deck with the Region Card on top, and each Encounter is revealed by the Key Card and a zoom.
  - **Header comments**: `ui/widgets/encounter_face.gd` says the face sits on the Deck, reached by zooming into its Region Card tile.
  - **`specs/005-playfield-polish/contracts/playfield-layout.md`**: add a superseded-in-part note for the left side, pointing to `specs/012-deck-region-card/contracts/deck-stack.md`.
- [ ] T037 Run `tools/test.sh` and walk quickstart.md "Manual checks" 1–10 on desktop, then on the emulators via the install-on-emulators skill. Record any timing change (the `T.PEEK_HOLD` cut first, per plan.md "Risks").

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)**: none.
- **Foundational (Phase 2)**: needs Setup. Blocks all stories.
- **US1 (Phase 3)**: needs Foundational.
- **US2 (Phase 4)**: needs US1 (the peek is placed relative to the zoomed-out Region Card, and `key_peek` sits before US1's `zoom_in`).
- **US3 (Phase 5)**: needs Foundational only (anchors on the stack). It can run in parallel with US1/US2, but it reads best after US1, when the Region Card is there to come from under.
- **US4 (Phase 6)**: needs US1 (zoom and the top-card slot). Independent of US2 and US3.
- **Polish (Phase 7)**: needs all chosen stories.

### Within phases

- T002 comes before everything else in Phase 2. T003/T004 and T005–T007 are separate files. T006 needs T005.
- US1: T008–T010 (tests) first, then T011 → T012 → T013. T014 can go in parallel with T011–T013 (a different file). Then T015 and T016.
- US2: T017–T019 (tests), then T020, which runs in parallel with T021. T021 → T022, then T023.
- US4: T027–T028 (tests), then T029 → T030 → T031, with T032 in parallel with T029–T031.

### Parallel opportunities

- Phase 2: T003 + T004 (view state) alongside T005 → T006 (deck stack), and T007 alongside T006.
- US1: T008, T009, T010 together. Then T014 (sequencer) alongside T011–T013 (widgets).
- US2: T017, T018, T019 together. Then T020 (creature) alongside T021 (deck stack).
- US3 alongside US4 once US1 is done.
- Polish: T033, T034, T036 together.

## Parallel Example: User Story 1

```text
Task: "T008 [US1] RegionCard model tests in tests/test_region_card.gd"
Task: "T009 [US1] Stack geometry tests in tests/test_deck_stack.gd"
Task: "T010 [US1] Zoom step placement tests in tests/test_sequencer.gd"
# then
Task: "T011–T013 [US1] RegionCard + DeckStack zoom in ui/widgets/"
Task: "T014 [US1] zoom_out/zoom_in steps in ui/model/sequencer.gd"
```

## Implementation Strategy

### MVP (US1)

Phases 1–3: the stack, the Region Card, and the zoom into each Encounter. Stop and check quickstart.md manual checks 1, 3 and 5 at 1280 × 720 and on a phone shape.

### Incremental delivery

1. **US2** (the Key Card peek): completes the rulebook's Scout Ahead. Checks 2, 4 and 8.
2. **US3** (anchors): checks 5.
3. **US4** (turns and the Dragon Card): checks 6 and 7.
4. **Polish**: checks 9 and 10, and the emulator pass.

Run `tools/test.sh` after every phase. Each phase leaves the game fully playable.
