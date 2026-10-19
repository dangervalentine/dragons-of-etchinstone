# Implementation Plan: The Left Side as the Physical Region Card and Deck

**Branch**: `013-physical-region-card` | **Date**: 2026-10-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/013-physical-region-card/spec.md`

## Summary

The left column becomes one thing: the stack of cards held in the left hand.

- **The Region Card** is redrawn to the printed card's proportions (R1). It has a title band, the four Enemies 2 × 2, the four Journeys in a row below, an XP star on each panel, and no card code.
- **Each Encounter is one `RegionPanel`** (R2), laid out as fractions of its own size. The same picture serves both on the card and zoomed in.
- **Zooming** scales the card itself about the panel. On landing, a full-size panel of the same layout swaps in so text stays crisp and the creature can move (R3).
- **A reading strip** beside the landed panel writes out what the Ability, Peril and Hardship icons mean (R4).
- **The 011 box is removed** (R5). Its building tips are dropped (R8).
- **Its other feedback** (step text, refusals, the Play result, the XP purse, the soak meter) now arrives as a **note**: a card-shaped panel laid on the stack in the card's place, with room to write the outcome out line by line (R6, R7).
- **The Dragon Card** gets the same printed treatment (R10).

012's motion design stands: its Sequencer steps, Key Card peek, card turns, the hold and the anchors. The engine and the rules are untouched.

## Technical Context

**Language/Version**: GDScript, Godot 4.7 (pinned, via the `godot` shim)

**Primary Dependencies**: None new.
- Reused: `StatChip`, `Creature`, `EncounterFace.enemy_crop`, `Glossary`, `Art`, `StoneStyle`, `PreviewPanel`, `XpPurse`, `SoakMeter`, `dragon_face` and 012's `DeckStack`.
- Reference: `reference/sheets-official/o5.png`.

**Storage**: N/A.

**Testing**:
- `tools/test.sh` runs the headless `tests/run.gd` suites, then `tools/ui_check.gd` across `layout_solver.MATRIX`.
- `tools/space_audit.gd` measures space.
- `tools/design_shots.gd` takes the `deck` shots and the new `scan` overlay.

**Target Platform**: Desktop (Windows/macOS), web, Android and iOS phone and tablet shapes.

**Project Type**: Single-player card game (desktop / mobile app).

**Performance Goals**:
- 60 fps through the zoom.
- On the left side, only the landed panel's creature moves. The eight panels on the card stay still.

**Constraints**:
- Text ≥ 22, including every numeral on the whole card at the narrowest (400) column.
- Taps ≥ 88 where there are taps.
- Never colour alone.
- Reduced motion fades, with no travel.
- Landscape, 1280 × 720 minimum.
- No rules change.
- No `DOE-` text anywhere.

**Scale/Scope**:
- 2 new widgets: `region_panel`, `table_note`.
- 1 removed: `region_tile`.
- About 11 changed source files.
- 1 new test and 5 changed tests.
- 3 tools and 3 documents.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so there are no formal gates. The project's established conventions (as used in 012) apply:

| Convention | Status |
|---|---|
| The engine is the only judge of rules | Pass. The panels read `db.encounter`, the strip reads the `Glossary`, and the outcome lines reuse the preview's engine-sourced help. `engine/` is untouched |
| Pure models are tested headless | Pass. `LAYOUT`/`panel_rect`, `RegionPanel.parts`, `panel_fit`, `zoom_scale`, `note_for` and note precedence (R11) |
| The Sequencer is pure; steps replay to the after state | Pass. No Sequencer change. The note is driven by the animator from existing steps and reset in `_finish` |
| How a sequence ends never depends on animation | Pass. `_finish` sets the note from `after.note` and the landed panel from `after.zoom` |
| Every screen is checked at every `MATRIX` shape | Pass. `ui_check` additions (R11) |
| Tap ≥ 88, text ≥ 22 | Pass by assertion. R9's fallback covers any shape where the whole card's numerals fall short |
| Reduced motion respected | Pass. The zoom cross-fades, the note fades, and the hold moves by alpha only |
| Never colour alone | Pass. Ether badges carry their Ether marks, and effects carry icons plus the strip's words |

Re-checked after Phase 1: no violations.

## Project Structure

### Documentation (this feature)

```text
specs/013-physical-region-card/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0: R1–R12
├── data-model.md        # Phase 1: Region Card/Panel models, note, DeckStack additions, geometry
├── quickstart.md        # Phase 1: checks, shots, play-through
├── contracts/
│   ├── region-card-face.md   # The card, both panel kinds, the reading strip, the Dragon Card
│   └── left-column.md        # One region, layers, per-phase table, the note, sequence hooks
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
ui/widgets/
├── region_panel.gd      # NEW: one Enemy/Journey in the printed layout, sized by fractions (R2)
├── table_note.gd        # NEW: the note laid on the stack; hosts preview/xp/soak/messages (R6)
├── region_tile.gd       # REMOVED (012's tile)
├── region_card.gd       # Printed layout (LAYOUT, panel_rect), title band, no code (R1)
├── dragon_card.gd       # Printed Dragon Card layout, no code, tier column targets (R10)
├── deck_stack.gd        # Card aspect 5:7; zoom about the panel; landed panel + reading strip; note layer and hold (R3, R4, R6)
└── preview_panel.gd     # No tip; roomy layout with outcome lines; setup lines move to the note (R7, R8)
ui/screens/play_screen.gd   # One left region; preview/xp/soak into the note; refuse() replaces toast(); anchors; detail area (R5, R6)
ui/model/
├── layout_solver.gd     # No preview region; no preview_needed/encounter_min (R5)
└── view_state.gd        # Panel models (full stats, xp, pair); tips removed; note_for (R8, data-model)
ui/fx/animator.gd        # Note at tally/verdict/zoom_out/_finish (contracts/left-column.md)
ui/theme/tokens.gd       # Retire ENCOUNTER_MIN/DRAGON_MIN/PREVIEW_MIN; add LEFT_MIN_W, NOTE_HOLD, NOTE_ROOMY_H
ui/main.gd               # _refuse → play.refuse
tests/
├── test_region_card.gd  # Rewritten (R11)
├── test_region_panel.gd # NEW
├── test_deck_stack.gd   # panel_fit, zoom, note precedence
├── test_layout_solver.gd
└── test_view_state.gd
tools/
├── ui_check.gd          # No DOE-, no tips, whole-card numerals, notes fit, no zoom jump, left column only the stack
├── space_audit.gd       # Measure the result note
└── design_shots.gd      # deck shots and the scan overlay
README.md
specs/012-deck-region-card/contracts/deck-stack.md        # superseded-in-part note
specs/011-card-contribution-highlights/contracts/left-box.md   # superseded note
```

**Structure Decision**: The existing single Godot project layout. The two new widgets join `ui/widgets/` beside the stack they serve. Every other change lands in the file that already owns that concern.

## Phase 0 — Research

See [research.md](research.md). There are no open NEEDS CLARIFICATION items. Decisions:

- **R1**: the printed card's measured layout, held as fractions.
- **R2**: one `RegionPanel` drawn by its own size; the XP star and the number marker.
- **R3**: the card scales about the panel, then a landed panel swaps in.
- **R4**: a reading strip for the Hardship, Ability and Peril.
- **R5**: one left region.
- **R6**: `TableNote`, its kinds, precedence and hold.
- **R7**: outcome lines in the roomy result.
- **R8**: codes and tips removed.
- **R9**: fitting the narrowest column, with a fallback.
- **R10**: the printed Dragon Card.
- **R11**: tests and tools.
- **R12**: documents.

A finding made while planning, now reflected in the spec: the printed star badge is the **XP Reward**, not the Encounter number. The number comes from the panel's position, and the game adds a small marker.

## Phase 1 — Design

- [data-model.md](data-model.md): the Region Card and Panel models (`pair` replacing `code`), the Dragon Card, `vs.note`, the DeckStack additions and the pure geometry.
- [contracts/region-card-face.md](contracts/region-card-face.md): the whole card, the Enemy and Journey panels part by part, the reading strip and the Dragon Card.
- [contracts/left-column.md](contracts/left-column.md): one region, the layers, the per-phase settled look, the note's behaviour and its hooks into the sequence, and anchors.
- [quickstart.md](quickstart.md): commands, shots and the play-through.

## Risks

- **Numerals on the whole card at the 400 column** come out at about 22–24, at the limit. `ui_check` asserts them. If a shape fails, R9's fallback applies: first a thinner Deck margin, then the peek rising over the band.
- **The swap from the zoomed card to the landed panel** could jump by a pixel or a frame of creature pose. Both use `RegionPanel.parts` at the same rect, and `ui_check` compares the rects at the end of the zoom. The creature is held until the swap.
- **The note hides the Encounter** during Divert and Fuse, when the player may want its figures. The hold-to-lift gesture covers this. If playtests find the gesture undiscoverable, the fallback is to shrink `mode` notes to the face's lower half, over the reading strip.
- **The result note's outcome lines** depend on the pills' help text being full sentences. Any pill whose help is terse gets its sentence improved at the source (`preview_panel._pill` callers), not duplicated.
- **012 is uncommitted in the working tree.** This work builds on it directly, so 012 should be committed (or at least kept) before 013 starts, so the two diffs stay readable.

## Complexity Tracking

No violations to justify.
