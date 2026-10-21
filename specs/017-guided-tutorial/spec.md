# Feature Specification: Guided Tutorial (Learn to Play)

**Feature Branch**: `017-guided-tutorial`

**Created**: 2026-10-21

**Status**: Draft

**Input**: User description: "we need an onboarding process which teaches user how to play the game. we would have a dedicated deck order for this so the same cards are always shown and utilized, an opioninated card they should select for upgrading during set up, they should be able to win their first hand, they should get a narrow victory in the second hand, and lose a hand. they should be required to select rodving for this process. we need to highlight the key card, ether, journey vs battles,  explanation that the deck is used for both battles and for determining when the user finishes a given region before moving on, ect."

## Overview

A new player today meets the full game cold: a random Deck, a choice of four dragons, and
rules that are only explained in How to Play. This feature adds a guided tutorial: a
short series of lessons played on the normal play screen against the normal rules.

The lessons are not one continuous game. Each lesson is a staged Encounter: it sets out
its own table (the Region, the Key Card, the Hand, the Deck and every card's Level),
chosen so that the guided play gives the result the lesson is about. Lessons do not carry
anything over from one to the next, so each can be written, tested and changed on its own,
and every player sees the same cards and the same outcomes.

The lessons, in order: setting out with Rodving and choosing a card to upgrade; a
Victory against an enemy; a Narrow Victory on a Journey, paid in time; a Loss, with damage
to Soak; a Victory won by Fusing two cards; and the end of a Region, when the Deck runs
low. A short message at each step points at the part of the screen it describes (the Key
Card, a card's Ether, the Encounter's figures, the Deck) and explains it at the moment it
matters. Together the lessons show both kinds of Encounter (enemies and Journeys), both
ways things go wrong (damage that is Soaked and time that is paid from the Deck), and the
Deck's double role as the source of every Encounter and as the clock that ends the Region.

## Clarifications

### Session 2026-10-21

- Q: At which point in the tutorial should the player be required to Fuse two cards? → A: A fourth scripted Hand after the Loss, which can only be won with a Fuse (a Victory).
- Q: Must the tutorial be one continuous game played from a fixed Deck order? → A: No. It is a series of unconnected staged Encounters, each dealt the cards that give its intended outcome.
- Q: Should players be able to pick any single lesson from a list, or only play the lessons in order from the start? → A: In order the first time, resuming at the first unfinished lesson; a lesson list lets the player replay any lesson already finished.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lesson 1: set out with Rodving (Priority: P1)

A player who has never played opens the game and chooses to learn how to play. The first
lesson takes them through setting out: Rodving is the dragon (the others are shown but
cannot be chosen, with a line saying why), the difficulty is fixed, and on the setup
screen one card among those offered is marked as the recommended upgrade, with a short
reason for choosing it. The player chooses it and the lesson ends.

**Why this priority**: It is the player's first contact with the tutorial and the only
lesson that covers the screens before play.

**Independent Test**: Start the tutorial from the landing page and confirm that only
Rodving can be chosen, and the setup offers the same cards every time with one marked as
recommended and accepted.

**Acceptance Scenarios**:

1. **Given** the landing page, **When** the player chooses Learn to Play, **Then** the
   dragon choice opens with Rodving selected and the other three dragons unavailable,
   each with a line saying the tutorial is played against Rodving.
2. **Given** the tutorial's setup screen, **When** it opens, **Then** the same cards are
   offered as on every other tutorial run, one of them is marked as the recommended
   upgrade, and a message explains why that card is the better choice.
3. **Given** the tutorial's setup screen, **When** the player tries to confirm a
   different card, **Then** the choice is not accepted and the message points back to
   the recommended card.

---

### User Story 2 - Learn the table: Key Card, Ether, the Encounter and the Deck (Priority: P1)

At the start of the first Encounter lesson, the tutorial walks the player around the play
screen, one thing at a time, each one lit while the rest is dimmed: the Deck, the Key Card
on top of it and the strip that names the Encounter, the Encounter itself and its figures,
a Mage Card's Ether (its colour and mark) and what Ether changes, and the three Roles of
the Action Set (Spell, Element, Boost) and the Reserve.

**Why this priority**: These are the ideas the game cannot be played without, and the
ones the user named explicitly (Key Card, Ether, the Deck).

**Independent Test**: Open the Victory lesson and step through the introductory messages;
confirm each one lights the part of the screen it describes and that the player can go
back to the previous message.

**Acceptance Scenarios**:

1. **Given** the Victory lesson's table is set out, **When** the Key Card message is
   shown, **Then** the Key Card and its Encounter strip are lit, the rest of the screen
   is dimmed, and the message explains that the top card of the Deck decides the next
   Encounter.
2. **Given** the Ether message is shown, **When** the player reads it, **Then** a card in
   the Hand is lit with its Ether mark called out, and the message explains that an
   Element whose Ether matches the Spell's enhanced action gives the enhanced value.
3. **Given** a tutorial message that follows another message with no action between
   them, **When** the player chooses Back, **Then** the previous message and its
   highlight return; on the first message after an action, Back is not offered.
4. **Given** any tutorial message, **When** the player presses a term in it (for example
   Key Card or Ether), **Then** the existing Glossary explanation for that term opens.

---

### User Story 3 - Lesson 2: win a fight (Priority: P1)

The lesson's Encounter is an enemy. The tutorial tells the player which card to make the
Spell, which the Element and which the Boost, and where to put the Boost, explaining each
choice (the matching Ether for the enhanced Attack, Initiative against the enemy's, the
Boost). The play is a Victory: the enemy is beaten, no damage is taken, and the XP it
earns is spent in the Upgrade Phase on a card the tutorial points to.

**Why this priority**: It teaches the core loop (build an Action Set, commit, see the
result, Upgrade, Cleanup) with nothing going wrong.

**Independent Test**: Play the lesson following the guidance and confirm the result is a
Victory with no damage, the XP is earned and spent, and Cleanup draws the Hand back up to
four.

**Acceptance Scenarios**:

1. **Given** the lesson's Encounter, **When** it is revealed, **Then** it is an enemy,
   and a message explains enemy figures (HP, Initiative, Attack, Armor, XP).
2. **Given** the player is building the Action Set, **When** they place the cards and
   Boost as the guidance says, **Then** the result shown before committing is a
   Victory.
3. **Given** the player places a card in a Role other than the one asked for, **When**
   they try to commit, **Then** the commit is held back and the message says which card
   belongs where, and why.
4. **Given** the Victory, **When** the Upgrade Phase opens, **Then** the tutorial points
   to the card to Upgrade and explains that unspent XP is lost.
5. **Given** Cleanup, **When** the new Hand is drawn, **Then** a message points out that
   the Reserve stayed in the Hand and the Deck is now smaller.

---

### User Story 4 - Lesson 3: a Narrow Victory on a Journey, paid in time (Priority: P2)

The lesson's Encounter is a Journey. The tutorial explains how a Journey differs from a
fight: it is crossed with Move instead of Attack, it has no Initiative and no Early
Damage, and what goes wrong costs time instead of damage. With the cards dealt, the best
the player can do is a Narrow Victory: they earn the XP but pay the Time Penalty, and the
tutorial shows the cards that leave the top of the Deck for it, explaining that the Deck
is also the Region's clock.

**Why this priority**: This is where the two kinds of Encounter are contrasted and where
the Deck's second role (the clock that ends the Region) is first shown, both named by the
user.

**Independent Test**: Play the lesson following the guidance and confirm it is a
Journey, the result is a Narrow Victory, XP is earned, and the Time Penalty discards that
many cards from the top of the Deck while a message explains why.

**Acceptance Scenarios**:

1. **Given** the lesson's Encounter, **When** it is revealed, **Then** it is a Journey,
   and a message contrasts it with a fight (Move and MP instead of Attack and HP; Time
   Penalty instead of Combat Damage).
2. **Given** the guided Action Set, **When** it is committed, **Then** the result is a
   Narrow Victory: the Move reaches at least half the MP but not all of it.
3. **Given** the Time Penalty is paid, **When** cards leave the Deck, **Then** the Deck
   is lit and a message explains that every card lost from the Deck brings the end of
   the Region closer.

---

### User Story 5 - Lesson 4: a Loss, and Soaking the damage (Priority: P2)

The lesson's Encounter cannot be won with the Hand dealt. The tutorial says so, explains
that a Loss is part of the game, and has the player commit anyway. The enemy's damage
must be Soaked: the tutorial explains Armor, the doubling when the Armor's Ether matches
the damage, and Downgrading, and points to the cards to Downgrade.

**Why this priority**: Losing and recovering is the rest of the core loop; without it a
new player meets Soak for the first time unguided.

**Independent Test**: Play the lesson following the guidance and confirm the result is a
Loss, the Penalty Phase asks for a Soak, and the guided Soak is accepted and Downgrades
the named cards.

**Acceptance Scenarios**:

1. **Given** the lesson's Encounter, **When** it is revealed, **Then** a message explains
   that this one cannot be won and that Diverting exists for Encounters like it (with
   Divert itself not required).
2. **Given** the guided Action Set, **When** it is committed, **Then** the result is a
   Loss and damage is due.
3. **Given** the Penalty Phase, **When** the Soak message is shown, **Then** each Hand
   card's Armor is called out, the cards to Downgrade are lit, and choosing them settles
   the damage.
4. **Given** the Soak is done, **When** the tutorial moves on, **Then** a message explains
   that a Level 1 card that is Downgraded is Trashed for good.

---

### User Story 6 - Lesson 5: Fuse two cards to win (Priority: P2)

The lesson's Encounter cannot be won with an ordinary Action Set from the Hand dealt, but
it can be won by Fusing. The tutorial explains Fuse (two cards of the same Ether become
one, which fills a Role and counts as any Ether the player chooses; it needs a full Hand;
both cards are discarded at Cleanup) and guides the player to Fuse the named pair, pick
the named Ether and build the Action Set. The result is a Victory, after the Loss.

**Why this priority**: Fusing is the one move that changes which Ether a card brings,
and new players rarely find it on their own.

**Independent Test**: Play the lesson following the guidance and confirm that no Action
Set without a Fuse would win, the guided Fuse is accepted, and the result is a Victory.

**Acceptance Scenarios**:

1. **Given** the lesson's Encounter with a full Hand, **When** it is revealed, **Then** a
   message says it cannot be won as the Hand stands and points to two cards of the same
   Ether.
2. **Given** the Fuse message, **When** the player Fuses the named pair and picks the
   named Ether, **Then** the fused card's Ether matches the Spell's enhanced action and
   the result shown before committing is a Victory.
3. **Given** the player commits without Fusing, or Fuses a different pair or Ether,
   **When** they try to commit, **Then** the commit is held back and the message says
   what to change.
4. **Given** the Victory, **When** Cleanup runs, **Then** a message points out that both
   fused cards were discarded, so Fusing costs a card that could have been kept.

---

### User Story 7 - Lesson 6: the Deck runs low and the Region ends (Priority: P2)

The lesson's table is set out late in a Region, with only a few cards left in the Deck.
The tutorial points to the Deck and the Hand and counts them. The player plays a guided
Encounter; at Cleanup, the Hand and Deck together hold fewer than five cards, so the
Region ends: every card that is not Trashed is gathered and shuffled, a new Hand is dealt,
and the next Region's card is set out. The tutorial explains each of these as it happens.

**Why this priority**: The user asked for the Deck's role in ending a Region to be
explained; staging it lets the player see it happen instead of only reading about it.

**Independent Test**: Play the lesson following the guidance and confirm that Cleanup
ends the Region, Region 2 is set out with the cards keeping their Levels, and the
messages explain why.

**Acceptance Scenarios**:

1. **Given** the lesson's table, **When** it is set out, **Then** the Deck is lit and a
   message says how many cards are left and that a Region lasts while the Hand and Deck
   together can give a fresh Hand and a Key Card (five cards).
2. **Given** the guided play is finished, **When** Cleanup leaves fewer than five cards
   in Hand and Deck, **Then** the Region ends and a message explains why.
3. **Given** the Region has ended, **When** Region 2 is set out, **Then** a message
   explains that the cards were gathered and shuffled, keep their Levels, that Trashed
   cards do not come back, and that after Region 4 comes the Final Battle.

---

### User Story 8 - Finish the tutorial (Priority: P3)

After the last lesson, the tutorial shows a summary of what was learned and what a full
game holds (four Regions, then the Final Journey and the Final Enemy, the dragon). The
player can then choose what to do next.

**Why this priority**: The tutorial needs a clear end, but the teaching value is in the
lessons before it.

**Independent Test**: Finish the last lesson and confirm the summary is shown, and each
choice offered after it leads where it says.

**Acceptance Scenarios**:

1. **Given** the last lesson is finished, **When** the summary is shown, **Then** it names
   what was covered and what a full game holds.
2. **Given** the summary, **When** the player chooses to leave, **Then** the landing page
   opens and the tutorial is marked as completed.
3. **Given** the tutorial is completed, **When** the player chooses Learn to Play again,
   **Then** the lesson list opens with all six lessons finished and any one can be
   replayed.

---

### Edge Cases

- The player leaves a lesson part way (menu, quit, closing the app): that lesson is not
  marked finished, and Learn to Play resumes at the start of it; lessons already finished
  stay finished.
- The player skips the tutorial: a Skip choice is available at every message; it ends the
  tutorial and returns to the landing page without marking the current lesson finished.
- The player replays a finished lesson from the lesson list: it plays exactly as the first
  time, and finishing it again changes nothing; leaving it part way does not unmark it.
- The window is resized or rotated mid-message: the highlight follows the element it
  points at, and the message stays readable at every supported window size.
- Reduced motion is on: every highlight and every pointed-at element has a still form,
  as the rest of the game does.
- The player opens How to Play, the Glossary or a card's inspect view mid-lesson: the
  tutorial waits and resumes on the same message when it is closed.
- The player taps a card or control the current step is not about: the tap is ignored or
  explained, and never changes the lesson's outcome.
- A lesson's table is set out partway through a game (cards in the discard pile, a Deck
  shorter than sixteen, cards at different Levels): the screen draws it as it would the
  same moment in a real game.
- No tutorial lesson may appear in the player's Records or Leaderboard.
- A future change to card data or rules breaks a lesson (its guided play no longer gives
  the intended result): this must be caught by an automated check, not by a player.

## Requirements *(mandatory)*

### Functional Requirements

**Entry**

- **FR-001**: The landing page MUST offer a Learn to Play entry that starts the tutorial,
  alongside the existing How to Play, Records and Play.
- **FR-002**: On the first launch (no lesson finished and no game ever played), the
  game MUST offer the tutorial before a regular game, and the player MUST be able to
  decline it.
- **FR-003**: When no lesson is finished, Learn to Play MUST start Lesson 1 directly.
  Once any lesson is finished, Learn to Play MUST open the lesson list (FR-003a), whose
  primary action starts the first unfinished lesson. Lessons MUST be played in order the
  first time; a lesson becomes available only once the one before it is finished.
- **FR-003a**: Learn to Play MUST also offer a list of the six lessons, showing which are
  finished, from which any finished lesson can be replayed at any time; unfinished lessons
  after the first unfinished one MUST be shown as not yet available.

**Lessons**

- **FR-004**: The tutorial MUST be a fixed sequence of lessons: (1) setting out; (2) a
  Victory against an enemy; (3) a Narrow Victory on a Journey with a Time Penalty; (4) a
  Loss with damage to Soak; (5) a Victory won by Fusing; (6) the end of a Region.
- **FR-005**: Each Encounter lesson MUST start from its own fixed table (the Region, the
  Key Card, the Hand, the order of the Deck, the discard pile and every card's Level),
  the same on every run, and MUST NOT depend on what happened in an earlier lesson.
- **FR-006**: From that table, every lesson MUST be played under the game's normal rules;
  the staging chooses the cards, it does not change what they do.
- **FR-007**: Each lesson's table MUST give the outcome the lesson is about:
  - Lesson 2: the guided Action Set beats an enemy outright (Victory, no damage).
  - Lesson 3: the guided Action Set crosses a Journey only narrowly (Narrow Victory with a
    Time Penalty), and no Action Set from the Hand dealt does better.
  - Lesson 4: no Action Set from the Hand dealt wins (Loss, with damage to Soak that the
    Hand can Soak without being Knocked Out).
  - Lesson 5: a full Hand holding two cards of the same Ether, against an Encounter that no
    Action Set without a Fuse can win and the guided Fuse wins (Victory).
  - Lesson 6: after the guided play, Cleanup leaves fewer than five cards in Hand and
    Deck, so Region 1 ends and Region 2 is set out.

**Setting out (Lesson 1)**

- **FR-008**: In the tutorial, Rodving MUST be the only dragon that can be chosen; the
  other dragons MUST be visibly unavailable with a line saying why.
- **FR-009**: The tutorial MUST NOT ask for a difficulty or alternate rules: the
  difficulty screen is skipped, no alternate rule is on, and Lesson 1 uses a setup of its
  own (five cards offered, one raised to Level 3) that belongs to no difficulty. No lesson
  is ever shown or recorded under a difficulty.
- **FR-010**: The tutorial's setup MUST offer the same cards on every run, mark one as the
  recommended upgrade with a short reason, and accept only that card.

**Guidance**

- **FR-011**: Each tutorial step MUST show a short message and light the part of the
  screen it describes, dimming the rest, and MUST let the player Skip the tutorial. The
  player MUST be able to go Back one message at a time through the messages shown since
  their last action; Back never goes past an action already taken, because a move made
  in the game cannot be undone.
- **FR-012**: The tutorial MUST explain, each at the moment it first matters: the Deck;
  the Key Card and its Encounter strip; Hardships; Ether and enhanced actions; the
  Spell, Element and Boost Roles and the Reserve; enemy figures and Initiative; Victory,
  Narrow Victory and Loss; Journeys and how they differ from fights; the Time Penalty
  and the Deck as the Region's clock; when and how a Region ends; Soak, Armor, Downgrade
  and Trash; Upgrade and unspent XP; Cleanup; Fuse (same-Ether pair, chosen Ether, full
  Hand needed, both cards discarded); and that Divert exists.
- **FR-013**: In each Encounter lesson, the tutorial MUST say which card goes in which
  Role (and, against an enemy, where the Boost goes; in Lesson 5, which pair to Fuse and
  which Ether to choose) and why, and MUST hold back a commit that differs from the
  guided Action Set or Fuse, saying what to change.
- **FR-014**: During the guided Soak and Upgrade steps, the tutorial MUST point to the
  cards to choose and MUST hold back a different choice, saying what to change.
- **FR-015**: Terms in tutorial messages MUST open the existing Glossary entries when
  pressed.
- **FR-016**: Tutorial messages MUST meet the same minimum text size and tap size as the
  rest of the interface, and MUST be readable and pointed correctly at every supported
  window size and with reduced motion on.

**Ending and records**

- **FR-017**: After the last lesson, the tutorial MUST show a summary and let the player
  leave to the landing page.
- **FR-018**: Each lesson MUST be marked finished when its last step is reached, and the
  tutorial MUST be marked completed once all six are finished and the summary is shown;
  these marks MUST persist between sessions.
- **FR-019**: Tutorial lessons MUST NOT be saved to Records, the Leaderboard or any play
  history.
- **FR-020**: An automated check MUST play every lesson's guided moves from its table
  against the real rules and fail if any lesson stops giving its intended outcome.

### Key Entities

- **Lesson**: one step of the tutorial. For an Encounter lesson: the fixed table it starts
  from (Region, Key Card, Hand, Deck order, discard pile, card Levels), the intended
  outcome, and its ordered steps. For Lesson 1: the dragon, difficulty, setup offer and
  recommended card.
- **Tutorial Step**: one message, the part of the screen it lights, and what the player
  must do to move on (read and continue, or a specific action such as a guided Action Set,
  Fuse, Soak or Upgrade).
- **Tutorial Progress**: which lessons are finished and whether the tutorial has been
  completed, kept between sessions. The first unfinished lesson is where Learn to Play
  resumes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On 100% of tutorial runs, every lesson's table and its outcome (Victory,
  Narrow Victory, Loss, Victory by Fuse, Region end) are identical.
- **SC-002**: A new player can complete the whole tutorial, from Learn to Play to the
  summary, in under 10 minutes.
- **SC-003**: After the tutorial, a player can name without help what the Key Card does,
  what matching Ether gives, how a Journey differs from a fight, and what ends a Region
  (checked in informal play-testing: at least 4 of 5 testers answer all four).
- **SC-004**: Every one of the concepts listed in FR-012 is explained by at least one
  tutorial message, and every message lights the element it describes at every
  supported window size.
- **SC-005**: Zero tutorial lessons appear in Records or the Leaderboard.

## Assumptions

- The tutorial runs on the existing play screen and setup screens; it adds guidance on
  top of them rather than a separate set of screens.
- "Win the first hand, narrow victory in the second, lose a hand" is read as Lessons 2,
  3 and 4 in that order; Lesson 5 (Fuse) and Lesson 6 (Region end) follow.
- The setup lesson's choice does not carry into the Encounter lessons, since each sets
  out its own table. The exact difficulty and number of setup picks are settled in
  planning, as long as the recommended card is the one choice the player is steered to.
- All Encounter lessons are played against Rodving in Region 1 (Lesson 6 moves on to
  Region 2), so the dragon never needs to be fought in the tutorial.
- Divert, Hardships, enemy Abilities and Journey Perils are explained only where a
  lesson's table brings them up; Divert is mentioned in the Loss lesson but not required.
  The Final Battle (including Regroup) is left to How to Play.
- The tutorial text is written for this project in its own words, like How to Play, and
  uses the same terms as the Glossary.
