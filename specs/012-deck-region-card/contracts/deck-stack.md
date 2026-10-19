# Contract: The Deck on the Left Side

> **Superseded in part by `specs/013-physical-region-card`**: the layers, the per-phase settled look, the zoomed-out Region Card (now the printed card, without its code) and the space rules are replaced by 013's [left-column.md](../../013-physical-region-card/contracts/left-column.md) and [region-card-face.md](../../013-physical-region-card/contracts/region-card-face.md). The peek, interaction and anchors below still stand.

What the `encounter` region shows in each state. `ui_check` and `design_shots` check this against every `layout_solver.MATRIX` shape.

## Layers, back to front

1. **Card edges**: `edges(vs.piles.deck)` outlines of the top card's footprint, each 3 units further down and right, in `T.BG_RAISED` with a `T.BRONZE_DARK` rim, inside the `DECK_EDGE` margin.
2. **Key Card peek**: hidden except during `key_peek`.
3. **Top card**: the Region Card, the Dragon Card, or nothing (setup).
4. **Face**: `encounter_face`, `dragon_face` or `setup_face`, shown when `view == "face"` or in setup.

The whole region clips its children, so nothing drawn here crosses into the header, the preview, the Hand or the action row (SC-006).

## Per phase, settled

| Phase | Edges | Top card | View | Face |
|---|---|---|---|---|
| `setup` | `edges(16)` | none | — | `setup_face` (unchanged), inset by `DECK_EDGE` |
| Region `challenge` | `edges(deck)` | Region Card, current Region | `face` | `encounter_face` of `vs.encounter`, creature moving |
| Region `penalty`, `upgrade`, `poison` | `edges(deck)` | Region Card | `face` | `encounter_face` of the Encounter just faced (unchanged rule) |
| `final_journey` | `edges(deck)` | Dragon Card | `face` | `dragon_face`, Final Journey look |
| `final_enemy`, `final_soak` | none (`deck` = 0) | Dragon Card | `face` | `dragon_face`, battle look |
| `won`, `lost` | as last | as last | `face` | as last |

## Zoomed-out view (`view == "card"`), only during sequences

- The top card is moved down by `peek_h` and scaled to fit, keeping its aspect ratio.
- The Region Card band reads `REGION n · NAME` with the card code at the right.
- The body has two rows of four tiles: Enemies 1–4 over Journeys 1–4.
- Each tile shows: the Encounter icon and number (≥ 22), a still creature or landscape, the HP or MP badge, and an Ability or Peril icon if it has one.
- The Dragon Card shows its name and title, then the `dragon_stats` figure with its MP Tiers column and HP Tiers column. These columns are the zoom targets.

## Peek

- A `CardFace` of `vs.key_face`/`after.key_face` at the Hand's card width, centred horizontally on the top card, behind it.
- At `"up"` its bottom is `peek_h` above the top card's top edge, so exactly its title band and Key Card strip show: Encounter icon, number and any Hardship. The strip's Encounter and Hardship are ringed.
- It never extends above the region's top.

## Interaction

- The settled face keeps every interaction it has today. Pressing it opens the Key Card (`inspect_key`), and its badges explain themselves (FR-013).
- The zoomed-out Region Card and the peek appear only inside sequences, where any press skips to the settled state. They take no input of their own.

## Anchors (`play_screen.point`)

| Anchor | Point |
|---|---|
| `deck` | The centre of the top card's top edge: where the Key Card sits and where draws leave from |
| `discard`, `trash` | The bottom-right corner of the deepest edge: the back of the Deck |
| `encounter` | The centre of the face (unchanged meaning) |

## Space

- `ENCOUNTER_MIN` and `DRAGON_MIN` each rise by `DECK_EDGE` (24), so every face keeps today's least size.
- `space_audit` measures the settled face as before.
- `ui_check` also asserts that during a sequence the peek's rect ⊂ the deck region and that tile text ≥ 22.
