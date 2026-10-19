# Research: Drawn Cards and the Key Card at the Region Card's Size

All decisions below come from reading the code as it stands after 013:
- `ui/widgets/deck_stack.gd`, `hand_tray.gd`, `card_face.gd`, `region_card.gd` and `region_panel.gd`
- `ui/fx/animator.gd` and `ui/model/sequencer.gd`
- `ui/theme/tokens.gd` and `stone_style.gd`

There are no open NEEDS CLARIFICATION items.

## R1 — Where a drawn card starts, and how it gets to the Hand

**Today**:
- `Animator._run("draw")` calls `screen.render(_after, true, screen.point("deck"))`.
- `HandTray.sync` places each new card at a rect 0.3 × its Hand size, centred on that point, with `modulate.a = 0`.
- `_glide` tweens `position`, `size` and alpha over `T.MOVE`, staggered by `T.STAGGER`.

**Decision**:
- `DeckStack` gains `top_rect() -> Rect2`, in global coordinates. It returns the whole top card's resting rect: `card_rect(size, "card", …)`, whatever the current view.
- `PlayScreen.render` passes that rect as `arrive_from`, and `HandTray.sync` accepts a `Rect2`.
- A new card starts at exactly that rect, at full alpha.
- `_glide` tweens `position` and `size` together to `home`, with the same easing, so both finish on the same frame.
- The flight gets its own duration, `T.DRAW_FLY` (0.45 s, up from 0.35). It covers a longer path and a size change.
- The draw step's duration becomes `minf(T.DRAW_FLY + T.STAGGER × (n − 1), 1.2)`.

**Rationale**:
- Tweening `size` keeps the card sharp. `CardFace` draws every part as a share of its own size, which is how Hand cards already resize between layouts.
- The aspect is identical, so position and size moving together keep the shape exact (SC-002): `RegionCard.ASPECT` = 5/7 and `T.CARD_ASPECT` = 190/266 = 5/7.
- The Hand is added to `PlayScreen` after the left column, so a card in flight draws over the Deck and the gap without any z-index work.

**Reduced motion**: unchanged. The card snaps to `home` and fades in over `T.FAST` (FR-010).

**Alternatives rejected**:
- **Tweening `scale` instead of `size`.** It blurs the text and fights `HandTray`'s layout, which reads `size`.
- **A separate flight layer copy that swaps into the Hand on landing.** It adds a swap frame, and SC-001 asks for an exact landing.

## R2 — The Key Card at the Region Card's width

**Today**:
- `peek()` sets `_peek.size = _card_size`, the Hand's card size, and centres it under the Region Card.
- `peek_h(_card_size)` is the band plus the strip: 0.155 h + 0.09 h.
- `card_rect` reserves `peek_h − dip` above the Region Card for the rise.

**Decision**:
- The Key Card's size is the Region Card's size: `RegionCard.card_size(cr.size.x)`. Its `x` is `cr.position.x`, so the sides line up exactly.
- The rise therefore depends on the Region Card's height. `card_rect` solves for it in closed form. With `k = PEEK_FRAC` (0.245) and `e = T.DECK_EDGE`:
  - when the card is height-limited and `k·h/2 ≥ e`: `h = (f.h + e) / (1 + k)`;
  - otherwise: `h = f.h / (1 + k/2)`.
  - The width-limited case is unchanged.
- `peek_h(card_size)` keeps its formula and is called with the Region Card's size.
- `set_card_size`, and `_card_size` in `DeckStack`, are removed, since nothing else uses them.

**Rationale**: the room is derived from the card that actually rises. No new constants are needed.

**Risk**: on a height-limited column the Region Card loses about 0.1 h. `ui_check`'s whole-card numeral check from 013 (≥ 22 at the 400 column) guards this. The narrow columns are width-limited, so this is expected to hold. If a shape fails, the fallback is a deeper dip (up to `peek_h / 2`), so the Deck sinks further while the Key Card rises.

## R3 — The two highlights, and the Key Card staying out

**Today**:
- `peek()` rises, holds 0.4 s and falls. `CardFace.set_model(m, ["encounter"])` already draws a gold ring (`_ring`, `glow = T.GOLD`) round the Encounter mark for the whole peek.
- `RegionCard.set_focus(key, amount)` dims every panel but `key`. The landed face uses it at 1.0.

**Decision**: `key_peek` is reshaped, and `zoom_in` takes over the fall.

1. **Rise**, `T.PEEK_RISE` (0.25). The Key Card comes up with no ring yet.
2. **The number is lit**, `T.KEY_LIT` (0.35).
   - The ring round the Encounter icon and number fades in, and the mark gains a gold wash behind it: the leafed-gold treatment used for the chosen Boost (`boost_aim.gd`).
   - The Hardship beside it is not ringed, but stays visible (US3 scenario 4).
   - This uses a new `CardFace.lit` amount (0–1) for the `"encounter"` ring, instead of an always-on ring.
3. **The panel is lit**, `T.PANEL_LIT` (0.45). It starts at 60% of step 2, so the two overlap, as the clarification allows.
   - `RegionCard.set_focus(key, amount)` tweens 0 → 1.
   - `RegionCard` also draws a gold rim round the focused panel at `amount`, at the same width as the Key Card's ring.
   - Both highlights then hold.
4. The step ends with the Key Card **still raised** and both highlights on.

`zoom_in` then starts. If the Key Card is up, it slides down over the first `T.PEEK_FALL` (0.2) of the zoom, and the Deck's dip comes back with it, while the card grows about the lit panel. By the time the zoom lands:
- the Key Card's ring has faded with it;
- the panel's rim has faded to 0 (a rim on the landed face would read as a selection);
- the dimming stays at 1.0, as the landed face already does.

Timing:
- `key_peek` lasts `T.KEY_PEEK` = 1.05 s, laid out as follows:
  - the rise runs 0–0.25 s;
  - the number lights 0.25–0.60 s;
  - the panel lights 0.46–0.91 s;
  - both hold until 1.05 s.
- `zoom_in` = `T.ZOOM` (0.55).
- So the reveal, from the Hand settling to the face landing, is 1.6 s. That is within 3 s (FR-012), and `_fit_time` still never shortens it (`Sequencer.REVEAL`).

**Reduced motion**:
- The Key Card appears raised, with the dip already applied, fading in over `T.FAST`.
- The number is lit, then the panel is lit, as alpha fades, with no travel.
- In `zoom_in` the Key Card fades out with the cross-fade.
- The step keeps its full duration (`Animator.reduced_duration` already exempts `key_peek`).

**Skip and finish**: `DeckStack.finish()` already hides `_peek` and clears `set_focus`. It now also sets `lit = 0`. Undo builds no reveal steps, so nothing replays (FR-013).

**Rationale**: everything reuses existing marks (the ring, the focus dimming, gold as the "chosen" colour), so no new visual language is introduced.

**Alternatives rejected**:
- **A pulse or bounce on the number.** It is motion in reduced-motion mode, and it reads as "tap me".
- **Arrows from the Key Card to the panel.** Busy, and they cross the title band.

## R4 — The Deck as a face-up pile of cards

**Today**:
- `_draw_edges` draws up to 8 square rects (`T.BG_RAISED`, with a bronze line), each offset by `EDGE_STEP` (3) down and right of the top card's rect.
- `edges(n) = clamp(ceil(n/2), 1, 8)`.

**Decision**: a pure `DeckStack.edge_rects(stack: Rect2, n_cards: int) -> Array[Rect2]` lays out the edges.
- **Count**: `edges(n)` is unchanged, so FR-014 holds (at least 1 while there are cards, capped).
- **Offsets**: each edge `i` is offset `EDGE_STEP × i` down and right. A fixed jitter is added from a small table indexed by `i`: ±1 px across, 0 to +1 px down. This makes the pile slightly uneven. It is stable across frames and counts, so nothing shimmers as the Deck thins.
- **Corners**: every edge is a rounded rect with radius `card_radius(w) = roundi(w × 0.075)`. That is `CardFace`'s own ratio, so the corners match the cards at any scale (FR-016).
- **Fill and line**: each edge is filled with a card-stock tone, `T.CARD_EDGE`, a warm pale grey: the side of a card. A thin `T.CARD_EDGE_LINE` separates it from the next edge. No Ether colour and no per-card data reach the drawing; the only input is the count (FR-015).
- **Shadow**: a soft shadow under the whole pile, made of 4 stacked rounded rects, each 2 px larger, at alpha 0.10 → 0.03, offset (2, 4) from the bottom edge.
- **Zoomed in**: the same edges hang from the face's rect (`_stack_rect`), as today (US5 scenario 5).

**Rationale**: the edges draw with `StyleBoxFlat` rounded corners in `_edges._draw`, which is cheap at up to 8 edges and a 4-layer shadow. The pile reads as card stock because it is lighter than the stone around it and has card-shaped corners.

**Alternatives rejected**:
- **Showing card backs.** The clarification fixed the pile as face-up. A side view shows card edges.
- **A count badge.** Already in the header, and it does not make the pile look like cards.

## R5 — Rounded corners on the Region Card and the Dragon Card

**Finding**: `RegionCard` and `DragonCard` draw their outline with `StoneStyle`, which has chamfered (cut) corners. Mage Cards are rounded (`CardFace`: radius 0.075 w). FR-016 and the spec's premise ("the Region Card is just another card") need the top cards rounded too.

**Decision**:
- `StoneStyle` gains `round_radius: float` (0 = chamfer, as now).
- When it is set, the outline, bevel and edge line follow a rounded rect.
- `RegionCard` and `DragonCard` set it to `card_radius(size.x)` in `_fit()`.
- The stone fill and band are unchanged. The band's top corners are clipped by drawing it inside the rounded outline, using `draw_style_box` with matching top radii.
- The landed face, which is a crop of the card, is unaffected. The note keeps its own look.

**Rationale**: this is the smallest change that makes the top card and the pile one family of cards. Every other stone panel keeps its chamfer.

## R6 — The Final Battle and the edge cases

- **Final Battle**: `top_rect()` returns the Dragon Card's rect, so draws in the Final Battle and after a Regroup start at the Dragon Card's size. There is no `key_peek`, so there are no highlights.
- **Draw while zoomed in**: `top_rect()` always uses the zoomed-out `card_rect`, so the start is the whole card's resting place (spec, edge cases). Today every draw follows a `zoom_out`, a `turn_card` or `show_card`.
- **Larger Hand cards**: R1 tweens to `home.size`, whichever way that goes.
- **Out of scope**: other motion stays as it is. The `gather_shuffle` fly to the Deck, the `discard {from: deck}` and `pay_time` ghosts, and `_away` all keep their motion.

## R7 — Tests and tools

- **`tests/test_deck_stack.gd`**:
  - `card_rect` with the Region-width peek, for both closed-form branches and the width-limited case: the room above the card equals `peek_h(card) − dip`.
  - `peek` geometry: the Key Card's rect has the same `x` and width as `card_rect`.
  - `edge_rects`: the count follows `edges(n)`, `n = 0` gives none, the jitter stays within ±1 px, the result is the same on every call, and each rect has the card's size.
  - `card_radius(190) == 14`.
- **`tests/test_sequencer.gd`**: `key_peek` lasts `T.KEY_PEEK` (1.05 s), and the reveal (`key_peek` + `zoom_in`) is ≤ 3.0 s. This supersedes 012's ≤ 1.4 s invariant. The `draw` duration follows the new formula.
- **`tests/test_card_face_layout.gd`**: `lit` 0 draws no ring and 1 draws the ring.
- **`tools/ui_check.gd`**, at every `MATRIX` shape:
  - The first frame of a drawn card equals `deck.top_rect()` within 2 px, and the last equals `home` within 2 px. The width-to-height ratio is within 1% at the sampled frames.
  - The raised Key Card's left and right edges match the Region Card's within 2 px.
  - Event order in a reveal: `key_lit`, then `panel_lit`, then the start of `zoom_in`. `DeckStack` emits `reveal_beat(name)` for this, and the lit panel is the zoom target.
  - No Ether colour in the edges: `edge_rects` takes only a count, so this is asserted structurally.
- **`tools/design_shots.gd`**: a `draw` shot (mid-flight, at 0.5), a `reveal` shot (both highlights on) and a `pile` shot (a full Deck and a 3-card Deck), at phone-tall and desktop.

## R8 — Documents

- **`specs/012-deck-region-card/contracts/reveal-sequence.md`**: a superseded-in-part note. The `key_peek` timing and invariant 6 now follow 014.
- **`specs/013-physical-region-card/contracts/left-column.md`**: a note that the stack's edges are drawn per 014 R4.
- **README**: no change.
