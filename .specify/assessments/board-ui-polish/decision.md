# Decision: Board, Zone and UI Personality Polish

- **Slug**: board-ui-polish
- **Decided**: 2026-10-15
- **Verdict**: go
- **Artifacts reviewed**: intake.md | research.md | problem.md | concept.md

## Scorecard

| Criterion | Rating | Justification |
|-----------|--------|---------------|
| Problem validity | strong | The owner is the sole player and decider and names three concrete problems: no identity, wasted space, a static board. The screenshots confirm them: generic dark panels, an empty lower preview panel, an oversized assignment area. |
| Evidence strength | adequate | Internal evidence is solid: specs, code, screenshots and the rulebook setting. There is no outside user signal and no web research. For a single-owner fan project the owner's judgment *is* the user signal, so this is adequate rather than strong. Screenshots predate the last five commits. |
| Value vs. inaction | adequate | Inaction breaks nothing; the game stays playable and legible. The value is in satisfaction and presentation only, but that is the project's stated priority (three presentation features in three days). |
| Feasibility / appetite | adequate | Option B fits a medium, one-branch appetite and builds on existing tokens, shaders, Ether colours and checks. Feasibility of a convincing code-drawn stone surface is unproven. Option A shows a smaller version is clearly doable. |
| Strategic fit | adequate | `.specify/memory/constitution.md` is an unfilled template, so there are no formal principles to check against. The work fits the project's evident direction (001, 005, and the card and art work on 003) and stays within the problem's non-goals. |
| Risk posture | adequate | The key risks are identified: taste, contrast on texture, GPU cost, Windows-PC art hand-off, layout-matrix churn. Two are mitigated: the play-screen style frame is an early exit, and the existing contrast and layout checks are guardrails. Performance has no formal gate because the owner chose that; it is mitigated only by "no visible stutter". |

## Verdict & Rationale

**Go.** The problem is real and clearly felt by the only person whose judgment matters
here (problem validity: strong). The evidence is internal but enough for a solo fan
project (adequate). Option B is a credible, medium-sized concept that meets all four
goals and reuses the existing dark palette, Ether system and checks. It isn't free:
the value is presentational only, and stone-surface feasibility and performance are
unproven. But the sequencing limits the downside. The space fixes deliver value
whatever happens, and the play-screen style frame is a deliberate stop point before
the look spreads to every screen. Nothing scored weak or unknown.

## If needs-clarification

- Not applicable.

## If go — Handoff to `/speckit-specify`

- **Problem**: Dragons of Etchinstone plays correctly but feels like a generic dark app. It's
  static between moments and spends screen space restating information. It needs an
  identity of its own, life, and space that earns its place, across every screen.
- **Chosen approach**: Option B, "Etched Stone and Ether Rifts". The world is carved dark
  stone, and zones read as engraved places cut into it. Ether rift light, tinted by the
  current Encounter's Ether, glows through seams to give each Region and fight its mood.
  Ambient life comes from shimmering seams, drifting motes, and zones that light when
  relevant. Each screen takes a lore framing: title as the Tower or The Tear, setup as
  the elders' proclamation, ending, rulebook and overlays as stone slabs and scrolls.
  It runs in three stages:
  1. Space: shrink the "which card for which role" area above the Hand to what it
     needs, and remove empty and dead zones.
  2. Play-screen style frame: the owner approves it against the current screenshot
     before rollout. This is the exit point.
  3. Rollout to the Final Battle, title, setup, rules, ending and overlays.
- **In scope / out of scope**:
  - In: every screen's layout, look and ambient and feedback motion.
  - Out:
    - Rules, card data, balance and new content.
    - Portrait orientation and new platforms.
    - Music and sound.
    - A light or parchment palette.
    - The publisher's art or trade dress.
    - Redrawing the creature and dragon silhouettes.
    - Formal device benchmarking as a gate.
- **Success metrics**:
  - Owner prefers the "after" on a side-by-side before/after of every screen.
  - Less screen share spent restating information during card selection; the
    assignment area is smaller.
  - No zone shows a large unused area in the standard screenshot states.
  - The owner can name what moves or responds while idle and after each action.
  - `tools/ui_check.gd`, the layout-matrix and contrast checks still pass.
  - No visible stutter on the web build or the Android emulator.
- **Carried-forward open questions**:
  - Can the seven-zone play-screen arrangement change, or only be restyled?
    The stage 1 space work may need a small change.
  - Code-drawn stone, or textures generated on the Windows PC?
  - Fresh before screenshots of the current build (`cc19722`) as the baseline.
  - The current share of the layout taken by the assignment area, as a baseline.
  - An inventory of current idle and feedback motion, as a baseline.
  - Whether one branch is enough, or it should split into "play screen" and
    "everything else" if rollout runs long.
  - Whether anyone besides the owner will play, and whether that raises the bar.
