# Research: UI Polish and Presentation Overhaul

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Date**: 2026-10-13

Findings come from reading the current code (`ui/main.gd`, `engine/`, `tools/`),
the card scans in `reference/sheets-official/`, the current device screenshots in
`build/screenshots/`, and probing the installed Godot 4.7.2.

## What the current UI does, and why it cannot be polished in place

- `ui/main.gd` (876 lines) frees every node and rebuilds the screen after each tap
  (`_refresh`). Nothing persists between two states, so nothing can move from one
  place to another. Animation needs nodes with identity.
- The engine applies an action in one call. By the time the UI redraws, the Hand has
  been redrawn, damage assessed and the phase advanced. What happened is reported as
  a text summary on the next screen.
- Text is 13 to 17 design units and buttons are 56 units tall on a 720-unit-wide
  design. On a 390-point-wide phone that is roughly 7 to 9 point text and 30 point
  tap targets. Both are below comfortable minimums.
- The layout is one 720-unit column inside a scroll container at every window size,
  and the project is locked to portrait on phones.

## Direction set after the first draft of this plan

The game is landscape only (spec, Clarifications): one arrangement, on phones,
tablets and desktop alike. There is no portrait arrangement. R4, R5 and R9 below
reflect this.

## R1. Screen architecture

**Decision**: Persistent screens made of small code-built widgets, one script each,
under `ui/`. `main.gd` shrinks to a root that owns the game, the current screen and
input routing. One `PlayScreen` serves every in-game phase (challenge, soak,
upgrade, both Final Battle stages); only its decision panel changes with the phase.

**Rationale**: A card must be the same node while it sits in the Hand, moves to a
slot, gets Downgraded and is discarded, or it cannot animate. Keeping one play
screen across phases gives that for free and satisfies FR-001 (stable regions).
Building in code matches the existing style, keeps diffs reviewable, and keeps
`tools/shot.gd` able to drive the real UI.

**Alternatives considered**:
- *Keep the rebuild and tween the new tree in*: gives fades only; no card travel, no
  cause and effect. Fails FR-021 and FR-022.
- *Author `.tscn` scenes in the editor*: nicer for hand-tuning, but scene files are
  awkward to write and review outside the editor, and every widget here is
  data-driven anyway.
- *Move to 2D nodes (Sprite2D, Node2D)*: easier free movement, but loses containers,
  focus, theming and text layout. Controls can be moved freely once taken out of
  container flow (see R3).

## R2. Getting a sequence of events out of an engine that resolves in one call

**Decision**: Do not change `engine/`. Before an action the UI takes a snapshot of
the game (zones, card Levels, phase, counters); after it, a second snapshot. A pure
function, the *sequencer*, turns (before, action, result, after) into an ordered
list of presentation steps. The view then plays the steps. The model is always
already in its final state; the view catches up.

**Rationale**: FR-027 and FR-037 require that animation cannot affect results and
that rules do not change. Model-first makes that structural: skipping an animation
is just "jump the view to the state the model is already in" (FR-024), and a crash
or resize mid-animation cannot corrupt the game. The snapshot diff captures
everything the engine does implicitly (time penalty paid from the deck, Knock Out
discards, trashing a Level 1 card, reshuffle at Region change) without the engine
having to report it. The sequencer is pure, so it is covered by headless tests.

**Alternatives considered**:
- *Add an event log to the engine*: more exact, but touches the frozen rules code
  and the 102 passing tests' subject. The diff has proven sufficient on paper for
  every engine path (see data-model.md, step derivation table).
- *Step the engine in smaller calls*: changes the engine's contract and its tests.

**Consequence**: The UI reads three engine internals today (`_soak_value`,
`_reserve`, `_regrouped`). These reads are confined to `ui/model/view_state.gd` so
exactly one file depends on them.

## R3. Animation and skipping

**Decision**: A single `Animator` runs one step list at a time using Godot `Tween`s
on persistent nodes. Moving cards are reparented to a free-positioned overlay layer
for the duration of a move, then handed to their destination container. While a
sequence runs, a full-screen input catcher turns the first tap or key press into
"skip": every tween is killed, every node is snapped to its end state from the
after-snapshot, and input is released. The press that skips is consumed.

**Rationale**: Consuming the skipping press is what guarantees an input is never
applied to the wrong step (edge case: repeated tapping). Snapping from the snapshot
rather than fast-forwarding tweens (`Tween.custom_step`, confirmed available) means
the end state never depends on animation code being correct.

**Timing budget** (SC-007: at most 3 s unskipped): cards to Encounter 0.35 s, tally
0.6 s, verdict 0.4 s, each consequence 0.25 to 0.35 s, redraw 0.12 s per card. A
worst case with every consequence is capped by compressing step durations
proportionally when the sum would exceed 3 s.

**Alternatives considered**: `AnimationPlayer` (suits authored, fixed animations,
not data-driven moves between computed positions); per-widget ad-hoc tweens (no
single place to skip or order them).

## R4. Responsive layout and scaling

**Decision**: One landscape arrangement with a minimum design size of 1280 x 720
units. The scale is the largest at which that minimum fits inside the window's safe
area (`min(w / 1280, h / 720)`). Space left over on the unconstrained axis is given
to the layout, not to margins: the design size grows (up to a maximum of 1760 x 990)
and the regions grow with it, cards first. A pure `layout_solver` returns the scale,
the design size and the rectangle of each region; widgets are placed from that.

Worked examples: a 16:9 phone gives exactly 1280 x 720; a tall notched phone about
1460 x 720 inside its safe area; an iPad 1280 x 960; a 1440 x 900 browser
1280 x 800.

**Project settings that follow**: the base design size becomes 1280 x 720 and the
mobile orientation becomes landscape in either direction (it is portrait-only
today).

**Thumb reach** (FR-028a): the Hand runs along the lower right, the primary action
sits in the bottom right corner and the secondary actions beside it, so everything
pressed every turn is under the right thumb, with the left thumb free for the
Encounter side (help taps, inspecting).

**Windows the layout does not suit** (FR-002): nothing scrolls. If the window is
taller than it is wide, or the scale falls below the point where 22-unit text is
about 9 points, the game is still drawn at the reduced scale, centred, and a
dismissible notice asks the player to turn the device or widen the window. On the
mobile apps this cannot happen because orientation is locked.

**Rationale**: One arrangement means one layout to design, fit-check and test, and
every animation path has a single set of positions. A pure solver is testable
headless against a matrix of sizes (SC-001, SC-008). This replaces `_fit_window`
and the scroll container.

**Alternatives considered**: a second, portrait arrangement chosen by whichever
fits at the larger scale (drafted, then dropped at the user's direction: landscape
only); fixed 16:9 letterboxing (wastes space on tablets and tall phones, fails
SC-008); breakpoints with different region structures per size (duplicated logic
for no gain at these aspect ratios).

## R5. Type sizes and tap targets

**Decision**: In design units, where a phone held sideways is 720 tall (about 2
units per point):
no text that must be read is smaller than 22; body is 26; card numerals 30 and up;
every tap target is at least 88 on its shorter side.

**Rationale**: Equivalent to roughly 11 point minimum text and 44 point targets,
the platform norms. The current UI is at about half of both.

**Fit check at 1280 x 720** (the smallest supported case). Header 56 across the
top; 16-unit margins leave a body 1248 wide and 624 tall, split into a left column
of 420 and a right column of 812.

- Left column: Encounter face 340, preview 276, gap 8. Total 624.
- Right column, Region Encounter: slot row 120, Hand (four cards at 190 x 266),
  actions and commit in one row of 96, gaps 16. Total 498, leaving about 125 to
  enlarge the cards on taller screens.
- Right column, Final Battle (seven cards, two Action Sets): both Action Sets side
  by side in one row of 104 (six slots of 135), Hand in two rows of four and three
  at 146 x 196 (400), actions and commit 88, gaps 24. Total 616, leaving 8.

The Final Battle is the tightest fit in the game. If it does not hold
up in practice, the commit control moves to the foot of the left column under the
preview, which frees 96.

## R6. Card and Encounter faces without the scanned art

**Decision**: Draw faces procedurally. A `CardFace` control draws the frame, the
Ether-coloured field and the stat column with custom drawing and theme styles; a
small canvas shader supplies the field's swirl pattern and a vignette. In place of
the mage illustration each card carries a large Ether sigil; each dragon gets its
own sigil. Layout follows the printed card: crown and name across the top, then
down the left edge Initiative, basic action, enhanced action, Boost, Armor, with
the Key Card strip (Encounter type, index, Hardship) under the name and the Upgrade
cost at the foot. New icons are added to `tools/gen_icons.py`, which already
generates the set.

**Rationale**: The spec's first assumption excludes shipping the scans. The printed
card shows two Levels per side, one inverted, because a physical card is rotated to
change Level; on screen only the current Level is needed, which frees half the face
and makes the numbers larger than print. The other Levels live in the inspect view
(FR-013). SC-010 is about position correspondence, which this preserves.

**Alternatives considered**: crop the scans into textures (excluded by assumption;
also 5 MB sheets, and upside-down second Levels baked into the art); commission or
generate illustrations (out of scope; can be dropped into the sigil's place later
without layout change).

## R7. Fonts

**Decision**: Two families under the SIL Open Font License, bundled in `art/fonts/`
with their licence files: **Cinzel** for titles, card names and card numerals (a
Trajan-style inscriptional face, the same genre as the printed cards), and
**Alegreya Sans** for body and interface text, with lining figures switched on.

**Rationale**: Nothing from the reference material may ship, so the printed font is
not available. Cinzel reads as the same world; a humanist sans keeps small text
legible on phones. Both have the weights needed. About 300 KB added to the web
build.

**To verify during implementation**: Alegreya Sans defaults to old-style figures;
confirm the lining-figures feature renders in the web export. Fallback body face:
Source Sans 3 (also OFL).

## R8. Reduced motion and settings

**Decision**: A game setting with three values: follow the device (default), on,
off. "Follow the device" reads `DisplayServer.accessibility_should_reduce_animation()`
(present in 4.7.2; returns -1 when the platform cannot say) and, on web, falls back
to the browser's `prefers-reduced-motion` media query. The setting is stored in a
small local settings file. In reduced mode the Animator plays the same steps with
travel, shake and particles replaced by cross-fades of at most 0.15 s.

**Rationale**: FR-026. The same step list in both modes means reduced motion cannot
drift out of sync with what full motion shows. A settings file is not a saved game,
so it stays inside the spec's scope.

## R9. Input: touch, mouse and keyboard

**Decision**: Tap a Hand card to place it in the highlighted slot; tap a slot to
choose where the next card goes; tap a placed card to take it back (the current
model, kept because it is one tap per assignment). Press and hold a card, or
right-click it, to inspect. On desktop: hover states on everything interactive;
number keys choose Hand cards, Tab cycles slots, Enter commits, Escape cancels the
current mode or closes an overlay, `I` inspects, `?` opens help.

**Rationale**: FR-016, FR-020. Tap-to-place is already learned by anyone who has
played the current build, and every tap of a turn falls under the right thumb.

**Alternatives considered**: drag and drop as the primary gesture (slower on a
phone, a long reach across a sideways screen, conflicts with press-and-hold to
inspect). It can be
added later as a second way to do the same thing; the persistent card nodes make
that cheap.

## R10. Help text

**Decision**: A `glossary` table keyed by the same ids the card data uses (icons,
Hardships, Abilities, Perils, plus terms such as Reserve, Fuse, Divert, Soak, Key
Card). Each entry has a name and a one- or two-sentence explanation written for
this project and checked against `reference/rulebook.txt`. A headless test asserts
that every effect id appearing in `data/cards.json` has an entry.

**Rationale**: FR-035, FR-036. Short original wording avoids reproducing rulebook
text while agreeing with it. The existing one-line descriptions in `ui/main.gd`
are the starting point.

## R11. Testing a visual feature

**Decision**: Three layers.

1. **Unchanged engine suite** (`tools/test.sh`, 102 tests passing today): must stay
   green and unedited (SC-012).
2. **New headless tests of the pure UI model**: view state, turn draft, sequencer,
   layout solver, glossary coverage. These run in the same runner.
3. **A UI check script** that drives the real screens through a seeded game at a
   matrix of window sizes with animation skipped, asserting that every region lies
   inside the viewport, that no interactive control is under 88 units, that the play
   screen never scrolls, and that the game ends in the same state
   as the engine-only playthrough with the same seed and choices.

`tools/shot.gd` is extended to save screenshots across the same size matrix for
review by eye. The observer-based success criteria (SC-002 to SC-005, SC-009) are
checked by hand using quickstart.md.

**Rationale**: Layout and state logic are where regressions hide and both are
testable without a display. Looks and feel need eyes; the screenshot matrix makes
that fast.

## R12. Performance on web and mid-range phones

**Decision**: Stay on the Compatibility renderer. No full-tree rebuilds: widgets
update in place from the view state. Shaders are single-pass and texture-free.
Particles are CPU particles with small caps, used only for XP, damage and the win.
Fonts and icons are preloaded at startup.

**Rationale**: SC-006. The current build already runs on all three targets; the
risk is added overdraw and per-frame allocation, both of which this avoids.

## Open items carried into implementation

- Confirm lining figures in the web export (R7).
- Confirm what `accessibility_should_reduce_animation()` returns on iOS, Android
  and web builds; the web fallback covers the case where it reports unknown (R8).
- The card-scan assumption in the spec was not changed by the user before planning
  and is treated as accepted (R6).
