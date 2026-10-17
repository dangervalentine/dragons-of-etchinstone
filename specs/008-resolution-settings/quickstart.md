# Quickstart: checking the display feature

## Automated

```sh
./tools/test.sh
```

Expected: all tests pass, including:

- `tests/test_window_sizer.gd`: start size on 720p, 1080p (usable 1920×1032 → 1280×720), 1440p, 4K and below-720p monitors; minimum size clamping.
- `tests/test_layout_solver.gd`: `stage_for_window` for each `MATRIX` row (16:9 fills, 16:10 bars top/bottom, ultrawide bars left/right, upright bars top/bottom); `undersized` when upright.
- Settings round-trip of `window_mode`, and the fallback for a bad value.
- `tools/ui_check.gd`: every screen at every matrix shape gets `plan.view == Solver.matrix_view(name)` (`T.DESIGN_MIN` on the locked rows, the grown view on the phone and tablet rows), and the Window row exists in the menu on desktop.
- `tests/test_layout_solver.gd` (amendment): `view_for_window` in both modes, the safe area of a notched phone that fills its screen, and the content clamp past `T.DESIGN_MAX`.

## By hand (Windows, editor run or `build/windows/` export)

Delete `%APPDATA%\Godot\app_userdata\Dragons of Etchinstone\settings.cfg` for a first launch.

| # | Do | Expect |
|---|----|--------|
| 1 | Launch on a 1080p monitor | 1280×720 window, centred, title bar visible |
| 2 | Drag the right edge far out | Play area stays 16:9, black bars at the sides; the dragon's animation keeps running |
| 3 | Drag the bottom edge down | Bars at top and bottom instead |
| 4 | Try to drag the window below 960×540 | It stops at 960×540 |
| 5 | Maximise | Fills the screen above the taskbar; 16:9 with thin bars |
| 6 | F11 | Full screen, no frame, taskbar hidden |
| 7 | Alt+Enter with a button focused | Back to windowed at 1280×720; the button isn't pressed |
| 8 | Settings → Window → Full screen, quit, relaunch | Opens full screen |
| 9 | Mid-game, toggle a few times | Hand, draft and turn state unchanged; an open inspect panel stays open |
| 10 | Click cards and buttons in each mode | Every click lands on what's under the pointer |
| 11 | Look at the bars against the stone | Black reads as a plain dark border (research §2; if not, switch to the stage fallback) |

Web: open Settings and check there's no Window row. Narrow the browser, or open it on a phone, and check the play area stays 16:9 with bars.

Mobile (amendment, Android or iOS app):

| # | Do | Expect |
|---|----|--------|
| 12 | Open Settings | No Window row |
| 13 | Play a turn on a notched 19.5:9 phone | No bars; the layout is wider than on desktop; nothing under the notch or the home indicator |
| 14 | Turn the phone end over end | The layout moves away from the notch on its new side |
| 15 | Play a turn on a tablet | No bars; the layout is taller; the hand and actions are where they are on desktop |
