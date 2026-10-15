---

description: "Task list for Etched Stone and Ether Rifts"
---

# Tasks: Etched Stone and Ether Rifts

**Input**: Design documents from `/specs/006-etched-stone-polish/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. The plan names three new headless tests and extends one; they
are the gates for FR-002–FR-004, FR-015–FR-017 and SC-001. Each is written before
the code it checks.

**Organization**: Tasks are grouped by user story. The stories run in this order:

1. US1, space (P1)
2. US2, stone and rift on the play screen (P2)
3. US3, board life (P3)
4. **Stage 2 sign-off gate**
5. US4, every screen (P4)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Paths are relative to the repository root. Run all tests with `./tools/test.sh`.

## Conventions every task follows

- `engine/` and `data/cards.json` are never edited (FR-019).
- GDScript style:
  - Tabs, and `##` doc comments on every function and file.
  - Typed locals.
  - Preload constants named like `const T = preload("res://ui/theme/tokens.gd")`.
  - Match the surrounding file.
- Test files extend `"res://tests/base.gd"` and use `eq()` / `ok()`. Every `test_*`
  method is picked up by `tests/run.gd`. Build games as `tests/test_view_state.gd`
  does.
- Floors: minimum text 22 design units (`T.TEXT_MIN`), tap target 88 (`T.TAP_MIN`).
  Contrast is ≥ 4.5:1 for text and ≥ 3:1 for numerals ≥ 32 units.
- Anything that animates checks `UI.reduced_motion` and applies the end state at once
  (or the `still` form from `board_response.gd`) when it is true.
- **Staging**:
  - US1 must not change the look (FR-022).
  - US2 and US3 restyle *only* the play screen, including the Final Battle. Use the
    new `UI.stone_*` helpers in play-screen widgets only, and never change what
    `UI.box`, `UI.panel` or `UI.raised_panel_box` return before US4. That keeps a
    rejected style frame cleanly revertible.
- Commit at the end of each phase. Stage 2 (US2 + US3) must be separate commits on top
  of US1.
- Never run art generation on this Mac. A Windows-PC texture fallback is a hand-off
  command only.

---

## Phase 1: Setup (Baselines before anything changes)

**Purpose**: Record today's look, band size and empty space so later checks compare
against them. Do this on the unmodified code (commit `cdae3d2`).

- [ ] T001 Capture "before" screenshots (build/ is git-ignored; do not commit them):
  - Run `godot --path . -s tools/shot.gd -- build/006-before`.
  - Run `godot --path . -s tools/design_shots.gd -- build/006-before/design`.
  - Confirm `build/006-before/phone-16x9/05_challenge_assigned.png` and `12_final_journey.png` exist.
- [ ] T002 Create `tools/space_audit.gd`, an `extends SceneTree` tool modelled on `tools/shot.gd`.
  - **Drive**: load `res://scenes/main.tscn` at the `phone-16x9` matrix size (1280 × 720) and drive the same seeded states as `shot.gd`: challenge empty, one placed, all assigned, soak, upgrade, final journey, final enemy.
  - **Role display share**: the global rect of the role display (today the play screen's `slots` region node; after US1 the `rail`) as a share of `plan.content` area.
  - **Per-zone empty fraction** for every play-screen region: `1 − area(union of visible descendant Controls' global rects ∩ region rect) / area(region rect)`. Approximate the union with a 16-unit occupancy grid.
  - **Output**: one line per state and zone, plus `MAX_EMPTY` per state.
  - **Flags**: with `-- --baseline <file>` it writes JSON; with `-- --compare <file>` it prints the rail-against-band ratio and FAILs if any zone's empty fraction exceeds 1/3 or the one-set ratio exceeds 0.5.
- [ ] T003 Run `godot --headless --path . -s tools/space_audit.gd -- --baseline specs/006-etched-stone-polish/baseline.json` on unchanged code.
  - Write `specs/006-etched-stone-polish/baseline.md` with a short table: per state, the band size and share, and the emptiest zone and its fraction.
  - Expect the band to be 824 × 154 at one set and 824 × 96 at two (research D1).
- [ ] T004 Run `godot --path . -s tools/field_bench.gd` and record the average and p99 frame times at the bottom of `specs/006-etched-stone-polish/quickstart.md` under "Results", as the pre-feature bench.

---

## Phase 2: Foundational (Tokens every story reads)

**Purpose**: New design tokens. These are constants only; nothing visible changes.

**⚠️ CRITICAL**: Complete before any user story.

- [ ] T005 In `ui/theme/tokens.gd` add, with `##` comments, under new `# Rail`, `# Stone` and `# Rift` headings:
  - `RAIL_TOKEN_W := 132`
  - `PREVIEW_MIN := 150`
  - `STONE_L_MIN := 0.012`, `STONE_L_MAX := 0.026` (relative luminance; the top must not exceed `luminance(BG_RAISED)`)
  - `CHAMFER_S := 6`, `CHAMFER_M := 12`, `CHAMFER_L := 20`
  - `BEVEL_LIGHT := Color(1, 1, 1, 0.10)`, `BEVEL_SHADOW := Color(0, 0, 0, 0.45)`
  - `SEAM_NEUTRAL := Color("8f7fd6")`
  - `SEAM_MAX_UNDER_TEXT := 0.0`
  - `RIFT_TINT_TIME := REVEAL`
  - `MOTES_MAX := 24`

  Run `./tools/test.sh` and confirm it is still green.

**Checkpoint**: tokens in place; tests green; nothing on screen changed.

---

## Phase 3: User Story 1 - Space that earns its place (Priority: P1) 🎯 MVP

**Goal**: Replace the slot band with the role rail (contracts/role-rail.md), and make
the left column's split content-driven, on today's look.

**Independent Test**: quickstart §2. `space_audit.gd --compare` passes; the by-hand
steps 1–8 pass; nothing else looks different.

### Tests for User Story 1 (write first; they must fail)

- [ ] T006 [P] [US1] Create `tests/test_role_rail.gd` against a new pure static function `ViewState.rail_tokens(vs: Dictionary) -> Array` in `ui/model/view_state.gd` (shapes per data-model.md § RoleToken). Use real view states built as `test_view_state.gd` does and assert:
  - (a) one set, nothing placed: 3 tokens `spell`, `element`, `boost`. The active one has `state == "next"` and the others `"empty"`; each empty `tap == {"type": "select_slot", "set": 0, "role": <role>}`.
  - (b) after placing a card in Spell: that token `state == "filled"`, `card_id` set, `ether` equal to the card's element, `tap == {"type": "take_back", "id": <id>}`, and `contribution == [basic.value, enhanced.value, enhanced.element]` from the card's current Level.
  - (c) Element contribution is `[element, initiative]`; Boost is `[boost]`.
  - (d) "Never shows a card's name as visible text": the token dict has no `name` key, and only `tooltip` contains the card name (`"Spell 1: <name>"`; `"Spell 1"` when empty).
  - (e) Final Battle (`final_enemy`, two sets): 6 tokens with `set` 0 and 1.
  - (f) after a battle (`vs.played` set, `vs.sets` empty): `played` tokens for each role, plus a `reserve` token whose state is `kept` when `played.reserve_kept`, else `discarded`; every recap `tap == null`.
  - (g) intent parity: for each of these states, the set of non-null `tap` intents equals the set of intents the current `ui/widgets/slot_row.gd` buttons would emit (enumerate them by hand from `slot_row._slot`).
- [ ] T007 [P] [US1] Update `tests/test_layout_solver.gd`:
  - In `ORDER` and every assertion, rename the `slots` region to `rail`.
  - Replace `test …spare height goes to the slots` (line 118) with `test_rail_is_one_tap_target_tall()`: for every matrix size, with `sets` 1 and 2, `regions.rail.size.y == T.TAP_MIN`; with 0 sets it is `0.0`.
  - Add `test_rail_area_is_at_most_half_the_old_band()`: at `phone-16x9` with one set, `regions.rail.size.x * regions.rail.size.y <= 0.5 * 824 * 154`.
  - Add `test_preview_takes_what_it_needs()`: `solve(..., preview_needed := 200)` gives `regions.preview.size.y == 200` at `phone-16x9`; `preview_needed := 0` gives `PREVIEW_MIN`; a huge value is capped at half the body height. The encounter always fills the rest of the column (`encounter.end.y + GAP == preview.position.y`).
  - Keep `test_hand_cards_are_no_smaller_than_before` passing unchanged.

### Implementation for User Story 1

- [ ] T008 [US1] In `ui/model/layout_solver.gd`:
  - **Signature**: change `solve()` to `solve(view, safe, hand_count := 4, set_count := 1, points_per_unit := 0.5, preview_needed := 0.0)`.
  - **Rail**: rename the `slots` region to `rail`. It is `T.TAP_MIN` tall when `set_count > 0`, else 0, with the spare-height top-up deleted. Its width is `minf(right_w, (3 * T.RAIL_TOKEN_W + 150 + 3 * T.S) if set_count == 1 else (8 * T.TAP_MIN + 7 * T.S))`, centred over the right column.
  - **Preview split**: `preview_h = clampf(preview_needed, T.PREVIEW_MIN, roundf(body_h * 0.5))` when `preview_needed > 0`, else keep today's `body_h - encounter_h - GAP`. `encounter_h = body_h - preview_h - GAP`.
  - **Docs**: update the doc comments.

  Make T007 pass.
- [ ] T009 [US1] In `ui/model/view_state.gd`, add `static func rail_tokens(vs: Dictionary) -> Array` per data-model.md § RoleToken (fields `set`, `role`, `state`, `card_id`, `contribution`, `ether`, `tap`, `tooltip`, plus a toggle entry `{"role": "boost_to", "set", "target": "attack"|"initiative", "tap": {"type": "toggle_boost_to", "set": n}}` when `sets[n].show_boost_to`).
  - Call it from `build()` as `vs["rail"] = rail_tokens(vs)`.
  - Reuse the role and contribution logic from `ui/widgets/slot_row.gd` (`_contribution`, `_render_played`), moved here as data.

  Make T006 pass.
- [ ] T010 [P] [US1] Add `func needed_height() -> float` to `ui/widgets/preview_panel.gd`, `ui/widgets/soak_meter.gd` and `ui/widgets/xp_purse.gd`.
  - Return the content's minimum height for the state last rendered: `get_combined_minimum_size().y` of the content container, plus the panel's content margins.
  - Tighten `preview_panel.gd`'s composition so its rows stack from the top with `T.S` gaps and the verdict sits directly under them, not pinned to the bottom of an oversized panel.
- [ ] T011 [US1] Create `ui/widgets/role_rail.gd` (`extends HBoxContainer`, centred, separation `T.S`), replacing `ui/widgets/slot_row.gd`. It has `signal intent(data)` and `func render(vs)`, which draws one `Button` per entry of `vs.rail`.
  - **Size**: `custom_minimum_size = Vector2(T.RAIL_TOKEN_W if one set else T.TAP_MIN, T.TAP_MIN)`.
  - **Styling**: today's `UI.box` styling from `slot_row._slot` (focus rim and shadow for `next`, the Ether border for `filled`).
  - **Content**:
    - The role icon, 22 units.
    - The set pip as a small `"1"`/`"2"` label when there are two sets.
    - The contribution numerals and icons exactly as `slot_row._contribution` draws them (compact form when there are two sets).
    - For recap states, the role icon plus a struck "discarded" mark (an `orn`-free `Line2D` across the icon is fine), and the Reserve icon in `T.GOLD` when `kept`.
  - **Tooltip and taps**: `tooltip_text = token.tooltip`. Pressed emits `token.tap` when it is not null.
  - **Boost-to toggle**: drawn as today (`UI.button` with the target icon, and the word in one-set mode), emitting `toggle_boost_to`.
  - **Rects**: add `func token_rect(set: int, role: String) -> Rect2` returning the token's global rect.
  - **Style**: no card name anywhere. Doc comments in the file's style.
- [ ] T012 [US1] In `ui/screens/play_screen.gd`:
  - Rename the `slots` region to `rail`, and replace `slots`, `SlotRow` and `_render_slots()` with a single `RoleRail` instance filled into `_regions.rail` (`rail.render(vs)`; connect `intent`).
  - In `_replan()`, pass `preview_needed` from whichever of `preview`, `soak_meter` or `xp_purse` is visible (`needed_height()`), and replan when it changes: extend the `for` key to `[count, sets, roundi(preview_needed)]`.
  - Update `apply_layout()`'s region loop.
- [ ] T013 [US1] In `ui/main.gd` (around line 158, the `Solver.slot_rows(vs)` call), pass the visible preview widget's `needed_height()` through to `Solver.solve()` the same way. Update any other `"slots"` region references found by `grep -rn '"slots"\|regions.slots' ui tools tests`.
- [ ] T014 [US1] Delete `ui/widgets/slot_row.gd` and `ui/widgets/slot_row.gd.uid` once nothing references them (`grep -rn slot_row ui tools tests`).
- [ ] T015 [US1] Add a non-regression check to `tools/ui_check.gd` using the same empty-fraction maths as `tools/space_audit.gd` (T002). For every play state it already drives, FAIL when any play-screen region's empty fraction is over 1/3 at that matrix size. Move the shared maths into a small `static func empty_fraction(region: Rect2, root: Control) -> float` in `ui/model/layout_solver.gd` and call it from both tools.
- [ ] T016 [US1] Run `./tools/test.sh` (all green) and `godot --headless --path . -s tools/space_audit.gd -- --compare specs/006-etched-stone-polish/baseline.json` (PASS). Then take `godot --path . -s tools/shot.gd -- build/006-us1 phone-16x9 desktop` and compare by eye with `build/006-before`: only the rail and the left split differ (FR-022).
- [ ] T017 [US1] Walk quickstart §2 by-hand steps 1–8 on the desktop build and on the Android emulator (`install-on-emulators` skill). Fix any defect found. Commit "Role rail and a content-driven left column".

**Checkpoint**: US1 is complete and shippable on its own.

---

## Phase 4: User Story 2 - A play screen carved from stone and lit by the rift (Priority: P2)

**Goal**: The play screen (including the Final Battle) becomes carved stone with
rift light (contracts/stone-and-rift.md).

**Independent Test**: quickstart §3 steps 1–2 (Ether mood with cards covered; 5-second
first look), and `test_stone_contrast` is green.

### Tests for User Story 2 (write first)

- [ ] T018 [P] [US2] Create `tests/test_stone_contrast.gd`. Bake the textures through `Stone.grain()` (T020) and read their `Image`. Find the brightest and darkest texel luminances after remap, then:
  - Assert the brightest `≤ T.luminance(T.BG_RAISED)`.
  - Compute `bright = brightest texel colour blended with T.FOCUS at the StoneStyle's maximum rim-glow alpha` (export that alpha as `StoneStyle.GLOW_MAX_UNDER_TEXT`).
  - For every text colour in `[T.INK, T.INK_MUTED, T.GOLD, T.GOOD, T.CAUTION, T.BAD, T.HP]` plus `T.ether_ink(e)` for each Ether, assert `T.ratio(colour, bright) >= 4.5` and `T.ratio(colour, darkest) >= 4.5`.
  - For numerals, use `>= 3.0` on `T.GOLD` and the Ether inks.

  It fails until T020 exists.

### Implementation for User Story 2

- [ ] T019 [P] [US2] In `tools/gen_icons.py`, add eight ornament SVGs written to `art/icons/`, in the existing icons' flat style (a single shape, detail as cut-out negative space):
  - `orn_divider` (a gouged horizontal rule, wide aspect)
  - `orn_corner`
  - `orn_flourish_l`, `orn_flourish_r`
  - `orn_rift` (a jagged vertical tear)
  - `orn_tower`
  - `orn_seal` (a round wax seal with a carved T)
  - `orn_scroll_end`

  Run the script, open the project once headless so Godot imports them (`godot --headless --path . --import`), and commit the `.svg` and `.import` files.
- [ ] T020 [US2] Create `ui/theme/stone.gd` (`extends RefCounted`), with static, lazily baked, cached textures:
  - `grain() -> Texture2D`: a `NoiseTexture2D` 512², `seamless = true`, `FastNoiseLite` simplex fractal with 3 octaves and frequency about 0.012. Remap it into `[T.STONE_L_MIN, T.STONE_L_MAX]` luminance in a cool grey-violet near `T.BG_SURFACE`, using a `color_ramp` Gradient.
  - `cracks() -> Texture2D`: a `NoiseTexture2D` 512², seamless, `FastNoiseLite` `TYPE_CELLULAR` with `cellular_return_type = RETURN_DISTANCE2_SUB` and frequency about 0.008, inverted so the thin valleys are bright.
  - **Override**: if `res://art/stone/grain.png` or `res://art/stone/cracks.png` exists, return that instead (research D3 fallback).
  - **Readiness**: `await_ready()` waits for `NoiseTexture2D.changed` the first time, so the images can be read.

  Make T018 pass. Tune the gradient, not the floors.
- [ ] T021 [US2] Create `ui/theme/stone_style.gd` (`extends StyleBox`) overriding `_draw(to_canvas_item: RID, rect: Rect2)` and `_get_draw_rect`:
  - **Properties**:
    - `kind` (`"well"|"plinth"|"slab"|"inset"|"lintel"`)
    - `depth` (0–1)
    - `glow` (0–1)
    - `glow_colour` (`Color`, default `T.FOCUS`)
    - `fill_offset` (`Vector2`, so neighbours do not repeat)
    - `const GLOW_MAX_UNDER_TEXT := 0.35`
  - **Drawing**:
    - A chamfered polygon with corner cut `CHAMFER_S|M|L` by kind, filled with `Stone.grain()` tiled via UVs from `fill_offset`.
    - Darkened by `depth × 0.35` for wells and insets.
    - An inner bevel for recessed kinds (`well`, `inset`): a `BEVEL_SHADOW` polyline along the top and left inner edges and a `BEVEL_LIGHT` polyline along the bottom and right.
    - An outer bevel for raised kinds (`plinth`, `slab`, `lintel`): light at the top and left, shadow at the bottom and right, plus a soft cast shadow for `slab`.
    - When `glow > 0`, a rim polyline 2–3 units wide in `glow_colour` at alpha `glow × GLOW_MAX_UNDER_TEXT`, plus an outer soft line.
  - **Interface**: the content margins come from `T.S` and `T.M` by kind. Emit `changed` on property sets so tweens redraw.
- [ ] T022 [US2] In `ui/theme/theme.gd` add the stone helpers. Do **not** change `box`, `panel` or `raised_panel_box` (staging convention):
  - `static func stone_box(kind: String, depth := 0.5) -> StyleBox`, returning a configured `StoneStyle`.
  - `static func stone_panel(kind: String, depth := 0.5) -> PanelContainer`.
  - `static func style_stone_button(b: Button, kind := "normal")`: plinth states, with `primary` drawn as a gold-leafed plinth (`T.GOLD` face, dark ink) and pressed sinking to flush.
  - `static func carved_label(text, type, colour) -> Label`: a display label plus a 1-unit dark shadow offset `(0,-1)` and a light outline/offset `(0,1)` for the incised look, via `font_shadow_color` / `shadow_offset_*` and a second label or `font_outline`.
- [ ] T023 [US2] Rewrite `ui/fx/shaders/backdrop.gdshader` per research D6, keeping the existing `base`, `glow`, `ether_tint` and `tint_amount` uniforms working.
  - **New uniforms**:
    - `stone_amount` (0 = today's look exactly, 1 = stone)
    - `sampler2D grain`, `sampler2D cracks`
    - `vec4 seam_colour`
    - `int ether_id` (−1 neutral)
    - `float motion`, `float time_scale`
    - `vec2 rift_source` (UV)
    - `vec4 zones[8]`, `int zone_count`
    - `float intensity`
  - **Composition**: grain plus vignette, then seams `= smoothstep` on the crack map × `seam_colour` × shimmer. The shimmer is two sines on a per-cell hash; it is constant when `motion == 0`.
  - **Per-Ether behaviour** on `ether_id`, per contracts/stone-and-rift.md § Rift light: fire faster flicker, water slow swell, lightning rare jolt (no more than one per 4 s, ≤ 40%), shadow dim with pinpricks.
  - **Rift bloom**: a soft radial bloom from `rift_source`.
  - **Under zones**: seams × `(1 − inside(zones))`, so `SEAM_MAX_UNDER_TEXT` = 0 under zones.
- [ ] T024 [US2] Create `ui/fx/rift_layer.gd` (`extends Control`, full rect, mouse ignored) owning the backdrop's rift state:
  - **`set_ether(e)`**: tweens `seam_colour` to `T.ether_shade(e, "lit")`, or `T.SEAM_NEUTRAL` for null, over `T.RIFT_TINT_TIME` (instant under reduced motion), and sets `ether_id`.
  - **Other setters**: `set_source(global_point)`, `set_zones(rects: Array)` (≤ 8, converted to UV) and `set_stone(on: bool)`.
  - **Motes**: a placeholder hook for US3.

  In `ui/main.gd`:
  - Pass the backdrop's `ShaderMaterial` and the `Stone` textures to it.
  - Extend `_tint_backdrop(vs)` to call `set_ether`, using the Encounter's element, or the dragon's in the Final Battle phases.
  - Call `set_stone(true)` only while the play screen is shown (US4 makes it global).
- [ ] T025 [US2] In `ui/screens/play_screen.gd`:
  - Give `_hand_panel` `UI.stone_box("well", 0.9)`, and switch `_render_prominence()` to set `glow` 1 or 0 on the zone styles instead of swapping `raised_panel_box` kinds.
  - After layout, call `rift_layer.set_zones()` with the encounter, preview, rail, hand-panel and actions rects, and `set_source()` at the encounter centre. Reach `main.gd`'s rift layer through a `signal board_changed(zones, source)` that `main.gd` connects.
- [ ] T026 [P] [US2] Restyle the Encounter side to stone:
  - In `ui/widgets/encounter_face.gd`, `ui/widgets/dragon_face.gd` and `ui/widgets/face_frame.gd`, the frame becomes `UI.stone_box("well", 1.0)` with its Ether-coloured rim kept as `glow_colour` at a low resting `glow`.
  - Name bands become `lintel` with `UI.carved_label` for the name.
  - Keep every value and icon.
- [ ] T027 [P] [US2] Restyle the preview side to stone:
  - In `ui/widgets/preview_panel.gd`, `ui/widgets/soak_meter.gd` and `ui/widgets/xp_purse.gd`, replace `raised_panel_box` / `UI.box` with `UI.stone_box("well", 0.6)`, keeping the soak meter's damage border as `glow_colour`.
  - Inner chips (`ui/widgets/stat_chip.gd` *only where used by these widgets*; pass a flag rather than changing its default) become `inset`.
  - The "Still needed" chips become `inset`.
- [ ] T028 [P] [US2] Restyle the header and actions:
  - In `ui/widgets/header_bar.gd`, the header becomes a `lintel` with an `orn_divider` under the title, and the title via `UI.carved_label`.
  - In `ui/widgets/action_bar.gd`, the buttons use `UI.style_stone_button` (Play stays the gold primary).
  - In `ui/widgets/role_rail.gd`, the tokens become `inset` (`next` with `glow` 1).
- [ ] T029 [P] [US2] Restyle the in-play popups to slabs: `ui/widgets/ether_picker.gd` and `ui/widgets/card_detail.gd` become `UI.stone_box("slab")`. These are play-screen popups, not global overlays.
- [ ] T030 [US2] Check every Ether's mood and the floors:
  - Run `./tools/test.sh` (green, including `test_stone_contrast` and `ui_check` at every matrix size).
  - Run `godot --path . -s tools/shot.gd -- build/006-us2 phone-16x9 desktop`.
  - Run `godot --path . -s tools/design_shots.gd -- build/006-us2/design` (its `_ethers()` pass gives one Encounter per Ether).
  - Tune the shader behaviours until quickstart §3 step 1 (name the Ether with cards covered) works for the developer on all four. Commit "Stone and rift light on the play screen".

**Checkpoint**: The play screen is in stone; the other screens are unchanged.

---

## Phase 5: User Story 3 - A board that is alive (Priority: P3)

**Goal**: Ambient motion, a lit active zone, and a board response for every action
(contracts/board-life.md).

**Independent Test**: quickstart §3 steps 3–6.

### Tests for User Story 3 (write first)

- [ ] T031 [P] [US3] Create `tests/test_board_responses.gd` against `ui/model/board_response.gd` (T033):
  - (a) `BoardResponse.TABLE` has exactly the 12 events `place`, `take_back`, `fuse`, `divert`, `regroup`, `play`, `hit_enemy`, `take_damage`, `soak`, `upgrade`, `encounter_won`, `encounter_lost`. Each has `target`, `colour`, `motion.kind` in `["flare","surge","shudder","burst","sweep","dim"]`, `motion.duration` between `T.FAST` and `T.REVEAL`, and a non-empty `still`.
  - (b) For every step kind the animator handles (`play_cards`, `tally`, `verdict`, `gain_xp`, `damage`, `pay_time`, `poison_pending`, `knock_out`, `downgrade`, `upgrade`, `trash`, `discard`, `gather_shuffle`, `stage_banner`, `draw`, `ending`), `BoardResponse.for_step(kind, values, encounter_kind)` returns either an event in `TABLE` or `""`. It is `""` only for kinds listed in `BoardResponse.QUIET_STEPS`, and `play_cards` against an Enemy returns `hit_enemy`.
  - (c) `verdict` with outcome `complete`/`narrow` gives `encounter_won`, and `loss` gives `encounter_lost`.
- [ ] T032 [P] [US3] Extend `tests/test_view_state.gd` for the active zone (research D9):
  - `input_region` is `"rail"` when a Boost card is placed against an Enemy and `boost_to` has not been chosen. If no such pending state exists in `turn_draft.gd`, assert `"rail"` only when `draft.mode == "none"` and the player has tapped an empty token, so `active_slot` differs from the default next slot.
  - It is `"preview"` in the Soak phase.
  - It is unchanged otherwise. The existing `hand`/`commit` cases still pass.

### Implementation for User Story 3

- [ ] T033 [US3] Create `ui/model/board_response.gd` (pure, `extends RefCounted`) with `const TABLE`, `const QUIET_STEPS` and `static func for_step(kind, values, encounter_kind) -> String`, filled from contracts/board-life.md § Responses. Make T031 pass.
- [ ] T034 [US3] Extend `_input_region()` in `ui/model/view_state.gd` per T032 and research D9. Make T032 pass, then run `./tools/test.sh`.
- [ ] T035 [US3] In `ui/fx/rift_layer.gd`, add ambient life:
  - **Motes**: a `CPUParticles2D`, `amount = T.MOTES_MAX`, lifetime 4–7 s, emitting from `rift_source` in a wide upward cone with slight drift, colour from `seam_colour` at alpha about 0.5 fading to 0, size 2–5 units.
  - **Shimmer**: `motion` and `time_scale` uniform control.
  - **`set_busy(on)`**: stops emitting and halves the shimmer amplitude during animator sequences.
  - **`set_live(on)`**: pauses everything under overlays; hook it to `main.gd`'s existing `_fields_live` path.
  - **Reduced motion**: no motes (`emitting = false`), `motion = 0`.
  - **Responses**: add `respond(event: String, colour: Color)`, which plays a `BoardResponse.TABLE[event]` entry's seam-level effects:
    - `surge`: intensity up and back toward the source;
    - `flare`: a local seam flare at the zone given by `target`;
    - `dim`: intensity down and colour toward `T.BAD`;
    - `burst`: a one-shot mote burst at a point;
    - `sweep`: a seam pulse along the header.

    Under reduced motion, apply the `still` form: hold the tint for `T.BASE`.
- [ ] T036 [US3] In `ui/screens/play_screen.gd`, the active zone:
  - Keep a `_zone_styles := {hand, rail, preview, encounter, commit}` map of `StoneStyle`s.
  - In `_render_prominence()`, tween `glow` to 1 on the zone named by `vs.input_region` and 0 elsewhere over `T.BASE` (instant under reduced motion).
  - While waiting, run a looping tween breathing the active `glow` between 0.85 and 1.0 over about 3 s, killed on change and absent under reduced motion.
- [ ] T037 [US3] Wire the responses:
  - **Animator**: in `ui/fx/animator.gd` `_run()`, call `BoardResponse.for_step(st.kind, st.values, <encounter kind>)` and, if non-empty, `rift.respond(event, colour)`. Take `colour` from the card's or Encounter's Ether as the table says, via a `rift` reference set by `main.gd`, as `flight` is.
  - **Busy state**: call `rift.set_busy(true)` at sequence start and `false` on `finished`.
  - **Draft events**: in `ui/main.gd` `dispatch()`, after the draft change succeeds, call `rift.respond`:
    - `place` on a card placed (the `pick`/place path);
    - `take_back`;
    - `fuse` when a fuse completes (`fuse_element`);
    - `divert`, `regroup`.
  - **Rail feedback**: for `place` and `take_back`, also flare or fall the matching rail token via `role_rail.token_rect()` and a short `UI.flash`, or set its style colour under reduced motion.
- [ ] T038 [US3] Extend `tools/field_bench.gd`: add the stone backdrop (with `stone_amount = 1`, a seam colour, `motion = 1`) behind the 11 faces, and a live `rift_layer` emitting motes. Run it and require PASS (average ≤ 16.7 ms, p99 ≤ 33 ms). If it fails, apply research D7's fallbacks in order (motes to 12, then Ether behaviours to the plain shimmer) and re-run. Record the numbers under "Results" in `quickstart.md`.
- [ ] T039 [US3] Run `./tools/test.sh` (green). Walk quickstart §3 steps 3–5 on desktop. Then run step 6 (stutter) on the web build and the Android emulator via the `install-on-emulators` skill. Fix defects. Commit "Board life: motes, seam shimmer, active zone and responses".

**Checkpoint**: Stage 2 is complete on the play screen.

---

## Stage 2 sign-off gate (US2 scenario 5 — exit point)

- [ ] T040 Take the stage 2 screenshots with `godot --path . -s tools/shot.gd -- build/006-after phone-16x9 desktop`. Build a side-by-side for the owner of `05_challenge_assigned.png` and `12_final_journey.png` (before from `build/006-before`), and send it with the SendUserFile tool. Ask: *"Which looks more like Dragons of Etchinstone, and more finished?"* Record the answer under "Results" in `quickstart.md`.
  - **If the owner prefers before**: `git revert` the US2 and US3 commits (T030, T039 and any fixes), keep US1, run `./tools/test.sh`, commit, and **stop**. Skip Phase 6.
  - **If the owner wants the procedural stone replaced by textures**: hand off a Windows-PC generation command for `art/stone/grain.png` and `art/stone/cracks.png` (seamless 512², the luminance band from T005). Do not run it here. `Stone` picks them up automatically (T020).

---

## Phase 6: User Story 4 - Every screen in the same world (Priority: P4)

**Goal**: Carry the stone and lore framing to every other screen
(contracts/screens-and-lore.md). **Only after T040 approves.**

**Independent Test**: quickstart §5. Side-by-side of every screen; every "Must keep"
item is present; `ui_check` is green.

- [ ] T041 [US4] Make the stone global:
  - In `ui/main.gd`, call `rift.set_stone(true)` on every screen. Set the rift source and Ether per screen from contracts/screens-and-lore.md: the title takes the selected dragon's Ether at the tiles, and other screens are neutral.
  - In `ui/theme/theme.gd`, switch `box`, `panel` and `raised_panel_box` to return `StoneStyle`s: `raised_panel_box("active")` is a deep `well` with `glow` 1, `"rest"` a `well` with `glow` 0, and `box` / `panel` are `inset` when radius ≤ `T.RADIUS_S`, else `well`. `style_button` delegates to `style_stone_button`.
  - Run `./tools/test.sh` and fix any contrast or layout failure.
- [ ] T042 [P] [US4] Title as **The Tear**, in `ui/screens/title_screen.gd`:
  - The game title in a `lintel` with `UI.carved_label`.
  - An `orn_rift` seam behind the dragon tiles as the rift source.
  - Dragon tiles (`ui/widgets/choice_tile.gd`) as plinths, the selected one lit in its Ether.
  - Keep the tiles with all stats, Settings, Glossary, How to Play, Continue and the credits text.
- [ ] T043 [P] [US4] Rules setup as **the elders' proclamation**, in `ui/screens/rules_screen.gd`:
  - A slab headed by `orn_tower` and a carved "By order of the Tower".
  - Options as carved lines with `orn_divider` between groups.
  - `orn_seal` on Continue.
  - Keep difficulty, every alternate rule, Back and Continue.
- [ ] T044 [P] [US4] Region banner as a carved **lintel**, in `ui/overlays/stage_banner.gd`. Tween the rift tint to the next Region's first Encounter's Ether beneath it (`rift.set_ether`). Keep the Region number, name and glyph.
- [ ] T045 [P] [US4] Ending as an **inscribed slab**, in `ui/screens/ending_screen.gd`. Victory carves the verdict and fires `encounter_won` with gold seams; a loss fires `encounter_lost`. Keep the verdict, summary, Play again and To title.
- [ ] T046 [P] [US4] Rulebook and glossary as **scrolls**, in `ui/overlays/rulebook_overlay.gd`, `ui/widgets/rulebook_figure.gd` and `ui/overlays/glossary_popover.gd`: a slab body with `orn_scroll_end` caps top and bottom (full glossary), and a small slab for the popover. Keep the contents, sections, figures, tables, navigation and every entry.
- [ ] T047 [P] [US4] The remaining overlays as **slabs**: `ui/overlays/overlay.gd` (base: dim over stone), `ui/overlays/inspect_overlay.gd` (rift source in the card's Ether), `ui/overlays/menu_overlay.gd`, `ui/overlays/confirm_dialog.gd` and `ui/overlays/size_notice.gd`. Keep every option and button.
- [ ] T048 [US4] Check the Final Battle in the play screen: the dragon's Ether lights the rift (from T024), and the road from 003 reads as carved into the Encounter well in `ui/widgets/dragon_face.gd`. Adjust only styling.
- [ ] T049 [US4] Run `./tools/test.sh` (green at every matrix size) and `godot --headless --path . -s tools/space_audit.gd -- --compare specs/006-etched-stone-polish/baseline.json` (PASS). Then take the full screenshots:
  - `godot --path . -s tools/shot.gd -- build/006-after`
  - `godot --path . -s tools/design_shots.gd -- build/006-after/design`

  Commit "Every screen in stone: the Tear, the proclamation, slabs and scrolls".
- [ ] T050 [US4] Owner review (SC-003): for each row of contracts/screens-and-lore.md, build a before/after pair from `build/006-before` and `build/006-after`, send them with SendUserFile, and ask which is preferred. Record the answers under "Results" in `quickstart.md`, and rework any screen where the before is preferred.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T051 [P] Remove anything the restyle left unused (`grep` for `raised_panel_box`, `RADIUS_CARD`, the old flat backdrop path when `stone_amount` is always 1). Keep `stone_amount` only if T040 needed it; otherwise simplify the shader to the stone path.
- [ ] T052 [P] Reduced-motion sweep (SC-009): with Menu → Motion → Reduced, open every screen and overlay and confirm nothing moves ambiently and responses are held tints. Fix any widget that still tweens.
- [ ] T053 Run quickstart.md end to end on the desktop build, the Android emulator, the iOS simulator and the served web build (`install-on-emulators` skill). Record the results at the bottom of `quickstart.md`. Run `./tools/test.sh` a final time and commit.

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (1)**: T001–T004 on unchanged code; they come first.
- **Foundational (2)**: T005 after Setup; it blocks all stories.
- **US1 (3)**: after T005. Independent of US2–US4.
- **US2 (4)**: after US1. The stone styles the rail and the content-driven layout,
  and staging requires US1 to land first (FR-022).
- **US3 (5)**: after US2. It needs `StoneStyle.glow`, `rift_layer.gd` and the backdrop
  uniforms.
- **Gate T040**: after US3.
- **US4 (6)**: only after T040 approves.
- **Polish (7)**: after US4, or after T040 if stopped (then only T052 and T053 apply).

### Within stories

- Tests come before implementation: T006 and T007 → T008 and T009; T018 → T020;
  T031 and T032 → T033 and T034.
- US1: T008 and T009 → T010 → T011 → T012 and T013 → T014 → T015 → T016 → T017.
- US2: T019 and T020 → T021 → T022 → T023 → T024 → T025 → T026–T029 → T030.
- US3: T033 and T034 → T035 → T036 → T037 → T038 → T039.

### Parallel opportunities

- T006 ∥ T007 (different test files).
- T010 ∥ T011 once T009 is done (different widgets).
- T018 ∥ T019 (test against new code ∥ icon generation).
- T026 ∥ T027 ∥ T028 ∥ T029 (separate widget files) after T022–T025.
- T031 ∥ T032.
- T042–T047 (one screen each) after T041.
- T051 ∥ T052.

## Parallel Example: User Story 2 restyle

```text
Task: "T026 [US2] Restyle encounter_face.gd, dragon_face.gd, face_frame.gd to stone wells"
Task: "T027 [US2] Restyle preview_panel.gd, soak_meter.gd, xp_purse.gd to stone wells"
Task: "T028 [US2] Restyle header_bar.gd (lintel), action_bar.gd (plinths), role_rail.gd (insets)"
Task: "T029 [US2] Restyle ether_picker.gd and card_detail.gd to slabs"
```

## Implementation Strategy

### MVP first (User Story 1 only)

1. Setup (T001–T004) and Foundational (T005).
2. US1 (T006–T017): the role rail and the content-driven left column, on today's look.
3. **Stop and validate**: `space_audit --compare` PASS and quickstart §2. This ships
   on its own and answers the owner's one concrete complaint.

### Incremental delivery

1. US1 → commit (MVP).
2. US2 → commit (stone and rift on play).
3. US3 → commit (life).
4. **T040 owner gate**. Rejected → revert stage 2, stop. Approved → continue.
5. US4 → commit (every screen) → T050 owner review.
6. Polish.

### Notes

- [P] tasks touch different files and have no dependency on incomplete tasks.
- Commit at the end of each phase. Keep stage 2 in its own commits so T040 can revert
  it cleanly.
- Never edit `engine/` or `data/`. Never run art generation on this Mac.
