# Quickstart: The Deck and Region Card on the Playfield

## Prerequisites

Godot 4.7.2 on `PATH` as `godot` (see README).

## Automated checks

```sh
./tools/test.sh            # headless suites, then the UI check at every MATRIX shape
```

Expected: all suites pass.

- `test_sequencer` checks the reveal steps in [contracts/reveal-sequence.md](contracts/reveal-sequence.md).
- `test_region_card` checks the 8 tiles, the card codes and the sides.
- `test_deck_stack` checks edges, tile aspect, zoom scale and the peek height at every shape.
- `test_layout_solver` checks the raised minimums.
- `ui_check` reports no failures. That covers the stack depth matching the Deck count after every settle, the face's values matching the Encounter, the peek and top card staying inside the deck region, and tile text ≥ 22 ([contracts/deck-stack.md](contracts/deck-stack.md)).

```sh
godot --path . -s tools/design_shots.gd -- build/screenshots/012
```

Expected: shots of the zoomed-out Region Card for Regions 1–4, the peek held with and without a Hardship, a half-turn and a card swap mid-way, the Dragon Card, and the settled faces. Each at 1280 × 720 and one phone shape.

## Manual checks

Run `godot --path .`. For phones, use the install-on-emulators skill.

1. **The Deck** (US1):
   - Start a game. During the starting-card step, the left side is a stack with the setup face on it.
   - On Begin, the Region 1 Region Card lands on top.
   - Through Region 1 the edges thin as the header's Deck count falls: 8 edges at 16 cards, 1 at 1–2.
2. **The reveal** (US2):
   - The Hand is dealt from under the Region Card.
   - When the cards settle, a Mage Card rises from beneath it, showing only its title and the bronze strip (e.g. Enemy 2, plus Storm if it has it), then slides back.
   - The view zooms into Enemy 2's tile until it is the full face, and the creature starts to move.
   - Press the face: the Key Card opens as before.
3. **Skip**: press anywhere during the reveal. The face appears at once, zoomed in, with correct values.
4. **Divert** (US3): Divert twice. Each time the view zooms out, the old Key Card leaves the back of the stack, the next one rises and slides back, and the view zooms into its slot.
5. **Cleanup** (US3): finish an Encounter. The view zooms out, the Action Set leaves for the back of the stack, the new cards come from under the Region Card, and the reveal plays.
6. **Region change** (US4): at the end of Region 1 the Region Card half-turns to Region 2. At the end of Region 2 it slides away and the other card comes up as Region 3.
7. **Final Battle** (US4):
   - At the end of Region 4 the Dragon Card comes up on top and the seven cards are dealt.
   - The view zooms into its MP Tiers, which become the Final Journey face, with no Key Card rising.
   - After Play, the view zooms out, the remaining cards are dealt, and it zooms into the HP Tiers.
   - Regroup zooms out and back into the MP Tiers.
8. **Reduced motion** (FR-011): turn reduced motion on and repeat 2, 4 and 6. Each shows the strip briefly by a fade and then the face, with no rising, sliding, turning or zooming, and creatures stay still.
9. **Undo** (FR-012): in Upgrade, upgrade then undo. Nothing on the Deck moves.
10. **Timing** (SC-003): from the Hand settling to the face settling takes about 1.4 s and never more than 2 s.
