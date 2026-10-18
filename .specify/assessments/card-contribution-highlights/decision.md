# Decision: The cards tell the story; the math box steps aside

- **Slug**: card-contribution-highlights
- **Decided**: 2026-10-17
- **Verdict**: go
- **Artifacts reviewed**: intake.md | research.md | problem.md | concept.md

## Scorecard

| Criterion | Rating | Justification |
|-----------|--------|---------------|
| Problem validity | strong | The owner needs the math box's space for a follow-up pass. The box holds load-bearing jobs, so it cannot simply be cleared: the Boost aim that gates Play, which card values count, and Hardship and ability effects (preview_panel.gd; turn_draft.gd:167-177; view_state.gd:669). |
| Evidence strength | strong | This is an enabling refactor, so the evidence needed is what the box does and what depends on it. That is fully cited from the code: rules, emphasis, aim path, layout limits and the tests at stake. No user-demand evidence is needed for freeing space. |
| Value vs. inaction | adequate | Nothing breaks today, but the follow-up pass stays blocked, or has to mix moving these functions with a redesign (problem.md: Cost of Inaction). |
| Feasibility / appetite | strong | Option B is medium (one to two weeks) and reuses what exists: per-card emphasis, `terms` from the engine, the unused `_ink_for` hook, the flight layer and the Play gating on an unset aim. The XP change shrank to stars flying from a number. |
| Strategic fit | strong | It directly enables the owner's next planned pass. It reverses outcome-preview goals from specs 001, 006 and 010, which the owner frames as normal iteration. The constitution is still the blank template, so there is no written principle to check against. |
| Risk posture | adequate | The risks are named with fallbacks: the aim tap on a card that also swaps and drags, icon fit at 197×275, highlights that must match the engine everywhere, about a dozen tests plus ui_check to rewrite, and dropping the number flights. Option C's split remains available. The aim-tap and drag conflict is the least-tested risk. |

## Verdict & Rationale

**Go, with Option B.** This is an enabling change: free the math box's space for the follow-up pass without breaking what the box does today. Every job the box holds is accounted for: the Boost aim moves to the Boost card, the parts that count and the Hardship and ability effects move onto the cards, and the predicted totals, verdict and loss warning are retired. The evidence is the code itself and is strong, and Option B fits a medium appetite by reusing existing pieces. The weakest point is the on-card Boost aim's tap area sharing a card with swap and drag. It is carried into the spec as a requirement to prove, not a reason to wait.

## If needs-clarification

- Not applicable.

## If go — Handoff to `/speckit-specify`

- **Problem**: Free the left column's math box for a follow-up pass without breaking current functionality. The box is the only place the Boost is aimed (which gates Play), and the only place showing which card values count and how Hardships and Enemy abilities bear on them. Those jobs move onto the cards; the predicted totals, verdict and loss warning are retired. The XP spend gains a star animation in the same pass.
- **Chosen approach**: Option B — cards carry it all, aim on the Boost card, XP stars flying from the number.
  - **Math box:** stripped of every prediction (rows, verdict, cost pills, red loss edge; Play loses its `warning` look). It keeps its place in the left column and shows a short tip for the current step.
  - **Highlights:** each placed card lifts exactly the parts the engine counts, following the Boost aim, Night Travel, enhanced vs basic action, and the Reserve's Boost only when it counts. This is checked against the engine's terms.
  - **Hardship and ability icons:** they sit to the right of each affected badge and also stay at their source:
    - Night Travel on the Boost and the Element's Initiative.
    - Steep on the Reserve's Boost.
    - Ranged and Freeze on the Reserve.

    Source icons stay on the Enemy panel and on the Journey.
  - **Boost aim:** each Boost card shows a small Attack or Initiative aim icon beside its badge, set by a tap on the card's lower band (tap area at least 88). There is no default; Play stays locked until every Boost that needs an aim has one. It covers both Boosts in the Final Battle, and no aim appears on Journeys.
  - **XP:** the purse keeps its number. Each level-up step flies as many stars as it costs from the number into the card, and the number counts down. Undo counts it back up. Unspent XP visibly goes away at the end of the Encounter. The post-Play recap stays.
- **In scope / out of scope**:
  - **In:** everything above, plus updating the tests, ui_check, space_audit, design_shots and README to replace the outcome-preview requirements of specs 001 (SC-002) and 010 (FR-004/010/018).
  - **Out:** the left column's final design (follow-up spec), the Enemy panel and Journey values, the post-Play recap, any rule change, a tutorial, a default Boost aim, and new art beyond small icons and stars.
- **Success metrics** (from problem.md):
  - No predicted player totals, outcome or loss warning appear before Play in any encounter type.
  - Highlighted parts match the engine's counted terms exactly, for every placed card in every encounter type.
  - Hardship and ability icons appear at the source and beside each affected badge.
  - Every Boost is aimable at a tap target of at least 88 on all sizes, with Play gated until it is aimed.
  - Stars fly per level-up step and undo restores the number.
  - The suite and ui_check pass with their requirements updated.
  - Every function the box hosts today is either moved or explicitly retired.
  - Qualitative: the follow-up spec can take over the space without first moving anything else out of it.
- **Carried-forward open questions**:
  - Should a Boost aimed at Initiative be marked differently from one aimed at Attack, beyond its aim icon?
  - How does the Boost-card tap area coexist with tap-to-swap and drag, on touch and mouse?
  - Is the tip text one line generally, or one per step (setup, place, aim, Upgrade)?
  - Are the number flights and tally/verdict reveal (animator.gd:88,91) dropped, or re-aimed at the cards?
  - How does unspent XP visibly go away at the end of the Encounter now that it is a number?
  - Does ui_check's preview-space rule need retuning to the tip's height?
