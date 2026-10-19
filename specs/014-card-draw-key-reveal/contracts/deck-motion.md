# Contract: The Draw and the Key Card Reveal

This supersedes in part `specs/012-deck-region-card/contracts/reveal-sequence.md`, for the `key_peek` timing, the reveal's length and the `draw` start. Its step order per action is unchanged.

## Steps (`Sequencer`)

| Step | Duration | Change from 012/013 |
|---|---|---|
| `draw` | `minf(T.DRAW_FLY + T.STAGGER × (n − 1), 1.2)` | Longer flight, from the top card's rect |
| `key_peek` | `T.KEY_PEEK` (1.05) | Rise, then the number lit, then the panel lit, ending raised; no fall |
| `zoom_in` | `T.ZOOM` (0.55) | Starts with the Key Card's fall if it is raised |

Invariants (tested in `test_sequencer.gd`):

1. `key_peek` is always directly followed by `zoom_in`.
2. `key_peek` + `zoom_in` ≤ 3.0 s (FR-012). At the defaults this is 1.6 s.
3. `key_peek` never appears in the Final Battle (unchanged).
4. 012's other invariants hold.

## The draw (`Animator` → `PlayScreen` → `HandTray`)

| | Motion | Reduced motion |
|---|---|---|
| Start | Each new card at `deck.top_rect()`, alpha 1 | At `home`, alpha 0 |
| Flight | `position` and `size` tween together to `home` over `DRAW_FLY`, cubic in-out, staggered `T.STAGGER` | Alpha → 1 over `T.FAST` |
| End | Exactly at `home` | Same |

- A card is always face-up: its `CardFace` is drawn at every frame of the flight.
- In the Final Battle, `top_rect()` is the Dragon Card's rect.

## The reveal (`DeckStack`)

| Beat | t (s) | Motion | Reduced motion | `reveal_beat` |
|---|---|---|---|---|
| Rise | 0–0.25 | Key Card (Region Card width, sides aligned) rises to `key_rect(raised)`; Deck dips | Appears raised, fades in (`T.FAST`); dip applied | — |
| Number lit | 0.25–0.60 | `_peek.lit` 0 → 1: gold ring and wash on the Encounter icon and number; Hardship visible, unringed | Same, by alpha | `key_lit` at 0.25 |
| Panel lit | 0.46–0.91 | `region_card.set_focus(target, 0→1)` and `set_rim(0→1)` | Same, by alpha | `panel_lit` at 0.46 |
| Hold | to 1.05 | Key Card stays up, both lit | Same | — |
| `zoom_in` | 0–0.55 | The Key Card falls to rest and the dip returns over 0.2. The card grows about the panel. Ring and rim → 0 by landing; dim stays 1 | Cross-fade; the Key Card fades out with it | `zoom` at 0 |

- `target` is the `zoom_in` target. It is passed to `peek` by the animator (from `_after.zoom`), so the lit panel is the zoomed panel.
- Skip and finish: `deck.finish()` leaves the landed face with no Key Card, `lit = 0`, `rim = 0`.
