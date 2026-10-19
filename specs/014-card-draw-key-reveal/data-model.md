# Data Model: Drawn Cards and the Key Card at the Region Card's Size

There is no game-state change. The engine, `ViewState` and the snapshots are untouched. Everything below is UI geometry, widget state and tokens.

## Tokens (`ui/theme/tokens.gd`)

| Token | Value | Use |
|---|---|---|
| `DRAW_FLY` | 0.45 | One drawn card's flight from the top card to its Hand place (R1) |
| `KEY_LIT` | 0.35 | The Key Card's Encounter number lighting up (R3) |
| `PANEL_LIT` | 0.45 | The matching panel lighting up; starts at 60% of `KEY_LIT` (R3) |
| `KEY_PEEK` | 1.05 | The whole `key_peek` step: rise, number lit, panel lit, hold (R3) |
| `PEEK_HOLD` | removed | The hold is now the highlights |
| `PEEK_RISE`, `PEEK_FALL` | unchanged (0.25, 0.2) | The rise, and the fall at the start of `zoom_in` |
| `CARD_EDGE` | warm pale grey, e.g. `Color("8d8778")` | The side of a card in the pile (R4) |
| `CARD_EDGE_LINE` | darker, e.g. `Color("4a463e")` | The line between edges (R4) |

## Pure geometry (`DeckStack`, static)

| Function | Returns | Rule |
|---|---|---|
| `card_rect(deck_size, v, peek: bool)` | `Rect2` | As today when width-limited. When height-limited with a Key Card above, the height is solved so that `room = peek_h(card) − dip(peek_h(card))` (R2). `peek` replaces the old `peek_h` argument |
| `peek_h(card_size)` | `float` | Unchanged formula, now given the Region Card's size |
| `key_rect(deck_size, raised: bool)` | `Rect2` | The Key Card: `card_rect`'s `x`, width and height. Its `y` is `card_rect.y` at rest, or `card_rect.y + dip − peek_h` when raised |
| `card_radius(width)` | `int` | `roundi(width × 0.075)`, matching `CardFace` |
| `edges(n)` | `int` | Unchanged: `clamp(ceil(n/2), 1, EDGES_MAX)`, and 0 for n ≤ 0 |
| `edge_rects(stack, n)` | `Array[Rect2]` | `edges(n)` rects of `stack.size`, the i-th (1-based) at `stack.position + Vector2.ONE × EDGE_STEP × i + JITTER[i−1]`, deepest first |
| `JITTER` | `const Array[Vector2]` | 8 fixed offsets in `[-1, 1] × [0, 1]` |

## `DeckStack` instance changes

| Member | Change |
|---|---|
| `_card_size`, `set_card_size()` | Removed. The Key Card is sized from the Region Card (R2) |
| `top_rect() -> Rect2` | New. The global rect of the whole top card at rest: `card_rect(size, "card", …)` plus `global_position`, whatever the view (R1, R6) |
| `peek(face_model, target, d)` | `target` is `_after.zoom`. Rise, then light the number, then light `target`'s panel. It ends raised (`_peek_up = true`) and does not settle the view (R3) |
| `zoom_in(target, d)` | If `_peek_up`: slides the Key Card down and undoes the dip over `PEEK_FALL`, and fades the panel rim to 0 by the time it lands. Reduced motion: the Key Card fades out with the cross-fade |
| `_peek_up: bool` | New. True from the end of the rise until the fall is done |
| `signal reveal_beat(name)` | New. Emits `"key_lit"`, `"panel_lit"` and `"zoom"` for `ui_check`'s order assertion |
| `finish()` | Also sets `_peek_up = false`, `_peek.lit = 0` and `region_card.set_rim(0)` |
| `_draw_edges()` | Draws a soft shadow, then `edge_rects` as rounded `CARD_EDGE` rects with a `CARD_EDGE_LINE` rim (R4) |

## Other widgets

| Widget | Change |
|---|---|
| `CardFace` | `lit: float` (0–1). It scales the `"encounter"` ring and its gold wash. `set_model(m, ["encounter"])` no longer forces the ring on; the ring shows at `lit` |
| `RegionCard` | `set_rim(amount)`: a gold rim round `focus_key`'s panel. `_fit()` sets the outline's `round_radius = card_radius(size.x)` |
| `DragonCard` | Rounded outline, as for `RegionCard` |
| `StoneStyle` | `round_radius: float` (0 keeps the chamfer). When set, the outline, bevel and edge follow a rounded rect |
| `HandTray.sync(vs, plan, animate, arrive_from)` | `arrive_from: Rect2` (global). A fresh card starts at it with alpha 1 and glides `position` and `size` over `DRAW_FLY` |
| `PlayScreen.render(state, animate, arrive_from)` | Passes the `Rect2` through. `deck.set_card_size` is no longer called |
| `Animator` `"draw"` / `"key_peek"` | `screen.render(_after, true, screen.deck.top_rect())`; `screen.deck.peek(_after.key_face, _after.zoom, d)` |
| `Sequencer` | `DURATION.key_peek = T.KEY_PEEK`. `_draw_step` duration is `minf(T.DRAW_FLY + T.STAGGER × (n − 1), 1.2)` |

## State over a reveal

```text
Hand settled ─▶ key_peek: rise ─▶ number lit ─┬─▶ panel lit ─▶ (hold, Key Card up)
                                              └── overlap 40% ──┘
             ─▶ zoom_in: Key Card falls (0.2) + card grows about the panel (0.55)
                         rim → 0, ring → 0, dim stays 1.0 ─▶ landed face
skip / finish at any point ─▶ landed face, _peek hidden, lit 0, rim 0
```
