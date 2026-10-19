# Contract: Reveal Steps in Each Sequence

What `Sequencer.build(before, action, result, after)` emits for the Deck. `test_sequencer.gd` checks this table. The existing steps are unchanged except where they are shown here, in order. `…` stands for the existing steps that stay where they are.

## New steps

| Kind | Values | State change (`apply`) |
|---|---|---|
| `zoom_out` | `{}` | none |
| `turn_card` | `{from: int, to: int \| "dragon"}` | none |
| `key_peek` | `{key: after.deck[0], kind, index, hardship}` | none |
| `zoom_in` | `{target: after-view zoom}` | none |

The **reveal** is `key_peek` (Regions only) followed by `zoom_in`. It follows the draw that dealt the Hand. In a `finish` that ends Knocked Out by poison, it comes after the knock-out steps, because the time paid comes off the top of the Deck and changes the Key Card. `_fit_time` never shortens it, and in reduced motion `key_peek` keeps at least 0.6 s (`Animator.reduced_duration`).

## Per action

| Action (case) | Steps |
|---|---|
| `start` (first Encounter) | `stage_banner`, `draw`, **`key_peek`, `zoom_in`** |
| `setup` | `…level steps`, `gather_shuffle`, **`turn_card {from: 0, to: 1}`**, `stage_banner`, `draw`, **`key_peek`, `zoom_in`** |
| `play` (Region, any outcome) | unchanged: the face stays zoomed in through Penalty and Upgrade |
| `upgrade`, `soak` | unchanged |
| `finish`, same Region | `xp_lost`?, **`zoom_out`**, `discard`, `draw`, (`damage`/`knock_out`… if any), **`key_peek`, `zoom_in`** |
| `finish`, next Region (1→2, 3→4) | `xp_lost`?, **`zoom_out`**, `discard`, `gather_shuffle`, **`turn_card {from, to}`** (half-turn), `stage_banner`, `draw`, **`key_peek`, `zoom_in`** |
| `finish`, Region 2→3 | as above; `turn_card` swaps the card |
| `finish`, Region 4 → Final Journey | `xp_lost`?, **`zoom_out`**, `discard`, `gather_shuffle`, **`turn_card {from: 4, to: "dragon"}`**, `stage_banner`, `draw`, **`zoom_in {target: "mp"}`** |
| `finish` → `poison` phase | the reveal comes before the poison `damage` step. The Encounter is shown first, then the poison lands on the new Hand |
| `divert` | **`zoom_out`**, `discard {from: deck}` (the old Key), `discard {from: hand}`, **`key_peek`, `zoom_in`** |
| `play_final`, Final Journey → Final Enemy | `play_cards`, `tally`, `verdict`, `gain_xp`?, **`zoom_out`**, `discard`, `pay_time`?, `stage_banner`, `draw`, **`zoom_in {target: "hp"}`** |
| `play_final`, other | unchanged |
| `regroup` | **`zoom_out`**, `discard`, `gather_shuffle {keep_discard}`, `draw`, **`zoom_in {target: "mp"}`** |
| any → `won`/`lost` | no reveal; `ending` last as today |

## Invariants (tested)

1. `key_peek.values.key == after.deck[0]`, and `{kind, index, hardship}` equal the engine's `encounter()` after the action.
2. `zoom_in.values.target == ViewState.build(...).zoom` for `after`.
3. Every `zoom_in` comes after a `zoom_out` in the same sequence, except for `start`/`setup`, where the stack starts zoomed out.
4. `key_peek` never appears in the Final Battle.
5. Replaying all steps with `apply` on `before` still yields `after` for hand, discard and trash (the existing test), since the new steps change nothing.
6. The sum of durations before the reveal is ≤ `T.SEQUENCE_MAX`. The reveal itself is ≤ 1.4 s (SC-003: ≤ 2 s from the Hand settling).

## Animator behaviour (`ui/fx/animator.gd`)

| Step | Motion | Reduced motion |
|---|---|---|
| `zoom_out` | `deck.zoom_out(d)` (research R3) | cross-fade `2 × FAST` |
| `turn_card` | `deck.turn_to(after.top_card, d)` (R6) | cross-fade |
| `key_peek` | `deck.peek(after.key_face, d)`: rise 0.25 / hold 0.4 / fall 0.2 (R4) | fade in raised (`T.FAST`), hold (≥ 0.3), fade out (`T.FAST`): at least 0.6 s in all. This is the one step besides `stage_banner` that the reduced-motion clamp (`minf(d, 2 × T.FAST)`) doesn't shorten, so the strip can still be read (FR-011) |
| `turn_card` from `0` (setup) | the Region Card drops onto the stack and fades in | fade in |
| `zoom_in` | `deck.zoom_in(target, d)`, then release the creature | cross-fade, creature stays still (reduced motion) |

- At `play()`: if the steps contain `zoom_in`, call `deck.hold_card(true)`.
- At `_finish()` (end or skip): `deck.finish()` is called before `screen.render(_after)`. `held` is cleared, so the face shows zoomed in on `_after.zoom`.
