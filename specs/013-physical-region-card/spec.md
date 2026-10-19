# Feature Specification: The Left Side as the Physical Region Card and Deck

**Feature Branch**: `013-physical-region-card`

**Created**: 2026-10-18

**Status**: Draft

**Input**: User description: "for this effort, we are trying to shore up how the left hand side shows the region and the cards from a deck. the current result is partway there, but this should actually look like the physical game's region card - don't show the DOE-R0x text - but the enemies laid out in a 2x2 annd the regions laid out below those. the lower left area which shows the "Tap the bottom of the Boost card..." and other helpr texts, is not needed. the whole left side is meant to contain the region card, the deck of cards the mage cards are drawn from and then the encounters from the region card zoomed in. the left should look like a stack of cards as that is what they are - with the deck size being the remaining cards in the deck for the region"

## Background

This feature follows on from `specs/012-deck-region-card`, which put a Deck with a Region Card on top on the left side of the play screen, and added the Key Card lift and the zoom into the chosen Encounter. That work is partway there:

- The Region Card it draws does not look like the physical card. It shows a header with the card code ("REGION 1 · DOE-R01") and a row of small numbered chips rather than the printed layout.
- The left side is split in two. The Deck and Region Card sit in the upper part, and a separate box below them holds step tips such as "Tap the bottom of the Boost card to aim it at Attack or Initiative."
- The stack does not read clearly as a pile of real cards.

**The physical Region Card** (see `reference/sheets-official/o5.png`, Jade Mountains and Burning Basin) is laid out top to bottom:

1. **A title band.** It has the Region's name ("JADE MOUNTAINS") and "REGION 1" beneath it, with a skull ornament at each end.
2. **The four Enemies, in a 2×2 grid.** Each is a framed panel with the creature's art. Down its left edge is a column of stat badges: HP (heart), Initiative, Attack (Ether-coloured, with its Ether drop) and Armor (Ether-coloured shield). Any Ability icon sits at the top right, and the XP Reward sits in a star badge at the bottom right.
3. **The four Journeys, in a row of four tall panels below the Enemies.** Each has a header strip with MP (Ether-coloured mountain badge) and Time Penalty (hourglass), the landscape art below it, any Peril icon at the top right, and the XP Reward in a star badge at the bottom.
The printed card has no Encounter numbers. A panel's position gives its number: Enemies 1 and 2 on the top row and 3 and 4 below, left to right; Journeys 1 to 4 left to right. The game adds a small number marker to each panel (FR-002, FR-003), because the Key Card's number has to be matched to a panel at a glance.

4. **The card code** ("DOE-R01") is printed small at the bottom. The game does **not** show it.

## Clarifications

### Session 2026-10-18

- Q: With the lower-left box gone, where does its non-tip feedback go (refusals, Fuse/Divert/Regroup steps, setup prompt, Play tally and verdict, soak meter, XP purse)? → A: It temporarily replaces the card on the left side, shown instead of the Encounter for the moment it is needed. This gives the result text more room to appear and to explain the outcome of the Encounter. The lower-left box was always meant to be temporary and removed.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The Region Card looks like the physical card (Priority: P1)

A player who owns or has seen the physical game looks at the left side of the play screen and sees the Region Card laid out as it is printed. The Region's name and number are across the top, the four Enemies sit in a 2×2 grid with their stat badges and XP stars, and the four Journeys sit in a row beneath them with their MP, Time Penalty and XP stars. No card code appears anywhere.

**Why this priority**: This is the heart of the request. Every other story depends on the Region Card being right, because the zoomed Encounters are taken from it.

**Independent Test**: Start a game and look at the left side before the first Key Card is revealed. Compare it side by side with the Jade Mountains card in the official scan. Every Enemy and Journey is in the same position, with the same values, XP, Ether colours and icons, and "DOE-R01" appears nowhere.

**Acceptance Scenarios**:

1. **Given** the first Encounter of Region 1, **When** the whole Region Card is in view, **Then** it shows "Jade Mountains" and "Region 1" in a title band, the four Enemies in a 2×2 grid (1 and 2 on top, 3 and 4 below, as printed), and the four Journeys in a single row of four below them (1 to 4, left to right, as printed).
2. **Given** any Enemy panel, **When** the player reads it, **Then** it shows that Enemy's art, a column of HP, Initiative, Attack and Armor badges down its left edge (Attack and Armor in their Ether colours), any Ability icon at the top right, its XP Reward in a star at the bottom right, and a small marker with its Encounter number. The values match the Region's data.
3. **Given** any Journey panel, **When** the player reads it, **Then** it shows the MP badge in its Ether colour and the Time Penalty in a header strip, the landscape art below, any Peril icon, its XP Reward in a star at the bottom, and a small marker with its Encounter number. The values match the Region's data.
4. **Given** any Region, in any state of play, **When** the Region Card is shown, **Then** no card code (for example "DOE-R01" or "DOE-R02") is shown on it or anywhere else on the play screen.
5. **Given** the End of a Region, **When** the Region Card turns to the next Region, **Then** the new Region is laid out the same way with its own name, number, Enemies and Journeys.

---

### User Story 2 - The whole left side is the stack of cards (Priority: P1)

The left side of the play screen is one thing: the stack of cards held in the left hand. The Region Card lies on top, and the Mage Cards of the Deck lie beneath it. Their edges visibly stack, and the stack's thickness reflects how many cards remain in the Deck for this Region. The lower-left box with step tips is gone, and the stack takes the whole column.

**Why this priority**: The user asked for the left side to look like what it is, a stack of cards. The helper box breaks that and is no longer wanted.

**Independent Test**: Play the first Region from start to finish. At every step the left column holds only the stack: no tip box and no separate panel. The stack's depth always agrees with the Deck count in the header, and it shrinks as cards are drawn and Diverted.

**Acceptance Scenarios**:

1. **Given** any step of a Region Encounter, **When** the player looks at the left side, **Then** it shows only the stack of cards (Region Card on top, Deck beneath) filling the column, except while feedback temporarily takes the card's place (Story 4). No box with step tips is shown.
2. **Given** the Deck has N cards left, **When** cards are drawn into the Hand or Diverted, **Then** the stack visibly thins, and its depth always corresponds to the Deck count in the header.
3. **Given** the End of a Region, **When** the Deck is reshuffled, **Then** the stack visibly grows back to the reshuffled Deck's size before the new Hand is drawn.
4. **Given** the player is building an Action Set, **When** they would previously have seen a tip such as "Tap the bottom of the Boost card to aim it at Attack or Initiative" or "Tap two cards to swap their Roles. Hold a card to inspect it.", **Then** no such tip is shown on the left side.

---

### User Story 3 - The Encounter is the Region Card's panel, zoomed in (Priority: P2)

After the Hand is drawn and the Key Card reveals its Encounter number, the view zooms into that Enemy or Journey panel on the Region Card. The zoomed-in Encounter is that same printed panel enlarged, with the same layout, badges and art, so that it fills the left side. It does not swap to a differently styled face. Anything the printed panel shows only as an icon (the Ability, the Peril, the Key Card's Hardship) is still readable in full while zoomed in.

**Why this priority**: It completes the "encounters from the region card zoomed in" part of the request. It depends on Story 1's faithful panels.

**Independent Test**: Reach an Enemy Encounter with a Hardship and an Ability. The zoomed view is recognisably the same panel seen on the whole card, now large. The player can read its HP, Initiative, Attack, Armor, what its Ability does and what the Hardship changes, all without leaving the left side.

**Acceptance Scenarios**:

1. **Given** the Key Card shows Enemy 3, **When** the reveal ends, **Then** the view zooms from the whole Region Card into Enemy 3's panel until it fills the left side, keeping the panel's printed layout.
2. **Given** a zoomed Encounter, **When** the player reads it, **Then** every value used in play (Enemy HP, Initiative, Attack, Armor, Ability; Journey MP, Time Penalty, Peril; any Hardship from the Key Card) is visible and agrees with what the game uses.
3. **Given** the Encounter ends (Cleanup) or the player Diverts, **When** the next Key Card is to be revealed, **Then** the view zooms back out to the whole Region Card first.
4. **Given** reduced motion is on, **When** an Encounter is chosen, **Then** the zoomed panel and the same information appear without zooming or sliding movement.

---

### User Story 4 - Feedback takes the card's place for a moment (Priority: P2)

The lower-left box used to carry more than tips: refusal reasons, the Fuse, Divert and Regroup steps, the setup prompt, the Play result count-up and verdict, the soak meter and the XP purse. That box was always temporary and is now gone. When the player needs one of these, it temporarily replaces the card on the left side, filling the column, so there is room to explain the outcome properly. Then the card comes back.

**Why this priority**: Removing the box must not take away information the player needs to play. Showing the feedback in the card's place also gives the Encounter's outcome room to be explained, not squeezed into a small box.

**Independent Test**: Trigger each kind of feedback (a refused Action Set, each step of Fuse, Divert and Regroup, a Play with its result, an Upgrade spending XP). Each appears in place of the card on the left, uses the column's space, and gives way to the card again afterwards. Nothing appears in a box under the stack.

**Acceptance Scenarios**:

1. **Given** the game refuses an Action Set, **When** the player tries to Play it, **Then** the reason appears in place of the card on the left, and the card returns once the player moves on.
2. **Given** a Fuse, Divert or Regroup in progress, **When** the player is mid-way, **Then** the current step's instruction is shown in place of the card until the action completes or is cancelled.
3. **Given** the player presses Play, **When** the result is tallied, **Then** the totals, the win/lose verdict and an explanation of the Encounter's outcome are shown in place of the card, with more room than the old box allowed.
4. **Given** the player has XP to spend, **When** they Upgrade, **Then** the XP available and the XP spent are shown in place of the card, as they are today.
5. **Given** any of this feedback has finished or been dismissed, **When** play continues, **Then** the left side shows the card again (the zoomed Encounter, or the whole Region Card between Encounters).

---

### User Story 5 - The Dragon Card in the Final Battle gets the same treatment (Priority: P3)

In the Final Battle the Dragon Card takes the Region Card's place on top of the stack. It is laid out like the physical Dragon Card, with the dragon's name and title in a title band, the row of stat badges, the MP Tiers down the left and the HP Tiers down the right, over the dragon's art. No card code is shown. The Final Journey zooms into its MP Tiers and the Final Enemy into its HP Tiers, as decided in 012.

**Why this priority**: It keeps the left side consistent through the end of the game. It is less central than the Region Card the player sees for most of the game.

**Independent Test**: Reach the Final Battle. The top card is laid out like the scanned Dragon Card for the chosen dragon, and each Final Battle stage zooms into the matching Tiers.

**Acceptance Scenarios**:

1. **Given** the Final Battle begins, **When** the Dragon Card takes the top of the stack, **Then** it shows the dragon's name, title, stat badges, MP Tiers and HP Tiers in the physical card's arrangement, with no card code.
2. **Given** the Final Journey or the Final Enemy, **When** the Hand has been drawn, **Then** the view zooms into the MP Tiers or the HP Tiers respectively, with all values used in play readable.

---

### Edge Cases

- **Deck nearly empty.** At fewer than five Mage Cards (the End of the Region trigger), the stack is thin but still reads as a stack beneath the Region Card. It never shows as empty while the Deck has cards.
- **An Encounter without an Ability, Peril or Hardship.** The panel shows no empty icon or placeholder in that place, as on the printed card.
- **An Enemy with more than one Armor value, or an Attack and Armor in different Ethers.** Each badge shows its own Ether colour, as printed.
- **Smallest supported window.** The whole Region Card (title, 2×2 Enemies, row of four Journeys) fits the left column. Stat values meet the game's minimum text size on the zoomed-in panel, where they are read.
- **Setup (choosing starting cards).** There is no Region Card yet, as in the rulebook's Setup. The left side still reads as the Deck, and setup's own prompt takes the left column in the card's place.
- **Undo within an Encounter.** The Key Card reveal and zoom are not replayed. The zoomed panel stays.
- **The game is lost or won mid-Encounter.** The left side's state at that moment does not hide or overlap the end-of-game screen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Region Card MUST be laid out like the physical Region Card: a title band with the Region name and "Region N", then the four Enemies in a 2×2 grid (1 and 2 above, 3 and 4 below), then the four Journeys in a single row of four (1 to 4, left to right).
- **FR-002**: Each Enemy panel MUST show the creature's art, a left-edge column of HP, Initiative, Attack and Armor badges (Attack and Armor in their Ether colours with their Ether marks), any Ability icon at the top right, the XP Reward in a star badge at the bottom right, and a small Encounter number marker that does not crowd the printed elements.
- **FR-003**: Each Journey panel MUST show a header strip with the MP badge (in its Ether colour) and the Time Penalty, the landscape art below, any Peril icon, the XP Reward in a star badge at the bottom, and a small Encounter number marker that does not crowd the printed elements.
- **FR-004**: The Region Card and the rest of the play screen MUST NOT show the card code (for example "DOE-R01", "DOE-R02").
- **FR-005**: The left column MUST contain only the stack of cards (the Region Card or Dragon Card on top of the Deck), or the feedback that temporarily takes the card's place (FR-011). The box below it that shows step tips MUST be removed.
- **FR-006**: The building tips ("Tap two cards to swap their Roles…", "Tap the bottom of the Boost card…", "…re-aim it.", "Hold a card to inspect it.") MUST no longer be shown.
- **FR-007**: The stack MUST read as physical cards, with visibly layered card edges beneath the top card. Its depth MUST track the number of cards remaining in the Deck for the current Region, and change whenever that number changes.
- **FR-008**: When an Encounter is chosen, the view MUST zoom into that Enemy or Journey panel on the Region Card. The zoomed view MUST keep the panel's printed layout (same badges, positions and art) enlarged to fill the left side, not swap to a separately styled face.
- **FR-009**: While zoomed in, every value used in play MUST be visible and correct: Enemy HP, Initiative, Attack, Armor and Ability; Journey MP, Time Penalty and Peril; and the Key Card's Hardship. That includes what an Ability, Peril or Hardship does, not only its icon.
- **FR-010**: The view MUST zoom back out to the whole Region Card before the next Key Card is revealed (after Cleanup or a Divert), and at the End of a Region before the card turns.
- **FR-011**: Feedback the removed box used to carry, other than the building tips, MUST still reach the player: refusal reasons, Fuse, Divert and Regroup step instructions, setup's prompt, the Play result tally and verdict, the soak meter and the XP purse during Upgrade. It MUST be shown by temporarily taking the place of the card on the left side, using the whole column, with room to explain an outcome in full. The card (zoomed Encounter or whole Region Card) MUST return once the feedback is done or dismissed.
- **FR-012**: In the Final Battle, the Dragon Card on top of the stack MUST be laid out like the physical Dragon Card (title band, stat badge row, MP Tiers left, HP Tiers right, over the dragon art) without a card code, and MUST be zoomed into as decided in 012.
- **FR-013**: The behaviour established in 012 MUST be kept: the Hand drawn from under the top card, the Key Card lift showing its Encounter number and Hardship, no replay on undo, reduced-motion equivalents, and the header's Deck, Discard and Trash counts.
- **FR-014**: At every supported window size the stack MUST fit the left column, with the whole Region Card legible, and MUST NOT overlap the header, the Hand or the action row.
- **FR-015**: The Region Card MUST use the game's existing creature and landscape art for each Encounter and the game's existing Ether colours and icons. No new painted art is required.

### Key Entities

- **Region Card**: one side of a double-sided card for one Region. It has a name and number, four Enemies (2×2 grid) and four Journeys (row of four), each with its stats and XP Reward. Its position gives its Encounter number 1–4. It lies on top of the Deck during a Region.
- **Enemy panel**: one Enemy on the Region Card, with art, HP, Initiative, Attack (with Ether), Armor (one or more, with Ether), an optional Ability, an XP Reward and an Encounter number (from its position).
- **Journey panel**: one Journey on the Region Card, with art, MP (with Ether), Time Penalty, an optional Peril, an XP Reward and an Encounter number (from its position).
- **Deck stack**: the Mage Cards remaining in the Deck for the current Region, beneath the top card. Its depth reflects the Deck count.
- **Key Card**: the top Mage Card under the Region Card. Its Encounter number picks a panel, and its Hardship modifies that Encounter.
- **Dragon Card**: the top card in the Final Battle, with name, title, stat badges, MP Tiers and HP Tiers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Put side by side with the official scan of each Region Card, every Enemy and Journey is in the same position with the same values, Ether colours, icons and XP Rewards (zero mismatches across all four Regions).
- **SC-002**: No card code is shown on the play screen at any point in a full playthrough.
- **SC-003**: At every step of a full playthrough, the left column holds only the stack of cards or, for the moment it is needed, the feedback shown in the card's place. The stack's depth agrees with the Deck count (zero mismatches).
- **SC-004**: A player familiar with the physical game recognises the left side as "the Region Card on the Deck" on first sight, and can identify the zoomed Encounter as a panel from that card.
- **SC-005**: No play information is lost. Every value, refusal, step instruction, Play result and XP figure shown today is still available to the player in the same game state.
- **SC-006**: At every supported window size, the whole Region Card fits the left column, and the stack overlaps no other part of the screen. Every value is at or above the game's minimum text size once zoomed in. The whole card is a picture of the printed card, seen while the Deck zooms, and its small print is read by zooming in.

## Assumptions

- "The regions laid out below those" means the four **Journeys**, the landscape panels in a row beneath the Enemies on the printed card.
- The star badge on each printed panel is the XP Reward (checked against the Region data). The Encounter number marker is the game's one addition to the printed panel.
- The printed card's arrangement, including which Encounter number sits in which grid position, is taken from the official scan in `reference/sheets-official/o5.png`.
- The stack is a visual approximation of the Deck: it reads as "more" or "fewer" cards and tracks the count. It does not draw every card's edge individually.
- On the printed card, Abilities, Perils and Hardships are icons. In the game, their full meaning remains readable while zoomed in (as it is today), without breaking the panel's printed look.
- The removed box's non-tip feedback is kept and shown temporarily in the card's place (FR-011). Only the building tips are dropped.
- How the feedback and the card hand over (fade, flip, slide) follows the game's existing motion conventions and reduced-motion setting.
- The header's Region title and Deck, Discard and Trash counts are unchanged.
- No change to rules, scoring or the game engine's behaviour is intended.
- This work builds on, and replaces where they conflict, the Region Card and left-column layout decisions of `specs/012-deck-region-card`. The motion and reveal decisions of 012 stand.
