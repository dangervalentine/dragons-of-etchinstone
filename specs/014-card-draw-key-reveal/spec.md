# Feature Specification: Drawn Cards and the Key Card at the Region Card's Size

**Feature Branch**: `014-card-draw-key-reveal`

**Created**: 2026-10-19

**Status**: Draft

**Input**: User description: "regarding the animation for how cards are drawn, how the key card is shown: the cards from the desk should start at the same size as the region card - as it is - and scale down to the appropriate size as it is translating to its resting place in the player's hands. that means translating to the right and shrinking in size. the idea is to capture that the cards are all the same size and the region card is just another card. when the key card is shown, it should be as wide as the region card as well. the key card's number should be highlighted and then the intended encounter of the region matching the key card should be highlighted - followed by the zoom into that given encounter."

## Background

This feature follows on from `specs/012-deck-region-card` and `specs/013-physical-region-card`. Together they put the Deck on the left side of the play screen, with the Region Card (or the Dragon Card) on top. The Hand is drawn from under the top card. The Key Card lifts to show its Encounter, and the view zooms into the matching panel.

How it looks today:

- **Drawing.** Each new Hand card appears as a small, faded card about a third of the Hand card's size, centred on the Deck. It grows as it glides to its place in the Hand. It never looks like a card the same size as the Region Card it came from under.
- **The Deck.** The cards under the Region Card show as a few plain stone-coloured edges offset below and to the right. It is hard to tell they are a pile of cards.
- **The Key Card.** The Key Card rises from under the Region Card at the Hand's card size, which is narrower than the Region Card. It shows its title band and Encounter strip, holds, and slides back. Then the view zooms in. Nothing ties the Key Card's number to a panel on the Region Card before the zoom.

In the physical game, every card is the same size. The Region Card is just another card lying on top of the Deck. This feature makes the motion say so.

## Clarifications

### Session 2026-10-19

- Q: Does the Key Card slide back before the matching panel is highlighted, or stay out? → A: It stays raised while the panel is highlighted. The number highlight and the panel highlight may happen at the same time if that reads better. The Key Card slides back down under the Region Card when the zoom starts.
- Q: What should make the Deck read as a pile of real cards being drawn from? → A: Real card edges. Each card under the Region Card shows as a thin card edge, a little offset and slightly uneven, so the pile thickens and thins with the Deck count, with a soft shadow under it. The edges do not reveal any card's Ether colour; every edge looks the same. The edges have the same rounded corners as the cards, and so does the pile as a whole.
- Q: Should a drawn card show its face the whole way, or start as a card back and turn over? → A: Cards are always face-up, and so is the Deck, as in the physical game: the Region Card lies on a face-up pile, which is why the Key Card's number can peek out from under it. Drawn cards show their faces throughout the flight. Because the pile is face-up and seen from the side, its edges are plain card edges (the cards' sides), not card backs, and show no Ether colour.

### Session 2026-10-19 (after the first build)

- Q: Where do drawn cards come from? → A: From under the Region Card, which stays lying on top of them. A drawn card starts hidden beneath the top card and slides out from under it, then shrinks into the Hand.
- Q: Should the zoomed Encounter show its number? → A: No. The reading strip names it without the number ("Swamp Treant", not "1 Swamp Treant"), and the number plate fades out of the panel's art as the view zooms in. It stays on the whole Region Card, where it matches the Key Card's number.
- Q: Which views of the Region Card are rounded? → A: All of them: the whole card, the card while it grows into the panel, and the zoomed face.
- Q: Does the reveal go straight on to the zoom? → A: No. Once the Key Card is up with its number and its Encounter lit, the reveal waits for the player. The action reads "Face Enemy 3" (or "Face Journey 2"), and any press goes on: the Key Card slides down and the Deck zooms in. A press earlier in the sequence hurries it on to this point instead of past it, so every Encounter is seen and confirmed. A change of window size or the app going to the background still finishes the whole sequence at once.
- Q: How does the note showing an Encounter's results look? → A: Like the card itself: the zoomed face's colour and rounded corners, with no rim of its own. The Region Card seems to have changed its contents to show the results.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Drawn cards leave the Deck at the Region Card's size (Priority: P1)

When the Hand is drawn, each card starts exactly where the Region Card lies on the Deck, at the Region Card's size, as if it were slipped out from under it. It then travels right to its place in the Hand, shrinking as it goes, and arrives at the Hand's card size. The player sees that the cards in the Hand and the Region Card are cards of one size, shown at different scales.

**Why this priority**: This is the main point of the request. Every draw in the game uses this motion, so it is what the player sees most.

**Independent Test**: Start a game and watch the first Hand being drawn. Pause or slow the motion at the first frame of each drawn card. The card's outline matches the Region Card's outline on the Deck. Through the motion it moves right and shrinks steadily, and it ends at its Hand place and size.

**Acceptance Scenarios**:

1. **Given** the Region Card is on top of the Deck and the Hand is about to be drawn, **When** a card is drawn, **Then** it first appears with the same position, width and height as the Region Card on the Deck.
2. **Given** a drawn card has appeared, **When** it travels to the Hand, **Then** it moves toward its place in the Hand and shrinks at the same time, with no jump in size or position. It arrives at exactly its resting place and the Hand's card size.
3. **Given** several cards are drawn at once (a new Hand, or a Cleanup draw), **When** they leave the Deck, **Then** each one starts at the Region Card's size and position, one after another with the existing stagger, and each lands in its own place.
4. **Given** a drawn card is in motion, **When** the player looks at it, **Then** it reads as a whole card at every moment. It keeps its shape and is not faded out, so it never looks like a small dot or a ghost growing from nothing.
5. **Given** the Final Battle, with the Dragon Card on top, **When** cards are drawn (the first Hand or after a Regroup), **Then** they start at the Dragon Card's size and position and shrink into the Hand the same way.

---

### User Story 2 - The Key Card is as wide as the Region Card (Priority: P1)

When the Key Card is revealed from under the Region Card, it is the same width as the Region Card. It is the next card in the same stack, so its edges line up with the Region Card's edges. It rises just far enough to show its Encounter icon, number and any Hardship, at that larger size.

**Why this priority**: The request depends on this. A Key Card narrower than the card above it says the cards are different sizes, which is what this feature is meant to undo.

**Independent Test**: Reach any Region Encounter. When the Key Card rises, its left and right edges line up with the Region Card's left and right edges. The part that shows is its Encounter strip, now drawn at the Region Card's scale.

**Acceptance Scenarios**:

1. **Given** the Key Card rises from under the Region Card, **When** it is at its highest point, **Then** its width equals the Region Card's width and its sides line up with the Region Card's sides.
2. **Given** the Key Card is raised, **When** the player reads it, **Then** its Encounter icon, number and any Hardship are shown in full at that size, and no more of the card shows than is needed for them.
3. **Given** the Key Card has been shown, **When** it slides back, **Then** it goes back under the Region Card with its edges still aligned, and the stack looks as it did before.

---

### User Story 3 - The Key Card's number, then its Encounter, are highlighted before the zoom (Priority: P1)

While the Key Card is raised, its Encounter number is highlighted. Next, the matching Enemy or Journey panel on the Region Card is highlighted, so the player can see which panel that number points to. Only then does the view zoom into that panel. The player follows the rule step by step: this card, this number, this Encounter.

**Why this priority**: This is the teaching moment of the physical game's draw. Without it, the zoom seems to come from nowhere.

**Independent Test**: Reach an Encounter whose Key Card names Journey 3. In order: the Key Card rises; its "3" and Journey icon are highlighted; the Journey 3 panel on the Region Card is highlighted while the Key Card is still raised (or both highlights at once); the Key Card slides down as the view zooms into Journey 3. Repeat for an Enemy Key Card.

**Acceptance Scenarios**:

1. **Given** the Key Card has risen, **When** it holds, **Then** its Encounter icon and number are highlighted. The highlight stands out from the rest of the card in the game's highlight style.
2. **Given** the Key Card's number has been highlighted (or is being highlighted), **When** the sequence moves on, **Then** the panel on the Region Card with that Encounter type and number is highlighted while the Key Card stays raised with its number still highlighted, and no other panel is highlighted.
3. **Given** the panel is highlighted, **When** the zoom starts, **Then** the Key Card slides back down under the Region Card as the view zooms into exactly that panel, and the highlights fade as the zoom lands. The settled Encounter face does not keep the highlight.
4. **Given** a Key Card with a Hardship, **When** its number is highlighted, **Then** the Hardship is still visible next to it. The Encounter face after the zoom still carries that Hardship, as today.
5. **Given** the player Diverts, **When** the next Key Card is revealed, **Then** the same sequence runs: rise at Region Card width, number highlighted, panel highlighted, zoom.

---

### User Story 4 - Reduced motion and skipping still tell the same story (Priority: P2)

With reduced motion on, cards do not travel or shrink and the Key Card does not slide. The player still learns the same things: the Hand fills, the Key Card's number is shown and highlighted, and the matching panel is highlighted before the Encounter face appears. A player who skips the sequence lands on the same settled state.

**Why this priority**: Accessibility and pace matter, but they come second to getting the motion itself right.

**Independent Test**: Turn on reduced motion and reach an Encounter. No card moves or changes size. The Key Card fades in at Region Card width with its number highlighted. Then the matching panel is highlighted, then the face appears. Separately, tap through a sequence to skip it and check the settled Hand and face are the same as without skipping.

**Acceptance Scenarios**:

1. **Given** reduced motion is on, **When** cards are drawn, **Then** they appear in their Hand places at Hand size with no travel or scaling, as today.
2. **Given** reduced motion is on, **When** the Key Card is revealed, **Then** it appears in place at the Region Card's width, already raised. Its number is highlighted, then the matching panel is highlighted, and then the face fades in. Nothing slides or zooms.
3. **Given** a draw or reveal is playing, **When** the player skips, **Then** everything settles at once into the same Hand, stack and Encounter face as if the sequence had played out.

---

### User Story 5 - The Deck looks like a pile of cards (Priority: P2)

The Deck on the left reads at a glance as a face-up pile of real cards, with the Region Card lying on top. Each card under the Region Card shows as a thin, plain card edge (the side of a card), a little offset and slightly uneven, with rounded corners like the cards themselves. A soft shadow lies under the pile. The pile thickens and thins as the Deck count changes, so the draws visibly come out of it.

**Why this priority**: The request names it as hard to tell today. It supports the draw motion: a card leaving the Deck needs a Deck that looks like cards.

**Independent Test**: Start a game and look at the left side with the view zoomed out. A player calls it "a deck of cards with the Region Card on top" without prompting. Draw a Hand, and check the pile is thinner afterwards. Look closely, and check no edge shows an Ether colour and every corner is rounded.

**Acceptance Scenarios**:

1. **Given** the Deck holds cards, **When** the player looks at it, **Then** beneath the top card they see separate card edges, each the plain side of a card. The edges are slightly offset and uneven, with a soft shadow under the pile.
2. **Given** any card edge in the pile, **When** the player looks at it, **Then** it shows no Ether colour or other hint of which card it is. Every edge looks alike.
3. **Given** the pile and its edges, **When** the player looks at the corners, **Then** they are rounded the same way as the Region Card's and the Hand's cards.
4. **Given** the Deck count drops (a draw, time paid, a Divert) or rises (a reshuffle), **When** the change is shown, **Then** the pile visibly thins or thickens to match.
5. **Given** the view is zoomed into an Encounter, **When** the player looks at the left side, **Then** the card edges are still visible beneath the face, as a pile.

---

### Edge Cases

- **Small windows and phones.** The Region Card is much bigger than a Hand card there (for example 198 × 277 against the Hand's size on phone-tall). The draw must still read as shrinking, not as a sudden jump. Cards in flight may pass over the gap between the left column and the Hand, but they end inside the Hand's area.
- **Large windows.** If the Hand's cards are as large as or larger than the Region Card, the card grows or keeps its size on the way. The rule is "start at the Region Card's size, end at the Hand's size," whichever way that goes.
- **Draw while zoomed in.** Cards are only drawn once the view has zoomed out to the whole Region Card (012 FR-005b). If a draw ever starts while zoomed in, cards start at the whole Region Card's size and resting place on the Deck, not at the enlarged face.
- **One card drawn.** A single card drawn mid-Encounter, if the rules ever draw one, follows the same motion.
- **Cards going back.** Cards gathered back into the Deck (reshuffle, Regroup) and cards sent from the Deck to the discard are not covered by this feature. They keep their current motion.
- **Undo.** Undoing a choice within an Encounter does not replay the draw, the Key Card reveal or the highlights (012 FR-012).
- **Key Card with no matching panel.** This cannot happen in a Region. In the Final Battle there is no Key Card reveal, so there are no highlights there (012 FR-010).
- **Nearly empty Deck.** With very few cards left, the pile shows only one or two edges, but still at least one while the Deck has any cards. With none left, no edges show under the top card.
- **Many cards.** The pile's thickness is capped so it fits the left column; past the cap, it stays at its thickest.
- **Region change.** At the End of a Region, the Region Card turns to the next Region first. The new Hand then starts at the new Region Card's size and position.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every card drawn from the Deck into the Hand MUST first appear with the same position and size as the card on top of the Deck: the whole Region Card in a Region, or the whole Dragon Card in the Final Battle.
- **FR-002**: From there, each drawn card MUST move to its resting place in the Hand while its size changes continuously to the Hand's card size. Position and size MUST change together over the same motion and both finish when the card lands.
- **FR-003**: A drawn card MUST keep its card shape and stay fully visible throughout its flight. It MUST NOT start as a small, faded card.
- **FR-004**: When several cards are drawn at once, each MUST follow FR-001 to FR-003, staggered one after another as today, and land in its own place in the Hand order.
- **FR-005**: When the Key Card is revealed, it MUST be drawn at the Region Card's width, with its sides aligned to the Region Card's sides. It MUST rise only far enough to show its Encounter icon, number and any Hardship at that size.
- **FR-006**: While the Key Card is raised, its Encounter icon and number MUST be highlighted.
- **FR-007**: After, or at the same time as, the Key Card's number is highlighted, the Region Card panel with the matching Encounter type and number MUST be highlighted, and no other panel. The Key Card MUST stay raised, with its number highlighted, while the panel is highlighted.
- **FR-008**: The zoom into the Encounter MUST start only after the matching panel has been highlighted. It MUST zoom into that panel, and the highlight MUST be gone once the zoom has settled.
- **FR-009**: The order MUST be: the Hand is drawn and settles; the Key Card rises; its number is highlighted; the matching panel is highlighted, with the Key Card still raised (the two highlights may happen together); then the zoom starts, and the Key Card slides back down under the Region Card as it does. This order MUST apply to every Key Card reveal, including after a Divert.
- **FR-010**: With reduced motion on, draws MUST place cards with no travel or scaling. The Key Card MUST appear in place at the Region Card's width, already raised. Both highlights MUST still be shown, in order or together, while the Key Card is shown. The Key Card MUST then fade out as the Encounter face fades in, with no sliding or zooming.
- **FR-011**: Skipping a draw or reveal MUST settle at once into the same Hand, stack and Encounter face as letting it play.
- **FR-012**: From the Hand settling to the zoomed face settling, the reveal (rise, two highlights, zoom) MUST take no more than 3 seconds. It MUST be skippable by the player's next input.
- **FR-002a**: While the Hand is drawn, the top card MUST lie over the cards being drawn. Each drawn card is hidden beneath it at first and comes out from under it.
- **FR-017**: Zoomed in, the Encounter MUST be named without its number, and the panel's number plate MUST NOT show. The plate fades out during the zoom in and back in during the zoom out.
- **FR-018**: The Region Card's rounded corners MUST hold before, during and after the zoom, including on the zoomed face.
- **FR-019**: The note laid in the card's place (results, steps, Soak, XP, refusals) MUST have the zoomed face's colour and rounded corners and no rim of its own.
- **FR-020**: Every Region reveal MUST wait, with the Key Card up and both highlights on, until the player presses. The primary action MUST name the Encounter ("Face Enemy 3"), and the other actions (Fuse, Divert, Regroup) MUST be hidden until the reveal goes on. A press before the wait MUST hurry the sequence on to the wait, not past it. A press during the wait MUST go on with the zoom and the rest of the sequence.
- **FR-013**: The behaviour established in 012 and 013 MUST otherwise be kept: the Region Card stays on top throughout, the stack's depth tracks the Deck count, the reveal is not replayed on undo, the Final Battle has no Key Card reveal, and the left side fits at every supported window size.
- **FR-014**: The Deck MUST show the cards under the top card as separate edges, each the plain side of a card (the pile is face-up, so no card back is shown), a little offset and slightly uneven, with a soft shadow under the pile. The number of edges shown MUST rise and fall with the Deck count, up to a cap that fits the left column, and MUST be at least one while the Deck holds any card.
- **FR-015**: The Deck's card edges MUST NOT reveal any card's Ether colour or anything else that tells cards apart. All edges look alike.
- **FR-016**: The Deck's edges, and the pile as a whole, MUST have the same rounded corners as the cards (the Region Card, the Dragon Card and the Hand's cards).

### Key Entities

- **Top card**: the Region Card (in a Region) or the Dragon Card (in the Final Battle) lying on the Deck. Its whole size and resting place on the Deck are where every drawn card starts.
- **Drawn card**: a Mage Card moving from under the top card to its place in the Hand. It starts at the top card's size and ends at the Hand's card size.
- **Deck pile**: the Mage Cards left in the Deck, under the top card. The pile is face-up, as in the physical game. Each card shows as a plain, rounded card edge. The pile's thickness tracks the Deck count up to a cap.
- **Key Card**: the Mage Card directly under the Region Card. It is revealed at the Region Card's width. Its Encounter icon and number are highlighted.
- **Matching panel**: the one Enemy or Journey panel on the Region Card whose type and number match the Key Card. It is highlighted before the zoom.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a frame-by-frame check of any draw, at every supported window size, the first frame of each drawn card matches the top card's outline on the Deck within 2 px on each edge. The last frame matches its Hand place within 2 px.
- **SC-002**: Throughout every draw, each card's width-to-height ratio stays the card ratio (within 1%), and its size changes in one direction only, without overshoot.
- **SC-003**: At its highest point, the Key Card's left and right edges line up with the Region Card's within 2 px, at every supported window size.
- **SC-004**: In 100% of Region Encounter reveals in a full playthrough, the Key Card's number highlight comes before or with the panel highlight, the Key Card is still raised while the panel is highlighted, the panel highlight comes before the zoom, and the highlighted panel is the one that is zoomed into.
- **SC-005**: In a playtest, a player shown any Encounter reveal can say which number the Key Card showed and point to the panel it selected, in at least 9 of 10 reveals, without consulting the rulebook.
- **SC-006**: A player who sees the draw for the first time describes the Hand's cards and the Region Card as "the same kind of card" (or similar), rather than as different things.
- **SC-007**: From the Hand settling to the zoomed face settling takes no more than 3 seconds, and a full game is not noticeably longer than before this feature.
- **SC-008**: At first sight of the play screen, at least 9 of 10 playtesters describe the left side as a deck or pile of cards without prompting.
- **SC-009**: At every Deck count in a full playthrough, the number of edges shown agrees with the count's rule (FR-014), and no edge shows an Ether colour (zero mismatches).

## Assumptions

- The physical game's cards are all the same size, and the game already draws the Region Card and the Mage Cards at the same 5:7 shape. So a drawn card can shrink from one to the other without changing shape.
- "As it is" means the Region Card's current size and place on the Deck are unchanged. Only the drawn cards and the Key Card adapt to it.
- Cards are never shown face-down. A drawn card shows its face (its normal Hand appearance, scaled) throughout the flight.
- "Highlighted" uses the game's existing highlight style: gold leaf or glow, as used for a chosen Boost or a picked card. No new visual language is introduced.
- The 013 Encounter number marker on each panel is what makes the match readable. The panel highlight covers the whole panel, including its marker.
- The extra highlight steps lengthen the reveal. The 2-second budget of 012 SC-003 is raised to 3 seconds for this reason (FR-012, SC-007).
- Cards leaving the Hand or the Deck in other ways (discard, trash, reshuffle, Regroup gather, time paid from the Deck) keep their current motion. They are out of scope.
- No change to rules, scoring or the game engine's behaviour is intended.
