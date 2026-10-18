# Feature Specification: Card Contribution Highlights

**Feature Branch**: `011-card-contribution-highlights`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: the handoff section of `.specify/assessments/card-contribution-highlights/decision.md` (verdict: go, Option B). Original ask: "we are no longer going to show the intended outcome of the damage, initiative, ect... in the bottom left. instead, when a card is in a given position, highlight the parts of the card which will contribute to the outcome when the user hits 'play'… if a user is facing a journey which has a hardship that takes a value from their cards… apply another highlight to that card… ranged enemies cause the reserve card to show this impacted state until they elect to give up their reserve… take these parts out of the left column and leave it empty. we are updating it in a follow up spec." Owner correction: "the reason isn't to obfuscate the answer from users. it's because we are freeing up that space to utilize in a follow up pass without breaking current functionality."

## Background

Feature 010 made the preview panel (the "math box") under the Encounter face the place where the player:
- reads the Attack, Initiative and Move values, with the verdict and the costs;
- aims the Boost, by tapping the Attack or Initiative row;
- sees what a Hardship or Enemy ability does to their numbers.

The owner wants that space free for a follow-up pass that redesigns the left column. The box cannot simply be emptied, because three of its jobs are load-bearing:
- The Boost can only be aimed there, and Play waits until it is aimed.
- It is the only place that shows which of the player's card values count.
- It is the only place that shows how a Hardship or Enemy ability works against those values.

This feature moves those jobs onto the cards and retires the rest:
- **Contributing parts:** each placed card lifts exactly the parts that will count when Play is pressed.
- **Impacts:** a Hardship or Enemy ability that works against a card value shows its icon beside that value, as well as at its source.
- **Boost aim:** it is set on the Boost card itself, next to its Boost badge.
- **Retired:** the player's predicted totals, verdict, cost pills and loss warning. Players work out from the cards and the Encounter whether the Hand is enough.
- **The box:** it stays in the left column, holding only a short tip for the current step, until the follow-up pass replaces it.
- **XP:** the purse keeps its number. Spending XP on a level-up now sends that many stars from the number into the card.

Hiding the outcome from players is not a goal. Retiring the predictions is a consequence of freeing the space.

## Clarifications

### Session 2026-10-17

- Q: When Play is pressed, the numbers fly into the box, add up, and the verdict is revealed. With the box emptied before Play, what happens at Play? → A: A summary is shown on screen with the numbers added up. They don't need to come from the cards (FR-023).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The math box space is freed (Priority: P1)

While the player builds an Action Set, the box under the Encounter face no longer shows the player's Attack, Initiative or Move rows, the verdict, the cost pills, or a loss warning. It holds a short tip for the current step. The soak meter and the XP purse stay in the left column. The Enemy's own panel beside its image and the Journey's values are unchanged.

**Why this priority**: Freeing the space is the reason for the feature. Everything else exists so that freeing it breaks nothing.

**Independent Test**: In each encounter type (Enemy, Journey, Final Journey, Final Enemy), arrange a winning Hand and a losing Hand. Check that the box shows only a tip in both, that Play looks the same in both, and that the Enemy panel and the Journey values match today's.

**Acceptance Scenarios**:

1. **Given** a Region Enemy Encounter with a Hand dealt, **When** the board appears, **Then** the box shows a one- or two-line tip and no Attack, Initiative, target or verdict figures.
2. **Given** a Hand that would lose or Knock Out the dragon, **When** the player looks at the board, **Then** neither the box nor Play warns of it. Play looks the same as for a winning Hand.
3. **Given** a Journey or the Final Journey, **When** the board appears, **Then** the box shows no Move total, no Tier and no verdict, and the Journey's own values are shown as today.
4. **Given** the Hand is played, **When** the Encounter resolves, **Then** a summary shows the numbers added up against their targets with the verdict, and none of the numbers fly from the cards. The post-Play recap (verdict, damage, time, Knocked Out) then appears in the XP purse as today.
5. **Given** the step changes (setup, building the Hand, aiming a Boost, Soak, Upgrade), **When** the box is shown, **Then** its tip names what to do next in that step.

---

### User Story 2 - The cards show what counts (Priority: P1)

With the predicted totals gone, each placed card shows which of its parts will count when Play is pressed, given the current arrangement, Boost aim, Encounter, Hardship and Enemy ability:
- **Spell:** its enhanced action is lifted when the Element's Ether matches it and the action fits the Encounter. Otherwise its basic action is lifted.
- **Element:** its Ether is lifted, and so is its Initiative against an Enemy.
- **Boost:** its Boost is lifted.
- **Reserve:** its Boost is lifted only when it counts toward Move.

Nothing that does not count is lifted.

**Why this priority**: Without this, removing the box's rows would take away the player's only view of which values matter, which would be a regression.

**Independent Test**: For a set of arrangements covering every encounter type, check that the lifted parts on every card match, one for one, the parts the game counts in its result for that arrangement.

**Acceptance Scenarios**:

1. **Given** a Spell whose enhanced Ether matches the Element in the Element position, and an enhanced action that fits the Encounter, **When** the board shows, **Then** the Spell's enhanced action is lifted and its basic action is not.
2. **Given** the Element is swapped for one whose Ether does not match, **When** the swap completes, **Then** the Spell's basic action is lifted instead (or neither, when neither fits and the Spell counts for 1).
3. **Given** an Enemy Encounter, **When** a card is in the Element position, **Then** its Ether and its Initiative are lifted. **Given** a Journey, **Then** only its Ether is lifted.
4. **Given** a Journey where the Reserve's enhanced Ether matches the Journey's Ether, **When** the board shows, **Then** the Reserve's Boost is lifted. **Given** it does not match, **Then** nothing on the Reserve is lifted.
5. **Given** any arrangement in any encounter type, **When** the lifted parts are compared with the game's own count, **Then** they match exactly.

---

### User Story 3 - Aiming the Boost on its card (Priority: P1)

Against an Enemy, the Boost card carries a small aim mark beside its Boost badge: Attack, Initiative, or "choose" when not yet aimed. The player sets or changes the aim by tapping the Boost card's aim control. Play stays disabled until every Boost that needs an aim has one. In the Final Enemy, each set's Boost card carries its own aim control. On a Journey or the Final Journey, no aim control appears.

**Why this priority**: Aiming the Boost is required to play against an Enemy. Moving it out of the box is what lets the box be freed.

**Independent Test**: Against an Enemy, check that Play is disabled until the Boost is aimed. Aim it at Initiative, then at Attack, by tap and by keyboard, and check the aim mark and the lifted parts after each. Repeat for both Boosts in the Final Enemy. Check that tapping and dragging the Boost card to swap it still work.

**Acceptance Scenarios**:

1. **Given** an Enemy Encounter with a card in the Boost position and no aim chosen, **When** the board shows, **Then** the Boost card shows the "choose" aim mark and Play is disabled with a reason that names the Boost aim.
2. **Given** that state, **When** the player taps the aim control, **Then** the aim mark shows Attack and Play becomes available (if nothing else blocks it). **When** they tap it again, **Then** it shows Initiative.
3. **Given** a Boost aimed at Initiative, **When** the player taps the aim control again, **Then** the aim moves to Attack in one tap.
4. **Given** the Final Enemy with two Boost cards, **When** the player aims each, **Then** each card's aim is set from that card alone, and Play waits until both are aimed.
5. **Given** a Boost card, **When** the player taps it outside the aim control or drags it, **Then** it is picked up or dragged to swap exactly as today, and its aim does not change.
6. **Given** a swap that brings a different card into the Boost position, **When** the swap completes, **Then** the aim stays with the position, as today.
7. **Given** a keyboard-only player, **When** they want to aim or re-aim a Boost, **Then** they can do it without a pointer.
8. **Given** a Journey or the Final Journey, **When** a card is in a Boost position, **Then** no aim control or aim mark is shown.

---

### User Story 4 - Hardships and Enemy abilities shown where they bite (Priority: P2)

When a Hardship or Enemy ability works against a card value, its icon appears just to the right of that value's badge on the card, as well as at its source on the Enemy panel or the Journey. This is a mark next to the badge, not only a colour change:
- **Night Travel:** marks the Boost card's Boost and the Element card's Initiative.
- **Steep:** marks the Reserve's Boost.
- **Ranged:** marks the Reserve until the player gives up the Reserve.
- **Freeze:** marks the Reserve.
- **Armor:** marks the Spell's enhanced attack when it applies.

**Why this priority**: These effects were visible only in the box's sums. Moving them to the cards keeps the information. It ranks below the core aim and highlights because these effects arise only in some Encounters.

**Independent Test**: Set up an Encounter for each Hardship or ability listed. Check that its icon is on the source and beside each affected badge, and nowhere else. Check that it disappears when the effect no longer applies (Reserve given up, a card swapped out).

**Acceptance Scenarios**:

1. **Given** a Night Travel Encounter, **When** the Hand is dealt, **Then** the Night Travel icon shows to the right of the Boost card's Boost badge and of the Element card's Initiative badge, as well as on the Encounter.
2. **Given** a Steep Journey, **When** a card is in the Reserve, **Then** the Steep icon shows beside the Reserve's Boost badge.
3. **Given** a Ranged Enemy with a card in the Reserve, **When** the board shows, **Then** the Ranged icon shows on the Reserve card and stays there until the player gives up the Reserve. After that, the Reserve shows as given up, as today.
4. **Given** a Freeze Enemy with a card in the Reserve, **When** the board shows, **Then** the Freeze icon shows on the Reserve card.
5. **Given** an Armored Enemy and a Spell whose enhanced attack applies, **When** the board shows, **Then** the Armor icon shows beside the Spell's enhanced action.
6. **Given** a badge carrying both an aim mark and a Hardship icon (Night Travel on an aimed Boost), **When** the card is drawn at its smallest size, **Then** both marks are visible and readable and neither covers a value.
7. **Given** a card swapped out of an affected position, **When** the swap completes, **Then** its marks leave with the position, and the card now there carries them.

---

### User Story 5 - XP spent visibly flows into the card (Priority: P3)

The XP purse keeps showing the XP to spend as a number. Each time the player levels a card up, as many stars as that level costs leave the number and fly into that card, and the number counts down. Undoing a level-up counts the number back up, and no stars fly back. XP still unspent when the Upgrade step ends visibly goes away.

**Why this priority**: The owner bundled it into this pass. It touches the left column but is not needed to free the space.

**Independent Test**: In an Upgrade step with XP to spend, level a card up, then undo it, then level two cards in a row. Check the star count per flight, the number after each step, and what happens to XP left over when the step ends. Repeat with reduced motion on.

**Acceptance Scenarios**:

1. **Given** 8 XP and a level-up costing 3, **When** the player levels the card up, **Then** 3 stars travel from the XP number to that card and the number reads 5.
2. **Given** that level-up, **When** the player undoes it, **Then** the number reads 8 again and no stars fly back to the purse.
3. **Given** two level-ups in quick succession, **When** both run, **Then** each sends its own stars to its own card, and the number is right after each.
4. **Given** XP left unspent, **When** the Upgrade step ends, **Then** the leftover XP visibly goes away before the next Encounter.
5. **Given** reduced motion is on, **When** a level-up happens, **Then** the number changes with no stars flying.

---

### Edge Cases

- **Not every card placed**: with fewer cards than positions, only placed cards show lifted parts. An empty position shows nothing, and Play's existing rules for short Hands apply.
- **Fused cards**: a fused pair is lifted and marked as the one card in its position, with its effective Ether. The tucked card shows nothing.
- **Spell counts for 1**: when neither action fits the Encounter, neither action is lifted. The tip or the card's existing label may say the Spell counts for 1.
- **Night Travel cuts the Boost to 0**: the Boost badge carries the Night Travel icon. It is still lifted, because the Boost is still a term in the sum, only reduced.
- **The Slow ability**: a Spell's Move action counts as attack against a Slow Enemy, so a fitting Move action is lifted.
- **Reserve given up against Ranged**: the Ranged icon leaves the Reserve card, and the given-up state shows as today. Taking the choice back restores the icon.
- **Final Battle, two sets**: lifted parts and marks are worked out per set. The Reserve's mark applies once.
- **Setup and Soak**: no lifted parts, aim controls or Hardship marks are shown beyond what those steps show today. The box shows the step's tip.
- **Reduced motion**: lifting, marks and aim changes appear without animation.
- **Every checked window shape**: the aim control meets the minimum tap-target size, and no mark overlaps a value or another mark.

## Requirements *(mandatory)*

### Functional Requirements

**Freeing the box**

- **FR-001**: Before Play, the box under the Encounter face MUST NOT show the player's predicted Attack, Initiative, Move or Tier values, targets compared against them, a verdict, cost pills (XP, damage, time, poison, Reserve discarded, Knocked Out), or a loss warning, in any encounter type.
- **FR-002**: Play MUST NOT change its look or wording based on the predicted outcome.
- **FR-003**: The box MUST stay in the left column, and MUST show a short tip (no more than two lines) for the current step: setup, building the Hand, aiming a Boost, Soak or Upgrade. The tip MUST NOT include predicted values.
- **FR-004**: The soak meter, the XP purse and the post-Play recap MUST stay as they are, except as FR-019 to FR-022 change the XP purse.
- **FR-005**: The Enemy's panel beside its image and the Journey's displayed values MUST NOT change.
- **FR-006**: The box MUST NOT host any control. Every action it offered before (aiming the Boost) MUST be available elsewhere, as FR-011 to FR-015 describe.

**What counts**

- **FR-007**: On each placed card, the parts that count toward the result if Play were pressed now MUST be lifted, and no other part MUST be:
  - the Spell's enhanced or basic action (whichever applies);
  - the Element's Ether, and its Initiative against an Enemy;
  - each Boost card's Boost;
  - the Reserve's Boost when it counts toward Move.
- **FR-007a** *(owner, 2026-10-17)*: On each placed card, the stat-column figures that neither count nor carry a mark MUST step back slightly (fill and figure part of the way toward muted), so the counted and marked ones stand out. Nothing steps back during a Fuse, Divert or Regroup, or outside building.
- **FR-008**: The lifted parts MUST be derived from the same count the game uses to resolve the Encounter, taking the arrangement, the Boost aim, the Encounter type, the Hardship and the Enemy ability into account. They MUST update after every swap, aim change, Fuse and Reserve choice.
- **FR-009**: Lifted parts MUST be distinguishable without relying on colour alone.
- **FR-010**: Lifting MUST NOT reveal a predicted total or outcome.

**Boost aim**

- **FR-011**: Against an Enemy (Region or Final Enemy), each card in a Boost position MUST carry an aim control beside its Boost badge, showing Attack, Initiative, or not yet aimed.
- **FR-012**: Tapping the aim control MUST set the aim when none is set, and MUST switch it between Attack and Initiative when one is. Each Boost's aim MUST be set from its own card. The control MUST be at least the minimum tap-target size on its shorter side.
- **FR-013**: Tapping a Boost card outside its aim control, and dragging it, MUST pick it up or swap it exactly as before, without changing the aim.
- **FR-014**: There MUST be no default aim. Play MUST stay disabled, with a reason naming the Boost aim, until every Boost that needs an aim has one. An aim MUST stay with its Boost position when the card there changes.
- **FR-015**: Aiming MUST be possible by keyboard. On a Journey or the Final Journey, no aim control MUST be shown.

**Hardships and Enemy abilities**

- **FR-016**: When a Hardship or Enemy ability works against a card value, its icon MUST appear immediately to the right of that value's badge on the card, and MUST remain at its source (the Enemy panel or the Journey):
  - Night Travel: the Boost card's Boost and the Element card's Initiative.
  - Steep: the Reserve's Boost.
  - Ranged: the Reserve, while it has not been given up.
  - Freeze: the Reserve.
  - Armor: the Spell's enhanced attack when Armor applies to it.
- **FR-017**: These marks MUST NOT rely on colour alone. When a badge carries both an aim mark and a Hardship icon, both MUST fit beside it at every checked size without covering a value.
- **FR-018**: Marks MUST follow the position, not the card: a swap moves them to the card that now fills the affected position. They MUST disappear when the effect stops applying.

**XP spend**

- **FR-019**: The XP purse MUST keep showing the XP to spend as a number.
- **FR-020**: Each level-up MUST send as many stars as it costs from the XP number to the card being levelled, and the number MUST count down to the new amount.
- **FR-021**: Undoing a level-up MUST restore the number without stars flying back.
- **FR-022**: XP unspent when the Upgrade step ends MUST visibly go away before the next Encounter. With reduced motion on, star flights and the leftover fade MUST be replaced by an immediate change.

**Retiring the box's animations**

- **FR-022a** *(owner, 2026-10-17)*: In the Final Battle the dragon's face MUST keep the height it needs to show every tier; the box under it takes what is left, and its after-Play sum is clipped to the box rather than spilling. No tier is lit before Play.
- **FR-023**: When Play is pressed, a summary MUST appear on screen showing the numbers added up: each sum's terms, its total against its target, and the verdict. The numbers MUST NOT fly from the cards; the number flights that land on the box are retired. The summary MUST appear only after Play, never before. It MAY use the box's space during resolution, since it is not a prediction. The post-Play recap MUST still appear.

**Unchanged**

- **FR-024**: The game rules and outcomes MUST NOT change. The engine MUST receive the same actions as before for the same arrangement and aim.
- **FR-025**: Requirements of earlier features that this feature replaces MUST be updated, not left contradicting it:
  - 001's outcome preview and its SC-002;
  - 006's math box;
  - 010's FR-004, FR-010 and FR-018 to FR-018c (aiming from the preview rows).

  The README's description of the outcome preview MUST be updated too.

### Key Entities

- **Lifted part**: a region of a placed card (enhanced action, basic action, Ether, Initiative, Boost) that counts toward the result for the current arrangement.
- **Impact mark**: the icon of a Hardship or Enemy ability, drawn beside a badge whose value it works against. It belongs to a position and an effect.
- **Boost aim**: Attack, Initiative or not yet aimed. It belongs to an Action Set's Boost position against an Enemy, and is set from the card in that position.
- **Step tip**: the short instruction the box shows for the current step.
- **XP star**: a transient mark that carries one XP from the purse's number to the levelled card.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In all four encounter types, the box shows no predicted value, verdict, cost or warning before Play: 0 of these on screen, against several today.
- **SC-002**: Every job the box does today is accounted for, either moved (Boost aim, which values count, Hardship and ability effects) or retired (predicted totals, verdict, costs, loss warning), with none left unaccounted.
- **SC-003**: Across a test set covering every encounter type, Hardship and Enemy ability, the lifted parts on every placed card match the game's own count in 100% of arrangements.
- **SC-004**: A player can aim a Boost in one tap and switch it in one more, on every checked window shape, without dragging. In the Final Enemy, each Boost is aimed in one tap on its own card.
- **SC-005**: Swapping a Boost card by tap or by drag works the same as before in 100% of trials. No swap changes an aim, and no aim tap starts a swap.
- **SC-006**: Every Hardship and Enemy ability that works against a card value shows its icon at its source and beside 100% of the affected badges, and nowhere else.
- **SC-007**: For each level-up, the number of stars that fly equals the XP spent, and the XP number is correct after every level-up and undo.
- **SC-008**: Every existing rules test and recorded playthrough gives the same outcome as before. The automated suite and the layout check pass, with the requirements they encode updated rather than skipped.
- **SC-009**: The follow-up left-column pass can take over the box's space without moving any control or information out of it first.

## Assumptions

- **The aim mark is enough to tell aims apart.** A Boost aimed at Initiative is lifted the same way as one aimed at Attack, and the aim mark shows which. The Element's Initiative is lifted against an Enemy either way.
- **The tip is one short line per step**, in the game's existing instruction voice. It is not a tutorial. The follow-up pass may replace it.
- **Lifting reuses the card face's existing lifted-part look**, which already marks parts by shape and not only by colour.
- **Hardship and ability icons are the existing rule icons**, drawn small. The owner judges that two fit beside one badge.
- **The aim control can be told apart from the card's swap gestures.** Its tap area can meet the minimum size without blocking a tap or drag on the rest of the card; this is to be proven in planning.
- **Leftover XP fades out at the purse** at the end of the Upgrade step, following the rule "Excess XP is lost at the end of [the] Encounter".
- **Poison, Ambush, Hazards, Storm and Treacherous change only damage or time**, not a card value, so they get no mark on the cards. They stay on their source as today.
- **The left column keeps its current layout and size**; only the box's content changes. If the layout check's space rule cannot be met by a short tip, the rule is retuned for this interim state.
- This feature replaces 010's preview-row Boost aiming (FR-018 to FR-018c) and 010's assumption that values are read in the preview panel. 010's one-row Hand, labels, swaps and action row stay.
