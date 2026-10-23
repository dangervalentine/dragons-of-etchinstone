# Contract: materials and the ground

## Stone (`ui/theme/stone_style.gd`)

| Kind | Face | Corners | Depth | Used by |
|---|---|---|---|---|
| `slab` | `STONE` | `CHAMFER_LG` (trays, dialogs); `CHAMFER_MD` (panels) | `SHADOW_SLAB` | panels, the Action Set tray, dialogs, the menu, popups |
| `plinth` | `STONE_RAISED`, or `BRASS` when primary | `CHAMFER_MD` (buttons); `CHAMFER_SM` (tabs) | `SHADOW_SLAB`, or `SHADOW_BRASS`; pressed `SHADOW_SLAB_PRESSED` | buttons, tabs, tiles |
| `well` | `WELL` | `CHAMFER_SM` | `SHADOW_WELL`, `LINE` 2-unit rim | slots, chips, the Hand well, meter tracks |
| `lintel` | `STONE` | `CHAMFER_LG` ends | `SHADOW_SLAB` | banners, the title wordmark |

- Every raised kind draws, in order: the drop, the face, the `BORDER_ETCH` parchment@0.10
  line inside the top edge, the bottom bevel, and the `BORDER_EDGE` rim in `EDGE`.
- Selected or target replaces the rim with `BORDER_SELECT` `BRASS`. Focus uses
  `BORDER_SELECT` `JADE`. Disabled has no bevel and no drop, a `STONE` face and a `LINE`
  rim.
- The `inset` kind and `T.muted` are removed. `round_radius` stays for paper and card
  shapes only.
- The chamfer is capped at 30% of the short side, as today.

## Paper

`UI.paper_box()`:

- `PAPER` face with a 2-unit rim of `PAPER` darkened 0.15.
- Corners rounded at `RADIUS_PLATE`.
- `SHADOW_CARD` underneath.

Text on paper is `PAPER_INK` in `BODY`, with secondary text in `PAPER_MUTED`. Lines are at
most about 50 characters, with the box at most `COACH_MAX_W` wide.

It is used for tooltips (`wrapped_tooltip`, `help_tip`, `tip_box`), the coach bubble, the
glossary popover and full view, rulebook pages (the page body; the overlay's frame is a
slab), and the unspent-XP question.

## Cards

- **Corners**: `UI.card_radius(w) = w * CARD_RADIUS_SHARE` (0.08) for every card: Mage
  Card, Key Card, Region Card, Encounter face, Dragon face and card, table note, Deck, and
  trashed back. No card computes its own radius.
- **Shadow**: `UI.card_shadow(lifted: bool)` draws `SHADOW_CARD`, or `SHADOW_LIFT` while
  the card is held, dragged or inspected.
- **Selected**: a `BORDER_SELECT` `BRASS` ring at radius + 2, plus `SHADOW_LIFT`.
- **Out of play**: greyscale at `OUT_OF_PLAY`. Ineligible this step keeps today's dimmed
  plates.
- **Mage Card**:
  - `CARD_FRAME` frame and title band; the name in `CARD_NAME` over the full band width,
    with no inline glyph circle.
  - The Ether glyph is always present in the band.
  - A `CARD_RIBBON` ribbon with cost on the left and XP on the right in `BRASS_BRIGHT`.
  - Figures on `STAT_PLATE` (`RADIUS_PLATE`), never on the field.
  - The highlighted figure fills with `ether_shade(pill)` and its ink is
    `ether_shade(pill_ink)`.

## Ground and the Region wash (`ui/fx/backdrop.gdshader`, `ui/fx/backdrop_layer.gd`)

- The shader's uniforms are `ground` (`GROUND`), `wash` (colour), `wash_amount` (0 to
  `REGION_WASH`), `wash_centre` (in pixels) and `wash_radius` (in pixels).
- Output: `ground`, plus `wash` × `wash_amount` × smooth radial falloff from the centre.
- `BackdropLayer.set_region(stage, centre)`:
  - Region `n` → `REGION[n]`.
  - Final → `REGION_LAIR`.
  - `null` (screens without a game) → `wash_amount` 0.
  - Changes tween over `T.MOVE`, or are set at once under reduced motion.
- The centre is the centre of the left column's card, taken from the layout solver; the
  radius is 0.6 × view height.
- The ground picker, its setting, the stone tiles and the grain are removed (research R5).
