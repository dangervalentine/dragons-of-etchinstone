# Button

Buttons are carved stone slabs; the one action that moves the game forward is brass.

## Variants
- **Stone** (`.es-btn`): `stone-raised` fill, `edge` rim, `shadow-slab` bevel, `button` text in `parchment`. Fuse, Divert, Back, Change options, Leaderboard.
- **Brass** (`.es-btn--primary`): `brass` fill, `brass-deep` rim and bottom bevel, `on-brass` text. Play, Play again, Continue, Confirm. **One brass button per screen.**
- **Disabled**: `stone` fill, `line` rim, `parchment-faint` label, no bevel. Keep the label so the player knows what will unlock (Confirm 3/4).
- **Pressed**: bevel collapses (`shadow-slab-pressed`) and the slab drops 2px. No colour change for stone.

## Rules
- Height `action-height` (48pt) in the bottom action row; never below `touch-min`.
- Chamfer `chamfer-md`. Icon above label, 4pt apart; counts after a middle dot in `numeral`-style figures (Divert · 2).
- Sentence case labels, a verb or the thing you get: "Play again", not "OK".
- Focus (controller/keyboard): the rim turns `jade`, 3px.

## Godot
StyleBoxFlat: `bg_color` = fill, `border_color` = rim, `border_width_all` = 2, `corner_radius_all` = 10, `corner_detail` = 1. Fake the bevel with `border_width_bottom` = 4 in a darker rim, or a 9-slice texture if you want the inner highlight line.
