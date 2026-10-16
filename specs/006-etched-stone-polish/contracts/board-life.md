# Contract: A Board That Answers (US4)

Revised: no ambient effects. The response table is `ui/model/board_response.gd`;
responses play through `play_screen.flare()`.

## While idle

Nothing moves except the **waiting zone's edge**: the Hand while a card is to be
chosen, or Play once the set is ready. Its 3-unit focus edge brightens and dims over
about 3 s. It is still under reduced motion.

## Responses

| Event | Box | Normal | Reduced motion |
|---|---|---|---|
| `place` | the slot | number flies in (role-slots.md); edge flashes in the card's Ether | number appears; edge held in the Ether for `T.BASE` |
| `take_back` | the slot | number fades; edge flashes neutral | cleared at once |
| `fuse` | Hand | edge flashes in the fused Ether | edge held |
| `divert`, `regroup` | header | edge flashes neutral | edge held |
| `play` | Encounter | edge flashes in its Ether | edge held |
| `hit_enemy` | Encounter | small shake and Ether edge flash | edge held |
| `take_damage`, `soak` | Hand | edge flashes red | edge held |
| `upgrade` | Hand | edge flashes gold | edge held |
| `encounter_won` | Encounter | edge flashes gold | edge held |
| `encounter_lost` | Encounter | edge dims red | edge held |
| a total changes | math box | the total counts to its new value | changes at once |

## Guarantees

- Every event has both forms (`tests/test_board_responses.gd`).
- Responses never delay input, and they can be skipped with the animator's skip.
- No particles, glows or moving patterns anywhere (FR-016, SC-006).
