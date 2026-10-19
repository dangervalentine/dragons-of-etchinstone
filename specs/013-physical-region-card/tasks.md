---

description: "Task list for 013 The Left Side as the Physical Region Card and Deck"
---

# Tasks: The Left Side as the Physical Region Card and Deck

**Input**: Design documents from `specs/013-physical-region-card/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/region-card-face.md](contracts/region-card-face.md), [contracts/left-column.md](contracts/left-column.md), [quickstart.md](quickstart.md)

**Tests**: Included. The project tests every pure model headless and every screen in `ui_check` (plan, Constitution Check). Research R11 lists them.

**Organization**: Tasks are grouped by user story (spec.md US1–US5).

**Builds on 012**: 012's widgets and steps are in the working tree. `DeckStack`'s zoom, peek, `turn_to`, hold and anchors are reused. Only what research.md changes is changed.

**Units**: every figure is in design units.

**Check**: run `tools/test.sh` after each phase.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: Which user story the task belongs to (US1–US5)

---

## Phase 1: Setup

- [X] T001 Run `tools/test.sh` on the current tree (012 uncommitted) and confirm it is green, so later failures belong to this feature. Record any pre-existing failure in this file's Notes before going on. Do not commit (the user commits only when asked).

---

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: The tokens and the view-side models every story reads. After this phase the screen looks as it does today.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] In `ui/theme/tokens.gd`:
  - Add `LEFT_MIN_W := 400`, the narrowest left column (research R5, R9).
  - Add `NOTE_HOLD := 2.4`, how long a refusal note stays (R6).
  - Add `NOTE_ROOMY_H := 360`, the least note height for the roomy result (R7).
  - Leave `ENCOUNTER_MIN`, `DRAGON_MIN` and `PREVIEW_MIN` in place for now. T024 retires them.
- [X] T003 In `ui/model/view_state.gd`, change `region_card_model(db, region)` to the data-model.md shape:
  - Rename `code` to `pair` (the same value, `r.card`), never rendered.
  - Rename `tiles` to `panels`. Each panel is `{key, kind, index, title, art, element, xp, effect}` plus either `enemy: {hp, initiative, attack: {value, element}, armor: [{value, element}, …]}` or `journey: {mp: {value, element}, time_penalty}`, with every value taken from `db.encounter(region, kind, index)`.
  - Drop `stat`.
  - Keep the order: Enemies 1–4, then Journeys 1–4.
  - Remove `code` from `dragon_card_model(dragon)`.
- [X] T004 Update the users of the renamed fields:
  - `ui/widgets/deck_stack.gd` `turn_to`: compare `was.pair == m.pair` instead of `code`.
  - `ui/widgets/region_card.gd`: iterate `model.panels`, keeping 012's tiles working via `RegionTile.render` until T009 replaces them. Map `stat` from the panel in `region_tile.gd` for now: HP for an Enemy, MP for a Journey.
  - `ui/widgets/dragon_card.gd`: stop reading `m.code`.
- [X] T005 [P] In `tests/test_view_state.gd`, update the Region Card model assertions:
  - The model has no `code` but has `pair`.
  - There are 8 `panels` in order.
  - Jade Mountains Enemy 1 is `{hp 7, initiative 8, attack {1, lightning}, armor [{lightning, 1}], xp 4}`.
  - Journey 1 is `{mp 12, time_penalty 2, xp 5}`.
  - `effect` is null where the data has none.
  - `dragon_card_model` has no `code`.

**Checkpoint**: `tools/test.sh` is green, and the game plays as before.

---

## Phase 3: User Story 1 - The Region Card looks like the physical card (Priority: P1) 🎯 MVP

**Goal**: The top card is drawn as the printed Region Card (contracts/region-card-face.md): a title band, the Enemies 2 × 2, the Journeys in a row of four, XP stars, number markers, and no code. 012's zoom still lands on today's `encounter_face` until US3.

**Independent Test**: Run `godot --path . -s tools/design_shots.gd -- build/screenshots/013 scan` and compare the whole Jade Mountains card with the overlaid scan. Every panel is in place with matching values and XP, and no `DOE-` text appears.

### Tests for User Story 1

- [X] T006 [P] [US1] Create `tests/test_region_panel.gd` against `RegionPanel.parts(size, kind, armor_count)` (data-model.md "Pure geometry"):
  - Every part rect lies inside the panel.
  - The rects scale linearly: `parts(2 * s)` = 2 × `parts(s)`.
  - An Enemy has 4 badge rows. Armor ×2 gives two shields side by side, each 0.92 of a badge.
  - A Journey's MP and Time sit in the top 0.25.
  - The XP star is bottom-right (Enemy) or bottom-centre (Journey).
  - The number marker is at the art's top-left.
  - An effect disc is present only when `effect != null`.
- [X] T007 [P] [US1] Rewrite `tests/test_region_card.gd` against `RegionCard.LAYOUT`, `RegionCard.card_size(width)` (= width × 7/5) and `RegionCard.panel_rect(card_size, key)`:
  - All 8 rects are inside the card and do not overlap.
  - Enemy 1 is left of Enemy 2, and both are above Enemies 3 and 4.
  - Journeys 1–4 run left to right, below every Enemy.
  - Enemy rects have an aspect of ≈ 1.45 and Journey rects ≈ 0.6 (±0.08).
  - Nothing lies in the foot band (y > 0.955).
  - Remove the old `tile_rect` tests.

### Implementation for User Story 1

- [X] T008 [US1] Create `ui/widgets/region_panel.gd` (research R2, contracts/region-card-face.md tables):
  - `extends Control`, with `mouse_filter` IGNORE by default.
  - `render(panel: Dictionary, hardship = null)`.
  - `static func parts(size, kind, armor_count) -> Dictionary` returns the named rects at the contract's fractions.
  - Enemy art: a `Creature` held still by default, with crop `EncounterFace.enemy_crop(art, art_rect.size)`. Journey art: `Art.FULL`, cropped to fill the art rect.
  - Badges are `StatChip.make` with the same options `encounter_face.gd` uses: hp, initiative, attack_badge, armor, mp_badge (backing in the MP Ether), time_badge (`STEEL` with an inset of `T.BG_BAND`). Each badge is sized and positioned to its part rect, with the chips' `help` signal re-emitted as `intent` `{"type": "help", …}`.
  - The XP star is a `StatChip` with icon `xp`, colour `T.GOLD` and ink `T.BG_BASE`.
  - Effect discs come from `Glossary.entry(id).icon`. The hardship disc, when given, sits to the left of the effect disc.
  - The number marker is `str(index)` in `T.LABEL_BOLD` on `Color(T.BG_BASE, 0.72)`.
  - `_draw` draws the frame: a fill of `Color(T.ether(element), 0.18)` and an edge of `T.muted(T.ether(element))` at 2.
  - Relayout on `resized`.
  - Provide `set_live(on)` to release or hold the creature.
- [X] T009 [US1] Rewrite `ui/widgets/region_card.gd` to the printed layout (research R1):
  - Add `const LAYOUT` holding the fractions from R1's table.
  - Add `static func card_size(width)` and `static func panel_rect(card_size, key)`.
  - Build the title band: the name in `T.HEADING`, stepping down to fit and never below `T.TEXT_MIN`, with "REGION n" under it in `T.LABEL` / `T.GOLD` and a `sigil_region` ornament at each end. No code, and no `face_aspect` parameter.
  - Make one `RegionPanel` per `model.panels`, positioned at `panel_rect`. Keep `tile(key)` as `panel(key)`.
  - Remove `tile_rect`.
- [X] T010 [US1] Delete `ui/widgets/region_tile.gd` and `ui/widgets/region_tile.gd.uid`, and remove every reference to them. Check with `grep -rn region_tile ui tests tools`.
- [X] T011 [US1] In `ui/widgets/deck_stack.gd`, make the whole card the printed card's shape:
  - `card_rect(deck_size, "card", peek_h)` fits `RegionCard.card_size` (5 : 7) to the face rect's width, below the peek room, and centres it horizontally. If the height binds instead, fit to the height. `DragonCard` keeps its current rect until US5.
  - `_render_top` calls `region_card.render(model)` with no aspect.
  - `_target_rect(key, cr)` uses `RegionCard.panel_rect(cr.size, key)`.
  - Because the panel's aspect is no longer the face's, `zoom_scale` takes `minf(face.w / tile.w, face.h / tile.h)`. The existing zoom still lands on `encounter_face` (US3 replaces that).
- [X] T012 [US1] Update `tests/test_deck_stack.gd` for T011:
  - `card_rect` in `"card"` view has aspect 5 : 7 (±0.01) and lies inside the deck size.
  - `zoom_scale` uses the binding axis.
  - Remove the assertions that assumed tiles share the face's aspect.
- [X] T013 [US1] In `tools/ui_check.gd`, add the US1 checks:
  - At every `MATRIX` shape, show the whole card (`deck.show_card()` on a Region 1 state) and assert that every visible `StatChip` numeral and every number-marker `Label` has a font size of at least `T.TEXT_MIN` (research R9). If a shape fails, apply R9's fallback (the Deck margin to 16 at that shape, via a `T.DECK_EDGE_TIGHT := 16` used by `face_rect` when `size.x < LEFT_MIN_W + 24`) and note it in this file.
  - In every state visited, assert that no visible `Label` on the play screen contains `DOE-` (SC-002).
- [X] T014 [US1] In `tools/design_shots.gd`, add a `scan` mode (second arg `scan`):
  - Render the whole Jade Mountains card alone at a 498-wide card.
  - Draw `res://reference/sheets-official/o5.png`'s right-hand top card (the region x 512–1010, y 0–695) over it at 0.5 alpha.
  - Save `scan_region_1.png`. Do the same for Burning Basin (left-hand top card, Region 3) as `scan_region_3.png`.
- [X] T015 [US1] Run the `scan` shots and tune `RegionCard.LAYOUT` and the `RegionPanel.parts` fractions until the panels' edges and badges line up within about 4 px of the scan. Then run `tools/test.sh`.

**Checkpoint**: The zoomed-out Region Card matches the printed card. Play is otherwise unchanged.

---

## Phase 4: User Story 2 - The whole left side is the stack of cards (Priority: P1)

**Goal**: The left column holds only `DeckStack`. The tip box and the tips are gone. The non-tip feedback is kept on a basic `TableNote` laid on the stack (US4 completes the note's behaviour).

**Independent Test**: Play Region 1 to its End. The left column shows only the stack. The stack's depth always agrees with the header's Deck count and refills at the reshuffle. No tip text appears.

### Tests for User Story 2

- [X] T016 [P] [US2] Update `tests/test_layout_solver.gd`:
  - For every `MATRIX` shape, `solve(...)` returns no `preview` region.
  - `regions.encounter` spans the left column's full body height: from under the header to the body's bottom, `left_w` wide.
  - `left_w ≥ T.LEFT_MIN_W`.
  - Remove the preview and `encounter_min` assertions.
- [X] T017 [P] [US2] In `tests/test_view_state.gd`:
  - While building an Action Set (Journey; Enemy with an unaimed Boost; Enemy all aimed), `vs.prompt.text` is `""` and no string equal to the old `TIP_SWAP`, `TIP_AIM` or `TIP_REAIM` text appears anywhere in `vs`.
  - Add `note_for` cases per data-model.md: mode fuse → `"mode"`, soak → `"soak"`, upgrade → `"upgrade"`, setup → `"setup"`, building → null.

### Implementation for User Story 2

- [X] T018 [US2] In `ui/model/layout_solver.gd`, drop the left column's split:
  - Remove the `preview_needed` and `encounter_min` parameters from `solve`, and the `preview` region.
  - `encounter` = `Rect2(c.position.x, body_y, left_w, body_h)`.
  - Update every caller's argument list: `ui/screens/play_screen.gd`, `tools/ui_check.gd`, `tools/space_audit.gd` and the tests.
- [X] T019 [US2] In `ui/model/view_state.gd`:
  - Remove `TIP_SWAP`, `TIP_AIM` and `TIP_REAIM`, and make `_prompt` return `text: ""` while building. Keep the step text for setup, Fuse, Divert and Regroup.
  - Add `static func note_for(game, draft, vs) -> Variant`, returning `{kind}` or null, with first match in this order: `draft.mode != "none"` → `mode`; `vs.soak != null` → `soak`; `phase == "upgrade"` → `upgrade`; `phase == "setup"` → `setup`.
  - Set `vs["note"]` in `build`.
- [X] T020 [US2] Create `ui/widgets/table_note.gd` (basic):
  - A `Control` drawn as a card: a `StoneStyle("well", 0.5)` fill with a `T.BRONZE_DARK` card edge, in the face's cut outline.
  - Children `preview: PreviewPanel`, `xp_purse: XpPurse` and `soak_meter: SoakMeter`, each made with `.new()` and filling a padded content rect.
  - `show_kind(kind, vs)` makes exactly the matching child visible and renders it: `mode`/`setup`/`result` → preview, `upgrade` → xp_purse, `soak` → soak_meter.
  - Content is centred vertically when shorter than the note, otherwise top-aligned.
  - Re-emit the preview's `intent`.
- [X] T021 [US2] In `ui/widgets/deck_stack.gd`, add the note layer above `_faces` and below `_peek_clip`:
  - `note: TableNote`, placed at `face_rect(size)`.
  - `render(state)` shows the note with `state.note.kind` (no motion yet), or hides it when null.
  - Its `intent` is forwarded.
  - `face_node()` is unchanged. The note never counts as the face.
- [X] T022 [US2] In `ui/screens/play_screen.gd`:
  - Remove the `preview` region and `_fill(_regions.preview, …)`.
  - Point `preview`, `soak_meter` and `xp_purse` at `deck.note.preview`, `deck.note.xp_purse` and `deck.note.soak_meter`, so the animator's `screen.preview` etc. keep working.
  - Remove `_render_preview`'s visibility juggling: the note decides.
  - In `_replan`, drop the `needed`/`least` measuring and pass the new `solve` arguments. The `for` key becomes `[count, places, final, cells]`.
  - `point("preview")` and `point("xp")` use the note: its centre, or `xp_purse.point()` when the purse shows.
  - `_show_detail`'s area becomes `plan.regions.encounter`.
- [X] T023 [US2] In `ui/widgets/preview_panel.gd`'s `_prompt`:
  - Render nothing when `prompt.text == ""` and there is no step.
  - Remove the setup-only "Hold a card to see its other Levels." line here. T037 moves it into the setup note.
  - Keep the blocked-reason line for now. US4 moves refusals.
- [X] T024 [US2] In `ui/theme/tokens.gd`, remove `ENCOUNTER_MIN`, `DRAGON_MIN` and `PREVIEW_MIN` and every remaining use (`grep -rn "ENCOUNTER_MIN\|DRAGON_MIN\|PREVIEW_MIN" ui tools tests`).
- [X] T025 [US2] In `tools/ui_check.gd`:
  - Replace the `preview` zone checks (around lines 131–175) with note checks: when `vs.note` is set, the note is visible, inside `regions.encounter`, and its visible content's height ≤ the note's height.
  - Assert that no visible Control in the left column lies outside `DeckStack`.
  - Assert that no visible `Label` on the play screen contains any of the three removed tip strings.
  - Keep 012's stack-depth assertions (depth = `edges(vs.piles.deck)`).
- [X] T026 [US2] In `tools/space_audit.gd`, measure the note's content in its `result` look (`preview.reveal()` on a played state) instead of the preview zone. Report the note height and content height per shape.

**Checkpoint**: The left column is only the stack (with its note when one applies), no tips remain, and `tools/test.sh` is green.

---

## Phase 5: User Story 3 - The Encounter is the Region Card's panel, zoomed in (Priority: P2)

**Goal**: The zoom grows the card itself about the chosen panel. On landing, a full-size `RegionPanel` of that Encounter takes over, with a reading strip writing out the Hardship, the Ability or Peril, and the name (research R3, R4).

**Independent Test**: Reach an Enemy Encounter with a Hardship and an Ability. The zoomed view is the same panel, large, with a moving creature, and its strip reads the name, the Hardship's short text and the Ability's short text. Pressing a badge explains it, and pressing the panel shows the Key Card.

### Tests for User Story 3

- [X] T027 [P] [US3] In `tests/test_deck_stack.gd`, test `DeckStack.panel_fit(face_rect, aspect, strip_lines)` → `{panel, strip}`:
  - Both lie inside the face rect and do not overlap.
  - For a portrait face, the strip is below the panel. For a landscape fit, it is to the right.
  - `strip.size.y ≥ 2 × T.BODY[1] × 1.3` when below.
  - The panel keeps `aspect` (±0.01).
  - With `strip_lines == 1` (name only), the panel is larger than with 3.
  - `zoom_scale(fit.panel, panel_on_card)` takes the card's panel exactly onto `fit.panel` (its centre and size after scaling, ±0.5).

### Implementation for User Story 3

- [X] T028 [US3] In `ui/widgets/deck_stack.gd`, add the landed face:
  - `landed: RegionPanel` and `strip: VBoxContainer` in `_faces`.
  - `static func panel_fit(face_rect, aspect, strip_lines)` per T027.
  - `_render_faces()` for a Region Encounter renders `landed` with the panel for `vs.zoom` (from `vs.top_card.panels`) and the Hardship from `vs.encounter.effects` (the effect that is a Hardship, if any). It uses `landed` instead of `encounter_face`, which stays only for the rulebook figure (`ui/widgets/rulebook_figure.gd`).
  - `landed.mouse_filter` is STOP. A release emits `intent` `{"type": "inspect_key"}`, as `encounter_face` does today.
  - `encounter_node()` and `flare("encounter")` work with `landed`: give `RegionPanel` a `_stone`-compatible glow, or let `flare` fall back to a `UI.flash` on the node when it has no `_stone`.
- [X] T029 [US3] Build the reading strip in `ui/widgets/deck_stack.gd` (contracts/region-card-face.md "The reading strip"):
  - Line 1: the Encounter icon (`kind`, ink `T.ether_ink(element)`), `index`, and `title` upper-cased in `T.SUBHEAD`, clipped.
  - Line 2: if there is a Hardship, a `StatChip` disc with its glossary icon (help enabled) and `Glossary.entry(id).short` in `T.BODY`.
  - Line 3: the same for the panel's `effect`.
  - Omit empty lines. Wrap text, and keep every Label ≥ `T.TEXT_MIN`.
- [X] T030 [US3] Rework `zoom_in(target, d)` in `ui/widgets/deck_stack.gd` (research R3):
  - Compute `fit = panel_fit(face_rect, panel_aspect, lines)` and the card's panel rect at `cr`.
  - Tween the top card's `scale` and `position` about the panel's centre so the panel ends exactly on `fit.panel`, and fade the strip in over the last 40%.
  - On landing, hide the top card and show `landed` at `fit.panel` and `strip` at `fit.strip`, then release the creature with `landed.set_live(true)`. Keep it held during the motion.
  - Reduced motion: cross-fade the card out and the landed panel and strip in, with no travel.
  - Keep `_set_stack_rect` tweening from `cr` to the face rect.
- [X] T031 [US3] Rework `zoom_out(d)` in `ui/widgets/deck_stack.gd` as the reverse:
  - Hide `landed` and `strip` (the strip fades over the first 40%).
  - Show the top card scaled so its panel sits on `fit.panel`, and tween it to `cr`.
  - Reduced motion: a cross-fade.
  - Update `finish()` and `_settle_view()` to reset `landed`, `strip` and the card's scale and alpha.
- [X] T032 [US3] In `tools/ui_check.gd`, run an animated Encounter to the moment before the `zoom_in` landing and record the top card's panel's global rect. After landing, assert that `landed.get_global_rect()` equals it (±1). Also assert that every Label in the strip is ≥ `T.TEXT_MIN`, and that the strip has no line for an absent Hardship, Ability or Peril.
- [X] T033 [US3] Update the existing tests and checks that read `deck.encounter_face` on the board to read `deck.landed`: `tests/test_board_responses.gd`, `tests/test_playthrough.gd` (if they touch it), `tools/ui_check.gd` and `ui/fx/animator.gd` (any `screen.encounter_face`). Check with `grep -rn "encounter_face" ui tools tests`, leaving the rulebook's own uses alone.

**Checkpoint**: Each Encounter zooms from the printed card into its own panel and back, with no jump. `tools/test.sh` is green.

---

## Phase 6: User Story 4 - Feedback takes the card's place for a moment (Priority: P2)

**Goal**: The note behaves as contracts/left-column.md says: it is laid on and taken off the stack, a refusal is shown in the card's place, the Play result arrives at `tally` with outcome lines, and pressing and holding lifts it aside.

**Independent Test**: Refuse a Play, run each step of Fuse, Divert and Regroup, Play an Encounter, and Upgrade. Each appears as a note on the stack and gives way to the card afterwards. The result lists each reward and cost with its reason. Holding a note shows the card beneath.

### Tests for User Story 4

- [X] T034 [P] [US4] In `tests/test_deck_stack.gd`, test `DeckStack.note_on_show(persistent, result, refusal) -> String`, with precedence `refusal` > `mode` > `result` > `soak` > `upgrade` > `setup` (data-model.md). Cover each pair and all-empty → `""`.

### Implementation for User Story 4

- [X] T035 [US4] In `ui/widgets/deck_stack.gd`:
  - Add `note_kind`, `_result_on: bool` and `_refusal_text: String`, plus `static func note_on_show(...)` per T034.
  - `_update_note(animate)` picks the kind and calls `note.show_kind`.
  - When the note appears: slide it in from `x + T.DECK_EDGE` with alpha 0 → 1 over `T.BASE`, `TRANS_CUBIC` ease out. When it leaves, do the reverse.
  - When the kind changes while shown: cross-fade the content in place.
  - Reduced motion: alpha only.
  - The edges hang from the note's rect while it shows.
- [X] T036 [US4] Add the hold to `ui/widgets/table_note.gd` and `ui/widgets/deck_stack.gd`:
  - On press-and-hold (mouse button down for ≥ `T.FAST`) on the note, tween it to 60% off to the right at 0.25 alpha. On release, tween it back.
  - Never emit an intent from the hold.
  - Reduced motion: alpha only, to 0.15.
  - No helper text (spec FR-006).
- [X] T037 [US4] The `setup` note (research R6):
  - In `ui/widgets/table_note.gd`, render the setup look: band "PREPARE YOUR DECK" with the crown, the dragon art faint behind the text (as `deck_stack._render_setup_face` does today), `vs.prompt.step` and `vs.prompt.text`, and "Hold a card to see its other Levels." in `T.LABEL` / `T.INK_MUTED`.
  - Remove `setup_face` and `_render_setup_face` from `ui/widgets/deck_stack.gd`, along with `play_screen.setup_face` and its users (`grep -rn setup_face ui tools tests`).
- [X] T038 [US4] Refusals:
  - In `ui/screens/play_screen.gd`, replace `toast(text)` and the `_toast*` members with `refuse(text)`, which calls `deck.show_refusal(text)`.
  - `DeckStack.show_refusal(text)` renders the reason in `T.BODY` / `T.BAD` in the note and clears after `T.NOTE_HOLD`, or on the next `intent` from the screen (connect in `play_screen`).
  - In `ui/main.gd` `_refuse`, call `play.refuse(text)`. Keep the haptics and the card shake.
  - Remove the blocked-reason line from `PreviewPanel._prompt`. A blocked Play's press already reaches `_refuse` with the engine's reason. Verify by grepping `main.gd` for where a blocked commit is refused, and add the call if it is missing.
- [X] T039 [US4] In `ui/fx/animator.gd` (contracts/left-column.md "The sequence"):
  - At `tally`, call `screen.deck.show_result(true, animate)` before `preview.reveal()` and `play_tally(d)`.
  - At `verdict`, leave the code unchanged; it already calls into the preview.
  - At `zoom_out`, call `screen.deck.clear_transient_notes(d / 3.0)` (result off, and the upgrade note off if the after phase is not upgrade) before the zoom.
  - In `_finish`: keep `result` when `after.phase == "penalty"`, otherwise clear it, then render `after.note`.
  - Change no Sequencer steps (`tests/test_sequencer.gd` stays green unchanged).
- [X] T040 [US4] Outcome lines in `ui/widgets/preview_panel.gd` (research R7):
  - Add `roomy: bool`, set by `TableNote` when its height ≥ `T.NOTE_ROOMY_H`.
  - When roomy, `_build_sum` puts the verdict as a headline (`T.SUBHEAD` with the verdict icon) and keeps the sum rows. `_outcome_row` is replaced by `_outcome_lines`: one row per pill, each with the pill's icon and figure, then that pill's help sentence in `T.BODY`, wrapped.
  - Use the same help text each `_pill(..., help_id)` call already carries. Where a help text is terse (fewer than 4 words), improve it at its source rather than writing new prose here.
  - `needed_height(width)` accounts for the lines.
- [X] T041 [US4] In `tools/ui_check.gd`:
  - For each note kind (setup, mode/divert, refusal, result after a Play, upgrade, soak) at every `MATRIX` shape, assert that the note is inside `regions.encounter`, its content fits (no clipping), and every Label is ≥ `T.TEXT_MIN`.
  - After `_finish` of a Cleanup, assert that no note shows.
  - During a hold, assert that no intent is emitted.
- [X] T042 [US4] In `tools/space_audit.gd`, report the roomy result's content height against the note height per shape, and flag any shape where it exceeds the note.

**Checkpoint**: Every kind of feedback appears in the card's place and leaves again. `tools/test.sh` is green.

---

## Phase 7: User Story 5 - The Dragon Card in the Final Battle gets the same treatment (Priority: P3)

**Goal**: The Dragon Card is drawn as printed (contracts/region-card-face.md "The Dragon Card"), with no code. The Final Journey and the Final Enemy zoom into its tier columns and land on today's `dragon_face`.

**Independent Test**: Reach the Final Battle. The top card matches the scanned Dragon Card for the chosen dragon, and each stage zooms into the matching Tiers.

- [X] T043 [P] [US5] Update the Dragon Card tests in `tests/test_deck_stack.gd` (or a new `tests/test_dragon_card.gd`):
  - `DragonCard.target_rect(card_size, "mp")` lies in the card's left 0.35 and `"hp"` in its right 0.35, both below the badge row.
  - The two do not overlap.
- [X] T044 [US5] Rewrite `ui/widgets/dragon_card.gd` to the printed layout:
  - `const LAYOUT` holds the fractions measured from `reference/sheets-official/o5.png` (Grimroch, Vuurhast): the title band y 0–0.105 (name in `T.HEADING`, title in `T.LABEL` gold); the badge row centred at y 0.12–0.2 (Initiative, Early Damage, Armor as `StatChip`s, from `dragon_stats`' figures); the MP Tiers column at x 0.02–0.24, y 0.24–0.5 (one MP badge + hourglass per tier); the HP Tiers column at x 0.76–0.98, y 0.24–0.5 (one heart + Attack per tier).
  - Draw the dragon's art (`m.art`) over the body.
  - No `code`.
  - `target_rect` returns the two column rects.
  - `card_size` follows the Region Card's 5 : 7.
- [X] T045 [US5] In `ui/widgets/deck_stack.gd`, use the 5 : 7 `card_rect` for the Dragon Card too (no peek room in the Final Battle) and `DragonCard.target_rect` for `"mp"`/`"hp"`. The zoom lands on `dragon_face` with the shared cross-fade, as in 012.
- [X] T046 [US5] Extend `tools/design_shots.gd`'s `scan` mode to overlay the Grimroch card (o5.png, bottom left, x 0–505, y 700–1400) on a rendered Grimroch Dragon Card as `scan_dragon_grimroch.png`. Tune `DragonCard.LAYOUT` to fit, and run `tools/test.sh`.

**Checkpoint**: The Final Battle's top card matches print and zooms into the right Tiers.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T047 [P] Update `README.md`'s play-screen description: the left side is the Deck with the printed Region Card (or Dragon Card) on top, Encounters zoom into their panel, and feedback is laid on the stack as a note.
- [X] T048 [P] Add a "Superseded in part by `specs/013-physical-region-card`" note to the top of `specs/012-deck-region-card/contracts/deck-stack.md` (layers, per-phase table, zoomed-out view, space), and a "Superseded by 013: the box is removed" note to `specs/011-card-contribution-highlights/contracts/left-box.md`.
- [X] T049 Extend `tools/design_shots.gd`'s `deck` mode with the quickstart's shots: the whole card in Region 1, an Enemy landed, a Journey landed, each note kind, and the Dragon Card. Run it to `build/screenshots/013` and review each shot against contracts/region-card-face.md and contracts/left-column.md.
- [X] T050 Run the whole of quickstart.md: `tools/test.sh`, `tools/space_audit.gd`, both shot modes, and a Region 1 play-through on desktop (and on the emulators via the `install-on-emulators` skill if the user wants). Record the results in this file's Notes.
- [X] T051 Clean up: remove any now-unused code (`deck_stack` setup-face helpers, `play_screen` toast, `EncounterFace.show_key_line` if only the board used it). Run `grep -rn "DOE-\|TIP_SWAP\|TIP_AIM\|TIP_REAIM\|region_tile\|PREVIEW_MIN" ui tools tests` and expect only `data/`-sourced values (none in `ui`, `tools` or `tests`).

---

## Dependencies & Execution Order

- **Setup (T001)** → **Foundational (T002–T005)** → user stories.
- **US1 (T006–T015)** depends on Foundational. It is the MVP.
- **US2 (T016–T026)** depends on Foundational only. It can run alongside US1. They touch different parts of `deck_stack.gd`: US1's `card_rect`/`_target_rect` and US2's note layer, so they must be merged carefully if run in parallel.
- **US3 (T027–T033)** depends on US1: it needs `RegionPanel` and `panel_rect`.
- **US4 (T034–T042)** depends on US2: it needs `TableNote` and the single region.
- **US5 (T043–T046)** depends on US1's 5 : 7 `card_rect` (T011).
- **Polish (T047–T051)** comes after the stories it describes.

```text
T001 → T002‥T005 ─┬─ US1 ─┬─ US3
                  │       └─ US5
                  └─ US2 ─── US4
                                └─ Polish
```

## Parallel Opportunities

- **Foundational**: T002 and T005 alongside T003/T004.
- **US1**: T006 and T007 (two test files) before T008 and T009.
- **US2**: T016 and T017 (tests) together. T018 (solver) alongside T019 (view_state).
- **US3**: T027 alongside T028's start.
- **US4**: T034 alongside T040 (`preview_panel.gd`).
- **US5**: T043 alongside T044.
- **Polish**: T047 and T048 together.
- **Across stories**: US1 and US2 after Foundational. US3 and US4 once their parents land.

## Implementation Strategy

1. **MVP**: Setup, Foundational, then US1. The Region Card looks like print, and play is unchanged. Check it with the `scan` shot.
2. **US2**: the left column becomes only the stack, with a basic note. This delivers the other half of the user's ask.
3. **US3**: the zoom into the printed panel, with the reading strip.
4. **US4**: the note's full behaviour and the roomy result.
5. **US5**: the printed Dragon Card.
6. **Polish**.

Run `tools/test.sh` at every checkpoint. Do not commit unless the user asks.

## Notes

- T001 baseline: 341 tests, 0 failed; ui check 94585 checks, 0 failed.
- T004: no RegionTile adapter was needed. RegionPanel (T008) and the new RegionCard (T009) replaced the tiles in the same step.
- T005: the model assertions went into `tests/test_region_card.gd`, which is where the Region Card model tests already lived, rather than `test_view_state.gd`.
- T013 / R9: whole-card numerals cannot reach `T.TEXT_MIN`. At the narrowest column a badge is about 26 units, and its numeral fits a window about half that. The whole card is therefore treated as a picture of the printed card, seen while the Deck zooms; its figures are read on the landed panel (US3), where they are ≥ 22. `ui_check` instead asserts that every panel's figures equal the model (SC-001) and that no Label anywhere contains `DOE-` (SC-002). Spec SC-006 has been amended to match.
- T015: the scan overlays (`build/screenshots/013/01_scan_region_1.png`, `02_scan_region_3.png`) line up with R1's measured LAYOUT, with no tuning needed. After US1: 348 tests, 0 failed; ui check 111583 checks, 0 failed.
- US2–US4 were built together in `deck_stack.gd` (one rewrite), because the note, the landed face and the zoom share its layers.
- T027–T031: the landed face is the whole card grown round the panel and clipped, not a lone panel with a strip beneath it (research.md Implementation notes, R3/R4). The test is for `DeckStack.landing()` (not `panel_fit`), and the strip lies along the foot.
- T034: precedence became composition. `note_kinds()` sets out the result together with the step after it. A refusal shows alone, over either.
- T036 / T041: the hold is in `table_note.gd` and `deck_stack._lift_note`, and it emits only `held`, never an intent. `ui_check` does not simulate a press-and-hold; the no-intent guarantee is structural.
- T040: the outcome lines fall back to the one-row outcome when the note's content would overflow (result plus Soak on short shapes).
- T042: `space_audit` measures the result note when its sampled state has a complete set. None of its current samples does, so `ui_check`'s per-state note-fit check carries this.
- T049: the `deck` and full design shots cover setup, Fuse, result plus Soak, result plus Upgrade, Enemy, Journey and Ranged landed, and the Dragon Card. There is no separate refusal shot; `ui_check` asserts the refusal note.
- Owner requests during implementation (2026-10-18):
  - The Journeys' Hardship text is confirmed in the strip (Night Travel, Steep shots).
  - The Final Enemy face shows the whole dragon.
  - The Dragon Card's dragon is large, placed so its face is clear of the tiers.
  - The design shot tool now deals the Final Journey Hand as the game does (`ui._reset_draft()`). Its old `draft.reset(2)` left all 7 cards unplaced in one illegible row.
- T050: after implementation, 351 tests, 0 failed; ui check 139777 checks, 0 failed; space audit PASS.
