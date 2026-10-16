# Contract: Raised Boxes and Flat Ground (US3)

Replaces "Stone and Rift" (revision 1). Values in `ui/theme/tokens.gd`; drawing in
`ui/theme/stone_style.gd`; the ground in `ui/theme/stone.gd` and
`ui/fx/shaders/backdrop.gdshader`.

## Boxes (research R6)

| Kind | Use | Look |
|---|---|---|
| `well` | Zones: the Encounter frame, the math box, the Hand | Raised block, flat `BG_RAISED` face, hard drop shadow 6–8 units, light top bevel, chamfered corners |
| `plinth` | Buttons, slots | As `well`, smaller chamfer; pressed sits flush |
| `inset` | Chips, small badges | Shallow recess, `BG_SURFACE` face |
| `slab` | Popups, overlays | Thick raised block, deeper shadow |
| `lintel` | The header and banners | A full-width shallow band |

- **Edges**: 2 units at rest. They may carry a meaning colour (an Ether, damage owed,
  gold for XP).
- **Waiting or answering**: the edge becomes a solid 3-unit line in the focus or
  response colour. No soft outer glow.
- **Primary**: the primary plinth is gold-faced; a warning plinth is red-faced.

## Ground (research R5)

- `art/stone/grain.png`: a 512² seamless tile of flat woodcut lines in 3 tones,
  inside `[STONE_L_MIN, STONE_L_MAX]`, made by `tools/generate_art.py pattern ground`
  and `tools/make_ground.gd`. The noise grain is the fallback when the file is absent.
- The backdrop draws it flat and still, with the existing vignette. Nothing on the
  ground glows, flickers or moves (FR-016).

## Guarantees

- Every text colour keeps ≥ 4.5:1 (≥ 3:1 for numerals ≥ 32) on box faces and on the
  ground's lightest and darkest tones (`tests/test_stone_contrast.gd`, run on the
  shipped ground).
- No publisher art or trade dress (FR-025).
