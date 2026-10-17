# Quickstart: checking the ordered Hand

## Automated

```sh
./tools/test.sh
```

Expected: all tests pass, including:

- `tests/test_turn_draft.gd`:
  - pick and put;
  - a swap between two places, and between a place and the floating row;
  - the derived Reserve;
  - refusals (a tucked card; the Reserve with under four cards; the Reserve in the Final Enemy);
  - `to_action()` is identical to today's for the same Roles.
- `tests/test_role_slots.gd` (places): the order for the Region, Final Journey and Final Enemy; the Reserve's states including `given_up`; numbers matching today's cases.
- `tests/test_layout_solver.gd`:
  - the strip is at most half of the old band;
  - the action row is ¼ · ¼ · ½ within 2%;
  - every stage of building fits, with no overlap, for Hands of 1–4 in a Region and 7, 8 and 9 in the Final Battle, at every `MATRIX` window;
  - the Final Battle uses `FINAL_LEFT_W`.
- `tests/test_card_face_layout.gd`: the new Region (≈148 × 207) and Final (≈117 × 164, ≈101 × 141) card sizes keep every region inside and apart.
- `tests/test_rules.gd`, `tests/test_playthrough.gd`: unchanged and passing (FR-026, SC-006).
- `tools/ui_check.gd`: seeded games played through `pick` / `put` intents at every window shape, with no overlap and no space failures.

## Screens to look at

```sh
godot --path . -s tools/design_shots.gd -- build/shots-009
godot --path . -s tools/space_audit.gd
```

Check the Final Journey and Final Enemy shots at `FINAL_LEFT_W`. The dragon's stats, the tier ladders and the math box must not clip (research R6). If they clip, raise `FINAL_LEFT_W` by 20 and re-run.

## By hand

| # | Do | Expect |
|---|----|--------|
| 1 | Start a game, reach the first Encounter | Right side, top to bottom: strip (Reserve, Element, Spell, Boost), four empty outlines, four floating cards, then Fuse · Divert · Play (¼ ¼ ½). The preview shows no outcome |
| 2 | Tap a card, then the Spell outline | The card rises, the places glow while it is held, then it glides into the third place. The strip shows the Spell number, and the preview starts filling |
| 3 | Fill Element and Boost the same way | The last floating card moves into the Reserve on its own. The Hand reads Reserve · Element · Spell · Boost |
| 4 | Drag the Boost card onto the Element place | The two swap, and the numbers and preview update |
| 5 | Tap the Spell card, then the floating row | It returns to floating, and the Spell outline is empty |
| 6 | Keyboard: `2`, `Tab`, `Tab`, `Space` | The second card is picked, the highlight moves, and the card goes in the highlighted place |
| 7 | Against a Ranged enemy, tap the Reserve's toggle (or press `R`) | The Reserve shows as given up. The action row has no Give up Reserve button |
| 8 | Divert twice, then build with 2 cards | The Reserve outline is inactive, and Play enables once a Spell is placed |
| 9 | Fuse two cards | The tucked card sits behind its partner in that place. Dragging the top card brings both |
| 10 | Turn on reduced motion and repeat 2–4 | Cards and numbers snap with no glide |
| 11 | Reach the Final Journey | The left side is narrower. 7 places in one row with a divider between sets; all 7 cards visible; Fuse · Regroup · Play |
| 12 | Reach the Final Enemy with 9 cards | No Reserve place. All 9 cards visible at every stage, with no scrolling |
| 13 | Play a set, then look at the Upgrade step | The recap shows the same order and the Reserve's fate. Undo Upgrade sits in the first quarter |
