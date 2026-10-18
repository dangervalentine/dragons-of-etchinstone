# Feature Specification: UI Polish and Presentation Overhaul

**Feature Branch**: `001-ui-polish`

**Created**: 2026-10-13

**Status**: Draft

**Input**: User description: "give this game as much of a ui polish as you can manage. the core rules are present already but the layout and structure (for both web and mobile) should prioritize digestability and presentation. animations, polish. we have the rulebook and scans of the physical cards if that helps"

## Context

The game is fully playable today, from the menu through four Regions and the Final
Battle. Every screen, however, is a single scrolling column of text labels and
outlined buttons. The player reads the Encounter as a row of chips, reads the
predicted outcome as three lines of prose, assigns cards by tapping text buttons, and
sees the result of a turn as a small grey sentence at the top of the next screen.
Nothing moves. On a phone the menu fills less than half the screen and the play
screen runs past the bottom of it; in a wide browser window the same narrow column
sits in the middle of empty space.

This feature changes how the game is presented and how the player reads and handles
it. It does not change the rules.

## Clarifications

### Session 2026-10-13

- Q: Which orientation should phones use? → A: Landscape is the preferred layout on
  mobile. It is designed and built first.
- Q: Is an upright (portrait) arrangement still wanted as a secondary layout? → A:
  No. The game is landscape only. There is one arrangement, on every target.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read the turn at a glance (Priority: P1)

> **Superseded in part by 011 (2026-10-17)**: the predicted outcome is no longer shown before Play. The cards lift the parts that count and mark what an Encounter works against; the sum and verdict show once Play is pressed. See `specs/011-card-contribution-highlights/spec.md`.

A player facing an Encounter can see, without scrolling and without reading
sentences, what they are up against, what they have assigned so far, and what would
happen if they committed right now. The Encounter, the Action Set being built, the
predicted outcome, and the Hand each occupy a distinct, stable area of the screen.
The predicted outcome is shown as a comparison (their total against the target) with
an unmistakable verdict, and it updates the moment an assignment changes.

**Why this priority**: The whole game is a sequence of these decisions. If the play
screen is hard to read, nothing else about the presentation matters. This story
alone makes the game noticeably better to play.

**Independent Test**: Start a game, reach the first Encounter, and confirm that the
Encounter, the Action Set, the outcome preview, the Hand and the commit control are
all visible together on a phone held in landscape, and that the verdict can be read correctly by
someone looking at the screen for a few seconds.

**Acceptance Scenarios**:

1. **Given** a Region Encounter on a phone in landscape, **When** the screen appears,
   **Then** the Encounter, the three Action Set slots, the outcome preview, all four
   Hand cards and the commit control are visible without scrolling.
2. **Given** an incomplete Action Set, **When** the player looks at the preview area,
   **Then** it shows which slot still needs a card rather than an error sentence.
3. **Given** a complete Action Set, **When** the player swaps one card, **Then** the
   preview shows the new totals and verdict immediately, and the values that changed
   are visibly drawn to the eye.
4. **Given** an enemy Encounter, **When** the preview is shown, **Then** the player
   can see their Attack against the enemy's HP and their Initiative against the
   enemy's Initiative as two separate comparisons, each with its own result.
5. **Given** a predicted outcome that would cost the player (damage, time penalty,
   poison, losing the Reserve, or losing the game), **When** the preview is shown,
   **Then** each cost is shown distinctly from the rewards and a game-ending outcome
   is the most prominent thing on the screen.
6. **Given** an Encounter with a Hardship, an enemy Ability or a journey Peril,
   **When** the screen appears, **Then** each is shown with its icon and name, and
   its effect on the numbers is already reflected in the preview.
7. **Given** any point in a game, **When** the player looks at the screen, **Then**
   they can tell which Region they are in, how far through it they are, and how many
   cards are in the deck, the discard and the trash.

---

### User Story 2 - Cards that look and handle like cards (Priority: P2)

Mage Cards appear as cards: a framed face in the card's Ether colour, with its name,
Level, and the numbers and icons arranged as on the printed card. A player who owns
the physical game recognises a card on sight; a player who does not can still tell
at a glance what a card offers in each of the three roles. A card's state (in the
Hand, assigned to a slot, fused, Downgraded this Encounter, unaffordable to Upgrade,
chosen for Soak) is visible on the card itself. Any card can be opened for a
larger, fully legible view.

**Why this priority**: Cards are the game's only playing pieces, and the player
handles them every turn. After the play screen is readable, the quality of the cards
is what most determines whether the game feels finished.

**Independent Test**: Lay a Hand beside the corresponding physical cards (or scans)
and confirm that each value sits in the corresponding position, and that every card
state used in the game is distinguishable without reading a text label.

**Acceptance Scenarios**:

1. **Given** a card in the Hand, **When** the player looks at it, **Then** its name,
   Level, Ether colour, and its Spell, Element and Boost values are legible at Hand
   size on a phone.
2. **Given** a card in the Hand, **When** the player opens it, **Then** a larger view
   shows the full card at its current Level, what the next Level would give and what
   it costs, and what a Downgrade would leave.
3. **Given** a card assigned to a slot, **When** the player looks at the Hand and the
   Action Set, **Then** it is obvious which card fills which slot and which role of
   that card is in use.
4. **Given** two fused cards, **When** the player looks at the Hand, **Then** they
   appear as one combined piece with the tucked card visibly behind and the chosen
   Ether element shown.
5. **Given** a card that cannot be chosen in the current step, **When** the player
   looks at it, **Then** it is visibly unavailable and the reason is shown on or
   beside it.
6. **Given** the Key Card for the current Encounter, **When** the screen appears,
   **Then** the Encounter is presented as the face of that card rather than as a
   name in small print.

---

### User Story 3 - Motion that shows what happened (Priority: P3)

When the player commits, the game shows the result instead of describing it. Cards
travel from the Hand to where they are played; totals count up against the target;
the verdict lands; XP is awarded, damage arrives, cards are discarded or trashed,
and the next Hand is dealt, each as a visible step in order. Upgrades and Downgrades
visibly change the card. The player can follow cause and effect without reading a
summary, and can skip ahead whenever they like.

**Why this priority**: Motion is what turns a correct interface into a satisfying
one, and it replaces the after-the-fact text summary as the way the player learns
what a turn did. It depends on the layout and cards from the first two stories.

**Independent Test**: Play one Encounter of each kind to a complete victory, a
narrow victory and a loss, and confirm that an observer who did not see the preview
can say what happened from the resolution sequence alone.

**Acceptance Scenarios**:

1. **Given** a complete Action Set, **When** the player commits, **Then** the played
   cards move to the Encounter, the totals are shown against the target, and the
   verdict is revealed, in that order.
2. **Given** a resolved Encounter, **When** there are consequences (XP, damage, time
   penalty, poison, a discarded Reserve, a trashed card), **Then** each is shown as
   its own step at the place on screen where it applies.
3. **Given** a resolution sequence in progress, **When** the player taps, **Then**
   the sequence completes at once and the game is ready for the next decision.
4. **Given** a card being Upgraded or Downgraded, **When** the change happens,
   **Then** the card visibly changes Level and the values that changed are
   highlighted.
5. **Given** the end of an Encounter, **When** the next Hand is drawn, **Then** cards
   arrive from the deck one at a time and the deck, discard and trash counts change
   as the cards move.
6. **Given** any control, **When** the player presses it, **Then** it responds
   visibly within the same moment, whether or not the action is allowed.
7. **Given** a player who has asked for reduced motion (through the device setting
   or the game's own setting), **When** anything resolves, **Then** the same
   information is shown with movement replaced by simple fades or instant changes.

---

### User Story 4 - At home on every screen (Priority: P4)

The game is played in landscape everywhere, in one arrangement: the Encounter and
its predicted outcome on one side, the Hand and the controls on the other, with the
controls within reach of the thumbs at the lower corners. A phone is the smallest
case; tablets and desktop browsers get the same arrangement with larger cards and
more room, not a small layout floating in empty space. Notches and rounded corners
are respected whichever way round the phone is held. On a desktop the game also
responds to the mouse and the keyboard.

**Why this priority**: The landscape arrangement itself arrives with the first
story, sized for a phone. This story covers what is left: making good use of larger
screens, safe areas in both landscape directions, resizing, mouse and keyboard, and
behaving sensibly in a window the layout does not suit. It is ranked after cards
and motion because those improve every turn on every device.

**Independent Test**: Open the same mid-game position on a small phone and a large
phone in both landscape directions, a tablet, and a desktop browser at several
window sizes, and confirm that each is fully usable and none is mostly empty.

**Acceptance Scenarios**:

1. **Given** a phone in landscape, in either direction, **When** any screen is
   shown, **Then** nothing interactive sits under the notch, the rounded corners or
   the home indicator.
2. **Given** the mobile app, **When** the device is held upright, **Then** the game
   stays in landscape.
3. **Given** a game in progress, **When** the window is resized or the device is
   turned to the other landscape direction, **Then** the layout adapts and the
   player's current assignments and step are kept.
4. **Given** a desktop browser, **When** the player uses a mouse, **Then** controls
   and cards show a hover state, and the common actions can also be performed from
   the keyboard.
5. **Given** the Final Battle with a Hand of seven and two Action Sets, **When** it
   is shown on a phone, **Then** every card remains legible and tappable and both
   Action Sets are visible together.
6. **Given** a tablet or a desktop browser window, **When** an Encounter is shown,
   **Then** the content uses the extra room, with text and cards at a comfortable
   reading size.
7. **Given** a browser window taller than it is wide (including a phone browser
   held upright), **When** the game is shown, **Then** it remains playable at the
   reduced size and a notice asks the player to turn the device or widen the
   window.

---

### User Story 5 - A sense of occasion (Priority: P5)

The moments around play are presented as moments. The title screen introduces the
game and lets the player choose a dragon, a difficulty and alternate rules from
options that explain themselves. Entering a new Region, reaching the Final Battle,
winning and losing each get their own presentation. The end screen shows the score
and how it was earned, and offers a quick way back in.

**Why this priority**: These screens are seen once or a few times per game rather
than every turn, so they matter less than the play screen, but they are where the
game makes its first and last impression.

**Independent Test**: Play one complete game and confirm that the title screen, each
Region change, the start of the Final Battle and the ending are each visually
distinct from an ordinary turn.

**Acceptance Scenarios**:

1. **Given** the title screen, **When** the player selects a dragon, **Then** they
   see that dragon's name, title and Ether colour, and what makes it different to
   fight.
2. **Given** the title screen, **When** the player selects a difficulty or an
   alternate rule, **Then** they see in plain words what it changes.
3. **Given** the last Encounter of a Region, **When** it resolves, **Then** the
   arrival in the next Region is announced with its name before the next Encounter
   appears.
4. **Given** the end of the fourth Region, **When** the Final Battle begins,
   **Then** the dragon is introduced and the two stages of the battle are laid out.
5. **Given** a won game, **When** the end screen appears, **Then** the score is
   shown with the parts that make it up, and the player can start again with the
   same options in one action.
6. **Given** a lost game, **When** the end screen appears, **Then** it says where
   and how the game was lost.

---

### User Story 6 - Help where the question arises (Priority: P6)

A player who does not remember what an icon, a Hardship, an Ability, a Peril or a
game term means can tap it and get a short explanation in the rulebook's words,
without leaving the game. The multi-step actions (Fuse, Divert, Regroup, Soak,
choosing starting cards) guide the player through each step and can be cancelled.

**Why this priority**: The icon language is dense and currently assumes the player
knows the rulebook. This makes the game approachable to someone who has not played
the physical version, but experienced players can enjoy the rest without it.

**Independent Test**: Give the game to someone who has never played it and confirm
that they can find out what every symbol on the first Encounter means without
outside help.

**Acceptance Scenarios**:

1. **Given** any icon or named effect on screen, **When** the player taps (or
   hovers and clicks) it, **Then** a short explanation appears and can be dismissed
   without affecting the game.
2. **Given** a multi-step action in progress, **When** the player looks at the
   screen, **Then** the current step is stated, the cards that can be chosen are
   distinguished from those that cannot, and there is a visible way to cancel.
3. **Given** the Soak step, **When** the player selects cards to Downgrade, **Then**
   a running total fills toward the damage owed and the confirm control becomes
   available only when the damage is covered.
4. **Given** the Upgrade step, **When** the player has XP, **Then** the cards they
   can afford are distinguished from those they cannot, and each shows its cost.

---

### Edge Cases

- The player taps repeatedly or commits again while a resolution sequence is still
  playing: input must never be lost, duplicated or applied to the wrong step.
- A browser window that is taller than it is wide, or too small for the layout to
  be legible (including a phone browser held upright): the game stays playable at
  the reduced size and shows a notice asking the player to turn the device or widen
  the window.
- The Final Journey Hand of seven cards, and a Hand reduced below four by Knock Out
  or a short deck.
- A step in which no card can legally be chosen (for example, no affordable
  Upgrade, or a Hand that cannot Soak the damage): the screen says so and offers the
  one action that remains.
- Card and Region names of very different lengths, and the longest Ability and
  Hardship descriptions, must fit without truncation that hides meaning.
- Elements are distinguished by colour: every use of an Ether colour must also carry
  its icon or name so the game is playable with colour vision deficiency.
- The window is resized, the device turned to the other landscape direction, or the
  app sent to the background in the middle of an animation.
- A device too slow to animate smoothly: the game must stay responsive and correct
  even if motion is reduced.
- The Cavalier rule removes Fusing: the Fuse control must be absent, not disabled
  without explanation.
- A game that goes straight from a Region to the Final Battle because fewer than
  five cards remain.

## Requirements *(mandatory)*

### Functional Requirements

**Layout and hierarchy**

- **FR-001**: The play screen MUST present the Encounter, the Action Set(s), the
  outcome preview, the Hand and the commit control as distinct regions whose
  positions stay the same from turn to turn.
- **FR-002**: On a phone, every step of the game, including both stages of the Final
  Battle, MUST fit on one screen without scrolling. No screen of the game scrolls;
  where the window is too small or too narrow for the layout to be legible, the
  game MUST say so and say how to fix it (turn the device, or widen the window).
- **FR-003**: The game MUST show at all times during play the current Region or
  battle stage, progress through it, and the deck, discard and trash counts.
- **FR-004**: The game MUST use one consistent visual language (type scale, spacing,
  colour roles, icon style, control shapes) across every screen.
- **FR-005**: Each screen MUST have exactly one visually dominant primary action,
  and it MUST be the action that advances the game.

**Outcome preview**

- **FR-006**: The outcome preview MUST show each comparison (Attack against HP,
  Initiative against Initiative, Move against MP, or a total against the dragon's
  tiers) as the player's value beside the target with a clear result.
- **FR-007**: The preview MUST update immediately on any change to the assignment,
  the Boost target, Fusing, or giving up the Reserve.
- **FR-008**: The preview MUST show rewards and costs separately, and MUST make a
  game-ending outcome more prominent than anything else on screen.
- **FR-009**: When the Action Set is incomplete, the preview MUST say what is
  missing instead of showing an error.
- **FR-010**: The numbers shown in the preview MUST always equal the numbers the
  rules produce when the player commits.

**Cards**

- **FR-011**: Mage Cards MUST be drawn as cards in their Ether colour, with name,
  Level and all role values arranged as on the printed card.
- **FR-012**: Every card state used in play (available, assigned and to which role,
  fused, Downgraded this Encounter, unavailable, selected) MUST be visible on the
  card without relying on a text label alone.
- **FR-013**: The player MUST be able to open any visible card for an enlarged view
  showing its current Level, its next Level and Upgrade cost, and its Downgraded
  state.
- **FR-014**: The current Encounter MUST be presented as a card face, including the
  dragon in the Final Battle, with its tiers readable as a ladder.
- **FR-015**: Every Ether element MUST be identifiable by something other than
  colour.

**Interaction**

- **FR-016**: The player MUST be able to assign a card to a role with a single
  direct action, and to change or clear an assignment as easily as making it.
- **FR-017**: Every interactive element MUST be large enough to tap reliably with a
  thumb and MUST respond visibly when pressed.
- **FR-018**: Multi-step actions (choosing starting cards, Fuse, Divert, Regroup,
  Soak) MUST state the current step, mark which cards are eligible, and offer a way
  to cancel before committing.
- **FR-019**: Unavailable actions MUST show why they are unavailable.
- **FR-020**: In a desktop browser, interactive elements MUST show a hover state and
  the commit, cancel and card-selection actions MUST be available from the keyboard.

**Motion and feedback**

- **FR-021**: Committing an Action Set MUST play a resolution sequence that shows,
  in order, the cards played, the totals against the target, the verdict, and each
  consequence.
- **FR-022**: Every movement of a card between Hand, deck, discard, trash and the
  Action Set MUST be shown as that card moving between those places.
- **FR-023**: Upgrades, Downgrades, XP gains, damage, time penalties and poison MUST
  each have distinct visible feedback at the place they apply.
- **FR-024**: The player MUST be able to skip any animation with a tap, and no
  animation may leave the game unable to accept the next decision afterward.
- **FR-025**: Changes between screens and steps MUST be transitions, not abrupt
  replacements of the whole screen.
- **FR-026**: The game MUST offer a reduced-motion mode, on by default when the
  device requests it, that conveys the same information without travel or shake
  effects.
- **FR-027**: Animation MUST never change the result of an action or the order in
  which the rules are applied.

**Responsive presentation**

- **FR-028**: The game MUST be presented in landscape only, in a single arrangement
  that grows to use the space on tablets and desktop browsers. The mobile apps MUST
  stay in landscape, in either direction, however the device is held.
- **FR-028a**: In the landscape arrangement on a phone, the Hand, the secondary
  actions and the commit control MUST sit where the thumbs reach when the device is
  held by its short edges.
- **FR-029**: The game MUST keep all content and controls clear of device notches,
  rounded corners and system gesture areas.
- **FR-030**: Resizing the window, or turning the device between the two landscape
  directions, MUST preserve the game position and the player's in-progress
  assignments.

**Framing screens**

- **FR-031**: The title screen MUST present dragon, difficulty and alternate-rule
  choices with a plain-language description of what each changes.
- **FR-032**: Entering a Region, starting the Final Battle, winning and losing MUST
  each have a distinct presentation.
- **FR-033**: The end screen MUST show the score with its components after a win,
  the cause after a loss, and a single action to play again with the same options.
- **FR-034**: The player MUST be able to leave a game in progress and return to the
  title screen, with a confirmation.

**Help**

- **FR-035**: Every icon, Hardship, enemy Ability, journey Peril and game term shown
  on screen MUST offer a short explanation on demand that does not disturb the game.
- **FR-036**: Rules explanations MUST agree with the rulebook.

**Preservation**

- **FR-037**: The feature MUST NOT change any rule, card value, difficulty setting
  or scoring. Every action available today MUST remain available.
- **FR-038**: The existing fan-project credit and non-affiliation notice MUST remain
  visible from the title screen.

### Key Entities

- **Card face**: The visual form of a Mage Card at a given Level: name, Ether
  colour, Level, and the Spell, Element and Boost values in their printed positions,
  plus a visible state.
- **Encounter face**: The visual form of the current challenge (an enemy, a journey,
  or a stage of the Final Battle): its targets, its rewards and costs, and any
  Hardship, Ability or Peril.
- **Action Set**: Three role slots (Spell, Element, Boost), each empty or holding a
  card, with the Boost target where it applies. Two of them in the Final Battle.
- **Outcome preview**: The predicted result of committing the current Action Set:
  comparisons, verdict, rewards and costs.
- **Resolution sequence**: The ordered set of visible steps that plays between
  committing and the next decision.
- **Piles**: The deck, discard and trash, each with a place on screen and a count.
- **Glossary entry**: The short explanation attached to an icon or game term.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a phone in landscape, every Region Encounter and both stages of the
  Final Battle can be played from first look to commit without scrolling.
- **SC-002** *(superseded by 011, 2026-10-17: no predicted outcome is shown before Play)*: A player who knows the rules can state the predicted outcome of a
  complete Action Set (win, narrow win or loss, and what it will cost) within 3
  seconds of looking at the screen.
- **SC-003**: An observer who sees only the resolution sequence, not the preview,
  can correctly say whether the Encounter was won and what it cost in at least 9 of
  10 Encounters.
- **SC-004**: Someone who has never played the game can discover the meaning of
  every symbol on their first Encounter without leaving the game, in under 2
  minutes.
- **SC-005**: A first-time player completes the setup step and their first three
  Encounters without outside help.
- **SC-006**: Every control responds visibly within a tenth of a second of being
  pressed, and motion stays smooth on a mid-range phone from the last four years.
- **SC-007**: A full resolution sequence takes no more than 3 seconds unskipped and
  can be skipped to completion in under half a second.
- **SC-008**: At phone, tablet and desktop sizes in both orientations, no screen is
  more than one third empty and no text falls below a comfortable reading size.
- **SC-009**: Every interactive element can be tapped on the first try at least 95%
  of the time in ordinary two-thumb landscape phone use.
- **SC-010**: For every Mage Card at every Level, each value appears in the position
  corresponding to the printed card.
- **SC-011**: The game is fully playable with colour perception removed.
- **SC-012**: Every game position reachable today is reachable after the change with
  identical numbers and outcomes; the existing rules test suite passes unchanged.
- **SC-013**: A full game takes no longer to play, with animations skipped, than it
  does today.

## Assumptions

- **Scans and rulebook are reference, not content.** The card scans and rulebook are
  used to match the printed cards' layout, proportions, colours and icon language,
  and as the source for help text. The scanned artwork itself is not included in the
  game, in keeping with the project's stated position that reference material is not
  part of the repository. Cards and Encounters get original frames, textures and
  ornament; the mage and dragon illustrations are not reproduced. This is the
  assumption most worth confirming, because including the scans would change what
  the cards look like and what can be distributed.
- **Rules are frozen.** The rules, card data and the rules interpretations listed in
  the README stay as they are. Any rules defect noticed along the way is reported
  rather than fixed under this feature.
- **Landscape only.** There is one arrangement and it is landscape, on phones,
  tablets and desktop browsers. The mobile apps are locked to landscape in either
  direction. No upright (portrait) arrangement is designed or built. A browser
  cannot be locked, so an upright browser window gets the same layout scaled down
  with a notice.
- **No sound.** Sound effects, music and haptic feedback are out of scope. The
  design should leave room for them but none are added.
- **No new game features.** Saving and resuming a game, statistics, achievements,
  an undo of committed actions, a scripted tutorial and additional languages are out
  of scope. On-demand help (User Story 6) is the only teaching aid.
- **Single player, single device.** There are no accounts, no network features and
  no data collected.
- **Supported targets are unchanged**: web, Android and iOS, on devices capable of
  running the game today.
- **Fonts and ornament must be freely licensed** or made for the project, since
  nothing from the reference material is shipped.
- **Priority order is build order.** If the work has to stop early, the stories are
  delivered in priority order and each leaves the game in a shippable state.
