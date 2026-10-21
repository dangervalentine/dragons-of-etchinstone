# Feature Specification: Shuffling the Deck Under the Card on Top

**Feature Branch**: `016-deck-shuffle-animation`

**Created**: 2026-10-20

**Status**: Draft

**Input**: User description: "Add a shuffle animation whenever it would be needed to the deck. in most siutations, you would have a region card placed on top and that would cover the deck while the shuffling occurs - after initial setup, between regions, before the final encounter with the dragon card laid on top instead"

## Background

This feature builds on `specs/012-deck-region-card` and `specs/013-physical-region-card`, which made the left side of the play screen the held Deck, with the Region Card (or, in the Final Battle, the Dragon Card) lying on top of it.

The physical game shuffles the Deck at three moments (rulebook *Setup*, *End of the Region*, *The Final Battle*):

1. **Setup**: the Mage Cards are oriented to Level 2 and shuffled. The setup offer for the chosen difficulty is then shuffled back into the Deck before the first Hand is drawn.
2. **End of the Region** (Regions 1 to 3): every Mage Card that has not been Trashed is gathered and shuffled into a new Deck, and the Region Card is set on top, turned to the next Region.
3. **The Final Battle** (after Region 4): the same reshuffle happens, and the Dragon Card takes the Region Card's place on top of the Deck.

The game already does these shuffles, but the player never sees one. Today the Deck simply refills (the setup cards fly back under the note preparing the Deck, or the Discard flies back under the turned card) and the next Hand is drawn. Nothing tells the player that the order of the cards has been redone.

The user asks for the shuffle to be shown. It should happen with the card that belongs on top already lying there and covering the Deck, so that what the player watches is the stack being worked beneath the Region Card or Dragon Card.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The Deck is shuffled under the next Region Card between Regions (Priority: P1)

A player finishes the last Encounter of a Region. The Hand and the rest of the Deck go to the Discard, and the Region Card turns to the next Region. The Discard comes back under the Region Card as the Deck. The stack is then visibly shuffled beneath the Region Card: one after another, the Mage Cards just under it peel out a little from under it and slide back in under the rest, while the Region Card stays on top. Only after that is the new Hand drawn.

**Why this priority**: The End of a Region is the shuffle the player meets most often (three times a game), and it is the one the rules make most of: Levels carry over, so the order is all that changes.

**Independent Test**: Play to the End of Region 1. Between the Region Card turning to Region 2 and the first card of the new Hand leaving the Deck, the Deck is seen being shuffled under the Region 2 card. Each peeling card shows only the strip of its face that sticks out from under the card, and nothing blank shows.

**Acceptance Scenarios**:

1. **Given** the last Encounter of Region 1, 2 or 3 is finished, **When** the Deck is gathered for the next Region, **Then** the Region Card has already turned to the next Region and lies on top, and the shuffle plays beneath it before any card of the new Hand is drawn.
2. **Given** the shuffle is playing, **When** the player watches the left side, **Then** the Region Card stays on top and in place the whole time, and the Mage Cards peeling from beneath it show their faces as the face-up Deck holds them, never a blank side.
3. **Given** the shuffle has finished, **When** the new Hand is drawn, **Then** the stack's depth equals the Deck count in the header, and the Hand's cards come from under the Region Card as they do today.
4. **Given** the Discard is flying back under the turned card, **When** its last card lands, **Then** the shuffle starts only after it, so cards are never seen arriving and being shuffled at once.

---

### User Story 2 - The Deck is shuffled under the Dragon Card before the Final Battle (Priority: P1)

A player finishes Region 4. The cards are gathered as at any End of a Region, but the Dragon Card is laid on top of the Deck instead of a Region Card. The Deck is shuffled beneath the Dragon Card, and the Final Journey's Hand is then drawn from under it.

**Why this priority**: It is the same moment as Story 1, marking the start of the climax of the game. The user named it specifically, with the Dragon Card as the cover.

**Independent Test**: Play to the end of Region 4. Once the Dragon Card is on top, the Deck is shuffled under it before the Final Journey's seven cards are drawn.

**Acceptance Scenarios**:

1. **Given** the last Encounter of Region 4 is finished, **When** the Deck is gathered for the Final Battle, **Then** the Dragon Card takes the Region Card's place on top first, and the shuffle plays beneath it.
2. **Given** the shuffle under the Dragon Card has finished, **When** the Final Journey begins, **Then** its Hand is drawn from under the Dragon Card and the view zooms into the MP Tiers as today.

---

### User Story 3 - The Deck is shuffled under Region 1's card after setup (Priority: P2)

A new game begins. Once the player has chosen and Downgraded the setup cards for their difficulty and they go back into the Deck, the Region 1 Region Card is laid on top. The Deck is shuffled beneath it, and the first Hand is drawn.

**Why this priority**: It happens once per game, but it is the player's first sight of the Deck and teaches them what the shuffle looks like before it matters. It needs the order of today's setup sequence to change: the Region Card is laid down before the shuffle, not after the cards return.

**Independent Test**: Start a new game on any difficulty and finish setup. The setup cards go back into the Deck, the Region 1 card is laid on top, and the shuffle plays under it before the first Hand is drawn.

**Acceptance Scenarios**:

1. **Given** setup is confirmed, **When** the setup offer returns to the Deck, **Then** the Region 1 Region Card is laid on top of the Deck before the shuffle plays, and the shuffle plays before the first Hand is drawn.
2. **Given** a difficulty whose setup offer has no cards to choose (or a game that skips the setup step), **When** the first Hand is about to be drawn, **Then** the shuffle under the Region 1 card still plays once, because the game still shuffles the Deck at the start.
3. **Given** the setup shuffle has played, **When** the first Encounter begins, **Then** the stack's depth equals the Deck count in the header.

---

### User Story 4 - The shuffle respects reduced motion and the pace of play (Priority: P3)

A player with reduced motion on still learns that the Deck was shuffled, without seeing cards move. A player who has seen the shuffle many times is not slowed by it more than the other transitions slow them.

**Why this priority**: It is needed for accessibility and to keep play from dragging, but it adds nothing until the shuffle itself exists.

**Independent Test**: Turn reduced motion on and play to the End of Region 1. The moment of the shuffle is marked without movement. With reduced motion off, time the gap between the Region Card settling and the first card of the new Hand leaving.

**Acceptance Scenarios**:

1. **Given** reduced motion is on, **When** a shuffle would play, **Then** no card moves, and the player is still told, in a still and brief way, that the Deck has been shuffled.
2. **Given** reduced motion is off, **When** a shuffle plays, **Then** it finishes within the time limit in SC-002, and any skip or speed-up that applies to the surrounding sequence applies to the shuffle too.

---

### Edge Cases

- **Small Decks**: late in the game, many cards may have been Trashed, so the gathered Deck is small. The shuffle must still read as a shuffle with only a few cards, and must never show more cards moving than the Deck holds (beyond the stack's usual drawn depth).
- **No Deck at all**: if every card not in the Hand has been Trashed and nothing is gathered, no shuffle plays.
- **Diverts and ordinary Cleanup draws**: these do not shuffle the Deck in the physical game, so no shuffle plays.
- **Regroup**: the rulebook shuffles the six Hand cards and puts them at the *back* of the Deck. That is a shuffle of the Hand, not of the Deck under the Dragon Card, so this feature does not add a Deck shuffle there (see Assumptions).
- **Undo**: undoing a choice within an Encounter never replays a shuffle that has already been shown.
- **Resizing mid-shuffle**: if the window is resized or rotated during a shuffle, the shuffle stays within the Deck's place on the left side and ends with the stack correctly sized.
- **Leaving mid-shuffle**: if the player leaves the play screen during a shuffle, coming back shows the settled state (shuffled Deck, card on top) without replaying the shuffle.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A shuffle animation MUST play on the Deck each time the game shuffles the Deck: once after setup, at each End of a Region from Region 1 to 3, and once before the Final Battle.
- **FR-002**: Before each shuffle begins, the card that belongs on top for what follows MUST already be lying on top of the Deck: the Region 1 Region Card after setup, the next Region's side at each End of a Region, and the Dragon Card before the Final Battle.
- **FR-003**: Throughout the shuffle, the card on top MUST stay on top and visible, and MUST cover the Deck. The Mage Cards seen moving MUST be shown as real Mage Cards, face up as the Deck is held. Only the strip that sticks out from under the card on top shows, and they come out less far than a Key Card rises. They MUST NOT be shown in the Deck's new order, and nothing blank may show. *(Changed 2026-10-20: the first build showed blank card-stock edges pulled far out, which the user rejected.)*
- **FR-004**: The shuffle MUST read clearly as a shuffle of a physical stack: cards visibly separate from the stack, change order, and are squared back into a neat stack under the card on top.
- **FR-005**: The shuffle MUST finish before the first card of the following Hand is drawn, and the following Hand's draw, Key Card reveal and zoom MUST proceed as they do today.
- **FR-006**: When the shuffle ends, the stack's visible depth MUST match the Deck count shown in the header.
- **FR-007**: After setup, the Region 1 Region Card MUST be laid on top before the shuffle. This changes today's order, where the Deck refills first and the Region Card is laid on after.
- **FR-008**: No shuffle animation MUST play where the game does not shuffle the Deck: on Diverts, on ordinary Cleanup draws, on Knock Outs, and on Regroup.
- **FR-009**: The shuffle MUST start only once every card coming back into the Deck (the setup cards, or the Discard at the End of a Region) has landed in it, and MUST NOT overlap the stage banner that follows.
- **FR-010**: With reduced motion on, no card MUST move during a shuffle, and the player MUST still be told briefly, without motion, that the Deck was shuffled.
- **FR-011**: A shuffle MUST play once per real shuffle. Undo, and leaving and returning to the play screen, MUST NOT replay it.
- **FR-012**: The shuffle MUST stay within the Deck's place on the left side at every supported window size and resolution, without overlapping the Hand, the header or the action row.
- **FR-013**: A shuffle MUST NOT change what is shuffled. The order of the Deck the player then plays against is the one the game produced, and the animation only shows it happening.

### Key Entities

- **Deck**: the ordered Mage Cards not in the Hand, Discard or Trash, shown as the stack on the left side. It is what is shuffled.
- **Card on top**: the Region Card (turned to the current Region) or the Dragon Card, lying on the Deck. It stays put and covers the Deck while the Deck is shuffled.
- **Shuffle moment**: one of the game's real Deck shuffles: after setup, at the End of Regions 1 to 3, and before the Final Battle.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a full game, the shuffle is seen exactly 5 times (once after setup and once after each of Regions 1 to 4), and at no other time.
- **SC-002**: Each shuffle takes no more than 1.5 seconds from start to the stack settling. Each End of a Region sequence takes no more than 1 second longer than it does today.
- **SC-003**: In every shuffle, the Region Card or Dragon Card is on top from the first moment to the last. Every card seen moving is a Mage Card face, and none comes out further than a Key Card rises.
- **SC-004**: Shown a recording of an End of a Region, a player who has not seen it before can say that the Deck was shuffled under the new Region Card.
- **SC-005**: With reduced motion on, 0 cards move during any shuffle moment, and each moment is still marked.
- **SC-006**: After every shuffle, the stack depth and the header's Deck count agree in 100% of cases.

## Assumptions

- **Regroup is out of scope.** The rulebook has the six Hand cards shuffled in the hand and placed at the back of the Deck, not the Deck shuffled under the Dragon Card. Regroup keeps its current return-to-the-Deck movement. A small in-Hand shuffle for Regroup could be added later if wanted.
- **The Region Card covers the Deck despite the rulebook's order.** At the End of a Region, the rulebook reshuffles, draws the Hand and only then places the Region Card. As the user asked, the game lays the card on top first and shuffles under it. This is a presentation choice and has no effect on the rules.
- **The setup shuffle always plays**, even on a difficulty or path where no setup cards were chosen. The game always shuffles the Deck before the first Hand.
- **Look of the shuffle**: the riffle of the sibling project NextQuest. A few cards peel out from under the pile one after another, each tilting and shrinking slightly at the height of its arc, then slide back in under the rest. The next card starts before the last is home. Here the cards peel out from under the card on top, into whatever room the Deck has above or below it.
- **Sound**: the game has no card sound effects in scope today, so none is required here.
- **Skip and speed**: the shuffle follows whatever skip or fast-forward behaviour the surrounding animation sequence already has. It adds no control of its own.
- **Dependencies**: the Deck, the Region Card, the Dragon Card, the card turn, and the regather of the Discard from specs 012 to 015 are in place and are reused.
