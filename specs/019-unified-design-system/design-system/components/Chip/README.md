# Chip

A small sunken counter for a single figure: pile sizes, XP to spend, damage taken.

- `well` fill, 1px `line` rim, `chamfer-sm`, height 28pt, `numeral-sm` figure.
- Default figure `parchment`; `--reward` uses `brass-bright` (XP, Score); `--harm` uses `danger` and always carries a minus sign or the heart.
- The leading slot holds the game's icon (pile, star, heart). Word labels in the preview are stand-ins.
- Wrap a chip in a `touch-min` hit area if tapping it opens the glossary.
