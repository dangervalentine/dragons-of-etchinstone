# Data Model: Locked Aspect Ratio and Display Mode

## Display mode setting (`Settings.window_mode`)

| Field | Type | Values | Default | Stored as |
|-------|------|--------|---------|-----------|
| `window_mode` | String | `"windowed"`, `"fullscreen"` | `"windowed"` | `[display] window` in `user://settings.cfg` |

**Validation**: `load_all()` accepts only the two values. Anything else, or a missing key or file, falls back to `"windowed"` (FR-010). Same pattern as `motion`.

**Lifetime**: read once at startup, before the first screen is shown, and written by `save_all()` whenever it changes. It isn't used on mobile or web: it's never read there and is left at its default.

**Not stored**: window size, window position, maximised state.

### State transitions

```text
            toggle (setting / F11 / Alt+Enter)
 windowed  ─────────────────────────────────▶  fullscreen
 (normal,  ◀─────────────────────────────────  (borderless,
 resized,     toggle, or OS leaves full screen   whole monitor)
 maximised)
```

- `windowed → fullscreen`: `window_set_mode(FULLSCREEN)` on the current screen.
- `fullscreen → windowed`: `window_set_mode(WINDOWED)`, then size = `WindowSizer.start_size(...)`, centred on the current screen.
- Maximised is still `windowed`. Toggling from maximised goes to full screen.
- If the OS changes the mode, the setting follows the window's real mode on the next `size_changed`.

## Stage rect (derived, not stored)

The rect, in window pixels, that the 16:9 play area occupies:

```text
s     = min(window.x / 1280, window.y / 720)
size  = (1280 * s, 720 * s)
pos   = ((window - size) / 2)
```

It's used to map the device safe area into view units and to compute points per unit. The view itself is always `T.DESIGN_MIN` (1280×720).

## Starting window size (derived)

`WindowSizer.start_size(usable, decorations)` returns the first of `[3840×2160, 2560×1440, 1920×1080, 1280×720]` with `size + decorations ≤ usable` on both axes. If none fits, it returns the largest 16:9 `size` with `size + decorations ≤ usable`.

Minimum window size: `min(960×540, start_size)`.
