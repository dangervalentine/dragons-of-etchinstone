# Contract: Playing Field Layout and Surfaces

**Modules**: `ui/model/layout_solver.gd` (pure), `ui/screens/play_screen.gd`,
`ui/widgets/header_bar.gd`, `ui/widgets/slot_row.gd`, `ui/theme/theme.gd`,
`ui/overlays/inspect_overlay.gd`
**Tests**: `tests/test_layout_solver.gd` (extended), `tools/ui_check.gd` (unchanged
checks must keep passing)

## Solver constants

| Constant | Today | New |
|---|---|---|
| `HEADER_H` | 56 | 48 |
| `GAP` | 8 | 12 |
| `COLUMN_GAP` | 16 | 24 |
| Left column width | 0.335 × content, 400–580 | 0.32 × content, 400–548 |
| Slot row base height (1 set / 2 sets) | 120 / 104 | 112 / 96 |
| Slot row extra height | spare − 24, up to +96 | half of (spare − 24), up to +80 |
| Card gap in the Hand | 8–28 | 12–36; 10–36 once more than four share a row |

Region order, the commit corner and the single landscape arrangement are unchanged.

Worked check at `phone-16x9` (content 1248 wide): today the right column is
1248 − 418 − 16 = 814, so four cards are (814 − 3 × 8) / 4 → 197 wide. New: 1248 −
400 − 24 = 824, so (824 − 3 × 12) / 4 → 197. The narrower left column pays for the
wider gaps; the card-size floor test holds the result.

## Invariants (tested)

1. All existing layout tests pass unchanged (regions inside the safe area, no
   overlap, tap sizes, region order, commit bottom-right, larger screens used).
2. **Card size floor**: for every entry in `MATRIX` and hand counts 4 and 7, Hand card
   width ≥ the value recorded from the current solver (table captured in the test
   before the constants change).
3. **Air**: gaps between regions ≥ 12; gaps between Hand cards ≥ 12 (≥ 10 when
   more than four share a row).
4. **Extra space**: on every matrix size larger than `phone-16x9`, the Hand card
   width and the Encounter height are each at least their `phone-16x9` values, and
   gaps never exceed their maximums above (FR-021).

## Surfaces and prominence

- `UI.raised_panel(kind)` replaces flat `UI.box` for the play-screen panels:
  `kind = "active" | "rest"`. Active: lighter surface (`T.BG_RAISED`), top-lit
  gradient, 2-unit `T.FOCUS` rim at 60 %. Rest: `T.BG_SURFACE`, no rim, 1-unit
  `LINE_SOFT` at 50 %.
- `play_screen.gd` applies `active` to the panel named by `vs.input_region` and
  `rest` to the others on every render.
- The header: Region title in `T.HEADING` at `INK` (not gold), progress bar and pile
  counts in `INK_MUTED` at `T.LABEL` size.
- The slot being filled next (`vs.next_role`) uses the same `T.FOCUS` rim and glow as
  emphasised card regions, and shows that role's region icon in `T.FOCUS`.
- The Encounter panel's backdrop picks up the Encounter's Ether `deep` colour.

## Inspect overlay (all Levels)

- One face per Level, 1 to `max_level`, left to right, all the same size: the
  largest size that fits `max_level` faces with `T.L` gaps in the content rect,
  capped at 440 tall.
- The current Level is raised with a `T.FOCUS` rim and titled "CURRENT · LEVEL n".
- Captions: Level n−1 "If Downgraded"; Level n+1 "If Upgraded · c XP"; other Levels
  "Level k". When the current Level is 1, a "Trashed if Downgraded" note sits under
  it. Changed figures on n−1 and n+1 are ringed as today.
- Tap anywhere closes, as today.
