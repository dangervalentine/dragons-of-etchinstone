# Data Model: Shuffling the Deck Under the Card on Top

No game state changes. The engine's Deck order is untouched (FR-013). What is added is one Sequencer step kind and one transient view value on the Deck.

## Sequencer step: `shuffle`

| Field | Value |
|---|---|
| `kind` | `"shuffle"` |
| `cards` | The ids of up to `T.SHUFFLE_PEELS` of the Deck's cards that are seen peeling: the Deck's ids sorted and rotated by `(region × 3) mod size`, never the new order. `ui/main.gd` `_show_faces` attaches `values.models[id]` (`ViewState.plain_card`) for their faces |
| `values.count` | The size of the Deck being shuffled: the `values.deck.size()` of the gather before it, or `after.hand.size() + after.deck.size()` on `start` |
| `anchor` | `"deck"` |
| `duration` | `T.SHUFFLE` (0.9 s), its own time (`OWN_TIME`), unchanged in reduced motion |

**Rules**

- It appears only in `start`, `setup`, and a `finish` that changes Region or enters `final_journey`. It appears exactly once in each, and never in `divert`, `regroup`, `play`, `play_final`, `soak`, `upgrade` or an ordinary `finish`.
- It is omitted when `values.count` would be 0.
- It always follows the card on top being in place. In `setup` and in a Region-change `finish`, it comes after `turn_card`. In a Region-change `finish`, it also comes after `gather_shuffle {from: "discard"}`.
- It always precedes `stage_banner` and the first `draw`.
- `Sequencer.apply(state, shuffle)` returns `state` unchanged, so the replay tests still reach the after snapshot.

## DeckStack transient: the shuffle in progress

| Field | Meaning |
|---|---|
| `_shuffle_t: float` | `-1` when not shuffling. Otherwise how far through, 0 to 1, driven by a tween held in `_tweens` |
| `_riffle: Control` | The layer the peeling cards lie on: under `_tops`, over `_peek_clip` and `_edges` |
| `_peels: Array[CardFace]` | A pool of up to `T.SHUFFLE_PEELS` faces, made the first time they are needed |
| `_peel_n`, `_peel_under` | How many peel in this shuffle, and which have gone in under the rest |
| `_shuffle_label` | The "Deck shuffled" caption. It is visible only under reduced motion while the step plays |

**State transitions**

```text
idle (_shuffle_t = -1, peels hidden)
  └─ shuffle(models, d) ─► shuffling (0 → 1 over d; _place_peels() each step)
                              ├─ tween ends ─► idle
                              └─ finish()   ─► idle (immediately)
```

**Pure geometry** (static, tested headless)

- `peel_lift(deck_size, card: Rect2) -> float`: the signed distance the peeling cards travel, with negative meaning up. It is `min(room, peek_h(card.size) × T.SHUFFLE_PEEL)`, toward whichever of above or below the card has more room. The card moved by it stays on the Deck.
- `peel_at(k, n, t) -> float`: how far out the `k`th of `n` cards is, 0 to 1. It is 0 at t = 0 and t = 1, reaches 1 once, and the cards peak in order, each starting before the last is home.
- `peel_count(ids) -> int`: `min(ids.size(), T.SHUFFLE_PEELS)`.
