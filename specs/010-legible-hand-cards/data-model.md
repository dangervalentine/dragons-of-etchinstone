# Data Model: Legible Hand Cards

These are changes to the 009 model ([009 data-model](../009-ordered-hand-layout/data-model.md)). Everything not listed here is unchanged.

## TurnDraft (`ui/model/turn_draft.gd`)

| Member | Change |
|---|---|
| `sets`, `reserve`, `boost_to`, `held`, `fuse`, `give_up_reserve` | Kept. A card's position is its role in `sets`, or `reserve` |
| `active` | Kept for the keyboard target cycle only. It no longer drives a "next" label |
| `deal(hand)` | **New.** Fills the positions in draw order (research R2). Called after `reset()` in `challenge`, `final_journey` and `final_enemy` |
| `settle(hand)` | **New.** Moves the Reserve card into an empty role when no Reserve is on offer, and puts an unfused card in the first empty position (R3) |
| `swap(a, b, hand)` | **New.** Two Hand cards trade positions, including an extra card with no role (Final Enemy) |
| `put(target, hand)` | The `"floating"` target goes. Targets are `[set, role]`, `"reserve"`, or `{"card": id}` (swap with that card) |
| `floating(hand)` | Renamed `extras(hand)`: Final Enemy cards with no role, in Hand order. Empty in the Regions and the Final Journey once dealt |
| `boost_target_set(held)` | **New.** The set a row tap aims: the held card's set if it is a Boost, else the first unaimed set, else 0 when `set_count == 1`, else `-1` (refuse) |

### Invariants

- After `deal`, every Hand card that is not tucked holds a position, or is an extra in the Final Enemy.
- `reserve != null` implies `reserve_offered(hand)`.
- `to_action()` gives the same dictionary for the same roles as in 009.

## View state (`ui/model/view_state.gd`)

### `places[]`: one per position, rulebook order, then extras

| Field | Change |
|---|---|
| `key`, `set`, `role`, `card_id`, `tap`, `tooltip`, `set_start`, `given_up`, `rule` | Kept. `role` is `"extra"` for a Final Enemy card with no role |
| `state` | `empty`, `inactive`, `filled`, `target`, `given_up`, `played`, `kept`, `discarded`. `next` goes |
| `number`, `counts_to`, `choices`, `toggle_tap`, `boost_to`, `ether` | **Removed.** Values are read in the preview panel, and the aim and Give up live elsewhere |
| `index` | **New.** The position's index in the solver's `positions` |

### `math.sums[]`

| Field | Change |
|---|---|
| `aim` | **New.** `{to: "attack" or "initiative", on: [set indexes aimed here], open: bool}` against an Enemy while building, otherwise null. `open` is true while some Boost is unaimed |

### Other fields

| Field | Change |
|---|---|
| `secondary` | `[Fuse or Undo or Cancel, Divert or Regroup or Cancel, Give up Reserve?]`. The third entry is present only against a Ranged Enemy while the Reserve holds a card (research R8) |
| `action_cells` | **New.** Integer 1–5: what the solver splits the row by (R5) |
| `floating` | Replaced by `unplaced`: the Hand cards in no place (every card in setup and Soak; while building, only a Fuse's tucked card). Final Enemy extras are places with `role: "extra"` |

## Layout plan (`ui/model/layout_solver.gd`)

| Key | Change |
|---|---|
| `regions.slots` | **Removed** |
| `regions.hand` | From `body_y` to `actions.y − GAP` |
| `regions.secondary` | Array of 2–4 rects, by `action_cells` (R5) |
| `regions.commit` | Play: right ½, ¼ or ⅕ |
| `positions` | **New.** `[{label: Rect2, card: Rect2}]` in position order (R6). One row while building a Region set; up to three in the Final Battle, setup and Soak |
| `label_h` | **New.** `LABEL_H`, or 0 in setup and Soak |
| `card_size` | One size per Hand, from the 1/2/3-row search |
| `place_rects`, `floating_rects()`, `outline_height()`, `card_size_for()`, `_stages_fit()`, `PLACE_EMPTY_H`, `STRIP_H` | **Removed** |
| `LABEL_H` | **New.** 36 |

## Intents (`ui/main.gd`)

| Intent | Change |
|---|---|
| `aim_boost {to}` | **New.** `draft.boost_target_set(draft.held)`, then `set_boost_to`. A held Boost card is put down afterwards |
| `put {target}` | Targets as in TurnDraft. Tapping a card while another is held is `put {card: id}` |
| `toggle_give_up_reserve` | Kept, now sent by the action-row button |
| `set_boost_to`, `toggle_boost_to` | Kept (keyboard `B`, tests) |
| `select_slot`, `take_back` | **Removed.** Every card has a position, so there is nothing to select or take back |
