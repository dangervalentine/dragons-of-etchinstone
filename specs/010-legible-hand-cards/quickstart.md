# Quickstart: Validating Legible Hand Cards

## Automated

```sh
tools/test.sh
```

This runs the headless suites, then `tools/ui_check.gd`. Expect every test to pass, including:

- `test_turn_draft`: `deal`, `settle`, `swap` and `boost_target_set` (research R1–R3).
- `test_layout_solver`: card sizes against the research R6 table; the action-row splits for 3, 4 and 5 cells (R5).
- `test_view_state`: the `places` fields, `math.sums[].aim`, `secondary` and `action_cells`.
- `test_card_face_layout`: the longest name is ≥ 17 at a 308-tall card.
- `ui_check`: every `MATRIX` shape, building driven through swaps and Boost aiming, and no tap target under 88.

## Screenshots

```sh
godot --path . -s tools/design_shots.gd
```

Check the phone-tall Region shots against [contracts/board-layout.md](contracts/board-layout.md):

1. One row of four cards with labels Reserve, Element, Spell and Boost, and no strip above them.
2. Every card name readable at phone size (SC-003). Compare with the original screenshot (cards 138 × 194).
3. The action row reads Fuse ¼ · Divert ¼ · Play ½, or with a Ranged Enemy, four quarters with Play rightmost.
4. Against an Enemy, Attack and Initiative rows at least 88 tall, with an unaimed Boost inviting a tap.

Then check the Final Journey and Final Enemy shots: two rows with the break at the set divider, every card visible.

## By hand (desktop or phone build)

1. Start a game, finish setup, and reach the first Encounter. The Hand shows in draw order, every card labelled, and the preview shows an outcome. Against an Enemy, the preview asks where the Boost goes.
2. Tap the Initiative row. The Boost moves there and Play enables (if the set is legal). Tap the Attack row: it moves back.
3. Tap the Element card, then the Boost card. They swap, and the preview updates. Drag the Spell onto the Reserve: they swap.
4. Divert: the Hand drops to 3 cards. No card sits in the Reserve, and all three roles are filled.
5. Fuse two cards of the same Ether in a 4-card Hand. The Reserve empties into the role the tucked card left. Unfuse: the card returns to the first empty position.
6. Against a Ranged Enemy: Give up Reserve appears as a fourth quarter, and Play narrows to a quarter at the right end. Toggle it: the Reserve label shows "given up".
7. Final Enemy: tap a row to aim Boost 1, tap again to aim Boost 2. Pick up the Boost 1 card and tap the other row to re-aim it. With both aimed and nothing held, a row tap says to pick up a Boost card.
8. Turn on reduced motion and swap: the cards snap.
