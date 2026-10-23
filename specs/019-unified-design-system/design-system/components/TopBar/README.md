# TopBar

The top bar names where the player is and keeps the three pile counts in reach.

- Fill `stone`, a 2px `card-frame` line under it, height `topbar-height` (40pt) inside the safe area.
- Title in `title` (Fraunces 700, 22pt), title case. Lead with the place, demote the number: "Jade Mountains · Region 1" in `parchment` + `parchment-muted`. The current all-caps Cinzel "REGION 1 · JADE MOUNTAINS" is the hardest-to-read line in the game.
- Counters are `.es-chip`s: `well` fill, `line` rim, `numeral-sm` figures. Keep the game's own pile icons in place of the word labels shown here; the labels are a stand-in.
- Menu button is a stone slab at `touch-min` width. The current bare hamburger is about 22pt to tap.
- A screen that is a menu (Leaderboard, Hunt a Dragon) puts a stone Back button left and centres the title.
