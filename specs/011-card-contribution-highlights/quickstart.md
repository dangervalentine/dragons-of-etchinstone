# Quickstart: Card Contribution Highlights

## Prerequisites

Godot 4.7.2 on `PATH` as `godot` (see README).

## Automated checks

```sh
./tools/test.sh            # headless suites, then the UI check at every MATRIX shape
```

Expected: all suites pass, including the emphasis table tests against [contracts/card-marks.md](contracts/card-marks.md), and `ui_check` reports no failures. That covers the aim zone (≥ 88 tall, ≤ 50% of the card), marks clear of figures, and space measured in the summary state.

```sh
godot --path . -s tools/design_shots.gd -- build/screenshots/011
```

Expected: shots of each effect's marks, the unset/Attack/Initiative aim marks, the tip state and the post-Play summary.

## Manual checks

Run `godot --path .`. For phones, use the install-on-emulators skill.

1. **The box is free** (US1): start a game and reach a Region Enemy. The box shows only a tip. Arrange a losing Hand: Play looks the same, and there is no red edge. Press Play: the rows and verdict appear in the box and count up. Then the Upgrade recap shows.
2. **What counts** (US2): swap a matching and a non-matching Element under the Spell. The lift moves between the enhanced and basic plates. On a Journey the Element's Initiative is not lifted. With the Spell enhanced on the MP's Ether, the Reserve's Boost lifts.
3. **Aim on the card** (US3): against an Enemy, Play is disabled and the Boost shows `?`. Tap the bottom of the Boost card: Attack. Tap again: Initiative. Tap the top of the card, or drag it: it swaps, and the aim is unchanged. Press `B`: the aim cycles. In the Final Enemy, each Boost aims on its own.
4. **Marks** (US4): in a Night Travel Encounter, icons appear beside the Boost and the Element's Initiative. With a Ranged Enemy, the Reserve is marked until Give up Reserve. Check a Steep Journey, a Freeze Enemy, and an Armored Enemy with an enhanced attack.
5. **XP stars** (US5): with 8 XP, level a card costing 3. 3 stars fly to it and the number reads 5. Undo: it reads 8, and no stars fly. Finish with XP left: it fades. Repeat with reduced motion on.
