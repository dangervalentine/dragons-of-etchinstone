# Implementation Plan: Locked Aspect Ratio and Display Mode

**Branch**: `008-resolution-settings` (spec folder; git is still on `003-dragon-art`) | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-resolution-settings/spec.md`

## Summary

Lock the play area to 16:9 by switching the project's stretch aspect from `expand` to `keep`. The viewport is then always 1280×720 design units, the engine scales it evenly and letterboxes the rest in black, and input mapping comes for free. `main.gd`'s three window-to-view conversions (safe area, points per unit, the upright notice) move to a new stage rect. On desktop, a small `WindowSizer` module opens the game as a 16:9 window sized to the monitor, allows free resize and maximise with a 960×540 minimum, and toggles borderless full screen from a new Window row in Settings or with F11 / Alt+Enter. The choice is saved with the other settings. A Windows export preset is added.

**Amendment (mobile fills the screen)**: the Android and iOS apps override the aspect to `expand` (`window/stretch/aspect.mobile`), so phones grow wider and tablets taller, up to `T.DESIGN_MAX` (1760×990), with the layout centred past that. `stage_for_window` and `safe_in_view` take the real view size, so `main.gd` has one code path for both modes. See research §12.

## Technical Context

**Language/Version**: GDScript, Godot 4.7.2 (`godot` shim in `~/.local/bin`)

**Primary Dependencies**: None beyond the engine. Touches `ui/main.gd`, `ui/model/settings.gd`, `ui/model/layout_solver.gd`, `ui/overlays/menu_overlay.gd`, `project.godot`, `export_presets.cfg`

**Storage**: `user://settings.cfg`, one new key `[display] window`

**Testing**: `./tools/test.sh` (headless unit tests in `tests/` plus `tools/ui_check.gd` over `LayoutSolver.MATRIX`). Window behaviour checked by hand per [quickstart.md](quickstart.md), since headless runs have no real window.

**Target Platform**: Windows desktop (new preset) and Web keep the aspect lock; Android and iOS fill the screen within the clamp (amendment). None but desktop get the display setting

**Project Type**: Single Godot game project

**Performance Goals**: Mode switch visible within 1 s (SC-002). Window drags cause no relayout.

**Constraints**: No change to any screen's layout code. On desktop and web the layout is always the 1280×720 one, scaled up on larger windows. On mobile it gets the extra room up to `T.DESIGN_MAX` (amendment).

**Scale/Scope**: One new module (~80 lines), one new test file, edits to five existing files and two config files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is still the unfilled template, so it defines no gates. These project conventions are followed instead: settings follow the `motion` / `ground` pattern in `Settings`; menu choices use `ChoiceTile`; pure logic lives in `ui/model/` with headless tests; `##` doc comments match the surrounding style.

Post-design re-check: no violations; no complexity tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/008-resolution-settings/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── display.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
project.godot                   # stretch aspect keep; toggle_fullscreen action (F11, Alt+Enter)
export_presets.cfg              # NEW preset: Windows Desktop → build/windows/
ui/
├── main.gd                     # apply saved mode at start; stage-based safe area / points / notice;
│                               # early return in _on_resize; _input handles toggle_fullscreen;
│                               # follow OS mode changes
├── model/
│   ├── window_sizer.gd         # NEW: applies, start_size, min_size, apply, toggle, current_mode
│   ├── settings.gd             # window_mode, load/save under [display] window
│   └── layout_solver.gd        # stage_for_window replaces view_for_window; solve(..., upright)
└── overlays/
    └── menu_overlay.gd         # Window row (Windowed / Full screen), desktop only
tests/
├── test_window_sizer.gd        # NEW: start/min size across monitors
└── test_layout_solver.gd       # stage_for_window per matrix row; upright → undersized
tools/
├── ui_check.gd                 # expects plan.view == DESIGN_MIN; Window row on desktop
├── shot.gd                     # uses stage_for_window
└── space_audit.gd              # uses stage_for_window
```

**Structure Decision**: Keep the single-project layout. Window logic goes in its own `ui/model/window_sizer.gd`, so `main.gd` only calls it, and the size rules can be tested headless.

## Risks

- **Bar colour**: Godot 4 can't texture the letterbox, so it's black. If black looks wrong against the stone in quickstart step 11, fall back to the stage approach in research §1.
- **Tablets and tall phones**: settled by the amendment. They fill the screen (FR-012). Every screen added since the lock (the 009 hand layout among them) was only checked at 1280×720, so the phone and tablet rows of `tools/ui_check.gd` are the check that they still fit when grown.
- **Launch flash**: the window opens at 1280×720 and then resizes; kept short by sizing before the first screen is shown.

## Phases

- **Phase 0**: [research.md](research.md). How the lock works, border colour, the solver, safe area, early return on resize, full screen, starting size, minimum size, keys, the setting, the export preset.
- **Phase 1**: [data-model.md](data-model.md), [contracts/display.md](contracts/display.md), [quickstart.md](quickstart.md).
- **Phase 2**: `/speckit-tasks`.
