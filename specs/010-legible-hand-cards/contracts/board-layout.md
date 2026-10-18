# Contract: Card Side of the Play Board (010)

This replaces [009 board-layout](../../009-ordered-hand-layout/contracts/board-layout.md). Figures are design units.

## Bands (top to bottom, full card-side width)

| Band | Height | Contents |
|---|---|---|
| Hand | everything between `body_y` and the action row, less `GAP` | Positions: each a `LABEL_H` (36) label over a card, in 1–3 rows |
| Action row | 88 | Secondary cells, then Play, rightmost |

- **Setup, Soak, Upgrade**: no labels (`label_h = 0`). Cards in Hand order.
- **Recap after a battle**: the labels show `played`, `kept` and `discarded`.
- **Left side**: unchanged from 009 (400–548 wide in the Regions, `FINAL_LEFT_W` in the Final Battle).

## Positions

| Stage | Order | Rows |
|---|---|---|
| Region | Reserve · Element · Spell · Boost | 1 |
| Final Journey | Reserve · E1 · S1 · B1 ‖ E2 · S2 · B2 | whichever of 1–3 gives the widest card; a tie breaks at ‖ |
| Final Enemy | E1 · S1 · B1 ‖ E2 · S2 · B2, then extras | as above |

- At the deal, card *k* goes to position *k*. A short Hand fills Spell, Element, Boost, then the Reserve.
- Card size: the widest that fits, ≤ `CARD_MAX_W`, the same for every card. It is fixed for the Hand and never changes during swaps.

## Label

| State | Shows |
|---|---|
| `empty` | Role icon and name, muted |
| `inactive` | Dimmer; refuses puts |
| `filled` | Role icon and name |
| `target` | Glowing: the held card can go here |
| `given_up` | Reserve struck through |
| `played` / `kept` / `discarded` | Recap marks |
| Set 2's first | The set divider |
| Reserve with Steep or Freeze | The rule's mark |

A label never shows a number or a card name. The tooltip names the card.

## Action row

| Cells *k* | Layout |
|---|---|
| ≤ 3 | Secondary cells ¼ each (a blank cell when an action is not on offer), Play ½ |
| 4 | Four cells, ¼ each |
| 5 | Five cells, ⅕ each |

Order from the left:

1. Fuse, or Undo Upgrade in the Upgrade phase.
2. Divert, or Regroup in the Final Journey.
3. Give up Reserve (Ranged Enemy with a Reserve).
4. Play.

Cancel replaces the action under way, in its own cell. Play's right edge is always the row's right edge.

## Preview panel: aiming the Boost

- Against an Enemy while building, the Attack and Initiative rows are buttons, each ≥ 88 tall.
- An aimed Boost shows its term (`Boost`, `Boost 1`, `Boost 2`) in its row.
- While a Boost is unaimed, both rows show a dimmed "Boost?" cell and a gold edge, and Play stays disabled.
- A row tap aims:
  - the held card's Boost, if a Boost card is held;
  - otherwise the first unaimed Boost;
  - otherwise, in a Region, the one Boost;
  - otherwise (Final Enemy, both aimed, nothing held) the tap is refused: "Pick up a Boost card, then tap where it goes."
- The Initiative note sits inside the Initiative row. The Region drops the separate "ends the game in defeat" line; the red edge and verdict remain.

## Interaction

| Input | Effect |
|---|---|
| Tap a card (nothing held) | `pick` |
| Tap another card or a label (card held) | `put`: swap, or move to an empty position |
| Tap the held card, or empty board | `put_down` |
| Drag a card (> 12) onto a card or label | `put` there. Elsewhere: glides home, no change |
| Tap the Attack or Initiative row | `aim_boost` |
| `1`–`9` | `pick` the card at that on-screen index |
| `Tab` / `Shift+Tab` (held) | Move the target highlight |
| `Space` (held) | `put` on the target |
| `Esc` (held) | `put_down` |
| `B` | Aim the active set's Boost: Attack first, then back and forth |
| `R` | Toggle Give up Reserve |
| `Enter`, `H`, `?`, `I` (inspect) | Unchanged |

## Board responses

- A swap plays `place` for both cards, staggered by `T.STAGGER`.
- The number flight lands on the preview row's total.
- An aim plays a short flare on the row it lands on.
- Under reduced motion, cards snap and numbers appear at once.

## Guarantees

- At every `layout_solver.MATRIX` shape and every stage: every card and label is fully on screen; nothing overlaps; no tap target is under 88 on its shorter side; text is ≥ 22.
- Region cards at phone-tall are ≥ 291 tall (1.5 × 194), and every card is ≥ its 009 size at every shape.
- The action row splits as above, within 2%.
- The engine receives the same action dictionaries as before.
