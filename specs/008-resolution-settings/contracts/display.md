# Contract: Display behaviour

What the player, the tests and the tools can rely on.

## Play area

- The viewport is always 1280×720 design units (`get_viewport_rect().size == T.DESIGN_MIN`) on every platform and window shape.
- The play area is centred in the window and scaled evenly. Leftover space is a black letterbox; nothing is drawn there.
- Pointer and touch positions arrive in view units, already mapped by the engine.

## Keys (desktop only)

| Input | Effect |
|-------|--------|
| F11 | Toggle Windowed ↔ Full screen |
| Alt+Enter | Toggle Windowed ↔ Full screen. Doesn't press the focused button. |

Both work on every screen and with any overlay open. Input action: `toggle_fullscreen`.

## Settings menu (desktop only)

Under **Ground**, a **Window** row with two choice tiles:

| Tile | Selected when | Pressing it |
|------|---------------|-------------|
| Windowed | `Settings.window_mode == "windowed"` | Leaves full screen if needed, saves |
| Full screen | `Settings.window_mode == "fullscreen"` | Enters full screen, saves |

The row is absent on mobile and web (`WindowSizer.applies() == false`). It's present both from the title screen and in the in-game menu. The tiles update if the mode changes by key or by the OS while the menu is open.

## Window

- First launch, or after leaving full screen: windowed at `WindowSizer.start_size`, centred on the current monitor.
- Launch with the saved mode `"fullscreen"`: opens full screen on the current monitor.
- Freely resizable and maximisable. Minimum size `min(960×540, start size)`.
- Resizing, maximising or switching modes doesn't lose game state, doesn't skip a running animation and doesn't close overlays, because the layout inputs don't change.

## Module surface

`ui/model/window_sizer.gd` (new, `RefCounted`, static):

| Function | Purpose |
|----------|---------|
| `applies() -> bool` | Desktop build (not mobile, not web) |
| `start_size(usable: Vector2i, decorations: Vector2i) -> Vector2i` | Pure; FR-006 |
| `min_size(start: Vector2i) -> Vector2i` | Pure; `min(960×540, start)` |
| `apply(mode: String) -> void` | Puts the window into `mode` (sizes and centres when windowed) |
| `toggle() -> String` | Flips `Settings.window_mode`, applies it, saves, and returns the new mode |
| `current_mode() -> String` | Reads the window's real mode as `"windowed"` / `"fullscreen"` |

`ui/model/layout_solver.gd`:

| Change | Detail |
|--------|--------|
| `view_for_window(px)` → `stage_for_window(px) -> Rect2` | The 16:9 rect in window pixels |
| `solve(..., upright := false)` | `undersized = upright or points_per_unit < LEGIBLE_SCALE` |
