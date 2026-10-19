# Implementation Plan: Notes Dealt On and Discarded Off Like Cards

**Branch**: `015-dealt-table-notes` | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/015-dealt-table-notes/spec.md`

## Summary

Every note on the Deck becomes a card dealt in from the left and thrown off to the left, and notes pile up within an interaction.

- **One card per kind** (R1). The single `TableNote` becomes a `NotePile` of cards, one per kind (result, step, Soak, XP), plus a refusal card on top.
- **What to deal and throw** (R2). A pure `NotePile.plan(pile, wanted)` decides it from the existing `note_kinds`:
  - nothing wanted throws the whole pile;
  - an undo throws the cards above the wanted one;
  - a newly wanted kind is dealt on top.
- **Unclipped flight** (R3). The Deck's clip moves to an inner `_table`, so cards fly past the Deck's edge unclipped.
- **One motion** (R4). Deal and discard share the setup discard's path and turn. They are fully opaque, 0.35 s each, and the pile is thrown with a 0.04 s fan.
- **The pile on the table** (R5). Cards beneath lie at small fixed tilts, so their corners show, each with a soft card shadow. A refused move is its own card, thrown alone.
- **Unchanged triggers**. The screen and animator reach the panels through getters (R6). Holding, finishing, resizing and reduced motion are covered in R7.

The engine, `ViewState`, the Sequencer and every trigger's timing are unchanged.

## Technical Context

**Language/Version**: GDScript, Godot 4.7 (pinned, via the `godot` shim)

**Primary Dependencies**: none new.
- Reused: `TableNote`, `PreviewPanel`, `SoakMeter`, `XpPurse`, `DeckStack` and `Animator`.

**Storage**: N/A.

**Testing**:
- `tools/test.sh` runs the headless `tests/run.gd` suites (`test_deck_stack`, new `test_note_pile`), then `tools/ui_check.gd` across `layout_solver.MATRIX`.
- `tools/design_shots.gd` gains a `notes` Deck shot.

**Target Platform**: Desktop (Windows/macOS), web, Android and iOS phone and tablet shapes.

**Project Type**: Single-player card game (desktop / mobile app).

**Performance Goals**:
- 60 fps with up to 4 note cards in flight.
- Each card is one rounded face, a 4-layer shadow and its existing content.

**Constraints**:
- Text ≥ 22.
- Reduced motion fades in place, with no travel or turn.
- Notes stay fully opaque in flight.
- Landscape, 1280 × 720 minimum.
- No rules change.
- The pile's tilt stays within the `T.DECK_EDGE` margin.

**Scale/Scope**:
- 1 new widget: `note_pile.gd`.
- About 6 changed source files: `deck_stack`, `table_note`, `play_screen`, `tokens`, and `animator` only if a getter needs it.
- 2 tests: `test_deck_stack`, and the new `test_note_pile`.
- 3 tools: `ui_check`, `space_audit` and `design_shots`.
- 1 superseded-in-part note.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so there are no formal gates. The project's established conventions (as used in 012–014) apply:

| Convention | Status |
|---|---|
| The engine is the only judge of rules | Pass. No engine change. What lies on the Deck still comes from `ViewState.note_for` and `result_held` |
| Pure models are tested headless | Pass. `NotePile.plan`, `tilt` and `off_table` are static and tested. `NotePile` is driven headless in `test_note_pile` |
| The Sequencer is pure; steps replay to the after state | Pass. No step is added or retimed |
| How a sequence ends never depends on animation | Pass. `DeckStack.finish()` → `NotePile.finish()` lands every flight, and `_finish` renders `_after` |
| Every screen is checked at every `MATRIX` shape | Pass. `_check_note` reworked for the pile (R8) |
| Tap ≥ 88, text ≥ 22 | Pass. Card content and size are unchanged. The XP card regains its recap, which `_check_note`'s fit check covers |
| Reduced motion respected | Pass. Deal and discard fade in place |
| Never colour alone | N/A. No new meaning is carried by colour |

Re-checked after Phase 1: no violations. A new widget file is justified by `deck_stack.gd`'s size and the pile being its own concern (R1).

## Project Structure

### Documentation (this feature)

```text
specs/015-dealt-table-notes/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0: R1–R9
├── data-model.md        # Phase 1: tokens, NotePile, widget changes, card states
├── quickstart.md        # Phase 1: checks, shots, play-through
├── contracts/
│   └── note-pile.md     # Rules, motion, triggers, settling, anchors
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
ui/widgets/
├── note_pile.gd         # NEW: the cards, plan/tilt/off_table, deal/throw/refusal/lift/finish, panel() (R1, R2, R4, R5, R6, R7)
├── deck_stack.gd        # _table holds the clip; note → pile; triggers delegate; turn_to throws the setup card; finish/_place reach the pile (R3, R4)
└── table_note.gd        # Unclipped root with a clipped _body; card shadow; XP keeps its recap (R1, R5)
ui/theme/tokens.gd       # NOTE_DEAL, NOTE_DISCARD, NOTE_TURN, NOTE_TILT, NOTE_PILE_STAGGER, CARD_SHADOW
ui/screens/play_screen.gd   # preview / soak_meter / xp_purse as getters via deck.panel() (R6)
tests/
├── test_deck_stack.gd   # NotePile.plan table, tilt
└── test_note_pile.gd    # NEW: deal, throw, refusal single, finish, panel spares
tools/
├── ui_check.gd          # _check_note for the pile; Boost refusal via pile; lost-fight pile 1→2→3→0
├── space_audit.gd       # The result card via pile.card("result")
└── design_shots.gd      # notes shot
specs/013-physical-region-card/contracts/left-column.md   # superseded-in-part note
```

**Structure Decision**: the existing single Godot project layout. The pile is a new widget beside `deck_stack.gd`, which owns it. Every other change lands in the file that already owns that concern.

## Phase 0 — Research

See [research.md](research.md). There are no open NEEDS CLARIFICATION items. Decisions:

- **R1**: one card per kind in a `NotePile`.
- **R2**: `plan()`'s three rules.
- **R3**: the clip moved to `_table`.
- **R4**: the shared deal and discard motion.
- **R5**: tilt, shadow and the refusal card.
- **R6**: panel getters.
- **R7**: hold, finish, resize and reduced motion.
- **R8**: tests and tools.
- **R9**: documents.

Two findings made while planning:
- **One note held several kinds.** Today the result, Soak and XP share one note, stacked in a column. Splitting them into cards means the XP card must carry its own recap again.
- **The setup throw unclips the whole Deck.** That is harmless at setup, but would let a zooming card spill out once the result is thrown during `zoom_out`. Hence R3.

## Phase 1 — Design

- [data-model.md](data-model.md): the tokens, `NotePile`'s fields, pure functions and methods, a card's states, and the changes to `DeckStack`, `TableNote` and `PlayScreen`.
- [contracts/note-pile.md](contracts/note-pile.md): the rules, the motion table (normal and reduced), the triggers, settling and the anchors.
- [quickstart.md](quickstart.md): commands, shots and the play-through.

## Risks

- **Fly-to targets during a deal.** `gain_xp` ghosts fly to `note_point()`, the top card. If a card is dealt mid-step, the point is its rest centre, not its flying position. `note_point()` uses the rest rect.
- **The tilt's corners on the smallest shapes.** At 1.2° on a 476-unit card, the corners move about 5 units, within `T.DECK_EDGE` (24). `ui_check`'s region check uses a grown rect to allow for it.
- **The result covered too soon.** With the Soak card dealt over the result straight away, the player may want to reread the result. Press-and-hold lifts the pile, as today. If it reads badly in play, the Soak's deal can wait until the verdict has shown, by the same trigger it has today.
- **`_table` reparenting.** Code that reads `_edges.get_parent() == self` or similar positions must use `_table`'s origin, which is `(0, 0)`, so every rect is unchanged.

## Complexity Tracking

No violations to justify.
