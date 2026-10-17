# Implementation Plan: Ordered Hand and Play-Board Layout

**Branch**: `009-ordered-hand-layout` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/009-ordered-hand-layout/spec.md`

## Summary

The card side of the play board is reorganised. From the top down it holds:

- a short role strip;
- a row of ordered places in rulebook order (Reserve · Element · Spell · Boost);
- a floating row of unplaced cards;
- one action row: Fuse ¼ · Divert ¼ · Play ½.

The player picks a card up and puts it in a place, by tap, drag or keyboard. A card on a filled place swaps with the card there. Nothing lands in a place on its own except the last card into the Reserve. The engine is untouched. `TurnDraft` gains `held` and `reserve`, `view_state` turns role slots into an ordered `places` list, and `layout_solver` lays out the new bands. The solver picks one card size per Hand that keeps every stage of building on screen. In the Final Battle the left side narrows to `FINAL_LEFT_W` so 7–9 cards fit.

## Technical Context

**Language/Version**: GDScript, Godot 4 (the project's pinned version, via the `godot` shim)

**Primary Dependencies**: None new. Existing `ui/theme`, `ui/widgets`, `ui/model` and `engine`.

**Storage**: N/A. The draft is in memory; settings and history are unchanged.

**Testing**: `tools/test.sh`, which runs the headless `tests/run.gd` suites and then `tools/ui_check.gd`. Visual checks come from `tools/design_shots.gd` and `tools/space_audit.gd`.

**Target Platform**: Windows desktop (primary export), and the phone and tablet shapes in `layout_solver.MATRIX`.

**Project Type**: Single-player card game (desktop / mobile app).

**Performance Goals**: Glides at the existing `T.MOVE` timing, 60 fps. Layout is solved once per Hand or resize, not per frame.

**Constraints**:
- 1280 × 720 design canvas, landscape only.
- Tap targets ≥ 88, text ≥ 22, strip numbers ≥ 32.
- Reduced motion snaps everything.
- No rules change (FR-026).

**Scale/Scope**: About 8 UI files changed, plus their tests. Hands of 1–4 cards (Region) and 7–9 cards (Final Battle).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it sets no project gates. The plan holds to the conventions earlier features established instead:

| Convention | Status |
|---|---|
| The engine is the only judge of rules. The UI only arranges its figures | Pass: R1. The engine is unchanged and `to_action()` is identical |
| Pure models are tested headless (`turn_draft`, `view_state`, `layout_solver`) | Pass: R9 lists the tests |
| Every screen is checked at every `MATRIX` window by `ui_check` | Pass: kept and extended |
| Reduced motion respected | Pass: FR-009 and the contract |

Re-checked after Phase 1: no new violations.

## Project Structure

### Documentation (this feature)

```text
specs/009-ordered-hand-layout/
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
ui/model/turn_draft.gd       # held, reserve, pick/put/put_down, derived Reserve (R2)
ui/model/view_state.gd       # places, floating, held; role_slots → places; Give up Reserve leaves _secondary (R3, R5)
ui/model/layout_solver.gd    # strip/places/floating/action-row bands, per-Hand card size, FINAL_LEFT_W (R4–R6)
ui/model/emphasis.gd         # next role from the hinted place; target highlighting while held
ui/model/board_response.gd   # put / swap responses
ui/widgets/role_slots.gd     # becomes the role strip: short sections over place columns, Reserve toggle, set divider
ui/widgets/hand_tray.gd      # positions cards by place/floating; manual drag and drop hit-testing (R7)
ui/widgets/card_view.gd      # drag start threshold; held look
ui/widgets/action_bar.gd     # fixed ¼ · ¼ · ½ row (R5)
ui/screens/play_screen.gd    # new regions; hand panel round places + floating
ui/main.gd                   # pick/put/put_down/toggle_give_up_reserve intents; keyboard (R8)
tests/test_turn_draft.gd, test_role_slots.gd, test_layout_solver.gd, test_view_state.gd,
tests/test_emphasis.gd, test_board_responses.gd, test_card_face_layout.gd
tools/ui_check.gd            # drive building through pick/put
```

**Structure Decision**: The existing single Godot project layout. The change stays in `ui/` and `tests/`, and `engine/` is not modified.

## Phases

- **Phase 0** (done): [research.md](research.md), R1–R9. There are no open unknowns. `FINAL_LEFT_W` = 340 is provisional and checked in implementation (R6).
- **Phase 1** (done): [data-model.md](data-model.md), [contracts/board-layout.md](contracts/board-layout.md), [quickstart.md](quickstart.md).
- **Phase 2**: `/speckit-tasks`. Suggested order:
  1. Draft model and tests.
  2. Solver bands and sizes, and tests.
  3. View state `places`.
  4. Action row.
  5. Role strip.
  6. Hand tray positions.
  7. Intents and keyboard.
  8. Drag.
  9. Final Battle width check with `design_shots`.
  10. `ui_check`.

## Risks

- **Smaller cards**: Region cards go from 197 × 275 to ≈ 148 × 207, and Final Battle cards from 145 to ≈ 117 wide (≈ 101 with a full 9-card Final Enemy Hand). This follows from the clarified layout: two full rows of cards plus the strip and action row. Numerals stay at the legibility floor in the Region. Hover detail and inspect carry the close reading. Fallback (needs a spec change): badges on the outlines in the Final Battle instead of a separate strip.
- **Dragon face at 340 wide**: may clip. It is measured early; step up by 20 until it does not.
- **Drag versus hold-to-inspect**: these could conflict. The 12-unit move threshold decides, and holding still still inspects.

## Complexity Tracking

No violations to justify.
