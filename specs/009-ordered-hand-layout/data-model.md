# Data Model: Ordered Hand and Play-Board Layout

Everything here lives in the UI model (`ui/model/`). The engine's data is unchanged (research R1).

## TurnDraft (`ui/model/turn_draft.gd`) — changed

| Field | Type | Meaning |
|---|---|---|
| `set_count` | int | 1 in a Region, 2 in the Final Battle (unchanged) |
| `sets` | Array[Dictionary role → id] | The Roles. Remains the only record of which card fills which Role (unchanged) |
| `active` | [set, role] | The hinted next place. It no longer receives cards by itself (R2) |
| `boost_to`, `fuse`, `fuse_pick`, `mode`, `give_up_reserve`, `picks` | — | Unchanged |
| **`held`** | String or null | The card picked up and waiting for a place |
| **`reserve`** | String or null | The card the player put in the Reserve place |

**Derived**

- `reserve_card()`: the card in the Reserve place, which is either:
  - `reserve`, if set; or
  - the one floating card left, when every role place is filled and the Reserve place is offered (Region with four cards, or Final Journey).
- `floating(hand)`: Hand cards that are in no Role, are not the Reserve, and are not the tucked half of a Fuse. Kept in Hand order.
- `place_of(id)`: `[set, role]`, `"reserve"`, or null when the card is floating.

**Operations**

| Operation | Effect |
|---|---|
| `pick(id)` | Sets `held = id`. Picking the held card again clears `held`. Refused for the tucked card of a Fuse ("That card is tucked behind another. Unfuse to use it."). |
| `put(target)` | Moves `held` to `target` (`[set, role]`, `"reserve"`, `"floating"`). If `target` holds a card, that card goes to `held`'s old place, or to floating if `held` was floating. Then clears `held` and recomputes `active`. Refused: `"reserve"` when the Reserve place is not offered (Hand under four in a Region; Final Enemy). |
| `put_down()` | Clears `held`. Nothing else changes. |
| `take_back(id)` | Same as `pick(id)` then `put("floating")`. Kept for the recap and existing callers. |
| `drop(id)` | Also clears `held` and `reserve` when they name `id`. |
| `choose_fuse_element` | As today. The tucked card also leaves `reserve` and `held`. |
| `reset`, `duplicate_draft` | Include `held` and `reserve`. |
| `to_action()` | Unchanged. The engine derives the Reserve itself. |

**Invariants**

- A card id appears at most once across `sets[*]` values and `reserve`.
- `held` is null whenever `mode != "none"`. Starting a mode puts the held card down.
- A tucked Fuse card is never in `sets`, `reserve` or `held`.

## Place (view model, `view_state.places`) — replaces RoleSlot

| Field | Type | Notes |
|---|---|---|
| `key` | String | `"reserve"`, or `"<set>/<role>"`, e.g. `"0/spell"` |
| `set` | int | 0 or 1. 0 for the Reserve |
| `role` | String | `reserve`, `element`, `spell`, `boost` |
| `card_id` | String or null | The card in it |
| `state` | String | `empty`, `next`, `target`, `filled`, `inactive`; recap: `played`, `kept`, `discarded`; Reserve: `given_up` |
| `number` | int or null | As RoleSlot today. The Reserve shows its Boost only while that Boost counts (`reserve_boosts`) |
| `counts_to` | String | `attack`, `initiative`, `move`, or `""` |
| `ether`, `boost_to`, `tooltip` | — | As RoleSlot |
| `tap` | intent | `{"type": "put", "target": key}` while a card is held; `{"type": "pick", "id"}` when filled and nothing is held; `{"type": "select_slot", ...}` when empty and nothing is held; `{"type": "inspect", "id"}` in the recap |
| `toggle_tap` | intent or null | Boost: `toggle_boost_to`. Reserve against a Ranged enemy: `toggle_give_up_reserve` |
| `set_start` | bool | True on the first place of Set 2, where the strip draws the divider between sets |

**Order**: see research R3. The index in `places` is the column the place and its strip section take.

## View state additions (`view_state.build`)

| Key | Type | Notes |
|---|---|---|
| `places` | Array[Place] | Empty in setup and Soak, which have no role strip |
| `floating` | Array[String] | Unplaced card ids in Hand order |
| `held` | String or null | |
| `cards[id].place` | String or null | Place key |
| `cards[id].state` | String | Gains `held`. `assigned` is kept for placed cards |
| `secondary` | Array | Give up Reserve removed (R5) |

## Layout plan additions (`layout_solver.solve`)

| Region key | Meaning |
|---|---|
| `strip` | The role strip band, `STRIP_H` tall |
| `places` | The places row band |
| `floating` | The floating band (one or two rows) |
| `actions` | The action row: full card-side width, `ACTION_ROW_H` |
| `secondary` | Array of the two quarter-width cells |
| `commit` | Play, the half-width cell |

| Key | Meaning |
|---|---|
| `card_size` | Fixed per Hand (R4, R6) |
| `place_rects` | Array[Rect2], one per place, filled height |
| `place_empty_h` | The outline height while all places are empty |
| `floating_rects(count)` | Rects for `count` floating cards, wrapped |
| `left_w` | 400–548 in Regions, `FINAL_LEFT_W` in the Final Battle |

The `hand`, `slots` and `card_rects` keys are removed. Callers move to the keys above.
