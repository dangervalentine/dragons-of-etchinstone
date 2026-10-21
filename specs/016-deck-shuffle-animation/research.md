# Research: Shuffling the Deck Under the Card on Top

All decisions below are grounded in the code as it stands on `main` (2026-10-20): `ui/model/sequencer.gd`, `ui/fx/animator.gd`, `ui/widgets/deck_stack.gd`, `ui/main.gd`, `engine/game.gd`. There were no open NEEDS CLARIFICATION items.

## R1. Where the game really shuffles the Deck

**Decision**: Four moments get a shuffle step:

| Action (Sequencer) | Engine shuffle | Card on top before the shuffle |
|---|---|---|
| `setup` | `Game._finish_setup` (and the deal in `_init`) | Region 1's card, laid by `turn_card {from: 0, to: 1}` |
| `start` (no setup offer to choose from) | `Game._init` | Region 1's card, shown at once by `DeckStack.show_card()` (`main.gd` `start_game`) |
| `finish` with a Region change (Regions 1→2, 2→3, 3→4) | `Game._gather` | The next Region's side, after `turn_card` |
| `finish` into `final_journey` | `Game._gather` | The Dragon Card, after `turn_card {to: "dragon"}` |

Regroup is not one of them. `Game.regroup` shuffles the *Hand* and puts it at the back of the Deck (rulebook p. 28), so it keeps its current `gather_shuffle {keep_discard}` step and gold ghost.

**Rationale**: This matches the engine's `_shuffle(deck)` calls exactly, except `_shuffle(hand)` in `regroup`. SC-001 then holds: one shuffle after setup and one after each of Regions 1 to 4.

**Alternatives considered**: (a) Showing the shuffle wherever `gather_shuffle` plays would include Regroup, which the spec excludes. (b) Folding the motion into `gather_shuffle` itself: the cards arriving and the shuffle would overlap, which breaks FR-009, and `gather_shuffle` would mean two things.

## R2. A new step, `shuffle`, after the gather

**Decision**: Add a Sequencer step kind `shuffle`, `{cards: [], values: {count: <Deck size>}, anchor: "deck"}`. It goes after the step that fills the Deck and before `stage_banner`:

- `setup`: `gather_shuffle {undraw}` → `turn_card` → **`shuffle`** → `stage_banner` → `draw` …
- `start`: **`shuffle`** → `stage_banner` → `draw` …
- `finish` (Region change / Final Battle): … `turn_card` → `gather_shuffle {from: discard}` → **`shuffle`** → `stage_banner` → `draw` …

It is left out when the Deck it would shuffle is empty (the spec's "no Deck at all" case). `Sequencer.apply` leaves the state as it is on `shuffle`: the gather's `values.deck` already carries the engine's shuffled order (FR-013).

**Rationale**: The Sequencer is pure, and its tests replay steps to the after state. A no-op step keeps that true. A separate step kind gives the animator, `board_response`, the reduced-motion table and the ordering tests one thing to name.

**Alternatives considered**: Renaming `gather_shuffle` to `gather` would be clearer, but it would touch every test and tool that names it for no gain to the player. It is left as is.

## R3. Setup's order changes: the card goes on before the shuffle

**Decision**: In `setup`, `turn_card` already comes after `gather_shuffle {undraw}`. The `shuffle` step is inserted after `turn_card`. The setup cards still fly back under the note preparing the Deck, the note is thrown off as the Region 1 card is laid on, and then the shuffle plays under that card. This gives the order FR-007 asks for, "card on top, then shuffle", without moving the gather.

**Rationale**: In today's code, the "shuffle" in `gather_shuffle {undraw}` is only the refill. Inserting the new step after `turn_card` gets the order right with the smallest change, and the `test_sequencer` assertion `turn > gather_shuffle` still holds.

**Alternatives considered**: Moving `turn_card` before the undraw would send the setup cards in under the Region Card rather than under the note, and would undo the specs/015 deal and discard of the note preparing the Deck.

## R4. What the shuffle looks like: NextQuest's riffle, under the card on top

*Revised 2026-10-20. The first build split the stack's plain card-stock edges up to 35% of the card's height out from under the card. The user rejected it because it pulled the cards too far out and showed a blank, stone-coloured side. The user asked for the riffle of the sibling project NextQuest instead (`NextQuest/app/src/components/shuffle/ShuffleCard.tsx`).*

**NextQuest's riffle**: from a small, slightly uneven pile, the cards peel one after another (300 ms apart):

- Each card arcs out to the side and back in one ease-in-out cubic arc of 400 ms.
- At the height of the arc it is tilted 5° and scaled to 0.96.
- At that point its z drops to the bottom, so it slides back *under* the pile.
- Every card is a whole card, never a blank.

**Decision**: The same peel, adapted to the Deck.

- **Which cards.** Up to `T.SHUFFLE_PEELS` (5) Mage Cards peel out from under the card on top. They are drawn as real `CardFace`s, face up as the Deck is held (the user chose real faces over a shared back), at the top card's size and lined up with it, as the Key Card is. They are taken from the Deck in an order of their own (sorted ids, rotated by Region), never the new order (FR-003).
- **Layering.** They lie on a new `_riffle` layer under `_tops`, so the card on top covers all but the strip that sticks out.
- **Direction and distance.** They peel *up*, into the room a Key Card rises into, because the Deck has almost no room beside the card: 0–36 px at the `MATRIX` shapes. Where the card lies raised at the start, or for the Dragon Card, they peel to whichever of above or below has more room. The distance is `T.SHUFFLE_PEEL` (60%) of a Key Card's rise, capped by that room (`peel_lift`), so a peel never comes out as far as a Key Card does.
- **The arc.** Each card's arc takes `T.SHUFFLE_ARC` (45%) of the step, with the starts spread evenly so the next starts before the last is home (`peel_at`). Ease-in-out cubic, out and back.
- **Tilt and size.** At the height of the arc each card is tilted `T.SHUFFLE_TILT`, 2°, alternating sides like the two halves of a riffle, and scaled to `T.SHUFFLE_SCALE`, 0.96. It pivots on the edge that stays under the card on top. The tilt is 2° rather than NextQuest's 5° because these cards are about three times larger, and 5° would swing their far edge off the Deck.
- **Back under the pile.** At the height of its arc, each card moves to the bottom of `_riffle`, so it slides back in under the cards still to come.
- **The edge stack does not move**, so the Deck's depth is right throughout (FR-006).

**Alternatives considered**:

- The first build's split of the plain edges: rejected by the user, as above.
- A shared card back: offered, and not chosen.
- Peeling sideways as NextQuest does: there is no room beside the card.

## R5. Timing: its own time, outside the sequence limit

**Decision**: Add `T.SHUFFLE := 0.9` and set `DURATION["shuffle"] = T.SHUFFLE`. Add `"shuffle"` to `Sequencer.OWN_TIME`, so `_fit_time` never squeezes it, and to `Animator.reduced_duration`'s keep-its-time list.

**Rationale**:
- `T.SEQUENCE_MAX` is 3.0 s, and an End of a Region sequence already reaches it. Inside the limit, the shuffle would steal time from the draw and the turn and would itself be squeezed.
- Kept outside, the sequence grows by exactly 0.9 s. That is within SC-002 (≤ 1.5 s per shuffle, ≤ 1 s added).
- `press()` and `skip()` already end everything before the Key Card at once (`_to_wait`, `_finish` → `DeckStack.finish()`), so a player in a hurry is never held by the shuffle (US4).

**Alternatives considered**: 1.2 s reads better, but it would break the "≤ 1 s longer" criterion. 0.6 s is too short for the interleave to read on a phone.

## R6. Reduced motion: a still word, no movement

**Decision**: Under `UI.reduced_motion`, `DeckStack.shuffle(d)` moves no edge. Instead, a "Deck shuffled" label (body text ≥ 22, `T.INK` on the card-stock chip used for Deck captions) appears centred on the top card's lower third. It fades in, holds and fades out within the step's 0.9 s, and fades are already the reduced-motion idiom (`reduced_duration`). With motion on, no label is shown: the riffle says it.

**Rationale**: FR-010 needs the moment marked without motion. The stage banner straight after is a screen overlay that already keeps its time in reduced motion. A short word on the Deck itself ties the mark to the Deck.

**Alternatives considered**:
- A line added to the stage banner for everyone: it would change the banner's tested two-line layout (`stage_banner.gd`) for a reduced-motion need.
- Dimming the edges: too subtle to count as being "told".

## R7. Once only: undo, leaving and skipping

**Decision**: No new guard is needed.

- **Undo**: steps are built only from engine actions (`main.gd` `dispatch`). An undo within an Encounter builds no `setup`, `start` or Region-change `finish` steps.
- **Leaving**: `start` steps are built only in `start_game` (a new game). Coming back to a game in progress renders state and builds no steps.
- **Skipping**: `DeckStack.finish()` resets `_shuffle_t = -1` and redraws the edges in place, so skipping always lands squared.
- **Resizing**: `_place()` resets `_stack_rect`, and `_draw_edges()` recomputes the offsets from the new rect each frame.

**Rationale**: FR-011 and the spec's resize and leave edge cases come from the existing architecture, so `test_sequencer` only has to confirm that the step appears in the right actions and in no others.

## R8. What else names every step kind

**Decision**: These places name every step kind and are updated to include `shuffle`:

- **`board_response.gd` `QUIET_STEPS`**: `shuffle` gets no board flash.
- **`test_board_responses.gd` `STEPS`**: `shuffle` is added to the list.
- **`DeckStack`**: emits `reveal_beat("shuffle")` as the step starts, so `tools/ui_check.gd` can check its order against `"key_lit"`.
- **`tools/design_shots.gd`**: gains a `shuffle` mode (`-- <out dir> shuffle`, beside `deck` and `notes`), shooting t = 0.5 (mid riffle) under the Region 2 card and under the Dragon Card, for review.

`tools/ui_check.gd` has uncommitted edits in the working tree. The new beat check is appended next to the existing reveal-beat check, and nothing else in the file is touched.
