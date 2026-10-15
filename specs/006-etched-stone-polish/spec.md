# Feature Specification: Etched Stone and Ether Rifts

**Feature Branch**: `006-etched-stone-polish`

**Created**: 2026-10-15

**Status**: Draft

**Input**: User description: "Board, zone and UI personality polish (assessment: .specify/assessments/board-ui-polish/decision.md, verdict go). Problem: Dragons of Etchinstone plays correctly but feels like a generic dark app — static between moments, spending screen space restating information — and needs an identity of its own, life, and space that earns its place, across every screen. Approach: \"Etched Stone and Ether Rifts\" — the world as carved dark stone with zones read as engraved places; Ether rift light tinted by the current Encounter's Ether glowing through seams for each Region's and fight's mood; ambient life (shimmering seams, drifting motes, zones lighting when relevant); lore framing per screen (title as the Tower / The Tear, setup as the elders' proclamation, ending, rulebook and overlays as stone slabs and scrolls). Staged: (1) space — shrink the \"which card for which role\" area above the Hand to what it needs, remove empty/dead zones; (2) play-screen style frame approved by the owner against the current screenshot before rollout (exit point); (3) rollout to Final Battle, title, setup, rules, ending and overlays. Out of scope: rules, card data, balance, new content, portrait, new platforms, music and sound, a light/parchment palette, publisher art or trade dress, redrawing creature and dragon silhouettes, formal device benchmarking as a gate. Success: owner prefers the after in a side-by-side of every screen; less screen share restating information during card selection; no zone with a large unused area in standard screenshot states; owner can name what moves or responds while idle and after each action; ui_check, layout-matrix and contrast checks still pass; no visible stutter on web and Android emulator."

## Context

Features 001 and 005 made the game legible and gave its cards real depth and Ether
character. Around the cards, though, every screen is still a set of identical rounded
dark panels on a near-black background. It reads as a competent dark-themed app
rather than a game set in Vale. The assessment in
`.specify/assessments/board-ui-polish/` found three problems:

1. **No identity.** Nothing outside the cards and creature art says *Dragons of
   Etchinstone*. The rulebook's world (the land of Vale, Ether rifts torn through
   it, the mages' Tower, an apprentice answering the elders' proclamation) is absent
   from the screens.
2. **Space that doesn't earn its place.** While building an Action Set, a band of
   large slots above the Hand repeats the name and values of each placed card. Those
   cards are already in the Hand and already marked with their role. The predicted
   outcome panel leaves much of its lower half empty, and there are gaps between
   zones.
3. **A static board.** Apart from the creature's idle breathing and the card fields'
   sheen, nothing moves or answers between the player's actions.

The chosen direction is **Etched Stone and Ether Rifts**. The world is carved dark
stone, and each zone reads as a place cut into it. Ether light from the rifts glows
through seams in the stone, tinted by the current Encounter, so each Region and fight
has its own mood. The work is staged so that the space fixes ship first and the
owner approves the look on the play screen before it spreads to every screen.

This feature changes presentation only. It does not change the rules, the steps of
play, or what the player can do in each step.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Space that earns its place (Priority: P1)

While building an Action Set, the player sees which card fills which role without a
large band of slots that repeats what the Hand already shows. The role assignment
takes only the room it needs, and the space it frees goes to what matters in that
step: larger cards, a clearer prediction, or room to breathe. No zone on the play
screen sits mostly empty in any standard state.

**Why this priority**: It is the owner's one concrete complaint, it delivers value
whatever visual direction follows, and the rest of the look is designed around the
layout it settles. It ships even if the style frame (User Story 2) is rejected.

**Independent Test**: Take before and after screenshots of the play screen at each
build step (no card placed, one placed, all placed) and in the Final Battle. Measure
the share of the screen given to showing role assignments, and confirm the player
can still tell, at a glance, which card fills each role and which role is next.

**Acceptance Scenarios**:

1. **Given** the player is building an Action Set, **When** no card is placed yet,
   **Then** the screen shows which roles must be filled and which comes next, in less
   space than today's slot band.
2. **Given** a card has been placed in a role, **When** the player looks at the
   screen, **Then** they can tell which card fills that role and what it contributes,
   without the card's name and values being shown again at full size elsewhere.
3. **Given** the Boost role targets a stat ("Boost adds to Attack"), **When** the
   Boost card is placed, **Then** what it boosts is still shown.
4. **Given** any standard play state (building, resolving, Soak, Upgrade, Final
   Battle Journey and Enemy), **When** shown at the minimum window size, **Then** no
   zone has a large empty area while another zone is cramped.
5. **Given** the player wants to undo a placement, **When** they act on the
   placed card or its role, **Then** removing it works at least as easily as
   today.
6. **Given** the Final Battle with two Action Sets, **When** cards are placed,
   **Then** both sets' role assignments are shown, and still more compactly than
   today.

---

### User Story 2 - A play screen carved from stone and lit by the rift (Priority: P2)

The play screen becomes a place in Vale. Its surface reads as dark carved stone; the
Encounter, prediction, Hand and actions read as places cut into that stone, each with
its own weight, so the eye knows where to start. Ether light from the rift glows
through seams in the stone, tinted by the current Encounter's Ether, so a Fire
Encounter feels hot and a Shadow Encounter feels cold and strange. Headings, borders
and dividers use the same woodcut, linocut language as the creature art. This screen
is the style frame: the owner judges it against the current screenshot before the
look spreads anywhere else.

**Why this priority**: It answers the main complaint, "generic, no identity", and
tests the direction on the screen the player sees most. It is the decision point for
whether User Story 4 proceeds.

**Independent Test**: Show the restyled play screen beside the current one in the
same game state and ask the owner which looks more like *Dragons of Etchinstone* and
more finished. Show screenshots from Encounters of each of the four Ethers and
confirm each has a distinct mood.

**Acceptance Scenarios**:

1. **Given** the play screen in any state, **When** shown, **Then** its surface and
   zone frames read as carved stone, not as flat panels.
2. **Given** Encounters of each of the four Ethers, **When** each play screen is
   shown, **Then** the rift light differs by Ether and a viewer can name the Ether
   from the board alone, not just from the cards.
3. **Given** the play screen, **When** shown to a first-time viewer for 5 seconds,
   **Then** they can still name the Encounter, the predicted result and the Play
   control.
4. **Given** text and values on any restyled surface, **When** measured, **Then**
   they meet the same size and contrast minimums as today.
5. **Given** the owner compares the restyled play screen with today's in the same
   state, **When** asked, **Then** they prefer the restyled one. If they do not, work
   stops after this story, and User Story 1 remains delivered.

---

### User Story 3 - A board that is alive (Priority: P3)

The board moves gently while the player thinks and answers every action. The rift
seams shimmer, motes of Ether drift up from the light, and the zone that needs the
player's input next lights up. Placing a card, filling a role, playing a set, taking
damage and winning an Encounter each draw a visible response from the board, not just
from the card involved. All of it stays quiet enough not to distract and stops when
the player asks for reduced motion.

**Why this priority**: It answers "feels static" and completes the style frame, but
the stone and light (User Story 2) must exist first for the life to live in.

**Independent Test**: Leave the play screen idle for 10 seconds and list what moves.
Then perform each player action in turn and list what on the board responds. Turn on
reduced motion and confirm the ambient motion stops.

**Acceptance Scenarios**:

1. **Given** the play screen is idle, **When** watched for 10 seconds, **Then** at
   least two kinds of ambient motion are visible (for example, shimmering seams and
   drifting motes), and none of it flashes or pulls the eye from the cards.
2. **Given** a step that needs the player's input in a particular zone, **When**
   that step begins, **Then** that zone visibly lights up, and the light moves when
   the step moves to another zone.
3. **Given** each player action (place a card, remove a card, Fuse, Divert, Regroup,
   Play, Soak, Upgrade, win or lose an Encounter), **When** performed, **Then** the
   board shows a response the owner can name.
4. **Given** reduced motion is on, **When** the play screen is shown, **Then** ambient
   motion stops, the rift light holds still, and the active zone is marked without
   animation.
5. **Given** the play screen with ambient motion running, **When** played on the web
   build and the Android emulator, **Then** there is no visible stutter while idle,
   while placing cards, or during the resolution sequence.

---

### User Story 4 - Every screen in the same world (Priority: P4)

Once the owner approves the style frame, the same stone and rift light carry
through the rest of the game, each screen framed by the lore. The title is the Tower
or The Tear. The dragon and rules setup reads as the elders' proclamation. The
Region banner, Final Battle, ending, rulebook, glossary, card inspection, menu and
dialogs read as stone slabs and scrolls of the same world. The same dead-space and
liveliness standards apply on every screen.

**Why this priority**: Coherence across the game is a goal, but it is only worth
doing once the direction is approved on the play screen.

**Independent Test**: Take before and after screenshots of every screen and overlay
in the standard screenshot set and show them side by side to the owner, screen by
screen.

**Acceptance Scenarios**:

1. **Given** the title screen, **When** shown, **Then** it presents the Tower or The
   Tear and leads into the game in the same stone and rift language.
2. **Given** dragon and rules setup, **When** shown, **Then** it reads as the elders'
   proclamation calling the apprentice, and every choice and value shown today is
   still there and still as legible.
3. **Given** the Final Battle's Journey and Enemy steps, **When** shown, **Then** they
   use the play screen's look, with the dragon's Ether lighting the rift.
4. **Given** the ending screen (victory or loss), **When** shown, **Then** it reads
   as an inscribed stone or chronicle and responds visibly to the outcome.
5. **Given** any overlay (rulebook, glossary, inspect, menu, confirm dialog,
   Region banner), **When** opened, **Then** it reads as a slab or scroll of the same
   world and stays fully legible.
6. **Given** each screen's before and after, **When** shown side by side, **Then**
   the owner prefers the after on every screen.

---

### Edge Cases

- **Reduced motion**: every ambient and feedback motion has a still equivalent;
  nothing a player needs is conveyed only by motion.
- **No Encounter Ether**: screens with no current Encounter (title, setup, menus,
  ending) and Encounters without an Ether use a neutral rift light that still
  belongs to the same world.
- **Ether changes mid-screen**: moving from one Encounter to the next, or from a
  Region into the Final Battle, shifts the rift light smoothly rather than snapping.
- **Smallest and largest windows**: on every window in the existing layout matrix
  (small phone through ultrawide, safe-area insets, flipped landscape), the stone
  framing never covers content, crowds tap targets, or leaves bars of plain
  background.
- **Busy moments**: during the resolution sequence and flying cards, ambient motion
  does not compete with or obscure the sequence.
- **Many cards**: the Final Battle's two Action Sets and a full Hand still fit,
  with no less room per card than today.
- **Ether colour against Ether light**: a card of one Ether shown over rift light of
  another stays readable and does not clash into mud.
- **Owner rejects the style frame**: User Story 1 remains shipped and consistent
  with the existing look; no half-restyled screens are left behind.

## Requirements *(mandatory)*

### Functional Requirements

**Space (User Story 1)**

- **FR-001**: While building an Action Set, the game MUST show which role each placed
  card fills and which role comes next, in a smaller share of the screen than today's
  slot band.
- **FR-002**: The game MUST NOT repeat a placed card's name and values at full size
  outside the card itself. A compact indication of role and contribution is
  allowed.
- **FR-003**: What the Boost card boosts MUST remain visible once a Boost card is
  placed.
- **FR-004**: Removing a placed card MUST remain at least as easy and discoverable as
  today.
- **FR-005**: In every standard play state, a zone MUST NOT show a large unused area while
  another zone is cramped. The space freed MUST go to content in that state (cards,
  prediction, Encounter) or to deliberate breathing room.
- **FR-006**: The Final Battle's two Action Sets MUST follow the same compact role
  display.

**Stone and rift light (User Stories 2 and 4)**

- **FR-007**: Every screen's background and zone frames MUST read as carved dark stone,
  with zones as distinct places in it, replacing the flat rounded panels.
- **FR-008**: Zones MUST differ in visual weight, so the zone that matters in each step
  draws the eye first.
- **FR-009**: Rift light MUST glow through the stone and take its tint from the current
  Encounter's Ether (the dragon's Ether in the Final Battle), with a neutral light
  where there is none.
- **FR-010**: Each of the four Ethers MUST give the board a distinct, nameable mood.
- **FR-011**: Headings, borders, dividers and frames MUST share the woodcut and linocut
  language of the existing creature art.
- **FR-012**: The title, setup, ending and overlay screens MUST each carry the lore
  framing named in User Story 4.

**Life (User Story 3)**

- **FR-013**: The idle play screen MUST show at least two kinds of gentle ambient
  motion that do not flash or draw the eye from the cards.
- **FR-014**: The zone needing the player's input in the current step MUST visibly
  light up, and the light MUST follow as the step changes.
- **FR-015**: Each player action listed in User Story 3, scenario 3, MUST draw a
  visible response from the board.
- **FR-016**: With reduced motion on, ambient motion MUST stop and every response MUST
  have a still equivalent.

**Guardrails**

- **FR-017**: Every text and value MUST meet the existing size and contrast minimums
  on every restyled surface, and every control MUST meet the existing minimum tap
  size.
- **FR-018**: The existing automated layout, layout-matrix and contrast checks MUST
  pass. They may be extended, not loosened.
- **FR-019**: Rules, steps of play, card data and available actions MUST NOT change.
- **FR-020**: Everything shown today on each screen MUST still be available, unless
  it is a duplicate removed under FR-002.
- **FR-021**: The game MUST NOT reproduce the publisher's artwork or trade dress beyond
  the card faces that already follow the official cards.

**Staging**

- **FR-022**: User Story 1 MUST be complete and consistent with the current look on
  its own, before any restyle.
- **FR-023**: The restyle MUST reach the other screens only after the owner has
  approved the play-screen style frame (User Story 2, scenario 5).

### Key Entities

- **Zone**: a place on a screen with one job (Encounter, prediction, roles, Hand,
  actions, header, or a whole overlay). It has a visual weight and may be the active
  zone for the current step.
- **Rift light**: the Ether-tinted light that glows through the stone. Its tint comes
  from the current Encounter's or dragon's Ether, or is neutral.
- **Role assignment**: which placed card fills Spell, Element or Boost (and which set,
  in the Final Battle), plus what the Boost targets.
- **Lore framing**: the in-world identity a screen takes (Tower or Tear, proclamation,
  slab, scroll, chronicle).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: During Action Set building at the minimum window size, the screen area
  used to show role assignments falls by at least half compared with today's slot
  band.
- **SC-002**: In every state of the standard screenshot set, no zone is more than a
  third empty, judged on the minimum window sizes. A zone is the panel drawn on
  screen (for the Hand, the panel around its cards). The stone between panels is
  background, not empty zone.
- **SC-003**: In a side-by-side before/after of each screen and overlay in the
  standard screenshot set, the owner prefers the after on every one.
- **SC-004**: Shown a still of the board with the cards and the Encounter frame covered, a viewer
  names the Encounter's Ether correctly in at least 3 of 4 Ethers.
- **SC-005**: A first-time viewer shown the play screen for 5 seconds names the
  Encounter, the predicted result and the Play control (as in feature 005).
- **SC-006**: The owner can name at least two ambient motions on the idle play screen,
  and a board response for every action listed in User Story 3.
- **SC-007**: All existing automated layout, layout-matrix and contrast checks pass on
  every window in the matrix.
- **SC-008**: No visible stutter on the web build or the Android emulator while idle,
  while placing cards, or during resolution.
- **SC-009**: With reduced motion on, nothing on any screen moves ambiently.

## Assumptions

- The landscape-only, 1280 × 720 minimum layout from feature 001 stays. Zones on the
  play screen may be rearranged or resized to meet User Story 1, but the screen keeps
  the same jobs.
- Placed cards stay visible in the Hand with their role marked (as today), which is
  what lets the role band shrink.
- The stone and light can be drawn by the game itself. Generated textures from the
  Windows PC art pipeline may be used if drawn stone falls short; they go through
  the usual hand-off there.
- The existing creature and dragon silhouettes and the Mage Card faces from feature 005
  are reused as they are. Cards keep their own look and sit on the stone.
- The reduced-motion setting from feature 001 is reused.
- The "standard screenshot set" is the set the existing screenshot tooling produces,
  extended to any screen or state it does not cover yet.
- The owner is the only judge of preference (SC-003). Fresh before screenshots are
  taken from the current build before any change.
- Music and sound, portrait orientation, new platforms, a light or parchment palette,
  new content and formal device benchmarking are out of scope.
- If the owner rejects the style frame, the feature ends after User Story 1, and a
  different direction would be assessed separately.
