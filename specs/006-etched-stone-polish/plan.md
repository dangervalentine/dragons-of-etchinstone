# Implementation Plan: Raised Stone and the Math in Plain Sight

**Branch**: `006-etched-stone-polish` (work continues on `003-dragon-art`, as for 004 and 005) | **Date**: 2026-10-15 (revision 2) | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-etched-stone-polish/spec.md` (revision 2, after the stage 2 review)

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

The first stage left raised, chamfered stone boxes on the play screen, a content-sized
left column, zone responses at the boxes' rims and a space check in `ui_check`. The
owner then set the glow effects aside and asked for a bigger layout change. This plan
builds that on what remains.

1. **Role slots (US1).** The compact rail becomes full-size **role slots**: raised
   boxes above the Hand, each showing the number its card contributes.
   - Placing a card sends that number, as a flying figure, from the card to its slot.
   - The secondary actions move into an **action column** beside the slots: a 2 × 2
     grid of tap targets.
   - The button row under the Hand goes.
   - **Play** becomes the foot of the math box and carries the verdict
     ("Play · Narrow victory"), so the result and the decision sit together. There is
     a measured fallback to the bottom-right corner (research R3).
2. **The math box (US2).** It replaces the comparison bars: equation rows such as
   `8 + 2 − 1 = 9 / 11`, each term labelled with its source, with the consequences
   below.
   - **Every term comes from the engine.** The rules functions gain a `terms`
     breakdown, built from the same intermediate values they already compute, so the
     terms always add up to the engine's totals.
   - A new `Game.explain()` resolves an incomplete set, so the box can show the terms
     placed so far.
   - Outcomes do not change. A property test checks the sums over every Encounter.
3. **Raised boxes and flat ground (US3).**
   - The boxes are finished: stronger edges, flat lines, no glow anywhere on the
     ground.
   - The stone grain is replaced by a flat, seamless woodcut-line pattern, generated
     with ComfyUI on this Mac by a new `pattern` command in `tools/generate_art.py`.
     It is then tiled, quantised to a few flat tones and fitted to the contrast band
     by a headless Godot tool, `tools/make_ground.gd`. It ships as
     `art/stone/grain.png`, which `stone.gd` already prefers when present.
4. **A board that answers (US4).** Mostly built. Kept as zone-rim responses plus the
   flying number and counting totals; nothing ambient.
5. **Every screen (US5).** After the owner approves the play screen: the same boxes
   and ground on every other screen, with the lore framing from revision 1.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (standard build); Python 3 for the
generation driver

**Primary Dependencies**:
- Godot engine only in the game.
- The ground tile is made offline: ComfyUI + FLUX (already set up at `~/ComfyUI` by
  `tools/setup_comfyui.sh`), driven by `tools/generate_art.py`.
- Post-processing runs as a headless Godot tool using `Image`, because PIL is not
  installed (research R5).

**Storage**: N/A (the reduced-motion setting in `ui/model/settings.gd` is reused)

**Testing**: The headless runner `tools/test.sh` runs `tests/run.gd` and
`tools/ui_check.gd` (real matrix sizes, space check).
- New tests: `tests/test_terms.gd` (engine breakdown: the terms sum to the totals for
  every Encounter, Hardship and ability, and outcomes are unchanged) and
  `tests/test_role_slots.gd` (replaces `test_role_rail.gd`).
- Extended tests: `tests/test_layout_solver.gd` (slots, action column, Play in the
  left column) and `tests/test_stone_contrast.gd` (runs on whichever ground ships).
- Tools: `tools/space_audit.gd` and `tools/field_bench.gd` as before; screenshots
  from `tools/shot.gd` and `tools/design_shots.gd`.

**Target Platform**: Web (HTML5), Android, iOS; desktop for development. Compatibility
renderer.

**Project Type**: Single-project game client (mobile and web), no backend.

**Performance Goals**: `tools/field_bench.gd` PASS (average ≤ 16.7 ms, p99 ≤ 33 ms).
Today it is 2.07 ms. The ground is a static texture; the flying numbers reuse the
existing flight layer.

**Constraints**:
- **Rules are unchanged** (FR-023). `engine/` may gain *reporting only*: `terms`
  arrays in result dictionaries and the `explain()` entry points. Every existing
  result field keeps its value for the same input, which `test_terms.gd` and the
  existing `test_rules.gd`, `test_game.gd` and `test_playthrough.gd` check.
- **The math box never computes a total** (FR-010). It lays out the engine's terms.
- **Floors**: minimum text 22 units, tap target 88, contrast ≥ 4.5:1 for text and
  ≥ 3:1 for large numerals, against the ground and the box faces.
- **Layout**: landscape only, 1280 × 720 minimum, layout matrix unchanged. Hand cards
  no smaller than the baseline at any size. No zone more than a third empty at the
  minimum sizes.
- **No ambient effects**: nothing glows, flickers or moves on the ground (FR-016).
- **Card faces from 005 unchanged** (FR-017).
- **Generation**: allowed on this Mac. Keep runs small (one tile, a few seeds) and
  say how long they take (memory: art-generation-location).

**Scale/Scope**:
- **Engine**: a `terms` breakdown in `engine/rules.gd` and `engine/game.gd`, and
  `explain()`.
- **UI**: one reworked widget (`role_rail.gd` → `role_slots.gd`), one rebuilt widget
  (`preview_panel.gd` → math box), an `action_bar.gd` relayout, and solver and
  play-screen changes.
- **Tools**: one new tool (`make_ground.gd`) and one extended (`generate_art.py`).
- **Tests**: two new or replaced files.
- **Size**: about 1,500–2,000 lines changed.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template. **Result: PASS (no
gates defined)**, before research and after design. The plan keeps the project's
working rules:

| Existing project rule | How the plan keeps it |
|---|---|
| The rules engine has no dependency on the interface and is covered by headless tests | Engine changes are additive reporting only. Outcomes are checked unchanged by the existing engine tests plus `test_terms.gd`. No UI code enters `engine/` |
| One source of truth for game figures | The math box shows the engine's terms. The terms come from the same expressions that make the totals |
| Layout is a pure function checked across the matrix | Slots, the action column and Play's place go into `layout_solver.gd` and its tests. `ui_check` runs the real sizes |
| Legibility floors are tested | The contrast test runs against whichever ground ships (generated or fallback) |
| Reduced motion is honoured | The flying numbers, counting totals and responses all have still forms |
| Reference material is not part of the repository | The ground is generated; nothing is traced from the publisher |
| Art generation: keep runs small, say how long | One tile, a handful of seeds, timed. Larger sweeps are offered for the Windows PC |

**Post-design re-check**: still PASS.

## Project Structure

### Documentation (this feature)

```text
specs/006-etched-stone-polish/
├── plan.md              # This file (revision 2)
├── research.md          # Phase 0: R1–R8 (revision 2), with what was kept from revision 1
├── data-model.md        # RoleSlot, Term, Sum, Explanation, Zone, Ground
├── quickstart.md        # Verification by story; results so far kept
├── baseline.md / baseline.json   # Space baseline (unchanged)
├── contracts/
│   ├── role-slots.md        # US1 (replaces role-rail.md)
│   ├── math-box.md          # US2: the box and the engine's terms
│   ├── boxes-and-ground.md  # US3 (replaces stone-and-rift.md)
│   ├── board-life.md        # US4 (revised: no ambient effects)
│   └── screens-and-lore.md  # US5 (lightly revised)
├── checklists/requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks; to be regenerated)
```

### Source Code (repository root)

```text
engine/
├── rules.gd             # + terms in resolve_enemy / resolve_journey results (reporting only)
└── game.gd              # + terms in _final_journey / _final_enemy; + explain(), explain_final()
ui/
├── model/
│   ├── view_state.gd    # slot tokens from the engine's terms; math sums for the box
│   ├── layout_solver.gd # slots + action column; Play in the left column; button row removed
│   └── board_response.gd
├── widgets/
│   ├── role_slots.gd    # REWORKED from role_rail.gd: full-size raised slots with numbers
│   ├── preview_panel.gd # REBUILT as the math box: equation rows, consequences, Play
│   ├── action_bar.gd    # secondary actions in a 2 × 2 grid beside the slots; Play handed to the box
│   └── hand_tray.gd     # unchanged logic; more height
├── fx/flight_layer.gd   # number flight from card to slot (reused API)
├── theme/stone.gd, stone_style.gd, theme.gd   # stronger raised boxes; flat lines; ground from art/stone/grain.png
└── screens/play_screen.gd
art/stone/grain.png      # NEW: generated flat ground tile
tools/
├── generate_art.py      # + `pattern` command (seamless flat woodcut-line tile)
├── make_ground.gd       # NEW: seam fix, tone quantise, luminance fit → art/stone/grain.png
├── space_audit.gd, field_bench.gd, ui_check.gd
tests/
├── test_terms.gd        # NEW
├── test_role_slots.gd   # replaces test_role_rail.gd
└── test_layout_solver.gd, test_stone_contrast.gd   # extended
```

**Structure Decision**: The same single Godot project. The engine gains reporting
only. Presentation stays under `ui/`, and pure shaping stays in `ui/model/`. The ground
is an asset made by offline tools.

## Staging and the exit point

| Stage | Stories | Gate to continue |
|---|---|---|
| A | US1 + US2 (slots, numbers, math box, Play in the box) on the existing raised boxes | `tools/test.sh` green; `test_terms` proves the sums; owner sees the new layout |
| B | US3 + US4 (finished boxes, generated flat ground, responses) | Owner prefers the restyled play screen (US3 scenario 4). **No → stop**; stage A stays |
| C | US5 (every screen) | Owner prefers the after on every screen |

## Complexity Tracking

| Item | Why needed | Simpler alternative rejected because |
|---|---|---|
| Additive reporting in `engine/` (the plan for revision 1 forbade engine edits) | FR-010 requires the box to show the engine's own figures; only the engine knows the intermediate values (Armor removed, Night Travel's cut, the Reserve added) | Recomputing the terms in the UI would duplicate the rules and could drift from them, which FR-010 forbids. The change is reporting only and guarded by tests that the outcomes are unchanged |
