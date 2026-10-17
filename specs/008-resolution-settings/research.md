# Research: Locked Aspect Ratio and Display Mode

## 1. How the 16:9 lock is made

- **Decision**: Change the project's stretch aspect from `expand` to `keep` (`display/window/stretch/aspect="keep"`, mode stays `canvas_items`, base size stays 1280×720). The engine then scales the whole interface evenly to the largest 16:9 rect that fits the window and letterboxes the rest.
- **Rationale**: With `keep`, the viewport is always exactly 1280×720 design units, whatever the window shape. Every screen is laid out once, at the size it was designed for. The engine maps pointer and touch input into the scaled rect itself (FR-003), and no screen code has to know about the borders.
- **Alternatives considered**:
  - *Keep `expand` and centre a 1280×720 "stage" Control in the bigger viewport.* With `expand`, the largest 16:9 rect in the viewport is always exactly 1280×720 units, so this works too, and the border could be any colour or even stone. It was rejected for now because it means reparenting the backdrop, screen host, flight layer and overlays under an offset node, and checking every global-position calculation (flights, popovers, inspect overlay). It stays as the fallback if the engine's bars turn out unacceptable (see 2).
  - *Snap the window itself to 16:9 while it's resized.* Rejected in clarification: the player may make the window any shape.

## 2. Border colour

- **Decision**: Use the engine's letterbox bars, which Godot 4's compatibility renderer clears to black. Black sits under the darkest stone tone and counts as the "plain dark colour" in FR-002.
- **Rationale**: Nothing to build. Godot 4 has no `black_bars_set_images` / `black_bars_set_margins` (probed on 4.7.2: both missing), so the bars can't be given a texture. The colour is checked by eye in the quickstart.
- **Alternatives considered**: The stage approach from 1, which can draw the bars in any colour. Use it only if black reads badly against the stone in the manual check.

## 3. What happens to the responsive layout solver

- **Decision**: Keep `LayoutSolver.solve` as it is; it now always gets `view = 1280×720`. Replace `Solver.view_for_window(window_px)` (which today returns the expanded view) with `Solver.stage_for_window(window_px) -> Rect2`: the 16:9 rect the play area occupies in window pixels. The view is always `T.DESIGN_MIN`.
- **Rationale**: The solver already handles 1280×720 (the `phone-16x9` row of the matrix), so no layout code changes. The matrix rows stay useful as window shapes: they now test bar placement, safe-area mapping and the size notice, not different layouts.
- **Alternatives considered**: Removing the solver's adaptive branches. That's dead-code clean-up with real regression risk and no benefit to this feature; out of scope.

## 4. Safe area, points per unit and the size notice under `keep`

- **Decision**:
  - `_safe_rect` maps the device safe area into view units through the stage rect: `((safe.position - stage.position) / k, safe.size / k) ∩ view`, where `k = stage.size.x / 1280`.
  - `_points_per_unit` uses the stage width: `stage.size.x / 1280 / screen_scale`.
  - The "Turn your device sideways / Widen the window" notice shows when the **window** is taller than it is wide, or the points per unit are below `LEGIBLE_SCALE`. Today the solver checks `view.y > view.x`, which can't happen any more, so the solver takes the window's upright flag as an input.
- **Rationale**: These are the only three places where `main.gd` mixes window pixels with view units. On notched phones the side bars (about 226 px on a 2532×1170 phone) are wider than the notch inset (141 px), so the safe rect usually becomes the whole view. The code stays for devices where it isn't.

## 5. Not re-laying out on every window drag

- **Decision**: `_on_resize` returns early when the solver inputs (view, safe rect, points per unit, hand count, set count) are unchanged.
- **Rationale**: Under `keep`, dragging a window edge changes nothing about the layout. Today every resize event also skips the running animation and closes the inspect overlay. With the early return, dragging the window or switching modes leaves the game untouched (FR-008).

## 6. Full screen

- **Decision**: `DisplayServer.WINDOW_MODE_FULLSCREEN` (value 3), Godot's borderless full screen. Exclusive full screen (value 4) isn't used.
- **Rationale**: This matches "full windowed screen" in the request, switches instantly, and doesn't change the monitor's display mode.
- **Switching back**: leaving full screen returns to `WINDOW_MODE_WINDOWED` at the starting size (7), centred. The window size isn't saved (spec, Key Entities).
- **Maximised windows**: a window maximised by the OS button or Win+Up stays mode "windowed". Only real full screen counts as "fullscreen".

## 7. Starting window size

- **Decision**: A pure function `WindowSizer.start_size(usable: Vector2i, decorations: Vector2i) -> Vector2i` picks the largest of 3840×2160, 2560×1440, 1920×1080 and 1280×720 for which `size + decorations` fits in `usable`. If none fits, it returns the largest 16:9 size that does. `usable` comes from `DisplayServer.screen_get_usable_rect(screen)` (taskbar excluded). `decorations` comes from `window_get_size_with_decorations() - window_get_size()` once the window exists.
- **Rationale**: This follows FR-006 exactly and can be unit-tested without a display. On Windows, a 1080p monitor's usable height is about 1032 px, so it opens at 1280×720; a 1440p monitor opens at 1920×1080; 4K opens at 2560×1440. Godot reports physical pixels on Windows (hiDPI is allowed by default), so OS scaling doesn't break the fit.
- **Flash at launch**: the window first opens at the project's 1280×720 override, then resizes in `main._ready`. To keep that brief, sizing and full screen happen before the first screen is shown. `display/window/size/initial_position_type` stays centred.

## 8. Minimum window size

- **Decision**: `DisplayServer.window_set_min_size(Vector2i(960, 540))`, clamped down to the starting size on very small monitors.
- **Rationale**: At 960 px wide with 150% OS scaling, the points per unit are 960 / 1280 / 1.5 = 0.5, above `LEGIBLE_SCALE` (0.41). Text stays readable down to the minimum, and the size notice almost never shows on desktop. This settles the "smallest window size" left open in clarification.

## 9. Keys

- **Decision**: A new input action `toggle_fullscreen` bound to F11 and Alt+Enter in `project.godot`, handled in `main._input` (not `_unhandled_input`) and marked handled there.
- **Rationale**: In `_unhandled_input`, a focused button would take Enter as `ui_accept` and press itself before the toggle saw it. Handling the action first keeps Alt+Enter from also pressing the focused button. The action is ignored on mobile and web.

## 10. Where the setting lives

- **Decision**: `Settings.window_mode` (`"windowed"` | `"fullscreen"`, default `"windowed"`), saved as `[display] window` in `user://settings.cfg` next to `motion` and `ground`. `MenuOverlay` gets a "Window" row of two `ChoiceTile`s (Windowed / Full screen) under Ground, shown only when `WindowSizer.applies()` (desktop: `OS.has_feature("pc")` and not `OS.has_feature("web")`).
- **Rationale**: This reuses the settings pattern and tile widget the menu already has. If the OS changes the mode (for example a full-screen window dragged off with Win+Shift+arrows), `main._on_resize` reads the mode back, updates the setting, saves it, and refreshes an open menu's tiles.

## 11. Desktop export preset

- **Decision**: Add a "Windows Desktop" preset to `export_presets.cfg`, with the same include filter (`data/*.json`) as the others, exporting to `build/windows/`.
- **Rationale**: The spec's Assumptions note that there's no desktop preset yet. The feature can be checked in the editor without it, but SC-004 is about the shipped game. macOS and Linux presets stay out of scope.
