# Contract: Mage Card Face

**Widget**: `ui/widgets/card_face.gd` (rebuilt) with `ui/fx/shaders/ether_card.gdshader`
(replaces `ether_field.gdshader` for Mage Cards; Encounter faces may keep the old one)
**Consumers**: `card_view.gd`, `card_detail.gd`, `inspect_overlay.gd`,
`rulebook_figure.gd`, `slot_row.gd` (mini faces), `tools/design_shots.gd`

## Interface

```gdscript
func set_model(m: Dictionary, ring: Array = [], ring_colour: Color = T.GOLD) -> void   # unchanged
func set_focus(focus: Dictionary) -> void      # new; {} or {"regions": [], …} = no focus
var dimmed: bool                                # unchanged: whole card unavailable
var motion: bool                                # new; false freezes the field (reduced motion, covered)
func region_rect(key: String) -> Rect2          # new; for tests, slot links and hit-testing
```

`m` keeps its current shape: `id, name, element, level, stats, downgraded`.
`set_focus` may be called every view-state update; it animates only when the focus
actually changes.

## Layout (fractions of the face, any size)

Top to bottom, matching the printed card:

| Band | Height | Content |
|---|---|---|
| Top band | 0.150 h | Crown with Level (`level`), Ether pip + name in display capitals (`name`) |
| Key strip | 0.095 h | Bronze band with left tab: Encounter icon + index + Hardship (`key`); right: cost + XP burst (`cost`); torn edge below |
| Ether field | rest, minus border | Field shader; sword spine; stat column down the left; large sigil right of centre (`ether`) |

Stat column inside the field, top to bottom, each row ≈ field height / 5.4:
Initiative pennant crest · basic octagon plate · arrow · enhanced octagon plate ·
Boost square plate · Armor shield crest. The sword blade runs behind the column, its
crossguard level with the two action plates, its pommel behind the Armor crest.

`region_rect(key)` returns the rectangle of each region in this layout. Regions do
not overlap except `ether`, which spans the field.

## Drawing rules

- **Depth**: the card casts a soft drop shadow; every band, crest and plate is drawn
  shadow → body → top highlight → bottom shade, lit from the top, by one helper.
- **Frame**: near-black (`T.CARD_FRAME`), no Ether border; a thin inner rim in the
  Ether `lit` colour at 25 % so the card still reads as its Ether at a glance.
- **Enhanced plate**: filled with the enhanced action's Ether `plate` colour; ink is
  that Ether's `plate_ink`; Ether pip at the top-right corner.
- **Armor crest**: filled with the Armor Ether `plate` colour when it has one, black
  otherwise; Ether pip beside it.
- **Field**: `ether_card.gdshader` with `ether`, `motion`, `phase` (hash of card id),
  `focus_dim` (0 normal, 0.25 quietened field), `dim` (unavailable).
- **Downgraded**: the existing crack drawing, over everything.

## Treatments

| Treatment | Plates and crests | Ink | Field | Extra |
|---|---|---|---|---|
| Normal (no focus) | Full | `INK` / `plate_ink` | Full | — |
| Emphasised region | Raised 1–2 units further, focus rim (`T.FOCUS`, 2 units) with soft outer glow | Full | — | `mark` badge where applicable |
| Quietened region | Fill blended 75 % toward the band colour; no highlight | `INK_MUTED` (≥ 4.5:1 on the quietened fill) | `focus_dim` 0.25 unless `ether` is emphasised (then brightened 15 %) | — |
| Unavailable card | Greyscale field (`dim`), frame and plates desaturated | `INK_MUTED` | Greyscale, still | Existing reason tag; no focus rim on any region |

Marks: `soaks_more` – a "×2" chip on the Armor crest in the damage Ether's `lit`
colour; `affordable` – cost in `T.GOLD` with the focus rim; `unaffordable` – cost in
`T.BAD` with no rim; `max_level` – cost shows "MAX" in `INK_MUTED`.

A focus change cross-fades between treatments over `T.FAST`; with reduced motion it
is applied at once.

## Ether character

Finished like a premium foil trading card: faint and slow, never a visualizer
(user direction, 2026-10-14). Each Ether is told apart by an etched line texture
that holds almost still; the only real motion is a broad holographic sheen that
takes about half a minute to drift across the field, catching the etching in soft
shifting colour, and a few foil glints that brighten and fade slowly. Both are
kept faint enough to be noticed second, never first.

| Ether | Etching | Still frame (motion = 0) | Sigil |
|---|---|---|---|
| Fire | Strands rising from a glowing base, curling into layered flame-tongue outlines at the top | Same, sheen resting across the upper left | Leaning flame with curl |
| Water | Long even waves running across | Same | Droplet |
| Lightning | Sharp zig-zag rows with a bolt etched through | Same | Zig-zag bolt |
| Shadow | Lines coiling round the centre under faint four-point stars | Same | Four-point sparkle |

## Guarantees (tested or checked)

1. Every numeral and label meets FR-026 contrast in every treatment and Ether
   (`tests/test_card_contrast.gd`, computed from tokens).
2. `region_rect` regions are inside the face and do not overlap (except `ether`) at
   Hand, detail and inspect sizes (`tests/test_card_face_layout.gd`, headless).
3. At the smallest Hand card size on `phone-16x9`, numerals are at least as large as
   today (same test, against recorded values).
4. Greyscale screenshots of the four Ethers are distinguishable (manual, quickstart).
