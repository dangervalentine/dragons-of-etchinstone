# Implementation Plan: Etched Stone and Ether Rifts

**Branch**: `006-etched-stone-polish` (work continues on `003-dragon-art`, as for 004 and 005) | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-etched-stone-polish/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

Three stages, in the spec's order.

1. **Space (US1).** The band of large slots above the Hand is replaced by a
   **role rail**: one row of compact role tokens, one tap target tall. Each token
   shows the role's icon and, once filled, the card's contribution (not its name).
   The rail also carries the Boost-to toggle and the after-battle recap. One-set
   Hand cards are width-bound, so the height the rail frees becomes the Hand's
   well; the two-row Final Battle Hand's cards gain the little height freed there. The left column's split
   becomes content-driven: the preview takes the height its state needs, and the
   Encounter gets the rest.
2. **Stone and rift (US2, US3), the style frame.**
   - **Stone surface.** The flat backdrop and rounded panels become carved stone.
     A stone grain and a cellular crack map are baked once from Godot's built-in
     noise. A custom `StyleBox` draws every zone as a chamfered, bevelled well cut
     into that stone.
   - **Rift light.** The backdrop shader lets Ether light glow through the cracks,
     tinted by the Encounter's Ether, or neutral when there is none.
   - **Ornament.** Woodcut ornaments (gouged dividers, corner cuts) are generated
     as icons.
   - **Life.** Shimmering seams, a small budget of drifting motes, a lit active
     zone, and a named board response for every player action. All of it is still
     under reduced motion.
3. **Rollout (US4).** Once the owner approves the play screen, the same style and
   lore framing reach the other screens:
   - Title: The Tear.
   - Rules setup: the elders' proclamation.
   - Ending: an inscribed slab.
   - Overlays: slabs and scrolls.
   - Final Battle and the Region banner.

`engine/` and `data/` do not change.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (standard build)

**Primary Dependencies**: Godot engine only, using `FastNoiseLite` / `NoiseTexture2D`
(built in) for stone and crack maps and `CPUParticles2D` for motes. Ornament icons
come from `tools/gen_icons.py` (Python 3, standard library). No add-ons, no new
fonts. Bitmap stone textures from the Windows-PC art pipeline are an optional
fallback only (research D3).

**Storage**: N/A. The existing reduced-motion setting in `ui/model/settings.gd` is
reused.

**Testing**: The headless runner `tools/test.sh` runs `tests/run.gd` and
`tools/ui_check.gd`.
- New tests: `tests/test_role_rail.gd`, `tests/test_stone_contrast.gd`,
  `tests/test_board_responses.gd`.
- Extended tests: `tests/test_layout_solver.gd` (rail height, content-driven split).
- New tool `tools/space_audit.gd` measures SC-001 and SC-002.
- `tools/field_bench.gd` is extended with the backdrop, seams and motes.
- Before/after screenshots come from `tools/shot.gd` and `tools/design_shots.gd`.

**Target Platform**: Web (HTML5), Android, iOS; desktop for development. Compatibility
renderer (`gl_compatibility`), as today.

**Project Type**: Single-project game client (mobile and web), no backend.

**Performance Goals**: `tools/field_bench.gd` PASS (average ≤ 16.7 ms, 99th
percentile ≤ 33 ms) with 11 living card faces *plus* the stone backdrop, rift seams
and motes. The added board cost is ≤ 1 ms GPU at 1280 × 720 (research D7). On the
web build and the Android emulator there must be no visible stutter (SC-008); this
is judged by eye, not formally gated.

**Constraints**:
- `engine/` and `data/cards.json` are unchanged, with the same outcomes for the same
  seed and choices (FR-019; checked by `tools/ui_check.gd`).
- Minimum text is 22 design units and the minimum tap target is 88. Contrast must be
  ≥ 4.5:1 for text and ≥ 3:1 for large numerals, measured against the *brightest*
  stone and glow a text area can sit on (FR-017, research D5).
- Landscape only, one arrangement, 1280 × 720 minimum. The layout matrix in
  `ui/model/layout_solver.gd` is unchanged.
- Hand cards are no smaller than today at any matrix size. One-set cards are
  width-bound and keep their size; two-row Final Battle cards gain the small
  height freed there (research D2).
- No publisher artwork or trade dress beyond the existing card faces (FR-021).
- Reduced motion: no ambient motion; every response has a still form (FR-016).
- Staging: US1 lands on the current look and is complete on its own (FR-022). The
  restyle reaches other screens only after the style-frame sign-off (FR-023).

**Scale/Scope**: 3 new widgets and modules (`role_rail.gd`, `stone_style.gd`,
`rift_layer.gd`), 1 rewritten shader (`backdrop.gdshader`), 1 new pure model
(`ui/model/board_response.gd`), restyle edits to about 20 UI files (every user of
`UI.box`, `UI.panel` and `raised_panel_box`), about 8 new ornament icons, 3 new
tests, 1 new tool. About 1,800–2,400 lines changed.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template. It defines no
principles, so there are no gates to evaluate. **Result: PASS (no gates defined)**,
before research and again after design.

The plan holds itself to the rules the project already follows (as in 001, 004 and 005):

| Existing project rule | How the plan keeps it |
|---|---|
| The rules engine has no dependency on the interface and is covered by headless tests | Engine untouched; the role rail reads the existing view state; `BoardResponse` is pure and tested headless |
| Layout is a pure function checked across the matrix | Rail height and the content-driven left split go into `layout_solver.gd` and its tests; `ui_check.gd` runs every matrix size |
| Legibility floors are tested, not eyeballed | `test_stone_contrast.gd` checks every text colour against the brightest stone and glow it can sit on |
| Reduced motion is honoured everywhere | Every ambient and response element reads `UI.reduced_motion`; quickstart checks it |
| Reference material is not part of the repository | Stone, cracks and ornaments are generated; nothing is traced from the publisher |
| Art generation runs on the Windows PC, never on this Mac | Default stone is procedural. The fallback textures are a hand-off command, not run here |

**Post-design re-check**: still PASS. The design adds no engine dependency, loosens
no check and leaves the matrix unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/006-etched-stone-polish/
├── plan.md              # This file
├── research.md          # Phase 0: decisions D1–D12
├── data-model.md        # Phase 1: Zone, RoleToken, RiftLight, BoardResponse, LoreFrame
├── quickstart.md        # Phase 1: how to verify each story and success criterion
├── contracts/
│   ├── role-rail.md         # US1: what the rail shows and does
│   ├── stone-and-rift.md    # US2: the visual language (surfaces, wells, light, ornament)
│   ├── board-life.md        # US3: ambient motion and the response for each action
│   └── screens-and-lore.md  # US4: each screen's lore framing and what must survive
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks; not created here)
```

### Source Code (repository root)

```text
ui/
├── theme/
│   ├── tokens.gd            # + stone, rift and well tokens; ornament sizes
│   ├── theme.gd             # box/panel/raised_panel_box route to StoneStyle; carved headings
│   └── stone_style.gd       # NEW: StyleBox drawing a chamfered, bevelled stone well
├── model/
│   ├── layout_solver.gd     # rail height replaces slot band; content-driven left split
│   ├── view_state.gd        # rail tokens and active zone exposed (read-only shaping)
│   └── board_response.gd    # NEW: pure map from game events to board responses
├── widgets/
│   ├── role_rail.gd         # NEW: replaces slot_row.gd
│   ├── slot_row.gd          # REMOVED after the rail lands
│   ├── preview_panel.gd     # reports its needed height; tighter composition
│   ├── hand_tray.gd         # sits in the deeper Hand well (no logic change)
│   └── header_bar.gd, encounter_face.gd, dragon_face.gd, face_frame.gd,
│       soak_meter.gd, xp_purse.gd, action_bar.gd, stat_chip.gd, choice_tile.gd,
│       dragon_stats.gd, card_detail.gd, ether_picker.gd   # restyle only
├── fx/
│   ├── shaders/backdrop.gdshader  # REWRITTEN: stone grain + crack seams + rift light
│   ├── rift_layer.gd        # NEW: motes, seam shimmer timing, tint transitions
│   └── animator.gd          # calls BoardResponse for board-level reactions
├── screens/
│   ├── play_screen.gd       # rail in place of slots; active-zone light
│   ├── title_screen.gd      # The Tear
│   ├── rules_screen.gd      # the elders' proclamation
│   └── ending_screen.gd     # inscribed slab
├── overlays/                # every overlay as a slab or scroll
└── main.gd                  # backdrop + rift layer host; tint on every screen

art/icons/                   # + ornament SVGs from tools/gen_icons.py
tools/
├── gen_icons.py             # + woodcut ornaments
├── space_audit.gd           # NEW: SC-001 / SC-002 measurements
└── field_bench.gd           # + backdrop, seams and motes in the timed scene
tests/
├── test_role_rail.gd        # NEW
├── test_stone_contrast.gd   # NEW
├── test_board_responses.gd  # NEW
└── test_layout_solver.gd    # extended
```

**Structure Decision**: The existing single Godot project. Presentation code stays
under `ui/` in its current split (theme, model, widgets, fx, screens, overlays). The
new pure logic (`board_response.gd`, rail shaping in `view_state.gd`, layout) lives in
`ui/model/` so it is tested headless, as in 005.

## Staging and the exit point

| Stage | Stories | Lands on | Gate to continue |
|---|---|---|---|
| 1 | US1 | Current look | `tools/test.sh` and `space_audit.gd` pass. Shippable alone. |
| 2 | US2 + US3 on the play screen only (incl. Final Battle, which shares it) | Stone look on play | Owner compares before/after play screenshots (quickstart §4). **No → stop.** Revert stage 2 commits; stage 1 stays. |
| 3 | US4 | Stone look everywhere | Owner prefers the after on every screen (SC-003) |

Stage 2 is built from separate commits on top of stage 1, so a rejection reverts
cleanly. The code carries no runtime flag for the old look.

## Complexity Tracking

No constitution violations, so nothing to justify.
