# Implementation Plan: Legible Hand Cards

**Branch**: `010-legible-hand-cards` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/010-legible-hand-cards/spec.md`

## Summary

The card side becomes two bands:

- **one row of Hand positions**: a short label over each card, with a second row only in the Final Battle;
- **the action row**: its width shared by cell count.

Dealt cards fill the positions in draw order (Reserve · Element · Spell · Boost), and the player rearranges by swapping. The role strip, the places row and the floating row go. So does 009's requirement to fit two full card rows at once. That requirement was what made the cards small. Cards are now limited by width: 220 × 308 at phone-tall, against 138 × 194.

Values are read in the preview panel. Against an Enemy, its Attack and Initiative rows become 88-tall buttons that aim the Boost. Divert stays in the action row. Give up Reserve joins it as a fourth cell against a Ranged Enemy, and every cell then becomes a quarter, with Play rightmost.

The engine is untouched. `TurnDraft` gains `deal`, `settle`, `swap` and `boost_target_set`.

## Technical Context

**Language/Version**: GDScript, Godot 4 (the project's pinned version, via the `godot` shim)

**Primary Dependencies**: None new. Existing `ui/theme`, `ui/widgets`, `ui/model` and `engine`.

**Storage**: N/A. The draft is in memory.

**Testing**: `tools/test.sh`, which runs the headless `tests/run.gd` suites and then `tools/ui_check.gd`. Visual checks come from `tools/design_shots.gd`.

**Target Platform**: Windows desktop (primary export), the web build, and the phone and tablet shapes in `layout_solver.MATRIX`.

**Project Type**: Single-player card game (desktop / mobile app).

**Performance Goals**: Glides at `T.MOVE`, 60 fps. Layout is solved once per Hand or resize.

**Constraints**:
- Landscape only, 1280 × 720 minimum view.
- Tap targets ≥ 88, text ≥ 22.
- The left column's height is fully used (research R4, R5).
- Reduced motion snaps everything.
- No rules change (FR-020).

**Scale/Scope**: About 10 UI files changed, plus their tests. Hands of 1–4 cards (Region) and 7–9 cards (Final Battle).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it sets no gates. The plan holds to the project's established conventions:

| Convention | Status |
|---|---|
| The engine is the only judge of rules; the UI arranges its figures | Pass. `to_action()` is unchanged (R1) |
| Pure models are tested headless | Pass. R9 lists `turn_draft`, `layout_solver` and `view_state` tests |
| Every screen is checked at every `MATRIX` shape by `ui_check` | Pass. Extended to swaps and aim rows |
| Tap ≥ 88, text ≥ 22 | Pass. Aim rows are 88 (R4); labels hold 22 text in 36 |
| Reduced motion respected | Pass |

Re-checked after Phase 1: no violations.

## Project Structure

### Documentation (this feature)

```text
specs/010-legible-hand-cards/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── board-layout.md
├── checklists/
│   └── requirements.md
└── tasks.md              # /speckit-tasks
```

### Source Code (repository root)

```text
ui/model/turn_draft.gd       # deal, settle, swap, boost_target_set; floating → extras (R1–R3)
ui/model/view_state.gd       # places slimmed, math.sums[].aim, secondary + action_cells, no "next" (R4, R7, R8)
ui/model/layout_solver.gd    # hand band + positions, 1–3 row search, action row by cell count (R5, R6)
ui/model/emphasis.gd         # no "next" place; target highlighting kept
ui/model/board_response.gd   # number flight to the preview row; aim flare
ui/widgets/role_slots.gd     # → place_labels.gd: a label per position (R7)
ui/widgets/hand_tray.gd      # positions from the plan; outlines and floating rows go; drop on card or label
ui/widgets/action_bar.gd     # 2–4 secondary buttons, rects from the solver (R5)
ui/widgets/preview_panel.gd  # aim rows (88), Initiative note in-row, Region warning line dropped (R4)
ui/screens/play_screen.gd    # regions without slots; labels over the Hand
ui/main.gd                   # deal/settle calls; aim_boost; put {card}; A/I keys; select_slot/take_back removed
tests/test_turn_draft.gd, test_layout_solver.gd, test_view_state.gd, test_emphasis.gd,
tests/test_board_responses.gd, test_card_face_layout.gd, test_role_slots.gd → test_place_labels.gd
tools/ui_check.gd, tools/design_shots.gd
```

**Structure Decision**: The existing single Godot project. Changes stay in `ui/`, `tests/` and `tools/`. `engine/` is not modified.

## Phases

- **Phase 0** (done): [research.md](research.md), R1–R9. No open unknowns.
- **Phase 1** (done): [data-model.md](data-model.md), [contracts/board-layout.md](contracts/board-layout.md), [quickstart.md](quickstart.md).
- **Phase 2**: `/speckit-tasks`. Suggested order:
  1. Draft `deal`, `settle`, `swap` and `boost_target_set`, with tests.
  2. Solver: hand band, positions, row search and action-row split, with tests.
  3. View state: places, aim, `secondary`, `action_cells`.
  4. `main`: deal/settle wiring and intents.
  5. Place labels (replacing the role strip).
  6. Hand tray positions and drop targets.
  7. Action bar by cell count.
  8. Preview aim rows and height budget.
  9. Board responses.
  10. Keyboard.
  11. `ui_check` and `design_shots` at every shape.

## Risks

- **Preview height at phone-tall**: the Enemy box goes from 272 to 256, against a 273 budget, and only by dropping the Region warning line and moving the Initiative note into its row (R4). The `ui_check` fit test catches a miss. Fallback: shorten the outcome row's pills.
- **Outcome shown at the deal**: the preview shows the draw-order result before any choice. The spec accepts this as an assumption. Watch for players pressing Play on the default arrangement. Against an Enemy, Play still waits for the Boost aim.
- **Play narrowing to ¼ against Ranged Enemies**: still ≥ 200 wide everywhere. It is the only time Play changes width within a phase, and it holds for the whole Encounter unless a Divert drops the Reserve.
- **Swap by tapping a card**: tapping a card while another is held now swaps rather than picking the new card. That matches 009's swap rule, but makes it the only way to re-pick a different card. `put_down` (tap empty board or `Esc`) stays available.

## Complexity Tracking

No violations to justify.
