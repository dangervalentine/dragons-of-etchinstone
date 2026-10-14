# Implementation Plan: Two-Step Game Setup

**Branch**: `002-split-game-setup` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-split-game-setup/spec.md`

## Summary

Split the single title screen into two setup steps. The first step is the title screen, which now offers only the dragon choice (with title, Settings, Glossary and credits) and a Continue button. The second is a new rules screen with difficulty and alternate rules together, a reminder of the chosen dragon, Back and Set out. `main.gd` carries the options between the two in `menu` through two new intents. It also gains handling for Android system back and for Escape, which both return from the rules screen to the dragon screen. Nothing is saved until the player sets out, as today.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (GL Compatibility renderer)

**Primary Dependencies**: Godot engine only; the project's own `ui/theme`, `ui/widgets/choice_tile.gd` and `ui/fx/creature.gd`

**Storage**: Existing `Settings.last_options` (user settings file), unchanged

**Testing**: `./tools/test.sh`: headless unit suite (`tests/run.gd`) and the UI check (`tools/ui_check.gd`), which drives the real screens at every size in `Solver.MATRIX`

**Target Platform**: Web, Android, iOS (landscape); desktop for development

**Project Type**: Mobile/web game (single Godot project)

**Performance Goals**: Screen change uses the existing 0.25 s fade (`T.BASE`); no frame drops beyond today's title screen

**Constraints**: Fit within the safe content rect at every matrix size with no scrolling and no clipped text; tap targets ≥ `T.TAP_MIN` (88 design units); reduced-motion setting respected through `_switch()`

**Scale/Scope**: 1 screen reworked, 1 screen added, ~6 dispatch/input lines in `main.gd`, UI check and design shots extended

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it has no ratified principles to gate against. **PASS (no gates defined).** The plan follows the conventions the codebase already shows:
- Screens emit typed intents and only `main.dispatch()` acts on them.
- The rules engine (`engine/`) is untouched.
- Interface behaviour is verified through the UI check at every layout size.

Post-design re-check: still PASS. The design adds no new layers, dependencies or storage.

## Project Structure

### Documentation (this feature)

```text
specs/002-split-game-setup/
├── plan.md              # This file
├── research.md          # Phase 0: design decisions R1–R7
├── data-model.md        # Phase 1: options dictionary and setup flow
├── quickstart.md        # Phase 1: how to validate
├── contracts/
│   └── setup-screens.md # Phase 1: screen contents, intents, back/escape
└── tasks.md             # Phase 2 (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
ui/
├── main.gd                  # + setup_rules / setup_dragon intents, _show_rules(),
│                            #   Escape on rules screen, Android go-back handling
├── screens/
│   ├── title_screen.gd      # reworked: dragon choice + Continue only
│   └── rules_screen.gd      # NEW: chosen dragon, difficulty, alternate rules,
│                            #   Back, Set out
└── widgets/
    └── choice_tile.gd       # unchanged (reused by both screens)

tools/
├── ui_check.gd              # inspect both setup screens; round-trip and start checks
└── design_shots.gd          # + "rules" shot
```

**Structure Decision**: Single Godot project, existing layout. The new screen sits beside the other screens in `ui/screens/`, and `main.gd` stays the only place that switches screens.

## Complexity Tracking

No violations to justify.
