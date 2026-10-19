# Feature Specification: Notes Dealt On and Discarded Off Like Cards

**Feature Branch**: `015-dealt-table-notes`

**Created**: 2026-10-19

**Status**: Draft

**Input**: User description: "treat every post encounter information and anything else which appears over the left hand side of the encounters as if they were cards being served onto and off of a deck of cards. the post encounter summary, damage being applied, exp being applied, when a user hits play without selecting where the boost is applied - all of those should be treated as cards coming in from the left and look like a playing card being laid over the existing content. it should look like the card is discarded off to the left again when the interaction is complete. we already have some of this animation pattern done - when we finish the set up sets for upgrading cards"

## Background

This feature follows on from `specs/012-deck-region-card`, `specs/013-physical-region-card` and `specs/014-card-draw-key-reveal`. The left side of the play screen is the Deck, with the Region Card (or the Dragon Card) on top. While there is something else for the player to read, a **note** lies over the Encounter in the card's place. The note can show:

- the **result** of the set just played (its sum and verdict, the Encounter summary);
- a **step** to follow (a Fuse, a Divert, a Regroup, or the Deck being prepared);
- the **Soak** (damage being taken);
- the **XP** to spend (upgrading cards);
- a **refused move's** reason, for example pressing Play without choosing where the Boost goes.

How it looks today:

- **Coming on.** The note slides a short way in from the right while it fades in. It reads as a panel appearing, not a card being laid down.
- **Going off.** It slides a short way back to the right while it fades out.
- **Changing.** When what it says changes while it is showing (for example from the result to the Soak), it dims and brightens in place.
- **The one exception.** At the end of setup, the note that prepared the Deck is thrown off to the left like a discarded card, turning a little as it goes, out past the Deck's edge. This is the motion the player should see for every note.

In the physical game, nothing hovers over the table: anything put down over the Region Card is a card, and it is taken away by discarding it. This feature makes every note behave that way.

## Clarifications

### Session 2026-10-19

- Q: When the note changes to a different kind of information while it is showing, how do the cards hand over? → A: Each new piece of information is a new card laid on top of the ones already down. They build up into a small pile and are all discarded together once the interaction is complete.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Every note is dealt on from the left like a card (Priority: P1)

Whenever a note comes onto the Deck, it arrives from off the left edge of the screen as a whole playing card, the size of the card it covers, and is laid down over the Encounter. It travels in, turning slightly as it comes and straightening as it settles, and lands exactly in the card's place. It does not fade in from nothing and does not come from the right.

**Why this priority**: This is the first half of the request and applies to everything the left side ever shows over the Encounter.

**Independent Test**: Play a set against an Enemy. When the result appears, it comes in from the left as a card, fully opaque, turns slightly in flight, and lands square over the Encounter face. Repeat for the Soak, the XP to spend, a Fuse/Divert/Regroup step, and pressing Play without choosing a Boost role.

**Acceptance Scenarios**:

1. **Given** the Encounter face is showing with no note, **When** the result of a Play is ready, **Then** a card carrying the result enters from beyond the left edge of the Deck and comes to rest exactly over the Encounter face.
2. **Given** a note is in flight, **When** the player looks at it, **Then** it reads as a whole card at every moment: rounded corners, the same width and height as the card under it, a soft card shadow under it, and fully opaque.
3. **Given** a note arrives, **When** it lands, **Then** it is square to the Deck (no lasting tilt) and its edges line up with the card it covers.
4. **Given** the player presses Play without choosing where the Boost goes, **When** the move is refused, **Then** the reason arrives on a card dealt in from the left in the same way.
5. **Given** damage is to be soaked, or XP is to be spent, **When** that step begins, **Then** the Soak or the XP to spend arrives on a card dealt in from the left in the same way.

---

### User Story 2 - Every note is discarded off to the left when done (Priority: P1)

When the player is done with a note (the result is acknowledged, the Soak is applied, the XP is spent, the step is taken, or a refused move's moment passes), the card is thrown off to the left like a discard, turning a little as it goes, out past the Deck's edge, uncovering the Encounter or card beneath. This matches the note that is thrown off at the end of setup today.

**Why this priority**: This is the second half of the request. Together with Story 1, it gives the full "laid on, discarded off" cycle.

**Independent Test**: Take a set through its result, Soak and XP. Each time a note is done with, it leaves to the left, rotating slightly, and passes beyond the Deck's left edge before disappearing. The motion matches the end-of-setup discard.

**Acceptance Scenarios**:

1. **Given** a note is lying on the Deck, **When** the player is done with it, **Then** it moves off to the left, turning a little as it goes, and leaves past the Deck's left edge.
2. **Given** a note is being discarded, **When** it crosses the Deck's edge, **Then** it is not cut off by the Deck's bounds; it is seen leaving the left side of the screen.
3. **Given** a refused move's reason is lying on the Deck, **When** its moment passes or the player does something else, **Then** it is discarded to the left the same way.
4. **Given** the end of setup, **When** the note preparing the Deck is thrown off, **Then** it looks the same as every other note's discard (one shared motion, not two).

---

### User Story 3 - A note that changes is a new card laid over the old one (Priority: P2)

When what the note says changes while it is showing (for example the result is followed by the Soak, or the Soak by the XP to spend), the change happens the way it would at a table: the new information is dealt in from the left as a new card and laid on top of the card already there. The cards build up into a small pile over the Encounter. The ones underneath stay down, a little uneven, so a sliver of their edges shows the pile growing. When the whole interaction is complete, the pile is discarded off to the left together.

**Why this priority**: The flow after an Enemy often goes result → Soak → XP. How those hand over to each other decides whether the sequence reads as one stack of cards or one card flickering.

**Independent Test**: Lose to an Enemy with XP to gain. Watch the handover from result to Soak to XP. Each new piece of information arrives as its own card, laid on top of the last, with no dimming in place. When the XP is spent, all the cards leave to the left together.

**Acceptance Scenarios**:

1. **Given** a note is showing, **When** its content changes to a different kind of information, **Then** the new information arrives on its own card dealt in from the left and laid on top of the card already there, never by the old card dimming and changing in place.
2. **Given** a new card has been laid on top, **When** the player looks at the Deck, **Then** the earlier cards are still there underneath, with a sliver of their edges showing, so the pile reads as cards stacked up.
3. **Given** several notes have been laid down one after another, **When** the interaction is complete, **Then** the whole pile is discarded off to the left together (the cards may leave a beat apart, but as one discard), no card is left behind, and the Encounter (or the next Encounter's card) is uncovered.
4. **Given** a pile of notes, **When** the player is done with the top one but the interaction is not complete, **Then** no card is discarded yet; the next card is laid on top.
5. **Given** a note only updates the numbers it already shows (for example the Soak meter filling, or XP being spent card by card), **When** the numbers change, **Then** the same card stays down and updates in place; no new card is dealt.

---

### User Story 4 - Reduced motion and skipping (Priority: P3)

With reduced motion on, notes do not fly or turn. They appear in place and leave by fading where they lie, as the setup note does today. Skipping or hurrying a sequence lands on the same settled state.

**Why this priority**: Needed for accessibility, but secondary to the motion itself.

**Independent Test**: Turn on reduced motion and play a set through result, Soak and XP. Each note fades in where it lies and fades out where it lies; nothing travels or rotates.

**Acceptance Scenarios**:

1. **Given** reduced motion is on, **When** a note comes on, **Then** it fades in at its resting place with no travel or rotation.
2. **Given** reduced motion is on, **When** a note is done with, **Then** it fades out where it lies.
3. **Given** a note is in flight, **When** the window size changes or the app goes to the background, **Then** the note finishes at once in its final state (lying down or gone).

---

### Edge Cases

- **Press and hold.** Pressing and holding the note pile still lifts it aside, the whole pile together, to show the Encounter under it, and letting go lays it back down. This is not a discard and does not use the discard motion.
- **A note arriving while the pile is leaving.** If a new note is needed while a pile is still flying off, the new card is dealt onto the bare Deck as the start of a new pile. Both are visible; neither stops halfway.
- **Refused moves.** A refused move's reason is laid on top of whatever is already down (or on the bare Encounter). When its moment passes or the player does something else, that refusal card alone is discarded, uncovering the pile under it. Pressing Play repeatedly without a Boost role does not stack up several refusal cards: the one lying there stays and its moment restarts.
- **Pile size.** Only a few notes build up in one interaction (result, Soak, XP, perhaps a step). The pile's visible edges stay within the Deck's margin however many cards are in it.
- **Zooming out.** When the Deck zooms out to the next Encounter, any pile still lying there is discarded to the left first (or as the zoom starts), never shrunk along with the card.
- **Undo.** Undoing a choice that brings back an earlier state brings its note back by dealing it in again; undoing past a note discards it.
- **Small windows and phones.** The flight from and to the left edge is short there, since the Deck sits near the screen's left edge. The card must still be seen entering and leaving, not popping.
- **Final Battle.** Notes over the Dragon Card follow the same rules.
- **Things that are not notes.** The Key Card reveal, drawn Hand cards and the zoom are not notes and keep their own motion (specs/014).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every note that comes onto the Deck (the result of a Play, a step to follow, the Soak, the XP to spend, a refused move's reason) MUST arrive from beyond the left edge of the Deck and come to rest exactly over the card or face it covers.
- **FR-002**: A note MUST look like a playing card throughout its arrival, its time on the Deck and its departure: the same width and height as the card it covers, the same rounded corners, a soft card shadow, and fully opaque while in flight.
- **FR-003**: A note in flight MUST turn slightly as it moves and MUST lie square once it lands.
- **FR-004**: When the player is done with a note, it MUST be discarded off to the left, turning a little as it goes, until it is past the Deck's left edge, with the same motion used today when setup ends.
- **FR-005**: A note leaving or arriving MUST NOT be cut off at the Deck's bounds while it crosses them.
- **FR-006**: The end-of-setup discard and every other note's discard MUST share one motion, so they look the same.
- **FR-007**: When a note's content changes to a different kind of information while it is showing, the new information MUST be dealt in from the left as a new card laid on top of the cards already down, never shown by the note dimming and changing in place.
- **FR-007a**: The cards under the top one MUST stay visible as a pile, with a sliver of their edges showing.
- **FR-007b**: When the interaction is complete, all the notes laid down during it MUST be discarded off to the left together. No card in the pile is discarded before then, except a refused move's reason (FR-009).
- **FR-008**: When a note's numbers update within the same kind of information (the Soak meter filling, XP being spent), the card MUST stay down and update in place.
- **FR-009**: A refused move's reason MUST be laid on top of the pile and discarded on its own when its moment passes, leaving the pile under it in place. At most one refused-move card MUST lie on the Deck at a time.
- **FR-010**: Pressing and holding the note pile MUST still lift it aside as one to show what is under it, and letting go MUST lay it back down, without discarding it.
- **FR-011**: With reduced motion on, notes MUST appear and leave by fading in place, with no travel or rotation.
- **FR-012**: A window resize or the app going to the background MUST finish any note motion at once in its final state.
- **FR-013**: The timing of when notes appear and are done with (what triggers them, how long a refused move's reason stays) MUST stay as it is today; only how they come and go changes.

### Key Entities

- **Note**: A card-sized piece of information laid over the Encounter on the Deck. Kinds: result, step (Fuse, Divert, Regroup, Deck preparation), Soak, XP to spend, refused move.
- **Note pile**: The notes laid down during one interaction, each on top of the last, discarded together when the interaction is complete.
- **Discard**: The motion that takes a note (or the whole pile) off the Deck, to the left, turning slightly, out past the Deck's edge.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the note kinds listed in FR-001 arrive from the left and leave to the left; none fades in or out in place or slides to the right (reduced motion excepted).
- **SC-002**: A player shown the post-Encounter sequence describes it as "cards being laid down and discarded" without prompting.
- **SC-003**: Side by side, the end-of-setup discard and the discard of a Play's result are indistinguishable in path, turn and duration.
- **SC-004**: At no frame of a note's arrival or departure is it partly transparent (outside reduced motion) or clipped at the Deck's edge.
- **SC-005**: Playing a full Region with notes dealt and discarded takes no more than 5% longer than today; dealing and discarding do not add waiting.

## Assumptions

- "Anything else that appears over the left-hand side of the encounters" means the note in all its kinds. The Key Card, drawn Hand cards and the Encounter zoom are not included.
- Notes arrive from the left, the same side they leave to, as the request says; the Deck is the leftmost thing on screen, so the card comes from off screen.
- The arrival and departure take about as long as the note's slide does today, so the game's pace is unchanged.
- Reduced motion keeps today's reduced-motion behaviour of the setup discard (fade in place).
- "The interaction is complete" means the moment the last note would be taken off today (for example, the XP is spent and play moves on to the next Encounter). Notes that today replace one another in place now stack instead.
- A refused move is its own short interaction, so its card is discarded alone (FR-009).
- Existing triggers for showing and clearing each note are unchanged (FR-013).
