---

description: "Task list for 014 Drawn Cards and the Key Card at the Region Card's Size"
---

# Tasks: Drawn Cards and the Key Card at the Region Card's Size

**Input**: Design documents from `specs/014-card-draw-key-reveal/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/deck-motion.md](contracts/deck-motion.md), [contracts/deck-pile.md](contracts/deck-pile.md), [quickstart.md](quickstart.md)

**Tests**: Included. The project tests every pure model headless and every screen in `ui_check` (plan, Constitution Check). Research R7 lists them.

**Organization**: Tasks are grouped by user story (spec.md US1–US5).

**Builds on 012 and 013**, which are committed. `DeckStack`'s zoom, `turn_to`, hold, note and anchors are reused. Only what research.md changes is changed.

**Units**: every figure is in design units.

**Check**: run `tools/test.sh` after each phase.

**Commits**: do not commit. The user commits only when asked.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story the task belongs to (US1–US5)

---

## Phase 1: Setup

- [X] T001 Run `tools/test.sh` on the current tree and confirm it is green, so later failures belong to this feature. Record any pre-existing failure in this file's Notes before going on.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: The tokens and the pure helpers several stories read. After this phase the screen looks as it does today.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] In `ui/theme/tokens.gd`, add these tokens beside `ZOOM`/`TURN`/`PEEK_*` (data-model.md "Tokens"):
  - `DRAW_FLY := 0.45`
  - `KEY_LIT := 0.35`
  - `PANEL_LIT := 0.45`
  - `KEY_PEEK := 1.05`
  - `CARD_EDGE := Color("8d8778")`
  - `CARD_EDGE_LINE := Color("4a463e")`

  Each gets a one-line `##` comment in the file's style. Leave `PEEK_HOLD` in place for now; T020 removes it.
- [X] T003 [P] In `ui/widgets/deck_stack.gd` "geometry (pure)", add `static func card_radius(width: float) -> int` returning `roundi(width * 0.075)`. That is `CardFace`'s own corner ratio (`card_face.gd:304`). Add a test in `tests/test_deck_stack.gd`: `card_radius(190.0) == 14`.
- [X] T004 In `ui/widgets/deck_stack.gd`, add `func top_rect() -> Rect2`. It returns `Rect2(global_position + r.position, r.size)`, where `r = card_rect(size, "card", <peek for the shown top>)`. It always uses the zoomed-out rect, whatever `view` is (research R1, R6). It works for both the Region Card and the Dragon Card.

**Checkpoint**: `tools/test.sh` green; nothing visible has changed.

---

## Phase 3: User Story 1 — Drawn cards leave the Deck at the Region Card's size (Priority: P1) 🎯 MVP

**Goal**: every drawn card starts as big as the top card, exactly where it lies, and shrinks into its Hand place while moving right, face-up and fully visible (FR-001–FR-004).

**Independent Test**: start a game and watch the first Hand being drawn. Each card's first frame matches the Region Card's outline, and it moves right and shrinks steadily into its place. In the Final Battle, the same happens from the Dragon Card.

### Tests for User Story 1

- [X] T005 [P] [US1] In `tests/test_sequencer.gd`, assert that a `draw` step of `n` cards has `duration == minf(T.DRAW_FLY + T.STAGGER * (n - 1), 1.2)` for n = 1, 4 and 7.
- [X] T006 [US1] In `tools/ui_check.gd`, at every `MATRIX` shape, play a `start` sequence and check the drawn cards (contracts/deck-motion.md "The draw"):
  - For each drawn card, sample its `CardView` on the first frame after it is added and assert its global rect equals `deck.top_rect()` within 2 px on each edge (SC-001).
  - Sample at about 50% of the flight and assert `size.x / size.y` is within 1% of `T.CARD_ASPECT` (SC-002), and that `modulate.a == 1.0`.
  - After the step, assert each card's rect equals its `home` within 2 px.
  - Repeat once in the Final Battle, where `top_rect()` is the Dragon Card's rect.

  Use `Engine.get_main_loop().process_frame` stepping, as the existing zoom-jump check does.

### Implementation for User Story 1

- [X] T007 [US1] In `ui/widgets/hand_tray.gd` `sync()`, make `arrive_from` a global `Rect2` (or `null`). Update the doc comment above `sync` to say so. For a fresh, animated card:
  - set `view.position = arrive_from.position - global_position`;
  - set `view.size = arrive_from.size`;
  - set `view.modulate.a = 1.0` (reduced motion: `0.0`, as `_glide` fades it in).

  This replaces the 0.3 × `home.size` start rect at `hand_tray.gd:85`.
- [X] T008 [US1] In `ui/widgets/hand_tray.gd` `_glide()`, add a `fly := false` parameter. When `fly` is true and motion is not reduced:
  - tween `position` and `size` together over `T.DRAW_FLY` with the existing cubic in-out, with the same delay, so both finish on the same frame;
  - add no alpha tween, because the card is already opaque.

  The arrival branch in `sync()` calls `_glide(view, arrivals * T.STAGGER, true)`. Other callers are unchanged. Reduced motion keeps snapping to `home` and fading in over `T.FAST` (FR-010).
- [X] T009 [US1] In `ui/screens/play_screen.gd` `render(state, animate, arrive_from)`, pass `arrive_from` through to `hand.sync` unchanged, with the type now `Rect2` or `null`, and update its doc comment. Search the file for any other caller passing a `Vector2`, and make it pass `deck.top_rect()`.
- [X] T010 [US1] In `ui/fx/animator.gd` `_run`, change the `"draw"` branch to `screen.render(_after, true, screen.deck.top_rect())`.
- [X] T011 [US1] In `ui/model/sequencer.gd` `_draw_step`, set `st.duration = minf(T.DRAW_FLY + T.STAGGER * (ids.size() - 1), 1.2)`. Check that `_fit_time` still keeps the sum of steps before the reveal ≤ `T.SEQUENCE_MAX`. Run `test_sequencer` and fix any duration-sum expectations that the new draw length moves.

**Checkpoint**: US1 works alone. Run `tools/test.sh`, then `tools/design_shots.gd` (deck) and look at a mid-flight frame.

---

## Phase 4: User Story 2 — The Key Card is as wide as the Region Card (Priority: P1)

**Goal**: the Key Card rises at the Region Card's size, its sides aligned, just far enough to show its Encounter icon, number and Hardship (FR-005).

**Independent Test**: reach any Region Encounter. The raised Key Card's left and right edges line up with the Region Card's, and only its title band and Encounter strip show.

### Tests for User Story 2

- [X] T012 [P] [US2] In `tests/test_deck_stack.gd`, test the solved `card_rect` (research R2):
  - **Width-limited** (a tall deck, e.g. `Vector2(400, 900)`): the card is `face_rect.size.x` wide, as today.
  - **Height-limited with a Key Card**: the room above the card equals `peek_h(cr.size) - dip(peek_h(cr.size))` within 0.5. Check both branches, one where `peek_h/2 >= T.DECK_EDGE` and one where it is below (a small deck such as `Vector2(300, 200)`).
  - **The Dragon Card** (no peek): the whole face, as today.

  Replace the old assertion that used the Hand's card size (`test_deck_stack.gd:37-47`).
- [X] T013 [P] [US2] In `tests/test_deck_stack.gd`, test `key_rect(deck_size, raised)`:
  - its `position.x` and `size.x` equal `card_rect(...).position.x` and `.size.x`;
  - its size is `RegionCard.card_size(cr.size.x)`;
  - at rest its `y == cr.position.y`;
  - raised, its `y == cr.position.y + dip(ph) - ph`, with `ph = peek_h(cr.size)`.

### Implementation for User Story 2

- [X] T014 [US2] In `ui/widgets/deck_stack.gd`, change `card_rect(deck_size, v, peek_h: float)` to `card_rect(deck_size, v, peek: bool)`:
  - Width-limited: `s = RegionCard.card_size(f.size.x)`, then `ph = peek_h(s)`, `room = ph - dip(ph)`.
  - If `s.y > f.size.y - room` (height-limited), solve with `k := 0.245`, which is `peek_h`'s `0.155 + 0.09`:
    - if `k * h / 2 >= T.DECK_EDGE`: `h = (f.size.y + T.DECK_EDGE) / (1 + k)`;
    - else: `h = f.size.y / (1 + k / 2)`;
    - then `s = Vector2(h * RegionCard.ASPECT, h)` and recompute `room` from `s`.
  - Keep the centring of the spare space.
  - When `peek` is false, there is no room, as today.

  Update every caller: `_place`, `top_point`, `top_rect`, `zoom_in`, `zoom_out`, `peek`, `turn_to` and any others found by searching for `card_rect(`. Each passes `_peeks()`, a new helper returning true when the shown (or state's) top card is a Region Card; it replaces `_peek_h() > 0`.
- [X] T015 [US2] In `ui/widgets/deck_stack.gd`, add `static func key_rect(deck_size: Vector2, raised: bool) -> Rect2` per data-model.md. In `peek()`:
  - set `_peek.size = cr.size`;
  - use `key_rect(size, false).position` and `key_rect(size, true).position` for `rest` and `up`;
  - use `peek_h(cr.size)` for the dip.

  Remove `_card_size`, `set_card_size()` and `_peek_h()`'s use of the Hand's size, keeping `peek_h(card_size)` itself. Update `top_point()` to use the new `card_rect`.
- [X] T016 [US2] In `ui/screens/play_screen.gd`, remove the `deck.set_card_size(...)` call (`play_screen.gd:110`) and any other caller found by search.
- [X] T017 [US2] In `tools/ui_check.gd`, at every `MATRIX` shape, during a `key_peek`, once the rise has ended:
  - assert `deck._peek.global_position.x` and its right edge equal the Region Card's within 2 px (SC-003);
  - assert the existing whole-card numerals check (≥ 22) still passes with the solved `card_rect`.

  If a shape fails the numerals check, apply research R2's fallback: let `dip()` go to `peek_h / 2` without the `T.DECK_EDGE` cap, in `card_rect`'s solve and in `dip()` together. Record which shapes needed it in Notes.

**Checkpoint**: US1 and US2 work together. Run `tools/test.sh`.

---

## Phase 5: User Story 3 — The number, then the Encounter, highlighted before the zoom (Priority: P1)

**Goal**: in a Region:
- the Key Card rises;
- its Encounter number lights in gold;
- the matching panel lights (overlapping) while the Key Card stays up;
- the Key Card slides down as the zoom starts;
- the highlights are gone when the zoom lands (FR-006–FR-009, FR-012).

**Independent Test**: reach an Encounter whose Key Card names Journey 3. The Key Card rises, its "3" is ringed and washed in gold, and the Journey 3 panel is rimmed in gold with the rest dimmed, while the Key Card is still up. The Key Card then slides down as the view zooms into Journey 3, with no gold left on the landed face. Repeat after a Divert.

### Tests for User Story 3

- [X] T018 [P] [US3] In `tests/test_sequencer.gd`, assert:
  - the `key_peek` duration is `T.KEY_PEEK`;
  - every `key_peek` is directly followed by `zoom_in`;
  - `key_peek.duration + zoom_in.duration <= 3.0` (FR-012).

  Replace 012's ≤ 1.4 s invariant.
- [X] T019 [P] [US3] In `tests/test_card_face_layout.gd` and `tests/test_region_card.gd`, test the two highlights:
  - A `CardFace` with `set_model(m, ["encounter"])` and `lit = 0.0` queues no ring (`_rings` empty after a draw pass). With `lit = 1.0` it queues one ring round `_geo().key`.
  - `RegionCard.set_rim(1.0)` after `set_focus("journey:3", 1.0)` draws the rim only round `panel_rect(size, "journey:3")`. Expose a pure `rim_rect()` that returns that panel's rect grown by half the rim width, and assert on it.

### Implementation for User Story 3

- [X] T020 [US3] In `ui/model/sequencer.gd`, set `DURATION.key_peek = T.KEY_PEEK`. Then remove `PEEK_HOLD` from `ui/theme/tokens.gd` and fix any remaining reference (search `PEEK_HOLD`).
- [X] T021 [P] [US3] In `ui/widgets/card_face.gd`, add `var lit := 1.0` with a setter that calls `_ink.queue_redraw()`. In `_draw_strip`:
  - draw the `"encounter"` ring only when `lit > 0`, using `Color(glow, glow.a * lit)` in `_draw_rings` for that ring;
  - before the icon and number, draw a gold wash behind the key rect `g.key`: a filled rounded rect in `Color(T.GOLD, 0.28 * lit)`, the "leafed in gold" of `boost_aim.gd`;
  - leave the Hardship icon unringed.

  The default stays `1.0`, so other uses of `set_model(m, ["encounter"])` (if any) look as today. Search for other callers before changing the default.
- [X] T022 [P] [US3] In `ui/widgets/region_card.gd`, add `var rim := 0.0`, `func set_rim(amount: float)` (stores it and calls `queue_redraw()`) and `func rim_rect() -> Rect2`. At the end of `_draw()`, when `rim > 0` and `focus_key != ""`, draw an unfilled rounded rect round `rim_rect()` in `Color(T.GOLD, rim)`.
  - The width is `maxf(2.0, size.x * 0.012)`, the same as `CardFace._draw_rings`.
  - The radius is `int(rim_rect().size.y * 0.04)`.
  - It sits on the panel's frame edge, so it never covers the number marker or the XP star.
- [X] T023 [US3] In `ui/widgets/deck_stack.gd`, reshape `peek(face_model, target: String, d: float)` (contracts/deck-motion.md "The reveal"):
  - Add `signal reveal_beat(name: String)` and `var _peek_up := false`.
  - Set `_peek.lit = 0.0`.
  - **Motion**, with `d` laid out in the `KEY_PEEK` proportions (rise `PEEK_RISE`, number `KEY_LIT` from the rise's end, panel `PANEL_LIT` from `PEEK_RISE + 0.6 * KEY_LIT`):
    1. tween `position` to `up` and the dip, as today, over the rise;
    2. then emit `reveal_beat("key_lit")` and tween `_peek.lit` 0 → 1;
    3. in parallel, after its delay, emit `reveal_beat("panel_lit")` and tween `region_card.set_focus(target, x)` and `region_card.set_rim(x)` for x 0 → 1;
    4. at the end, set `_peek_up = true` and do **not** fall or `_settle_view()`.
  - **Reduced motion**: put the Key Card at `up` with the dip applied and `modulate.a` 0 → 1 over `T.FAST`, then the same two lit tweens by alpha, with the same beats.
- [X] T024 [US3] In `ui/widgets/deck_stack.gd` `zoom_in(target, d)`:
  - Emit `reveal_beat("zoom")` at the start.
  - If `_peek_up`, tween `_peek.position` to `key_rect(size, false).position` and the dip back to 0 over `d * T.PEEK_FALL / T.ZOOM`, in parallel with the zoom, cubic ease-in. Then hide `_peek`, reset `_peek.lit = 0` and `_peek_up = false`.
  - Over the zoom, tween `region_card.set_rim` 1 → 0, keeping `set_focus` at 1.0 so the landed face matches.
  - **Reduced motion**: fade `_peek.modulate.a` to 0 with the cross-fade.

  Check that `_zooming` and the existing "Key Card sliding home" guard (`deck_stack.gd` near `_zooming`) still behave.
- [X] T025 [US3] In `ui/widgets/deck_stack.gd` `finish()`, also set `_peek_up = false`, `_peek.lit = 0.0` and `region_card.set_rim(0.0)` (FR-011), next to the existing `set_focus("", 0.0)`.
- [X] T026 [US3] In `ui/fx/animator.gd` `_run`, change `"key_peek"` to `screen.deck.peek(_after.key_face, st.values.get("target", _after.zoom), d)`. In `ui/model/sequencer.gd` `_reveal`, add `"target": target` to the `key_peek` step's values, so the lit panel is always the zoomed one. Update `test_sequencer`'s invariant to assert `key_peek.values.target == zoom_in.values.target`.
- [X] T027 [US3] In `tools/ui_check.gd`, at every `MATRIX` shape, connect `deck.reveal_beat` during a `start` and a `divert` sequence. Assert:
  - the order is `key_lit`, then `panel_lit`, then `zoom`;
  - `key_lit` comes at or before `panel_lit` (SC-004);
  - the `region_card.focus_key` at `panel_lit` equals the step's `zoom_in` target;
  - after the sequence, `region_card.rim == 0`, `_peek.visible == false` and `_peek_up == false`.

**Checkpoint**: US1–US3 work. Run `tools/test.sh`, then design_shots `reveal`.

---

## Phase 6: User Story 4 — Reduced motion and skipping tell the same story (Priority: P2)

**Goal**: with reduced motion, nothing travels or scales, but both highlights show in order. A skip lands on the same state (FR-010, FR-011).

**Independent Test**: turn on reduced motion and reach an Encounter. No card moves or changes size. The Key Card fades in at Region Card width with its number lit, then the panel lights, then the face appears. Tap during a reveal, and the result matches an unskipped one.

- [X] T028 [US4] In `ui/fx/animator.gd` `reduced_duration(st)`, confirm `key_peek` is still exempt from the reduced-motion clamp, and keeps at least `T.KEY_PEEK` so both lit beats show. Adjust it if the clamp would cut it.
- [X] T029 [US4] In `tools/ui_check.gd`, add a reduced-motion pass at one desktop and one phone shape (`UI.reduced_motion = true`):
  - drawn cards' first sampled rect is `home`, not `top_rect()`;
  - `reveal_beat` order is as in T027;
  - `_peek.global_position` never changes between its first visible frame and the `zoom` beat.

  Restore `UI.reduced_motion` afterwards.
- [X] T030 [US4] In `tools/ui_check.gd`, add a skip pass. Start a `start` sequence, call `animator.skip()` at mid-draw, after `key_lit` and after `panel_lit`. Each time, assert that `hand` card rects equal their `home`, `deck.view == "face"`, `region_card.rim == 0`, `_peek.visible == false` and `landed.key == _after.zoom`.

**Checkpoint**: Run `tools/test.sh`.

---

## Phase 7: User Story 5 — The Deck looks like a pile of cards (Priority: P2)

**Goal**: the pile is a face-up stack of rounded, plain card edges, slightly uneven, with a soft shadow. It tracks the count and shows no Ether colour. The top cards' corners are rounded to match (FR-014–FR-016).

**Independent Test**: look at the zoomed-out left side. It reads as a pile of cards with the Region Card on top, with rounded corners everywhere and no Ether colour on any edge. Draw a Hand, and the pile thins.

### Tests for User Story 5

- [X] T031 [P] [US5] In `tests/test_deck_stack.gd`, test `edge_rects(stack, n)` (contracts/deck-pile.md "Rules"):
  - the size is `edges(n)` for n in [0, 1, 2, 5, 16, 40];
  - `n = 0` gives `[]`;
  - every rect has `stack.size`;
  - the i-th (1-based, deepest first in the returned order) is offset from `stack.position + Vector2.ONE * EDGE_STEP * i` by at most 1 px across and 0–1 px down;
  - two calls return equal arrays (no randomness).

### Implementation for User Story 5

- [X] T032 [US5] In `ui/widgets/deck_stack.gd`:
  - Add `const JITTER := [Vector2(0, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 1)]`, one per edge up to `EDGES_MAX`.
  - Add `static func edge_rects(stack: Rect2, n: int) -> Array`. It returns `edges(n)` rects, deepest first. Edge `i` (1-based) is `Rect2(stack.position + Vector2.ONE * EDGE_STEP * i + JITTER[i - 1], stack.size)`. The only inputs are the rect and the count (FR-015).
- [X] T033 [US5] In `ui/widgets/deck_stack.gd`, rewrite `_draw_edges()` per contracts/deck-pile.md "Drawing":
  1. Shadow: for g in 1..4, a `StyleBoxFlat` rounded rect round the deepest edge's rect, grown by `2 * g`, offset `(2, 4)`, with the `bg_color` alpha `[0.10, 0.07, 0.05, 0.03][g - 1]` in black. The corner radius is `card_radius(w) + 2 * g`.
  2. Each edge from `edge_rects(_stack_rect, count)` is a `StyleBoxFlat` with `bg_color = T.CARD_EDGE`, `border_color = T.CARD_EDGE_LINE`, `border_width_all = 1` (1.5 px drawn) and `corner_radius_all = card_radius(_stack_rect.size.x)`, drawn with `_edges.draw_style_box`.

  Build the style boxes once and update their radius when `_stack_rect` changes, rather than per frame.
- [X] T034 [P] [US5] In `ui/theme/stone_style.gd`, add `var round_radius := 0.0` with a setter that calls `emit_changed()`. When it is `> 0`:
  - `_draw` follows a rounded rect of that radius (arcs of 8 segments per corner) for the face, the bevel runs and the edge line;
  - the outline helper (`stone_style.gd:69`) returns the rounded polygon.

  With 0, nothing changes for any other stone panel. If the rounded bevel looks wrong in a shot, apply plan.md's fallback (a `StyleBoxFlat` rounded outline in the stone colours) for the two top cards only, and note it.
- [X] T035 [US5] In `ui/widgets/region_card.gd` `_fit()` and `ui/widgets/dragon_card.gd`'s equivalent, set the card's `StoneStyle.round_radius = DeckStack.card_radius(size.x)`. Clip the title band to the rounded top: draw the band with a `StyleBoxFlat` of `corner_radius_top_left/right = card_radius(size.x)` instead of `draw_rect`. Do this in `region_card.gd:118` and the Dragon Card's band. Preload `deck_stack.gd` for `card_radius`, or move `card_radius` to `ui/theme/theme.gd` if a preload cycle appears, and update T003's test path.
- [X] T036 [US5] In `tools/design_shots.gd` `_deck()`, add the shots:
  - `pile_full` (a fresh Region);
  - `pile_low` (Deck count 3, set via `deck.set_count(3)`);
  - `draw_mid` (the `start` sequence stepped to 50% of the first card's flight);
  - `reveal` (stepped to just after `panel_lit` plus `PANEL_LIT`);
  - `draw_final` (Final Battle draw at mid-flight).

  Take them at phone-tall and 1280 × 720.

**Checkpoint**: all stories work. Run `tools/test.sh` and the design shots, and review them against quickstart.md's table.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T037 [P] Add a superseded-in-part note at the top of `specs/012-deck-region-card/contracts/reveal-sequence.md`: "`key_peek` timing, the Key Card staying raised into `zoom_in`, and invariant 6 (now ≤ 3 s) follow specs/014 contracts/deck-motion.md."
- [X] T038 [P] Add a note to `specs/013-physical-region-card/contracts/left-column.md`: "The stack's edges are drawn per specs/014 contracts/deck-pile.md."
- [X] T039 Update the doc comment at the top of `ui/widgets/deck_stack.gd`:
  - the edges are rounded, card-stock card sides with a shadow (specs/014);
  - the Key Card rises at the Region Card's size, lights its number and the panel, and stays up until `zoom_in` slides it down.
- [X] T040 Run `tools/test.sh` and `godot --headless --path . -s tools/space_audit.gd`. Then use the `install-on-emulators` skill and walk quickstart.md "Play it" steps 1–7 on the phone-tall emulator. Record any frame drops during a 7-card draw (plan Risks). If they appear, apply the `scale`-then-`size` fallback in `hand_tray.gd` `_glide` and re-run.

---

## Dependencies & Execution Order

- **Setup (T001)**, then **Foundational (T002–T004)**, then the stories.
- **US1 (T005–T011)**: needs T002 and T004. It is independent of the other stories.
- **US2 (T012–T017)**: needs T002. T014 changes `card_rect`, which `top_rect` (T004) calls, so re-run US1's ui_check after T014.
- **US3 (T018–T027)**: needs US2, because the peek geometry and `key_rect` come from T015.
- **US4 (T028–T030)**: needs US1 and US3.
- **US5 (T031–T036)**: needs T002 and T003 only. It can run alongside US1–US3. T035 depends on T034.
- **Polish (T037–T040)**: after all stories.

### Within stories

- Tests are written first and fail before their implementation tasks.
- `deck_stack.gd` tasks run in sequence (T014 → T015 → T023 → T024 → T025 → T032 → T033), because they edit the same file.

## Parallel Examples

- **After Phase 2**: T005, T012, T013, T031 and T034 can run at once (separate files or pure tests).
- **US3**: T018, T019, T021 and T022 can run together (`test_sequencer`, the two widget tests, `card_face.gd`, `region_card.gd`), then T023–T027.
- **Polish**: T037 and T038 together.

## Implementation Strategy

- **MVP**: Phases 1–3 (US1). Cards leave the Deck at the Region Card's size. This is the change the player sees most.
- **Then**:
  - US2 and US3 together complete the Key Card reveal (one sitting, since US3 needs US2).
  - US5 restyles the pile and the corners.
  - US4 hardens reduced motion and skipping.
- Run `tools/test.sh` at every checkpoint. Do not commit unless the user asks.

## Notes

- T001: the tree was green before any change (353 tests, 140,442 UI checks).
- T017: no shape needed R2's deeper-dip fallback. The whole-card numeral check passes at every `MATRIX` shape with the solved `card_rect`.
- T034: the rounded `StoneStyle` bevel looks right in the shots, so the `StyleBoxFlat` fallback was not needed.
- T036: the `draw_final` shot (a Final Battle draw) was not added, because design_shots has no quick path to the Final Battle. `ui_check`'s draw check runs in every `_watch_deck`, including the region change, but not in the Final Battle either.
- T008: a drawn card waiting its turn in the stagger is hidden until its flight starts, then shows whole at the top card's rect. Otherwise the waiting cards would lie face-up over the Region Card.
- T040: `tools/test.sh` and `space_audit` are green. Re-run with the phone awake: the build is installed on the Android phone (wireless adb) and opens on the title screen. No iOS simulator was booted. The 7-card-draw frame-rate check on a phone is still to do.
