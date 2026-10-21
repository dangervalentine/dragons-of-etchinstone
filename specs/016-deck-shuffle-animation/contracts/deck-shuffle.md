# Contract: The Deck Shuffle

This is the interface between the Sequencer, the Animator and the `DeckStack` widget for the shuffle. See [data-model.md](../data-model.md) for the step's fields.

## Sequencer → Animator

`Sequencer.build()` returns these step orders. Only the steps that matter here are shown; other steps may come between them, but never between `shuffle` and the step before it.

```text
start:    shuffle → stage_banner → draw → key_peek → zoom_in
setup:    …levels… → gather_shuffle{undraw} → turn_card{0→1} → shuffle → stage_banner → draw → key_peek → zoom_in
finish (Region r → r+1):
          zoom_out → discard{hand} → discard{deck}? → turn_card{r→r+1} → gather_shuffle{from: discard} → shuffle → stage_banner → draw → key_peek → zoom_in
finish (Region 4 → Final Battle):
          zoom_out → discard{hand} → discard{deck}? → turn_card{4→dragon} → gather_shuffle{from: discard} → shuffle → stage_banner → draw → zoom_in
```

No other action's steps contain `shuffle`.

## Animator → DeckStack

| Step | Call | Notes |
|---|---|---|
| `shuffle` | `screen.deck.shuffle(faces, d)` | `faces` are `st.values.models[id]` for `id` in `st.cards`. `d` is `st.duration` in both modes (it is in `reduced_duration`'s keep-its-time list) |

The Animator adds nothing else for `shuffle`: no ghost, no header bump, no `board_response`. The step is quiet.

## DeckStack

```gdscript
## The Deck shuffled under the card on top for `d` seconds, as NextQuest riffles
## its cards (research R4). Ended at once by finish().
func shuffle(models: Array, d: float) -> void

static func peel_lift(deck_size: Vector2, card: Rect2) -> float
static func peel_at(k: int, n: int, t: float) -> float
static func peel_count(ids: Array) -> int
```

**Guarantees**

1. **The top card stays put.** `top_node()` has the same position, scale and modulate throughout the step (FR-003, SC-003).
2. **Real cards, under the top card.** Only the `CardFace`s in `_riffle` move: real Mage Cards, face up, on a layer under `_tops`. The edge stack does not move, and no blank card stock is shown moving.
3. **Short of the Key Card.** No peel travels further than `T.SHUFFLE_PEEL × peek_h`, which is less than a Key Card's rise. Each stays inside `Rect2(Vector2.ZERO, size)` (FR-012).
4. **The stack's depth is fixed.** The number of edges drawn is `edges(count)` at every frame (FR-006).
5. **It is announced.** `reveal_beat("shuffle")` is emitted once, as the step starts.
6. **It ends clean.** After the tween ends or after `finish()`: `_shuffle_t == -1`, every peel is hidden and upright, and the label is hidden.
7. **Reduced motion moves nothing.** Under `UI.reduced_motion`, no card peels, and the label shows for the step's middle (FR-010, SC-005).
