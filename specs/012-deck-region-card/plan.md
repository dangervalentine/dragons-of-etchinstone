# Implementation Plan: The Deck and Region Card on the Playfield

**Branch**: `012-deck-region-card` | **Date**: 2026-10-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/012-deck-region-card/spec.md`

## Summary

The left side's Encounter region becomes the Deck: card edges whose depth follows the Deck count, with the Region Card on top (the Dragon Card in the Final Battle). Today's Encounter and dragon faces sit on that stack (R1, R2).

Each new Encounter plays a short **reveal** after the Hand settles:

1. The Key Card rises from under the Region Card just far enough to show its title band and the bronze Key Card strip (the Encounter number and any Hardship), then slides back (R4).
2. The view zooms from that Encounter's tile on the Region Card into today's face, whose creature starts moving when the zoom lands (R3, R7).

The Final Battle zooms into the Dragon Card's MP Tiers, then its HP Tiers, with no lift (R6).

The rest of the design:
- **Sequencer steps**: four new steps (`zoom_out`, `turn_card`, `key_peek`, `zoom_in`) that change no state (R8).
- **Anchors**: draws come from the top of the stack, and discards and trashes go to its back (R9).
- **Unchanged**: the engine, the rules, the faces' contents and the math box.

## Technical Context

**Language/Version**: GDScript, Godot 4.7 (the project's pinned version, via the `godot` shim)

**Primary Dependencies**: None new. Existing `ui/theme`, `ui/widgets` (`face_frame`, `encounter_face`, `dragon_face`, `dragon_stats`, `card_face`, `stat_chip`), `ui/fx` (`creature`, `animator`), `ui/model` (`sequencer`, `view_state`, `layout_solver`, `art`), `engine`. Existing art: creatures, `sigil_region` icon, Encounter/Hardship icons.

**Storage**: N/A.

**Testing**: `tools/test.sh`, which runs the headless `tests/run.gd` suites and then `tools/ui_check.gd`. Visual checks come from `tools/design_shots.gd`.

**Target Platform**: Desktop (Windows/macOS), the web build, and the Android/iOS phone and tablet shapes in `layout_solver.MATRIX`.

**Project Type**: Single-player card game (desktop / mobile app).

**Performance Goals**:
- 60 fps during the zoom.
- The 8 tiles' creatures are held still, so at most one live creature shader runs on the left side, as today.

**Constraints**:
- Reveal ≤ 2 s and skippable (SC-003).
- Text ≥ 22 (including tile numbers and stats).
- Never colour alone.
- Reduced motion fades without travel.
- No rules change.
- Landscape, 1280 × 720 minimum view.
- The left column is 400–548 wide (380 in the Final Battle).

**Scale/Scope**:
- 3 new widgets (`deck_stack`, `region_card`, `dragon_card`).
- About 8 changed files (`play_screen`, `animator`, `sequencer`, `view_state`, `creature`, `face_frame`, `tokens`, `main`), plus 2 new tests, 2 changed tests and 2 tools.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it sets no gates. The plan holds to the project's established conventions:

| Convention | Status |
|---|---|
| The engine is the only judge of rules; the UI arranges its figures | Pass. The reveal reads `after.deck[0]` and the engine's `encounter()`. `engine/` is untouched |
| Pure models are tested headless | Pass. The Sequencer steps, the Region Card model, and the stack geometry (`edges`, `tile_rect`, `zoom_scale`, `peek_h`) (R10) |
| The Sequencer is pure and its steps replay to the after state | Pass. The new steps are no-ops in `apply` (contract invariant 5) |
| How a sequence ends never depends on animation code | Pass. `_finish` calls `deck.finish()`, then renders `_after` (R8) |
| Every screen is checked at every `MATRIX` shape by `ui_check` | Pass. Depth, values, containment and text-size checks (R10) |
| Tap ≥ 88, text ≥ 22 | Pass. The new surfaces take no taps; tile text ≥ 22 is asserted |
| Reduced motion respected | Pass. Every new step has a fade path, and creatures stay still (contract table) |
| Never colour alone | Pass. Tiles carry icons and numbers; the peek shows the printed strip |

Re-checked after Phase 1: no violations.

## Project Structure

### Documentation (this feature)

```text
specs/012-deck-region-card/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0: R1–R11
├── data-model.md        # Phase 1: view state additions, Region/Dragon Card models, stack state
├── quickstart.md        # Phase 1: how to see and check it
├── contracts/
│   ├── reveal-sequence.md   # The steps per action, invariants, animator behaviour
│   └── deck-stack.md        # Layers, per-phase settled look, zoomed-out view, peek, anchors, space
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
ui/widgets/
├── deck_stack.gd        # NEW: edges, peek, top card, faces; zoom_out/zoom_in/peek/turn_to/hold_card/finish (R1–R4, R6)
├── region_card.gd       # NEW: model(db, region) and the 8-tile face (R5)
├── dragon_card.gd       # NEW: model(dragon); name band over dragon_stats; MP/HP column rects (R6)
└── face_frame.gd        # set_held(on) → creature (R7)
ui/fx/
├── creature.gd          # held flag in _apply_motion (R7)
└── animator.gd          # Run zoom_out, turn_card, key_peek, zoom_in; hold at play(); deck.finish() in _finish (R8)
ui/model/
├── sequencer.gd         # Four new steps placed per contract; reveal excluded from _fit_time (R8)
└── view_state.gd        # top_card, key_face, zoom (data-model)
ui/screens/play_screen.gd   # Fill the encounter region with DeckStack; encounter_node(); point() anchors (R1, R9)
ui/theme/tokens.gd       # ENCOUNTER_MIN, DRAGON_MIN += DECK_EDGE; reveal durations (R2, R8)
ui/main.gd               # Start-of-game render begins zoomed out (bare state) (R8)
tests/
├── test_sequencer.gd    # Reveal placement and invariants (R10)
├── test_region_card.gd  # NEW (R10)
├── test_deck_stack.gd   # NEW (R10)
└── test_layout_solver.gd   # Raised minimums (R10)
tools/
├── ui_check.gd          # Depth, values, containment, tile text (R10)
└── design_shots.gd      # Zoomed-out and peek shots (R10)
README.md                # Play-screen description (R11)
specs/005-playfield-polish/contracts/playfield-layout.md   # Superseded-in-part note (R11)
```

**Structure Decision**: The existing single Godot project layout. The three new widgets join `ui/widgets/`, beside the faces they hold. Every other change lands in the file that already owns that concern.

## Phase 0 — Research

See [research.md](research.md). There are no open NEEDS CLARIFICATION items. Decisions:

- **R1**: `DeckStack` owns the encounter region.
- **R2**: `edges = clamp(ceil(n/2), 1, 8)` in a fixed 24-unit margin, with the minimums raised to match.
- **R3**: a shared-element zoom between the tile and the real face; tiles share the face's aspect.
- **R4**: the peek is the Key Card's own `CardFace` at Hand width, rising by band + strip.
- **R5**: the Region Card is a band and 2 × 4 tiles, current side only.
- **R6**: the half-turn within a card, a swap between cards, and a Dragon Card over `dragon_stats`.
- **R7**: creatures are held until the zoom lands; tiles are always still.
- **R8**: four no-op steps, a fixed-time reveal outside `_fit_time`, and the hold released by `_finish`.
- **R9**: deck, discard and trash anchors on the stack.
- **R10**: tests and tools.
- **R11**: documents.

## Phase 1 — Design

- [data-model.md](data-model.md): `top_card`, `key_face`, `zoom`; the Region Card and tile; the Dragon Card; the stack's state and transitions; the pure geometry.
- [contracts/reveal-sequence.md](contracts/reveal-sequence.md): the steps each action emits, the invariants `test_sequencer` checks, and what the animator does per step.
- [contracts/deck-stack.md](contracts/deck-stack.md): what the left side shows per phase, the zoomed-out view, the peek, anchors and space.
- [quickstart.md](quickstart.md): commands and manual checks.

## Risks

- **Longer turns**: the reveal adds about 1.4 s per Encounter and 0.55 s of zoom-out at Cleanup. *Mitigations*:
  - any press skips the whole sequence (existing rule);
  - the reveal has a fixed budget outside `SEQUENCE_MAX`.

  If playtests find it slow, the hold (0.4 s) is the first thing to cut.
- **Tile legibility on phones**: four tiles across a 400-unit column leave about 90 units each. `ui_check` asserts text ≥ 22. If a shape fails, the tile drops its effect icon first, then its stat badge, keeping the number and the art.
- **Deck region shrinks by `DECK_EDGE`**: the raised `ENCOUNTER_MIN`/`DRAGON_MIN` take height from the preview on the shortest shapes. The `space_audit` and layout solver tests catch any shape where the preview falls below `T.PREVIEW_MIN`. If so, `DECK_EDGE` drops to 16 there.
- **Render during a held sequence**: `draw` calls `screen.render(_after)`, which would otherwise zoom to the new face early. `DeckStack.held` guards this. `ui_check`'s animated games assert the view is `"card"` between `draw` and `zoom_in`.

## Complexity Tracking

No violations to justify.
