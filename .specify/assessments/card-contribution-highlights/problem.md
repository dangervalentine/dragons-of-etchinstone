# Problem Definition: Free the math box's space without losing what it does

- **Slug**: card-contribution-highlights
- **Created**: 2026-10-17 (reframed the same day after owner correction)
- **Inputs used**: intake.md, research.md (including the owner answers recorded there)

## Problem Statement

The owner wants the left column's math box free for a follow-up redesign. The box cannot simply be removed, because it currently carries jobs the game depends on:
- It is the only place the Boost is aimed, and Play is gated on that aim.
- It is the only place that shows which card values count toward the result.
- It is the only place that shows how a Hardship or Enemy ability bears on the player's cards.

[research: preview_panel.gd:304-437; turn_draft.gd:167-177; view_state.gd:669] Those jobs must move elsewhere, so that the space frees up without breaking current functionality.

The owner's stated motive is to free the space, not to hide the outcome from players. Dropping the spelt-out predicted totals and verdict is accepted as part of freeing it ("they can figure out if they have it or not") [owner, 2026-10-17].

## Affected Users & Stakeholders

- **Users**: players of Dragons of Etchinstone on phone, tablet, desktop and web.
  - They must still be able to aim each Boost and see which card parts count and which a Hardship or Enemy ability affects, once the math box no longer shows these.
  - The XP spend is touched in the same pass: it gains stars flying to the levelled card.
- **Stakeholders**:
  - The project owner, who sets direction and scope [intake].
  - The follow-up spec that will use the freed left-column space. It needs the box emptied of load-bearing functions and left in a usable interim state [intake; research Owner Answers].

## Goals

- **G1 Free the space:** the math box no longer holds any function the game needs. Before Play it shows none of the player's predicted totals, verdict, costs or loss warning, and holds only a short interim tip that the follow-up spec can replace freely.
- **G2 Keep "what counts" visible:** on any placed card, the player can tell which parts will count toward the result if Play is pressed now, and which a Hardship or Enemy ability will work against. Neither relies on colour alone [research: design-tokens.md:66].
- **G3 Keep Boost aiming:** the player can still aim each Boost (one per set in the Final Battle) on every supported screen size. Play stays unavailable until every Boost that needs an aim has one [owner answer].
- **G4 Keep Hardship and ability effects visible:** they show at their source (the Enemy panel or the Journey) and where they land on the player's cards [owner answer].
- **G5 XP spend (bundled change):** spending XP shows stars travelling from the XP number to the card being levelled. Undo restores the number, and unspent XP visibly goes away at the end of the Encounter [owner; research: rulebook.txt:790].
- **G6 No regressions:** every behaviour the math box supported today still works or has a stated replacement, and the test suite and UI checks pass.

## Non-Goals

- Designing what the freed space will hold (the follow-up spec).
- Hiding information from players as a design aim in itself.
- Changing the Enemy stats panel or the Journey's displayed values.
- Changing the post-Play recap (verdict, damage, time). It stays for now.
- Any game rule change.
- Changing the soak meter beyond what the shared column requires.
- A tutorial or onboarding flow beyond a short general tip.

## Success Metrics

- **Measurable:**
  - Before Play, the math box shows only the interim tip in every encounter type (Enemy, Journey, Final Journey, Final Enemy). No player prediction, verdict, cost pill or loss warning appears there or on Play. (Baseline: all shown.)
  - Every function the math box hosts today is either moved (Boost aim, contributing parts, Hardship and ability effects) or explicitly retired (predicted totals, verdict, loss warning), with none left implicit. (Baseline: all in the box.)
  - For every placed card in each encounter type, the parts marked as contributing are exactly the ones the engine counts, checked automatically against the engine's terms. (Baseline: emphasis ignores the Boost aim and Night Travel [research: emphasis.gd].)
  - Every Hardship or Enemy ability that takes from a card value shows its icon at the source and beside each affected badge:
    - Night Travel on the Boost and the Element's Initiative.
    - Steep on the Reserve's Boost.
    - Ranged and Freeze on the Reserve.
  - Each Boost's aim can be set and changed on all target sizes with a tap target of at least 88 (tokens.gd:16). Play is gated until it is set, including both Boosts in the Final Battle.
  - Each level-up step sends as many stars as it costs from the XP number to the levelled card, and the number counts down. Undo counts it back up. (Baseline: the number changes with no motion.)
  - The automated suite and the UI check pass, with the requirements they encode updated explicitly rather than skipped. (Baseline: about a dozen tests and the UI check depend on the math box.)
- **Qualitative:**
  - The follow-up spec can take over the box's space without needing to move anything else out of it first.

## Cost of Inaction

The follow-up left-column redesign stays blocked, or has to move the Boost aim and the per-card information itself while also designing the new column. That would mix a functional move with a redesign in one pass, which is harder to verify and riskier for regressions. Players lose nothing today.

## Open Questions

- [NEEDS CLARIFICATION: Should a Boost aimed at Initiative be marked differently from one aimed at Attack beyond its aim icon?]
- [NEEDS CLARIFICATION: How does a tap area that reaches past the Boost badge (to meet the 88 minimum) coexist with tap-to-swap and drag on the same card?]
- [NEEDS CLARIFICATION: Wording of the interim tip — one generic line, or one per step (setup, place cards, aim Boost, Upgrade)?]
- [NEEDS CLARIFICATION: Do the number flights and tally/verdict reveal that land on the math box today (animator.gd:88,91) move to the cards, or are they retired with it?]
- [NEEDS CLARIFICATION: How does unspent XP visibly go away at the end of the Encounter, now that it stays a number?]
