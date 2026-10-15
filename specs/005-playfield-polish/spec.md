# Feature Specification: Playing Field and Card Polish

**Feature Branch**: `005-playfield-polish`

**Created**: 2026-10-14

**Status**: Draft

**Input**: User description: "your job is to polish the cards and layout of the playing field. things are relatively dense, colors are flat, areas of cards should be highlighted for the portion which matters according to the current step - armor being highlighted when soaking damage, experience being highlighted when upgrading, boost being highlighted when selecting a boost card, ect... we have a lot of the engine down but this really needs some polish"

## Context

The rules engine is complete and the play screen already has a fixed landscape
arrangement (header, Encounter, preview, Action Set slots, Hand, secondary actions,
primary action) with cards drawn like the printed Mage Cards. Three problems remain:

1. **Every part of a card is equally loud.** A Mage Card carries its Level, name,
   Key Card strip (Encounter, Hardship, Upgrade cost), Initiative, basic action,
   enhanced action, Boost, Armor and Ether. In any one step only one or two of those
   matter, but the player has to find them on every card, every time.
2. **The field is dense.** Regions sit close together with similar weight, so the
   eye has no obvious starting point and the screen reads as one block.
3. **Colours are flat.** Surfaces, cards and panels are mostly solid fills of
   similar darkness, with little depth, lighting or separation between layers.

This feature changes presentation only. It does not change the rules, the steps
of play, or what the player can do in each step.

It includes a rework of how Mage Cards are drawn, bringing them closer to the
official printed cards (`reference/sheets-official`): their framing, depth and
visual vocabulary.

## Clarifications

### Session 2026-10-14

- Q: Should a card in play show only its current Level, or both Levels end to end
  like the printed card? → A: Only the current Level on the field, styled like the
  printed card. In this digital version each Level is effectively its own card; the
  enlarged view shows all four Levels of the card, each as its own face.
- Q: Should the Ether field carry a mage illustration like the printed cards? → A: No
  mage illustration. Instead, redraw each Ether's sigil closer to the official
  shapes, and give each Ether field its own character so the Ethers feel alive: Fire
  cards feel like fire, Lightning feels shocking, and so on for Water and Shadow.
- Q: Where should the card-rendering rework sit in priority? → A: It is its own
  top story (P1), so step emphasis is drawn on the new card face. Step emphasis is
  P2, layout P3, field colour and depth P4.
- Q: (During implementation) How animated should the Ether fields be? → A: Faint and
  slow, like premium trading cards, not like a visualizer: a holographic foil
  sheen. Each Ether keeps its own etched texture; motion is a quiet shared sheen,
  not per-Ether flicker, flashes or ripples.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cards that look like the official cards (Priority: P1)

Mage Cards are redrawn to look and feel much closer to the official printed cards:
the same framing, banding and stat vocabulary, with real depth (layered plates,
edge light, shadow) instead of flat fills. Each card shows only its current Level;
in this digital version each Level is effectively its own card. Each Ether has its
own character on the card: its sigil follows the official symbol's shape, and its
field carries its own etched texture under a faint, slow holographic sheen, like a
premium foil trading card. Opening a card shows all its Levels side by side, each as a full face.

**Why this priority**: The cards are the pieces the player handles every turn and
the first thing that reads as finished or unfinished. Step emphasis (User Story 2)
is drawn on this face, so building the face first avoids building emphasis twice.

**Independent Test**: Lay the Hand beside the official card scans and confirm a
player who owns the game recognises the styling; put one card of each Ether side by
side and confirm each is identifiable from its field's character alone; open a card
and confirm every Level is shown as its own face.

**Acceptance Scenarios**:

1. **Given** a player who owns the physical game, **When** they see a card in the
   Hand, **Then** they recognise the printed card's styling in it, even though only
   one Level is shown.
2. **Given** a card in the Hand, **When** shown, **Then** its stats, plates and bands
   read as raised, layered pieces with light and shadow, not flat fills.
3. **Given** a card of each Ether side by side, **When** shown, **Then** each field has
   its own etched texture (Fire licking upward, Water in long waves, Lightning in
   zig-zags, Shadow coiling under faint stars) under a faint, slow holographic sheen,
   and each sigil follows the official symbol's shape.
4. **Given** a card opened in the enlarged view, **When** shown, **Then** each of its
   Levels appears as its own full card face, with the current Level marked.
5. **Given** reduced motion is on, **When** cards are shown, **Then** each Ether's
   field keeps its character as a still image.
6. **Given** any card at Hand size on the smallest supported window, **When** shown,
   **Then** every value on it is at least as legible as today.

---

### User Story 2 - The card shows what matters right now (Priority: P2)

In every step of play, each card in the Hand draws attention to the part of the
card that the current step uses and quietens the rest. While Soaking damage the
Armor stands out; while Upgrading the Upgrade cost and the figures an Upgrade would
change stand out; while filling the Boost slot the Boost value stands out; and so
on for every step. The player can make each decision by glancing along the Hand at
one spot per card instead of reading every card in full.

**Why this priority**: This is the change the user asked for by name, and it saves
effort on every single decision in the game. It is drawn on the reworked card face
from User Story 1, so it follows that story; it does not depend on the layout or
field colour work.

**Independent Test**: Play through one Encounter of each kind into the Soak and
Upgrade steps. At each step, show the Hand to someone for three seconds and ask
which value on each card matters now; they point to the emphasised region.

**Acceptance Scenarios**:

1. **Given** the Soak step (damage, poison or the final Soak), **When** the Hand is
   shown, **Then** each card's Armor value and Armor Ether are emphasised, the rest
   of the card is quietened, and cards whose Armor Ether matches the incoming
   damage are visibly marked as Soaking more.
2. **Given** the Upgrade step, **When** the Hand is shown, **Then** each card's
   Upgrade cost is emphasised, cards the player can afford are distinct from those
   they cannot, and the figures an Upgrade would change are marked.
3. **Given** the next empty slot is the Boost slot, **When** the Hand is shown,
   **Then** each available card's Boost value is emphasised.
4. **Given** the next empty slot is the Spell slot, **When** the Hand is shown,
   **Then** each available card's basic and enhanced actions are emphasised.
5. **Given** the next empty slot is the Element slot, **When** the Hand is shown,
   **Then** each available card's Ether and Initiative are emphasised.
6. **Given** a card already placed in a slot, **When** the player looks at it,
   **Then** only the part of the card that slot uses is emphasised (for a Spell, the
   action actually in effect, basic or enhanced).
7. **Given** a Fuse in progress, **When** the player is choosing cards or the Ether,
   **Then** each card's Ether is emphasised.
8. **Given** a step in which no single part of the card matters (choosing starting
   cards, Divert, Regroup), **When** the Hand is shown, **Then** no region is
   emphasised and cards appear at full strength.
9. **Given** any step, **When** a card is emphasised in part, **Then** every value
   on it is still legible; quietened regions are de-emphasised, never hidden.

---

### User Story 3 - A playing field with room to breathe (Priority: P3)

The play screen reads in a clear order: the Encounter and the predicted outcome
first, the Action Set being built next, the Hand last, with the commit control
obvious. Regions are separated by space and grouping rather than by packing them
edge to edge, and secondary information (pile counts, Region progress, help) sits
back so the decision in front of the player comes forward.

**Why this priority**: The card stories help inside each card; this helps the player
find their way around the screen as a whole. It touches every region, so it comes
after the narrower, higher-value change.

**Independent Test**: Show a first-time viewer the play screen at the smallest
supported window for five seconds, then ask them to name what they are facing,
what would happen if they played now, and where to tap to play. They answer all
three.

**Acceptance Scenarios**:

1. **Given** any step of play at the smallest supported window, **When** the screen
   appears, **Then** every region is visible without scrolling and no region
   overlaps another.
2. **Given** any step of play, **When** the player looks at the screen, **Then** the
   region needing their input in that step (Hand, slots, or the primary action) is
   the most prominent area, and regions not used in that step recede.
3. **Given** the Hand of four cards (or the larger setup offer), **When** shown,
   **Then** the cards are at least as large as today and the space between and
   around them is visibly more generous than today.
4. **Given** the header, **When** shown, **Then** Region progress and pile counts
   remain readable but are visually quieter than the Encounter and the preview.
5. **Given** a larger window than the minimum, **When** the screen appears, **Then**
   the extra space goes to the cards and the Encounter rather than to wider gaps.

---

### User Story 4 - Colour and depth on the field (Priority: P4)

The field, panels and cards have depth: the background, the panels on it and the
cards on those read as distinct layers, lit consistently. Good, cautionary and bad results each have a colour treatment that reads
instantly, and the Encounter's Ether tints its area of the field.

**Why this priority**: This finishes the screen around the cards, but it is the
least tied to any decision the player makes.

**Independent Test**: Place a screenshot of the play screen before and after side
by side and ask viewers which looks more finished; then confirm the after version
still passes the contrast and legibility checks below.

**Acceptance Scenarios**:

1. **Given** the play screen, **When** shown, **Then** the background, panels and
   cards are distinguishable as three layers by shading alone.
2. **Given** a card of each Ether, **When** shown, **Then** the four Ethers remain
   distinguishable from each other at Hand size, including for players with common
   colour-vision deficiencies (each Ether keeps its icon).
3. **Given** a card that cannot be chosen, **When** shown beside eligible cards,
   **Then** it is clearly unavailable, and the difference from "quietened" regions
   of eligible cards is unambiguous.
4. **Given** an Encounter of a given Ether, **When** the screen appears, **Then** the
   Encounter's area picks up that Ether's colour.

---

### Edge Cases

- A card both placed in a slot and relevant to the current step (for example, the
  Reserve on a journey, whose Boost can count): the region the rules use for it is
  emphasised, and the Reserve's emphasis is shown only when it would actually count.
- An enemy Encounter where the Boost is sent to Initiative instead of Attack: the
  Boost card's emphasis still shows Boost; the slot and preview make clear where it
  goes.
- Downgraded cards in the Soak step cannot be chosen again: they are shown as
  unavailable, not merely quietened.
- A card at maximum Level in the Upgrade step: its Upgrade cost region shows it
  cannot be Upgraded rather than being emphasised.
- Holding or hovering a card to see its alternate Level (If Upgraded, If
  Downgraded): the alternate view keeps the same emphasis as the step.
- Two Action Sets at once (final battle steps): emphasis follows the slot that will
  be filled next, whichever set it is in.
- Card faces drawn outside play (rulebook figures, card detail, inspect overlay)
  show no step emphasis unless that view is explaining a step.
- The player has turned on reduced motion: emphasis is shown without animation.

## Requirements *(mandatory)*

### Functional Requirements

**Card rendering**

- **FR-001**: A card on the field MUST show only its current Level, drawn in the
  visual style of the official printed card.
- **FR-002**: Card faces MUST render their Ether colour with tonal variation (such as
  gradient, sheen or edge light) instead of a single flat fill.
- **FR-003**: Card frames, bands, stat crests and action plates MUST read as layered,
  raised pieces with consistent light and shadow, following the official card's
  vocabulary (dark framing bands, crest-shaped Initiative and Armor, plates for the
  actions with the enhanced action filled in its Ether colour).
- **FR-004**: The enlarged card view MUST show every Level of the card (up to four),
  each as a complete face of its own, with the current Level marked.
- **FR-005**: Each Ether's sigil and icon MUST be redrawn to match the shape of the
  official Ether symbol more closely.
- **FR-006**: Each Ether's card field MUST have its own character in colour and
  etched texture (Fire licking upward, Water in long waves, Lightning in zig-zags,
  Shadow coiling under faint stars), finished like a premium foil card: any motion
  is faint and slow (a holographic sheen and soft glints), never flickering or
  flashing. A player MUST be able to tell the four Ethers apart by their field alone.
- **FR-007**: The card field MUST NOT carry a mage illustration; its character
  MUST stay behind the stats and never reduce their legibility or contrast (FR-026).
- **FR-008**: With reduced motion on, each Ether field MUST still show its character
  as a still image, without ambient motion.

**Step emphasis on cards**

- **FR-009**: Each card face MUST be able to emphasise one or more of its regions —
  Level, Key Card strip, Upgrade cost, Initiative, basic action, enhanced action,
  Boost, Armor, Ether — and quieten the others.
- **FR-010**: The regions emphasised MUST follow the current step, as follows:

  | Step | Emphasised on Hand cards |
  |------|--------------------------|
  | Choosing starting cards | None |
  | Building an Action Set, Spell slot next | Basic and enhanced actions |
  | Building an Action Set, Element slot next | Ether and Initiative |
  | Building an Action Set, Boost slot next | Boost |
  | Card placed in a slot | The region that slot uses (Spell: the action in effect) |
  | Reserve on a journey | Boost, only when it would count |
  | Fuse, choosing cards or Ether | Ether |
  | Divert, Regroup | None |
  | Soak (damage, poison, final) | Armor value and Armor Ether |
  | Upgrade | Upgrade cost, plus the figures an Upgrade would change |

- **FR-011**: A quietened region MUST remain legible at Hand size; emphasis MUST NOT
  hide or remove any value from a card.
- **FR-012**: In the Soak step, cards whose Armor Ether matches the incoming damage
  MUST carry an extra mark showing they Soak more.
- **FR-013**: In the Upgrade step, a card's Upgrade cost MUST read differently when
  the player can afford it, cannot afford it, or the card is at maximum Level.
- **FR-014**: Emphasis MUST change in step with the game: when the next slot,
  mode or phase changes, the emphasis on every card updates at the same moment.
- **FR-015**: The empty slot being filled next MUST visibly share the emphasis
  colour or treatment used on the cards, so the slot and the card regions read as
  belonging together.
- **FR-016**: "Unavailable" (cannot be chosen in this step) and "quietened region"
  (part of an eligible card) MUST be visually distinct treatments.

**Layout**

- **FR-017**: The play screen MUST keep its single landscape arrangement and fit
  every supported window size without scrolling or overlap, including the smallest
  (1280 × 720 design units) and the window sizes the layout is already checked at.
- **FR-018**: Spacing between and within regions MUST increase relative to today,
  while Hand cards stay at least their current size.
- **FR-019**: The region taking the player's input in the current step MUST be the
  most prominent; regions not used in that step MUST recede.
- **FR-020**: Secondary information (pile counts, Region progress) MUST be
  visually subordinate to the Encounter, the preview and the Hand.
- **FR-021**: Extra space in larger windows MUST go first to the cards and the
  Encounter.

**Colour and depth**

- **FR-022**: Background, panels and cards MUST read as three separate layers through
  shading, lighting or shadow.
- **FR-023**: Each Ether MUST stay distinguishable from the others by colour and by
  icon.
- **FR-024**: The Encounter's area MUST carry a tint of the Encounter's Ether.
- **FR-025**: Result colours (good, cautionary, bad) MUST be applied consistently
  wherever results appear on the field.

**Constraints carried forward**

- **FR-026**: All existing legibility rules MUST still hold: nothing that must be
  read is set below the minimum text size, nothing tappable is below the minimum tap
  size, and text keeps sufficient contrast against its background (WCAG AA 4.5:1 for
  body text, 3:1 for large numerals) on both emphasised and quietened regions.
- **FR-027**: When reduced motion is on, emphasis changes MUST appear instantly
  without animation.
- **FR-028**: Game rules, step order and available actions MUST be unchanged.

### Key Entities

- **Card region**: A named area of a Mage Card face (Level, Key Card strip, Upgrade
  cost, Initiative, basic action, enhanced action, Boost, Armor, Ether) that can be
  emphasised, quietened or shown normally.
- **Step emphasis**: For the current step, the set of card regions that matter, per
  card, plus any extra mark (such as "Soaks more" or "can afford").
- **Ether character**: For each of the four Ethers, its colour, sigil shape, field
  texture and ambient motion, shared by every card of that Ether.
- **Field layer**: Background, panel or card; each has its own shading so the three
  read as separate depths.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In every step listed in FR-010, a viewer shown the Hand for 3 seconds
  correctly identifies the value that matters on each card in at least 9 of 10
  trials.
- **SC-002**: In the Soak step, players choose a set of cards that covers the damage
  with no more Downgrades than needed at least as often as today, and take less time
  to decide.
- **SC-003**: A first-time viewer shown the play screen for 5 seconds can name the
  Encounter, the predicted result and the control that plays the turn.
- **SC-004**: Every supported window size shows all regions with no scrolling and no
  overlap, and all text and tap targets meet the existing minimums.
- **SC-005**: Every text and numeral on the field, emphasised or quietened, meets the
  contrast ratios in FR-026.
- **SC-006**: In a side-by-side comparison of before and after screenshots, most
  viewers judge the after version as looking more finished.
- **SC-007**: With a full Hand of living Ether fields on screen, play stays smooth
  (no visible stutter) on the slowest supported target, including the web build on
  a mid-range phone.
- **SC-008**: Shown one card of each Ether with colour removed (greyscale), viewers
  identify the Ether from the field's character and sigil in at least 9 of 10 trials.
- **SC-009**: Players who own the physical game identify a Hand card as matching its
  printed counterpart, and say it resembles the official styling, without being told.
- **SC-010**: A full game plays from setup to ending with identical outcomes before
  and after this change for the same seed and choices.

## Assumptions

- The four-card Hand, the 1280 × 720 minimum layout and landscape-only orientation
  from feature 001 stay as they are.
- The printed card's stat arrangement (Level crown and name across the top, Key Card
  strip under it, stat column down the left of the Ether field) is kept; the rework
  restyles it toward the official visual vocabulary rather than inventing a new
  layout.
- "Quieten" means reduced contrast or saturation, not removal; the player can always
  read the full card.
- Emphasis is per step, not per card choice: hovering a card does not change which
  regions are emphasised on the other cards.
- The only new art is the four redrawn Ether sigils and icons; depth and Ether
  character otherwise come from shading, texture and motion, not illustrations.
- The title, rules and ending screens are out of scope except where they share card
  faces or theme colours with the play screen.
- The existing automated layout and legibility checks remain the gate for FR-017 and
  FR-026.
