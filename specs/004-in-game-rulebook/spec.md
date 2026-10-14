# Feature Specification: In-Game Rulebook

**Feature Branch**: `004-in-game-rulebook`

**Created**: 2026-10-14

**Status**: Draft

**Input**: User description: "c:\dev\dragons-of-etchinstone\reference\DOE_Rulebook.pdf create an in-game version of the rulebook, for reference so new players can learn how to play the game"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Learn the game from the title screen (Priority: P1)

A new player opens the game for the first time and has never seen the physical rulebook. From the title screen they open "How to Play" and read through the rules in order: what the goal is, what the cards show, how an Encounter plays out phase by phase, how Regions end, and how the Final Battle works. When they finish, or whenever they choose, they close the rulebook and are back on the title screen, ready to start a game.

**Why this priority**: This is the request. A player who cannot learn the rules inside the game has to find the printed rulebook elsewhere, and the game currently offers only a Glossary of individual terms, which explains words but not how a turn flows.

**Independent Test**: From the title screen, open the rulebook, read every section from first to last using only the rulebook's own navigation, close it, and confirm the title screen is unchanged.

**Acceptance Scenarios**:

1. **Given** the title screen is showing, **When** the player chooses How to Play, **Then** the rulebook opens at its first section.
2. **Given** the rulebook is open, **When** the player moves forward or back, **Then** the next or previous page is shown (moving into the next or previous section at a section's end), and the first and last pages make clear there is nothing before or after them.
3. **Given** the rulebook is open, **When** the player closes it, **Then** they return to the screen they opened it from with nothing about that screen changed.
4. **Given** the rulebook is open, **When** the player reads it in order, **Then** it covers, at minimum: the goal and how to win or lose; what Mage, Region and Dragon cards show; the five Encounter phases (Challenge, Action, Penalty, Upgrade, Cleanup) including Diverting, Hardships, Roles, Fusing, Enemy Abilities, Journey Perils, outcomes, Time Penalties, damage and Soaking, Knock Out, and Upgrading; the End of the Region; the Final Battle (Final Journey with Regrouping, Final Enemy); scoring; the four Ether elements; difficulty levels; and the alternate rules.

---

### User Story 2 - Look up a rule in the middle of a game (Priority: P1)

Partway through a Region, the player is unsure how Fusing works or what happens when they cannot Soak all the damage. They open the in-game menu, choose How to Play, jump straight to the relevant section from a list of contents, read it, and close the rulebook to find their game exactly where they left it.

**Why this priority**: The user asked for a reference, not only a tutorial. Players mostly need rules at the moment they are confused, which is mid-game. Without in-game access, the rulebook only helps before play starts.

**Independent Test**: Start a game, assign some cards to Roles without committing, open the rulebook from the in-game menu, jump to a section in the middle of the contents, close the rulebook, and confirm the Encounter, Hand and partly assigned Roles are unchanged.

**Acceptance Scenarios**:

1. **Given** a game is in progress, **When** the player opens the in-game menu, **Then** How to Play is offered alongside the existing options.
2. **Given** the rulebook is open, **When** the player opens the contents, **Then** every section is listed by name and choosing one shows that section directly.
3. **Given** the player has a partly assigned Action Set, **When** they open the rulebook and later close it, **Then** the game, including the partly assigned Action Set and any pending choices, is exactly as they left it.
4. **Given** the player closed the rulebook during a session, **When** they open it again in the same session, **Then** it reopens at the section they were last reading.

---

### User Story 3 - Rules that match what the digital game does (Priority: P2)

The printed rulebook spends many words on handling cards: rotating them to the right Level, placing discards behind the inactive Region card, shuffling without changing orientation, holding the Deck in the left hand. A player of the digital game never does any of this. The in-game rulebook explains each rule in terms of what the player decides and what the game does for them, so a reader is not left looking for a card to rotate.

**Why this priority**: The rules still teach the game if they are a faithful paraphrase of the printed book, so this is not required for a first version to be useful. It matters because physical-handling instructions confuse digital players and make the rulebook longer than it needs to be.

**Independent Test**: Read every section and confirm that no instruction asks the player to physically handle, orient, place or shuffle cards; wherever the printed rules describe such a step, the in-game text says what the game does automatically instead (or omits it when it has no bearing on play).

**Acceptance Scenarios**:

1. **Given** a section describes something the game handles automatically (Orienting cards, shuffling, drawing, discarding to the right pile, setting out Region and Dragon cards), **When** the player reads it, **Then** it states that the game does this, in one sentence or less.
2. **Given** a section describes a choice the player makes (Diverting, assigning Roles, Fusing, choosing where a Boost goes, Regrouping, choosing what to Upgrade, discarding a Reserve card against a Ranged Enemy), **When** the player reads it, **Then** it explains the choice and its consequences in full.
3. **Given** the printed rulebook mentions material not in this game (the DIZED tutorial app, the co-op variants and Challenge Mode, the Tracking Crystal), **When** the player reads the in-game rulebook, **Then** that material does not appear.

---

### User Story 4 - Pictures and links that connect the rules to the screen (Priority: P3)

While reading about Mage Cards, the player sees a card drawn the same way it appears in play, with each figure labelled (Level, Encounter icon, Hardship, Initiative, Basic and Enhanced Action, Boost, Armor, Upgrade Cost). While reading a section that mentions a term such as Narrow Victory or Ambush, they can press the term to see its Glossary explanation without leaving the section.

**Why this priority**: The rules can be learned from text alone, but the printed rulebook leans on annotated card diagrams, and the digital game already draws cards and has a Glossary. Reusing both makes the rulebook far easier to map onto what the player sees, but the text-only rulebook from Stories 1–3 is already useful without them.

**Independent Test**: Open the sections about Mage, Region and Dragon cards and confirm each shows a labelled example card matching how cards look in play; in any section, press a highlighted term and confirm its Glossary explanation appears and can be dismissed back to the same place in the section.

**Acceptance Scenarios**:

1. **Given** the player is reading the section about Mage Cards, Region Cards or Dragon Cards, **When** the section is shown, **Then** it includes an example of that card in the in-game style with each figure labelled by name.
2. **Given** a section mentions a term that has a Glossary entry, **When** the player presses that term, **Then** its Glossary explanation appears, and dismissing it leaves the player at the same position in the same section.
3. **Given** the outcome tables (Attack against HP, Move against MP, and the Final Battle tiers), **When** the player reads them, **Then** each is shown as a table or equivalent layout that pairs each result with its consequence.

---

### Edge Cases

- **Opened during the end-of-turn sequence**: if the player opens the menu while the short sequence showing an Encounter's results is playing, opening the rulebook does not skip, repeat or lose any part of the result.
- **Opened from the ending screen**: the rulebook is reachable (or not) from the game's ending screen consistently with the title screen; closing it returns there.
- **Small screens**: on the smallest supported window sizes, every section is readable without text being cut off; long sections are split into pages rather than overflowing or scrolling.
- **Keyboard and touch**: the player can open, navigate (next, previous, contents, scroll) and close the rulebook using touch, mouse or keyboard alone, matching how the rest of the game is played.
- **Reduced motion**: with reduced motion on, moving between sections uses no animation beyond fades.
- **Glossary term inside the rulebook links to a term with no entry**: such a term is shown as plain text, never as a link that does nothing.
- **Rules disagree with the game**: if the rulebook text and the game's behaviour ever differ on a rule, this is treated as a defect in one of them; the rulebook never describes a rule differently from how the game resolves it.

## Requirements *(mandatory)*

### Functional Requirements

**Access**

- **FR-001**: The title screen MUST offer a How to Play option that opens the rulebook.
- **FR-002**: The in-game menu MUST offer a How to Play option that opens the rulebook without ending, restarting or otherwise changing the game in progress.
- **FR-003**: Closing the rulebook MUST return the player to the screen they opened it from, with that screen's state unchanged.
- **FR-004**: Within a single session, reopening the rulebook MUST show the section the player was last reading.

**Navigation**

- **FR-005**: The rulebook MUST be divided into named sections presented in a fixed reading order that follows the order of play: overview and goal, the cards, setup, an Encounter's five phases, End of the Region, the Final Battle, scoring, Ether elements, difficulty and alternate rules.
- **FR-006**: Players MUST be able to move to the next and previous page from any page, crossing into the neighbouring section at a section's first or last page.
- **FR-007**: Players MUST be able to open a contents list showing every section by name and jump directly to any of them.
- **FR-008**: The rulebook MUST show which section the player is in and where it sits in the whole (for example, "6 of 14").
- **FR-009**: Sections longer than one screen MUST be divided into pages that each fit the screen whole, with the page position shown (for example, "page 2 of 3"); nothing in the rulebook scrolls, matching the rest of the game, and all navigation controls stay in view on every page.
- **FR-010**: All rulebook navigation MUST be usable by touch, mouse and keyboard.

**Content**

- **FR-011**: The rulebook MUST cover every rule from the printed rulebook that the game implements, including at minimum the topics listed in User Story 1, Acceptance Scenario 4.
- **FR-012**: The rulebook text MUST be written in this project's own words, checked against the printed rulebook for accuracy, and MUST NOT reproduce the printed rulebook's text or page layout verbatim.
- **FR-013**: Every rule stated in the rulebook MUST agree with how the game resolves that rule.
- **FR-014**: Where the printed rules describe physical card handling the game performs automatically, the rulebook MUST say briefly that the game does it, or omit it if it has no bearing on the player's decisions.
- **FR-015**: Every decision the player makes during play (Diverting, assigning Roles, Fusing, directing the Boost, Regrouping, Upgrading, and discarding the Reserve card to ignore a Ranged Enemy) MUST be explained along with its trade-offs as described in the printed rulebook.
- **FR-016**: The outcome rules (Attack against HP, Move against MP, Final Journey MP Tiers, Final Enemy HP Tiers) MUST be presented so each result is paired with its consequence.
- **FR-017**: Every Hardship (Ambush, Hazards, Night Travel, Storm), Enemy Ability (Freeze, Poison, Ranged, Slow) and Journey Peril (Steep, Treacherous) MUST be described.
- **FR-018**: All six difficulty levels and both alternate rules (Cavalier, Glass Cannon) MUST be described, with a note of where in the game they are chosen.
- **FR-019**: The rulebook MUST NOT include material for features the game does not have (the DIZED tutorial app, co-op variants, Challenge Mode, the Tracking Crystal).
- **FR-020**: The rulebook MUST use the same names for icons, terms and figures as the rest of the game, so a term read in the rulebook is the term seen on screen.
- **FR-021**: The rulebook MUST credit the original game's designer and publisher and state that the rules belong to them, consistent with the project's existing attribution.

**Presentation (P3)**

- **FR-022**: The sections on Mage, Region and Dragon cards SHOULD each include an example card drawn as it appears in play, with every figure labelled by name.
- **FR-023**: Terms in the rulebook that have a Glossary entry SHOULD be pressable to show that entry in place, and dismissing it MUST return the player to the same position in the section.
- **FR-024**: Icons that appear in the game (Ether elements, Attack, Move, HP, MP, Time Penalty, XP, Armor, Boost, Initiative, Hardships, Abilities, Perils) SHOULD appear alongside their names in the rulebook text.

**General**

- **FR-025**: The rulebook MUST be available without a network connection.
- **FR-026**: The rulebook MUST be readable at every window size the game supports, with no text cut off.
- **FR-027**: Moving between sections MUST respect the game's motion setting.

### Key Entities

- **Rulebook**: The complete set of rules shown in the game, as an ordered list of sections, with an attribution to the original game's creators.
- **Section**: A named, self-contained part of the rules (for example "The Action Phase" or "The Final Enemy"), with a position in the reading order, a body of text, and optionally tables, labelled card examples and Glossary-linked terms.
- **Reading position**: The section and page the player was last viewing in the current session, used when the rulebook is reopened.
- **Glossary entry** (existing): A short explanation of one term or icon. The rulebook links to these rather than repeating them.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player who has never seen the printed rulebook can, after reading the in-game rulebook, start a game and complete their first Encounter without consulting any outside source.
- **SC-002**: From any point in a game, a player can reach any named rule section in 3 actions or fewer (for example: menu, How to Play, choose from contents).
- **SC-003**: Opening and closing the rulebook mid-game changes nothing about the game in 100% of cases, including partly assigned Action Sets and pending Upgrade choices.
- **SC-004**: 100% of the topics listed in User Story 1, Acceptance Scenario 4 are covered, verified by checking each against the contents.
- **SC-005**: A review of every section against the game's behaviour finds no rule described differently from how the game resolves it.
- **SC-006**: No section contains an instruction to physically handle, orient, place or shuffle cards.
- **SC-007**: Every section is fully readable, with no clipped text and all controls reachable, at every window size in the game's layout matrix.
- **SC-008**: Reading the whole rulebook start to finish takes a typical reader no more than about 15 minutes.

## Assumptions

- **Audience**: The primary reader is a solo player new to Dragons of Etchinstone who has the digital game but not the printed rulebook. Experienced players use it for lookups.
- **Reference, not tutorial**: This is a readable reference. An interactive, step-by-step tutorial that plays alongside a real game is out of scope.
- **Own words**: Because the rules text belongs to Chip Theory Games and the printed rulebook is kept out of the repository, the in-game rulebook is a paraphrase written for this project and checked against the printed book, the same approach the existing Glossary takes. The printed book's illustrations are not reused; card examples are drawn with the game's own card visuals.
- **Source of truth**: The printed rulebook (version 1.0) defines the rules; the game's rules engine is expected to already match it. Any mismatch found while writing the rulebook is reported as a defect rather than written around.
- **Glossary stays**: The existing Glossary remains as the quick, term-by-term explanation. The rulebook complements it and links to it rather than replacing it.
- **Reading position**: Remembering the last section read is for the current session only; the rulebook opens at the first section in a new session.
- **Ending screen**: Access from the ending screen is optional for the first version; if offered, it behaves like access from the title screen.
- **Language**: English only, matching the rest of the game.
- **Lore**: The printed rulebook's opening story may be kept as a short introduction but is not required.
