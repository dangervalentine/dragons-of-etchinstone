# Feature Specification: Raised Stone and the Math in Plain Sight

**Feature Branch**: `006-etched-stone-polish`

**Created**: 2026-10-15

**Revised**: 2026-10-15, after the stage 2 review (see Clarifications)

**Status**: Draft (revision 2)

**Input**: User description: "Board, zone and UI personality polish (assessment: .specify/assessments/board-ui-polish/decision.md, verdict go). Problem: Dragons of Etchinstone plays correctly but feels like a generic dark app — static between moments, spending screen space restating information — and needs an identity of its own, life, and space that earns its place, across every screen. Approach: \"Etched Stone and Ether Rifts\" — the world as carved dark stone with zones read as engraved places; Ether rift light tinted by the current Encounter's Ether glowing through seams for each Region's and fight's mood; ambient life (shimmering seams, drifting motes, zones lighting when relevant); lore framing per screen (title as the Tower / The Tear, setup as the elders' proclamation, ending, rulebook and overlays as stone slabs and scrolls). Staged: (1) space — shrink the \"which card for which role\" area above the Hand to what it needs, remove empty/dead zones; (2) play-screen style frame approved by the owner against the current screenshot before rollout (exit point); (3) rollout to Final Battle, title, setup, rules, ending and overlays. Out of scope: rules, card data, balance, new content, portrait, new platforms, music and sound, a light/parchment palette, publisher art or trade dress, redrawing creature and dragon silhouettes, formal device benchmarking as a gate. Success: owner prefers the after in a side-by-side of every screen; less screen share restating information during card selection; no zone with a large unused area in standard screenshot states; owner can name what moves or responds while idle and after each action; ui_check, layout-matrix and contrast checks still pass; no visible stutter on web and Android emulator."

## Context

Features 001 and 005 made the game legible and gave its cards real depth and Ether
character. Around the cards, every screen was still a set of identical rounded dark
panels on a near-black background. The game read as a competent dark-themed app,
not a game set in Vale. The assessment in `.specify/assessments/board-ui-polish/`
found three problems: no identity, space that does not earn its place, and a static
board.

The first version of this spec answered with carved stone lit by Ether rifts. At the
stage 2 review the owner kept part of it and redirected the rest:

- **Kept**: strong, raised, chamfered boxes on a plain stone ground. Every zone of the
  play screen reads as a solid block.
- **Set aside**: glowing cracks, rift light, drifting motes and other generated
  effects. They "look like early 2000's flash animation".
- **Wanted instead**:
  - Flat lines and a consistent, flat pattern for the ground.
  - A bigger change to the layout, so the player sees the game's arithmetic happen.
    A card placed in a role sends its number up into that role's slot, and a box
    shows the numbers adding up to the result, including whatever a Hardship or
    ability changes.

The role rail built in the first stage (compact tokens with no names) is replaced
by full-size role slots that carry the numbers. The space it saved is recovered
another way: the secondary actions (Fuse, Divert, Regroup) move up beside the
slots, and the band of buttons below the Hand goes.

This feature changes presentation only. It does not change the rules, the steps of
play, or what the player can do in each step.

## Clarifications

### Session 2026-10-15 (stage 2 review)

- Q: Approve the carved stone with Ether light in the cracks? → A: No. Drop the glowing
  cracks, rift light and motes. Keep strong raised boxes. Use flat lines, perhaps a
  consistent pattern generated in ComfyUI.
- Q: What should replace the compact role rail? → A: Full-size role slots, with the
  secondary actions moved up beside them, as in the owner's reference
  (`~/Downloads/unnamed-2.png`). Pressing a card sends its number (for example the
  Spell's damage) up into its slot.
- Q: What should the box beside the Encounter show? → A: The math: each number as it
  adds up to the total, with the changes made by Hardships or anything else, and the
  result.
- Q: "The format playing cards are actually printed in": both Levels on one face, or
  printed proportions? → A: Printed proportions only. Asked what is off today, given
  the shape already matches the printed cards (about 0.72): nothing. The cards stay
  as they are, and the requirement is dropped.
- Q: Where may the ground pattern be generated? → A: With ComfyUI, on this Mac.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Numbers that go where they count (Priority: P1)

Above the Hand sit the role slots of the Action Set: Spell, Element and Boost (and
the second set's in the Final Battle). Each is a full-size raised box. When the
player taps a card, the number that card gives in that role rises from the card into
its slot:
- the Spell's damage or movement (the enhanced value when the Ether matches);
- the Element's Ether and Initiative;
- the Boost's bonus.

The slot then shows that number large, with what it counts toward (Attack, Move,
Initiative), so the player reads the set as numbers rather than card names. The
secondary actions (Fuse, Divert, Regroup, Give up Reserve, Cancel) sit in a column
beside the slots. The row of buttons under the Hand is gone, and the Hand takes its
room.

**Why this priority**: It is the layout change the owner asked for by name. It turns
the role area from a list of names into the first step of the arithmetic, and it is
the frame the math box (User Story 2) reads from.

**Independent Test**: Place a Spell, an Element and a Boost one by one. Each time, a
number visibly travels from the card to its slot and stays there, large. Confirm
the slots show numbers, not card names, and that Fuse and Divert are beside the
slots, with no button row under the Hand.

**Acceptance Scenarios**:

1. **Given** no card is placed, **When** the play screen shows an Action Set being
   built, **Then** each role slot names its role, the slot the next card fills is
   marked, and the secondary actions stand beside the slots.
2. **Given** the player taps a card, **When** it is placed in the Spell slot, **Then**
   the Spell's value for this Encounter rises from the card into the slot. That is
   the enhanced value if the Element's Ether already matches, else the basic value.
   The slot keeps showing it, with the Attack or Move icon.
3. **Given** the Element is placed and its Ether makes the Spell's enhanced action
   apply, **When** the Element lands, **Then** the Spell slot's number changes to
   the enhanced value, visibly.
4. **Given** the Boost is placed, **When** it lands, **Then** its bonus shows in its
   slot with what it adds to (Attack or Initiative against an Enemy, Move on a
   Journey). The Attack-or-Initiative choice is still made from the Boost slot.
5. **Given** a placed card, **When** the player taps its slot or the card, **Then**
   the card is taken back, its number leaves the slot, and the totals update.
6. **Given** the Final Battle's two Action Sets, **When** cards are placed, **Then**
   both sets' slots show their numbers, and the secondary actions still fit beside
   them.
7. **Given** reduced motion is on, **When** a card is placed, **Then** its number
   appears in the slot at once, without travelling.
8. **Given** the minimum window size, **When** any building state is shown, **Then**
   the Hand cards are no smaller than today, and nothing overlaps or is cut off.

---

### User Story 2 - The math, shown (Priority: P2)

The box beside the Encounter shows the sum the game is doing. Each line is a term:
the Spell's value, the Boost, and each change made by a Hardship, an Enemy's
ability or Armor, or the Reserve. Each term has its sign and its source, and the
lines add up to a total set against the target. Against an Enemy there is a second
line for Initiative against the Enemy's. Below the sums sit the verdict and its
consequences (XP, damage, time). As cards are placed, terms appear and the totals
count to their new value. A player who wonders why a number came out as it did
finds the answer in the box.

**Why this priority**: It answers the owner's request to see "the math involved",
including "the alterations caused by hardships". It builds on the slot numbers
from User Story 1.

**Independent Test**: Build an Action Set against an Enemy with Armor, on a Journey
under Night Travel, and in the Final Battle. In each, check that the box lists every
term the result depends on and that the terms add up to the total shown.

**Acceptance Scenarios**:

1. **Given** a Spell and a Boost against an Enemy, **When** the box is shown,
   **Then** it reads as a sum: Spell value, plus Boost (if it goes to Attack), equals
   Attack, against the Enemy's HP, with the verdict.
2. **Given** the enhanced action applies against an Enemy with Armor in that Ether,
   **When** the box is shown, **Then** the Armor appears as its own minus line, named.
3. **Given** the Boost goes to Initiative, **When** the box is shown, **Then** the
   Boost line moves to the Initiative sum: Element Initiative plus Boost, against the
   Enemy's Initiative, with who strikes first.
4. **Given** a Hardship or ability that changes a number (Night Travel shrinking the
   Boost, a Steep peril raising the MP, Ambush doubling early damage, Hazards or
   Storm adding time or damage, the Reserve's Boost on a matching Journey), **When**
   it applies, **Then** it appears as its own named line, with its sign, where it
   acts.
5. **Given** a set still being built, **When** a role is empty, **Then** the box shows
   the terms placed so far and marks what is still needed, without a verdict.
6. **Given** the Final Battle, **When** both sets are placed, **Then** the box adds
   both sets' values, shows which tier the total reaches, and what that tier costs.
7. **Given** any state, **When** compared with the engine's own figures, **Then**
   every total in the box equals the engine's. The box explains the result and never
   computes a different one.
8. **Given** reduced motion is on, **When** totals change, **Then** they change at
   once, without counting.

---

### User Story 3 - Strong raised boxes on a flat ground (Priority: P3)

Every zone of the play screen is a strong, raised box: the Encounter, the math box,
the role slots, the Hand, the actions and the header. Each has a clear edge, a solid
face and depth, and cut corners in the game's woodcut manner. The ground beneath is
a flat, consistent pattern in the game's own style: flat lines, no glow, no motion.
The pattern is generated for the game. The Mage Cards keep the faces from feature 005.

**Why this priority**: It answers "generic, no identity" in the owner's chosen
terms. The boxes already exist from the first stage; this story finishes them and
replaces the ground with the generated pattern.

**Independent Test**: Show the play screen beside today's and the owner's reference.
Every zone reads as a raised box and the ground as a flat pattern with nothing
moving.

**Acceptance Scenarios**:

1. **Given** the play screen in any state, **When** shown, **Then** each zone reads as
   a raised box with a clear edge, and none as a flat or glowing panel.
2. **Given** the ground, **When** watched for 10 seconds, **Then** nothing on it moves
   or glows; it is a flat, repeating pattern with no visible seams.
3. **Given** text and values on any box, **When** measured, **Then** they meet the
   same size and contrast minimums as today.
4. **Given** the owner compares the restyled play screen with today's, **When** asked,
   **Then** they prefer the restyled one. If they do not, work stops after this
   story, and User Stories 1 and 2 remain delivered.

---

### User Story 4 - A board that answers (Priority: P4)

The board answers the player's actions plainly, without ambient effects:
- a number rises to its slot;
- the totals count;
- the zone waiting on the player is lit at its edge;
- each action (place, take back, Fuse, Divert, Regroup, Play, a hit, damage, Soak,
  Upgrade, winning or losing an Encounter) gives the box concerned a brief edge
  flash in a meaningful colour.

Nothing moves while the player is thinking, except a slow light on the waiting zone.

**Why this priority**: It keeps the board from feeling static, which was one of the
three problems found, within the owner's "no flash effects" direction. Most of it
was built in the first stage.

**Independent Test**: Perform each action and name what the board did. Leave the
screen idle and confirm nothing moves except the waiting zone's edge. Turn on
reduced motion and confirm the responses show as held colours with no movement.

**Acceptance Scenarios**:

1. **Given** each player action, **When** performed, **Then** the box concerned gives a
   response the owner can name.
2. **Given** the idle play screen, **When** watched for 10 seconds, **Then** no
   particles, glows or patterns move; only the waiting zone's edge breathes slowly.
3. **Given** reduced motion is on, **When** actions are taken, **Then** every response
   is a held colour with no movement, and the waiting zone's edge is still.

---

### User Story 5 - Every screen in the same world (Priority: P5)

Once the owner approves the play screen (User Story 3, scenario 4), the same raised
boxes and flat ground carry through the rest of the game:
- the title (the Tower or The Tear);
- dragon and rules setup (the elders' proclamation);
- the Region banner;
- the ending;
- the rulebook, glossary, card inspection, menu and dialogs, each as a raised slab
  in the same style.

**Why this priority**: Coherence across the game is a goal, but only worth doing once
the look is approved on the play screen.

**Independent Test**: Take before and after screenshots of every screen and overlay
and show them to the owner side by side.

**Acceptance Scenarios**:

1. **Given** any screen or overlay, **When** shown, **Then** it uses the raised boxes
   and flat ground of the play screen, and every control and value shown today is
   still there and as legible.
2. **Given** each screen's before and after, **When** shown side by side, **Then** the
   owner prefers the after.

---

### Edge Cases

- **Reduced motion**: numbers appear in slots and totals change at once; responses
  are held colours; nothing a player needs is conveyed only by motion.
- **Fuse**: a fused pair counts as one card of the chosen Ether. Its slot shows the
  value the fused card gives, and the box names the Fuse where it changes a number.
- **Spell with no matching action**: when neither action fits the Encounter, the
  Spell counts as 1. The slot shows 1 and the box says why.
- **The Reserve**: on a Journey the Reserve's Boost can add to Move. It appears in
  the box as its own line, not in a slot.
- **Two sets** (Final Battle): six slots plus the secondary actions must fit beside
  each other at the minimum width. If they cannot, the actions stack in a narrow
  column of icon buttons, each still a full tap target.
- **Soak and Upgrade**: there are no role slots in these steps. The slot area shows the
  recap of the set just played (its numbers, and the Reserve's fate), and the box
  shows the Soak meter or the XP to spend.
- **Smallest and largest windows**: on every window in the layout matrix the boxes
  never cover content, crowd tap targets or leave large empty areas.
- **Ground pattern missing**: if the generated pattern is not present, the ground
  falls back to the plain stone grain without breaking anything.
- **Owner rejects the restyle** (User Story 3): User Stories 1 and 2 remain, in the
  boxes as they stand; no screen is left half-restyled.

## Requirements *(mandatory)*

### Functional Requirements

**Slots and numbers (User Story 1)**

- **FR-001**: Each role of each Action Set MUST have a full-size slot above the Hand
  that shows the number its card contributes, large, with the stat it counts toward.
- **FR-002**: A slot MUST NOT need the card's name to be read. The name stays on the
  card in the Hand, which is marked with its role.
- **FR-003**: Placing a card MUST send its number visibly from the card to its slot;
  taking it back MUST remove it. Under reduced motion both happen at once.
- **FR-004**: A slot's number MUST update when a later placement changes it (for
  example, the Element's Ether enabling the Spell's enhanced action).
- **FR-005**: The Attack-or-Initiative choice for the Boost MUST stay reachable from
  the Boost slot.
- **FR-006**: The secondary actions MUST sit beside the role slots, and the separate
  button row under the Hand MUST be removed. The room it frees goes to the Hand.
- **FR-007**: Selecting which role the next card fills, and taking a card back, MUST
  stay at least as easy as today.

**The math (User Story 2)**

- **FR-008**: The box beside the Encounter MUST show the result as a sum of named
  terms (Spell, Boost, and each change from a Hardship, ability, Armor, Reserve or
  Fuse), adding up to a total set against its target.
- **FR-009**: Against an Enemy the box MUST show the Initiative sum against the
  Enemy's Initiative, and who strikes first.
- **FR-010**: Every total MUST equal the engine's own figure for the same state. The
  box explains the result and MUST NOT compute its own.
- **FR-011**: While a set is incomplete, the box MUST show the terms so far and what
  is still needed, without a verdict.
- **FR-012**: In the Final Battle the box MUST add both sets and show the tier reached
  and its cost.
- **FR-013**: The verdict and its consequences (XP, damage, time, poison, Reserve
  lost) MUST stay visible under the sums, as today.

**Boxes and ground (User Story 3)**

- **FR-014**: Every play-screen zone MUST be drawn as a raised box with a clear edge
  and cut corners; none as a flat or glowing panel.
- **FR-015**: The ground MUST be a flat, still, seamlessly repeating pattern in the
  game's style, generated for it, with the plain stone grain as fallback.
- **FR-016**: The ground MUST NOT glow, flicker or move.
- **FR-017**: The Mage Card faces from feature 005 MUST stay as they are; this feature
  restyles what is around them.

**Responses (User Story 4)**

- **FR-018**: Each player action listed in User Story 4 MUST draw a visible response
  from the box it concerns.
- **FR-019**: The zone waiting on the player MUST be marked at its edge. It may
  breathe slowly; nothing else moves while the player is idle.
- **FR-020**: With reduced motion on, every response MUST have a still equivalent.

**Guardrails**

- **FR-021**: Every text and value MUST meet the existing size and contrast minimums
  on every box, and every control the existing minimum tap size.
- **FR-022**: The existing automated layout, layout-matrix and contrast checks MUST
  pass. They may be extended, not loosened.
- **FR-023**: Rules, steps of play, card data and available actions MUST NOT change.
- **FR-024**: Everything shown today on each screen MUST still be available.
- **FR-025**: The game MUST NOT reproduce the publisher's artwork or trade dress
  beyond the card faces, which follow the printed cards.

**Staging**

- **FR-026**: User Stories 1 and 2 MUST be complete and usable on their own, before
  the ground pattern changes.
- **FR-027**: The style MUST reach the other screens only after the owner has
  approved the play screen (User Story 3, scenario 4).

### Key Entities

- **Role slot**: one role of one Action Set. It holds the number its card contributes,
  the stat it counts toward, and whether it is next. The Boost slot also holds the
  Attack-or-Initiative choice.
- **Term**: one line of the math. It has a label and source (Spell, Boost, Armor,
  Night Travel, Reserve, Fuse, ...), a signed value, and the sum it belongs to
  (Attack, Initiative, Move, MP, or a Final Battle total).
- **Sum**: a list of terms adding up to a total, set against a target, with an
  outcome.
- **Zone**: a box on a screen with one job, and whether it waits on the player.
- **Ground pattern**: the flat, seamless image the boxes stand on.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Placing each of the three roles, an observer sees a number go from the
  card to its slot every time, and can say what each slot's number is without
  reading a card name.
- **SC-002**: For every state in the standard screenshot set (all Encounter kinds,
  each Hardship that changes a number, and the Final Battle), the box's terms add up
  exactly to the engine's totals: 100% of states.
- **SC-003**: Shown a state with a Hardship in effect, a first-time viewer finds in the
  box what changed the result within 10 seconds.
- **SC-004**: At the minimum window size, Hand cards are no smaller than today, and no
  zone is more than a third empty in any standard state.
- **SC-005**: In a side-by-side of each screen in the standard screenshot set, the
  owner prefers the after on every one.
- **SC-006**: The idle play screen shows no moving or glowing element except the
  waiting zone's edge, and the owner can name the response to each action.
- **SC-007**: All existing automated layout, layout-matrix and contrast checks pass on
  every window in the matrix.
- **SC-008**: No visible stutter on the web build or the Android emulator during play.
- **SC-009**: With reduced motion on, nothing on any screen moves.

## Assumptions

- **Kept from the first stage:** the landscape-only, 1280 × 720 minimum layout; the
  raised, chamfered box style; the zone responses; the content-sized left column;
  and the measured-space checks.
- **The compact role rail** (first-stage User Story 1) is replaced by the full-size
  slots. Its tests are rewritten for the new slots.
- **Play stays the one gold primary action.** With the button row under the Hand gone,
  it sits at the foot of the math box, so the result and the decision to play it sit
  together. The owner can move it at the restyle review.
- **The math box replaces today's comparison bars** in the challenge and Final Battle
  steps. The Soak meter and XP purse keep their jobs in their own steps.
- **The ground pattern** is generated with ComfyUI on this Mac (allowed since
  2026-10-15) as a seamless tile, flat in tone. It stays within the contrast band the
  stone grain uses today, so text keeps its contrast.
- **The engine already reports every figure** the box needs, or can report it without
  changing any rule: Spell value, Boost after Night Travel, Armor removed, Reserve
  added, MP after Steep, tiers.
- **Out of scope:** glowing or animated grounds, particles, rift light, music and
  sound, portrait orientation, new platforms, a light or parchment palette, new
  content, redrawing creature or dragon silhouettes, and formal device benchmarking.
