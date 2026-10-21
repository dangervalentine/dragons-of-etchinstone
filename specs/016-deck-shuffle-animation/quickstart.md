# Quickstart: Validating the Deck Shuffle

## Prerequisites

- Godot 4.7 via the project's `godot` shim.
- The repo root as the working directory.

## Automated

```sh
tools/test.sh
```

This should pass, with the new checks included:

- **`tests/test_sequencer.gd`**: across the seeded full-game runs, `shuffle` appears in exactly the actions in [contracts/deck-shuffle.md](contracts/deck-shuffle.md), with the orders it gives (after `turn_card` / the gather, before `stage_banner`). It appears exactly 5 times in a game that reaches the Final Battle (SC-001). The steps still replay to every after snapshot.
- **`tests/test_deck_stack.gd`**: `peel_at` is 0 at t = 0 and t = 1, reaches 1 once per card, and the cards peak in order with overlap. `peel_lift` keeps the peeled card on the Deck, short of a Key Card's rise but at least `T.DECK_EDGE`, at each `MATRIX` shape, for the Region Card at rest and raised and for the Dragon Card. `shuffle()` followed by `finish()` hides every peel and leaves the top card unmoved. Under reduced motion, nothing peels and the label shows.
- **`tests/test_board_responses.gd`**: `shuffle` is in `STEPS` and is quiet on purpose.
- **`tools/ui_check.gd`**: at every MATRIX shape, `reveal_beat("shuffle")` comes before `"key_lit"` on a Region change, and nothing on the Deck overlaps the Hand, the header or the action row mid-shuffle.

## Visual

```sh
godot --path . -s tools/design_shots.gd -- <out dir> shuffle
```

Check the shots under the Region 1 card (lying raised, so the cards peel downward), the Region 2 card and the Dragon Card, each taken early, midway and late in the riffle:

- The top card is whole and on top.
- Real Mage Cards peel out from under it, a little tilted, each less far than a Key Card rises.
- Nothing blank shows.

## By hand (use the `install-on-emulators` skill, or run on desktop)

1. **New game, Normal**: finish setup. The setup cards fly back, the note is thrown off, the Region 1 card is laid down, and the stack riffles under it. The banner and the first Hand follow.
2. **End of Region 1**: the Hand and Deck go to the Discard, and the card turns to Region 2. The Discard flies back in, then the riffle plays, and only then the banner. From the card turning to the first draw is about 1 s longer than before.
3. **End of Region 4**: the same, under the Dragon Card, then the Final Journey's seven cards.
4. **Regroup, Divert and an ordinary Cleanup**: no riffle.
5. **Settings → Reduced motion on**, then repeat step 2. Nothing slides, and "Deck shuffled" shows briefly on the Region 2 card.
6. **Tap during the riffle**: it jumps straight to the Key Card waiting, with the stack squared.
