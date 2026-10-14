# Quickstart: Validating the UI Polish

How to prove the feature works. Contracts are in [contracts/](contracts/); the
entities referred to are in [data-model.md](data-model.md).

## Prerequisites

- Godot 4.7.2 on `PATH` (`godot --version`)
- For device checks: a running Android emulator and/or iOS simulator, as described
  in the README

## 1. Automated checks

```sh
./tools/test.sh
```

Expected: the existing engine tests pass unmodified (102 today), followed by the new
UI model tests (view state, turn draft, sequencer, layout solver, glossary) and the
UI check. The last line reports zero failures and the script exits 0.

What the UI check asserts, at each size in the matrix below, through a seeded game
with animation skipped:

- every Play screen region is inside the viewport and the safe area;
- nothing scrolls, in any step, including the Final Battle with seven cards;
- no control is smaller than 88 units on its shorter side, and no help target
  (a figure or effect that explains itself when pressed) smaller than 44;
- no text is set below 22 units, apart from separators and captions marked as
  such in the code;
- the game ends in the same state as the engine-only playthrough with the same
  seed and the same choices (SC-012).

| Name | Window (px) | Safe-area insets (px) | Expected |
|---|---|---|---|
| phone-16x9 | 1280 x 720 | none | design size 1280 x 720 |
| phone-tall | 2532 x 1170 | 141 left and right, 63 bottom | fits inside the safe area |
| phone-tall-flipped | 2532 x 1170 | the same, turned the other way | fits inside the safe area |
| phone-small | 1334 x 750 | none | not undersized |
| tablet | 2048 x 1536 | 40 bottom | design size 1280 x 960 |
| desktop | 1440 x 900 | none | design size 1280 x 800 |
| desktop-ultrawide | 3840 x 1080 | none | content capped at 1760 wide and centred |
| upright-browser | 720 x 1280 | none | undersized: notice shown, still playable |

The matrix lives in `ui/model/layout_solver.gd` (`MATRIX`); the tests, the UI check
and the screenshot tool all read it from there.

## 2. Screenshot matrix

```sh
godot --path . -s tools/shot.gd -- build/screenshots/matrix              # every size
godot --path . -s tools/shot.gd -- build/screenshots/matrix phone-16x9   # one size
```

Expected: one folder per size above, each holding the same named steps (title,
setup, challenge empty, challenge assigned, soak, upgrade, stage banner, final
journey, final enemy, won, lost). Review by eye for:

- no screen more than one third empty (SC-008);
- nothing clipped, overlapping or truncated, including the longest card and Region
  names and the longest effect descriptions;
- one gold primary action per screen.

## 3. Play it

```sh
godot --path .                 # desktop window
scripts/install.sh             # Android emulator, iOS simulator and local web
```

Walk through these on a phone target held in landscape, which is how the mobile
apps open, and in a desktop browser.

**Read the turn (User Story 1)**
1. Start a Normal game. At the first Encounter, without touching anything, say what
   the Encounter is and what it rewards and costs. Nothing should need scrolling.
2. Place three cards. The preview shows the comparison, a verdict, and the rewards
   and costs. Swap a card: the changed figures pulse.
3. Build a set that loses. The costs are plain; if it would end the game, the
   warning dominates the screen.

**Cards (User Story 2)**
4. Hold a card (right-click on desktop). The inspect view shows this Level, the
   next and its cost, and the Downgraded Level.
5. Compare three Hand cards with the scans in `reference/sheets-official/`: each
   value sits where the print has it (SC-010).
6. Fuse two cards of one Ether. They read as one piece with the chosen Ether shown.

**Motion (User Story 3)**
7. Play the set. Cards travel, totals count, the verdict lands, consequences arrive
   one by one, the next Hand is dealt. Under 3 seconds.
8. Play again and tap during the sequence. It completes at once; the tap does
   nothing else; the next decision is ready.
9. Tap rapidly through a whole Encounter. Nothing is skipped past or applied twice.
10. Turn on reduced motion in Settings. Repeat step 7: same information, no travel
    or shake.

**Every screen (User Story 4)**
11. In a desktop browser, resize the window mid-turn. The regions resize in place
    and your placed cards stay placed. Make it taller than it is wide: the notice
    appears and the game is still playable. On a phone, hold it upright: the app
    stays in landscape. Turn it to the other landscape direction: it follows, and
    your placed cards stay placed.
12. Play a turn with the keyboard only: number keys, Tab, Enter, Escape.
13. On the iOS simulator, in both landscape directions, confirm nothing sits under
    the notch or home indicator, and that a whole turn can be played with the right
    thumb without shifting grip.

**Occasion (User Story 5)**
14. On the Title screen, select each dragon and each difficulty. Each explains what
    it changes.
15. Finish a Region. The next Region is announced by name.
16. Reach the Final Battle (Casual difficulty is quickest). The dragon is
    introduced and both stages show their tier ladder.
17. Win and lose once each. A win breaks the score down; a loss says where and why.
    "Play again" starts a new game with the same options in one press.

**Help (User Story 6)**
18. Tap every icon on an Encounter with a Hardship and an Ability. Each explains
    itself and dismisses without changing anything.
19. Start a Fuse and cancel at each of its three steps. The draft is as it was.
20. Take damage. The Soak meter fills as cards are chosen and the confirm control
    enables exactly when the damage is covered.

**Colour (SC-011)**
21. Turn the display to greyscale (macOS: Accessibility, Display, Colour Filters)
    and play one Encounter. Every Ether, verdict and cost is still identifiable.

## 4. Observer checks

These success criteria need a person other than the developer.

| Criterion | Check |
|---|---|
| SC-002 | Show a complete Action Set for 3 seconds, hide it, ask for the outcome and its cost |
| SC-003 | Show ten resolution sequences without the preview; ask what happened each time; at least nine right |
| SC-004, SC-005 | Hand the game to someone who has not played; time them finding every symbol's meaning; watch setup and three Encounters without helping |
| SC-009 | Count missed taps over one full game played two-thumbed in landscape |

## Done when

- Section 1 exits 0.
- Sections 2 and 3 show no defects on phone, tablet and desktop targets.
- The engine directory and the existing tests are unchanged
  (`git diff --stat main -- engine tests/test_*.gd` lists only new test files).
