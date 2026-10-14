# Feature Specification: Two-Step Game Setup

**Feature Branch**: `002-split-game-setup`

**Created**: 2026-10-14

**Status**: Draft

**Input**: User description: "add a selection process to the beginning of a game, instead of selecting dragon, difficulty, and modifier all in the same screen. show the dragon options on one screen, and the difficulty and modifiers on another, shared screen."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choose a dragon on its own screen (Priority: P1)

When the player opens the game, the first thing they see is the title and a screen dedicated to picking which dragon to hunt. With the whole screen given to the dragons, each option has room to show its art, name, title and what makes it different. The player picks a dragon and moves on to the next step.

**Why this priority**: The dragon is the most consequential choice and today it competes for space with five other decisions. Giving it its own screen is the core of the request; without it, nothing has been split.

**Independent Test**: Launch the game, confirm only dragon options (plus the title, Settings and Glossary) are shown, select a dragon, and confirm the game advances to a second setup step carrying that dragon.

**Acceptance Scenarios**:

1. **Given** the game has just launched, **When** the first setup screen appears, **Then** it shows every available dragon and no difficulty or alternate-rule choices.
2. **Given** the dragon screen is showing, **When** the player selects a dragon, **Then** that dragon is clearly marked as chosen and any previously chosen dragon is unmarked.
3. **Given** a dragon is chosen, **When** the player continues, **Then** the second setup screen appears and the chosen dragon is the one that will be hunted.
4. **Given** the player has played before, **When** the dragon screen appears, **Then** the dragon from their last game is already chosen.

---

### User Story 2 - Choose difficulty and alternate rules together, then set out (Priority: P1)

After picking a dragon, the player sees a second screen holding both the difficulty options and the alternate rules (Cavalier, Glass Cannon). Each option still says what it changes. The screen reminds the player which dragon they picked. From here they set out and the game begins with all their choices applied.

**Why this priority**: Without this screen there is no way to finish setup and start a game; it is required for the split to be playable at all. It ships together with Story 1.

**Independent Test**: From the second screen, pick a difficulty, toggle each alternate rule, set out, and confirm the game starts with that dragon, that difficulty and exactly those rules active.

**Acceptance Scenarios**:

1. **Given** the player arrived from the dragon screen, **When** the second screen appears, **Then** it shows all difficulty levels and all alternate rules on the same screen, along with a reminder of the chosen dragon.
2. **Given** the second screen is showing, **When** the player selects a difficulty, **Then** exactly one difficulty is marked as chosen.
3. **Given** the second screen is showing, **When** the player toggles an alternate rule, **Then** it switches between on and off independently of the other rule and of the difficulty.
4. **Given** choices are made on both screens, **When** the player sets out, **Then** the game starts with the chosen dragon, difficulty and alternate rules, and those choices are remembered for next time.
5. **Given** the player has played before, **When** the second screen appears, **Then** the difficulty and alternate rules from their last game are already chosen.

---

### User Story 3 - Go back to change the dragon (Priority: P2)

On the second screen, the player realises they want a different dragon. They go back to the dragon screen, pick another, and return to find their difficulty and alternate-rule choices still as they left them.

**Why this priority**: Splitting a single screen into two creates a new trap — a choice the player can no longer see or change. A way back removes it, but the game is still playable without it.

**Independent Test**: On the second screen, change the difficulty and turn on a rule, go back, choose a different dragon, continue, and confirm the difficulty and rule are unchanged.

**Acceptance Scenarios**:

1. **Given** the second screen is showing, **When** the player chooses to go back, **Then** the dragon screen appears with the current dragon still marked as chosen.
2. **Given** the player went back and changed nothing, **When** they continue again, **Then** the second screen shows exactly the choices they had made before going back.
3. **Given** the player went back and chose a different dragon, **When** they continue, **Then** the difficulty and alternate-rule choices are preserved.
4. **Given** the second screen is showing on a device with a system back gesture or button, **When** the player uses it, **Then** it behaves the same as the on-screen way back.

---

### Edge Cases

- A first-time player has no remembered choices: both screens start on the default dragon, Normal difficulty and no alternate rules, so setting out immediately is always possible.
- A remembered dragon no longer exists in the game's card data: the dragon screen falls back to the default dragon rather than showing nothing chosen.
- Returning to the title after a game ends (or quitting from the in-game menu) lands on the dragon screen, with the just-played choices remembered.
- The player opens Settings or the Glossary from a setup screen and closes it: they return to the same setup screen with choices intact.
- Small or narrow screens (phones in either orientation): every dragon, difficulty and alternate rule fits on its screen without being cut off by rounded corners or notches, in line with the existing layout rules.
- Keyboard or controller navigation: focus starts on the action that moves forward (continue on the first screen, set out on the second), and all choices remain reachable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST present setup as two sequential screens: first a dragon screen, then a shared difficulty-and-alternate-rules screen.
- **FR-002**: The dragon screen MUST show every available dragon, each with its art, name, title and the facts that distinguish it (currently initiative and early damage), and MUST NOT show difficulty or alternate-rule choices.
- **FR-003**: The dragon screen MUST keep the game's title and the existing access to Settings and the Glossary, and the attribution/credits text.
- **FR-004**: The dragon screen MUST provide a clear way to continue to the second screen; exactly one dragon MUST always be chosen, so continuing is never blocked.
- **FR-005**: The second screen MUST show all six difficulty levels and both alternate rules (Cavalier, Glass Cannon) together, each with the same short explanation of what it changes that is shown today.
- **FR-006**: The second screen MUST show which dragon was chosen.
- **FR-007**: Exactly one difficulty MUST be chosen at all times; each alternate rule MUST toggle on and off independently.
- **FR-008**: The second screen MUST provide a way to set out, which starts a game with the chosen dragon, difficulty and alternate rules.
- **FR-009**: The second screen MUST provide a way back to the dragon screen, and the system back gesture/button MUST do the same; going back MUST NOT discard any choices.
- **FR-010**: Both screens MUST start pre-filled with the player's choices from their last game, or with the defaults (default dragon, Normal, no alternate rules) if there is none.
- **FR-011**: Setting out MUST remember all choices for next time, as it does today.
- **FR-012**: Both screens MUST follow the game's existing visual style, layout safe areas and minimum tap sizes.
- **FR-013**: Every path that currently leads back to the title (end of game, quitting a game) MUST lead to the dragon screen.

### Key Entities

- **Game setup choices**: The dragon, the difficulty and the on/off state of each alternate rule. Carried from the first screen to the second, kept while moving back and forth, and remembered after setting out.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A returning player who wants to replay their last setup can start a game in 2 taps (continue, set out).
- **SC-002**: A player can change any single setup choice and start a game in no more than 4 taps.
- **SC-003**: No setup screen presents more than two groups of choices (one on the dragon screen, two on the second), down from three on today's single screen.
- **SC-004**: On every supported screen size, 100% of dragon, difficulty and alternate-rule options are fully visible without scrolling and with no text cut off.
- **SC-005**: Moving back from the second screen and forward again preserves 100% of the player's choices.

## Assumptions

- Selecting a dragon marks it as chosen; moving on is a separate "continue" action, rather than advancing the moment a dragon is tapped. This lets the player compare dragons and matches how the current screen behaves.
- The title, crest art, Settings, Glossary and credits stay with the dragon screen, since it is the first thing seen on launch; the second screen is a plain continuation of setup.
- The decorative crest that today follows the chosen dragon may move or change with the new layout; the requirement is only that the chosen dragon is visible on both screens.
- The set of dragons, difficulty levels and alternate rules, and what each one does, are unchanged; this feature only changes how they are presented.
- No separate "press start" splash screen is added before the dragon screen.
- The way choices are remembered between sessions is reused as-is.
