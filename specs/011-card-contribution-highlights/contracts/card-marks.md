# Contract: Card Marks

What each placed card shows while an Action Set is built. The emphasis tests (SC-003, SC-006) and `ui_check` check against this table. "Lift" means the card face's existing raised plate with a `T.FOCUS` rim. "Mark" means an icon on a dark disc, drawn to the right of the region's plate (research R3).

## Lift (FR-007, FR-008)

| Encounter | Spell | Element | Boost | Reserve |
|---|---|---|---|---|
| Region Enemy | `enhanced` if Ether matches and type fits; else `basic` if it fits; else none | `ether`, `initiative` | `boost` (any aim) | none |
| Region Enemy, **Slow** | as above, with Move actions fitting | `ether`, `initiative` | `boost` | none |
| Region Journey | as above, for Move | `ether` | `boost` | `boost` when its Boost is added to Move (Spell enhanced and Ether matches the MP) |
| Final Journey | per set, as Region Journey | `ether` | `boost` | as Region Journey |
| Final Enemy | per set, as Region Enemy | `ether`, `initiative` | `boost` | — (no Reserve) |
| Spell with no Element placed | `basic` and `enhanced` | — | — | — |

A Boost whose value is 0 has no term, so it is not lifted.

## Impact marks (FR-016 to FR-018)

| Effect (source) | Card in position | Beside region | Shown while |
|---|---|---|---|
| Night Travel (Hardship) | each Boost | `boost` | the Encounter has Night Travel |
| Night Travel (Hardship) | each Element | `initiative` | the Encounter has Night Travel |
| Steep (Journey peril) | Reserve | `boost` | the Reserve holds a card |
| Ranged (Enemy ability) | Reserve | `boost` | the Reserve holds a card and Give up Reserve is off |
| Freeze (Enemy ability) | Reserve | `boost` | the Reserve holds a card |
| Armor (Enemy) | Spell | `enhanced` | an `Armor` term is in the Attack sum |

- The source keeps its own icon on the Enemy panel or the Journey, unchanged.
- Poison, Ambush, Hazards, Storm and Treacherous get no card mark.
- When a card leaves the position, its marks go; the incoming card takes them.

## Aim mark and zone (FR-011 to FR-015)

| Encounter | Boost card shows | Tap in the zone |
|---|---|---|
| Region Enemy, Final Enemy | aim mark beside `boost`: `?` (gold) / `attack` / `initiative` | cycles unset → Attack → Initiative → Attack |
| Journey, Final Journey | nothing | — (zone absent; the tap picks up as normal) |

- **Zone**: the full card width by 88, along the bottom edge. It never exceeds 50% of card height on any `MATRIX` shape.
- **Order of marks** beside one plate: the aim mark first, then impact icons. Neither covers a figure.
- **Keyboard**: `B` cycles the held Boost's set, or the first unaimed set.

## Not colour alone

Lift changes shape (raise and rim); marks are icons; the unset aim is a `?` glyph. Each reads in greyscale.
