---

description: "Task list for 015 Notes Dealt On and Discarded Off Like Cards"
---

# Tasks: Notes Dealt On and Discarded Off Like Cards

**Input**: Design documents from `specs/015-dealt-table-notes/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/note-pile.md](contracts/note-pile.md), [quickstart.md](quickstart.md)

**Tests**: Included. The project tests every pure model headless and every screen in `ui_check` (plan, Constitution Check). Research R8 lists them.

**Organization**: Tasks are grouped by user story (spec.md US1–US4).

**Builds on 013 and 014**, which are committed. The note's triggers (`show_result`, `clear_result`, `show_refusal`, `clear_refusal`, `_update_note`, `turn_to`) keep their timing. Only how notes come, lie and go changes.

**Units**: every figure is in design units.

**Check**: run `tools/test.sh` after each phase.

**Commits**: do not commit. The user commits only when asked.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story the task belongs to (US1–US4)

---

## Phase 1: Setup

- [X] T001 Run `tools/test.sh` on the current tree and confirm it is green, so later failures belong to this feature. Record the test and UI-check counts, and any pre-existing failure, in this file's Notes before going on.

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: the tokens, the pile widget with its pure rules, the unclipped layer, and `DeckStack`/`PlayScreen` moved onto the pile. After this phase a note still slides and fades as today, but it is a card in a `NotePile`.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] In `ui/theme/tokens.gd`, beside `NOTE_HOLD`, add these tokens (data-model.md "Tokens"), each with a one-line `##` comment in the file's style:
  - `NOTE_DEAL := 0.35`
  - `NOTE_DISCARD := 0.35`
  - `NOTE_TURN := 14.0`
  - `NOTE_TILT := [0.0, -1.2, 0.9, -0.6]` (degrees, by depth from the top; deeper cards repeat the last)
  - `NOTE_PILE_STAGGER := 0.04`
  - `CARD_SHADOW := [[2.0, 0.10], [4.0, 0.07], [6.0, 0.05], [8.0, 0.03]]`

  Then, in `ui/widgets/deck_stack.gd`, replace the constant `SHADOW` and its uses in `_draw_edges()` with `T.CARD_SHADOW`.
- [X] T003 [P] Write `tests/test_note_pile.gd` (extends `res://tests/base.gd`, preloads `res://ui/widgets/note_pile.gd`) with the pure tests first:
  - `NotePile.plan(pile, wanted)` gives exactly the seven rows of research.md R2's table, as `{"throw": n, "deal": [...]}`;
  - `plan([], [])` is `{"throw": 0, "deal": []}`;
  - `NotePile.tilt(0) == 0.0`; `tilt(1) == deg_to_rad(-1.2)`; `tilt(5) == deg_to_rad(-0.6)` (deeper repeats the last);
  - `NotePile.off_table(Rect2(20, 30, 300, 420), 40.0) == Vector2(-40 - 360, 30)`.

  They fail until T004.
- [X] T004 Create `ui/widgets/note_pile.gd`: `extends Control`, with a `##` header in the house style naming specs/015 and contracts/note-pile.md.
  - **Fields**: `cards`, `refusal_card`, `leaving`, `rest`, `lifted` and `_spares` (data-model.md "NotePile").
  - **Setup**: `mouse_filter = MOUSE_FILTER_IGNORE` on itself, and `clip_contents = false`.
  - **Signals**: `intent(data)` (forwarded from each card's `intent`) and `held(on)` (from the top card's `held`).
  - **Pure statics**: `plan`, `tilt` and `off_table`, exactly as research.md R2 and data-model.md define them.
  - **Methods** (data-model.md "Methods"): `sync`, `deal`, `throw_top`, `throw_all`, `show_refusal`, `clear_refusal`, `lift`, `lay_out`, `finish`, `top`, `card`, `panel`, `is_showing`, `kinds` and `refusal_text`.
    - At this stage, deal and throw use the **old** motion: from `rest + (T.DECK_EDGE, 0)` with alpha 0 → 1 over `T.BASE`, and the reverse. US1 and US2 replace it.
    - `deal` creates a `TableNote`, sizes it to `rest`, calls `show_kinds([kind], vs)` (with `result_vs` set first for `"result"`), and connects its `intent`.
    - `sync(wanted, vs, result_vs, animate)` applies `plan(kinds(), wanted)`: it throws, then deals. It then re-renders, with `show_kinds([k], vs)`, every lying card whose kind is in `wanted`.
  - `panel(name)` (research R6):
    - `"preview"`: the `result` card's `preview`, else the `mode`/`setup` card's;
    - `"soak_meter"`: the `soak` card's `soak_meter`;
    - `"xp_purse"`: the `upgrade` card's `xp_purse`;
    - otherwise: a lazily built, never-added, hidden spare (`PreviewPanel`, `SoakMeter`, `XpPurse`) kept in `_spares`.

  Add the stateful tests to `tests/test_note_pile.gd`, run on a `NotePile` not in a tree with `animate = false`:
  - `sync(["result"])` then `sync(["result","soak"])` gives `kinds() == ["result","soak"]`;
  - `sync([])` gives `kinds() == []` once `finish()` is called;
  - a second `show_refusal` keeps one refusal card and updates its text;
  - `panel("xp_purse")` with no XP card is not visible and has no parent.
- [X] T005 In `ui/widgets/table_note.gd` (research R5):
  - set `clip_contents = false` on the note itself;
  - add a child `_body` (`Control`, `clip_contents = true`, `MOUSE_FILTER_IGNORE`, filling the note on `_fit()`) and move `_creature` and `_box` under it;
  - in `_draw()`, draw `T.CARD_SHADOW`'s layers under the rounded face, as `DeckStack._draw_edges()` draws the pile's shadow (each layer the face rect grown by its amount, black at its alpha, radius grown to match);
  - keep everything else.
- [X] T006 In `ui/widgets/deck_stack.gd`, move the clip to a new child `_table` (research R3):
  - `var _table := Control.new()`, with `clip_contents = true` and `MOUSE_FILTER_IGNORE`;
  - in `_init()`, add `_edges`, `_peek_clip`, `_tops` and `_faces` to `_table` instead of to `self`, and add `_table` first;
  - set `clip_contents = false` on `DeckStack`;
  - in `_place()`, keep `_table` at `(0, 0)` and size `size`.

  Every child rect is unchanged, because `_table`'s origin is the Deck's. Grep `deck_stack.gd` for `clip_contents = ` and remove the toggles in `_discard_note()`.
- [X] T007 In `ui/widgets/deck_stack.gd`, replace the single note with the pile (data-model.md "DeckStack changes"):
  - `var pile := NotePile.new()`, added after `_table`, filling the Deck (`_place()` sets its rect to `(0, 0, size)`, then calls `pile.lay_out(_note_rect())`);
  - remove `var note`, `_note_tween`, `_slide_note`, `_note_to`, `_lift_note` and `_discard_note`;
  - make `note_on` a read-only property returning `pile.is_showing()`;
  - `_update_note(animate)` → `pile.sync(note_kinds(vs.get("note"), result_held), vs, _result_vs, animate)`, where the `result_vs` that `show_result()` stored on the old note is now a `DeckStack` field `_result_vs`;
  - `show_result`, `clear_result`, `show_refusal` and `clear_refusal` keep their bodies' triggers and delegate to `pile.sync` / `pile.show_refusal` / `pile.clear_refusal` (the `_refusal_timer` stays in `DeckStack`);
  - `face_node()` returns `pile.top()` when `pile.is_showing()`;
  - `note_point()` returns the centre of `pile.top()`'s rest rect, else of `_note_rect()`, in global coordinates;
  - add `func panel(name: String) -> Control: return pile.panel(name)`;
  - `pile.held` → `pile.lift(on)`;
  - `finish()` also calls `pile.finish()`.

  Update the header comment's last layer to say the notes lie in a pile (note_pile.gd).
- [X] T008 In `ui/screens/play_screen.gd`, replace the fixed `preview`, `soak_meter` and `xp_purse` references with read-only properties (`var preview: Control: get: return deck.panel("preview")`, and likewise). Check every `screen.preview` / `screen.soak_meter` / `screen.xp_purse` use in `ui/fx/animator.gd` still reads correctly. The `.visible` checks now see the hidden spare when there is no such card.
- [X] T009 Update the tools for the new shape:
  - `tools/ui_check.gd` `_check_note`: `deck.note` → `deck.pile.top()` for the region and fit checks, run for **every** lying card in `deck.pile.cards`. The region is grown by 8 for the tilt. `deck.note.refusal` → `deck.pile.refusal_text()`.
  - The Boost refusal check (around line 1374): `deck.pile.refusal_text().contains("Boost")`.
  - `tools/space_audit.gd`: `play.deck.note` → `play.deck.pile.card("result")`.
  - `tools/design_shots.gd`: any `deck.note` use goes to `deck.pile`.

**Checkpoint**: `tools/test.sh` green. In play, notes still slide in from the right, but each kind is now its own card and they stack (rule 3 is already live).

---

## Phase 3: User Story 1 — Every note is dealt on from the left like a card (Priority: P1) 🎯 MVP

**Goal**: every note arrives from off the left of the screen as a whole, opaque card, turning and straightening as it lands square in the card's place.

**Independent Test**: play a set against an Enemy. The result card comes in from the left, fully opaque, turned at first, and lands square on the face. The same holds for the Soak, the XP, a Divert step and Play without a Boost aim (quickstart steps 2–4).

- [X] T010 [P] [US1] In `tests/test_note_pile.gd`, add: after `deal("result", vs, true)` on a pile in a test `SceneTree` root (use `Engine.get_main_loop().root`, and free it after), the new card's position is `off_table(rest, global_position.x)`, its `rotation` is `deg_to_rad(-T.NOTE_TURN)`, and its `modulate.a == 1.0`. After `finish()`, it is at `rest.position` with `rotation == 0.0`.
- [X] T011 [US1] In `ui/widgets/note_pile.gd`, implement the deal (contracts/note-pile.md "Motion", Deal):
  - set `pivot_offset = size / 2`;
  - start at `off_table(rest, global_position.x)` with `rotation = deg_to_rad(-T.NOTE_TURN)` and `modulate.a = 1`;
  - tween `position` → `rest.position` and `rotation` → `tilt(0)` together over `T.NOTE_DEAL`, `TRANS_CUBIC`, `EASE_OUT`.

  Keep each card's tween in a per-card map, so `finish()` can kill it and set the end pose. The card being dealt is the top, so it is added as the last child.
- [X] T012 [US1] In `ui/widgets/note_pile.gd`, make the refusal card use the same deal (FR-001 scenario 4). A second refusal while one lies there does not re-deal it (FR-009).
- [X] T013 [US1] In `tools/ui_check.gd`, add a check while a deal is in flight. After the tally at one `MATRIX` shape, await one frame and read `deck.pile.top()`:
  - `modulate.a == 1.0`;
  - its global rect's left edge is left of the Deck's left edge, or it is already at rest;
  - after `_settle()`, its `rotation == 0.0` and its rect equals `_note_rect()` in global coordinates.

**Checkpoint**: every note comes in from the left. `tools/test.sh` green.

---

## Phase 4: User Story 2 — Every note is discarded off to the left when done (Priority: P1)

**Goal**: done-with notes are thrown off to the left, turning, past the Deck's edge, unclipped. The setup throw is the same motion.

**Independent Test**: take a set through its result, Soak and XP. Every card leaves left, turning, crossing the Deck's edge unclipped. Compare with the setup throw: they are the same (quickstart steps 1–3).

- [X] T014 [P] [US2] In `tests/test_note_pile.gd`, add:
  - after `throw_top(1, true)`, the thrown card is in `leaving`, its tween targets `off_table(...)` and `rotation` `deg_to_rad(-T.NOTE_TURN)`, and its `modulate.a` stays 1.0;
  - after `finish()`, `leaving` is empty and the card is freed (`is_instance_valid` false after a frame);
  - `throw_all` on three cards gives the top delay 0 and each lower card a further `T.NOTE_PILE_STAGGER`.
- [X] T015 [US2] In `ui/widgets/note_pile.gd`, implement the discard (contracts/note-pile.md "Motion", Discard and Pile thrown):
  - move the card from `cards` to `leaving`;
  - tween `position` → `off_table(rest, global_position.x)` and `rotation` → `deg_to_rad(-T.NOTE_TURN)` over `T.NOTE_DISCARD`, `TRANS_CUBIC`, `EASE_IN`, with alpha unchanged;
  - then hide it, remove it from `leaving` and `queue_free()` it;
  - `throw_top(n)` throws the refusal card too when it lies on them; the top card has delay 0 and each card below it a further `T.NOTE_PILE_STAGGER`;
  - `clear_refusal()` throws only `refusal_card`.
- [X] T016 [US2] In `ui/widgets/deck_stack.gd` `turn_to`, replace the old `_discard_note(d)` call with `pile.throw_all(true)`. Keep the `if not UI.reduced_motion: return` flow, so the Region Card is shown under it as today (FR-006).
- [X] T017 [US2] Make `clear_result(d)` in `ui/widgets/deck_stack.gd` throw the pile at once through `pile.sync(..., true)` (rule 1), not after a delay. Check that `zoom_out` still calls it first, so the pile leaves as the zoom starts and is never shrunk with the card (spec Edge Cases, Zooming out).
- [X] T018 [US2] In `tools/ui_check.gd`, add a check during a throw at one shape. Right after the zoom out starts, await one frame:
  - every card in `deck.pile.leaving` has `modulate.a == 1.0`;
  - `deck._table.clip_contents` is true;
  - `deck.clip_contents` is false;
  - after `_settle()`, `deck.pile.leaving` is empty.
- [X] T019 [US2] In `specs/013-physical-region-card/contracts/left-column.md`, "The note": add a one-line note at the top saying In, Out, Swap, Hold and Refusal are superseded by `specs/015-dealt-table-notes/contracts/note-pile.md` (research R9).

**Checkpoint**: deal and discard both work; this is the full spec P1 scope. `tools/test.sh` green.

---

## Phase 5: User Story 3 — A note that changes is a new card laid over the old one (Priority: P2)

**Goal**: within an interaction the cards build into a visible pile (tilted corners, shadows) and leave together. An undo throws only the cards above; a refusal is thrown alone; holding lifts the whole pile.

**Independent Test**: lose to an Enemy with XP to gain. Result, Soak and XP pile up with the lower corners showing, then all three leave together on the zoom out. Undo from XP to the Soak throws only the XP card (quickstart steps 3, 5 and 6).

- [X] T020 [P] [US3] In `tests/test_note_pile.gd`, add:
  - after three deals and `finish()`, each card's `rotation == tilt(depth)` (top 0, then −1.2°, then 0.9°);
  - `sync(["result","soak"])` on `["result","soak","upgrade"]` throws exactly the `upgrade` card;
  - a refusal over a two-card pile, then `clear_refusal()`, leaves `kinds() == ["result","soak"]`;
  - `lift(true)` puts every lying card at `rest.position + (0.6 * rest.size.x, 0)` with alpha 0.25 after `finish()`, and `lift(false)` returns them.
- [X] T021 [US3] In `ui/widgets/note_pile.gd`, when a card lands on top, ease every card beneath to `tilt(depth)` over `T.FAST` (pivot at its centre). `lay_out(rest)` and `finish()` set each card's size, `position = rest.position` and `rotation = tilt(depth)` at once (FR-007a).
- [X] T022 [US3] In `ui/widgets/note_pile.gd`, implement `lift(on)` for every lying card and the refusal card together (research R7):
  - on: to `rest.position + Vector2(0.6 * rest.size.x, 0)` and alpha 0.25 over `T.FAST`;
  - off: back to rest, alpha 1.

  Connect `held` on each card as it becomes the top, and disconnect it from the card it covers (FR-010).
- [X] T023 [US3] In `ui/widgets/table_note.gd`, remove `_without_recap` and render the XP purse with its recap (`xp_purse.render(vs)`), since the result now lies on its own card under it (research R1). Confirm in `ui_check` that the XP card's content still fits at every shape (the `_check_note` fit check from T009).
- [X] T024 [US3] In `tools/ui_check.gd`, add the lost-fight pile check at one shape. Play a set that loses to an Enemy with XP to gain, then assert `deck.pile.kinds()` after each `_settle()`:
  - `["result","soak"]` at the Soak;
  - `["result","soak","upgrade"]` at the XP;
  - `[]` once the next Encounter is zoomed into.

  If the dealt game cannot reach a lost Enemy fight quickly, use the seeded path the existing Soak checks use.
- [X] T025 [US3] In `tools/design_shots.gd`, add a `notes` shot to the Deck's shots: the result, Soak and XP cards piled and settled (quickstart "Shots").

**Checkpoint**: the pile reads as cards stacked up and leaves as one. `tools/test.sh` green.

---

## Phase 6: User Story 4 — Reduced motion and skipping (Priority: P3)

**Goal**: with reduced motion, notes fade in and out where they lie. Skipping, resizing or going to the background lands everything at once.

**Independent Test**: turn on reduced motion and play through a result, Soak and XP. Nothing travels or turns. Resize the window mid-flight: the card lands at once (quickstart steps 7 and 8).

- [X] T026 [P] [US4] In `tests/test_note_pile.gd`, with `UI.reduced_motion = true` (restored after):
  - a deal starts at `rest.position` with alpha 0 and `rotation` 0;
  - a throw keeps its position and tweens alpha to 0;
  - `finish()` lands both.
- [X] T027 [US4] In `ui/widgets/note_pile.gd`, branch the deal and the discard on `UI.reduced_motion` (contracts/note-pile.md, Reduced motion column):
  - deal: at rest, alpha 0 → 1 over `T.FAST`;
  - discard: alpha 1 → 0 in place over `T.FAST`, then freed;
  - the pile's tilts are set at once;
  - `lift` changes only alpha.
- [X] T028 [US4] In `ui/widgets/note_pile.gd` `lay_out(rest)`: when `rest` differs from the last one, call `finish()` first, then lay every card out (FR-012). Check `DeckStack._place()` calls it on every resize.
- [X] T029 [US4] In `tools/ui_check.gd`, after each `_settle()` in the existing `_check_note` path, assert `deck.pile.leaving.is_empty()` and that no lying card has a running tween. Run the reduced-motion pass the checks already make, if there is one, through the lost-fight check (T024).

**Checkpoint**: reduced motion and settling are correct. `tools/test.sh` green.

---

## Phase 7: Polish & Cross-Cutting

- [X] T030 [P] Read `ui/widgets/deck_stack.gd`, `note_pile.gd` and `table_note.gd` for stale comments that mention the note sliding from the right, cross-fading, or a single note, and update them to the pile.
- [X] T031 [P] Run `godot --path . -s tools/design_shots.gd -- build/screenshots/015 deck` and look at the `notes` shot: the corners show, each card has a shadow, and nothing spills past the left region. Run `tools/space_audit.gd` and confirm the result still fits its card.
- [ ] T032 Run the play-through in quickstart.md by eye (steps 1–8) and `tools/test.sh`. Record the results, and any shape where the tilt or the flight looked wrong, in Notes.

---

## Dependencies & Execution Order

- **Setup (T001)**, then **Foundational (T002–T009)**, then the stories.
  - Within Foundational: T002 and T003 can run in parallel; then T004, T005, T006, T007, T008, T009 in order. T007 needs T004 and T006, and T008 needs T007.
- **US1 (T010–T013)**: needs Foundational.
- **US2 (T014–T019)**: needs Foundational. It is independent of US1 in behaviour, but T015 edits the same file as T011, so do it after T011.
- **US3 (T020–T025)**: needs US1 and US2, since the tilt eases as a card lands and the pile is thrown together.
- **US4 (T026–T029)**: needs US1 and US2 (it branches their motion).
- **Polish (T030–T032)**: after all stories.

### Within stories

- Tests are written first and fail before their implementation tasks.
- `note_pile.gd` tasks run in sequence (T004 → T011 → T012 → T015 → T021 → T022 → T027 → T028), because they edit the same file.
- `ui_check.gd` tasks run in sequence (T009 → T013 → T018 → T024 → T029).

## Parallel Examples

- **Phase 2**: T002 (tokens) and T003 (pure tests) together.
- **US1**: T010 (test) alongside T011's start, since they are different files.
- **US2**: T014 (test) and T019 (013 doc note) together, then T015–T018.
- **US3**: T020 (test) and T023 (`table_note.gd`) together, then T021, T022, T024 and T025.
- **Polish**: T030 and T031 together.

## Implementation Strategy

- **MVP**: Phases 1–4 (US1 and US2). Every note is dealt in from the left and thrown off to the left. The stacking from rule 3 is already live from Phase 2, so the main request is met.
- **Then**: US3 makes the pile read as a pile (tilts, holding as one, the XP recap, undo). US4 hardens reduced motion and settling.
- Run `tools/test.sh` at every checkpoint. Do not commit unless the user asks.

## Notes

- T001: the tree was green before any change (361 tests; 196,251 UI checks, 150 space checks).
- T004: the pile fills a card through a replaceable `fill` callable, so its tests need no game state. The spare panels are hidden children of the pile rather than detached, so nothing asks a node outside the tree for its global position.
- T009: `ui_check`'s `_settle()` now also calls `deck.pile.finish()`: a note dealt or thrown flies for 0.35 s after the state is shown, and the checks look at the notes once they have landed. A tilted note is checked by its turned corners, within half the Deck's margin of the left region, since 1.2° moves a tablet card's corner about 10 units.
- T016 was done with T007: `turn_to` had to stop calling the removed `_discard_note`.
- T010, T014, T020, T026: the headless runner (`tests/run.gd`) runs before the scene tree is up, so nothing there can create a tween. The motion checks (dealt from off the left, whole and turned; thrown whole, the pile top first; the tilts; holding; reduced motion) are in `tools/ui_check.gd` `_note_motion()`, on a pile of its own in the tree. `tests/test_note_pile.gd` keeps the tree-free ones: `plan`, `tilt`, `off_table`, piling up, an undo, a refusal alone, the spare panels.
- T013, T018, T024, T029: rather than one hand-built lost fight, `_check_note` now checks every settled state of every game `ui_check` plays:
  - the wanted kinds lie, the last on top;
  - within an Encounter the notes only pile up;
  - nothing is in flight;
  - `_table` clips and the Deck and the pile do not;
  - each note's turned corners are on the Deck.

  A pile of three must be seen at least once.
- Found by the pile-up check: when the next Encounter opened with Poison, the last fight's result, Soak and XP were still lying there. The XP was still wanted as the Deck zoomed out, so nothing ever asked for an empty pile. The old Soak card was being reused for the Poison. Fixed in `DeckStack._update_note`:
  - the notes are thrown whenever the Encounter changes (`note_key`: the Region and the zoom);
  - `clear_result` closes the Encounter's notes until the phase moves on.
- T025: the shots are taken with `tools/design_shots.gd -- <out> notes`, a new mode that skips the reveal. The full `deck` run waits on the reveal by polling `is_waiting()`. When the Godot window lost focus during an unattended run, the game's focus-out skip ended the reveal and the wait never finished. The notes shots run inside `deck` too.
- T031: the first `notes` shot showed the pile did not read as a pile: the cards under the top one are the same stone, and their 1.2° corners vanished. Each note now has a 2-unit card edge in `T.CARD_EDGE_LINE`, as the Deck's own cards do, and the corners under the top card show. `space_audit` passes. It prints no result-note sizes, before this feature as after: none of its states has a complete set to play.
- T032: not done. The play-through in quickstart.md is by eye and needs a person at the game. The automated checks pass (369 tests; 192,868 UI checks, 150 space checks).
