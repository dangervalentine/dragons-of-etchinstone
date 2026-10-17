# Contract: Card Side of the Play Board

This replaces the slot band and action column in [006 role-slots](../../006-etched-stone-polish/contracts/role-slots.md). Data shapes are in [data-model.md](../data-model.md). Figures are design units at 1280 × 720.

## Bands (top to bottom, full card-side width)

| Band | Height | Contents |
|---|---|---|
| Role strip | 88 | One section per place, lined up over its column |
| Places row | card height, or a 56 outline while every place is empty | The ordered places |
| Floating row(s) | card height per row; wraps only in a 9-card Final Enemy | Unplaced cards in Hand order |
| Action row | 88 | Secondary 1 (¼), Secondary 2 (¼), Play (½) |

- **Setup and Soak**: no strip or places. The cards use the floating bands' room, and Play keeps its half.
- **Upgrade and penalty recap**: the strip and places show the set just played, in order, with the Reserve's fate.
- **Left side**: 400–548 wide in the Regions, and `FINAL_LEFT_W` (380, measured in T037) in the Final Journey, Final Enemy and Final Soak.

## Place order

| Stage | Order |
|---|---|
| Region | Reserve · Element · Spell · Boost |
| Final Journey | Reserve · E1 · S1 · B1 ‖ E2 · S2 · B2 |
| Final Enemy | E1 · S1 · B1 ‖ E2 · S2 · B2 |

`‖` is the set divider the strip draws (`set_start`).

## Strip section

| Place state | Shows |
|---|---|
| `empty` / `inactive` | Role icon and name, muted. `inactive` is dimmer and refuses puts |
| `next` | As `empty`, edged in the focus colour |
| `target` | As `empty`, or as `filled` if occupied, glowing: the held card can go here |
| `filled` | Small role icon, the large number (≥ 32), and what it counts toward. Boost: target icon toggles Attack / Initiative against an Enemy |
| Reserve `filled` | "Reserve". The Boost number only while it counts toward Move. Against Ranged, a Give up toggle |
| `given_up` | Reserve struck through, toggle on |
| Recap | `played`, `kept`, `discarded`, as in 006 |

A section never shows the card's name; its tooltip does.

## Interaction

| Input | Effect |
|---|---|
| Tap floating or placed card (nothing held) | `pick`. The card rises and glows; valid places become `target` |
| Tap a place, strip section, or the floating band (card held) | `put` there. Occupied place: swap |
| Tap the held card, or empty board | `put_down` |
| Drag a card (more than 12 units) and release over a place or the floating band | `put` there. Release elsewhere: no change, glide home |
| Drag the top card of a Fuse | The tucked card follows |
| `1`–`9` | `pick` the card at that on-screen index |
| `Tab` / `Shift+Tab` (held) | Move the target highlight |
| `Space` (held) | `put` on the highlighted target |
| `Esc` (held) | `put_down` (before cancelling a mode) |
| `R` | Toggle Give up Reserve (Ranged) |
| `Enter`, `B`, `I`, `H`, `?` | Unchanged |

## Intents (`main.dispatch`)

- New: `pick {id}`, `put {target}`, `put_down {}`, `toggle_give_up_reserve {}`.
- Kept: `card {id}`. In building phases it becomes `pick`, or `put` onto that card's place when another card is held. In other phases it is unchanged (setup, Soak, Upgrade, Divert, Regroup, Fuse picks).
- Kept: `select_slot`, `take_back`, `toggle_boost_to`, `inspect`, `action`, `primary`.
- Removed: the `give_up_reserve` action id.

## Board responses

- `put` onto a role place plays today's `place` response (number flight to the strip section, flare in the card's Ether).
- `put` to floating plays `take_back`.
- A swap plays `place` for both cards, staggered by `T.STAGGER`.
- Under reduced motion, cards snap and numbers appear at once.

## Guarantees

- Every card and every place is fully on screen at every stage of building, at every `layout_solver.MATRIX` window (SC-004a, SC-005).
- No tap target is under 88 on its shorter side. Strip numbers are ≥ 32 and text ≥ 22.
- The action row splits ¼ · ¼ · ½ within 2% (SC-003), and Play never moves within a stage.
- The engine receives the same action dictionaries as before (FR-026).
