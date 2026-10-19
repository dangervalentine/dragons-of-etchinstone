# Contract: The Deck Pile

This updates `specs/013-physical-region-card/contracts/left-column.md` for how the stack's edges are drawn. The layers and their order are unchanged.

## Drawing (`DeckStack._draw_edges`), back to front

1. **Shadow**: 4 rounded rects round the bottom edge's rect. Each grows by 2 px, is offset (2, 4), and has alpha 0.10, 0.07, 0.05 and 0.03. The radius is `card_radius(w) + growth`.
2. **Edges**: `edge_rects(_stack_rect, count)`, deepest first. Each is a rounded rect, radius `card_radius(w)`, filled `T.CARD_EDGE`, with a 1.5 px `T.CARD_EDGE_LINE` rim.
3. Then the top card, or the face (as today).

## Rules

| Rule | Check |
|---|---|
| The edge count is `edges(count)`: none at 0, at least 1 for ≥ 1, at most `EDGES_MAX` | `test_deck_stack` |
| The input is the count only. No card model, Ether or id reaches the pile | Structural: `edge_rects(stack, n)` signature |
| The jitter is fixed per edge index, within ±1 px across and 0 to 1 px down | `test_deck_stack` |
| The corner radius equals the cards' (`0.075 w`) | `test_deck_stack`: `card_radius` |
| The top card is rounded alike: Region Card and Dragon Card outlines use `StoneStyle.round_radius = card_radius(w)` | `ui_check` shot review; `design_shots` `pile` |
| Zoomed in, the edges hang from the face's rect | Unchanged from 013 |
| The pile and its shadow stay inside the left column at every `MATRIX` shape | `ui_check` (existing bounds check) |
