# Implementation Plan: Landing Page and Dragon Selection

**Branch**: `007-landing-and-dragon-select` (work happens on `main`) | **Date**: 2026-10-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-landing-and-dragon-select/spec.md`

## Summary

Split today's title screen into two pages. The **landing page** keeps the carved lintel title, gains the new story subtitle, the fan-made disclaimer, three main buttons (How to Play, Records, Play) and small Settings / Glossary buttons. The **dragon page** (new screen) shows the four dragons as cards (still head, name, title, flavour line), the animated full-body crest of the chosen dragon, and the full stats of the chosen dragon only, plus Back and Continue. The subtitle and the four flavour lines live in a hand-editable data file, `data/flavor.json`, read at runtime; it ships with the draft text from the spec and the user rewrites it after the rest is built.

## Technical Context

**Language/Version**: GDScript, Godot 4 (`/opt/homebrew/bin/godot`)

**Primary Dependencies**: None beyond the engine; existing project modules `ui/theme/*`, `ui/widgets/choice_tile.gd`, `ui/widgets/dragon_stats.gd`, `ui/fx/creature.gd`, `ui/model/art.gd`, `engine/card_db.gd`

**Storage**: `data/flavor.json` (new, read-only at runtime, already covered by the export presets' `data/*.json` include filter); remembered choices stay in the existing `Settings.last_options`

**Testing**: `./tools/test.sh` — headless unit tests in `tests/` plus `tools/ui_check.gd`, which drives the real screens at every size in `LayoutSolver.MATRIX`; screenshots via `tools/shot.gd`

**Target Platform**: Desktop, Android, iOS, web (the existing export presets)

**Project Type**: Single Godot game project

**Performance Goals**: Choosing a dragon updates the stats in the same frame; no visible rebuild flicker of the cards

**Constraints**: Every layout size in the matrix with no clipping or overlap (FR-017); buttons at least `T.TAP_MIN`; reduced motion respected by `Creature`

**Scale/Scope**: Two screens (one reworked, one new), one small data file and loader, routing changes in `ui/main.gd`, updates to `tools/ui_check.gd` and `tools/shot.gd`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it defines no gates. Project conventions followed instead: screens are `Control`s with `setup` / `apply_layout` / `intent` signal, routed through `main.gd`'s `dispatch`; text in `##` doc comments matches the surrounding style; the UI check covers every new screen at every size.

Post-design re-check: no violations; no complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/007-landing-and-dragon-select/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── screens.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
data/
└── flavor.json                 # NEW: subtitle + one flavour line per dragon, hand-editable
ui/
├── main.gd                     # routing: landing ↔ dragon page ↔ rules; Escape / system back
├── model/
│   └── flavor.gd               # NEW: reads data/flavor.json, with fallbacks
├── screens/
│   ├── title_screen.gd         # becomes the landing page (no dragon choice)
│   ├── dragon_screen.gd        # NEW: four cards, chosen dragon's crest and stats, Back / Continue
│   └── rules_screen.gd         # unchanged; its back() already emits setup_dragon
└── widgets/
    └── choice_tile.gd          # already takes a texture emblem (head crop)
tests/
└── test_flavor.gd              # NEW: file present, every dragon has a line, fallbacks
tools/
├── ui_check.gd                 # landing → dragon page → rules walk, stats follow the choice
└── shot.gd                     # screenshots of both pages
```

**Structure Decision**: Keep the existing single-project layout. The landing page keeps the `TitleScreen` script name so every "to_title" path (ending, leave game, records back) lands there without change; the dragon choice moves to a new `DragonScreen`.

## Phases

- **Phase 0** — [research.md](research.md): decisions on file format, where the text lives, screen split, in-place refresh, routing.
- **Phase 1** — [data-model.md](data-model.md), [contracts/screens.md](contracts/screens.md), [quickstart.md](quickstart.md).
- **Ordering note for tasks**: implementation ships `data/flavor.json` with the spec's draft text. Rewriting that text is the user's own, final step, after everything else is built and checked; no task depends on the wording, and tests check only that the lines exist.

## Complexity Tracking

None.
