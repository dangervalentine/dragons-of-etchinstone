# Contract: Role Slots (US1)

Replaces the compact role rail (revision 1). Data shape:
[data-model.md § RoleSlot](../data-model.md#roleslot-view).

## Placement (research R3)

- **Slot band**: the top of the right column, `SLOT_BAND_H` (184 at 1280 × 720) tall.
  The slots take the band's width less the action column.
- **Action column**: to the right of the slots, the same height.
  - Up to four secondary actions, in a 2 × 2 grid (each ≥ 88 × 88; icon and short
    label).
  - With two or fewer, two full-width rows.
  - In the Final Battle (at most three), a single column of icon-over-label buttons,
    so the six slots keep ≥ 88 each.
- **No button row under the Hand.** The Hand takes the column's remaining height.
- **Play**: at the foot of the math box (contracts/math-box.md), or, by the R3
  fallback, the bottom-right corner under the Hand.
- **Steps without roles** (Soak, Upgrade): the band shows the recap of the set just
  played, and the action column shows that step's actions (for example Undo
  Upgrade).

## What a slot shows

| State | Shows | Tap |
|---|---|---|
| `empty` | Role icon and name, muted | `select_slot` |
| `next` | Role icon and name, focus edge | `select_slot` |
| `filled` | Role icon (small); the **number** (large); what it counts toward (icon). Spell: the engine's Spell term value. Element: Ether icon + Initiative. Boost: `+n`, with its target icon (Attack/Initiative), which toggles on tap against an Enemy | the body: `take_back`; the Boost target icon: `toggle_boost_to` |
| `played`, `kept`, `discarded` (recap) | Number struck through, or the Reserve's fate | `inspect {id}` |

No slot shows a card's name (FR-002); the tooltip does.

## Number flight (FR-003)

- On a placement that succeeds, the number flies from the placed card to its slot
  (`FlightLayer.fly_text`) in `T.MOVE`. Then the slot shows it, and the board
  response `place` flashes the slot's edge.
- On take-back, the slot's number fades and the slot returns to `empty`.
- When a later placement changes a slot's number (the Element enabling the enhanced
  Spell), that slot's number counts to the new value and flashes its edge (FR-004).
- Under reduced motion, numbers appear and change at once.

## Guarantees

- Every intent the rail could send can still be sent: `select_slot`, `take_back`,
  `toggle_boost_to`, and `inspect` from the recap.
- Slots ≥ 88 on the shorter side; text ≥ 22; the slot's large number ≥ 32.
- Hand cards are no smaller than the baseline (`test_hand_cards_are_no_smaller_than_before`).
- No zone is more than a third empty at the minimum sizes (`ui_check` space check).

## Tests (`tests/test_role_slots.gd`, replacing `test_role_rail.gd`)

- Slot shaping:
  - empty, next and filled states;
  - the Spell number equals the engine's Spell term (basic, enhanced, or 1 with no
    fitting action);
  - it changes when an Element enables the enhanced action;
  - Element and Boost numbers;
  - the Boost target;
  - no `name` field;
  - the two-set Final Battle;
  - the recap with `inspect` taps.
- Tap intents match the old slot intents for the same states.
