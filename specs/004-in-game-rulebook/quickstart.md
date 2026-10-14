# Quickstart: Validating the In-Game Rulebook

## Prerequisites

- Godot 4.7.2 on `PATH` as `godot` (see the project README)
- Optional: `reference/rulebook.txt` (gitignored) for the not-verbatim check. Without it that check is skipped.

## Automated checks

```sh
./tools/test.sh
```

It must end with `0 failed` for both the unit suite and the UI check. The rulebook adds:

| Where | Proves |
|---|---|
| `tests/test_rulebook.gd` | Section structure and order; coverage of every Hardship, Ability, Peril, difficulty and alternate rule; every term, icon and engine number resolves; no physical-handling or out-of-scope wording; word budgets; not verbatim (research R11) |
| `tests/test_glossary.gd` (existing) | The new `book` icon is listed as a control, not a symbol |
| `tools/ui_check.gd` | At every matrix size: every rulebook page and the contents fit, with no scrolling, text ≥ 22 and tap targets ≥ 88 (chips ≥ 44), all inside the safe area; a terms popover over the rulebook passes too; opening and closing mid-game leaves the draft and view state unchanged |

## Screenshots for review by eye

```sh
godot --path . -s tools/shot.gd -- build/screenshots/rulebook phone-16x9 phone-tall desktop-ultrawide
```

Check the rulebook shots: the first page, the contents, a figure page and a table page. Text should be readable, columns balanced, nothing clipped, and the figures should match the cards in play.

## Manual walkthrough

Run `godot --path .`, then:

1. **Learn from the title screen (US1)**: press How to Play. It opens on page 1 of 18. Press Next through to the last page, where Next reads "End of rulebook" and is disabled. Press Close, and the dragon screen is unchanged, with the same dragon still selected.
2. **Look up mid-game (US2)**: start a game and place two cards into Roles. Open Menu → How to Play → Contents → Penalty Phase, press Next once, then Escape. The two cards are still placed and the Encounter is the same. Reopen How to Play, and it is on the page you left.
3. **Session only**: quit and relaunch, then open How to Play. It starts at page 1.
4. **Keyboard**: on the title screen press `H`. Use Right and Left to page, `C` for the contents, Tab and Enter to choose a section, and Escape to close.
5. **Terms (US4)**: on any page press a chip under "Terms on this page". The Glossary entry opens beside it. Press Escape and you are back on the same page.
6. **Figures (US4)**: Mage Cards, Regions and Encounters, The Dragons and Making a Journey each show a labelled example that looks like the cards in play.
7. **Reduced motion**: Settings → Motion → Reduced. Page changes only fade.
8. **Phone**: `scripts/install.sh android` (or `ios`). Repeat steps 1, 2 and 5 by touch, and check the Android back gesture closes the rulebook.

## Content review (SC-001, SC-005)

These can't be fully automated:

- **Against the engine**: read each section beside `engine/rules.gd` and `engine/game.gd` and confirm every rule is stated the way the engine resolves it. Any difference is a defect to fix in one or the other, never something to word around.
- **Against the printed rulebook**: confirm nothing the game implements is missing (FR-011).
- **New-player test**: someone who has never played reads the rulebook, then plays their first Encounter without help (SC-001).
