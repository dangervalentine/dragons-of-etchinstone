# Contract: tokens (`ui/theme/tokens.gd`)

The source of truth is [`../design-system/tokens.json`](../design-system/tokens.json).
`tests/test_design_tokens.gd` holds this file and `tokens.gd` to it. Sizes are design units
(1280×720 layout), each equal to round(phone points × 1.85).

This contract supersedes the colour values in `specs/001-ui-polish/contracts/design-tokens.md`
and the colour names cited in the contracts of features 005, 006, 011, 012, 013 and 017.
Those features keep their behaviour; only the colours they draw in change, following the mapping
below.

## Colour

| Token | Value | Replaces | Use |
|---|---|---|---|
| `GROUND` | `#0e1517` | `BG_BASE` (as ground) | the table behind everything |
| `STONE` | `#172225` | `BG_SURFACE` | panels, trays, top bar, dialogs, banners |
| `STONE_RAISED` | `#213033` | `BG_RAISED` | buttons, tabs, chips you press |
| `WELL` | `#0a1012` | — | sunken slots, chips, the Hand well, meter tracks |
| `LINE` | `#2e3f40` | `LINE_SOFT` (dividers) | hairlines, disabled rims |
| `EDGE` | `#64797a` | `LINE_SOFT` (rims) | etched rims of slabs and controls |
| `PARCHMENT` | `#f1e3d1` | `INK` | primary text and icons; step emphasis rings |
| `PARCHMENT_MUTED` | `#b4a894` | `INK_MUTED` | secondary text, heads, inactive tabs |
| `PARCHMENT_FAINT` | `#5f675f` | `INK_MUTED` at 0.6 (disabled) | disabled labels only |
| `BRASS` | `#dcb35c` | `GOLD_FACE`, `GOLD` (selection/target) | primary fill, selected and target rims |
| `BRASS_BRIGHT` | `#f2d16b` | `GOLD` (rewards) | Score, XP, star, 1st, banner headlines |
| `BRASS_DEEP` | `#8a6a2c` | — | brass bevel; glossary-term underline on paper |
| `ON_BRASS` | `#1c1508` | `BG_BASE` (as ink on gold) | ink on brass, brass-bright, ochre |
| `JADE` | `#8fc4a3` | `GOOD`, keyboard focus | good outcomes, focus ring |
| `DANGER` | `#ee7a62` | `BAD` | harm, always with a sign or icon |
| `STAT_HP` | `#e2697a` | `HP` | the HP heart |
| `PAPER` | `#e9dac4` | — | reading surfaces |
| `PAPER_INK` | `#1b2324` | — | text on paper |
| `PAPER_MUTED` | `#5a5244` | — | secondary text and rules on paper |
| `SCRIM` | `Color(5/255, 9/255, 10/255, 0.82)` | `BG_BASE` at alpha, `COACH_DIM` | behind dialogs, menu, banners, the coach's dim |
| `CARD_FRAME` | `#121618` | `CARD_FRAME` | card frame and title band; top-bar foot line |
| `CARD_RIBBON` | `#6b5639` | `BRONZE` | a card's stat ribbon, the Key Card strip |
| `STAT_PLATE` | `#101314` | `BG_BAND` (plates, chips on cards) | plates behind card figures; ink on bright pills |
| `CAUTION` | — | removed | the narrow victory is `BRASS` with its own icon (`narrow_victory`) |

`ETHER` is `{"water": {base #3566b0, bright #5a8bdb}, "lightning": {#c9902c, #e8b245},
"shadow": {#7350b0, #9576dd}, "fire": {#b93a2e, #de5a44}}`. `ether_shade(element, role)`
takes the roles `base`, `deep`, `lit` (= bright), `plate`, `plate_ink`, `pill` and
`pill_ink` (research R11).

`REGION` is `{1: #5f8a6e, 2: #4d8080, 3: #b5633a, 4: #3f6b4a}`; `REGION_LAIR` is `#8a3b3a`.

Extension tokens (research R12) carry a `## Extends the design system:` note. They are
`METAL`, `GLASS`, `CARD_EDGE`, `CARD_EDGE_LINE`, `CREATURE_LINE`, `SHADOW_DROP` (`#070b0c`),
`LOCKED`, `DIM_MODULATE`, `DIM_HOVER`, `DECK_BACK`, `SHADE` (black) and `SHEEN` (white),
the last two used with an alpha for shadows and washes.

## Space, shape and size

| Token | Units | Points |
|---|---|---|
| `SPACE_1` … `SPACE_6` | 7, 15, 22, 30, 44, 59 | 4, 8, 12, 16, 24, 32 |
| `CHAMFER_SM`, `CHAMFER_MD`, `CHAMFER_LG` | 11, 19, 30 | 6, 10, 16 |
| `CARD_RADIUS_SHARE` | 0.08 × card width | 8 on a 100 card |
| `RADIUS_PLATE` | 7 | 4 |
| `BORDER_ETCH`, `BORDER_EDGE`, `BORDER_SELECT` | 2, 4, 6 | 1, 2, 3 |
| `TOPBAR_H`, `ACTION_H`, `CHIP_H` | 74, 89, 52 | 40, 48, 28 |
| `COACH_MAX_W`, `DIALOG_W` | 560 (within the 629 maximum), 666 | ≤ 340, 360 |
| `TAP_MIN` | 88 (kept; `touch-min` is 81) | — |
| `TEXT_MIN`, `CARD_NAME_MIN` | 22, 20 | 12, 11 |
| `HELP_MIN` (ui_check) | 44 (kept) | — |

`XS`, `S`, `M`, `L`, `XL`, `RADIUS_S`, `RADIUS_M`, `RADIUS_CARD` and `CHAMFER_S/M/L` are
replaced by the tokens above and deleted.

## Shadow and opacity

| Token | Meaning (design units) |
|---|---|
| `SHADOW_SLAB` | 2 parchment@0.10 top line, 6 black@0.35 bottom bevel, 6 drop in `SHADOW_DROP` |
| `SHADOW_SLAB_PRESSED` | 4 black@0.45 top inset, 2 drop |
| `SHADOW_BRASS` | 2 `#fff4d6`@0.55 top line, 6 `BRASS_DEEP` bottom bevel, 6 drop |
| `SHADOW_WELL` | inset, 4 down, 11 blur, black@0.6 |
| `SHADOW_CARD` | 4 hard drop in `SHADOW_DROP` + 15 down / 33 soft at black@0.45 |
| `SHADOW_LIFT` | 7 hard drop + 30 down / 59 soft at black@0.55 |
| `REGION_WASH` | 0.22 |
| `OUT_OF_PLAY` | 0.45, with full desaturation |

## Motion (added; existing durations unchanged)

| Token | Seconds |
|---|---|
| `PRESS` | 0.08 |
| `RELEASE` | 0.12 |
| `PRESS_DROP` | 4 units (2pt) |
