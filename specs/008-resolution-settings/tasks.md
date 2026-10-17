---

description: "Task list for feature 008: locked aspect ratio and display mode"
---

# Tasks: Locked Aspect Ratio and Display Mode

**Input**: Design documents from `specs/008-resolution-settings/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/display.md](contracts/display.md), [quickstart.md](quickstart.md)

**Tests**: Included. The project keeps headless tests in `tests/` and `tools/ui_check.gd`, and the plan names the test files. Run everything with `./tools/test.sh` (Git Bash).

**Format**: `- [ ] T### [P?] [US?] description with file path`. `[P]` means the task touches a different file from the other tasks it's marked with and doesn't depend on unfinished work.

---

## Phase 1: Setup

- [X] T001 In `project.godot` under `[display]`, change `window/stretch/aspect="expand"` to `window/stretch/aspect="keep"`. Leave `viewport_width/height` (1280×720), the window overrides and `stretch/mode="canvas_items"` as they are.

---

## Phase 2: Foundational (blocks both stories)

- [X] T002 In `ui/model/layout_solver.gd`, replace `static func view_for_window(window_px: Vector2) -> Vector2` with `static func stage_for_window(window_px: Vector2) -> Rect2`. It returns the 16:9 rect the play area takes in window pixels: `s = min(window_px.x / T.DESIGN_MIN.x, window_px.y / T.DESIGN_MIN.y)`, `size = T.DESIGN_MIN * s`, `position = (window_px - size) / 2`. Rewrite its `##` comment ("The part of a window the 16:9 play area fills, in window pixels, as the project's `keep` stretch places it; the rest is letterbox."). Update the MATRIX comment to say the rows are now window shapes the play area is letterboxed into.
- [X] T003 In `ui/model/layout_solver.gd`, add a trailing parameter `upright := false` to `solve(...)` and change the result's `"undersized"` to `upright or points_per_unit < LEGIBLE_SCALE` (the view is always 1280×720 now, so `view.y > view.x` can't be true).

**Checkpoint**: The solver compiles. The callers updated in US1 still reference `view_for_window` until T005–T010 are done.

---

## Phase 3: User Story 1 — The layout always keeps its intended shape (P1) 🎯 MVP

**Goal**: Every screen shows the 1280×720 layout scaled evenly into any window or screen, with black bars filling the rest, and input lines up with what's drawn.

**Independent test**: `./tools/test.sh` passes. Running the game in the editor and dragging the window to wide, tall and square shapes keeps every screen 16:9 with bars, and clicks land on cards and buttons.

### Tests for User Story 1

- [X] T004 [P] [US1] In `tests/test_layout_solver.gd`:
  - Replace `test_design_sizes` with `test_stage_for_window`. It checks `stage_for_window(Vector2(1280,720)) == Rect2(0,0,1280,720)`; 1440×900 → `Rect2(0, 45, 1440, 810)` (bars top and bottom); 3840×1080 → `Rect2(960, 0, 1920, 1080)` (bars at the sides); 720×1280 → `Rect2(0, 437.5, 720, 405)`; and, for every `Solver.MATRIX` row, that the stage's width/height is 16/9 (within 0.01) and it lies inside the window.
  - Change `_plan` and `_safe` to use `view := T.DESIGN_MIN` and map the row's pixel insets through the stage: `stage = stage_for_window(m[0])`, `k = stage.size.x / T.DESIGN_MIN.x`, safe in pixels = `Rect2(Vector2(inset[0], inset[1]), m[0] - Vector2(inset[0] + inset[2], inset[1] + inset[3]))`, then in view units `Rect2((px.position - stage.position) / k, px.size / k)` and intersected with `Rect2(Vector2.ZERO, T.DESIGN_MIN)`. Pass points per unit `m[2] * k` to `solve` (`m[2]` is points per pixel), and `upright = m[0].y > m[0].x`.
  - Replace every other `Solver.view_for_window(m[0])` in the file with `T.DESIGN_MIN`.
  - Add `test_upright_is_undersized`: `solve(T.DESIGN_MIN, Rect2(Vector2.ZERO, T.DESIGN_MIN), 4, 1, 0.5, 0.0, T.ENCOUNTER_MIN, true).undersized == true`, and the same call with `false` gives `false`.

### Implementation for User Story 1

- [X] T005 [US1] In `ui/main.gd`, add `## For tools: pretend the window has this size in pixels.` `var window_override := Vector2()` next to `safe_override`, and a helper `func _window_px() -> Vector2` returning `window_override` if set, otherwise `Vector2(DisplayServer.window_get_size())`.
- [X] T006 [US1] In `ui/main.gd` `_safe_rect(view)`, after `clear_corners`, map the device safe area through the stage instead of `view.x / window.x`: `var stage := Solver.stage_for_window(window)`, `var k := stage.size.x / view.x`, return `Rect2((safe.position - stage.position) / k, safe.size / k).intersection(Rect2(Vector2.ZERO, view))`. Use `_window_px()` for `window`. Update the `##` comment to say the letterbox is left out, since it's outside the view.
- [X] T007 [US1] In `ui/main.gd` `_points_per_unit(view)`, use `Solver.stage_for_window(_window_px()).size.x / view.x / scale` in place of `window.x / view.x / scale`.
- [X] T008 [US1] In `ui/main.gd` `_on_resize()`:
  - Compute `upright := _window_px().y > _window_px().x` and pass it as the new last argument to `Solver.solve` (T003). The middle defaults stay: `preview_needed` 0.0, `encounter_min` `T.ENCOUNTER_MIN`.
  - Before `animator.skip()`, build `var key := [view, safe, ppu, upright, count, sets]`. If `key == _layout_key`, call only `_update_notice()` and return.
  - Add `var _layout_key := []` with a `##` comment ("What the layout was last made for; a window drag that changes none of it changes nothing").
  - Store `_layout_key = key` after solving.
- [X] T009 [P] [US1] In `tools/ui_check.gd` `_open(name)`:
  - Size `host` to `Vector2i(T.DESIGN_MIN)`, not `view_for_window(m[0])`. Add `const T = preload("res://ui/theme/tokens.gd")` if it isn't already there.
  - Set `ui.window_override = m[0]` before `host.add_child(ui)`.
  - Build `safe_override` by mapping the (flipped where needed) pixel insets through `Solver.stage_for_window(m[0])`, as in T004, intersected with the view.
  - In `_check_space`, replace the `ui.play.plan.view != Solver.view_for_window(...)` guard with `ui.play.plan.view != T.DESIGN_MIN`.
  - Add a check in `_open`: `_ok(ui.plan.view == T.DESIGN_MIN, "%s: the view is the design size" % name)`.
  - Keep the existing undersized/notice checks: `upright-browser` must still be undersized and show the notice, and no other row may be.
- [X] T010 [P] [US1] In `tools/shot.gd` `_size(name)` and `tools/space_audit.gd` `_open(name)`, size the window and `root` to `Vector2i(T.DESIGN_MIN)` (the screenshot is the viewport, which is always the design size now). Set `ui.window_override = m[0]`. Build `safe_override` through `Solver.stage_for_window(m[0])` as in T009. In `tools/shot.gd`, drop the `upright-browser` special case that forces a 720×1280 view.
- [X] T011 [US1] Run `./tools/test.sh` and fix failures until it reports 0 failed and `ui check` passes.

**Checkpoint**: The aspect lock works on its own. In the editor, dragging the window to any shape keeps 16:9 with black bars (quickstart rows 2, 3, 10, 11).

---

## Phase 4: User Story 2 — Opens in a well-sized window and can go full screen (P2)

**Goal**: On desktop, the game opens as a 16:9 window sized to the monitor, resizes freely down to 960×540, and toggles borderless full screen from Settings, F11 or Alt+Enter, remembering the mode.

**Independent test**: `./tools/test.sh` passes, and quickstart rows 1 and 4–9 pass on Windows.

### Tests for User Story 2

- [X] T012 [P] [US2] Create `tests/test_window_sizer.gd` (`extends "res://tests/base.gd"`, `const WindowSizer = preload("res://ui/model/window_sizer.gd")`). With decorations `Vector2i(16, 39)`, check that `start_size` gives:

  | Usable area | Result |
  |-------------|--------|
  | 1920×1032 (1080p minus taskbar) | 1280×720 |
  | 2560×1392 | 1920×1080 |
  | 3840×2112 | 2560×1440 |
  | 7680×4272 | 3840×2160 |
  | 1366×728 | `Vector2i(1224, 689)`. 1280×720 doesn't fit (720 + 39 > 728), so the room is 1350×689: height 689, width `floor(689 * 16 / 9) = 1224`. |
  | 1024×600 | Every result has `x / y` within 0.01 of 16/9 |

  Also check `min_size(Vector2i(1280, 720)) == Vector2i(960, 540)` and `min_size(Vector2i(800, 450)) == Vector2i(800, 450)`.
- [X] T013 [P] [US2] Create `tests/test_settings_window.gd`. It sets `Settings.window_mode = "fullscreen"`, calls `save_all()`, sets `window_mode = "windowed"`, calls `load_all()`, and checks the value is `"fullscreen"`. Then it writes `[display] window="huge"` with a `ConfigFile` to `Settings.PATH`, calls `load_all()`, and checks the value is `"windowed"`. Save and restore the real file's contents around the test (read `Settings.PATH` first if it exists; write it back, or remove it, at the end) so the developer's settings survive.

### Implementation for User Story 2

- [X] T014 [P] [US2] In `ui/model/settings.gd`:
  - Add `const WINDOW := ["windowed", "fullscreen"]` and `static var window_mode := "windowed"`.
  - In `load_all()`, add `var w = cfg.get_value("display", "window", "windowed")` and `window_mode = w if WINDOW.has(w) else "windowed"`.
  - In `save_all()`, add `cfg.set_value("display", "window", window_mode)`.
  - Extend the file's top `##` comment to mention the window mode.
- [X] T015 [US2] Create `ui/model/window_sizer.gd` (`extends RefCounted`, top `##` comment: "How the game's window opens on a desktop: a 16:9 window sized to the monitor, or borderless full screen. Not used on phones or the web."). Use `const Settings = preload("res://ui/model/settings.gd")`, `const SIZES := [Vector2i(3840, 2160), Vector2i(2560, 1440), Vector2i(1920, 1080), Vector2i(1280, 720)]` and `const MIN := Vector2i(960, 540)`. Static functions:
  - `applies() -> bool`: `OS.has_feature("pc") and not OS.has_feature("web")`.
  - `start_size(usable: Vector2i, decorations: Vector2i) -> Vector2i`: the first of `SIZES` with `size + decorations <= usable` on both axes. Otherwise `room = usable - decorations`, `h = min(room.y, floori(room.x * 9 / 16.0))`, and return `Vector2i(floori(h * 16 / 9.0), h)`.
  - `min_size(start: Vector2i) -> Vector2i`: `Vector2i(mini(MIN.x, start.x), mini(MIN.y, start.y))`.
  - `current_mode() -> String`: `"fullscreen"` if `DisplayServer.window_get_mode()` is `WINDOW_MODE_FULLSCREEN` or `WINDOW_MODE_EXCLUSIVE_FULLSCREEN`, else `"windowed"`.
  - `apply(mode: String) -> void`: return if not `applies()`. For `"fullscreen"`, `DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)`. Otherwise:
    1. Set `WINDOW_MODE_WINDOWED`.
    2. Get `screen := DisplayServer.window_get_current_screen()`, `usable := DisplayServer.screen_get_usable_rect(screen)` and `deco := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()`.
    3. Compute `size := start_size(usable.size, deco)`, then call `window_set_min_size(min_size(size))` and `window_set_size(size)`.
    4. Centre it: `window_set_position(usable.position + (usable.size - size - deco) / 2 + Vector2i(deco.x / 2, deco.y - deco.x / 2))`, so the frame, not just the client area, is centred and the title bar stays on screen.
  - `toggle() -> String`: `Settings.window_mode = "windowed" if current_mode() == "fullscreen" else "fullscreen"`, `apply(Settings.window_mode)`, `Settings.save_all()`, return the new mode.
- [X] T016 [US2] In `project.godot`, add an `[input]` section (after `[display]`) with an action `toggle_fullscreen` bound to F11 (`keycode` 4194342) and Enter with `alt_pressed=true` (`keycode` 4194309). Easiest: add it in the editor's Input Map and save, or copy the serialized `InputEventKey` form the editor writes. Also add `window/size/initial_position_type=1` (centre of the primary screen) under `[display]` if it isn't set.
- [X] T017 [US2] In `ui/main.gd`:
  - Add `const WindowSizer = preload("res://ui/model/window_sizer.gd")` with the other preloads.
  - In `_ready()`, right after `Settings.load_all()`: `if WindowSizer.applies(): WindowSizer.apply(Settings.window_mode)`.
  - At the very top of `_input(event)`, before the animator-skip block: `if WindowSizer.applies() and event.is_action_pressed("toggle_fullscreen") and not event.is_echo():` call `WindowSizer.toggle()`, `_refresh_menu()`, `get_viewport().set_input_as_handled()`, and `return`. Doing this before `ui_accept` reaches a focused button keeps Alt+Enter from pressing it; doing it before the skip keeps F11 from also skipping a sequence.
- [X] T018 [US2] In `ui/main.gd` `_on_resize()`, at the top: `if WindowSizer.applies() and WindowSizer.current_mode() != Settings.window_mode:` set `Settings.window_mode = WindowSizer.current_mode()`, call `Settings.save_all()` and `_refresh_menu()`. This follows the OS when it takes the window out of full screen. Add `func _refresh_menu() -> void`, which calls `_refresh()` on every child of `_overlays` whose script is `MenuOverlay`.
- [X] T019 [US2] In `ui/overlays/menu_overlay.gd`:
  - Add `const WindowSizer = preload("res://ui/model/window_sizer.gd")` and `var _window_tiles := {}`.
  - In `setup()`, after the Ground row, add this when `WindowSizer.applies()`: a `UI.label("Window", ["body_bold", T.BODY[1]], T.INK)`, then a `UI.hbox(T.S)` row with `custom_minimum_size.y = T.TAP_MIN` holding two `ChoiceTile.make(...)` tiles: `["windowed", "Windowed", "Resizable"]` and `["fullscreen", "Full screen", "F11"]`. Each tile's `pressed` connects to `_set_window.bind(key)`, and the tiles are stored in `_window_tiles`.
  - Add `func _set_window(value: String) -> void`, which returns if `value == Settings.window_mode`, otherwise calls `WindowSizer.toggle()` and `_refresh()`.
  - In `_refresh()`, mark `_window_tiles[key].selected = Settings.window_mode == key`.
  - Update the file's top `##` comment: "The settings are Motion, the Ground the board stands on and, on a desktop, the Window."
- [X] T020 [US2] In `tools/ui_check.gd`, where the settings menu is opened (`ui.dispatch({"type": "settings"})`, around line 307): check that the open `MenuOverlay` has `_window_tiles.size() == 2` when `WindowSizer.applies()`, and `0` otherwise, and that exactly one tile is `selected`. Don't press the tiles: a headless window can't change mode.
- [X] T021 [US2] Run `./tools/test.sh` and fix failures until it reports 0 failed and `ui check` passes.

**Checkpoint**: In the editor (F5), quickstart rows 1 and 4–9 behave as described.

---

## Phase 5: Polish & cross-cutting

- [X] T022 [P] In `export_presets.cfg`, add a `[preset.4]` / `[preset.4.options]` "Windows Desktop" preset: `platform="Windows Desktop"`, `runnable=true`, the same `export_filter`, `include_filter="data/*.json, art/creatures/*.json"` and `exclude_filter` as the Web preset, `export_path="build/windows/dragons-of-etchinstone.exe"`, and `application/product_name="Dragons of Etchinstone"`. Easiest: add it in the editor's Export dialog and save, then check the diff. Export once with `godot --headless --path . --export-release "Windows Desktop" build/windows/dragons-of-etchinstone.exe` to confirm the templates are present.
- [X] T023 [P] Update `ui/overlays/size_notice.gd`'s top `##` comment: the notice now shows when the window is taller than it is wide (the play area would be a thin letterboxed strip) or too small to read.
- [ ] T024 Run the whole quickstart by hand on Windows ([quickstart.md](quickstart.md) rows 1–11), using the exported build from T022. Report row 11 (whether black bars look right against the stone) to the user. If they don't, the fallback is the stage approach in research §1. Don't start it without the user agreeing.
- [ ] T025 Run `./tools/test.sh` one last time and `godot --headless --path . -s tools/shot.gd` to refresh screenshots; check that the screens look the same as before at 1280×720.

---

## Dependencies & execution order

- **Setup (T001)** → **Foundational (T002–T003)** → **US1 (T004–T011)** → **US2 (T012–T021)** → **Polish (T022–T025)**.
- US2 depends on US1 only through `main._on_resize` (T008 then T018 edit the same function) and the `tools/ui_check.gd` edits (T009 then T020). Its logic (`window_sizer.gd`, settings, menu) is independent and could start earlier, but stories are meant to land in order.
- Within US1: T004, T009 and T010 are separate files and can run in parallel once T002–T003 are done. T005 → T006 → T007 → T008 are sequential (same file).
- Within US2: T012, T013 and T014 can run in parallel. T015 needs T014. T017–T018 need T015 and T016. T019 needs T015. T020 needs T019.

### Parallel examples

```text
US1: T004 (tests/test_layout_solver.gd) ‖ T009 (tools/ui_check.gd) ‖ T010 (tools/shot.gd, tools/space_audit.gd)
US2: T012 (tests/test_window_sizer.gd) ‖ T013 (tests/test_settings_window.gd) ‖ T014 (ui/model/settings.gd)
Polish: T022 (export_presets.cfg) ‖ T023 (ui/overlays/size_notice.gd)
```

## Implementation strategy

1. **MVP = US1** (T001–T011): the aspect lock alone gives the main promise of the spec on every platform, with no new setting. Stop and check it in the editor.
2. **US2** (T012–T021): the window opening at the right size, full screen, keys and the menu row.
3. **Polish** (T022–T025): the Windows build, comments, and the manual quickstart, including the bar-colour check.

Open decision to settle before shipping to mobile (plan, Risks): settled by the amendment below. Mobile fills the screen.

---

## Phase 6: Amendment, mobile fills the screen (US3)

**Goal**: the Android and iOS apps fill the screen within the 1760×990 clamp (FR-012, FR-013); desktop and web stay locked. See research §12.

- [X] T026 [US3] In `project.godot` `[display]`, add `window/stretch/aspect.mobile="expand"` under `window/stretch/aspect="keep"`.
- [X] T027 [US3] In `ui/model/layout_solver.gd`:
  - Add `view_for_window(window_px: Vector2, fills: bool) -> Vector2`: `T.DESIGN_MIN` when not `fills`; otherwise `window_px / min(window_px.x / 1280, window_px.y / 720)`.
  - Give `stage_for_window` and `safe_in_view` a `view := T.DESIGN_MIN` parameter: the scale is `min(window / view)`, the stage is `view * s` centred, and the safe area is intersected with `Rect2(0, view)`.
  - Give each `MATRIX` row a fifth entry, `fills`: true for `phone-16x9`, `phone-tall`, `phone-tall-flipped`, `phone-small` and `tablet`. Add `matrix_view(name)`, and have `matrix_safe` map through it.
  - Update the file's and `MATRIX`'s `##` comments.
- [X] T028 [US3] In `ui/main.gd`, pass `view` to `Solver.safe_in_view` in `_safe_rect` and to `Solver.stage_for_window` in `_points_per_unit`.
- [X] T029 [P] [US3] In `tests/test_layout_solver.gd`: build `_plan` from `matrix_view` and its stage; test `view_for_window` both ways; `stage_for_window` covering the window when it fills; a filling notched phone's safe area keeping clear of the notch on each side; the tablet's home bar now inside the view; content clamped and centred past `T.DESIGN_MAX`; every region inside the safe area on each filling row.
- [X] T030 [P] [US3] In `tools/ui_check.gd`, `tools/shot.gd` and `tools/space_audit.gd`, size the viewport to `Solver.matrix_view(name)` and expect `plan.view` to match it.
- [X] T031 [US3] Run `./tools/test.sh` and fix failures until it reports 0 failed and `ui check` passes, then refresh the phone and tablet screenshots with `tools/shot.gd` and look at them.
- [ ] T032 [US3] Quickstart rows 12–15 on a real phone and tablet.
