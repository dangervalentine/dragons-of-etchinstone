# Quickstart: Checking the Draw, the Key Card and the Pile

## Run the checks

```sh
tools/test.sh                       # headless suites, then ui_check across every MATRIX shape
godot --headless --path . -s tools/space_audit.gd
```

Expected:
- All suites pass.
- `ui_check` reports, at every shape:
  - drawn cards start at the top card's rect and land at their Hand place (within 2 px), keeping the card's ratio;
  - the raised Key Card's sides line up with the Region Card's (within 2 px);
  - each reveal beats in the order `key_lit` → `panel_lit` → `zoom`, on the zoomed panel;
  - whole-card numerals still ≥ 22 (R2's risk).

## Look at it

```sh
godot --path . -s tools/design_shots.gd -- build/screenshots/014 deck
```

| Shot | Look for (contract) |
|---|---|
| `draw` (mid-flight) | A face-up card between the Region Card's size and the Hand's, on its way right ([deck-motion.md](contracts/deck-motion.md)) |
| `reveal` | The Key Card, as wide as the Region Card, raised; its number ringed and washed in gold; the matching panel rimmed in gold, the rest dimmed |
| `pile` (full and 3 cards) | Rounded, card-stock edges, slightly uneven, with a soft shadow, and no Ether colour. The Region Card's own corners are rounded to match ([deck-pile.md](contracts/deck-pile.md)) |
| `draw` in the Final Battle | Cards leave at the Dragon Card's size |

## Play it

Use the `install-on-emulators` skill (phone-tall shows the largest shrink), or run the desktop build:

1. Start a game. The first Hand's cards leave the Region Card one by one, as big as it, and shrink into the Hand.
2. The Key Card rises at the Region Card's width. Its number lights, then its panel lights while it is still up, then it slides down as the view zooms in.
3. Divert. The new Key Card runs the same reveal.
4. Tap during a reveal. It settles at once on the landed face, with no gold left behind.
5. Turn on reduced motion. Nothing travels or scales, but both highlights still show, in order.
6. Play to the Final Battle. Draws leave the Dragon Card's size, and there is no Key Card.
7. Watch the pile thin with every draw and Divert, and thicken at each reshuffle.
