# Contract: Stone and Rift Visual Language (US2, US4)

The visual vocabulary every screen draws from. The values live in
`ui/theme/tokens.gd`, the drawing in `ui/theme/stone_style.gd` and
`ui/fx/shaders/backdrop.gdshader`.

## Surfaces

| Surface | Drawn by | Look |
|---|---|---|
| Backdrop | `backdrop.gdshader` on the full-screen rect | Stone grain plus vignette, with crack seams carrying rift light; seams fade beneath zone rects |
| `well` | `StoneStyle` | A zone cut into the stone: chamfered corners, recessed inner bevel (shadow at the top and left, light at the bottom and right), a darker floor |
| `plinth` | `StoneStyle` | A button: a raised block with an outer bevel (light at the top and left). Pressed, it sinks to flush |
| `slab` | `StoneStyle` | An overlay or screen body: a thick raised slab with a cast shadow, its edge cut with gouge marks |
| `inset` | `StoneStyle` | A small chip or badge: a shallow recess |
| `lintel` | `StoneStyle` | A full-width carved band: the header, the Region banner, the title lintel |

The primary action (Play, Continue) stays gold. It is a gold-leafed plinth, so the
single gold call to action from 001 is unchanged.

## Shared textures (baked once at boot; D3)

- `stone_grain`: seamless 512² simplex fractal. Luminance is remapped into
  [`STONE_L_MIN`, `STONE_L_MAX`], whose top is no lighter than `BG_RAISED`.
- `stone_cracks`: seamless 512² cellular noise with `DISTANCE2_SUB` return. Its thin
  valleys form the seam mask.
- Optional override: bitmap files at `art/stone/grain.png` and `art/stone/cracks.png`.
  These would be Windows-PC generated; if present they replace the baked textures.

## New tokens (`tokens.gd`)

| Token | Meaning |
|---|---|
| `STONE_L_MIN`, `STONE_L_MAX` | The grain's luminance band (D5) |
| `CHAMFER_S`, `CHAMFER_M`, `CHAMFER_L` | Cut-corner sizes for inset, well/plinth and slab |
| `BEVEL_LIGHT`, `BEVEL_SHADOW` | Edge colours for carved bevels |
| `SEAM_NEUTRAL` | The neutral rift colour (cold violet) where there is no Ether |
| `SEAM_MAX_UNDER_TEXT` | 0. Seams never light beneath a zone |
| `RIFT_TINT_TIME` | = `REVEAL`; the Ether tint transition |
| `MOTES_MAX` | 24 (D7) |
| `RAIL_TOKEN_W` | about 132 (role-rail.md) |
| `PREVIEW_MIN` | The left split's floor for the preview (D2) |

The existing colour roles stay. `BG_SURFACE` and `BG_RAISED` become the reference
luminances for stone floors, not flat fills.

## Rift light per Ether (D6)

| Ether | Tint | Behaviour |
|---|---|---|
| Fire | `ether_shade("fire","lit")` | Warmer; quicker, small flicker |
| Water | water lit | Slow swell along the seams |
| Lightning | lightning lit | Steady, with rare brighter jolts (no more than one every 4 s; never a strobe) |
| Shadow | shadow lit | Dim, with faint pinpricks along the seams |
| None | `SEAM_NEUTRAL` | Plain slow shimmer |

**Acceptance**: with the cards and the Encounter frame covered, so the
Ether-tinted creature does not give it away, a viewer names the Ether in at least 3 of 4
(SC-004).

## Ornament and lettering (D10)

- New icons from `tools/gen_icons.py`: `orn_divider`, `orn_corner`,
  `orn_flourish_l`, `orn_flourish_r`, `orn_rift`, `orn_tower`, `orn_seal`,
  `orn_scroll_end`. Each is a flat shape with carved negative space.
- Carved headings: Cinzel display text with a 1-unit dark offset above and a
  light offset below (incised). Applied by `UI.carved_label()`; body text stays
  plain.

## Guarantees

- Every text colour keeps ≥ 4.5:1 (≥ 3:1 for numerals ≥ 32) against both the
  brightest stone plus maximum rim glow and the darkest stone.
  `tests/test_stone_contrast.gd` checks this.
- No zone is drawn as a rounded flat panel once its screen is restyled. US1 alone
  keeps today's look (FR-022).
- No publisher art or trade dress (FR-021). Everything is generated.
