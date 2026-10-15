# Quickstart: Verifying Etched Stone and Ether Rifts

How to check each stage against the spec. Commands run from the repository root.

## 0. Baseline (before any change)

```sh
godot --path . -s tools/shot.gd -- build/006-before                # every matrix size
godot --path . -s tools/design_shots.gd -- build/006-before/design
```

Record the role-band area and per-zone empty fractions once `tools/space_audit.gd`
exists. Run it against the commit before stage 1 (`git stash` or a worktree at
`ad808a6`), and write the numbers to `specs/006-etched-stone-polish/baseline.md`.

## 1. Every stage: automated gates (SC-007)

```sh
tools/test.sh
```

- **Expected**: all tests pass, and `ui check` reports 0 failures at every matrix
  size.
- **New tests**: `test_role_rail`, `test_stone_contrast` and `test_board_responses`,
  plus the extended `test_layout_solver`.

## 2. Stage 1: space (US1; SC-001, SC-002)

```sh
godot --path . -s tools/space_audit.gd
```

**Expected**
- At `phone-16x9` with one set, the role-rail area is ≤ 50% of the baseline band
  (824 × 153).
- With two sets (Final Battle), the rail area is below the baseline (824 × 96).
- No zone is more than about 1/3 empty in any standard state.

**By hand** (`install-on-emulators` skill, or the desktop build):
1. Start an Encounter. With no card placed, the rail shows three role tokens and the
   next one is ringed.
2. Place a card. Its token shows its contribution, with no name, and the card itself
   lifts in the Hand with its ribbon.
3. Tap the filled token, and separately the lifted card. Each takes the card back.
4. Tap an empty token. The next card goes to that role.
5. Place a Boost card against an Enemy. The toggle shows Attack or Initiative, and
   tapping it switches.
6. Play the set. The rail shows the recap: played roles struck, and the Reserve gold
   if it is kept. Each played card in the Hand wears its "played as" ribbon, and
   tapping a recap token opens that card's inspect view.
6b. Place cards one by one. The Encounter frame does not resize between placements
   (preview sized per Encounter, research D2).
7. Reach the Final Battle. Six tokens with set pips plus the toggles sit in one row,
   and the two-row Hand cards are no smaller than before (the rail frees only 8
   units here, so any growth is slight).
8. Confirm that the look is otherwise unchanged from today (FR-022).

## 3. Stage 2: stone, rift and life on the play screen (US2, US3)

```sh
godot --path . -s tools/field_bench.gd           # PASS required
godot --path . -s tools/shot.gd -- build/006-after phone-16x9 desktop
```

**By hand**
1. **Ether mood (SC-004).** Take screenshots of one Encounter per Ether and cover
   the cards and the whole Encounter frame (the creature is tinted in its Ether).
   Ask someone other than the developer to name the Ether: at least 3 of 4
   correct.
2. **First look (SC-005).** Show the play screen for 5 seconds to someone new. They
   name the Encounter, the predicted result and the Play control.
3. **Idle (SC-006).** Watch the idle play screen for 10 s. Name at least two ambient
   motions (seam shimmer, motes) and the lit active zone.
4. **Responses (SC-006).** Do each action in [contracts/board-life.md](contracts/board-life.md)
   § Responses and name the board's response to each.
5. **Reduced motion (SC-009).** Set Menu → Motion → Reduced. Nothing moves
   ambiently, the active zone is lit and still, and the responses show as held tints.
6. **Stutter (SC-008).** Run the web build (served locally) and the Android
   emulator. Watch idle play, card placement and a resolution sequence: no visible
   stutter.

## 4. Stage 2 exit point: owner sign-off

Put `build/006-before/phone-16x9/05_challenge_assigned.png` beside the stage 2 shot of
the same state, and do the same for `12_final_journey.png`. Ask the owner:
*Which looks more like Dragons of Etchinstone, and more finished?*

- **After preferred**: continue to stage 3.
- **Before preferred**: revert the stage 2 commits. Stage 1 stays shipped. Record
  the outcome at the bottom of this file and stop.

## 5. Stage 3: every screen (US4; SC-003)

```sh
godot --path . -s tools/shot.gd -- build/006-after
godot --path . -s tools/design_shots.gd -- build/006-after/design
```

For every screen and overlay in
[contracts/screens-and-lore.md](contracts/screens-and-lore.md):

1. Lay the before and after side by side. The owner should prefer the after on every
   one.
2. Check that every control and value in the "Must keep" column is present.
3. Repeat the reduced-motion check from §3, step 5.

## Results

_Record observer results, bench numbers and the owner's decisions here._

- **Pre-feature bench (T004, 2026-10-15, Apple M5 Pro, Compatibility renderer)**:
  `field_bench` average 2.14 ms, p99 3.88 ms, worst 6.67 ms: PASS.
