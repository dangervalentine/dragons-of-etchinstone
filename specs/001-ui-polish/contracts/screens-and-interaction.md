# Contract: Screens, Regions and Interaction

What the player-facing interface guarantees. Tests in `tools/ui_check.gd` and the
manual checks in [quickstart.md](../quickstart.md) verify against this document.
Sizes are in design units (see [design-tokens.md](design-tokens.md)).

## Screens

| Screen | Shown when | Primary action |
|---|---|---|
| Title | No game in progress; first setup step (dragon) | Continue |
| Rules | Second setup step (difficulty, alternate rules) | Set out |
| Play | Any engine phase from setup to final_soak | Depends on the step (below) |
| Ending | Phase is won or lost | Play again |

Overlays, shown above any screen and dismissed without changing the game: card
inspect, glossary popover, stage banner, settings, leave-game confirmation.

Changing screens is a transition of 0.25 s (cross-fade in reduced motion).

## Play screen regions

Seven regions, always present, always in the same relative place. The game is
landscape only; there is one arrangement, with a minimum design size of 1280 x 720.

```text
┌─────────────────────────────────────────┐
│ header                                  │
├──────────────────┬──────────────────────┤
│ encounter        │ slots                │
│                  ├──────────────────────┤
│                  │ hand                 │
├──────────────────┤                      │
│ preview          ├──────────────────────┤
│                  │ actions    │ commit  │
└──────────────────┴──────────────────────┘
```

The left column is about one third of the width. The commit control is in the
bottom right corner, under the right thumb, with the secondary actions beside it
and the Hand directly above. On larger screens the regions grow in place.

| Region | Contents |
|---|---|
| header | Stage name (Region and its name, or Final Battle and the dragon), progress through the stage, deck / discard / trash piles with counts, menu button |
| encounter | The Encounter face: Key Card's challenge, or the dragon's tier ladder |
| preview | The decision panel for the current step (see Steps) |
| slots | One Action Set, or two in the Final Battle (side by side); the Boost target toggle sits on the Boost slot when it applies |
| hand | The Hand: one row of up to four cards, or two rows for five to seven |
| actions | Secondary actions available in this step: Fuse, Divert, Regroup, Give up Reserve, Cancel |
| commit | The single primary action |

**Guarantees**
- On any phone of 16:9 or longer, all seven regions are visible in every step,
  including the Final Battle. Nothing on the Play screen scrolls, at any size.
- Nothing interactive overlaps the device safe-area insets, with the notch on
  either side.
- The mobile apps stay in landscape however the device is held.
- In a browser window taller than it is wide, or too small to be legible, the same
  layout is drawn at the reduced scale with a dismissible notice asking the player
  to turn the device or widen the window.
- Regions do not move when the step changes. Regions that have nothing to show in a
  step keep their space.

## Steps on the Play screen

| Engine phase | Prompt | Preview region shows | Primary action |
|---|---|---|---|
| setup | Choose N cards to start at Level L | Count chosen of N | Confirm (enabled at N) |
| challenge | Build your Action Set | Outcome preview | Play |
| penalty, poison, final_soak | Soak D damage | Soak meter filling toward D | Take the damage (enabled when covered) |
| upgrade | Spend XP | XP purse, with what was just won or lost | Continue |
| final_journey, final_enemy | Build two Action Sets | Outcome preview against the tier ladder | Play |

A primary action that is disabled states why, in place, in the preview region.

## Outcome preview

- Incomplete draft: names the empty slots. No error wording.
- Complete draft: one row per comparison, each showing the player's total, the
  target and the result, with the player's side filled proportionally to the target.
  - Enemy: Attack against HP; Initiative against Initiative.
  - Journey: Move against MP.
  - Final Journey: total Move against the three Move tiers.
  - Final Enemy: total Attack against the three HP tiers; total Initiative against
    the dragon's.
- Verdict: one word or short phrase, largest text in the region, with its own
  colour and icon: Complete victory, Narrow victory, Loss.
- Rewards (XP) on one side; costs (damage with element, time penalty, poison,
  Reserve discarded) on the other, each as an icon and a number.
- A fatal outcome replaces the verdict with a defeat warning that is the most
  prominent element on the screen, and the primary action is restyled as a warning.
  It stays enabled: losing on purpose is allowed.
- Any figure that changed since the last preview pulses once.

## Card interactions

| Gesture | Touch | Mouse | Keyboard |
|---|---|---|---|
| Choose / place a card | Tap | Click | `1` to `7` by Hand position |
| Take a placed card back | Tap it (in the Hand or in its slot) | Click | Same key again |
| Choose the slot to fill next | Tap the slot | Click | `Tab` / `Shift+Tab` |
| Toggle Boost target | Tap the toggle on the Boost slot | Click | `B` |
| Inspect a card | Press and hold 0.35 s | Right-click | `I` on the focused card |
| Explain an icon or term | Tap it | Click (hover highlights) | `?` opens the full glossary |
| Primary action | Tap | Click | `Enter` |
| Cancel mode / close overlay | Tap Cancel or outside the overlay | Same | `Escape` |
| Skip an animation | Tap anywhere | Click anywhere | Any key |

**Guarantees**
- Every control that plays the game is at least 88 units on its shorter side;
  figures and effects that only explain themselves are at least 44. Every press
  gives visible feedback within 0.1 s, including when the action is refused.
- The header is 56 units tall; its menu button reaches below it to make 88.
- A press that skips an animation does nothing else.
- A refused action shows its reason beside the thing pressed and changes nothing.
- Inspect and glossary overlays never change the draft or the game.

## Multi-step actions

Each shows its instruction in the preview region, dims ineligible cards with the
reason, and puts Cancel in the actions region.

| Action | Steps |
|---|---|
| Fuse | 1. Choose the card to play. 2. Choose a card of the same Ether to tuck behind it. 3. Choose the Ether it counts as. |
| Divert | 1. Choose a Hand card to discard with the Key Card. |
| Regroup | 1. Choose one card to discard; the rest are reshuffled and redrawn. |
| Soak | Choose cards to Downgrade until the meter is full; choosing again removes a card. |
| Setup | Choose N of the offered cards; choosing again removes a card. |

Fuse is absent, not disabled, under the Cavalier rule.

## Resolution sequence

Committing an Action Set plays, in order, the steps listed in
[data-model.md](../data-model.md#step-and-steplist). The sequence:

- shows each consequence at the region it affects (XP at the purse, damage at the
  Hand, time penalty at the deck, discards at the discard pile);
- takes at most 3 s and is skippable at any moment;
- ends with the screen in exactly the state a skip would produce.

## Title screen

> Split into two setup steps by `specs/002-split-game-setup/contracts/setup-screens.md`,
> which supersedes this section: dragons on the Title screen, difficulty and
> alternate rules on the Rules screen.

- Dragon choice: four options, each with name, title, Ether colour and sigil, and
  two or three figures that distinguish it (Initiative, early damage, Armor).
- Difficulty: six options, each stating what it changes in the starting deck.
- Alternate rules: two toggles, each stating what it changes.
- The credit and non-affiliation line.
- Settings (motion) and the glossary are reachable from here.
- Remembers the last options used.

## Ending screen

- Won: the dragon's defeat, the score, and the score broken down by card Level and
  cards lost to the trash.
- Lost: where it happened (Region and Encounter, or the Final Battle stage) and why
  (which comparison fell short, or damage that could not be Soaked).
- Play again (same options, one press) and Change options (back to Title).

## Leaving a game

The header's menu button offers Resume, Settings, Glossary and Leave game. Leave
game asks for confirmation and returns to the Title screen.
