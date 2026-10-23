# Tasks: Unified Design System (Inkstone and Brass)

**Input**: Design documents from `specs/019-unified-design-system/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. FR-024 asks for automated checks, and [contracts/checks.md](contracts/checks.md) lists them.

**Source of truth**: [design-system/tokens.json](design-system/tokens.json) and
`design-system/components/<Name>/README.md`. Where this file names a value, the contracts
hold the full table. Read the contract named in a task before doing it.

**Conventions** (CLAUDE.md):

- No `class_name`; use `const X = preload(...)`.
- Indent with tabs.
- `##` comments cite `specs/019` and the research item (for example `research R6`).
- Every animated state has a reduced-motion form.
- Run the narrowest test tier after each task (quickstart §3). Script errors fail a run.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1–US6 from spec.md

---

## Phase 1: Setup

**Purpose**: fonts in place and verified before any token points at them (research R3).

- [X] T001 Download the full upstream fonts (SIL OFL) into the session scratchpad, not the repo: `Fraunces[SOFT,WONK,opsz,wght].ttf` from github.com/google/fonts `ofl/fraunces/`, `AlegreyaSans-ExtraBold.ttf` from `ofl/alegreyasans/`, and both `OFL.txt` files. Copy `scratchpad/fontinfo.py` and `scratchpad/cover.py` from the planning session if they exist; otherwise rewrite them as research R3 describes. They report axes, GSUB features, digit advances and which game characters (from `data/*.json`, `ui/**/*.gd`, `engine/*.gd`) are missing. Run them with `uv run -q --no-project --with fonttools --with brotli python -I <script> <fonts>` and record the result. Fraunces must have axes `opsz`, `wght`, `SOFT` and `WONK`; record whether it has `tnum`. No game character may be missing.
- [X] T002 Add the verified fonts to `art/fonts/`: `Fraunces.ttf` (renamed from the bracketed name), `AlegreyaSans-ExtraBold.ttf`, `OFL-Fraunces.txt`. Keep `AlegreyaSans-Medium.ttf`, `AlegreyaSans-Bold.ttf` and `OFL-AlegreyaSans.txt`. Run `godot --headless --path . --import` and confirm `.import` files appear. Do **not** delete Cinzel yet (T041).

---

## Phase 2: Foundational (blocks every story)

**Purpose**: the new tokens and type styles exist, the old names still compile as aliases,
and the token and contrast tests guard them.

- [X] T003 Write `tests/test_design_tokens.gd` (extends `res://tests/base.gd`). It parses `res://specs/019-unified-design-system/design-system/tokens.json` and asserts:
  - every colour token equals the `T.<UPPER_SNAKE>` constant (`stone-raised` → `STONE_RAISED`; `scrim` parsed from `rgba(...)`);
  - every spacing, chamfer, radius-plate, border-width and size token equals `round(px × 1.85)` in `T` (names per contracts/tokens.md: `SPACE_1..6`, `CHAMFER_SM/MD/LG`, `RADIUS_PLATE`, `BORDER_ETCH/EDGE/SELECT`, `TOPBAR_H`, `ACTION_H`);
  - `T.CARD_RADIUS_SHARE == 0.08`, `T.REGION_WASH == 0.22`, `T.OUT_OF_PLAY == 0.45`;
  - every type style in `type.groups` has a `T` style with that family, size `round(px × 1.85)`, weight, `opsz` and letter spacing, and `upper` true for banner, card-name and label only;
  - every style's size is `>= T.TEXT_MIN` except `CARD_NAME` (`>= T.CARD_NAME_MIN`).

  Leave the "no old token remains" assertion for T074. It should fail until T004.
- [X] T004 Rewrite `ui/theme/tokens.gd` per contracts/tokens.md.
  - Add every colour (`GROUND` … `STAT_PLATE`, `SCRIM`) with `##` notes from the token's usage.
  - Add `ETHER = {"water": {"base": Color("3566b0"), "bright": Color("5a8bdb")}, "lightning": {c9902c, e8b245}, "shadow": {7350b0, 9576dd}, "fire": {b93a2e, de5a44}}`; `REGION = {1: 5f8a6e, 2: 4d8080, 3: b5633a, 4: 3f6b4a}`; `REGION_LAIR = 8a3b3a`.
  - Add `SPACE_1..6` (7, 15, 22, 30, 44, 59), `CHAMFER_SM/MD/LG` (11, 18, 30), `CARD_RADIUS_SHARE` 0.08, `RADIUS_PLATE` 7, `BORDER_ETCH/EDGE/SELECT` (2, 4, 6), `TOPBAR_H` 74, `ACTION_H` 89, `CHIP_H` 52, `COACH_MAX_W` 629, `DIALOG_W` 666, `CARD_NAME_MIN` 20, `REGION_WASH`, `OUT_OF_PLAY`, `PRESS` 0.08, `RELEASE` 0.12, `PRESS_DROP` 4, and the shadow tokens as dictionaries of their parts, named `SHADOW_SLAB`, `SHADOW_SLAB_PRESSED`, `SHADOW_BRASS`, `SHADOW_WELL`, `SHADOW_CARD` and `SHADOW_LIFT` (the old `CARD_SHADOW` list stays until T046; analysis I1).
  - Add the 12 type styles as dictionaries `{family, size, weight, opsz, spacing, upper}` per contracts/type-styles.md.
  - Keep `TEXT_MIN` 22, `TAP_MIN` 88 and every layout, motion and creature token unchanged.
  - Keep the old names as a clearly marked `# --- Migration aliases (specs/019, removed in T074) ---` block:
    - Colours: `BG_BASE=GROUND`, `BG_SURFACE=STONE`, `BG_RAISED=STONE_RAISED`, `BG_BAND=STAT_PLATE`, `LINE_SOFT=EDGE`, `INK=PARCHMENT`, `INK_MUTED=PARCHMENT_MUTED`, `GOLD=BRASS_BRIGHT`, `GOLD_FACE=BRASS`, `FOCUS=BRASS`, `GOOD=JADE`, `CAUTION=BRASS`, `BAD=DANGER`, `HP=STAT_HP`, `BRONZE=CARD_RIBBON`; `BRONZE_DARK`/`BRONZE_LIGHT` derived from it.
    - Type: `H1=TITLE`, `SUBHEAD=HEADING`, `EYEBROW=LABEL_CAPS`, `LABEL_BOLD=LABEL_CAPS`, `NUMERAL_S=NUMERAL_SM`, `NUMERAL_L=NUMERAL_XL`, `LABEL=BODY_SM` (the old small text). The design system's uppercase label is named `LABEL_CAPS` until T074 renames it. `HEADING`, `BODY`, `BUTTON` and `NUMERAL` keep their names with new values. The old `TITLE` (64, only `stage_banner.gd`) and the new `TITLE` style share a name, so change `stage_banner.gd`'s use to `T.BANNER` in this task; `T.TITLE` then means the new style.
    - Space: `XS=SPACE_1`, `S=SPACE_2`, `M=SPACE_4`, `L=SPACE_5`, `XL=SPACE_6`, `RADIUS_S=RADIUS_PLATE`, `RADIUS_M=CHAMFER_MD`, `CHAMFER_S/M/L`.
  - Make `ether()` return the base colour and `ether_shade()` take the roles of research R11 (`lit` = bright, `pill` = bright, `pill_ink` = `STAT_PLATE` or `ON_BRASS` on lightning).
  - Delete `ACCENT_MUTE`, and make `muted(c)` return `c` unchanged until T030 removes its callers.
  - Make `test_design_tokens` pass: `tools/test.sh unit design_tokens`.
- [X] T005 Rebuild fonts in `ui/theme/theme.gd` `font()` (:16-31) as `font(style) -> Font`: one cached `FontVariation` per style dictionary.
  - Display: `art/fonts/Fraunces.ttf`, with `variation_opentype` setting `wght`, `opsz`, `SOFT`=50 and `WONK`=0 by `TextServer.name_to_tag`, `spacing_glyph` from `spacing × size`, and `tnum`/`lnum` features when T001 found them.
  - Sans: `AlegreyaSans-Medium` for 500, `-Bold` for 700 and `-ExtraBold` for 800, with `lnum` and `tnum`.
  - Keep accepting the legacy string names (`display`, `display_bold`, `numeral`, `body`, `body_medium`, `body_bold`), mapped to `HEADING`, `TITLE`, `NUMERAL`, `BODY`, `BODY`, `BUTTON`, until T074.
  - Update `label()`, `style_label()` and `build_theme()` (:85) to take style dictionaries: size from the style, uppercase when `upper`, colour default `T.PARCHMENT`.
  - Update every `[font, size]` destructuring in `ui/` (grep `[0]]` and `[1]]` on type tokens: `preview_panel.gd:28` `VERDICT`, `rulebook_overlay.gd:26`, `xp_purse.gd:92-95`, `soak_meter.gd:69-72`, `stat_chip.gd:76`, `trashed_back.gd:42`) to `UI.font(style)` and `style.size`.
  - Run `tools/test.sh unit` and `tools/test.sh ui screens`.
- [X] T006 [P] Make `ui/theme/numerals.gd` (:16) use `UI.font(T.NUMERAL)`, with the weight following the style it is asked to draw. If T001 found no `tnum` in Fraunces, add tabular layout: each digit on the advance of the widest digit, centred in that cell (research R3 fallback), used by `draw`, `draw_left` and `width`. Run `tools/test.sh unit stat_chip card_face_layout`. **Done as**: the full Fraunces has no `tnum` either, so `tools/make_figures.py` cuts static instances for the three numeral styles (`art/fonts/FrauncesFigures-<weight>-<opsz>.ttf`, 71 KB each) with every digit the widest digit's width, and `UI.font` loads them for the numeral styles; Labels and `numerals.gd` both get tabular figures that way.
- [X] T007 [P] Delete `tests/test_stone_contrast.gd` (it checks the old ground images against the old surface colour), and rewrite `tests/test_card_contrast.gd` against the new card tokens: `PARCHMENT` on `CARD_FRAME`, `CARD_RIBBON` and `STAT_PLATE` ≥ 4.5; `BRASS_BRIGHT` on `CARD_RIBBON` ≥ 4.5; `PARCHMENT_MUTED` on `STAT_PLATE` ≥ 4.5; remove the `BRONZE` assertions. Then write `tests/test_palette_contrast.gd`. Using `UI.contrast`, assert:
  - ≥ 4.5: `PARCHMENT` and `PARCHMENT_MUTED` on `GROUND`, `STONE`, `STONE_RAISED` and `WELL`; `BRASS` and `BRASS_BRIGHT` on `GROUND`, `STONE` and `STONE_RAISED`; `JADE` and `DANGER` on `GROUND`, `STONE` and `STONE_RAISED`; `ON_BRASS` on `BRASS`, `BRASS_BRIGHT`, ochre base and ochre bright; `PAPER_INK` and `PAPER_MUTED` on `PAPER`; for each Ether, `ether_shade(e, "plate_ink")` on `plate` and `ether_shade(e, "pill_ink")` on `pill`.
  - ≥ 3.0: `EDGE` on `STONE` and `GROUND`; `STAT_HP` on `STONE`; `BRASS_DEEP` on `PAPER`; `ether_shade(e, "lit")` on `STONE`.
  - `< 4.5`: `PARCHMENT_FAINT` on `STONE`, documenting that it is disabled-only.

  Expected values are in research R4. Run `tools/test.sh unit palette_contrast card_contrast`.
- [X] T008 [P] Write `tests/test_fonts.gd`.
  - Load `art/fonts/Fraunces.ttf` and the Alegreya files as `FontFile`. For every non-ASCII character in `data/*.json` and in `ui/**/*.gd` string literals (read with `FileAccess`), assert `has_char`.
  - Assert the `NUMERAL` style's digits 0–9 draw with equal advances, through `Numerals.width` per digit.
  - Leave the "no Cinzel" assertion for T041.

**Checkpoint**: the game runs in the new palette and faces through the aliases. All unit
tests pass. The quick UI suite may show layout overflows, which US1–US6 fix.

---

## Phase 3: User Story 1 — The painted art is the colour (P1) 🎯 MVP

**Goal**: one slate ground, stone panels, parchment text, a Region wash, no patterned stone.

**Independent Test**: open every screen at the smallest and largest window sizes. Grounds,
panels, buttons and text use only the new palette. The play screen shows the Region's tint
behind the card, changing per Region and to the lair in the finale. The menu has no Ground
row.

- [X] T009 [US1] Rewrite `ui/fx/shaders/backdrop.gdshader` per contracts/materials-and-ground.md "Ground and the Region wash".
  - Uniforms: `ground` (vec4), `wash` (vec4), `wash_amount` (float), `wash_centre` (vec2, pixels), `wash_radius` (float, pixels), `view_size`.
  - Output `ground.rgb + wash.rgb * wash_amount * (1.0 - smoothstep(0.0, wash_radius, distance(FRAGCOORD.xy, wash_centre)))`, alpha 1.
  - Remove `grain`, `stone_amount`, `ether_tint`, `tint_amount` and the hard-coded `base`/`glow` vec4s.
- [X] T010 [US1] Rewrite `ui/fx/backdrop_layer.gd`. `setup()` sets `ground` from `T.GROUND`. Add `set_region(stage, centre: Vector2)`:
  - `stage == null` (or empty) → `wash_amount` 0.
  - `stage.kind == "region"` → `T.REGION[stage.region]`.
  - `stage.kind == "final"` → `T.REGION_LAIR`.
  - Radius `0.6 × view height`.
  - Tween `wash` and `wash_amount` over `T.MOVE`, or set them at once when `UI.reduced_motion`.

  Remove `refresh_ground` and `set_stone`.
- [X] T011 [US1] In `ui/main.gd`:
  - Replace `_tint_backdrop` (:1154-1169, called at :680 and :1101) with `backdrop_layer.set_region(vs.stage, centre)`. Take `centre` as the global centre of the play screen's left-column card rect (the Region Card or Encounter face; expose it from `ui/screens/play_screen.gd` as `wash_centre()`).
  - Call `set_region(null, …)` when leaving the play screen (title, setup, records, ending).
  - Remove the `set_stone` call (:318) and the `{"type": "ground"}` handling (:780-781).
- [X] T012 [P] [US1] Update `tools/field_bench.gd` (:30-37) to the new backdrop uniforms (ground plus a wash at Region 1).
- [X] T013 [US1] Remove the ground choice (FR-006a).
  - `ui/model/settings.gd`: delete `GROUNDS` (:24) and `ground` (:27), its load at :55-56 (leave the `display/ground` key unread, so it is ignored), its save (:76) and its reset (:92).
  - `ui/overlays/menu_overlay.gd`: delete `GROUND_NAMES` (:15), the Ground tile row (:61-68), `_set_ground` (:149-154), `_swatch` (:157-168), `_ground_tiles` and the refresh at :174-175.
- [X] T014 [US1] Delete `ui/theme/stone.gd` and its `.uid`, `art/stone/` (all `ground-*.png` and `.import`), and `tools/make_ground.gd` (`tests/test_stone_contrast.gd` went in T007). Delete `STONE_L_MIN`/`STONE_L_MAX` from `ui/theme/tokens.gd`, and the unused `Stone` preloads (`ui/theme/stone_style.gd:9` and any others: `grep -rn "theme/stone.gd" ui tools tests`).
- [X] T015 [P] [US1] Add to `tests/test_settings_window.gd` (or a new `tests/test_settings.gd`): write a config file with `display/ground = 3` to a test path, load it through `Settings`, and assert there is no error and no `ground` property (`not "ground" in Settings`). **Done in** `tests/test_settings.gd` (own test path, so the player's settings are untouched).
- [X] T016 [US1] Repaint the remaining grounds and panel fills on stone through the aliases (no brass decisions yet).
  - `UI.panel()` and `stone_slab`/`slab` faces → `T.STONE`.
  - `style_stone_button` stone face → `T.STONE_RAISED`.
  - The `well` kind, `stone_zone`, the Hand well (`ui/screens/play_screen.gd:50`) and the meter tracks (`soak_meter.gd:64`, `xp_purse.gd:87`) → `T.WELL`.
  - Dividers: `rulebook_overlay.gd:255,416`, `ending_screen.gd:117`, `dragon_screen.gd:111` → `T.LINE`.
  - Dims and scrims: `overlay.gd:29`, `coach_mark.gd:177`, `region_panel.gd:347`, `T.COACH_DIM` → `T.SCRIM` (`COACH_DIM` becomes the `SCRIM` alpha).
  - Carved-label colours (`theme.gd:393-398`, `header_bar.gd:42-45`).
- [X] T017 [US1] Add to `tools/ui_check.gd`'s `screens` walk: open the menu and assert no Control has text "Ground". In the `play` walk, assert the backdrop material's `wash_amount > 0` on the play screen, its `wash` equals `T.REGION[vs.stage.region]` in a Region and `T.REGION_LAIR` in the finale, and it is 0 on the title screen.
- [X] T018 [US1] Run `tools/test.sh unit settings palette_contrast design_tokens` and `tools/test.sh ui screens play`, then `tools/test.sh ui full screens`. Fix any overflow from the larger spacing by stepping that gap down one `SPACE_*` rung, with a `## specs/019 R2:` note. **Done**: gaps stepped down a rung in the rulebook, records, table note and preview panel; the layout solver keeps its own gutter (`LAYOUT_GUTTER`/`LAYOUT_GAP`); the rulebook gives its text 62–70% of the width by what its aside holds, and two pages were rebalanced (a sentence moved, Upgrade and Cleanup split); the History shows as many rows as fit; the action row's narrow cells set their words at 26; `COACH_MAX_W` stays 560, within the system's 629 maximum. Quick UI check and the full-matrix screens walk pass.

**Checkpoint**: US1 is visible on every screen and the menu has no Ground row.

---

## Phase 4: User Story 2 — Brass means "here" (P1)

**Goal**: brass only on the primary action, the selected thing and the one target slot;
bright brass only on rewards and headlines; jade focus.

**Independent Test**: play a turn through the screens. At each step at most one button is
brass and at most one slot is the brass target; the UI check's new checks pass in every
walk.

- [X] T019 [US2] Write the UI check first (it fails until T020–T029). In `tools/ui_check.gd`:
  - `_inspect_screen` (:741-790): count visible Controls with `get_meta("primary", false)` and `_ok(count <= 1, "%s: one primary button, found %d")`.
  - `_settle()` (:363-374): count places whose state is `"target"` in `ui.play` place labels and `_ok(count <= 1, …)`.
- [X] T020 [US2] Update `tests/test_place_labels.gd` (:67-79) and `tests/test_view_state.gd` to the place states of data-model.md ("Place state": `empty/open/target/filled/inactive`, "**exactly one at a time**: the keyboard aim, else the place under the pointer while holding, else `next_role`"). Cover:
  - holding a card gives `open` on the others and `target` only on the aimed one;
  - with nothing held, `target` is on `vs.next_role`;
  - on touch, a card that is held but not being dragged leaves `target` on `vs.next_role` (nothing hovers); while it is dragged, `target` follows the place under the finger;
  - given-up places are `inactive`.
- [X] T021 [US2] Implement the place states in `ui/model/view_state.gd` `places()` (:570-635), using `vs.key_target` (:91), a new `draft.hover_role` (set by `ui/widgets/hand_tray.gd` on mouse motion while holding and on touch drag; cleared when the pointer leaves the places or a touch drag ends; add it to `ui/model/turn_draft.gd`) and `vs.next_role` (:110). Make T020 pass: `tools/test.sh unit place_labels view_state turn_draft emphasis`. **Done as**: the pointer aims through the keyboard's aim (`_key_target`) with a light `aim` intent that redraws only the places (`play.reaim`), so nothing in the Hand moves under a drag; with a card held and nothing aimed, every other place is `open` and none is the target (`next_role` is empty while holding).
- [X] T022 [US2] Redraw the place headers in `ui/widgets/place_labels.gd` (:85-149):
  - `empty` → `PARCHMENT_MUTED`; `open` and `filled` → `PARCHMENT`; `target` → `BRASS` with a `BORDER_EDGE` `BRASS` underline; `inactive` → `PARCHMENT_FAINT`.
  - Remove the square fill and stroke boxes and the 3-unit GOLD keyboard stroke.
  - The Set 1 / Set 2 divider (:71-76) → `T.LINE` hairline.
- [X] T023 [US2] Redraw the empty places in `ui/widgets/hand_tray.gd` `_Outline` (:326-372) as wells: `StoneStyle("well")`, `CHAMFER_SM`, a `LINE` rim, and a `BORDER_SELECT` `BRASS` rim plus the place's name in `LABEL` `BRASS` inside when `target`. Remove the `T.muted(T.FOCUS)` rim on resting slots (:366) and the 0.14 fill. Remove the breathing FOCUS glow on the Hand well in `ui/screens/play_screen.gd` (:166-189).
- [X] T024 [US2] In `ui/theme/theme.gd`:
  - `button()` (:248) sets meta `primary = true` for kind `"primary"`.
  - `style_stone_button` (:351-388): primary face `T.BRASS`, ink `T.ON_BRASS`; remove the `active` kind (gold glow) and the `warning` kind; focus becomes a `StoneStyle`-shaped `BORDER_SELECT` `T.JADE` rim (no longer the rounded `box()` ring at :380).
  - Delete the dead `style_button` (:266) and `raised_panel_box` (:230).
  - `flash()` (:432) defaults to `T.PARCHMENT`.
  - `icon_ink()` (:139) returns `T.PARCHMENT` for non-Ether icons.
  - `tooltip_box()` (:97) rim → `T.EDGE` (paper comes in US4).
  - `stone_slab`/`slab` (:327/:337) default edge → `T.EDGE`.

  Grep and fix the callers of `"active"` and `"warning"`: rulebook contents (`rulebook_overlay.gd:233`) uses `"stone"` with meta `selected` (made into tabs in T064), and `confirm_dialog.gd` is handled in T027.
- [X] T025 [US2] Remove the extra gold buttons.
  - `ui/widgets/boost_aim.gd` (:86-94): build the Attack/Initiative pair per Action Set as a one-of-two choice. Until T056 and T064 make the tab row, use `UI.button(..., "stone")` with a `BORDER_SELECT` `BRASS` rim on the chosen one, not `"primary"`. The Journey's fixed Move is a disabled stone button.
  - `ui/widgets/action_bar.gd`: remove the FOCUS glow while ready (`_glow`, :148-152) and the `flash` when enabled (:110). Keep the primary as the only brass.
  - Check that `tests/test_view_state.gd:239,655` still holds (`prompt.primary.kind == "primary"`).
- [X] T026 [US2] Apply the "selected" role (contracts/brass-and-states.md) as a `BORDER_SELECT` `T.BRASS` rim, never a glow: Also: a card placed in a set has no ring (its header names it); only the card picked up is brass.
  - `ui/widgets/choice_tile.gd` (:10-20, :64-81; focus → `JADE`);
  - `ui/widgets/dragon_pick.gd` (:27, :141-154; chosen ring `BRASS` instead of the Ether ring and glow, focus `JADE`);
  - `ui/widgets/card_view.gd` (:409-420; assigned or selected outline `BRASS` without `T.muted`);
  - `ui/overlays/inspect_overlay.gd` (:37 title → `PARCHMENT`, :189 current frame `BRASS`);
  - `ui/overlays/menu_overlay.gd` (:63);
  - `ui/screens/records_screen.gd` (:131);
  - `ui/overlays/confirm_dialog.gd` (:34-35 checkbox fill `BRASS`, check `ON_BRASS`);
  - `ui/widgets/dragon_face.gd` (:85-86 reached MP rungs → `PARCHMENT` fill and `ON_BRASS`-free ink `STAT_PLATE`, since progress is not a selection).
- [X] T027 [US2] In `ui/overlays/confirm_dialog.gd` (:40-43), the answer button becomes `"primary"` (brass), on the right; Cancel stays stone on the left. A caller may pass `danger_icon` (used by Abandon run, `main.gd:803`, and Clear records, `main.gd:760`), shown as a `DANGER` icon on the answer. The slab edge (:11) → `EDGE`. **Done** together with T061's `title`, `danger_icon` and `paper` parameters; callers pass them in T061.
- [X] T028 [US2] Rewards to `T.BRASS_BRIGHT`, everything else off gold (contracts/brass-and-states.md "Role mapping").
  - Keep `BRASS_BRIGHT`:
    - `ending_screen.gd`: :80, 83, 111, 121, 128, 163.
    - `records_screen.gd`: :150, 154, 204, 241.
    - `xp_purse.gd`: :66, 69, 90.
    - `region_panel.gd:111`, `encounter_face.gd:102` (XP chips).
    - `preview_panel.gd:336`.
    - `animator.gd`: :321, 441.
    - `card_view.gd:465`.
  - Change to `EDGE`:
    - `xp_purse.gd:23` zone edge.
    - `ending_screen.gd:45` slab edge.
    - `rulebook_overlay.gd:370` callout border.
    - `title_screen.gd:71` lintel edge.
    - `dragon_card.gd:238`, `region_card.gd:173` band edges.
    - Ornaments: `place_labels.gd:74,76`, `rules_screen.gd:78`, `overlay.gd:96`, `title_screen.gd:52`.
  - `table_note.gd:228` "gold" accent and its emblem, foot rule and diamond (:408-425): `EDGE` rule, `PARCHMENT` emblem; keep `BRASS_BRIGHT` only on an upgrade note's XP figure.
  - Headings and eyebrows → `PARCHMENT_MUTED` (styled `LABEL_CAPS`) or `PARCHMENT`:
    - `glossary_popover.gd:68`, `menu_overlay.gd:44`.
    - `rulebook_overlay.gd`: :169, 362, 434.
    - `rules_screen.gd:62,109`, `inspect_overlay.gd:88`.
    - `dragon_face.gd:139,148`.
    - `preview_panel.gd:566`, `records_screen.gd:287`.
    - `table_note.gd:104`, `dragon_card.gd:253`, `region_card.gd:192`, `card_detail.gd:64`.
  - Icon tints → `PARCHMENT`:
    - `rulebook.gd:401` (non-Ether), `glossary_popover.gd:67`, `size_notice.gd:16`.
    - `rulebook_overlay.gd:165`, `rules_screen.gd:61`, `dragon_card.gd:265`, `card_detail.gd:61`.
    - `rulebook_figure.gd:55,57`, `card_view.gd:467,480`, `place_labels.gd:115`.
    - `ether_picker.gd:54`, `card_face.gd:258`.
  - Hover → `PARCHMENT` (`header_bar.gd:91,112,162`, `overlay.gd:72`).
  - Other uses:
    - `soak_meter.gd:67` fill → `PARCHMENT_MUTED`, and `JADE` when full.
    - `card_face.gd:478` affordable cost → `PARCHMENT`.
    - `preview_panel.gd:505` → `PARCHMENT`.
    - `card_view.gd:130`, `inspect_overlay.gd:54` upgrade ring → `PARCHMENT`.
    - `card_view.gd:423` dashed outline → `PARCHMENT_MUTED`.
    - `animator.gd:291` ghost → `PARCHMENT`.
    - `creature.gd:255-256` embers stay as art: use the fire Ether bright.
  - Banner callers in `ui/main.gd` (:1202-1211) pass the Region tint as the colour (`T.REGION[n]`, or `T.REGION_LAIR` for final stages) instead of `T.GOLD` or the dragon's Ether.
- [X] T029 [US2] Step emphasis to parchment (research R6). In `ui/widgets/card_face.gd`:
  - :423 pip ring, :557 plate lerp target, :611-612 `_glow_rim`, :94 wash behind a ringed Encounter, and :45/:73 defaults → `T.PARCHMENT`, with no glow layers (draw a single `BORDER_SELECT` ring).
  - `region_card.gd:114` panel rim → `T.PARCHMENT`.
  - `stone_style.gd:31` default `glow_colour` → `T.PARCHMENT`.
  - In `ui/main.gd` (:1188-1196), resolve the board-response colour roles: `focus` → `PARCHMENT`, `gold` → `BRASS_BRIGHT`, `bad` → `DANGER`, `ether` → `ether_shade(e, "lit")`, `neutral` → `EDGE`. Delete `RESPONSE_NEUTRAL` from tokens.
  - The coach mark's rim (`coach_mark.gd:346`) stays `BRASS`: it is the target.
- [X] T030 [US2] Remove every `T.muted(` call (`grep -rn "T.muted(" ui`; for example `face_frame.gd:111` → `T.ether(e)` as-is, `card_view.gd:410`) and delete `muted()` from `ui/theme/tokens.gd`.
- [X] T031 [US2] Signals always carry a sign or icon (FR-009): The unaffordable cost sits on its own `STAT_PLATE` plate in `DANGER` (danger on the ribbon is 2.5:1) rather than taking a minus sign, which would read as a negative cost.
  - `preview_panel.gd:261`: the verdict icon before the total.
  - `preview_panel.gd:554`: the narrow-victory icon with the target sum, in `PARCHMENT` (CAUTION is gone).
  - `card_view.gd:130` and `inspect_overlay.gd:48`: the downgrade ring gets a down-arrow icon.
  - `card_face.gd:481`: the unaffordable cost is drawn with a leading "−".
  - The inspect column titles (`inspect_overlay.gd:46/52`) get the up and down arrows.

  Remove the `CAUTION` alias, and change the `VERDICT` table's `narrow` colour to `T.BRASS`.
- [X] T032 [US2] Run `tools/test.sh unit` and `tools/test.sh ui play arrange divert lessons screens`. The new primary and target checks pass in every walk.

**Checkpoint**: US1 + US2 are the P1 MVP: the palette, the wash and brass meaning "here".

---

## Phase 5: User Story 3 — Easier type: Fraunces replaces Cinzel (P2)

**Goal**: every display string in Fraunces, title case where the role says so; tabular
figures; card names and drawn text at their floors.

**Independent Test**: no text uses Cinzel; titles and headings are title case; the top bar
reads "Jade Mountains · Region 1"; `test_fonts` and `test_card_face_layout` pass; no live
text is below `TEXT_MIN` except card names.

- [X] T033 [US3] Apply the type styles across `ui/` per contracts/type-styles.md "Replaces":
  - `T.BANNER` stays on the game's name (`title_screen.gd`) and the verdict (`ending_screen.gd`); `stage_banner.gd` moved to it in T004.
  - `T.H1` → `T.TITLE` (`size_notice.gd`).
  - `T.SUBHEAD` → `T.HEADING`.
  - `T.EYEBROW` and `T.LABEL_BOLD` → `T.LABEL_CAPS`.
  - `T.LABEL` → `T.BODY_SM`, except hints and fine print → `T.CAPTION` (help tips, coach footer, "Hold a card…" lines).
  - `T.NUMERAL_S` → `T.NUMERAL_SM`, `T.NUMERAL_L` → `T.NUMERAL_XL`.

  File counts are in the checks survey (research R9). Delete `NUMERAL_M`. Run `tools/test.sh ui screens`.
- [X] T034 [US3] Remove `.to_upper()` where the style now uppercases, and remove it from titles and headings, which become title case (FR-013):
  - `card_face.gd:426`, `region_card.gd:182`, `dragon_card.gd:243,250`, `encounter_face.gd:62`.
  - `card_detail.gd:43`, `deck_stack.gd:656`.
  - `table_note.gd:187,217,223`, `xp_purse.gd:54`, `preview_panel.gd:566`.
  - `rules_screen.gd:109`, `records_screen.gd:287`, `ending_screen.gd:46`, `stage_banner.gd:33-34`.
  - `rulebook_overlay.gd:73`, `rulebook_figure.gd:106`, `dragon_face.gd:113`, `inspect_overlay.gd:88`.
  - `theme.gd:126`, `place_labels.gd:108`.

  For each, decide by its style: `LABEL_CAPS`, `BANNER` and `CARD_NAME` keep capitals (applied by the style); `TITLE` and `HEADING` show the source string. Fix source strings that are all lower case or ALL CAPS into title case.
- [X] T035 [US3] Top bar heading. In `ui/model/view_state.gd` (:449-458), set `stage.heading` to `"%s · Region %d"` (name, number) and the finale to `"%s, %s · Final Battle"`, and add `stage.heading_parts = [main, muted]`. In `ui/widgets/header_bar.gd` (:39-46, :148), draw the heading in `T.TITLE` as two runs: main in `PARCHMENT`, `· Region n` in `PARCHMENT_MUTED` (an HBox of two labels, or a RichTextLabel with `normal_font_size >= TEXT_MIN`). Remove the carved shadow and outline. Update `tests/test_view_state.gd` for the new heading.
- [X] T036 [US3] Card names in Fraunces. In `ui/widgets/card_face.gd`: **Done as** (owner, 2026-10-22): the Ether glyph stays beside the name, clear of the Level on the crown, so names have a floor of their own, `CARD_NAME_SHARE` of the card's width (18 on the narrowest phone's 220-wide card), one step under `CARD_NAME_MIN`. Names are sized so two lines fill the band.
  - Delete `_name_font` (:853-861) and use `UI.font(T.CARD_NAME)` with its letter spacing.
  - Re-measure `LONGEST_LINE` over all card names in `data/cards.json` (uppercased, split as `name_lines` :820-837 does) and set it to the widest in Fraunces.
  - Raise the floor in `name_size` (:840-844) from 6 to `T.CARD_NAME_MIN × card_scale`, where `card_scale` is the card's on-screen size over its 1280×720 design size. If a name cannot fit at the floor, wrap to two lines first (it already does), and give the band the full card width with no inline glyph circle (MageCard README).
- [X] T037 [US3] Update `tests/test_card_face_layout.gd`: `test_longest_line_is_the_widest…` (:94-103) against Fraunces; `test_names_are_legible_on_a_long_phone` (:106-118) asserts `>= T.CARD_NAME_MIN` scaled to the 220×308 card; the numeral tests still hold. Run `tools/test.sh unit card_face_layout stat_chip`.
- [X] T038 [US3] Give drawn text a style and a floor (research R9). Each `draw_string` gets its size from a type style, clamped at `T.TEXT_MIN` (card names `T.CARD_NAME_MIN`), and sets meta `drawn_text_min` to the smallest size it drew: **Done as**: `UI.drew_text(owner, site, size, least)` records each site's latest size; drawn text on cards and chips is clamped at `TEXT_MIN`.
  - `xp_purse.gd:94-95`, `soak_meter.gd:71-72`.
  - `region_card.gd:183,190`.
  - `dragon_card.gd:244,251,259`.
  - `stat_chip.gd:81`, `trashed_back.gd:43`.
  - `region_panel.gd:349`.
  - `card_view.gd:489,520`.
  - `dragon_face.gd:19` (`NAME_MIN` → `T.CARD_NAME_MIN`), `:205-237`.
  - `table_note.gd:243-248`.
- [X] T039 [US3] In `tools/ui_check.gd` `_inspect_screen` (:778-787): Also: the label colour check (SC-002) and the focus check (G2); a control that draws its own focus ring sets meta `draws_focus`.
  - Check `drawn_text_min >= T.TEXT_MIN` on any Control that has the meta, except Controls with meta `card_name`, which use `T.CARD_NAME_MIN`.
  - Add a font check: each Label's `get_theme_font("font")` resolves (through `FontVariation.base_font`) to `Fraunces.ttf` or an `AlegreyaSans-*.ttf`.
  - Add a colour check (SC-002, analysis C1): each visible Label's `font_color` (and each RichTextLabel's `default_color`) is one of the text tokens proven in `test_palette_contrast` (`PARCHMENT`, `PARCHMENT_MUTED`, `PARCHMENT_FAINT` only when the Label's button is disabled, `BRASS`, `BRASS_BRIGHT`, `JADE`, `DANGER`, `ON_BRASS`, `PAPER_INK`, `PAPER_MUTED`, or an `ether_shade(e, "lit")`), compared ignoring alpha.
  - Add a focus check (FR-019, analysis G2): whenever the `arrange` walk or a screen walk gives a control keyboard focus, its `focus` style draws a `T.JADE` rim `T.BORDER_SELECT` wide.
- [X] T040 [US3] Run `tools/test.sh unit` and `tools/test.sh ui screens marks play deck lessons`, then `tools/test.sh ui full screens` (type sizes grew). Fix overflows by wrapping or by stepping a gap down a rung, never by going below a floor.

- [X] T041 [US3] Delete `art/fonts/Cinzel.ttf`, its `.import`, `art/fonts/OFL-Cinzel.txt` and `art/fonts/AlegreyaSans-Regular.ttf` with its `.import` (confirm no reference: `grep -rn "Cinzel\|AlegreyaSans-Regular" ui tools tests art`). Add the "no Cinzel" assertion to `tests/test_fonts.gd`. Check SC-005: `du -ch art/fonts/*.ttf` against the old total (Cinzel 125 KB + Alegreya 3 × 265 KB); the growth must be under 1 MB. Fonts: 908 KB before, 1.3 MB after (SC-005).
---

## Phase 6: User Story 4 — Carved stone, printed paper (P2)

**Goal**: one material per kind of thing: chamfered stone slabs with bevels, rounded paper
cards with physical shadows, paper reading surfaces; pressed and lifted states.

**Independent Test**: a button, tab, panel, slot, chip, dialog, banner and card at rest,
pressed, selected and disabled match contracts/materials-and-ground.md; coach tips,
glossary, rulebook pages and the unspent-XP question are on paper.

- [X] T042 [US4] Redraw `ui/theme/stone_style.gd` `_draw` (:122-166) per contracts/materials-and-ground.md "Stone". **Done early** (US1 needed the materials). Plinths and wells pad `SPACE_2`, slabs `SPACE_3` (one rung under the contract, so overlays keep fitting); `ring_only` draws the focus rim alone.
  - Drop: `SHADOW_DROP`, 6 units; 2 when pressed; none when disabled or recessed.
  - Face: by kind (`slab`/`lintel` `STONE`; `plinth` `STONE_RAISED` or the `face` override; `well` `WELL` with an inset shadow band 4 units deep at black 0.6 along the top).
  - A `BORDER_ETCH` line of `PARCHMENT` at 0.10 inside the top edge.
  - A 6-unit bottom bevel at black 0.35 (`BRASS_DEEP` when the face is `BRASS`, plus a `#fff4d6`@0.55 top line).
  - The rim: `BORDER_EDGE` `edge` (default `T.EDGE`; `T.LINE` for wells and disabled), or `BORDER_SELECT` when `selected`/`target` (`BRASS`) or `focus` (`JADE`).
  - Chamfer: `well`/tabs `CHAMFER_SM`, `plinth`/panels `CHAMFER_MD`, `slab` trays/dialogs and `lintel` `CHAMFER_LG` (add a `size` property: `"sm"/"md"/"lg"`).
  - Delete the `inset` kind and the glow path (state never glows, FR-018); keep `round_radius` for paper and cards.
  - Content margins become `SPACE_3` (wells and plinths) and `SPACE_4` (slabs).
- [X] T043 [US4] Press motion in `ui/theme/theme.gd` `press_feedback` (:405): on `button_down`, tween `position.y` by `+T.PRESS_DROP` over `T.PRESS` (the pressed style collapses the bevel); on `button_up`, tween back over `T.RELEASE`. When `reduced_motion`, swap the style only, with no travel. Remove the scale-to-0.96. Apply the same to card presses in `card_view.gd:261`, which keep their scale but take `T.PRESS`/`T.RELEASE`. **Done as**: the pressed `StoneStyle` draws the slab and its words `PRESS_DROP` lower (a style swap, so it needs no reduced-motion form and no container fights it); the scale pulse on buttons is gone, cards keep theirs.
- [X] T044 [US4] Add `UI.paper_box()` in `ui/theme/theme.gd` (contracts/materials-and-ground.md "Paper": `PAPER` face, 2-unit rim of `PAPER.darkened(0.15)`, corners `RADIUS_PLATE`, `SHADOW_CARD`) and `UI.paper_label(text, style)` (`PAPER_INK`; `PAPER_MUTED` for secondary). Then:
  - `tooltip_box()` and `wrapped_tooltip`/`entry_content` (:97-137) use paper with paper inks;
  - `help_tip.gd` and `tip_box.gd` follow.
- [X] T045 [US4] Put the reading surfaces on paper. Rulebook figures (drawn for stone) lie on a dark plate set into the page; rulebook and lesson inline icons use `ether_shade(e, "paper")`. The coach bubble's pointer is not drawn (the brass target ring shows what it means).
  - `ui/overlays/coach_mark.gd`: bubble (:67) → `paper_box`, max width `T.COACH_MAX_W`, a small pointer triangle in `PAPER` aimed at the target; text `PAPER_INK`; footer `PAPER_MUTED`.
  - `ui/overlays/glossary_popover.gd` (:28 popover, :60 full view): the entry body on paper inside the slab; glossary terms bold with a `BRASS_DEEP` underline.
  - `ui/overlays/rulebook_overlay.gd` (:150): the page body on paper inside the slab frame; callouts (:370) as `PAPER.darkened(0.06)` boxes; tables (:397-438) in paper inks until T063.
  - The unspent-XP body in `confirm_dialog.gd` on paper when the caller passes `paper = true` (`main.gd:1021-1024`).

  Lines at most 50 characters: cap the paper text width at `T.COACH_MAX_W`.
- [X] T046 [US4] Cards are rounded paper with physical shadows. `UI.draw_card_shadow(canvas, rect, radius, lifted)`.
  - `UI.card_radius(w)` (`theme.gd:178`) returns `w * T.CARD_RADIUS_SHARE`; `card_face.gd:323` and `card_view.gd:406` call it instead of 0.075.
  - Add `UI.card_shadow(canvas_item, rect, radius, lifted)`, which draws `SHADOW_CARD`, or `SHADOW_LIFT` when lifted. It replaces `card_face.gd:326`'s single shadow, `trashed_back.gd:23`, `table_note.gd:390` and `deck_stack.gd:758`.
  - Delete the old `T.CARD_SHADOW` layer list (replaced by `SHADOW_CARD`; no name clash, analysis I1).
  - `face_frame.gd` (:25, :108; base of `encounter_face` and `dragon_face`) becomes a rounded card (`round_radius = card_radius`), not a chamfered well.
  - `region_card.gd:39,155` and `dragon_card.gd:62,69,179` use `card_shadow` (Dragon card keeps no shadow where it lies in a well).
- [X] T047 [US4] Lift and out-of-play. Out of play in the Hand is a given-up Reserve: `vs.cards[id].out_of_play`, drawn wholly grey at `OUT_OF_PLAY`.
  - A held card (`hand_tray.gd:86`, `Solver.HELD_LIFT`), a dragged card and the inspected card (`inspect_overlay.gd:189`) draw `SHADOW_LIFT`; set a `lifted` flag on `card_view.gd`/`card_face.gd`.
  - Truly out-of-play cards (trashed, given up, locked dragon: `trashed_back.gd`, the given-up place, `dragon_card` lock) draw through a greyscale `CanvasItemMaterial`/shader at `modulate.a = T.OUT_OF_PLAY` (add `ui/fx/shaders/greyscale.gdshader`, one line of luminance).
  - Ineligible-this-step keeps `card_face.dimmed` (:97).
  - Reduced motion: lift and out-of-play are still forms already.
- [X] T048 [US4] Update `tests/test_deck_stack.gd` (:53-54) to `card_radius(190) == 15.2` (or its rounded use) and `card_radius(400) == 32`. Run `tools/test.sh unit deck_stack card_face_layout region_card note_pile` and `tools/test.sh ui deck skip look marks lessons screens`.

---

## Phase 7: User Story 5 — Mineral Ethers (P3)

**Goal**: the four Ethers are mineral pigments everywhere; plates carry the figures; the
highlighted pill is the bright partner with dark ink; the glyph is always shown.

**Independent Test**: one card of each Ether at rest and with a highlighted figure matches
the MageCard README; `test_palette_contrast` and `test_card_contrast` pass.

- [X] T049 [US5] Extend `tests/test_card_contrast.gd` (rewritten in T007) with the card-face pairs once T050 lands: each Ether's `plate_ink` on `plate` and `pill_ink` on `pill` as the card face actually draws them ≥ 4.5, and the ribbon's cost and XP inks on `CARD_RIBBON` ≥ 4.5. Covered by `test_highlighted_pills_read_on_every_ether`, `test_enhanced_plate_ink_reads_on_every_ether` and `test_bands_read` (T007).
- [X] T050 [US5] Card face colours in `ui/widgets/card_face.gd`: The highlighted figure on a black plate (Initiative, basic action, Boost) fills with the Ether's `pill` as its highlight rises, its ink turning to `pill_ink` past half.
  - The field shader takes `ether_shade(e, "base"/"deep"/"lit")` (:299-302; the uniforms are unchanged).
  - Plates (:350-382, :552, :559) → `T.STAT_PLATE` with `RADIUS_PLATE` corners.
  - The highlighted or enhanced figure (:361-362) fills with `ether_shade(e, "pill")` and inks with `ether_shade(e, "pill_ink")`.
  - The armor shield (:382) uses `plate`/`plate_ink`.
  - The frame and title band → `T.CARD_FRAME`.
  - The Key Card strip, bronze (:454) → `T.CARD_RIBBON`.
  - `STEEL` (:28) → `T.METAL`.
  - The Ether glyph is always drawn in the title band.
- [X] T051 [US5] Add the stat ribbon to Mage Cards where `card_view.gd` draws cost and XP ribbons (:427-474): `CARD_RIBBON` fill, cost on the left in `PARCHMENT` `NUMERAL_SM`, XP on the right in `BRASS_BRIGHT`. Neutral ribbons and tags (:439, 444, 472, 474) move from `BG_RAISED` → `CARD_RIBBON`, the match ribbon (:453) to `JADE` with its `note_icon` required, and ink to `PARCHMENT` (`ON_BRASS` only on ochre). The card's strip already is the leather ribbon (Key Card left, Upgrade cost right); the role, Reserve and note ribbons are lettered in parchment; a good match is jade with the victory icon.
- [X] T052 [P] [US5] Move every other Ether consumer onto the pigments: Every consumer reads `T.ether`/`ether_shade`, so it took the pigments with T004; the rulebook's raw `ETHER` read was fixed in T005.
  - `face_frame.gd:53-55,111`, `dragon_card.gd:88,96-109,232`, `dragon_face.gd:101,109,121,161-165,353`, `encounter_face.gd:53,56,84-93`, `region_panel.gd:85,99-108,300,316,339`;
  - `dragon_stats.gd:61,129,143-166`, `stat_chip.gd:146`, `soak_meter.gd:53`, `preview_panel.gd:593`;
  - `card_detail.gd:46,55`, `deck_stack.gd:655`, `rulebook_figure.gd:60`, `rulebook.gd:401` (raw `ETHER[e]` → `ether_shade(e, "lit")`);
  - `table_note.gd:267`, `records_screen.gd:131,296`, `dragon_screen.gd:126`, `creature.gd:245,281,296`, `hand_tray.gd:138`.

  Plate fills use `plate`/`plate_ink`, icons and text on stone use `lit`, washes use `base`, and pills use `pill`/`pill_ink`.
- [X] T053 [US5] Redraw `ui/widgets/ether_picker.gd` (:20-54): a slab with an `EDGE` rim; four plinth buttons `TAP_MIN` square, each with the Ether glyph in `ether_shade(lit)` on `STONE_RAISED`, a `BRASS` selected rim and a `JADE` focus rim; the pointer → `PARCHMENT`.
- [X] T054 [US5] Move the remaining colour literals into tokens (research R12): Also `METAL_LIGHT`/`GLASS_LIGHT` for the time chip, `SHADE`/`SHEEN` for neutral alphas; `test_design_tokens` fails on any `Color("…")` outside tokens.gd. Brightness multipliers on `modulate` stay as numbers.
  - `card_face.gd:28` `STEEL` → `T.METAL`;
  - `encounter_face.gd:13,15` and `region_panel.gd:22,24` → `T.METAL`/`T.GLASS`;
  - `dragon_card.gd:27` → `T.GLASS`, `:57` → `T.LOCKED`;
  - `dragon_screen.gd:32` and `dragon_pick.gd:16-17` → `T.DIM_MODULATE`/`T.DIM_HOVER`;
  - `deck_stack.gd:97` → `T.DECK_BACK`.

  Define each in `tokens.gd` with `## Extends the design system (specs/019 R12):` and a value in the slate family (METAL `#8f9a9a`, GLASS `#3a4a4c`, LOCKED `#0a1012`@0.9, DECK_BACK `#101618`@0.88). Also add `SHADE` (`Color(0, 0, 0)`) and `SHEEN` (`Color(1, 1, 1)`) and sweep every `Color(0, 0, 0, a)`/`Color(1, 1, 1, a)` literal in `ui/` (shadows, bevels, hover washes; the survey lists `theme.gd`, `stone_style.gd:132,166`, `card_view.gd:504-538`, `card_face.gd:326,411,540,581,660,676`, `stat_chip.gd:78,87,145`, `table_note.gd:392`, `deck_stack.gd:760`, `region_card.gd:195`, `header_bar.gd:60`, `inspect_overlay.gd:191`, `trashed_back.gd:23`, `dragon_stats.gd:143`, `region_panel.gd:277`) to `Color(T.SHADE, a)`/`Color(T.SHEEN, a)`. Then assert `grep -rn 'Color(' ui --include=*.gd | grep -v tokens.gd` finds only `Color(T.` forms and the over-bright flash modulates (`menu_overlay.gd:167`, `animator.gd:473`, `preview_panel.gd:462`, `creature.gd:281`), each marked `## not a palette colour` (SC-001, analysis I4).
- [X] T055 [US5] Run `tools/test.sh unit card_contrast palette_contrast card_face_layout dragon_stats art creature` and `tools/test.sh ui marks play deck screens`.

---

## Phase 8: User Story 6 — Components everywhere (P3)

**Goal**: each design-system component is built once and used everywhere its kind of thing
appears (contracts/components.md).

**Independent Test**: for each component README, every place the game shows that thing
follows it; the screens walk passes at every size.

- [X] T056 [P] [US6] Create `ui/widgets/tab_row.gd` (contracts/components.md "Tabs"): A `BoxContainer`, so it runs as a row or (`vertical`) a rail.
  - `setup(options: Array[{id, text, icon?}], selected_id)`; emits `chosen(id)`.
  - Each tab is a plinth at `CHAMFER_SM`, `TAP_MIN` high, sized to its label plus `SPACE_4` each side, in `BUTTON` style at `BODY` size in `PARCHMENT_MUTED`.
  - Selected: `STONE` face, `BORDER_SELECT` `BRASS` rim, `PARCHMENT` label. Focus: `JADE`. Exactly one selected.
  - Keyboard: left and right arrows move, Enter chooses.

  Add `tests/test_tab_row.gd` (one selected; choosing emits and moves the rim; at least `TAP_MIN`).
- [X] T057 [P] [US6] Create `ui/widgets/ledger.gd` (contracts/components.md "Ledger"): Read-only rows are 44 (24pt), under the README's 30pt, so a ten-place board fits a phone (plan departure); a pressed row is a full tap target.
  - `setup(columns: [{head, width, align, numeral?}], rows: [{cells, best?, on_press?}])`.
  - Heads in `LABEL_CAPS` `PARCHMENT_MUTED`.
  - Rows in `BODY_SM` with `LINE` 2-unit hairlines, at least 56 units high; a row is a flat button at least `TAP_MIN` high when it has `on_press`.
  - Numeral cells in `NUMERAL` (tabular); "—" and place in `PARCHMENT_MUTED`; the `best` row in `BRASS_BRIGHT`, only one.

  Add `tests/test_ledger.gd`.
- [X] T058 [P] [US6] Add `UI.chip(icon, figure, tone = "plain")` in `ui/theme/theme.gd` (contracts/components.md "Chip"): a well at `CHIP_H`, `CHAMFER_SM`, `LINE` rim, the icon then the figure in `NUMERAL_SM`; `plain` `PARCHMENT`, `reward` `BRASS_BRIGHT`, `harm` `DANGER` with a required sign. It returns a Control; callers wrap it in a `HELP_MIN` hit area when it opens the glossary.
- [X] T059 [US6] Add `UI.panel(heading = "", icon = "", size = "md")` in `ui/theme/theme.gd` (contracts/components.md "Panel"): a slab with the head row (icon `PARCHMENT_MUTED`, `HEADING` `PARCHMENT`, a `LINE` rule) and `SPACE_3`/`SPACE_4` padding. Replace `UI.slab`, `stone_slab`, `stone_zone` and the old `panel()` at every caller: **Done as** `UI.titled_panel(heading, icon, content, size)`: `UI.panel(...)` keeps its old signature (the rulebook's boxes use it), and `UI.slab`/`stone_slab` already draw the Panel's material with no gold rim, so they stay as the slab builders.
  - `menu_overlay.gd:38`, `confirm_dialog.gd:11`, `glossary_popover.gd:60`, `rulebook_overlay.gd:150`, `size_notice.gd:14`;
  - `card_detail.gd:22`, `ether_picker.gd:20`;
  - `rules_screen.gd:55`, `ending_screen.gd:45,105`, `records_screen.gd:281`;
  - `xp_purse.gd:23`, `soak_meter.gd:19` (the edge stays `DANGER` only with its hp icon), `preview_panel.gd:72`;
  - `dragon_screen.gd:186`, `trashed_back.gd:30`.

  Then delete the old helpers. The Action Set tray uses `size = "lg"`.
- [X] T060 [US6] Top bar per contracts/components.md "TopBar", in `ui/widgets/header_bar.gd` (:24-116): The bar is flat `STONE` with a `CARD_FRAME` foot; Menu and Back are stone slabs in the bar over their full tap targets; the pile counts are chips. Their hit areas are `TAP_MIN` wide and only as tall as the bar, since reaching below would cover the Action Set's headers (plan departure; `HELP_MIN` stays for them). The bar's height stays the layout solver's (48 inside the safe area).
  - a `STONE` bar `T.TOPBAR_H` high inside the safe area, with a 4-unit `CARD_FRAME` line under it;
  - the pile counts (:52-79) as `UI.chip` with the pile icons, each in a `TAP_MIN` hit area (as the TopBar README asks: counters' info taps are at least `touch-min`). The hit area may reach past the bar's foot without drawing there; `tools/ui_check.gd` holds these chips to `TAP_MIN`, not `HELP_MIN` (analysis I6);
  - Menu and Back as stone plinth buttons at least `TAP_MIN` square;
  - on menu screens (records, dragon), Back on the left and the title centred.

  Update `ui/model/layout_solver.gd` if the top bar's height token changes its reserved band, and run `tools/test.sh unit layout_solver window_sizer` and `tools/test.sh ui full screens` (CLAUDE.md: layout changes need the full screens walk).
- [X] T061 [US6] Dialog per contracts/components.md "Dialog", in `ui/overlays/confirm_dialog.gd`: add `title` (the question, `TITLE`) and `body` (one sentence, `PARCHMENT_MUTED` `BODY`), `T.DIALOG_W` wide, `SPACE_5` padding, `CHAMFER_LG`, over `SCRIM`. Update the four callers in `ui/main.gd`: Wording kept, split into question and consequence; Clear records carries the trash icon, Abandon run the close icon; the unspent-XP consequence is on paper.
  - :646 "Learn to Play first?" / "A short lesson before your first game."
  - :760 "Clear all records?" / "Your Leaderboard and History are deleted."
  - :803 "Abandon this run?" / "The game ends and is not recorded."
  - :1024 "Spend your XP first?" / "XP does not carry over."

  Keep the existing wording where it already says this (FR-022: change only what does not comply).
- [X] T062 [US6] Banner per contracts/components.md "Banner", in `ui/overlays/stage_banner.gd`: Done with the US2 banner work; the ending's verdict is a lintel rimmed `REGION_LAIR` (victory, bright-brass headline) or `DANGER` (defeat, parchment).
  - a lintel at `CHAMFER_LG` over `SCRIM`, the rim and medallion ring in the passed Region tint;
  - the kicker `LABEL_CAPS` `PARCHMENT_MUTED`, the headline `BANNER` `BRASS_BRIGHT` (or a passed headline colour);
  - it slides in, holds and slides out (replacing the fade-out); under reduced motion it appears and clears in place.

  Add `show_ending(won: bool)` for `ui/screens/ending_screen.gd` (:33-46): victory has a `REGION_LAIR` rim and a `BRASS_BRIGHT` "VICTORY" headline; defeat has a `DANGER` rim and a `PARCHMENT` headline. Replace the ending's carved slab with it. Run `tools/test.sh ui ending screens`.
- [X] T063 [US6] Ledgers: replace the Leaderboard rows (`records_screen.gd:141-175`), the History rows (:232, two-line rows: Ledger with a second-line cell), the ending's score table (`ending_screen.gd:105-128`), rulebook tables (`rulebook_overlay.gd:397-438`, on paper: heads `PAPER_MUTED`, rules `PAPER.darkened(0.15)`) and the dragon table (`dragon_screen.gd:110-194`) with `ledger.gd`. Rank 1 is the only `best` row. Update `tools/ui_check.gd`'s records checks if they find rows by type. Leaderboard on `ledger.gd`; the History, ending score and summary keep their own rows in the ledger's sizes; rulebook tables are on paper (T045).
- [X] T064 [US6] Tabs at every one-of-many choice: Records difficulty rail (vertical tabs, with Other) and dragon filter are tab rows; Boost aim and the rulebook's current section are selected (brass-rimmed) buttons; the menu's Motion and Window rows stay described tiles. A Leaderboard/History tab row was left out: the records screen has no room for another row on the shortest phones, and the menu already switches between them.
  - the records dragon filter (`records_screen.gd:126-138`);
  - a new Leaderboard/History tab row at the top of the records screen (set `_tab`, re-render);
  - Boost aim (`boost_aim.gd`, replacing T025's interim buttons);
  - the rulebook contents' current section (`rulebook_overlay.gd:233`);
  - the menu's Motion and Window rows (`menu_overlay.gd:56-78`).

  - the records screen's difficulty filter (`records_screen.gd:88-109`, today a rail of ChoiceTiles with an "Other" tile): a tab row, since it is a filter.

  ChoiceTile stays only for the setup screen's difficulty grid and the alternate rules, whose tiles carry descriptions (a deliberate departure, contracts/components.md "Tabs").
- [X] T065 [US6] Chips: the preview panel's `_pill` (`preview_panel.gd:575-593`) → `UI.chip` (the XP pill as `reward`, the cost pill as `harm` with its icon). `stat_chip.gd` plates (:87) → `STAT_PLATE` with `RADIUS_PLATE`; its hover → `PARCHMENT` at 0.08.
- [X] T066 [US6] Buttons: give every screen's buttons the `ACTION_H` height in the action row (`action_bar.gd`) and at least `TAP_MIN` elsewhere. Put icons above labels, `SPACE_1` apart. Counts follow a middle dot in `NUMERAL_SM` (Divert · 2). Check each screen's single primary against contracts/components.md "Button". Make `header_bar` and `overlay.gd:54` close buttons stone plinths. Already met: the action row is `TAP_MIN` (88, the system's 89), icons sit above labels, counts follow a middle dot.
- [X] T067 [US6] Motion polish (research R13): in `ui/fx/flight_layer.gd` and `ui/fx/animator.gd`, give the final settle of a card flight `Tween.TRANS_BACK`/`EASE_OUT` over its existing duration; skip it under reduced motion. Confirm the `skip` walk still settles identically: `tools/test.sh ui skip deck play`. Cards moving between places settle with `TRANS_BACK`; a drawn card's flight from the Deck keeps its path (the deck walk checks where it is first seen); banners slide out (T062).
- [X] T068 [US6] Voice pass over every button label, dialog title and dialog body in `ui/` (FR-022): sentence case, verbs or outcomes, capitalised game terms, no exclamation marks or emoji. Change only non-compliant strings and list them in the PR description. No string needed changing: no exclamation marks or emoji; labels are verbs or outcomes; "How to Play" and "Learn to Play" are names.
- [X] T069 [US6] Run `tools/test.sh unit tab_row ledger layout_solver` and `tools/test.sh ui full screens ending lessons`.

---

## Phase 9: Polish & cross-cutting

- [X] T070 [P] Update `README.md`: :52-53 (cards in their Ethers' mineral colours), :136 (`ui/theme/` holds the tokens of `specs/019-unified-design-system/design-system/`), :142 (`art/fonts/` is Fraunces and Alegreya Sans), :156 (credits: Fraunces and Alegreya Sans under OFL; drop Cinzel).
- [X] T071 [P] Update `CLAUDE.md` "Layers and their rules": `ui/theme/tokens.gd` follows `specs/019-unified-design-system/design-system/tokens.json` (enforced by `test_design_tokens`), with brass reserved per `contracts/brass-and-states.md`. Add `design_tokens palette_contrast fonts` to the "Theme, colours" row of the unit-test table (replacing `stone_contrast`).
- [X] T072 [P] Add a one-line note at the top of `specs/001-ui-polish/contracts/design-tokens.md`: "Colour and type values superseded by specs/019-unified-design-system/contracts/tokens.md."
- [X] T073 Grep for leftovers and fix them:
  - `grep -rnE "T\.(BG_BASE|BG_SURFACE|BG_RAISED|BG_BAND|LINE_SOFT|INK|INK_MUTED|GOLD|GOLD_FACE|FOCUS|GOOD|BAD|HP|BRONZE|CAUTION|TITLE|H1|SUBHEAD|EYEBROW|LABEL_BOLD|NUMERAL_S|NUMERAL_L|XS|S|M|L|XL|RADIUS_S|RADIUS_M|RADIUS_CARD|CHAMFER_S|CHAMFER_M|CHAMFER_L)\b" ui tools tests` (careful: the new `TITLE` is a real style; check each hit's intent);
  - `grep -rn 'UI.font("' ui`.
- [X] T074 Delete the migration aliases block from `ui/theme/tokens.gd`, rename `LABEL_CAPS` → `LABEL` (updating every caller), remove the legacy font names from `UI.font`, and add to `tests/test_design_tokens.gd` the assertion that none of the old names exists (`T.get_script().get_script_constant_map()` has no `BG_BASE`, `GOLD`, `INK`, …; list from data-model.md "Validation"). Also `BODY_STRONG` (an extension style for bold words in running text) replaced the old "body_bold" face; `test_the_old_palette_is_gone` guards the names.
- [X] T075 Run `tools/test.sh full`. All unit tests and every walk at every window size pass, still and animated, with no `SCRIPT ERROR`. Report the result with its output. Result 2026-10-22: `tools/test.sh ui full` 377,163 checks (after the left-card change), 0 failed; `tools/test.sh unit` 429 tests, 1 failed: `test_glossary` (icon `lock` has no entry), which failed before this feature. Run separately because `full` stops at that unit failure.
- [X] T076 Take the screenshot matrix (`godot --path . -s tools/shot.gd -- build/screenshots/matrix`) plus one play screen per Region, one in the Final Battle and one with reduced motion on. Put them beside `design-system/components/EncounterScreen/preview.html` for the owner's review (SC-007), and send them to the user. Matrix in `build/screenshots/matrix/` (8 sizes). The script reaches only Region 1 and the Final Journey, so other Regions' washes are covered by the play walk's `_check_wash`, not by pictures.
- [ ] T077 Check on devices with the `install-on-emulators` skill (Android emulator, iOS simulator, web): fonts render, the wash shows on GL Compatibility and the web build, and the press drop feels right on touch.

---

## Dependencies & execution order

- **Setup (T001–T002)** → **Foundational (T003–T008)** blocks every story.
- **US1 (T009–T018)** depends only on Foundational. It is the MVP slice.
- **US2 (T019–T032)** depends on Foundational. It touches many of the same files as US1's
  T016, so run it after US1.
- **US3 (T033–T041)** depends on Foundational (T005 fonts). It can run after US1, in
  parallel with US2 only if they split files; recommended after US2.
  - T041 (Cinzel removal) depends on T036 (card names off Cinzel) and T005.
- **US4 (T042–T048)** depends on Foundational. T042 changes `stone_style.gd`, which every
  slab uses, so do it before US6's component work.
- **US5 (T049–T055)** depends on Foundational (T004 Ether roles). It is independent of US3
  and US4 except for shared files (`card_face.gd`: do it after T029, T036 and T046).
- **US6 (T056–T069)** depends on US2 (primary meta, dialog answer), US3 (styles) and US4
  (materials).
- **Polish (T070–T077)** comes last. T074 (aliases removed) needs every story done.

## Parallel opportunities

- Foundational: T006, T007 and T008 are separate files.
- US1: T012 and T015 run beside T009–T011.
- US5: T052 (many widgets) can be split across agents by file once T050 lands.
- US6: T056 (tab_row), T057 (ledger) and T058 (chip) are new and independent.
- Polish: T070, T071 and T072.

```text
# Example: US6 builders together
T056 ui/widgets/tab_row.gd + tests/test_tab_row.gd
T057 ui/widgets/ledger.gd  + tests/test_ledger.gd
T058 UI.chip in ui/theme/theme.gd
```

## Implementation strategy

1. **MVP = Setup + Foundational + US1 + US2** (both P1). The game is in the new palette on
   a Region-washed ground, and brass means "here". Run `tools/test.sh` and show
   screenshots before continuing.
2. Then **US3** (type) and **US4** (materials), the P2 legibility and material pass.
3. Then **US5** (Ethers) and **US6** (components), the P3 finish.
4. **Polish**: aliases removed, docs, `tools/test.sh full`, screenshots and devices.

Commit only when the owner asks (memory: commit only when asked; no attribution lines).
