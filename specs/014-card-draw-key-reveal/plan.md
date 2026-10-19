# Implementation Plan: Drawn Cards and the Key Card at the Region Card's Size

**Branch**: `014-card-draw-key-reveal` | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/014-card-draw-key-reveal/spec.md`

## Summary

The Deck, the Key Card and the Hand are shown as one family of same-sized cards.

- **The draw** (R1). Each new Hand card starts at the whole top card's rect: the Region Card, or the Dragon Card in the Final Battle. It glides `position` and `size` together into its Hand place, face-up and at full alpha.
- **The Key Card** (R2) is drawn at the Region Card's size, its sides aligned. The room above the Region Card is solved from the Region Card's own height.
- **The reveal** (R3). `key_peek` rises, lights the Key Card's number (gold ring and wash), then lights the matching panel (gold rim, the rest dimmed), overlapping. It ends with the Key Card still up. `zoom_in` slides the Key Card down as it zooms, and the highlights fade by landing. The reveal is 1.6 s, within the 3 s limit.
- **The pile** (R4). The edges become rounded, card-stock-coloured card sides, slightly uneven, with a soft shadow. The only input is the count, so no Ether colour can show.
- **Rounded top cards** (R5). The Region Card and the Dragon Card outlines get the Mage Cards' corner radius (`0.075 w`) instead of the stone chamfer.

The engine, `ViewState`, the step order per action and every other motion are unchanged.

## Technical Context

**Language/Version**: GDScript, Godot 4.7 (pinned, via the `godot` shim)

**Primary Dependencies**: none new.
- Reused: `DeckStack`, `HandTray`, `CardFace` (its `_ring` and `glow`), `RegionCard.set_focus`, `StoneStyle`, `Sequencer` and `Animator`.

**Storage**: N/A.

**Testing**:
- `tools/test.sh` runs the headless `tests/run.gd` suites, then `tools/ui_check.gd` across `layout_solver.MATRIX`.
- `tools/design_shots.gd` takes the `deck` shots, now with `draw`, `reveal` and `pile`.

**Target Platform**: Desktop (Windows/macOS), web, Android and iOS phone and tablet shapes.

**Project Type**: Single-player card game (desktop / mobile app).

**Performance Goals**:
- 60 fps through a draw of up to 7 cards in flight, each resizing its `CardFace`.
- The pile is at most 8 rounded rects plus a 4-layer shadow.

**Constraints**:
- Text ≥ 22, including the whole card's numerals at the 400 column (R2's risk).
- Never colour alone: the number highlight is a ring plus a wash; the panel highlight is a rim plus the dimming of the rest.
- Reduced motion fades, with no travel or scaling.
- Landscape, 1280 × 720 minimum.
- No rules change.

**Scale/Scope**:
- No new widgets.
- About 10 changed source files: `deck_stack`, `hand_tray`, `card_face`, `region_card`, `dragon_card`, `stone_style`, `play_screen`, `animator`, `sequencer` and `tokens`.
- 4 changed tests: `test_deck_stack`, `test_sequencer`, `test_card_face_layout` and `test_region_card`.
- 2 tools: `ui_check` and `design_shots`.
- 2 superseded-in-part notes.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so there are no formal gates. The project's established conventions (as used in 012 and 013) apply:

| Convention | Status |
|---|---|
| The engine is the only judge of rules | Pass. No engine change. The lit panel is `_after.zoom`, which comes from `ViewState` |
| Pure models are tested headless | Pass. `card_rect` (solved peek), `key_rect`, `edge_rects`, `card_radius` and the `Sequencer` durations |
| The Sequencer is pure; steps replay to the after state | Pass. Only durations change, and `key_peek`/`zoom_in` still change no state |
| How a sequence ends never depends on animation | Pass. `deck.finish()` clears `_peek_up`, `lit` and the rim. `_finish` renders `_after` |
| Every screen is checked at every `MATRIX` shape | Pass. `ui_check` additions (R7) |
| Tap ≥ 88, text ≥ 22 | Pass by assertion. R2's smaller Region Card on height-limited shapes is covered by the existing numeral check, with a fallback |
| Reduced motion respected | Pass. The draw snaps and fades. The reveal fades in raised, the highlights fade, and the Key Card fades out with the cross-fade |
| Never colour alone | Pass. See Constraints |

Re-checked after Phase 1: no violations.

## Project Structure

### Documentation (this feature)

```text
specs/014-card-draw-key-reveal/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0: R1–R8
├── data-model.md        # Phase 1: tokens, pure geometry, widget changes, reveal states
├── quickstart.md        # Phase 1: checks, shots, play-through
├── contracts/
│   ├── deck-motion.md   # The draw and the reveal: steps, beats, reduced motion
│   └── deck-pile.md     # The pile's drawing and rules
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
ui/widgets/
├── deck_stack.gd        # top_rect, key_rect, solved card_rect, edge_rects/card_radius, pile drawing, peek ends raised, zoom_in fall, reveal_beat (R1–R4)
├── hand_tray.gd         # arrive_from: Rect2; fresh cards start there at alpha 1 and glide over DRAW_FLY (R1)
├── card_face.gd         # lit: the encounter ring and gold wash at an amount (R3)
├── region_card.gd       # set_rim; rounded outline (R3, R5)
└── dragon_card.gd       # Rounded outline (R5)
ui/theme/
├── stone_style.gd       # round_radius (R5)
└── tokens.gd            # DRAW_FLY, KEY_LIT, PANEL_LIT, KEY_PEEK, CARD_EDGE, CARD_EDGE_LINE; PEEK_HOLD removed
ui/screens/play_screen.gd   # render() passes a Rect2; no deck.set_card_size (R1, R2)
ui/fx/animator.gd        # draw from deck.top_rect(); peek gets _after.zoom (R1, R3)
ui/model/sequencer.gd    # key_peek and draw durations (R1, R3)
tests/
├── test_deck_stack.gd   # card_rect solve, key_rect alignment, edge_rects, card_radius
├── test_sequencer.gd    # reveal ≤ 3 s, key_peek = KEY_PEEK, draw duration
├── test_card_face_layout.gd  # lit 0/1
└── test_region_card.gd  # rim on the focused panel only
tools/
├── ui_check.gd          # draw start/end rects and ratio, Key Card alignment, beat order
└── design_shots.gd      # draw, reveal, pile shots
specs/012-deck-region-card/contracts/reveal-sequence.md     # superseded-in-part note
specs/013-physical-region-card/contracts/left-column.md     # edges per 014 note
```

**Structure Decision**: The existing single Godot project layout. Every change lands in the file that already owns that concern. No new files are needed outside the spec.

## Phase 0 — Research

See [research.md](research.md). There are no open NEEDS CLARIFICATION items. Decisions:

- **R1**: the draw starts at `top_rect()` and tweens `size` with `position`.
- **R2**: the Key Card at the Region Card's size, with `card_rect`'s room solved in closed form.
- **R3**: `key_peek` ends raised with two overlapping highlights. `zoom_in` takes over the fall.
- **R4**: the pile as rounded, card-stock edges with fixed jitter and a soft shadow, drawn from the count only.
- **R5**: a rounded outline for the Region Card and the Dragon Card.
- **R6**: the Final Battle and the edge cases.
- **R7**: tests and tools.
- **R8**: documents.

Two findings made while planning:
- **The rounded corners.** The Region Card and Dragon Card are chamfered today, so meeting FR-016 means rounding them too (R5).
- **The size of the rise.** The room for the Key Card's rise was reserved from the Hand's card size. It must now be derived from the Region Card itself (R2).

## Phase 1 — Design

- [data-model.md](data-model.md): the tokens, the pure geometry, the instance and widget changes, and the reveal's states.
- [contracts/deck-motion.md](contracts/deck-motion.md): the steps and durations, the draw, and the reveal's beats with reduced motion.
- [contracts/deck-pile.md](contracts/deck-pile.md): the pile's layers and rules.
- [quickstart.md](quickstart.md): commands, shots and the play-through.

## Risks

- **A smaller Region Card on height-limited shapes.** The larger Key Card needs more room above it, about 0.1 h. `ui_check`'s whole-card numeral assertion catches a shortfall. The fallback is a deeper dip (R2).
- **Resizing up to 7 `CardFace`s every frame** during a draw. Each redraws its ink layer per size change. If a phone drops frames, the fallback is to tween `scale` for the first 70% of the flight and settle `size` at the end. The text is too small to read mid-flight anyway.
- **Rounding `StoneStyle`'s bevel.** The chamfer's bevel runs are straight segments. A rounded variant needs arc runs. If the bevel looks wrong rounded, the fallback for the top cards is a `StyleBoxFlat` rounded outline in the stone colours, without the bevel.
- **The gold rim versus 013's number marker.** The rim must not cover the panel's number marker or XP star. It is drawn on the panel's frame edge, outside the badges.

## Complexity Tracking

No violations to justify.
