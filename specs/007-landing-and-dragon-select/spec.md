# Feature Specification: Landing Page and Dragon Selection

**Feature Branch**: `007-landing-and-dragon-select`

**Created**: 2026-10-16

**Status**: Implemented (flavour text pending the user's rewrite)

**Input**: User description: "the landing page for the game should be the title, subtitle, fan-made disclaimer, and buttons for how to play, records, and play. the dragon selection is the second page and that should be the four dragon cards, a small flavorful description along with the dragons' stats. only show the dragon which is selected's stats"

## Clarifications

### Session 2026-10-16

- Q: What should the landing page subtitle say? → A: A new line written for this project, drawn loosely (not quoted) from the rulebook's story: the player is an apprentice mage of the Tower, sent across Vale to hunt a dragon that came through an Ether rift and to earn the title of Ether Mage. Draft: "Cross the four Regions of Vale, hunt the dragon, and earn the name of Ether Mage."
- Q: What should each dragon's flavour description draw on? → A: Its existing title ("Scales of Stone", "The Last Breath", …) together with the character of its primary Ether (the Ether of its early damage), as the rulebook defines it: Water — very strong Armor and Initiative; Fire — very strong Attack, low everything else; Lightning — very strong Move, strong Initiative; Shadow — very strong Boost, the one Ether that flexes between Attack and Move. Drafts:
  - Grimroch, Scales of Stone (Water): "Its scales are stone and the water behind them deep; it turns spells aside and is seldom slower than you."
  - Helsang, The Undying (Shadow): "It surges back from every wound, Shadow carrying it from the hunt to the kill and back without warning."
  - Rodving, The Last Breath (Fire): "Slow to rise and thin of hide, but its fire is the last breath most mages ever draw."
  - Vuurhast, Death and Darkness (Lightning): "It comes out of the dark on the storm, already moving, gone before the thunder."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A landing page that only welcomes the player (Priority: P1)

When the player opens the game, they see a calm landing page: the name of the game, its subtitle, the fan-made disclaimer, and three clear ways forward — How to Play, Records and Play. Nothing on it asks them to decide anything about a game yet.

**Why this priority**: Today the first screen mixes the welcome with the dragon choice and a dense grid of stats, which is a lot to take in before the player has decided to play. A clean landing page is the core of the request and the entry point to everything else.

**Independent Test**: Launch the game and confirm the landing page shows the title, subtitle, disclaimer and the How to Play, Records and Play buttons, and no dragon cards or stats; press each button and confirm it goes where it says.

**Acceptance Scenarios**:

1. **Given** the game has just launched, **When** the first screen appears, **Then** it shows the game's title, its subtitle, the fan-made disclaimer, and buttons for How to Play, Records and Play, and shows no dragon cards or dragon stats.
2. **Given** the landing page is showing, **When** the player presses How to Play, **Then** the rulebook opens, and closing it returns to the landing page.
3. **Given** the landing page is showing, **When** the player presses Records, **Then** the records screen opens, and leaving it returns to the landing page.
4. **Given** the landing page is showing, **When** the player presses Play, **Then** the dragon selection page appears.
5. **Given** the landing page is showing, **When** the player looks for the main way forward, **Then** Play stands out as the primary action over How to Play and Records.

---

### User Story 2 - Choose a dragon from four cards, seeing only the chosen one's stats (Priority: P1)

After pressing Play, the player sees the four dragons as cards. Each card shows the dragon's head, name, title and a short, flavourful line about it. Only the dragon currently chosen has its stats shown — its Initiative, early damage, Armor and the Journey and Battle ladders — so the player can read one dragon at a time instead of four grids at once. Choosing a different card moves the stats to that dragon. From here the player continues to the difficulty and alternate-rules step as today.

**Why this priority**: This is the second half of the request and the only way to start a game once the landing page exists; the two stories ship together.

**Independent Test**: From the landing page press Play, confirm four dragon cards each with a flavour line, confirm exactly one dragon's stats are visible and they belong to the chosen dragon, choose each other dragon in turn and confirm the stats follow, then continue and confirm the next step carries the chosen dragon.

**Acceptance Scenarios**:

1. **Given** the player pressed Play, **When** the dragon selection page appears, **Then** it shows four dragon cards, each with the dragon's head, name, title and a short flavour description.
2. **Given** the dragon selection page is showing, **When** the player looks at it, **Then** the full stats are shown for the chosen dragon only, and no other dragon's stats are visible.
3. **Given** one dragon is chosen, **When** the player chooses a different card, **Then** that card is marked as chosen, the previous one is unmarked, and the stats shown change to the newly chosen dragon.
4. **Given** a dragon is chosen, **When** the player continues, **Then** the difficulty and alternate-rules step appears with that dragon carried forward, as it does today.
5. **Given** the player has played before, **When** the dragon selection page appears, **Then** the dragon from their last game is already chosen and its stats are shown.
6. **Given** a dragon is chosen, **When** the player views the page, **Then** the large moving picture of the whole chosen dragon is still shown beside the cards.

---

### User Story 3 - Move back and forth between the pages (Priority: P2)

From the dragon selection page the player can go back to the landing page, and from the difficulty step they can still go back to the dragon page, without losing any choice they made.

**Why this priority**: Adding a page in front of the dragon choice adds a step the player may want to undo. The game is playable without it, but a dead end would feel broken.

**Independent Test**: Press Play, choose a dragon, go back to the landing page, press Play again and confirm the same dragon is still chosen; continue to the difficulty step, go back, and confirm the dragon page shows the same choice.

**Acceptance Scenarios**:

1. **Given** the dragon selection page is showing, **When** the player chooses to go back (on-screen or with the system back gesture/button or Escape), **Then** the landing page appears.
2. **Given** the player chose a dragon and went back to the landing page, **When** they press Play again, **Then** the dragon they chose is still chosen.
3. **Given** the difficulty step is showing, **When** the player goes back, **Then** the dragon selection page appears with their dragon still chosen and its stats shown.

---

### Edge Cases

- A game ends or the player leaves a game: they return to the landing page, and pressing Play shows their last dragon already chosen.
- The remembered dragon no longer exists in the game data: the dragon page falls back to the default dragon, so exactly one dragon is always chosen and one set of stats is always shown.
- Narrow or tall windows (phone portrait, small phones): all four dragon cards stay visible and tappable, and the chosen dragon's stats are fully readable without overlapping the cards; if space is short the page may scroll rather than clip.
- The player chooses the card that is already chosen: nothing changes and the stats stay as they are.
- Keyboard or controller players: they can move between the four cards and the stats follow the card that is chosen (not merely focused), so stats never flicker while moving focus.
- Reduced motion is on: the chosen dragon's picture is shown still, as elsewhere in the game.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST open on a landing page showing the game's title, its subtitle and the fan-made disclaimer. The subtitle MUST be a line written for this project that frames the player as an apprentice mage of the Tower hunting a dragon across Vale to earn the title of Ether Mage, drawn from the rulebook's story without quoting it.
- **FR-002**: The landing page MUST offer exactly three main buttons: How to Play, Records and Play, with Play presented as the primary action.
- **FR-003**: The landing page MUST NOT show dragon cards, dragon stats, difficulty or alternate-rule choices.
- **FR-004**: How to Play MUST open the rulebook and Records MUST open the records screen; leaving either MUST return to the landing page.
- **FR-005**: Play MUST open the dragon selection page.
- **FR-006**: The dragon selection page MUST show one card for each of the four dragons, each with the dragon's head picture, name, title and a short flavour description of one or two sentences.
- **FR-007**: Each dragon MUST have its own flavour description, written for this project, built from the dragon's title and the character of its primary Ether (the Ether of its early damage) as the rulebook defines it: Water, strong Armor and Initiative; Fire, great Attack but little else; Lightning, great Move and strong Initiative; Shadow, great Boost and flexing between Attack and Move.
- **FR-008**: The dragon selection page MUST show the full stats (Initiative, early damage, Armor, Journey ladder and Battle ladder) for the chosen dragon only; the other dragons' cards MUST NOT show stats.
- **FR-009**: Exactly one dragon MUST be chosen at all times on the dragon selection page; choosing a card MUST make it the chosen dragon and update the stats shown to match it.
- **FR-010**: The dragon selection page MUST keep showing the large animated full-body picture of the chosen dragon, as the title screen does today.
- **FR-011**: The dragon selection page MUST offer a way to continue to the existing difficulty and alternate-rules step, carrying the chosen dragon.
- **FR-012**: The dragon selection page MUST offer a way back to the landing page; the system back gesture/button and Escape MUST do the same. Going back MUST NOT discard the chosen dragon.
- **FR-013**: Going back from the difficulty and alternate-rules step MUST lead to the dragon selection page, not the landing page.
- **FR-014**: The dragon choice MUST still be remembered after setting out, and pre-selected the next time the dragon selection page opens.
- **FR-015**: Every path that today leads back to the title screen (end of a game, leaving a game, closing Records opened from the title) MUST lead to the landing page.
- **FR-016**: Settings and the Glossary MUST remain reachable before a game starts, as secondary controls that do not compete with the three main buttons.
- **FR-017**: Both pages MUST lay out without clipping or overlap at every window size the game supports, including phone portrait.

### Key Entities

- **Dragon**: One of the four foes. Has a name, title, Ether, head picture, full-body picture, stats (Initiative, early damage, Armor, Journey and Battle ladders) and, new with this feature, a short flavour description drawn from its title and primary Ether. Its primary Ether is the Ether of its early damage: Grimroch Water, Helsang Shadow, Rodving Fire, Vuurhast Lightning.
- **Chosen dragon**: The single dragon currently selected; carried from the dragon page to the difficulty step, kept while moving back and forth, and remembered after setting out.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On launch, the landing page shows no more than three main buttons and zero dragon stats.
- **SC-002**: On the dragon selection page, exactly one dragon's stats are visible at any moment, and they match the chosen dragon 100% of the time, including immediately after each change of choice.
- **SC-003**: A returning player can get from launch to the start of a game with their previous setup in 3 presses (Play, Continue, Set Out).
- **SC-004**: Moving from the dragon page to the landing page and back, or from the difficulty step to the dragon page and back, preserves 100% of the player's choices.
- **SC-005**: At every supported window size, all landing-page text and buttons and all four dragon cards plus the chosen dragon's stats are fully visible or reachable by scrolling, with no overlap and every button at least the game's minimum tap size.
- **SC-006**: A first-time player shown the dragon page can say which dragon is chosen and read its Armor and ladders without confusing them with another dragon's.

## Assumptions

- The subtitle replaces the existing tagline ("A solo card game of four Regions and one dragon.") with the new story line in Clarifications; the disclaimer is the existing fan-made notice, unchanged.
- The difficulty and alternate-rules step (feature 002) is unchanged apart from its back button now leading to the dragon selection page.
- Settings and the Glossary stay reachable from the landing page as small secondary controls (as today), since otherwise Settings could not be reached before a game; the request lists only the three main buttons.
- The flavour descriptions are new text written for this project, not taken from the published game, and are stored with the other dragon data.
- The dragon cards show the dragon's head, still, as they do now; the full-body animated picture stays beside the cards on the dragon page and moves off the landing page.
- The landing page may keep a decorative picture (for example the woodcut tear or a dragon) as long as it is not a choice and shows no stats.
- Stats are shown in one place for the chosen dragon (beside or below the cards), using the same stat presentation the game already uses, including the full ladder tooltip.
