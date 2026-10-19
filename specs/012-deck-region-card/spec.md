# Feature Specification: The Deck and Region Card on the Playfield

**Feature Branch**: `012-deck-region-card`

**Created**: 2026-10-18

**Status**: Draft

**Input**: User description: "refactor the left side of the play scene so that the side looks like a deck of cards - from which the hand on the right is drawn from each round. look at the rulebook for how the physical card game is played - the region card is laid on top and you draw your hand from below that card - learning which enemy/journey you are to face based on what is the card below the region card. we currently don't have a region card so what that looks like would need to be figured out - maybe we show a region card like what the card game does and based on the card below the region card after the hand has been drawn we show the number of the top card like the physical game and then zoom in on that quadrant so that it matches the current enemy/journey layout. we can do something else as well - show the top card which turns into the encounter or something."

## Background: how the physical game does it

From the rulebook (Setup, Challenge Phase, Cleanup Phase, End of the Region, The Final Battle):

- The **Deck** is held in the left hand. The **Region Card** sits on top of it, turned to the current Region. Discarded Mage Cards go behind the inactive Region Card at the back; Trashed cards are stored behind the Dragon Card.
- The **Hand** is drawn from the Deck *below* the Region Card, into the right hand, until it holds four cards.
- The **Key Card** is the topmost Mage Card of the Deck, directly under the Region Card. Its **Encounter icon and number** (Enemy or Journey, 1–4) say which of the Region Card's eight Encounters you face, and its **Hardship** icon (if any) modifies it.
- **Diverting** discards the Key Card (and a card from the Hand); the next card down becomes the Key Card.
- At the **End of the Region** (fewer than five Mage Cards left), the Deck is reshuffled, a new Hand is drawn and the Region Card is turned to the next Region.
- In the **Final Battle**, the **Dragon Card** takes the Region Card's place on top of the Deck.

Today the left side of the play screen shows the current Encounter (or dragon) as a standalone face with the math box under it; the Deck exists only as a count in the header. This feature makes the left side read as that held Deck.

## Clarifications

### Session 2026-10-18

- Q: How should the chosen Region Card slot become the Encounter face the player plays against? → A: The Region Card stays on top of the Deck throughout. The Hand's cards are pulled from under it; once they settle, the Key Card beneath the Region Card lifts just far enough to show its Encounter number and any Hardship, then slides back down. The view then zooms into that Encounter's slot on the Region Card until it fills the Encounter area in today's Enemy/Journey layout, and that Encounter's creature starts its animation at that moment (animating every slot's creature all the time is acceptable if simpler).
- Q: In the Final Battle, should the Dragon Card on top of the Deck be zoomed into the same way: into its MP Tiers for the Final Journey, then its HP Tiers for the Final Enemy? → A: Yes. The Dragon Card sits on top; after the Hand is drawn the view zooms into its MP Tiers for the Final Journey, then zooms out and back in on its HP Tiers for the Final Enemy. There is no Key Card lift in the Final Battle.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The left side is the Deck, with the Region Card on top (Priority: P1)

A player looking at the play screen sees, on the left, a stack of Mage Cards with the current Region Card lying on top, the way the physical deck sits in the left hand. The stack visibly holds about as many cards as the Deck has left, and the Region Card shows the current Region's name, number and its four Enemies and four Journeys.

**Why this priority**: This is the core of the request: the left side should *look like the deck the Hand comes from*. Every other story builds on the Deck and Region Card being there.

**Independent Test**: Start a game and reach the first Encounter of Region 1. The left side shows a card stack topped by the Jade Mountains Region Card (Region 1) with all eight Encounters on it; the stack's thickness shrinks as the Deck count in the header falls.

**Acceptance Scenarios**:

1. **Given** a new game at the first Encounter of Region 1, **When** the play screen shows, **Then** the left side shows a Deck of Mage Cards with the Region 1 Region Card on top, naming the Region and showing its four Enemies and four Journeys with their numbers 1–4.
2. **Given** the Deck has 11 cards left, **When** a Cleanup draw takes 3 more, **Then** the stack visibly thins, and its depth always agrees with the Deck count shown in the header.
3. **Given** any step of a Region Encounter, **When** the player looks at the left side, **Then** it is recognisable as cards held together: stacked edges beneath the whole Region Card when zoomed out, or beneath the zoomed Encounter face when zoomed in. It never reads as a flat panel.

---

### User Story 2 - The Key Card under the Region Card picks the Encounter (Priority: P1)

After the Hand's cards have been pulled from under the Region Card and have settled in the Hand, the Key Card — the Mage Card directly under the Region Card — lifts up from beneath it just far enough to show its Encounter icon and number (and any Hardship), then slides back down under the Region Card. The view then zooms into the matching Enemy or Journey on the Region Card, which stays on top of the Deck, until that slot fills the Encounter area in the same layout as today's Enemy/Journey face; its creature starts animating at that moment.

**Why this priority**: This is the rulebook's "Scout Ahead" step made visible. It teaches the physical game and explains *why* this Encounter is the one faced, which the current screen does not show.

**Independent Test**: Reach any Region Encounter. After the Hand settles, the Key Card peeks out from under the Region Card showing its Encounter icon and number (e.g. "Enemy 2") and its Hardship, slides back, and the view zooms into the second Enemy on the Region Card until it is the full Encounter face with the same stats, its creature now moving.

**Acceptance Scenarios**:

1. **Given** a new Encounter whose Key Card shows Enemy 2 with no Hardship, **When** the Hand's cards have settled, **Then** the Key Card lifts from under the Region Card far enough to show "Enemy 2" (and no more of the card), slides back down, and the view zooms into Enemy 2 on the Region Card until it shows Enemy 2's HP, Initiative, Attack, Armor and any Ability in today's Enemy layout.
2. **Given** a Key Card that shows Journey 3 with the Storm Hardship, **When** the Key Card lifts, **Then** the Storm Hardship shows alongside its Encounter number, and after the zoom the Journey 3 Encounter face carries the Storm Hardship.
3. **Given** the zoom has settled, **When** the player looks at the Encounter, **Then** its creature is animating, the Region Card is still the card on top of the Deck, and the player can still open the Key Card in full (e.g. by pressing the face, as today).
4. **Given** reduced motion is on, **When** a new Encounter begins, **Then** the Key Card's Encounter number and Hardship are still shown briefly and the zoomed Encounter face then appears, without the lifting, sliding or zooming movement and without creature animation.

---

### User Story 3 - The Hand is drawn from the Deck (Priority: P2)

When cards enter the Hand — the first Hand of a Region, the Cleanup draw back up to four, the Final Journey's seven and the Final Enemy's remainder — they visibly come from the Deck on the left, from under the Region Card, and travel into the Hand on the right. Discards and Trashes visibly leave toward the back of the Deck.

**Why this priority**: It ties the two sides of the screen together and makes the Deck feel like the source of time and cards, but the screen is still understandable without the motion.

**Independent Test**: Finish an Encounter. The Action Set leaves for the discard pile, and the drawn replacement cards fly from beneath the Region Card into the Hand; the Deck stack thins by the number drawn.

**Acceptance Scenarios**:

1. **Given** the Cleanup Phase, **When** two cards are drawn, **Then** two cards leave the Deck from under the Region Card and arrive in the Hand, and the stack thins by two.
2. **Given** a Divert, **When** the Key Card is discarded, **Then** the view zooms back out to the whole Region Card, the Key Card leaves from under it toward the back of the Deck, and the next card lifts, slides back and is zoomed into as in Story 2.
3. **Given** reduced motion is on, **When** cards are drawn or discarded, **Then** the Hand and the stack update without travelling cards.

---

### User Story 4 - Region changes and the Final Battle (Priority: P3)

At the End of a Region, the Deck is reshuffled and the Region Card turns to the next Region. In the Final Battle, the Dragon Card takes the Region Card's place on top of the Deck, and the Final Journey and Final Enemy faces are reached by zooming into it, as Region Encounters are reached by zooming into the Region Card, but with no Key Card lift, since no card below it chooses anything.

**Why this priority**: Completes the metaphor across the whole game, but these moments occur only four times a game.

**Independent Test**: Play through the end of Region 1. The Region Card turns from Region 1 to Region 2, the stack refills, and a fresh Hand is drawn. Reach the Final Battle; the chosen Dragon Card now tops the Deck.

**Acceptance Scenarios**:

1. **Given** the End of Region 1, **When** Region 2 begins, **Then** the Region Card shown is Region 2 (the same physical card turned for Regions 1–2, the other card for Regions 3–4), the stack shows the reshuffled Deck, and the new Hand is drawn from it.
2. **Given** the Final Battle begins, **When** the Final Journey is shown, **Then** the Dragon Card sits on top of the Deck in place of the Region Card, the seven-card Hand is pulled from under it, no Key Card lifts, and the view zooms into the Dragon Card's MP Tiers until they fill the Encounter area as the Final Journey face.
3. **Given** the Final Enemy, **When** all remaining cards are drawn, **Then** the view first zooms back out to the whole Dragon Card, the remaining cards are pulled from under it into the Hand, the Deck under the Dragon Card is empty, and the view zooms into the Dragon Card's HP Tiers as the Final Enemy face.

---

### Edge Cases

- **Divert twice in a row**: each Divert removes a Key Card and reveals the next; the lift, slide-back and zoom in Story 2 repeat each time, and the stack thins by one per Divert (plus nothing for the Hand card, which leaves from the Hand).
- **Between Encounters**: at the Cleanup Phase the view zooms back out to the whole Region Card before the Action Set is discarded and new cards are pulled from under it, so every draw and Key Card lift is seen against the whole Region Card.
- **Same slot twice in a row**: if the next Key Card names the same Encounter, the full sequence (zoom out, draw, lift, slide back, zoom in) still plays, so the player sees the Key Card that chose it.
- **Deck nearly empty**: at five cards (four to draw plus one Key Card) the stack still reads as a small stack, never as nothing; the End of the Region is reached before the stack can look empty under a Region Card.
- **Before the first Encounter (choosing starting cards)**: there is no Region Card on top yet; the left side shows the prepared Deck and the dragon being hunted, and the Region Card is placed on top as the first Encounter begins (rulebook Setup step 4).
- **Undo / going back within an Encounter**: undoing role assignments must not replay the Key Card reveal; the reveal happens once per Encounter (and again after each Divert).
- **Inspecting the Encounter mid-turn**: hovering or pressing the face must still open the current details and the Key Card as today, not the whole Region Card.
- **Small windows and phone widths**: the Region Card's eight Encounters may be too small to read at the Deck's resting size; it is enough that they read as a Region Card and that the singled-out slot becomes readable as it enlarges.
- **The Region Card's other orientation**: each physical Region Card carries two Regions; only the current Region's side is readable, the other side is not shown or is shown upside down and dimmed, as on the physical card.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The left side of the play screen MUST present the Deck as a stack of Mage Cards whose visible depth reflects the number of cards remaining in the Deck.
- **FR-002**: Throughout a Region, a Region Card for the current Region MUST be the top card of the Deck. Whenever the view is zoomed out (as each Encounter's Hand is drawn and its Key Card revealed, and between Encounters), the whole Region Card MUST show its Region's name and number and its four Enemies and four Journeys, each with its Encounter number (1–4) and key stats, in an arrangement modelled on the printed Region Card. While zoomed in, the Encounter face shows that Region Card's chosen slot, with the Deck's edges still visible beneath it.
- **FR-003**: The two Region Cards MUST pair Regions as the physical cards do (Regions 1 and 2 on one card, Regions 3 and 4 on the other), with only the current Region readable.
- **FR-004**: At the start of every Region Encounter (including after each Divert), once the Hand's cards have settled, the Key Card MUST lift from beneath the Region Card just far enough to show its Encounter icon and number and its Hardship, if any, and then slide back down under the Region Card. The Region Card MUST stay on top of the Deck throughout.
- **FR-005**: After the Key Card slides back, the view MUST zoom into the Region Card slot matching the Key Card's Encounter until that slot fills the Encounter area in today's Enemy/Journey layout; the zoomed slot is the Encounter face the player plays against.
- **FR-005a**: The zoomed Encounter's creature MUST begin animating when the zoom settles. Animating every slot's creature on the Region Card continuously is an acceptable alternative.
- **FR-005b**: Before the Hand is drawn for the next Encounter (Cleanup) and before a Divert's Key Card leaves, the view MUST zoom back out to the whole Region Card.
- **FR-006**: Once settled, the Encounter face MUST show the same information and stats it shows today (Enemy HP, Initiative, Attack, Armor, Ability; Journey MP, Time Penalty, Peril; Hardship), so play is unchanged.
- **FR-007**: The math box (preview) MUST remain available on the left side alongside the Deck and Encounter face, with no loss of the information it shows today.
- **FR-008**: Cards entering the Hand MUST be shown coming from the Deck under the Region Card (or Dragon Card); cards discarded or trashed MUST be shown leaving toward the back of the Deck.
- **FR-009**: At the End of a Region, the Region Card MUST change to the next Region and the stack MUST refill to the reshuffled Deck before the new Hand is drawn.
- **FR-010**: In the Final Battle, the Dragon Card MUST take the Region Card's place on top of the Deck, and, after each Hand is drawn, the view MUST zoom into its MP Tiers for the Final Journey and, after zooming back out, into its HP Tiers for the Final Enemy. No Key Card lift happens in the Final Battle. A Regroup MUST zoom back out to the whole Dragon Card before the Hand returns to the back of the Deck and the new seven are drawn.
- **FR-011**: With reduced motion on, every reveal and draw MUST still show the same information (the Key Card's Encounter number and Hardship, the resulting zoomed face, updated Hand and stack) without lifting, sliding, zooming or travelling movement.
- **FR-012**: The Key Card reveal MUST happen once per Key Card; undoing choices within an Encounter MUST NOT replay it.
- **FR-013**: The player MUST still be able to inspect the current Encounter and its Key Card in full, as they can today.
- **FR-014**: The new left side MUST fit every supported window size and resolution without overlapping the Hand, the header or the action row.

### Key Entities

- **Deck**: the ordered Mage Cards not in the Hand, discard or trash; its top card is the Key Card. Shown as a stack whose depth tracks its count.
- **Region Card**: one of two double-sided cards; each side is a Region (name, number, four Enemies, four Journeys, each with stats and an Encounter number). Lies on top of the Deck during a Region.
- **Key Card**: the Mage Card directly beneath the Region Card. Its Encounter icon and number select one of the Region Card's eight Encounters; its Hardship modifies it.
- **Encounter slot**: one of the eight Enemy/Journey entries on a Region Card, with its creature art, stats and number; zoomed into, it is the Encounter face for this Encounter.
- **Dragon Card**: replaces the Region Card on top of the Deck in the Final Battle; zoomed into its MP Tiers, it is the Final Journey face; zoomed into its HP Tiers, the Final Enemy face.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a playtest, a player shown any Encounter can point to the Key Card mark and the Region Card slot that produced it, in at least 9 of 10 Encounters, without consulting the rulebook.
- **SC-002**: A player who has read the physical rulebook's Setup and Challenge Phase pages recognises the left side as "the Deck with the Region Card on top" on first sight.
- **SC-003**: From the Hand settling to the zoomed Encounter face settling (lift, slide back, zoom) takes no more than 2 seconds and can be skipped or sped past by the player's next input, so a full game is not noticeably longer than today.
- **SC-004**: The stack's depth matches the Deck count at every step of a full playthrough (zero mismatches).
- **SC-005**: Every value on the settled Encounter face matches what today's Encounter face shows for the same game state (no regression in play information).
- **SC-006**: At every supported window size, no part of the Deck, Region Card, Encounter face or math box overlaps another region of the screen.

## Assumptions

- The Region Card face is drawn by the game from the existing Region data (names, numbers, Enemies, Journeys) in the game's etched-stone style, using the creature and landscape art already painted for each Encounter; it does not need new painted art.
- The Encounter face's settled layout stays as it is today; it is now reached by zooming into the Region Card, which changes where it comes from and what surrounds it, not its contents.
- The Deck's stack is a visual approximation: it needs to read as "more" or "fewer" cards and agree with the count, not show every card's edge individually.
- The header's Deck/Discard/Trash counts remain; the stack complements them rather than replacing them.
- The pre-game step (choosing starting cards) keeps its current purpose; it gains the Deck look but has no Region Card until the first Encounter, as in the rulebook's Setup.
- Motion follows the game's existing reduced-motion setting and animation timing conventions.
- No change to rules, scoring or the game engine's behaviour is intended.
