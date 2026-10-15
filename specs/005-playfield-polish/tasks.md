---

description: "Task list for Playing Field and Card Polish"
---

# Tasks: Playing Field and Card Polish

**Input**: Design documents from `/specs/005-playfield-polish/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. The plan names new headless tests (emphasis, contrast, face layout, layout floor) as the gates for FR-010, FR-018, FR-026 and SC-004/005; they are written before the code they check.

**Organization**: Tasks are grouped by user story (US1 card face P1, US2 step emphasis P2, US3 layout P3, US4 field colour and depth P4).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Paths are relative to the repository root. Run all tests with `./tools/test.sh`.

## Conventions every task follows

- `engine/` and `data/cards.json` are never edited (FR-028).
- GDScript style: tabs, `##` doc comments on every function and file, typed locals,
  preload constants named like `const T = preload("res://ui/theme/tokens.gd")`.
  Match the surrounding file.
- Test files extend `"res://tests/base.gd"` and use `eq()` / `ok()`; every
  `test_*` method is picked up by `tests/run.gd` automatically. Build games as
  `tests/test_view_state.gd` does (`Game.new(db, {"seed": 3, "dragon": "rodving", "difficulty": "normal"})`).
- Minimum text 22 design units (`T.TEXT_MIN`), tap target 88 (`T.TAP_MIN`).
- Anything that animates checks `Settings.reduced_motion()` (`ui/model/settings.gd`)
  and applies the end state at once when it is true.

---

## Phase 1: Setup (Baselines before anything changes)

**Purpose**: Record today's look and sizes so later tests and reviews compare against them. Do these on the unmodified code.

- [X] T001 Capture "before" screenshots: run `godot --path . -s tools/shot.gd -- build/screenshots/005-before phone-16x9 desktop tablet` and `godot --path . -s tools/design_shots.gd -- build/screenshots/005-before-cards`; confirm `build/screenshots/005-before/phone-16x9/04_challenge_one.png`, `07_soak.png`, `08_upgrade.png`, `09_inspect.png` exist (build/ is git-ignored; do not commit them)
- [X] T002 Record today's Hand card widths: write a throwaway script in the scratchpad (not the repo) that calls `LayoutSolver.solve(view, safe, n, 1, ppu)` from `ui/model/layout_solver.gd` for every entry of `LayoutSolver.MATRIX` (use `view_for_window()` and the safe-area insets the same way `tests/test_layout_solver.gd` does) with `n` = 4 and 7, and prints `card_size.x`; paste the results as `const BASELINE_CARD_W := {"phone-16x9": {4: …, 7: …}, …}` and a new `test_hand_cards_are_no_smaller_than_before()` into `tests/test_layout_solver.gd` that asserts `card_size.x >= BASELINE_CARD_W[name][n]` for each; run `./tools/test.sh` and confirm it passes on unchanged code
- [X] T003 Record today's card numeral sizes: in a scratchpad script, reproduce the sizing maths of `_draw_ink()` in `ui/widgets/card_face.gd` (`row = floor((f.size.y - pad - gap*4)/5)`, `num = min(row*0.86, T.NUMERAL[1]*1.15)`, name font size from `_name()`) for face sizes 197×275 (Hand at phone-16x9), 170×238 (detail) and 314×440 (inspect); write the numbers to `specs/005-playfield-polish/baseline.md` as a small table (size → row, numeral, initiative numeral = num×0.78, armor numeral = num×0.74)

---

## Phase 2: Foundational (Theme values every story uses)

**Purpose**: Ether palette, focus colour and a contrast helper. Blocks US1, US2 and US4.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 In `ui/theme/tokens.gd` add: `FOCUS := Color("ffe08a")` (focus rim and glow), `CARD_FRAME := Color("0d0b10")`, `BRONZE := Color("5a4632")`, `BRONZE_DARK := Color("3a2c1f")`, `BRONZE_LIGHT := Color("a88a63")`; replace the `ETHER` values with the saturated printed hues (fire `c8261d`, water `1f5fd0`, lightning `e99a1c`, shadow `6b34c0`) and add `const ETHER_ID := {"fire": 0, "water": 1, "lightning": 2, "shadow": 3}`; add `static func ether_shade(element, role: String) -> Color` with roles `"base"`, `"deep"` (base darkened 0.55), `"lit"` (base lightened 0.35), `"plate"` (base; for lightning darkened 0.1) returning `LINE_SOFT` for null; keep `ether(element)` returning the base so existing callers still work
- [X] T005 In `ui/theme/theme.gd` add `static func contrast(a: Color, b: Color) -> float` (WCAG 2.1 relative-luminance ratio, sRGB linearised) and `static func best_ink(bg: Color) -> Color` returning whichever of `T.INK` and `T.BG_BASE` has the higher `contrast()` against `bg`; add `T.ether_shade(e, "plate_ink")` support in `tokens.gd` by calling the same maths (tokens.gd must not preload theme.gd, so put the luminance maths in `tokens.gd` as `static func luminance(c)` and have `theme.gd` call it)
- [X] T006 Create `tests/test_card_contrast.gd`: for each Ether in `T.ETHER` assert `UI.contrast(T.ether_shade(e,"plate_ink"), T.ether_shade(e,"plate")) >= 3.0` (large numerals); assert `contrast(T.INK, T.CARD_FRAME) >= 4.5`, `contrast(T.INK, T.BRONZE) >= 4.5`, `contrast(T.GOLD, T.BRONZE) >= 3.0`, `contrast(T.INK_MUTED, quiet) >= 4.5` where `quiet = fill.lerp(T.BG_BAND, 0.75)` for every plate fill used on the face (black plate `T.BG_BAND`, each Ether `plate`), and `contrast(T.BAD, T.BRONZE) >= 3.0` (unaffordable cost); tune the T004 colour values until every assertion passes; run `./tools/test.sh`

**Checkpoint**: Palette and contrast helper in place; `./tools/test.sh` green.

---

## Phase 3: User Story 1 - Cards that look like the official cards (Priority: P1) 🎯 MVP

**Goal**: Every Mage Card face is redrawn in the official style with depth, the official Ether symbols and a living per-Ether field; the inspect view shows every Level.

**Independent Test**: Lay the Hand beside `reference/sheets-official/o4a.png` and confirm the styling matches; view `ethers.png` from design shots in greyscale and name each Ether; hold a card and see all its Levels (quickstart §2–§4).

### Tests for User Story 1 ⚠️

> Write first; they fail until T012–T013 land.

- [X] T007 [P] [US1] Create `tests/test_card_face_layout.gd`: instantiate `preload("res://ui/widgets/card_face.gd").new()`, set `size` to each of 197×275, 170×238, 280×392 and 314×440, set a model from `CardDB.new()` (`db.mage(id)`, `db.mage_level(id, 1)`) for one card of each Ether; for each region key in `["level","name","key","cost","initiative","basic","enhanced","boost","armor","ether"]` assert `region_rect(key)` lies inside `Rect2(Vector2.ZERO, size)`, and that no two regions except `ether` intersect (`Rect2.intersects` with a 1-unit shrink); assert `numeral_size()` (a new public function returning the main numeral font size) at 197×275 is ≥ the value recorded in `specs/005-playfield-polish/baseline.md` (copy it into the test as `const BASELINE_NUMERAL := …` with a comment pointing at baseline.md); free the node at the end

### Implementation for User Story 1

- [X] T008 [P] [US1] In `tools/gen_icons.py` redraw the four Ether shapes in `ICONS` (48-unit box, white, as today): `"fire"` a slim flame leaning right with a curl at the tip and a rounded base; `"lightning"` a sharp three-segment zig-zag bolt, wide top, pointed bottom; `"shadow"` a four-point sparkle star (concave sides, long vertical points, shorter horizontal points); `"water"` a clean droplet (keep the current path if it already matches). Change `sigil()` for the four `sigil_<ether>` entries to draw the same shape large with an inner etched outline (a scaled-down copy subtracted as a stroke) and a soft outer flare, without the ticked ring; leave the dragon sigils and `sigil_region` unchanged. Compare by eye against the Ether pips beside the card names in `reference/sheets-official/o4a.png` and `o1a.png`
- [X] T009 [US1] Regenerate icons with `python3 tools/gen_icons.py`, then `godot --headless --path . --import` so `art/icons/*.svg.import` refresh; open `art/icons/fire.svg`, `lightning.svg`, `shadow.svg`, `water.svg`, `sigil_*.svg` and confirm they render (depends on T008)
- [X] T010 [P] [US1] Create `ui/fx/shaders/ether_card.gdshader` (canvas_item, single pass, no textures) per research D4 and `contracts/card-face.md` "Ether character": uniforms `int ether`, `vec4 tint`, `vec4 deep`, `vec4 lit`, `vec2 size`, `float motion` (0 or 1), `float phase`, `float focus_dim` (0–1), `float dim` (0–1, greyscale as in `ether_field.gdshader`); a shared labyrinth base from iso-lines of 2-octave value noise (`fract(n*6.0)` banded with `smoothstep`) scaled by `size` so the pattern keeps its scale; `float t = TIME * motion + phase`; Fire: noise domain scrolled upward and warped sideways, hashed embers rising and fading, glow breathing at the bottom; Lightning: static maze, every 1.5–3 s (hash of floor(t/period)+phase) a forked arc (abs of noise-displaced line distance) flashing ≈0.12 s with a whole-field brighten, faint sparks travelling along maze lines between flashes; Water: maze lines displaced by a sideways sine flow, two drifting caustic bands; Shadow: swirl (rotate UV by angle ∝ distance and t) around centre, four-point sparkles fading in and out, edges breathing darker; with `motion = 0` each branch must still show its signature (a frozen arc for Lightning, embers for Fire, bands for Water, sparkles for Shadow); vignette darker toward edges; apply `focus_dim` as a 25 % darken and `dim` as greyscale + darken; header comment says what each uniform does
- [X] T011 [US1] Rebuild `ui/widgets/card_face.gd` — structure and bands: keep the public API (`model`, `dimmed`, `changed`, `glow`, `set_model(m, ring, ring_colour)`, `set_dimmed`); add `func region_rect(key: String) -> Rect2` computed only from `size` (pure geometry, no drawing state, so tests can call it without a scene tree) using the band fractions in `contracts/card-face.md` (top band 0.150 h, key strip 0.095 h, field below, stat column rows ≈ field h / 5.4) and `func numeral_size() -> float`; add a `_raised(rect, points_or_rect, fill)` helper that draws shadow (offset 0,2, black 35 %) → body → 1-unit top highlight (fill lightened 0.25 at 60 %) → 1-unit bottom shade (fill darkened 0.4); draw the frame in `T.CARD_FRAME` with soft drop shadow and a thin inner rim in `T.ether_shade(e,"lit")` at 25 % (no coloured border); top band: white crown (`crown` icon tinted `T.INK`) with the Level number in `T.BG_BASE`, a small Ether pip (the card's Ether icon in its `lit` shade) then the name in display caps via the existing `_name()`; key strip in `T.BRONZE` with a pointed tab on the left edge, Encounter icon + index + Hardship on the left, Upgrade cost + `xp` icon on the right with a thin `T.BRONZE_LIGHT` rule running to the right edge; torn edges where the bands meet the field: a jagged polyline in `T.CARD_FRAME` whose jitter comes from a hash of `model.id` (same card, same tear); switch the field `ColorRect` material to `ether_card.gdshader` and set `ether`, `tint`, `deep`, `lit`, `size`, `phase` (hash of `model.id` mod 97 / 9.7) in `_layout()`
- [X] T012 [US1] Rebuild `ui/widgets/card_face.gd` — stat column and field ink: draw the sword behind the column (blade 3 units wide at Hand size, scaled by `size.x/190`, in `T.INK_MUTED` with `_raised` bevel; crossguard level with the two action plates; pommel behind the Armor crest); Initiative in a black pennant crest (pointed bottom); basic and enhanced actions as octagon plates (`_octagon(rect)` polygon) with numeral + action icons as `_action()` does today; a small down-arrow between them; enhanced plate filled with `T.ether_shade(enh,"plate")`, ink `T.ether_shade(enh,"plate_ink")`, Ether pip at its top-right corner; Boost as a black square plate on the blade showing `+N`; Armor as a shield crest, filled with the Armor Ether `plate` colour when `armor.element != null` (ink `plate_ink`) else black, with the Ether pip beside it; the large `sigil_<ether>` right of centre at 22 % alpha; keep `_ring()` behaviour for `changed` keys (`initiative`, `basic`, `enhanced`, `boost`, `armor`, `upgrade_cost`, `encounter`, `hardship`) drawn around the new shapes; keep `_crack()` for Downgraded cards drawn last; keep `dimmed` greying the field (`dim` uniform) and the frame; every numeral uses `numeral_size()`-derived sizes no smaller than `baseline.md`; run `./tools/test.sh` until `tests/test_card_face_layout.gd` and `tests/test_card_contrast.gd` pass (depends on T011)
- [X] T013 [US1] Add `var motion := true: set = set_motion` to `ui/widgets/card_face.gd`; the setter writes the shader's `motion` uniform as `1.0 if motion and not Settings.reduced_motion() else 0.0` (preload `res://ui/model/settings.gd`); re-evaluate in `set_model()` so a change of the Motion setting takes effect on the next render
- [X] T014 [US1] Update `ui/widgets/card_view.gd` `_draw_marks()` so ribbons, tags, order badges and the dashed outline sit correctly on the new face (use `_face.region_rect()` where they reference card parts; keep their texts and colours); confirm `_show_alt()` still swaps in the alternate Level with its `changed` ring
- [X] T015 [P] [US1] In `ui/widgets/card_detail.gd` set `_face.motion = visible` whenever `show_card()` / `hide_card()` change visibility so a hidden detail face does not animate
- [X] T016 [US1] Rewrite `ui/overlays/inspect_overlay.gd` `setup()` per `contracts/playfield-layout.md` "Inspect overlay": one face per Level from 1 to `db.mage(id).levels.size()`, all the same size (largest that fits that many faces with `T.L` gaps in `content`, height ≤ 440), left to right; the current Level raised with a `T.FOCUS` 3-unit rim (wrap the face in a `PanelContainer` with `UI.box(Color.TRANSPARENT, T.FOCUS, 3, T.RADIUS_CARD, 4)`) and titled `"CURRENT · LEVEL %d"` in `T.GOLD`; titles above others: Level n−1 `"IF DOWNGRADED"` (`T.BAD`), Level n+1 `"IF UPGRADED · %d XP"` (`T.GOOD`, cost from `db.mage_level(id, n).upgrade_cost`), others `"LEVEL %d"` (`T.INK_MUTED`); captions under n−1 and n+1 from the existing `_changes()`; when n is 1 add the existing "A Level 1 card is Trashed and scores nothing." caption under the current face; pass `changed` rings to the n−1 and n+1 faces (keys as in `ViewState._alt()`); keep "Tap anywhere to close"; delete the now-unused `_note()` if nothing calls it
- [X] T017 [US1] In `ui/main.gd`, connect `_overlays.child_entered_tree` and `child_exiting_tree` so that while any overlay is open every Hand card face and the detail face get `motion = false`, and get `motion = true` when the last overlay closes (add `func set_fields_live(on: bool)` to `ui/screens/play_screen.gd` that walks `hand` card views and `detail`)
- [X] T018 [P] [US1] Extend `tools/design_shots.gd`: after the existing shots, add a shot `ethers.png` that places four `CardFace` nodes (one card of each Ether from `CardDB`, Level 2) at Hand size side by side on the backdrop with `motion = false`, plus `ethers_grey.png` with the same scene under a greyscale `CanvasLayer` shader (or by saving a greyscale copy of the image with `Image.convert`/luminance loop)
- [X] T019 [P] [US1] Create `tools/field_bench.gd` (`extends SceneTree`, run with `godot --path . -s tools/field_bench.gd`): open a 1280×720 window, place 11 `CardFace` nodes (mixed Ethers) at Hand size with `motion = true`, run 10 s, sample `Performance.get_monitor(Performance.TIME_PROCESS)` and frame delta each frame, print average, 99th-percentile and worst frame time in ms and `PASS` if average ≤ 16.7 and 99th percentile ≤ 33, then quit
- [X] T020 [US1] Check the other users of the face and the Ether icons: `ui/widgets/rulebook_figure.gd` (card figure still sized `h * T.CARD_ASPECT`), `ui/widgets/face_frame.gd` and `ui/widgets/encounter_face.gd` (still use `ether_field.gdshader` and `sigil_<ether>`; confirm the new sigils look right at Encounter size), `ui/widgets/slot_row.gd` and `ui/widgets/dragon_stats.gd` (new Ether icons); fix anything that clips or misaligns
- [X] T021 [US1] Validate US1: `./tools/test.sh` green; `godot --path . -s tools/shot.gd -- build/screenshots/005-us1 phone-16x9 desktop`; `godot --path . -s tools/design_shots.gd -- build/screenshots/005-us1-cards`; `godot --path . -s tools/field_bench.gd` prints PASS; compare `04_challenge_one.png` and `09_inspect.png` with `reference/sheets-official/o4a.png` (frame, bronze strip, torn edges, sword spine, crests, octagon plates, Ether pip by the name) and with `build/screenshots/005-before`; name the four Ethers from `ethers_grey.png`

**Checkpoint**: Cards look like the official cards, Ethers are alive, inspect shows every Level. MVP is shippable here.

---

## Phase 4: User Story 2 - The card shows what matters right now (Priority: P2)

**Goal**: In every step the regions of each card that the step uses are emphasised and the rest quietened, matching the step table in `contracts/step-emphasis.md`; the next slot shares the treatment.

**Independent Test**: Play into each step (build, Fuse, Divert, Soak, Upgrade); show the Hand for 3 seconds and have someone point at the value that matters on each card (quickstart §2 and §5).

### Tests for User Story 2 ⚠️

- [X] T022 [P] [US2] Create `tests/test_emphasis.gd` (helpers copied from `tests/test_view_state.gd`: `_game`, `_filled`, `_to_final`, `_pair_in_hand`) with: `test_focus_is_pure` (build `ViewState.build` twice, `cards[*].focus` equal); `test_setup_has_no_focus`; `test_next_slot_drives_hand_focus` (empty draft → every unplaced card `regions == ["basic","enhanced"]`; after one tap → `["ether","initiative"]`; after two → `["boost"]`; `vs.next_role` matches each time); `test_placed_cards_focus_on_their_role` (Element card → `["ether","initiative"]`, Boost → `["boost"]`); `test_placed_spell_shows_the_action_in_effect` (for seeds 1–40, whenever a set is full, the Spell's region is `["enhanced"]` exactly when `g.preview(d.to_action()).enhanced` is true, else `["basic"]`; with no Element placed it is `["basic","enhanced"]`); `test_reserve_boost_only_when_it_counts` (journey Encounters across seeds 1–60: Reserve card has `"boost"` in regions exactly when the engine's `move` with the Reserve's Boost differs from `move` computed with `reserve_boost` 0 — compute via `Rules.resolve_journey` with both values); `test_fuse_and_divert` (fuse modes → `["ether"]`; divert/regroup → `[]`); `test_soak_focus_and_mark` (penalty phase: eligible cards `regions == ["armor"]`, `mark == "soaks_more"` iff `match`); `test_upgrade_marks_agree_with_eligibility` (affordable → `"affordable"` and regions ⊇ `["cost"]` plus mapped `alt.changed`; `reason` "Max Level" → `"max_level"`; "Costs N XP" → `"unaffordable"`; Downgraded → regions `[]`, mark `""`); `test_two_action_sets_follow_the_active_slot` (final phase, set 2 active → `next_role` and hand focus follow `draft.active`); `test_input_region` (`"hand"` with an empty draft; `"commit"` with a full set and mode none; Soak covered → `"commit"`); set up phases the same way `tests/test_view_state.gd` `test_soak_step_marks_cards_and_covers_damage` and `test_upgrade_step_explains_what_cannot_be_upgraded` do

### Implementation for User Story 2

- [X] T023 [US2] Create `ui/model/emphasis.gd` (`extends RefCounted`, static only, `##` docs) implementing `static func context(game, draft) -> Dictionary` (keys `phase`, `mode`, `next_role` = `draft.active[1]` if `draft.active` names an empty slot else `""`, `kinds` = `["attack","move"]` for a Slow enemy, `["attack"]` for other enemies and `final_enemy`, `["move"]` for journeys and `final_journey`, `sets` = each set's placed Element card's Ether or `""`, `journey_ether` = the journey's `mp.element` or `""`, `xp`) and `static func focus(c: Dictionary, lv: Dictionary, ctx: Dictionary) -> Dictionary` returning `{"regions", "mark", "changed"}` exactly per the step table in `contracts/step-emphasis.md`, using `Rules.action(lv_of_spell, element, kinds)` (preload `res://engine/rules.gd`) for the placed Spell and the Reserve rule "Spell action enhanced and its element == journey_ether"; map `alt.changed` keys with `{"upgrade_cost":"cost","encounter":"key","hardship":"key"}` (others unchanged), de-duplicated
- [X] T024 [US2] Wire `ui/model/view_state.gd`: in `build()` compute `var ctx := Emphasis.context(game, draft)` once; in `_card()` (after the existing phase match) set `c.focus = Emphasis.focus(c, lv, ctx)` — pass what `focus()` needs (the card's set and role from `c.role`, the set's Spell level data via `game.level_data(id)`); add `vs.next_role = ctx.next_role`; after `vs.prompt` is built add `vs.input_region` per `data-model.md`: `"commit"` when `vs.prompt.primary.enabled` and (building with mode `"none"` and preview `ready` | Soak `covered` | setup picks complete | Upgrade with no eligible card), else `"hand"`; keep "This is the only UI file that reads the engine's internals" true (Emphasis receives the game only through `context()` called here). Run `./tools/test.sh` until `tests/test_emphasis.gd` and `tests/test_view_state.gd` pass
- [X] T025 [US2] Add focus treatments to `ui/widgets/card_face.gd` per `contracts/card-face.md` "Treatments": `func set_focus(f: Dictionary)` storing regions/mark; a private `_focus_t` (0→1) tweened over `T.FAST` when the focus changes (set instantly when `Settings.reduced_motion()`); emphasised regions drawn raised 2 units further with a 2-unit `T.FOCUS` rim and a soft outer glow (two widening rims at 25 % and 10 %); quietened regions: plate fill `fill.lerp(T.BG_BAND, 0.75)`, no highlight, ink `T.INK_MUTED`, field `focus_dim = 0.25` unless `"ether"` is emphasised (then brighten the field 15 % and outline the name pip and sigil in `T.FOCUS`); marks: `soaks_more` → a `"×2"` chip on the Armor crest in the damage Ether's `lit` colour (the damage Ether is passed in the focus dictionary as `damage_element`; add it in T023 for Soak phases from `game.damage_element`), `affordable` → cost in `T.GOLD` with the focus rim, `unaffordable` → cost in `T.BAD` with no rim, `max_level` → cost text `"MAX"` in `T.INK_MUTED`; when `dimmed` (unavailable) draw no focus rims at all
- [X] T026 [US2] In `ui/widgets/card_view.gd` call `_face.set_focus(m.get("focus", {}))` in `set_model()`; in `_show_alt()` keep the focus when swapping to the alternate Level (edge case: hover keeps the step's emphasis); make sure the existing "Soaks N", "N XP" and reason tags still sit clear of the emphasised Armor crest and cost (move tags using `_face.region_rect()` if they overlap)
- [X] T027 [US2] In `ui/widgets/slot_row.gd` `_slot()`: the active slot (`active == true`) uses `T.FOCUS` for its border (3 units) and glow (`StyleBoxFlat.shadow_color = Color(T.FOCUS, 0.35)`, `shadow_size = 10`), its role icon and role label in `T.FOCUS`, replacing `T.GOLD` there; inactive empty slots keep `T.LINE_SOFT`
- [X] T028 [US2] Validate US2: `./tools/test.sh` green; `godot --path . -s tools/shot.gd -- build/screenshots/005-us2 phone-16x9`; check `03_challenge_empty` (Spell plates lifted), `04_challenge_one` (Ether + Initiative lifted, Element slot glows the same colour), `05_challenge_assigned`, `07_soak` (Armor lifted, ×2 chip on matching cards, covered cards greyscale not quietened), `08_upgrade` (cost states); set Menu → Motion → Reduced and confirm focus changes are instant

**Checkpoint**: US1 and US2 both work; every step points the eye at the right part of every card.

---

## Phase 5: User Story 3 - A playing field with room to breathe (Priority: P3)

**Goal**: More air between and around regions with cards no smaller, a quieter header, and the region taking input brought forward.

**Independent Test**: Show the play screen at `phone-16x9` for 5 seconds; a first-time viewer names the Encounter, the predicted result and the Play control (quickstart §5); layout tests pass at every matrix size.

### Tests for User Story 3 ⚠️

- [X] T029 [P] [US3] Extend `tests/test_layout_solver.gd` per `contracts/playfield-layout.md` "Invariants": `test_regions_have_air` (for every `MATRIX` entry, the gap between horizontally or vertically adjacent regions in `regions` is ≥ 12); `test_hand_cards_have_air` (for n = 4 and 7, adjacent `card_rects` in a row are ≥ 12 apart); `test_extra_space_goes_to_content` (for every entry larger than `phone-16x9`, `card_size.x` and `regions.encounter.size.y` are ≥ their `phone-16x9` values); keep `test_hand_cards_are_no_smaller_than_before` from T002 unchanged

### Implementation for User Story 3

- [X] T030 [US3] Change `ui/model/layout_solver.gd`: `HEADER_H` 56 → 48, `GAP` 8 → 12, `COLUMN_GAP` 16 → 24; `left_w := clampf(roundf(c.size.x * 0.32), 400.0, 560.0)`; slot spare growth `clampf(spare - 24.0, 0.0, 40.0)`; in `_fit_cards()` use a 12-unit minimum gap between columns instead of `GAP` where it computes `w`; in `_card_gap()` clamp to `12.0`–`36.0`; run `./tools/test.sh` — all layout tests (old, T002 floor, T029) and `tools/ui_check.gd` must pass; if the floor fails at any size, reduce the left column ratio in 0.005 steps (not below 400 units) rather than shrinking gaps
- [X] T031 [P] [US3] Quieten `ui/widgets/header_bar.gd`: Region title in `T.HEADING` and `T.INK` (no longer `T.GOLD`), progress bar track `LINE_SOFT` at 50 % with fill `T.INK_MUTED`, pile icons and counts in `T.INK_MUTED` at `T.LABEL` size; fit everything in the new 48-unit height; keep `pile_point()` and `bump()` working (the bump flash may stay gold)
- [X] T032 [US3] Add `static func raised_panel_box(kind: String) -> StyleBoxFlat` to `ui/theme/theme.gd`: `"active"` → bg `T.BG_RAISED`, border `Color(T.FOCUS, 0.6)` 2 units, `shadow_color` black 40 %, `shadow_size` 12, `shadow_offset` (0, 4); `"rest"` → bg `T.BG_SURFACE`, border `Color(T.LINE_SOFT, 0.5)` 1 unit, shadow black 30 %, size 6, offset (0, 2); both `T.RADIUS_M` corners and `T.S` content margins
- [X] T033 [US3] In `ui/screens/play_screen.gd` `render()`, apply `UI.raised_panel_box("active")` to the panel matching `state.input_region` and `"rest"` to the others: `"hand"` → a panel behind the Hand region (add a `Panel` under the hand tray sized to `plan.regions.hand`, mouse ignored), `"commit"` → the commit button's region outline glow (`ActionBar`'s primary button gets the active style's shadow and rim); the preview panel and the slots always use `"rest"` unless one becomes the input region later; changes animate over `T.FAST` (instant with reduced motion)
- [X] T034 [US3] Validate US3: `./tools/test.sh` green; `godot --path . -s tools/shot.gd -- build/screenshots/005-us3` (every size); compare against `build/screenshots/005-before`: visibly more air, cards the same size or larger, header quieter than the Encounter, the Hand panel raised while choosing and the Play button raised once ready

**Checkpoint**: Layout breathes at every size; all existing UI checks still pass.

---

## Phase 6: User Story 4 - Colour and depth on the field (Priority: P4)

**Goal**: Background, panels and cards read as three layers; the Encounter area carries its Ether; result colours are consistent.

**Independent Test**: Before/after screenshots side by side (quickstart §2); viewers pick the after version as more finished; contrast tests still pass.

### Implementation for User Story 4

- [X] T035 [P] [US4] Edit `ui/fx/shaders/backdrop.gdshader` and its owner (find with `grep -rn backdrop.gdshader ui`): add a `uniform vec4 ether_tint` blended at ≤ 12 % into the top-left quadrant behind the Encounter, and a stronger edge vignette; set the tint from `T.ether_shade(state.encounter.element, "deep")` on each `play_screen.gd` render (neutral when there is no Encounter); fade the change over `T.BASE` (instant with reduced motion)
- [X] T036 [P] [US4] In `ui/widgets/face_frame.gd` (used by `encounter_face.gd`, dragon and setup faces) switch the frame and field tint to the new palette (`T.ether_shade(e, "deep")` for the field centre, `"lit"` for the border) and give the frame the same drop shadow and top highlight as card faces (reuse the values from `card_face.gd`'s `_raised`)
- [X] T037 [US4] Give the remaining play-screen panels depth with `UI.raised_panel_box("rest")`: the preview container in `ui/widgets/preview_panel.gd`, `ui/widgets/soak_meter.gd`, `ui/widgets/xp_purse.gd`, slot buttons' normal style in `ui/widgets/slot_row.gd`, and secondary buttons in `ui/widgets/action_bar.gd` (keep each one's existing border colour where it carries meaning, e.g. the soak meter's damage colour)
- [X] T038 [US4] Audit result colours: `grep -rn "T.GOOD\|T.CAUTION\|T.BAD" ui`; make every verdict, cost and recap use `T.VERDICT[outcome].color` or the same three tokens (`ui/widgets/preview_panel.gd`, `ui/overlays/stage_banner.gd`, `ui/widgets/slot_row.gd` `_recap()`, `ui/widgets/soak_meter.gd`); no hard-coded result colours remain
- [X] T039 [US4] Validate US4: `./tools/test.sh` green; screenshots at `phone-16x9` and `desktop` into `build/screenshots/005-us4`; confirm background, panels and cards separate by shading alone (view a greyscale copy), the Encounter area takes its Ether's colour for a Fire and a Water Encounter

**Checkpoint**: All four stories complete.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T040 [P] Search `ui/model/rulebook.gd` and `ui/model/glossary.gd` for text describing the old card look (coloured border, swirl, crescent for Shadow, etc.) and update the wording to the new look; the rulebook sentence "Only the current Level counts, and it is the only one drawn." stays true on the field — add "Hold a card to see all its Levels." if not already said
- [X] T041 Full screenshot matrix: `godot --path . -s tools/shot.gd -- build/screenshots/005-after` (every size) and `tools/design_shots.gd -- build/screenshots/005-after-cards`; review every shot against `005-before` for clipping, overlap and legibility, including rulebook pages (`01a`–`01d`), the ending and the menu
- [X] T042 Reduced-motion pass: set Motion → Reduced in the menu; confirm card fields are still, each Ether still shows its character, focus changes and panel prominence switch instantly, the backdrop tint switches instantly
- [ ] T043 Performance on the weak target: run `godot --path . -s tools/field_bench.gd` (PASS required); export the web build (`export_presets.cfg` web preset) and open the setup offer and a full Hand on a mid-range phone browser; if it stutters, simplify the most expensive Ether branch in `ui/fx/shaders/ether_card.gdshader` first (drop to 1 octave, then fewer sparks) and re-run
- [X] T044 Run `./tools/test.sh` one final time; it must be green, including `tools/ui_check.gd` (identical outcomes to the engine-only run, SC-010)
- [ ] T045 Observer checks from `specs/005-playfield-polish/quickstart.md` §3 and §5 (greyscale Ether naming, 3-second Hand focus, 5-second first look, before/after, owner recognition); note results at the bottom of `specs/005-playfield-polish/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: first, on unmodified code. T002 must land before T030; T003 before T007/T012.
- **Foundational (Phase 2)**: after Setup; blocks US1, US2 and US4 (palette, `FOCUS`, contrast).
- **US1 (Phase 3)**: after Foundational.
- **US2 (Phase 4)**: after US1's face rebuild (T011–T012), because treatments are drawn on the new face (spec clarification: card rework first). T022–T024 (model and tests) can start in parallel with US1.
- **US3 (Phase 5)**: after Foundational; independent of US1/US2 except T033 uses `input_region` from T024 (do T029–T032 any time, T033 after T024).
- **US4 (Phase 6)**: after Foundational; T037 uses T032.
- **Polish (Phase 7)**: after the stories you intend to ship.

### User Story Dependencies

- **US1 (P1)**: none beyond Foundational.
- **US2 (P2)**: face work (T025–T026) depends on US1 T011–T013; model work (T022–T024) does not.
- **US3 (P3)**: T033 depends on US2 T024; the rest is independent.
- **US4 (P4)**: T037 depends on US3 T032; the rest is independent.

### Within Each User Story

- Tests first, and seen failing, before the code they check.
- Model (`emphasis.gd`, `view_state.gd`) before widgets.
- `card_face.gd` tasks are sequential (T011 → T012 → T013 → T025): one file.

### Parallel Opportunities

- T008 (icons), T010 (shader) and T007 (face test) are different files: run together.
- T015, T018, T019 are independent of each other once T013 is in.
- T022 and T023 can be written alongside US1's face tasks.
- T029, T031 and T032 are different files.
- T035, T036 are different files.

---

## Parallel Example: User Story 1

```text
# After Phase 2:
Task: "T007 Create tests/test_card_face_layout.gd"
Task: "T008 Redraw Ether shapes in tools/gen_icons.py"
Task: "T010 Create ui/fx/shaders/ether_card.gdshader"

# After T013:
Task: "T015 card_detail.gd motion off when hidden"
Task: "T018 design_shots.gd ethers.png"
Task: "T019 tools/field_bench.gd"
```

## Parallel Example: User Story 2

```text
# Can start while US1 is in progress:
Task: "T022 Create tests/test_emphasis.gd"
Task: "T023 Create ui/model/emphasis.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 baselines (on unmodified code).
2. Phase 2 palette and contrast.
3. Phase 3: new card face, Ether symbols, living fields, all-Levels inspect.
4. **Stop and validate** with T021: this alone answers "make the cards look better
   and closer to the official ones".

### Incremental Delivery

1. Setup + Foundational → palette ready.
2. US1 → official-style living cards (MVP).
3. US2 → step emphasis on the new face.
4. US3 → layout air and prominence.
5. US4 → field depth and Ether tint.
6. Polish → matrix review, reduced motion, web performance, observers.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks.
- Commit only when the user asks (user rule); never add Claude attribution to commit messages.
- `reference/` is git-ignored; never copy pixels from the scans into `art/`.
- If a test written first already passes before its implementation, tighten it.
