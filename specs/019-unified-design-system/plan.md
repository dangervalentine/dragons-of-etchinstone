# Implementation Plan: Unified Design System (Inkstone and Brass)

**Branch**: `019-unified-design-system` (work is on `main`; no branch was created) | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/019-unified-design-system/spec.md`

## Summary

This feature replaces the game's night-stone look with the "Inkstone and Brass" design
system in [design-system/](design-system/).

- **Palette**: a slate-green ground, stone panels and parchment text.
- **Brass**: reserved for the one primary action, the selected thing and the one target
  slot. Bright brass is for rewards only.
- **Type**: Fraunces replaces Cinzel for display and figures, which become tabular.
- **Materials**: chamfered stone slabs with a carved bevel, rounded paper cards with
  physical shadows, and paper reading surfaces.
- **Ethers**: four mineral pigments.
- **Ground**: a Region-tinted wash replaces the patterned stone grounds and the menu's
  choice of them.

The approach:

1. Rewrite `ui/theme/tokens.gd` to the design system's names and values, held to
   `tokens.json` by a unit test.
2. Redraw the materials once in `stone_style.gd` and the theme helpers.
3. Give each design-system component one builder.
4. Sweep every screen, widget and overlay through the role mapping from the colour audit
   (research R6).
5. Add checks for one primary button and one target slot.

Layout, rules and choreography do not change.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (standard build, GL Compatibility renderer)

**Primary Dependencies**: none new. Fonts: Fraunces (variable) and Alegreya Sans, SIL
OFL, as full TTFs (research R3). fontTools is used once, through `uv`, to verify them, and
is not shipped.

**Storage**: `user://` settings. The `display/ground` key is dropped and ignored if
present.

**Testing**: `tools/test.sh` (headless unit tests on `tests/base.gd`, and the UI check
walks at every window size, still and animated)

**Target Platform**: web, Android and iOS, landscape. The trimmed release templates keep
the `freetype` module, which reads TTF, so nothing there changes (CLAUDE.md "Release
size").

**Project Type**: mobile/web game, UI layer only (`ui/`, `art/fonts`, `tools/ui_check.gd`,
`tests/`). `engine/` is untouched.

**Performance Goals**: 60 fps on the existing animations. The new backdrop is one radial
term in a full-screen shader that already exists; the grain texture lookup goes away.

**Constraints**:

- `TEXT_MIN` 22 (with a `CARD_NAME_MIN` of 20 for card names only) and `TAP_MIN` 88.
- Every text pair meets its contrast (research R4).
- Reduced motion has a still form for every new state.
- Shipped data grows by less than 1 MB (SC-005).

**Scale/Scope**:

- Tokens: about 40 colour and 12 type tokens.
- Gold/focus uses reclassified: about 134.
- Files touched: 7 screens, about 30 widgets, 10 overlays, 4 theme files, 2 shaders and 4
  colour-literal sites.
- Tests: about 8 updated or new.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is the unfilled template, so it sets no gates. The
project conventions in CLAUDE.md stand in for it, and the design meets each one:

| Convention | How the design keeps it |
|---|---|
| Engine never preloads `ui/` | Only `ui/`, `art/`, `tools/` and `tests/` change |
| Values only from `tokens.gd` | Strengthened: the colour literals move into tokens (R12), and `tokens.json` is enforced by test |
| No `class_name`; `preload` consts; nodes built in code | New widgets (`tab_row.gd`, `ledger.gd`) follow the same pattern |
| `##` comments cite specs/research | New tokens and helpers cite `specs/019` and R-items |
| Reduced motion first-class | Press, lift, banner slide and wash change each have a still form (R13, contracts) |
| `TEXT_MIN` / `TAP_MIN` enforced by the UI check | Kept, extended to drawn text, plus the primary, target and font checks |
| README "Rules interpretations" | Not affected (no rules change) |

**Post-design re-check**: passes. Six deliberate departures from the design system are
recorded:

- The panel head glyph is muted rather than brass (contracts/components.md "Panel").
- The tap floor stays at 88 rather than 81.
- The setup screen's difficulty choice stays as described tiles, not tabs
  (contracts/components.md "Tabs"); the records difficulty filter does become tabs.
- Text printed on cards (names, Hand-card tags and ribbons, the Region and Dragon
  Cards' bands) is fitted to the card with a floor that scales with it, 18 on the
  narrowest phone's card rather than the system's 20 (a dragon's title 0.7 of that),
  so the Ether glyph can stay beside the name and the tags fit their cards (owner,
  2026-10-22, "relax the font size restriction"; `CARD_NAME_SHARE`).
- A ledger row only read (the Leaderboard's) is 44 units (24pt), under the Ledger
  README's 30pt, so a ten-place board fits a phone; a row that opens something is a
  whole tap target.
- `HELP_MIN` (44) stays for help targets, the top bar's counters included: they are
  a full `TAP_MIN` wide but only as tall as the bar, since a hit area reaching below it
  would cover the Action Set's headers under them (found in implementation; analysis
  I6 had asked for `TAP_MIN`).

## Project Structure

### Documentation (this feature)

```text
specs/019-unified-design-system/
├── spec.md
├── plan.md                 # this file
├── research.md             # R1–R14
├── data-model.md           # tokens, type styles, place and control states
├── quickstart.md
├── contracts/
│   ├── tokens.md
│   ├── type-styles.md
│   ├── brass-and-states.md
│   ├── materials-and-ground.md
│   ├── components.md
│   └── checks.md
├── design-system/          # the owner's design system, the source of truth
└── checklists/requirements.md
```

### Source Code (repository root)

```text
art/fonts/                  # + Fraunces[...].ttf, AlegreyaSans-ExtraBold.ttf, OFL texts
                            # − Cinzel.ttf, OFL-Cinzel.txt, AlegreyaSans-Regular.ttf
art/stone/                  # removed
ui/theme/
├── tokens.gd               # rewritten (contracts/tokens.md)
├── theme.gd                # fonts per style, button/panel/chip/paper/card helpers
├── stone_style.gd          # slab/plinth/well/lintel redrawn
├── numerals.gd             # Fraunces; tabular fallback
└── stone.gd                # removed (grain and grounds gone)
ui/fx/
├── backdrop.gdshader       # ground + Region wash
├── backdrop_layer.gd       # set_region()
└── animator.gd, flight_layer.gd   # settle overshoot, banner slide out, colour roles
ui/model/
├── view_state.gd           # place states (one target), top-bar heading text
└── settings.gd             # ground setting removed
ui/widgets/                 # + tab_row.gd, ledger.gd; every widget swept (R6, R9, R11)
ui/screens/, ui/overlays/   # swept; confirm_dialog gains a title; stage_banner for endings
ui/main.gd                  # _tint_backdrop → set_region; banner colours; dialog titles
tools/ui_check.gd           # primary, target and font checks; no Ground row
tools/make_ground.gd        # removed
tools/field_bench.gd        # new backdrop uniforms
tests/                      # + test_design_tokens, test_palette_contrast, test_fonts;
                            # − test_stone_contrast; updated card_contrast, place_labels,
                            #   card_face_layout, deck_stack, settings
README.md, CLAUDE.md        # fonts, credits, tokens pointer to specs/019/design-system
```

**Structure Decision**: The existing single Godot project layout. All the work is in the
UI layer and its checks. The two new widgets follow the `ui/widgets/<name>.gd`
convention.

## Delivery order

Each step leaves the game playable and the quick suite green:

1. **Fonts and tokens** (US3 foundation and FR-001–004):
   - Add the fonts and verify them (quickstart 1).
   - Write the new tokens, keeping the old names as aliases pointing at their new roles.
   - Add the type styles and `UI.font(style)`.
   - Add `test_design_tokens` and `test_palette_contrast`.
2. **Ground and wash** (US1): rebuild the backdrop shader and add `set_region`; remove
   the ground setting, the tiles and `stone.gd`.
3. **Materials** (US4): `stone_style`, `paper_box`, `card_radius` and `card_shadow`;
   pressed motion.
4. **Brass audit** (US2): sweep R6's role mapping file by file; primary meta; boost aim
   as tabs; dialog answer; one-target place states; the UI check's primary and target
   checks.
5. **Type sweep** (US3): map the styles, remove `.to_upper()`, title-case the sources,
   set card names in Fraunces, apply floors to drawn text, change the top bar's text.
6. **Ethers** (US5): the pigments and the pill/plate roles in every consumer.
7. **Components** (US6): tab_row, ledger, chip, panel heads, dialog titles, banners for
   endings, the top bar.
8. **Remove the aliases**, sweep the literals (R12), and update README, CLAUDE.md and the
   old contracts' pointer; then `tools/test.sh full` and the screenshot review.

## Changes asked for during implementation (owner, 2026-10-22)

- Every card on the left (the Deck's face, the Encounter, the notes laid on it) is the
  Hand cards' 5:7 shape: `DeckStack.face_rect` is the largest 5:7 rect in the column,
  centred; the column keeps its width (the owner chose this over widening it), so a
  note whose content is taller than its card is set smaller to fit, down to
  `CARD_TEXT_MIN` (18), its help chips kept at `HELP_MIN` as shown, and the Region
  Card's panel chips grow about their centres to `HELP_MIN`.
- Text printed on cards has a floor that scales with the card (spec FR-015).

## Complexity Tracking

No constitution violations. One risk is tracked:

| Risk | Mitigation |
|---|---|
| Spacing grows about 1.85× and some screens may stop fitting at the smallest window sizes | The layout solver keeps the large geometry. `tools/test.sh ui full screens` after step 1 finds any screen that overflows, and its gap steps down one rung with a `##` note (R2). |
