# Feature Specification: Legible Hand Cards

**Feature Branch**: `010-legible-hand-cards`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "from the 009 spec of adjusting the layout, card titles at this size are not able to be read. how can we reclaim space needed for cards to be legible on mobile? could we move the divert button to being near the enemy, move fuse and the play button, then have the room to grow to replace that space? on mobile we could move the header up, but maybe we are already as high as we can be." Follow-up: "the top row doesn't need to exist as-is. we don't need to show the values for the element, spell, or boost - those badges in the top row would become labels for the card slots instead - merging into a single cell. the values are already shown below the enemies on the left. the one thing to think about would be how to specify where boost is being applied. divert should move near the enemy anyway."

## Background

Feature 009 laid out the card side of the play board in four bands, from top to bottom: a role strip, the row of places (Reserve, Element, Spell, Boost), a floating row of unplaced cards, and an action row (Fuse, Divert, Play). Cards keep one size while a set is built, so the places row and the floating row must both fit at full card height. Cards are therefore limited by height, while a wide band of empty space sits beside them.

On a wide phone (the "phone-tall" shape the game is checked at) this leaves Hand cards about 138 × 194 design units, and their names are drawn at about 11 units. That is too small to read on the device. The header already sits at the top of the safe area, so moving it gains almost nothing.

This feature puts the Hand in a single row. Each position in the row is a role, labelled directly above its card, and the dealt cards fill the positions in the order they were drawn. The player rearranges the Hand by swapping cards. With one row instead of two, cards are limited by the card side's width instead of its height, and on the phone-tall shape they grow to about 220 × 308.

The role strip's values are dropped. The preview panel under the Encounter face already shows Attack, Initiative and Move with their values.

## Clarifications

### Session 2026-10-17

- Q: Does the role strip need to stay as its own row? → A: No. Its role badges become labels on the card positions, merged into one cell with each. The labels no longer show the Spell, Element or Boost values, since the preview panel on the left shows them.
- Q: Where does Divert go? → A: It stays in the action row under the cards. The row shares out its width by how many buttons it holds: with up to three, the secondary actions take a quarter each and Play the right half; a fourth button makes all four a quarter; a fifth makes all five a fifth. Play is always the rightmost button. (This replaces an earlier answer that put Divert by the Encounter face; the left column has no height to spare.)
- Q: With all cards in one row, how does each card get its role? → A: Position is role (Option A). The row has labelled positions (Reserve, Element, Spell, Boost). Dealt cards fill them in draw order, and the player rearranges by swapping two cards, by tap-then-tap or by drag. The preview shows the current arrangement from the moment the Hand is dealt. This replaces 009's separate places and floating row, and 009's rule that dealt cards wait unplaced.
- Q: Against an Enemy, how does the player choose whether the Boost adds to Attack or to Initiative? → A: By tapping the Attack or Initiative row in the preview panel (Option A). The Boost's icon sits on the row it is aimed at, and tapping the other row moves it there.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Card names readable on a phone (Priority: P1)

A player on a phone looks at the Hand while building an Action Set and can read every card's name and numbers without zooming or holding a card to inspect it.

**Why this priority**: This is the problem the request is about. If the names cannot be read, the player cannot choose cards from the board.

**Independent Test**: Open a Region Encounter at the phone-tall shape and measure the Hand cards and their name text against the 009 layout at the same shape.

**Acceptance Scenarios**:

1. **Given** a four-card Hand in a Region Encounter at the phone-tall shape, **When** the board appears, **Then** every Hand card is at least 50% taller than in the 009 layout at the same shape, and its name is drawn at least 17 design units tall.
2. **Given** any arrangement of the Hand, **When** the player swaps cards, **Then** no card changes size.
3. **Given** the desktop 1280 × 720 baseline, **When** the board appears, **Then** the Hand cards are no smaller than in the 009 layout.

---

### User Story 2 - One row where position is role (Priority: P1)

The Hand sits in a single row of positions. Each position carries its role label (Reserve, Element, Spell, Boost from left to right) in a short header joined to the card under it. When a Hand is dealt, its cards fill the positions in the order they were drawn, so every card has a role at once and the preview panel shows that arrangement's outcome. The player changes roles by swapping cards: tap a card, then tap another card or position, or drag one card onto another. The label shows the position's state, not the card's value; the player reads values in the preview panel.

**Why this priority**: One row is what frees the height the cards need, and swapping is how the player builds an Action Set in this layout.

**Independent Test**: Deal a four-card Hand and check that the cards sit in one row in draw order, each under a label, and that the preview shows an outcome. Swap the Element and the Boost by tapping one and then the other, then again by dragging, and check that the preview's values follow.

**Acceptance Scenarios**:

1. **Given** a freshly dealt four-card Hand, **When** the board appears, **Then** the cards sit in one row in the order drawn, under the labels Reserve, Element, Spell and Boost from left to right, and the preview panel shows the outcome of that arrangement.
2. **Given** a card tapped (picked up), **When** the player taps another card, **Then** the two cards swap positions and roles, and the preview updates.
3. **Given** a card picked up, **When** the player taps it again or taps empty board, **Then** it is put down where it was and nothing changes.
4. **Given** a drag in progress, **When** the player releases the card over another card or position, **Then** they swap. **When** released anywhere else, **Then** nothing changes and the card glides back.
5. **Given** a player using only taps or a keyboard, **When** they want any arrangement, **Then** they can reach it without dragging.
6. **Given** the Hand on screen, **When** the player looks at it, **Then** no separate role strip and no separate area of unplaced cards is drawn.

---

### User Story 3 - One action row that makes room for more buttons (Priority: P2)

The action row stays under the cards and holds every action: Fuse, Divert (or Regroup), Give up Reserve when it applies, and Play. Play is always the rightmost button. With up to two other actions, Play takes the right half and each other action a quarter. When a third action joins (Give up Reserve against a Ranged Enemy), all four buttons take a quarter each. A fifth button would make all five a fifth.

**Why this priority**: The role strip's Give up Reserve switch needs a new home, and the row has to hold it without crowding the cards.

**Independent Test**: Open a Region Encounter against a non-Ranged Enemy and check the row reads Fuse ¼ · Divert ¼ · Play ½. Then open one against a Ranged Enemy and check it reads Fuse ¼ · Divert ¼ · Give up Reserve ¼ · Play ¼.

**Acceptance Scenarios**:

1. **Given** a Region Encounter with Fuse and Divert on offer, **When** the board appears, **Then** the row reads Fuse (¼), Divert (¼), Play (½).
2. **Given** a Ranged Enemy with a card in the Reserve, **When** the board appears, **Then** the row reads Fuse, Divert, Give up Reserve, Play, each a quarter, with Play rightmost.
3. **Given** a Divert under way, **When** the player looks at Divert's button, **Then** it has become Cancel in the same cell, as today.
4. **Given** an action that is not on offer in this phase, **When** the row is drawn, **Then** its cell is left blank while the row holds three cells or fewer, so Play keeps the right half.

---

### User Story 4 - Choosing where the Boost goes (Priority: P2)

Against an Enemy, the player decides whether the Boost card adds to Attack or to Initiative. The role strip's toggle for this goes away with the strip. Instead the player taps the Attack or Initiative row in the preview panel, the place where those values are read.

**Why this priority**: The game needs this choice, but it applies only against Enemies and only to one card.

**Independent Test**: Against an Enemy, tap the preview panel's Initiative row and then its Attack row. After each tap, check that the Boost's icon sits on the tapped row and that the Attack and Initiative values change to match.

**Acceptance Scenarios**:

1. **Given** an Enemy Encounter with a card in the Boost position and the Boost not yet aimed, **When** the player looks at the preview panel, **Then** the Attack and Initiative rows both invite the Boost, and Play waits until it is aimed, as today.
2. **Given** that state, **When** the player taps the Initiative row, **Then** the Boost's icon sits on the Initiative row and the Initiative value includes the Boost.
3. **Given** a Boost aimed at Initiative, **When** the player taps the Attack row, **Then** the icon and the Boost's value move to Attack, with no swap needed.
4. **Given** a Journey (no Initiative), **When** a card is in the Boost position, **Then** no target choice is offered.
5. **Given** a keyboard-only or tap-only player, **When** they want to change the Boost's target, **Then** they can do it without dragging.

---

### User Story 5 - The Final Battle keeps the same scheme (Priority: P3)

In the Final Journey and the Final Enemy, the Hand follows the same scheme: labelled positions in rulebook order (Reserve, then Set 1's Element, Spell and Boost, then Set 2's), filled in draw order, rearranged by swapping. The labels show where Set 1 ends and Set 2 begins, and Regroup takes Divert's cell in the action row.

**Why this priority**: The Final Battle is the last stage of each game. It only needs to follow the new scheme.

**Independent Test**: Reach the Final Journey with seven cards and the Final Enemy with a full Hand, and check that every card is fully visible, each position is labelled, and the two sets are told apart.

**Acceptance Scenarios**:

1. **Given** the Final Journey, **When** the board appears, **Then** the positions read Reserve, then Set 1's Element, Spell and Boost, then Set 2's Element, Spell and Boost, each with its own label, and a divider separates the two sets.
2. **Given** the Final Journey, **When** Regroup is available, **Then** it takes Divert's cell in the action row.
3. **Given** the Final Journey's seven cards at the 1280 × 720 baseline, **When** the board appears, **Then** they sit in two rows, Reserve and Set 1 above and Set 2 below, because two rows give larger cards than one.
4. **Given** the Final Enemy with more cards than role positions, **When** the board appears, **Then** the extra cards follow the role positions as unlabelled cards, the row wraps onto a second row if it must, and every card is fully visible without scrolling and no smaller than in the 009 layout.
5. **Given** the Final Enemy, **When** the player swaps an unlabelled card with a card in a role position, **Then** the two trade places and the unlabelled card takes that role.

---

### Edge Cases

- **Play is ready at once**: because every card has a role from the deal, Play is enabled as soon as the Hand is dealt, whenever the arrangement is valid.
- **Fewer cards than positions** (after a Divert, or a Fuse): dealt cards fill the Spell first, then the Element, then the Boost, then the Reserve, so a short Hand is always valid when dealt. Positions with no card show their label as empty, and a card can be moved onto an empty position. With fewer than three cards, the Spell must hold a card before Play is enabled, as today.
- **Fused cards**: a fused pair takes one position, and the tucked card is never shown as the Reserve, as today. In a four-card Hand, fusing leaves no Reserve (the rules count the fused pair as one card), so the Reserve card moves into the role the tucked card left. Unfusing puts the tucked card back in the first empty position (Spell, Element, Boost, then the Reserve).
- **Dragging a fused pair**: moving the top card of a Fuse moves its tucked partner with it.
- **Give up Reserve against a Ranged enemy**: the role strip held this toggle. It joins the action row as a fourth button, so every cell becomes a quarter and Play narrows to a quarter at the right end. It leaves the row (and Play widens back to half) if the Hand drops to three cards and no Reserve is left. While it is on, the Reserve label shows the card as given up.
- **Reserve's Boost on a Journey**: the role strip showed the Reserve's Boost when it counted toward Move. The preview panel's Move value now carries it as a Reserve term, and the Reserve card itself keeps its existing Boost mark while that Boost counts. The label adds nothing.
- **Two Boosts in the Final Enemy**: the preview panel has one Attack row and one Initiative row for both sets. A row tap aims the first Boost not yet aimed; to re-aim one already aimed, the player picks up that Boost card and taps the row (FR-018c).
- **Instruction text in the preview panel**: if the panel cannot fit the Attack and Initiative rows at tap size, the instruction text ("Build your Action Set. Tap a card…") shortens or moves to the help overlay first.
- **Upgrade and penalty recap**: the strip marked the set just played (played, kept, discarded). These marks move onto the position labels.
- **Setup and Soak**: no role labels are shown. The cards use the card side, and Play keeps the right half of the action row.
- **Undo Upgrade**: in the Upgrade phase it takes Fuse's cell.
- **Every checked window shape**: at every window shape in the game's check list, nothing overlaps and no tap target falls below the minimum size.

## Requirements *(mandatory)*

### Functional Requirements

**One row, position is role**

- **FR-001**: The Hand MUST sit in one row of positions. Only in the Final Battle MAY it wrap onto a second (or third) row, and only when that gives larger cards; a wrap SHOULD fall where Set 1 ends. There MUST be no separate role strip and no separate area for unplaced cards.
- **FR-002**: In the Regions the positions MUST read, left to right, Reserve, Element, Spell, Boost (rulebook p. 15). A card's position MUST be its role.
- **FR-003**: When a Hand is dealt, its cards MUST fill the positions in the order drawn, so every card has a role at once. When there are fewer cards than positions, they MUST fill the Spell first, then the Element, the Boost and the Reserve.
- **FR-004**: The preview panel MUST show the outcome of the current arrangement from the moment the Hand is dealt, and MUST update after every swap.
- **FR-005**: The player MUST be able to swap any two cards (and so their roles) by tapping one and then the other, by dragging one onto the other, and by keyboard. Moving a card onto an empty position moves it there. Tapping the picked-up card again, or empty board, MUST put it down unchanged. Releasing a drag away from any card or position MUST change nothing.
- **FR-006**: Cards MUST glide between positions rather than jump, and MUST move without animation when reduced motion is on.

**Labels**

- **FR-007**: Each position MUST carry its role label in a header joined to its card, so label and card read as one cell.
- **FR-008**: A label MUST show the role's icon and name and the position's state (empty, inactive, target for the held card, given up, and the recap marks played, kept and discarded). It MUST NOT show the card's value.
- **FR-009**: A label MUST be tall enough for the game's minimum text size and no taller than it needs to be. Tapping or dropping on a label MUST act as tapping or dropping on its position.
- **FR-010**: The preview panel under the Encounter face MUST stay where the player reads the Attack, Initiative and Move values, including the Reserve's Boost when it counts toward Move.
- **FR-011**: In the Final Battle the labels MUST mark where Set 1 ends and Set 2 begins. Final Enemy cards beyond the role positions MUST carry no role label.

**Card size**

- **FR-012**: Hand cards MUST take the largest size at which the whole row (and its labels) fits the card side, the same for every card, and MUST NOT change size while cards are swapped.
- **FR-013**: At every checked window shape, Hand cards MUST be no smaller than in the 009 layout at the same shape.

**Actions**

- **FR-014**: The action row MUST stay under the cards and hold, from the left: Fuse (or Undo Upgrade in the Upgrade phase), Divert (or Regroup in the Final Journey), Give up Reserve when it applies, then Play, always rightmost.
- **FR-015**: The row's width MUST be shared by the number of cells: with three cells or fewer, the two secondary cells take a quarter each and Play the right half, and a secondary action not on offer leaves its cell blank; with four, every cell takes a quarter; with five, every cell takes a fifth. Give up Reserve MUST appear only against a Ranged Enemy while the Reserve holds a card.
- **FR-016**: An action under way (Fuse, Divert, Regroup) MUST turn into its own Cancel in the same spot, as today.
- **FR-017**: Every action button MUST be at least the minimum tap-target size on its shorter side.

**Boost target**

- **FR-018**: Against an Enemy, the preview panel's Attack and Initiative rows MUST each be a tap target that aims the Boost at that value. The Boost's icon MUST sit on the row it is aimed at, and that row's value MUST include the Boost. Tapping the other row MUST move the Boost there without swapping cards.
- **FR-018a**: Each of those rows MUST be at least the minimum tap-target size on its shorter side. Instruction text MUST NOT take the height the rows need.
- **FR-018c**: When a Boost card is picked up, tapping a row aims that card's Boost. When none is, a tap aims the first Boost not yet aimed (Set 1, then Set 2); in a Region, with one Boost, it re-aims that Boost. In the Final Enemy, re-aiming a Boost already aimed means picking up its card first; tapping a row with both aimed and no Boost card picked up says so.
- **FR-018b**: Until the Boost is aimed, both rows MUST invite it and Play MUST stay disabled, as today. A swap that brings a different card into the Boost position keeps the current aim.
- **FR-019**: The Boost target choice MUST be reachable by keyboard as well as by tap. On a Journey, no target choice is offered and the rows are not tap targets.

**Unchanged**

- **FR-020**: The game rules and outcomes MUST NOT change. The engine receives the same actions as before.

### Key Entities

- **Position**: one slot in the ordered row, with a role (Reserve, Element, Spell or Boost), an Action Set where that applies, a state, and at most one card (a fused pair counts as one). Final Enemy cards beyond the role positions sit in positions with no role.
- **Label**: the header joined to a position, naming its role and showing its state.
- **Boost target**: Attack, Initiative or not yet aimed, set against an Enemy from the preview panel's rows. It belongs to the Action Set's Boost position and stays when the card there changes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At the phone-tall shape, Hand cards in a Region Encounter are at least 50% taller than in the 009 layout (194 design units today).
- **SC-002**: At the phone-tall shape, in a Region Hand, every card name in the game, including the longest ("Motivated Flight", "Determined March"), is drawn at least 17 design units tall (about 11 today). In the Final Battle, names are no smaller than in the 009 layout.
- **SC-003**: A player on a phone can read the names of all four Hand cards without zooming or holding a card to inspect it.
- **SC-004**: At every checked window shape, every card and every label is fully visible, nothing overlaps, and no tap target is below the minimum size.
- **SC-005**: A player can swap the cards in any two roles in one drag, or in two taps without dragging.
- **SC-006**: In a Region, a player can aim the Boost at Attack or Initiative in one tap, and switch it in one more, without dragging. In the Final Enemy, each Boost is aimed in one tap and switched in two.
- **SC-007**: Play's right edge is the action row's right edge in every phase, and its width is ½, ¼ or ⅕ of the row (within 2%) for three, four or five cells.
- **SC-008**: Every existing rules test and recorded playthrough gives the same outcome as before.

## Assumptions

- The phone-tall shape (2532 × 1170 with side notches, a 1558 × 720 design view) is the reference phone, because it matches the screenshot that prompted this feature.
- The card face is not redesigned. Names grow because the cards grow.
- Showing an outcome as soon as the Hand is dealt is acceptable. The draw-order arrangement is a starting point the player can see and change, not a choice made for them, and every card is already visible.
- Removing the strip's values is safe because the preview panel already shows Attack, Initiative and Move, including the Reserve's Boost toward Move.
- The header stays where it is. It already sits at the top of the safe area, and its margin is worth only a few units.
- This feature replaces 009's role strip, its separate places and floating row, its "dealt cards wait unplaced" rule, and its fixed ¼ · ¼ · ½ action row. 009's rulebook order, tap/drag/keyboard interaction and Final Battle narrowing of the left side stay.
