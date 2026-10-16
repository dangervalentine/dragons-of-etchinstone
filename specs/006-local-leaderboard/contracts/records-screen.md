# Contract: Records Screen and Entry Points

**Screen**: `ui/screens/records_screen.gd` (`extends Control`, built in code like the
other screens, `apply_layout(content: Rect2)`, `signal intent(data)`).
**Data**: `HistoryStore.records`, `PlayHistory` views, the card database for dragon
order and names. The screen does not read the engine.

## Entry points and navigation

| From | Control | Intent | Opens |
|---|---|---|---|
| Title screen, bottom row beside "How to Play" | "Records" button, `trophy` icon | `{"type": "records", "from": "title"}` | Leaderboard tab |
| Ending screen, under the score | "Leaderboard" button (quiet) | `{"type": "records", "from": "ending"}` | Leaderboard tab |
| Records screen | "Back" button or system back gesture | `{"type": "records_back"}` | The screen it came from |
| Records screen | "Clear records" (quiet) | opens `ConfirmDialog` "Clear every recorded game? This cannot be undone." / "Clear records" / "Keep them" | Same screen, emptied, on confirm |

Returning to the ending screen re-renders it from the kept view state; the game
is already recorded, so nothing is recorded again.

The screen opens on `menu.difficulty` (the difficulty last chosen), dragon filter
"All", page 1. Tab, difficulty, filter and page are not remembered between visits.

## Layout (design units, content rect at least 1248 × 688)

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ Casual     │ [Back] [Leaderboard] [History]            [Clear records]   │  88
│            ├─────────────────────────────────────────────────────────────┤
│            │  Leaderboard tab                                            │
│ Easy       │  [All] [Grimroch] [Helsang] [Rodving] [Vuurhast]       88   │
│ Normal  ●  │  #   Score  Dragon     Rules        Time     Date           │
│ Hard       │  1st  35    Rodving    —            18:42    12 Oct 2026     │
│ Impossible │  2nd  31    Helsang    Cavalier     21:05    14 Oct 2026     │
│ Don't Even │  … up to 10 rows, no scrolling                               │
│ (Other)    │                                                             │
│  rail 6×88 ├─────────────────────────────────────────────────────────────┤
│            │  History tab                                                │
│            │  attempts list, page of 6         │ summary for difficulty  │
│            │  Won  Final Enemy  33  Rodving …  │ Attempts 12  Wins 5 42% │
│            │  Abandoned  Region 2  —  Helsang  │ Time played 3:41:09     │
│            │  ‹ Newer  Page 1 of 3   Older ›   │ per dragon: att, wins,  │
│            │                                   │ rate, best, avg         │
└────────────┴─────────────────────────────────────────────────────────────┘
```

- The rail runs the full height on the left, so it has room for an "Other" tile;
  the header (Back, the two tabs, Clear records) sits above the tab's content.
- Rail: the six difficulties in `Game.DIFFICULTY` order, named by
  `ViewState.DIFFICULTY_NAMES`, each a `ChoiceTile` at least `T.TAP_MIN` tall, the
  current one selected; an "Other" tile only when records exist with an unknown
  difficulty (History only).
- Leaderboard rows are text, not buttons; rank 1 is drawn in `T.GOLD` with the crown
  icon. Rules column lists "Cavalier", "Glass Cannon", both, or "—".
- Empty board (FR-015): "No game won on Hard yet." or "Helsang has not been beaten
  on Hard yet.", then "N attempts so far." (or "No attempts yet.").
- History rows: outcome (Won in `T.GOLD`, Lost in `T.BAD`, Abandoned in
  `T.INK_MUTED`), stage name, score (or "—" when not won), dragon, rules, time, date.
  Two lines per game; "‹ Newer" / "Older ›" are disabled at the ends.
- Summary panel: attempts, wins, win rate (whole percent), total time; then per
  dragon: attempts, wins, rate, best and average ("Not beaten yet" when no wins); a
  dragon not yet played on that difficulty takes a single line.
- Text at least 22 units, controls at least `T.TAP_MIN`; nothing scrolls; fits the
  1280 × 720 minimum (checked by `tools/ui_check.gd`).

## Ending screen additions

Under the score table, when `vs.ending.placing` is not empty: each line as a label
in `T.GOLD` (`body_bold`), first line with the crown icon. Then the "Leaderboard"
button. Losses show the button but no placing.

## Checks

- `tools/ui_check.gd`: opens the records screen from the title at every matrix size,
  with an empty history and with a seeded history of 60 records, on both tabs and the
  last history page; runs the existing bounds, tap-size, text-size and no-scroll
  checks; confirms a seeded game played to the end adds exactly one record.
- `tools/design_shots.gd`: `records_leaderboard.png`, `records_history.png`,
  `ending_placing.png` from the seeded sample history.
