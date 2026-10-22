# Contract: The Region Card and its Panels

What the top card shows, checked by `test_region_card`, `test_region_panel`, `ui_check` and the `scan` design shot.

## The whole card (`RegionCard`)

- **Aspect**: 5 : 7. It is fitted to the face rect's width, with its top below the peek room (012's `card_rect`).
- **Layout**: per research R1, with every rect a fixed fraction of the card.
- **Title band**:
  - The Region name in `T.HEADING`, stepping down to fit, never below `T.TEXT_MIN`.
  - "REGION n" under it in `T.LABEL` gold.
  - A `sigil_region` ornament at each end.
- **Order**: Enemies 1–2 on the top row and 3–4 below, left to right. Journeys 1–4 in one row, left to right.
- **Never drawn**: the card code, or any text matching `DOE-`.

## An Enemy panel (`RegionPanel`, kind `enemy`)

| Part | Where (fraction of the panel) | Content |
|---|---|---|
| Frame | whole | Box with its right-hand corners cut (`bevel`, 0.07 of the shorter side) as printed, in the panel's Ether at 0.18, edge `T.muted(ether)` over the art |
| Art | x 0.2 – 1, y 0 – 1 | Creature, cropped by `enemy_crop`. Still on the card, moving when landed. Edged in a `T.CREATURE_LINE` ink line, over a soft light in its Ether's lit shade (`T.CREATURE_BACKLIGHT`) round its figure, so it stands off the ground |
| Badge column | x 0.02 – 0.2, y 0.04 – 0.96 | HP (heart, `T.HP`), Initiative (`T.BG_BAND`), Attack (Ether), Armor (Ether; 2 shields at 0.92 size side by side when two) |
| Effect disc(s) | beside the HP heart, level with its centre and inside the frame, 0.18 h each | Ability, where it is printed. When landed, also the Key Card's Hardship, to its right |
| XP star | bottom-right, 0.22 h | `xp` in a star, `T.GOLD` |
| Number marker | top-right, 0.16 h | `index` in `T.LABEL_BOLD` on `T.BG_BASE` at 0.72 |

## A Journey panel (`RegionPanel`, kind `journey`)

| Part | Where | Content |
|---|---|---|
| Header strip | y 0 – 0.25 | MP badge (dark mountain on the MP Ether) on the left half, Time Penalty hourglass (`STEEL` bars, `GLASS` between them, flared as printed) on the right |
| Art | y 0.25 – 1 | Landscape, whole (`Art.FULL`), cropped to fill |
| Effect disc(s) | art's top-right | Peril. When landed, also the Hardship, to its left |
| XP star | foot, centred | `xp` |
| Number marker | art's top-left | `index` |

## Both kinds

- Every badge is a `StatChip` with its glossary id, so pressing it explains it (when landed; the whole card takes no input, per 012).
- Pressing the landed panel outside its badges emits `inspect_key` (unchanged from today's face).
- Every numeral is at least `T.TEXT_MIN` at every `MATRIX` shape when landed. The whole card is a picture, read by zooming in (research R9 note).

## The reading strip (landed only)

> As built (research.md Implementation notes): the strip lies along the face's foot over the zoomed card, on a dark band; the landed face is the whole card grown round the lit panel.

- **Placement**: below the panel when the face is taller than wide after the panel is fitted, otherwise to its right. It always has at least 2 lines of `T.BODY`.
- **Lines, in order**:
  1. The Encounter icon and number, and the name.
  2. The Hardship: its icon and `Glossary.entry(id).short`.
  3. The Ability or Peril: its icon and short text.
- Empty lines are omitted. If the strip has nothing but the name, the panel grows into the spare room.

## The Dragon Card (`DragonCard`)

- **Title band**: the name and the title. No code.
- **Badge row**: Initiative, Early Damage, Armor, centred under the band.
- **Tiers**: the MP Tiers column on the left and the HP Tiers column on the right, over the art.
- **Zoom targets**: `target_rect("mp")` and `target_rect("hp")` are those columns. The landing face is `dragon_face`, unchanged.
