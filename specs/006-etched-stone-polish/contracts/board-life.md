# Contract: Board Life (US3)

Ambient motion and the board's response to each action. Data shapes:
[data-model.md § RiftLight, BoardResponse](../data-model.md).

## Ambient motion (idle play screen)

| Element | Where | Normal | Reduced motion |
|---|---|---|---|
| Seam shimmer | Backdrop seams | Slow per-seam brightness drift in the Ether's behaviour (stone-and-rift.md) | Frozen at the mean |
| Motes | `rift_layer.gd`, from the rift source | ≤ `MOTES_MAX` alive, 4–7 s lifetime, drifting up and out, Ether-tinted, low alpha | None |
| Active-zone breath | The zone named by `vs.input_region` | Rim glow at 1, breathing ±15% over about 3 s | Rim glow at 1, still |

**Guarantees**
- At least two kinds of ambient motion are visible on the idle play screen (FR-013,
  SC-006): the seam shimmer and the motes.
- Nothing flashes. Brightness never changes by more than 30% in under 0.25 s, except
  the lightning jolt (one at most per 4 s, ≤ 40%).
- During an animator sequence, motes stop emitting and the shimmer drops to half
  amplitude.
- While an overlay covers the screen, the ambient motion pauses (as the card fields do
  today, `set_fields_live`).

## Active zone

| `vs.input_region` | Lit zone |
|---|---|
| `hand` | Hand well |
| `rail` | Role rail (a role choice or Boost-to pending) |
| `preview` | Preview, Soak meter or XP purse (the decision is read there) |
| `commit` | The primary action's plinth (with today's `actions.set_ready`) |

The light moves with a `T.BASE` cross-fade, or instantly under reduced motion
(FR-014).

## Responses

| Event | Normal | Still (reduced motion) |
|---|---|---|
| `place` | The rail token flares in the card's Ether; the Hand rim brightens briefly | The token is tinted for `T.BASE` |
| `take_back` | The token's contribution fades and falls 6 units | Instant clear |
| `fuse` | Seams near the Hand flare in the fused Ether | Hand rim in the Ether for `T.BASE` |
| `divert`, `regroup` | A cold sweep runs along the header lintel | The header rim is tinted |
| `play` | Seams surge toward the Encounter frame | Encounter rim in the Ether for `T.BASE` |
| `hit_enemy` | Encounter frame shudders (reusing `UI.shake`) and dust motes burst | Encounter rim flashes once at reduced alpha |
| `take_damage`, `soak` | A crack flash crosses the Hand well and the seams redden briefly | Hand rim in `T.BAD` for `T.BASE` |
| `upgrade` | The upgraded card's rim goes gold, with a short rise of motes | Card rim gold |
| `encounter_won` | Seams brighten everywhere, then settle; the tint eases toward neutral | Seams held bright for `T.BASE` |
| `encounter_lost` | Seams dim and redden | Seams held dim for `T.BASE` |

**Guarantees**
- Every event has both forms (`tests/test_board_responses.gd`).
- Responses never delay input. They are decorative and skippable with the animator's
  existing skip.
- Responses never move or cover a card the player must read.

## Performance

- `tools/field_bench.gd` adds the backdrop, seams and motes to its 11-face scene. It
  still needs PASS: average ≤ 16.7 ms, p99 ≤ 33 ms.
- Fallbacks, in order: motes to 12, then Ether behaviours to the plain shimmer.
- On the web build and Android emulator: no visible stutter while idle, placing
  cards or resolving (SC-008), judged by eye.
