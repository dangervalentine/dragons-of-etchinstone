# Problem Definition: Board, Zone and UI Personality Polish

- **Slug**: board-ui-polish
- **Created**: 2026-10-15
- **Inputs used**: intake.md, research.md, and the owner's answers on 2026-10-15

## Problem Statement

Dragons of Etchinstone plays correctly, but its screens feel like a generic dark app
rather than a game with its own world. The board is static between moments, and screen
space goes to repeated information while what matters competes for room. The owner
wants it to feel distinctive and finished. After two presentation passes (001, 005),
the remaining gap is identity, liveliness and space use, not legibility or rules.

## Affected Users & Stakeholders

- **Users**: the player, currently the owner, playing on phone, tablet and web — sees
  every screen on every turn. Today the game looks plain and unmemorable to them
  [source: owner answers; `research.md` Users & Demand]
- **Users**: people who know the physical game — [NEEDS CLARIFICATION: is anyone beyond
  the owner expected to play it? Research found no other users.]
- **Stakeholders**: the owner — sole decider and builder. Also generates art on the
  Windows PC [source: `research.md` Prior Art]
- **Stakeholders**: Joe Klipfel and Chip Theory Games (rights holders) — affected by how
  much of the original's look a fan version reproduces [source: title-screen
  disclaimer; `research.md` Data & Constraints]

## Goals

1. **Identity**: every screen reads as *this* game. A viewer could tell it apart from a
   generic dark-themed app, and it feels of a piece with the creature and dragon art.
2. **Space earns its place**: no screen area is spent restating information shown
   elsewhere, or left empty while other areas are cramped. The owner's named example:
   while cards are being chosen, a large area above the Hand calls out which card is
   selected for which role, and it takes more room than that job needs.
3. **Life**: the board feels alive between and during player actions, not only when a
   card resolves.
4. **Coherence across the whole game**: the title, setup, rules, play, Final Battle,
   ending and overlays share one recognizable character.
5. **Nothing lost**: legibility, touch-target minimums, contrast, landscape safe areas
   and the existing layout and contrast checks all still hold.

## Non-Goals

- Changing any game rules, card data or balance.
- Portrait orientation or new platforms.
- New gameplay features or content (new modes, new Encounters, sound design as its own
  effort) — [NEEDS CLARIFICATION: is audio in or out? It bears on "life".]
- Running the outstanding verification tasks from 001 and 005 (device performance,
  observer tests) as a gate or baseline. The owner chose to skip them.
- Committing in advance to a visual direction. Direction is an open question for the
  shape stage.
- Reproducing the publisher's artwork or trade dress wholesale.

## Success Metrics

All of these are qualitative or owner-judged. There is no player population to measure.

- The owner judges each screen to have "personality and polish". Before/after
  screenshots of every screen sit side by side, and the owner prefers the after on
  each (baseline: the current matrix screenshots).
- Space use: on the play screen during card selection, the share of the screen that
  restates information visible elsewhere goes down. In particular, the "which card
  for which role" area shrinks (baseline: [NEEDS CLARIFICATION: measure that area's
  current share of the 1280×720 layout from a fresh screenshot]).
- Empty regions: no zone shows a large unused area in the standard screenshot states
  (baseline: preview-panel lower half and the band above the Hand are empty in
  `05_challenge_assigned.png`).
- Life: the owner can name, for an idle play screen and for each player action, what
  moves or responds (baseline: [NEEDS CLARIFICATION: inventory of current idle and
  feedback motion]).
- Guardrail: `tools/ui_check.gd`, the layout-matrix checks and the contrast tests pass
  unchanged (baseline: passing today, per 001/005).
- Guardrail: no visible stutter on the web build and the Android emulator during play
  (baseline: unmeasured; owner chose not to set a formal one).

## Cost of Inaction

The game stays fully playable and legible. It keeps looking like a competent but
generic dark UI. The cards and creature art carry all its character, the frame around
them stays neutral, and some screen space stays wasted. Nothing breaks, but the owner
remains dissatisfied with how the game feels. The cost is purely in presentation and
satisfaction, not function [source: `research.md` Market & Context].

## Open Questions

- [NEEDS CLARIFICATION: Which visual direction gives the "personality": the etched-stone
  and woodcut style of the existing art, the physical game's look, or another? Owner
  left this open for the shape stage.]
- [NEEDS CLARIFICATION: How much of the physical game's look is acceptable to reproduce
  in a fan version?]
- [NEEDS CLARIFICATION: Is sound and music in scope as part of "life"?]
- [NEEDS CLARIFICATION: May the seven-zone arrangement of the play screen be
  rearranged, or only restyled? The "every screen" scope suggests the reach is wide,
  but this was not stated.]
- [NEEDS CLARIFICATION: Can it rely on new art from the Windows PC (backgrounds,
  textures, frames), or should it work with existing assets plus code-drawn effects?]
- [NEEDS CLARIFICATION: Fresh screenshots of the current build. The research
  screenshots predate the last five commits.]
- [NEEDS CLARIFICATION: Is anyone besides the owner expected to play it, and does that
  change the bar?]
- [NEEDS CLARIFICATION: How much effort is this worth: one feature branch, or a
  series?]
