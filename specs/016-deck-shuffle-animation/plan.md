# Implementation Plan: Shuffling the Deck Under the Card on Top

**Branch**: `016-deck-shuffle-animation` | **Date**: 2026-10-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/016-deck-shuffle-animation/spec.md`

## Summary

The Deck is shown being shuffled each time the engine really shuffles it: after setup (or at a game's start), at each End of a Region, and before the Final Battle. The Region Card or Dragon Card is already on top and covers the Deck throughout.

- **One new step** (R1, R2). The Sequencer gains a no-op `shuffle` step. It is placed after the card on top is in place and the Deck has been refilled, and before the stage banner and the first draw.
- **Setup's order** (R3). The step goes after `turn_card`, so the Region 1 card is laid on before the shuffle.
- **The look** (R4, revised). NextQuest's riffle. Up to five real Mage Cards, face up, peel out from under the card on top one after another. Each comes out 60% as far as a Key Card rises, tilted 2° and shrunk slightly at the height of its arc, then slides back in under the rest. The motion comes from the pure, tested `peel_lift()` and `peel_at()`.
- **Timing** (R5). `T.SHUFFLE` is 0.9 s, and the step keeps its own time outside `SEQUENCE_MAX`. Press and skip end it as they end anything before the Key Card.
- **Reduced motion** (R6). Nothing moves, and a brief "Deck shuffled" caption shows on the top card.
- **Once only** (R7). Already guaranteed by how steps are built: only from engine actions, and `start` only on a new game.

The engine, `ViewState`, Regroup, and the timing of every other step are unchanged.

## Technical Context

**Language/Version**: GDScript, Godot 4.7 (pinned, via the `godot` shim)

**Primary Dependencies**: none new.
- Reused: `Sequencer`, `Animator`, `DeckStack` (its `_edges` layer, `edge_rects`, `finish`, `reveal_beat`) and `BoardResponse`.

**Storage**: N/A.

**Testing**:
- `tools/test.sh` runs the headless `tests/run.gd` suites (`test_sequencer`, `test_deck_stack`, `test_board_responses`), then `tools/ui_check.gd` across `layout_solver.MATRIX`.
- `tools/design_shots.gd` gains a `shuffle` mode.

**Target Platform**: Desktop (Windows/macOS), web, Android and iOS phone and tablet shapes.

**Project Type**: Single-player card game (desktop / mobile app).

**Performance Goals**: 60 fps during the riffle. At most 5 `CardFace`s move (position, rotation, scale), pooled and made once, plus one caption label.

**Constraints**:
- The shuffle takes ≤ 1.5 s, and a sequence grows by ≤ 1 s (0.9 s chosen).
- The top card never moves.
- No Mage face shows.
- Everything stays within the Deck's clip.
- Text ≥ 22.
- Reduced motion has no travel.
- No rules change.

**Scale/Scope**:
- No new files except the spec docs.
- Changed: `ui/model/sequencer.gd`, `ui/fx/animator.gd`, `ui/widgets/deck_stack.gd`, `ui/theme/tokens.gd`, `ui/model/board_response.gd`.
- Tests: `test_sequencer`, `test_deck_stack`, `test_board_responses`.
- Tools: `ui_check` (one beat check) and `design_shots` (one mode).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so there are no formal gates. The project's established conventions (as used in 012–015) apply:

| Convention | Status |
|---|---|
| The engine is the only judge of rules | Pass. No engine change. The shuffle shows the order the engine produced (FR-013) |
| Pure models are tested headless | Pass. `shuffle_offsets` and `shuffle_spread` are static and tested. The step's placement is tested in `test_sequencer` |
| The Sequencer is pure; steps replay to the after state | Pass. `apply()` treats `shuffle` as a no-op, and the replay tests still hold |
| How a sequence ends never depends on animation | Pass. `DeckStack.finish()` resets `_shuffle_t`, and `_finish` renders `_after` |
| Every screen is checked at every `MATRIX` shape | Pass. `ui_check` checks the beat order and the bounds mid-shuffle |
| Tap ≥ 88, text ≥ 22 | Pass. Nothing new is tappable. The caption is ≥ 22 |
| Reduced motion respected | Pass. No offset is applied, and a still caption is shown instead (R6) |
| Never colour alone | Pass. The moment is shown by motion or by words, never by tint |

Re-checked after Phase 1: no violations, and Complexity Tracking is not needed.

## Project Structure

### Documentation (this feature)

```text
specs/016-deck-shuffle-animation/
├── spec.md
├── plan.md              # This file
├── research.md          # R1–R8
├── data-model.md        # The shuffle step; DeckStack's transient
├── quickstart.md        # How to validate
├── contracts/
│   └── deck-shuffle.md  # Step orders; Animator → DeckStack; guarantees
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks (not yet)
```

### Source Code (repository root)

```text
engine/game.gd               # unchanged; its _shuffle calls define the moments (R1)
ui/model/sequencer.gd        # "shuffle" in DURATION and OWN_TIME; _shuffle_step() after turn_card / gather in start, setup, Region-change finish; apply() no-op
ui/fx/animator.gd            # _run: "shuffle" → screen.deck.shuffle(faces, d); reduced_duration keeps its time
ui/main.gd                   # _show_faces(): faces for pay_time, gather from the Discard and shuffle, on every path incl. start_game
ui/widgets/deck_stack.gd     # shuffle(models, d), peel_lift(), peel_at(), peel_count(), _riffle layer of pooled CardFaces, caption, finish() reset, reveal_beat("shuffle")
ui/theme/tokens.gd           # SHUFFLE := 0.9, SHUFFLE_PEELS/ARC/PEEL/TILT/SCALE
ui/model/board_response.gd   # "shuffle" in QUIET_STEPS
tests/test_sequencer.gd      # placement, count per game, absence elsewhere
tests/test_deck_stack.gd     # peel arc and order, peel bounds at every shape, finish reset, reduced motion
tests/test_board_responses.gd# STEPS gains "shuffle"
tools/ui_check.gd            # beat order + bounds mid-shuffle (file has unrelated uncommitted edits; append only)
tools/design_shots.gd        # "shuffle" mode
```

**Structure Decision**: This is the existing single-project Godot layout. The work stays inside the Sequencer, Animator and DeckStack seam that specs 012–015 established.

## Notes for implementation

- The working tree has unrelated uncommitted edits to `ui/model/sequencer.gd`, `ui/main.gd`, `ui/model/view_state.gd`, `ui/model/turn_draft.gd`, `tools/ui_check.gd` and their tests (Upgrade stepping). Build on them, and leave them in place.
- The current branch is `main`. `setup-plan.sh` reports the branch as `016-deck-shuffle-animation`, but no branch was created.
