# Feature Specification: Ordered Hand and Play-Board Layout

**Feature Branch**: `009-ordered-hand-layout`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "for the playing board - move fuse and divert into the same row as play, so these buttons take up the whole row on the right half of the screen: fuse and divert taking up 25% of the row each while play takes up 50% of the row. move the cards down to be above this row. then shift the spell, element, and boost cards to being above the cards - shorter than now. look at the official rules of the game. c:\dev\dragons-of-etchinstone\reference\rulebook.txt the order of the cards is supposed to matter. being said we need to allow adjusting the position of the cards in your hand so they follow what the rules indicate they need to follow. that means we need a reserve card slot as well."

## Background

The official rulebook ("Ordering Your Hand", p. 15) tells players to hold their Hand in a fixed order, from the leftmost card to the rightmost: **Reserve, Element, Spell, Boost**. The base game does not score on that order, but expansions do, and the order is how a physical player shows which card fills which Role. Today the play board leaves the Hand cards where they were dealt, so a card's Role is shown only by the role slots, and the board has no place for the Reserve.

Today the right side of the play board has the Hand on top. Under it is a band with the Spell, Element and Boost slots on the left and an action column on the right, with Fuse and Divert in one row and Play under them.

## Clarifications

### Session 2026-10-17

- Q: What is "the right half of the screen"? → A: The board has two sides. The left side is the Encounter (Enemy or Journey) face with the preview panel under it. The right side is everything about the cards: the role strip, the Hand and the action row. The action row spans the right side's full width.
- Q: When a new Hand is dealt and no card has a Role yet, should the cards already sit in the Reserve/Element/Spell/Boost places, or wait apart until placed? → A: They wait apart (Option C). Dealt cards float, unplaced, on the right side while the empty places and their role badges stay visible. The player taps a card and then taps the place it should go to. Cards never land in places on their own, because a random arrangement would show the outcome before the player has decided anything.
- Q: Where do the unplaced cards float, given the empty places need room too? → A: Option A. Empty places are thin outlines with their role badges, under the role strip. The floating cards sit in a row just below the places, above the action row. A placed card leaves the floating row and fills its place at full size, so as cards are placed the floating row empties and the places fill.
- Q: In the Final Battle, can the left side give up width so all the cards fit on screen at once? → A: Option A. In the Final Battle only, the left side (dragon face and preview) narrows to its minimum readable width and the card side widens. The places run in one row (Reserve, Set 1, Set 2), and the floating cards wrap onto a second row when they do not fit in one. No card is ever off screen or reached by scrolling.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hand laid out in rulebook order (Priority: P1)

While building an Action Set, the player arranges the Hand as the rulebook says to hold it: Reserve on the far left, then Element, Spell, and Boost. A dealt Hand starts with its cards floating, unplaced, on the right side and the four empty places visible, each with its role badge. The player taps a card to pick it up and then taps the place it belongs in. Each card's place in the Hand then shows its Role, and a labelled role strip directly above the places names each one: Reserve, Element, Spell, Boost.

**Why this priority**: This is the rules-fidelity change the request is about. The board should look like the rulebook and like the physical game, and the Reserve gets a visible home.

**Independent Test**: Start an Encounter with a four-card Hand. Confirm that no card is in a place and no outcome is shown. Then, by tapping a card and then a place, put a card in each of Element, Spell and Boost. Check that the cards read left to right as Reserve, Element, Spell, Boost, each under the matching label in the strip above.

**Acceptance Scenarios**:

1. **Given** a freshly dealt four-card Hand, **When** the board appears, **Then** the cards float unplaced on the right side, the four places show empty with their badges (Reserve, Element, Spell, Boost from left to right), and the preview shows no outcome yet.
2. **Given** an unplaced card, **When** the player taps it, **Then** it is marked as picked up and the places it can go to are highlighted. **When** the player then taps the Spell place, **Then** the card moves into the Spell place (third from the left) and the strip above it shows the Spell's value.
3. **Given** a card picked up, **When** the player taps the same card again or taps empty space, **Then** the card is put down where it was and nothing else changes.
4. **Given** Spell, Element and Boost are all filled and one card is left unplaced, **When** the player looks at the Hand, **Then** that card sits in the Reserve place on the far left, and the strip above it reads Reserve. The last card goes to the Reserve on its own because it has no other place to go.
5. **Given** a card already in a place, **When** the player taps it and then taps the unplaced area, **Then** it leaves that place and floats unplaced again, and the place is empty.

---

### User Story 2 - Rearrange the Hand by moving cards between places (Priority: P1)

The player can change the order of the Hand at any time before Play. They tap a card and then another place, or drag the card onto that place. Putting a card on an occupied place swaps the two cards and their Roles. Because a card's place is its Role, rearranging the Hand is also how the player reassigns Roles, the way a physical player shuffles cards around in their hand.

**Why this priority**: The request asks to "allow adjusting the position of the cards in your hand". Swapping, say, the Element and the Boost should take one move, not a take-back and a re-place.

**Independent Test**: With all three Roles filled, tap the Boost card and then the Element place (and separately, drag it there). Confirm the two cards trade places and Roles and that the preview's numbers update to match.

**Acceptance Scenarios**:

1. **Given** a card in the Element place and another in the Boost place, **When** the player taps the Boost card and then the Element place, or drags it there, **Then** the two cards swap places, each now fills the Role of its new place, and the preview of the outcome updates.
2. **Given** a card in the Reserve place, **When** the player drags it onto the Spell place, **Then** it becomes the Spell and the former Spell becomes the Reserve.
3. **Given** a card not yet placed, **When** the player drags it onto an empty place, **Then** it fills that Role.
4. **Given** a drag in progress, **When** the player releases the card away from any place, **Then** nothing changes and the card returns to where it was.
5. **Given** a player who does not drag (for example, one using only taps or a keyboard), **When** they want any arrangement, **Then** they can reach it with tap-card-then-tap-place alone. No arrangement needs a drag.

---

### User Story 3 - One row of actions under the cards (Priority: P2)

The actions move into a single row across the bottom of the right side of the board, under the cards: Fuse takes the left quarter, Divert the next quarter, and Play the right half. Above that row, from the top down, the card side holds the role strip (shorter than today's role slots), the row of places, then the floating row of unplaced cards.

**Why this priority**: This is the layout the request asks for. It gives the cards the room the action column used to take beside the slots, and puts Play under the right thumb across a wide target.

**Independent Test**: Open an Encounter at the baseline 1280 × 720 window and check from top to bottom on the right side: role strip, places, floating row, action row. The action row reads Fuse (25%), Divert (25%), Play (50%) across the full width.

**Acceptance Scenarios**:

1. **Given** an Encounter in a Region, **When** the board appears, **Then** from top to bottom the right side shows the role strip, the places, the floating row of unplaced cards, then the action row, and the action row spans the right side's full width.
2. **Given** the action row, **When** it is measured, **Then** Fuse and Divert each take a quarter of the row and Play the remaining half, less the usual gaps between buttons.
3. **Given** the role strip, **When** it is compared with today's role slot band at the same window size, **Then** it is no more than half as tall, and each place in it is still at least the minimum tap-target size.
4. **Given** the action row has fewer than two secondary actions in a phase, **When** it is shown, **Then** Play stays in the right half, so the player always finds it in the same place.

---

### User Story 4 - The Final Battle follows the same order (Priority: P3)

In the Final Journey and the Final Enemy the player builds two Action Sets from a larger Hand. The Hand keeps the same order: the Reserve on the far left, then the first set's Element, Spell and Boost, then the second set's Element, Spell and Boost. Any further cards (the Final Enemy takes the whole remaining Deck into the Hand) sit apart from the ordered places until they are given a Role.

**Why this priority**: It keeps one rule for reading the Hand everywhere, but it only applies to the last stage of each game.

**Independent Test**: Reach the Final Journey with seven cards and confirm that all seven cards and all seven places are fully visible at once, with no scrolling. Then fill both Action Sets and confirm the Hand reads Reserve, Set 1 (Element, Spell, Boost), Set 2 (Element, Spell, Boost), with the role strip labelling each place and telling the two sets apart.

**Acceptance Scenarios**:

1. **Given** the Final Journey's seven-card Hand with both sets filled, **When** the player looks at the Hand, **Then** the order is Reserve, then Set 1's Element, Spell and Boost, then Set 2's Element, Spell and Boost, and the strip marks where each set begins and ends.
2. **Given** the Final Enemy with more cards than places, **When** both sets are filled, **Then** the unplaced cards stay together in the floating row, apart from the two sets, and none of them is labelled as a Role. The Final Enemy shows no Reserve place.
3. **Given** the Final Journey or the Final Enemy, **When** the board appears, **Then** the left side is narrower than in the Regions (but no narrower than the dragon face's minimum readable width), the card side is wider, the places sit in one row, and every card, placed or floating, is fully visible without scrolling. Floating cards wrap onto a second row when they do not fit in one.
4. **Given** the Final Battle, **When** the action row is shown, **Then** Regroup takes Divert's quarter in the Final Journey, Fuse keeps its quarter, and Play keeps the right half.

---

### Edge Cases

- **Fewer than four cards after a Divert**: The rules say one Role must be the Spell when the Hand has fewer than three cards. Places that cannot be filled show as empty and inactive. With exactly three cards, all three Roles are filled and the Reserve place stays empty. With two or one, the Spell must be filled before Play is enabled, as today.
- **Fused cards**: The tucked card leaves the ordered places. It stays tucked behind its partner in that card's place and is not the Reserve, as the rules say. Unfusing returns it to the unplaced cards.
- **Dragging a fused pair**: Moving the top card of a Fuse moves its tucked partner with it.
- **Give up Reserve (Ranged enemy)**: This choice belongs to the Reserve, so it moves off the action row and into the Reserve place as a toggle. When it is on, the Reserve place shows the card as given up.
- **Freeze, Steep and the Reserve's Boost on a Journey**: Rules that read the Reserve's Boost point at the Reserve place, so when the Reserve's Boost counts toward Move, the Reserve place is the one highlighted.
- **Undo Upgrade and Cancel**: In the Upgrade phase, Undo Upgrade takes a secondary quarter of the action row. While a Fuse, Divert or Regroup is under way, that action's quarter becomes its Cancel, as today, so the row never needs more than two secondary cells.
- **More secondary actions than cells**: The phases are such that at most two secondary actions apply at once once Give up Reserve moves into the Reserve place. If a future phase needs more, the extra action must not push Play out of its half.
- **Recap after a battle**: The recap of the set just played keeps the same order, so the player sees which card was Reserve and whether it was kept.
- **Setup and Soak**: When no Roles are being built, the role strip is hidden or blank, the Hand takes its room, and Play keeps the right half of the action row.
- **Narrow or scaled windows**: At every window shape the game is already checked at, the role strip, Hand and action row must all fit with no overlap and every tap target at or above the minimum size.

## Requirements *(mandatory)*

### Functional Requirements

**Hand order**

- **FR-001**: While an Action Set is being built in a Region, the Hand MUST show four ordered places, left to right: Reserve, Element, Spell, Boost (rulebook p. 15).
- **FR-002**: A card's place in the Hand MUST be its Role. Putting a card in a place assigns that Role, and the board MUST NOT show a card in one place while it fills another Role.
- **FR-003**: Once Spell, Element and Boost are filled, the one card left over MUST sit in the Reserve place without the player having to move it.
- **FR-004**: A newly dealt Hand MUST start with every card unplaced, in a floating row below the places and above the action row. The empty places and their role badges MUST stay visible, and no card MUST go into a place without a player action, except the last card going to the Reserve (FR-003). Until a Role is filled the preview MUST NOT show an outcome.
- **FR-005**: Placing by tap MUST work in two steps: tap a card to pick it up (it is marked, and the places it can go to are highlighted), then tap a place to put it there. Tapping a place that holds another card swaps the two. Tapping the unplaced area sends a placed card back to unplaced. Tapping the picked-up card again, or empty space, puts it down unchanged.
- **FR-006**: The player MUST also be able to drag a card onto any place, or onto the unplaced area. Dropping on an empty place fills that Role, and dropping on an occupied place swaps the two cards and their Roles. Releasing anywhere else MUST leave the Hand unchanged.
- **FR-007**: Every arrangement reachable by dragging MUST also be reachable with tap-card-then-tap-place alone, and by keyboard.
- **FR-008**: Moving cards between places MUST update the outcome preview, the highlighted card values and the Play button's state the same way placing a card does today.
- **FR-009**: Cards MUST glide between places rather than jump, and MUST move without animation when reduced motion is on.

**Reserve place**

- **FR-010**: The board MUST have a Reserve place, labelled in the role strip, that holds the card left out of the Action Set.
- **FR-011**: The Give up Reserve choice against a Ranged enemy MUST be offered on the Reserve place, not in the action row. The Reserve place MUST show when the Reserve is to be given up.
- **FR-012**: Wherever the rules use the Reserve's Boost (a Journey's enhanced Move of the matching Ether, Steep) or discard the Reserve (Freeze, Ranged), the board MUST point at the Reserve place.
- **FR-013**: A fused card tucked behind its partner MUST NOT be shown or counted as the Reserve.

- **FR-004a**: An empty place MUST be drawn as a thin outline under its role badge, taking only the height it needs. A filled place shows its card at full size. Placed and floating cards MUST be the same size, and the places row and floating row MUST fit together with every card fully visible, at every stage of placing.

**Role strip**

- **FR-014**: A role strip MUST sit directly above the Hand, with one labelled section per place, each lined up over its card.
- **FR-015**: Each filled section MUST show what the card in it contributes in that Role (the Spell's value, the Element's Initiative, the Boost's bonus), as the role slots do today. The Reserve section shows the Reserve's Boost when that Boost counts, and otherwise just names the place.
- **FR-016**: Against an Enemy, the Boost section MUST still let the player send the Boost to Attack or to Initiative.
- **FR-017**: The section for the Role filled next MUST stay marked, as the next role slot is today.
- **FR-018**: The role strip MUST be no more than half the height of today's role slot band at the same window size. Each section MUST stay at or above the minimum tap-target size.

**Action row**

- **FR-019**: The actions MUST sit in one row at the bottom of the right side of the board, directly under the Hand and spanning the right side's full width.
- **FR-020**: In that row the first secondary action (Fuse) MUST take the leftmost quarter, the second (Divert, or Regroup in the Final Journey) the next quarter, and Play the right half, less the standard gaps between buttons.
- **FR-021**: Play MUST stay in the right half of the row in every phase, including setup and Soak, even when fewer secondary actions apply. Any empty secondary cell MUST be left blank, not filled by stretching Play.
- **FR-022**: Undo Upgrade MUST take a secondary cell in the Upgrade phase. An action under way (Fuse, Divert, Regroup) MUST turn into its own Cancel in the same cell, as today.
- **FR-023**: The order of places and the action row MUST stay the same at every window shape the game is checked at, with no overlapping elements and no tap target below the minimum size.

**Final Battle**

- **FR-024**: With two Action Sets, the ordered places MUST be: Reserve, then Set 1's Element, Spell and Boost, then Set 2's Element, Spell and Boost. The role strip MUST show where each set begins and ends.
- **FR-024a**: In the Final Journey and the Final Enemy only, the left side MUST narrow to the dragon face's minimum readable width, and the card side MUST take the width freed. The places MUST stay in one row, and the floating cards MUST wrap onto a second row when one row cannot hold them at a legible size. Every card MUST be fully on screen at once, with no scrolling or paging.
- **FR-025**: The Final Enemy has no Reserve place, because the rules give it no use there; its places are Set 1's and Set 2's three Roles. Cards left out of both sets (Final Enemy) MUST stay together in the floating row and MUST NOT be labelled as any Role. They still Soak damage afterwards, as today.

**Unchanged rules**

- **FR-026**: The game rules and outcomes MUST NOT change. Card order is presentation and interaction only. The same Roles give the same results as before this feature.

### Key Entities

- **Hand place**: A position in the ordered Hand. It has a Role (Reserve, Element, Spell or Boost), an Action Set (1 or 2) where that applies, and at most one card. A fused pair takes one place.
- **Role strip section**: The label above a Hand place. It shows the place's Role, what its card contributes, whether it is next to fill, and Role-specific controls (Boost target, Give up Reserve).
- **Unplaced cards**: Hand cards without a Role. They are shown apart from the places.
- **Action row**: The bottom row on the right side. It has two secondary cells, each a quarter wide, and Play, half wide.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In every Region Encounter with a full Action Set, the Hand reads Reserve, Element, Spell, Boost from left to right. This holds in 100% of the automated playthrough states checked.
- **SC-002**: A player can swap the cards in any two Roles in one drag, or in at most four taps without dragging.
- **SC-003**: At the 1280 × 720 baseline, the action row's Fuse and Divert cells are each within 2% of a quarter of the row's width, and Play is within 2% of half.
- **SC-004**: At the 1280 × 720 baseline, the role strip is at most 50% of the height of today's role slot band. Every card in the Hand is fully visible at all times while a set is built, with its text at or above the game's existing legibility minimum.
- **SC-004a**: In the Final Journey (7 cards) and the Final Enemy (up to the whole remaining Deck), every card and every place is fully visible at once at the 1280 × 720 baseline, with card text at or above the legibility minimum.
- **SC-005**: At every window shape in the game's check list, nothing in the role strip, Hand or action row overlaps, and no tap target is below the minimum size.
- **SC-006**: Every existing rules test and recorded playthrough gives the same outcome as before. Card order changes nothing in scoring or resolution.
- **SC-007**: A player who knows the physical game can name every card's Role from the Hand alone, without reading the preview, on first sight of the board.

## Assumptions

- "The right half of the screen" means the card side of the board, beside the Encounter face and preview panel on the left (confirmed in Clarifications). The action row spans the card side's full width.
- The ordered Hand replaces today's habit of leaving cards where they were dealt. A card's position now shows its Role, and the role strip replaces today's role slot band rather than appearing alongside it.
- Tap-card-then-tap-place replaces today's tap-to-fill-the-next-Role, and dragging is added on top. Keyboard and tap-only players lose nothing.
- In the Final Battle, the Reserve goes on the far left and the two sets follow in order, extending the rulebook's single-set order. The rulebook gives no order for two sets.
- Give up Reserve moving onto the Reserve place leaves at most two secondary actions in any phase (Fuse plus Divert or Regroup, or Undo Upgrade alone), which fits the two quarter-width cells.
- No engine or rules change is needed. The base game does not score card order, and expansion rules that do are out of scope.
- The baseline used for measurements is the 1280 × 720 design layout the board is already checked at.
