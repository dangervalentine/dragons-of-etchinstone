# Feature Specification: Unified Design System (Inkstone and Brass)

**Feature Branch**: `019-unified-design-system`

**Created**: 2026-10-22

**Status**: Draft

**Input**: User description: "'/Users/danger/Downloads/etchinstone-design-system.zip' take this zip file of a design system and implement these changes to the tokens and design system used throughout the application to update the game to this unified and intentional pattern"

The design system ("Etchinstone", version 1) is kept with this feature in
[`design-system/`](design-system/): `README.md` is the guide, `tokens.json` is the
source of truth for every value, and `components/<Name>/README.md` gives the rules per
component. Where this spec and those files differ, those files win, except where this
spec records a deliberate adaptation to the game (see Assumptions).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The painted art is the colour; the chrome steps back (Priority: P1)

A player opens the game and every screen sits on one quiet, dark slate-green stone
table, lettered in warm parchment. The purple night-stone and the gold outlines round
every panel are gone. The Encounter paintings, the Region Card and the Ether fields on
the Mage Cards are the brightest, most colourful things on screen, so the eye goes to
the art and the cards rather than to the frames round them.

**Why this priority**: This is the heart of the design system ("the art is the
colour") and touches every screen. Replacing the palette and the grounds alone
delivers most of the visible change, and every later story builds on it.

**Independent Test**: Open each screen (title, setup, dragon choice, play, ending,
records, rulebook, lessons, every overlay) and compare against the design system's
previews: grounds, panels, buttons and text use only the design system's colours, and
no panel or header is outlined in gold at rest.

**Acceptance Scenarios**:

1. **Given** any screen, **When** it is shown, **Then** the screen background is the
   `ground` colour, panels and bars are `stone`, pressable slabs are `stone-raised`,
   empty slots are sunken `well`, and primary text is `parchment`.
2. **Given** a game in a Region, **When** the play screen is shown, **Then** a large,
   soft glow in that Region's own tint (Jade Mountains, Living Marshes, Burning
   Basin, Forest of Gath, or the lair for the Final Journey and Final Battle) lies over
   the ground behind the Encounter or Region Card, at the design system's wash
   strength.
3. **Given** any panel, tray, bar or button at rest, **When** it is drawn, **Then**
   its rim is the etched `edge` colour, never gold or brass.
4. **Given** any text or meaningful rim on any ground, **When** its contrast is
   measured, **Then** text keeps at least 4.5:1 and meaningful rims at least 3:1, except
   disabled labels, which are deliberately fainter.

---

### User Story 2 - Brass means "here" (Priority: P1)

A player choosing an Action Set always knows what to do next: the one slot the next tap
fills has a brass rim and a brass header, the card they have chosen has a brass ring,
and the one action that moves the game forward (Play, Play again, Continue, Confirm) is
the only brass button on screen. Rewards (Score, XP, first place, banner headlines) are
in a brighter brass. Nothing else on screen is gold.

**Why this priority**: Gold is used today on about 120 things, so it no longer says
anything. Making brass mean "the next thing you can do" directly helps the player play,
and it is the second principle of the design system.

**Independent Test**: Play a turn through the screens and check that at each step at
most one slot is the brass target, at most one button is brass, selected cards and tabs
have the brass ring, and reward figures use bright brass, while headers, panel rims,
icons and labels at rest do not.

**Acceptance Scenarios**:

1. **Given** an Action Set being built, **When** a slot is the next to be filled,
   **Then** only that slot's well has the 3-unit-wide brass rim and only its header is
   brass with a brass underline; empty slots' headers are muted parchment and filled
   slots' headers are parchment.
2. **Given** a screen with a primary action, **When** it is shown, **Then** exactly one
   button is brass-filled with dark `on-brass` text (never white), and every other
   button is a stone slab.
3. **Given** a primary action that is not yet available (Play before the set is full,
   Confirm 3/4), **When** it is shown, **Then** it is drawn disabled: flat stone, a
   `line` rim, no bevel and a faint label that is kept, so the player sees what will
   unlock.
4. **Given** a Score, XP figure, XP star, first place or banner headline, **When** it
   is shown, **Then** it is in `brass-bright`; other figures are parchment.
5. **Given** keyboard or controller focus on a control, **When** it is shown, **Then**
   the control's rim is 3 units of `jade`, distinct from the brass of selection.

---

### User Story 3 - Easier type: Fraunces replaces Cinzel (Priority: P2)

Titles, headings, card names and every game figure are set in Fraunces, a warm,
readable serif with open, tabular figures, in title case rather than all capitals.
Running text stays in Alegreya Sans. The top bar reads "Jade Mountains · Region 1",
with the place first and the number muted, instead of "REGION 1 · JADE MOUNTAINS" in
inscriptional capitals.

**Why this priority**: The design system calls the all-caps Cinzel top bar the hardest
line to read in the game. It is a contained change (the type scale and one face) with a
large legibility gain, but the game is playable without it.

**Independent Test**: Open every screen and check that no text uses the old display
face, that titles and headings are title case (only banners, card names and slot or
column labels are uppercase), that every game number uses the numeral styles with
tabular figures, and that no live text is smaller than the minimum size.

**Acceptance Scenarios**:

1. **Given** any screen, **When** it is shown, **Then** banners, titles, headings, card
   names and all game figures use Fraunces, and labels, buttons, body text and captions
   use Alegreya Sans.
2. **Given** a column of figures (a Result sum, the leaderboard, the counters),
   **When** it is shown, **Then** the figures are tabular, so digits line up.
3. **Given** the top bar in a Region, **When** it is shown, **Then** it reads the
   Region's name first in parchment and its number after it in muted parchment, in
   title case.
4. **Given** the type scale, **When** each style is measured at the game's base size,
   **Then** it matches the design system's size in phone points scaled to the game's
   720-unit-tall layout, and no live text is below the minimum readable size.

---

### User Story 4 - Carved stone, printed paper (Priority: P2)

Things you press and information panels look like carved stone slabs: chamfered
corners, an etched rim with a thin light line inside the top edge, and a bevel that
collapses when pressed. Things that are physically cards (Mage, Key, Region,
Encounter, Dragon) are rounded paper with a soft shadow that grows when a card is held
or inspected. Text read at length (lesson coach tips, glossary entries, rulebook pages,
the unspent XP question) is printed dark on warm paper, so it no longer sits
dark-on-dark against the panels behind it.

**Why this priority**: This makes the materials consistent and fixes the coach tip's
poor contrast, but the game is fully playable on the new palette without it.

**Independent Test**: Inspect a button, a tab, a panel, a slot, a chip, a dialog, a
banner and a card at rest, pressed, selected and disabled, and a coach tip, glossary
entry and rulebook page, against the component rules in the design system.

**Acceptance Scenarios**:

1. **Given** a stone button, tab, panel, tray, dialog or banner, **When** it is drawn,
   **Then** its corners are chamfered (small, medium or large cut per the component)
   and not rounded, and it carries the slab bevel.
2. **Given** a stone button, **When** it is pressed, **Then** its bevel collapses and
   it drops 2 phone points, with no colour change.
3. **Given** a Mage, Key, Region, Encounter or Dragon card, **When** it is drawn,
   **Then** its corners are rounded with the card radius and it casts the card shadow;
   **When** it is held, dragged or inspected, **Then** it casts the larger lift
   shadow.
4. **Given** a lesson's coach tip, a glossary entry, a rulebook page or the unspent XP
   question, **When** it is shown, **Then** it is printed in dark ink on `paper`,
   lines are kept to about 50 characters, and glossary terms in it are bold with a
   dark brass underline.
5. **Given** a card that is out of play, **When** it is shown, **Then** it is fully
   greyscale at the out-of-play opacity.
6. **Given** reduced motion, **When** a slab is pressed or a card is lifted, **Then**
   the still form of each state is shown without travel.

---

### User Story 5 - Mineral Ethers that sit with the painted art (Priority: P3)

The four Ether fields on the cards change from saturated printed hues to mineral
pigments: lapis for the drop, ochre for the bolt, amethyst for the spark and cinnabar
for the flame. A highlighted figure (the value a card is contributing) fills with the
Ether's brighter partner. Card numbers always sit on dark stat plates, never straight
on the field, and each card's Ether glyph is always shown, because three of the four
pigments are close in lightness.

**Why this priority**: The cards already read well; this makes them sit with the
painted art rather than shout over it. It is the most delicate change (the cards'
contrast checks must hold) and can come last.

**Independent Test**: Lay out one card of each Ether, at rest and with a highlighted
figure, and check its field colour, its plates, its glyph and its contrast against the
design system.

**Acceptance Scenarios**:

1. **Given** a card of each Ether, **When** it is drawn, **Then** its field is that
   Ether's mineral pigment and its frame and title band are `card-frame`, with a
   leather `card-ribbon` stat ribbon showing cost and XP.
2. **Given** a highlighted figure, **When** it is drawn, **Then** its pill is the
   Ether's bright partner with dark ink (`on-brass` on ochre, the `stat-plate` dark
   on the others), at least 4.5:1; parchment on the bright partners is under 3:1
   (plan research R4).
3. **Given** any card, **When** it is drawn, **Then** its Ether glyph is shown in the
   title band and no figure is set directly on the Ether field.
4. **Given** anything else coloured by an Ether (board responses, slot edges, the
   creature backlight, Ether pickers, notes), **When** it is drawn, **Then** it uses
   the same mineral family, so an Ether is one colour across the whole game.

---

### User Story 6 - Components match the system everywhere (Priority: P3)

Every recurring piece of the interface follows its component rule in the design
system: the top bar, chips, tabs, slots, panels, dialogs, banners, the ledger tables,
the coach tip and the Mage Card. The same thing looks the same wherever it appears.

**Why this priority**: This is the "unified and intentional" finish. Most of it falls
out of stories 1 to 5; this story catches each component's remaining specifics.

**Independent Test**: For each component README in the design system, find every place
the game uses that component and check it against the README's rules.

**Acceptance Scenarios**:

1. **Given** the top bar, **When** it is shown, **Then** it is a stone bar with a
   `card-frame` line under it, its pile counts are sunken chips with the game's own
   pile icons, and its menu button is a stone slab at least the minimum tap size.
2. **Given** a filter or one-of-many choice (the records screen's difficulty and
   dragon filters, Leaderboard or History, rules sections, Boost aim), **When** it is
   shown, **Then** it is drawn as tabs sized to their labels, not as full-height action
   buttons, with exactly one selected per group. The setup screen's difficulty choice
   stays as described tiles, because each carries a description (a deliberate
   departure).
3. **Given** the Leaderboard or History, **When** it is shown, **Then** column heads
   are muted uppercase labels, rows are separated by hairlines, scores use the numeral
   style, and only the best row is in bright brass.
4. **Given** a confirmation the game asks before something it cannot undo, **When** it
   is shown, **Then** it is a stone dialog over the scrim, its title is the question,
   its body states the consequence in one sentence, the safe way back is a stone button
   on the left and the answer is the brass button on the right.
5. **Given** a new Region, a victory or a defeat, **When** its banner is shown,
   **Then** the banner's rim and medallion are in the Region's tint (the lair tint for
   victory, `danger` for defeat), its kicker is a muted label and its headline is
   uppercase in bright brass (parchment for defeat).
6. **Given** a good or harmful outcome (covered damage, damage taken, an Armor
   penalty, a refused move), **When** it is shown, **Then** it is in `jade` or
   `danger` and always carries a tick, minus sign, heart or skull, never colour alone.

---

### Edge Cases

- **Card names at the smallest window.** The design system lets card names go below
  the general text floor (to about 20 design units) so a name like MOTIVATED FLIGHT
  fits in two lines; every other piece of live text keeps the existing floor.
- **Tap targets.** The design system's minimum touch size scales to about 81 design
  units, smaller than the game's current floor of 88; the larger floor stays.
- **Phones with notches or rounded corners.** The gutter and top bar sit inside the
  safe area at every window size in the layout matrix.
- **Reduced motion.** Every new state (press, lift, banner slide, wash change between
  Regions) has a still form.
- **Region wash between Regions and stages.** When the game moves to a new Region, or
  to the Final Journey or Final Battle, the wash changes to the new tint along with
  the banner, and the screens that show no Region (title, setup, records, rulebook) use
  the plain ground.
- **Dragon-specific lairs.** All four dragons use the single lair tint unless a dragon's
  lair art clearly calls for its own, which is noted rather than invented.
- **Colour-blind players.** Jade and danger, and lapis, amethyst and cinnabar, are
  never the only way something is told apart; the sign, icon or glyph is always there.
- **The ground pattern choice in the menu.** Today the player can choose one of four
  woodcut stone grounds. The choice is removed (owner, 2026-10-22): every screen is the
  flat `ground`, with the Region wash on the play screen. A saved setting from an
  earlier version is ignored, not an error.

## Requirements *(mandatory)*

### Functional Requirements

**Tokens**

- **FR-001**: The game's single source of visual values MUST hold every colour,
  typeface, type style, spacing step, chamfer, radius, border width, shadow and
  opacity named in the design system's `tokens.json`, with the same values, and the
  old night-stone palette MUST be removed rather than left beside it.
- **FR-002**: Every size in the design system (given in phone points) MUST be
  translated to the game's design units by the system's own factor (1.85 for the
  720-unit-tall layout), rounded to whole units, and the translation MUST be recorded
  once where the values are defined.
- **FR-003**: No screen, widget, overlay or effect MUST carry a colour, size or face
  of its own that is not taken from the tokens; the colours drawn into cards today as
  literals MUST move into tokens.
- **FR-004**: The old-to-new mapping in the design system's "Replacing the old
  palette" table MUST be applied everywhere an old colour role is used, choosing
  between the two new roles (`stone` or `stone-raised`, `edge` or `line`, `brass` or
  `brass-bright`) by what each use is for.

**Colour and grounds**

- **FR-005**: Every screen MUST be painted `ground`, with panels, trays and bars in
  `stone`, pressable slabs in `stone-raised` and sunken slots in `well`.
- **FR-006**: The play screen MUST lay a soft radial glow in the current Region's tint
  over the ground behind the Encounter or Region Card, at `opacity-region-wash`, with
  one tint per Region and the lair tint for the Final Journey and Final Battle.
- **FR-006a**: The patterned stone grounds and the menu's choice between them MUST be
  removed; a ground choice saved by an earlier version MUST be ignored without error.
- **FR-007**: Brass MUST be used only for the primary action, the selected thing and
  the slot being filled; `brass-bright` only for rewards and banner headlines. No
  panel, header, icon or rim at rest MAY be brass.
- **FR-008**: Each screen MUST show at most one brass (primary) button at a time.
- **FR-009**: Good outcomes and the focus ring MUST use `jade`; harm MUST use `danger`;
  each MUST always appear with a tick, minus sign, heart or skull.
- **FR-010**: All text and meaningful rims MUST meet the contrast stated for their
  pair in `tokens.json` (text at least 4.5:1, `edge` rims at least 3:1);
  `parchment-faint` MUST be used only for disabled labels.
- **FR-011**: The Ether colours MUST be the four mineral pigments and their bright
  partners, mapped drop to lapis (water), bolt to ochre (lightning), spark to amethyst
  (shadow) and flame to cinnabar (fire), and every place that colours by Ether MUST use
  them.

**Type**

- **FR-012**: Fraunces MUST replace Cinzel for the banner, title, heading, card-name and
  all numeral styles; Alegreya Sans MUST be used for label, button, body, body-sm and
  caption, in the weights the design system ships. Cinzel MUST no longer ship with the
  game.
- **FR-013**: Titles and headings MUST be title case; only banners, card names and
  labels MAY be uppercase.
- **FR-014**: Every game figure MUST use a numeral style with tabular figures.
- **FR-015**: No live text MAY be smaller than the existing minimum readable size,
  except text printed on a card (card names, the tags and ribbons on Hand cards, the
  names and titles in the Region and Dragon Cards' bands), which is fitted to the card
  and MAY go down to a floor that scales with the card's width: 18 design units on the
  narrowest phone's card, a step under the design system's `card-name` size; a line
  that reads second (a dragon's title) to 0.7 of that (owner, 2026-10-22).

**Shape, depth and states**

- **FR-016**: Stone elements (buttons, tabs, panels, trays, dialogs, banners, chips,
  wells) MUST have chamfered corners at the size the component rule names; only paper
  things (cards, plates on cards, pill chips) MAY be rounded.
- **FR-017**: Stone surfaces MUST carry an etched rim (`edge` at `border-edge` width
  plus a faint parchment line inside the top edge); selected and target states MUST
  replace the rim with a `border-select`-wide brass rim.
- **FR-018**: Depth MUST follow the design system's shadows: slabs bevelled and
  collapsing when pressed, brass buttons with their own bevel, wells inset, cards with
  a resting shadow and a larger lift shadow when held, dragged or inspected. No glows
  MAY be used for state.
- **FR-019**: The target, selected, pressed, disabled, out-of-play and focus states
  MUST each look as the design system's States section describes, wherever they occur.
- **FR-020**: Lesson coach tips, glossary entries, rulebook pages and the unspent XP
  question MUST be printed on `paper` with `paper-ink` and `paper-muted` text.

**Components**

- **FR-021**: Each component the design system describes (Banner, Button, Chip,
  CoachTip, Dialog, Ledger, MageCard, Panel, Slot, Tabs, TopBar) MUST be built once and
  used everywhere the game shows that kind of thing, following its README.
- **FR-022**: Labels and voice MUST follow the Voice section: sentence-case button
  labels that are verbs or outcomes, capitalised game terms, no exclamation marks or
  emoji. Existing wording that already complies MUST NOT be changed.

**Motion**

- **FR-023**: Slabs MUST press in about 80 ms and release in about 120 ms; cards MUST
  slide and settle with a short overshoot rather than fade while moving; banners MUST
  slide in over the scrim, hold and slide out. Every one of these MUST have a still
  form under reduced motion.

**Checks and records**

- **FR-024**: The automated checks MUST verify the rules that can be measured: the
  contrast of every text pair, the type floor (with the card-name exception), the tap
  floor, at most one brass button per screen, and at most one target slot.
- **FR-025**: The design system's reference files MUST stay with this feature, and the
  project's guidance on colours and type MUST point to them.

### Key Entities

- **Design token**: a named value (colour, type style, spacing, chamfer, radius,
  border, shadow, opacity, size) with a usage note saying where it may be used.
- **Type style**: a family, size, line height, weight, letter spacing and case, named
  by role (banner, title, heading, card-name, numeral-xl, numeral, numeral-sm, label,
  button, body, body-sm, caption).
- **Region tint**: the colour of one Region (or the lair), used for the ground wash,
  the banner rim and the medallion ring.
- **Ether pigment**: an Ether's field colour and its bright partner, with the ink that
  reads on each.
- **Component**: a recurring piece of the interface with its own rules, built from
  tokens.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of colours, faces and type sizes drawn by the interface come from
  the design system's tokens; a search of the interface finds no colour literal outside
  the token file, other than over-bright flash multipliers, which are not palette
  colours.
- **SC-002**: Every text and rim colour the interface draws is one of the token pairs
  in the plan's contrast table, and each pair meets its threshold (4.5:1 for text, 3:1
  for meaningful rims). Both are checked automatically: the pairs once, and the colours
  in use on every screen at every window size in the layout matrix.
- **SC-003**: On every screen the automated walks visit, at most one button is brass
  and at most one slot is the target.
- **SC-004**: Brass and bright-brass uses fall from about 120 today to only primary
  actions, selections, targets and rewards; no panel, header or icon at rest is brass.
- **SC-005**: No text on any screen uses the old display face, and the game's shipped
  size does not grow by more than 1 MB from the font change.
- **SC-006**: The full test suite (every unit test and every UI walk at every window
  size, still and animated) passes with no script errors.
- **SC-007**: Side by side with the design system's EncounterScreen preview at the same
  size, the game's Enemy Encounter matches it in ground, wash, panels, slots, card
  frame, brass use and type, as judged by the owner.
- **SC-008**: A first-time player can name the next thing to tap on the play screen
  within 3 seconds, because it is the only brass thing on screen.

## Assumptions

- The design system's `tokens.json` is the source of truth; the component previews and
  `bundle.css` are references for the look, not code to ship.
- The game's layout (top bar, Encounter or Region Card on the left, Action Set tray on
  the right, action row along the bottom), its rules, its art and its animations'
  choreography are unchanged; this feature changes how things look, not what they do or
  where they are.
- Sizes translate at 1.85 design units per phone point (the system's own factor), so
  `body` 15pt becomes 28, `caption` 12pt becomes 22 (the game's existing text floor)
  and `card-name` 11pt becomes 20. Where a translated size would break an existing
  floor, the floor wins except for card names (see Edge Cases).
- The tap floor stays at 88 design units, larger than the system's 44pt (81 units).
- The game's own icon set (slot glyphs, pile icons, Ether glyphs, stat shapes) is kept
  and drawn in a single colour that takes its colour from context; the word labels and
  diamonds in the previews are stand-ins.
- The lair tint is one colour for all four dragons, as the system proposes.
- Fraunces is set with its softness axis at 50 and its wonk axis at 0, as the system
  specifies. Both are the full upstream fonts under the SIL Open Font License, not
  the design system's web subsets, which lack tabular figures and the → glyph the
  game's text uses (plan research R3).
- The four painted pictures in the design system's `assets/Art/` are references only;
  the game ships its own art unchanged.
- Existing features' specs and contracts that name old colours (for example board
  responses, step emphasis and the coach mark) keep their behaviour; only their colours
  and materials follow the new system.
