# Quickstart: Notes Dealt On and Discarded Off Like Cards

## Automated checks

```sh
tools/test.sh
```

- `tests/run.gd` runs `test_deck_stack` (`NotePile.plan`, `tilt`) and `test_note_pile` (deal, throw, refusal, `finish`, `panel`).
- `tools/ui_check.gd` then checks the settled pile at every `MATRIX` shape, the Boost refusal card, and a lost fight's pile going 1 → 2 → 3 → 0.

All checks pass, with no `FAIL` lines.

## Shots

```sh
godot --path . -s tools/design_shots.gd -- build/screenshots/015 deck
```

The Deck's shots now include a `notes` shot. It shows the result, the Soak and the XP piled on the Deck: the XP card square on top, the corners of the two under it showing a sliver at their tilts, and a soft shadow under each.

## Play-through (by eye)

Run `godot --path .` and start a game.

1. **Setup**: the "Prepare your Deck" card is thrown off to the left, turning as it goes, as the Region Card is shown.
2. **A refused move**: against an Enemy, press Play without aiming the Boost. A card with the reason comes in from the left and lands square. About 2.4 s later it is thrown off to the left, alone.
3. **A lost fight**: play a set that loses to an Enemy.
   - The result card is dealt in from the left.
   - The Soak card is dealt in on top of it. The result card's corners show beneath, tilted.
   - Once the Soak is done, the XP card is dealt in on top.
   - Spend the XP and go on: all three cards are thrown off to the left together as the view zooms out.
4. **A step**: start a Divert, then cancel it. Its card is dealt in, then thrown.
5. **Hold**: press and hold the pile. It lifts aside as one, and lies back down on release.
6. **Undo**: undo from the XP back to the Soak. Only the XP card is thrown.
7. **Reduced motion**: turn it on in Settings and repeat 2 and 3. Every card fades in and out where it lies, with nothing travelling or turning.
8. **Resize mid-flight**: resize the window while a card is flying. It lands at once, and the pile is laid out for the new size.

Throughout: no card is ever see-through in flight (outside reduced motion), and none is cut off at the Deck's edge.
