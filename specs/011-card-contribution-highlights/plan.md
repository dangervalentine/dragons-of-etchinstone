# Implementation Plan: Card Contribution Highlights

**Branch**: `011-card-contribution-highlights` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/011-card-contribution-highlights/spec.md`

## Summary

The box under the Encounter face stops predicting. Before Play it shows only a step tip; its equation rows and verdict appear only once Play is pressed, as the post-Play summary (R5). Its three load-bearing jobs move onto the cards:

- **Lifted parts**: `Emphasis` lifts each card's regions from the engine's own `explain` terms, so the lift matches the count (R1).
- **Impact marks**: Night Travel, Steep, Ranged, Freeze and Armor draw their icon to the right of each affected badge, beside the source icon that stays on the Encounter (R2, R3).
- **Boost aim**: against an Enemy, each Boost card gains an 88-tall aim zone along its bottom edge. A tap there cycles unset → Attack → Initiative and shows an aim mark beside the Boost badge. Taps elsewhere and drags still swap (R4).

The XP purse keeps its number. Each level-up flies the XP spent as stars from the number to the card, and leftover XP fades when the Upgrade step ends (R7). The box keeps its height, so the follow-up pass inherits the region (R6). The engine is untouched.

## Technical Context

**Language/Version**: GDScript, Godot 4.7 (the project's pinned version, via the `godot` shim)

**Primary Dependencies**: None new. Existing `ui/theme`, `ui/widgets`, `ui/model`, `ui/fx` and `engine`. Existing icons `night_travel`, `steep`, `ranged`, `freeze`, `armor`, `attack`, `initiative` and `xp` in `art/icons/`.

**Storage**: N/A.

**Testing**: `tools/test.sh`, which runs the headless `tests/run.gd` suites and then `tools/ui_check.gd`. Visual checks come from `tools/design_shots.gd`.

**Target Platform**: Desktop (Windows/macOS), the web build, and the Android/iOS phone and tablet shapes in `layout_solver.MATRIX`.

**Project Type**: Single-player card game (desktop / mobile app).

**Performance Goals**: 60 fps. Lift and marks are worked out once per view state (one `explain` call, already made for `math`).

**Constraints**:
- Tap targets ≥ 88 (`T.TAP_MIN`) and text ≥ 22.
- Never colour alone.
- Reduced motion snaps or fades.
- No rules change (FR-024).
- Landscape, 1280 × 720 minimum view.

**Scale/Scope**: About 10 UI and model files changed, plus their tests and three tools. Hands of 1–4 cards (Region) and 7–9 (Final Battle).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it sets no gates. The plan holds to the project's established conventions:

| Convention | Status |
|---|---|
| The engine is the only judge of rules; the UI arranges its figures | Pass. Lift and Armor read `explain` terms (R1, R2). `to_action()` is unchanged |
| Pure models are tested headless | Pass. `Emphasis`, `TurnDraft`, `Sequencer` and `ViewState` tests (R8) |
| Every screen is checked at every `MATRIX` shape by `ui_check` | Pass. Aim zone, mark overlap and space checks (R6, R8) |
| Tap ≥ 88, text ≥ 22 | Pass. Aim zone is 88 tall, full card width (R4) |
| Reduced motion respected | Pass. Focus fades, star flights and the `xp_lost` fade all have reduced-motion paths (R7) |
| Never colour alone (001 design tokens) | Pass. Lift raises and rims; impact and aim marks are icons (R2, R3) |

Re-checked after Phase 1: no violations.

## Project Structure

### Documentation (this feature)

```text
specs/011-card-contribution-highlights/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0: R1–R9
├── data-model.md        # Phase 1: focus, impacts, aim, box states, star steps
├── quickstart.md        # Phase 1: how to see and check it
├── contracts/
│   ├── card-marks.md    # Lift, impact and aim per encounter type and effect
│   └── left-box.md      # What the box shows in each step, and the post-Play summary
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
ui/model/
├── emphasis.gd          # Lift from explain terms (R1); impacts (R2); aim in focus
├── view_state.gd        # Pass terms/effects to Emphasis; drop _aim and Play's warning kind; tip text per step
├── turn_draft.gd        # cycle_boost_to(set)
└── sequencer.gd         # upgrade.spent; finish → xp_lost
ui/widgets/
├── card_face.gd         # Draw impact and aim marks right of a region (R3)
├── card_view.gd         # aim_rect(); aim_tapped(id) from the zone (R4)
├── preview_panel.gd     # Tip-only render; reveal(math) for the summary; aim rows removed (R5)
└── xp_purse.gd          # count_to(n, d); fade_out(d)
ui/screens/play_screen.gd   # Forward aim_tapped; keep the preview region height (R6)
ui/fx/animator.gd        # tally → preview.reveal; upgrade stars; xp_lost
ui/main.gd               # _on_aim(id) → draft.cycle_boost_to; drop _aim_boost; keep B key
tests/                   # test_emphasis, test_view_state, test_turn_draft, test_sequencer (R8)
tools/                   # ui_check, space_audit, design_shots (R8)
README.md                # Outcome preview description (R9)
specs/001-*, 006-*, 010-*   # Superseded-in-part notes (R9)
```

**Structure Decision**: The existing single Godot project layout. No new files outside `specs/`. Every change lands in the file that already owns that concern.

## Phase 0 — Research

See [research.md](research.md). There are no open NEEDS CLARIFICATION items. Decisions:

- **R1**: lift from `explain` terms.
- **R2**: an impact table keyed by Encounter effects, with Armor read from the terms.
- **R3**: marks to the right of the plate, on dark discs.
- **R4**: an 88-tall bottom aim zone, cycling Attack first.
- **R5**: the box shows a tip before Play and the summary from the `tally` step.
- **R6**: the box keeps its height; the space check is measured on the summary.
- **R7**: stars on the flight layer, `upgrade.spent`, `xp_lost`.
- **R8**: the tests and tools to change.
- **R9**: superseded-document notes.

## Phase 1 — Design

- [data-model.md](data-model.md): card focus (`regions`, `impacts`, `aim`), Boost aim state and cycle, box modes, sequence step additions.
- [contracts/card-marks.md](contracts/card-marks.md): the expected lift, impact and aim for each encounter type and effect. This is the table the emphasis tests and `ui_check` check against.
- [contracts/left-box.md](contracts/left-box.md): the box's content per step, the post-Play summary, and the space rule.
- [quickstart.md](quickstart.md): commands and manual checks.

## Risks

- **Aim-zone feel**: a tap meant to pick up the Boost card that lands in its lower band aims instead. *Mitigations*:
  - the zone shows only against an Enemy;
  - a pick-up tap anywhere above the band still works;
  - the aim mark animates on change so the result is clear.

  To be checked on the phone shapes via the install-on-emulators skill.
- **Small Final Battle cards**: an 88 zone is a larger share of a small card. `ui_check` asserts the zone never exceeds 50% of card height. If it does on any shape, the zone shrinks to the lower half and the shape is reported.
- **Summary timing**: `reveal` must build from the pre-Play state. The animator never re-renders the screen before `_finish`, apart from the `draw` step, which comes after `verdict`.

## Complexity Tracking

No violations to justify.
