# Concept: The cards tell the story; the math box steps aside

- **Slug**: card-contribution-highlights
- **Created**: 2026-10-17
- **Recommended option**: B — Cards carry it all, aim on the Boost card, XP as stars

## Options

### Option A — Strip and point (smallest thing that could work)

- **Sketch**:
  - **Math box:** it loses its rows, verdict, cost pills and the red loss edge, and shows a single generic tip. Play loses its `warning` look.
  - **Highlights:** the cards keep today's emphasis as it is (raised parts with a focus rim).
  - **Hardship and ability icons:** they are added to the right of each affected badge, and stay on the Enemy and the Journey too.
  - **Boost aim:** it moves to a "Boost: Attack / Initiative" button in the action row. In the Final Battle the button aims whichever Boost card was last tapped.
  - **XP purse:** it keeps its number. Stars are left for later.
- **Appetite**: small (a few days).
- **Trade-offs**:
  - **Wins:** fastest route to G1 and G4, and it frees the math box for the follow-up spec.
  - **Highlights can mislead:** they would sometimes be wrong. Today's emphasis lights the Boost whatever its aim and ignores Night Travel [research: emphasis.gd], so G2's "only what the engine counts" fails.
  - **Final Battle aim is awkward:** aiming "the last tapped Boost" is a hidden mode, and tapping is already used for swapping.
  - **Action row gets crowded:** against a Ranged Enemy it fills to five cells.
  - **G5 not met:** the stars the owner asked for are dropped.
- **Rabbit holes**: a modal "which Boost am I aiming" rule in the Final Battle; tap-to-select clashing with tap-to-swap.

### Option B — Cards carry it all, aim on the Boost card, XP as stars

- **Sketch**:
  - **Math box:** emptied of every prediction and filled with a short tip for the current step (place cards, aim the Boost, press Play, spend XP).
  - **Highlights:** each placed card lifts exactly the parts the engine will count. This follows the Boost's aim, Night Travel, enhanced vs basic action, and the Reserve's Boost only when it counts.
  - **Hardship and ability icons:** they sit to the right of each affected badge (Night Travel on the Boost and the Element's Initiative, Steep on the Reserve's Boost, Ranged and Freeze on the Reserve), and also stay at their source on the Enemy panel or the Journey.
  - **Boost aim:** each Boost card carries a small Attack or Initiative aim icon beside its badge. It is set by a tap on the card's lower band (drawn small, with a tap area of at least 88), so it works the same for one Boost or two in the Final Battle. With no aim set, the icon shows a "choose" state and Play stays locked. On Journeys no aim icon appears.
  - **XP purse:** it keeps showing the XP as a number (owner revision, 2026-10-17).
    - On each level-up step, as many stars as that step costs come out of the number on the left and fly into the card on the right, and the number counts down.
    - Undo counts the number back up; no stars fly back.
    - XP still unspent at the end of the Encounter visibly goes away (exact treatment to be settled in spec).
    - The post-Play recap stays.
  - **Animations:** number flights and the tally that landed on the math box are dropped or re-aimed at the cards (to be settled in spec).
- **Appetite**: medium (one to two weeks). That is in line with recent specs 009 and 010, which each reworked the Hand and math box.
- **Trade-offs**:
  - **Wins:** meets G1–G6, scales to the Final Battle, keeps the action row at its current size, and makes highlights truthful by checking them against the engine's own terms.
  - **Sacrifices:** more work than A. The Boost card's lower band carries two jobs (aim and swap/drag), and the XP purse becomes an animated piece rather than a label.
  - **Risk:** small icons beside badges must stay legible on the 197×275 baseline card.
- **Rabbit holes**:
  - **Tap and drag on one card:** telling the aim tap apart from tap-to-swap and drag on the same card, on touch and mouse alike.
  - **Highlights matching the engine:** making them match in every encounter type (Final Journey Reserve, Final Enemy with two sets and Armor) instead of approximating.
  - **Star flights:** chained level-ups and undo mid-flight, alongside the existing upgrade animations and haptics. The star-count number removes the risk of laying out up to 9 stars.
  - **Tip wording:** this could creep into a tutorial system.
  - **Many tests to rewrite:** about a dozen tests plus ui_check, space_audit and design_shots encode the math box and need rewriting, not deleting.

### Option C — Two passes: Hand now, stars next

- **Sketch**: Option B's Hand work (prediction removed, tip, engine-true highlights, icons on both sides, on-card Boost aim) ships first. The XP stars ship as their own small spec straight after.
- **Appetite**: medium for the first pass, small for the second.
- **Trade-offs**:
  - **Wins:** each pass is smaller to review and test, and the stars' animation work cannot hold up the Hand change.
  - **Sacrifices:** the owner asked for the stars "in this change". Splitting adds a spec cycle, and the left column changes twice before the follow-up redesign.
- **Rabbit holes**: the same as B, spread across two passes.

### Do nothing

Considered and set aside. Nothing breaks, but the math box keeps holding the Boost aim and the per-card information. The follow-up left-column pass would then have to move them while redesigning the column [problem.md: Cost of Inaction].

## Recommendation

**Option B.** The aim is to free the math box's space for the follow-up pass without breaking anything it does today (problem.md, reframed). B moves every load-bearing job out of the box:
- **Truthful highlights:** it is the only option that makes the highlights match the engine (G2's measurable check). A's highlights would mislead once the numbers are gone, which would be a regression.
- **Final Battle aim:** it handles both Boosts without a hidden mode or a sixth action cell (G3), which the owner pointed to as the deciding case.
- **Stars included:** it delivers the stars the owner put in scope (G5).

The appetite is medium. With the XP shown as a number and only the spent stars flying, the star work is small. Option C's split is unlikely to be needed, but it stays as the fallback rather than cutting the Hand work.

## Out of Scope (for the recommended option)

- The left column's final design (the follow-up spec). This change leaves only the tip, the soak meter and the XP purse there.
- Changes to the Enemy stats panel, the Journey's values, or the post-Play recap.
- Any rule change (actions, Boost, Hardships, Ranged/Freeze, Armor, XP).
- A tutorial or onboarding flow beyond a one-line tip per step.
- A default Boost aim. It stays manual and gates Play.
- New art beyond small icons and stars drawn in the existing style.

## Assumptions to Validate

- **Tap and drag:** a tap area on the Boost card's lower band can be told apart from tap-to-swap and drag, on touch and mouse, without making swaps feel worse.
- **Icon fit:** a Hardship icon and an aim icon fit together to the right of a badge on the 197×275 baseline card and stay readable (owner: "they are small").
- **Engine terms:** the engine's existing `terms` give enough to decide per card which parts count. The highlights then need no new rules arithmetic [research: rules.gd:146-148; emphasis.gd].
- **Star flights land:** stars flying from the XP number to a card can reuse the existing flight layer (`ui/fx/flight_layer.gd`) and stay readable when several level-ups follow quickly.
- **Losing the flights:** dropping or re-aiming the number flights and tally (animator.gd:88,91) does not leave the moment of Play feeling empty. [Owner judgement]
- **Tip text:** a short tip keeps the left column within the UI check's space rule, or that rule is retuned to it.
- **Players cope:** players can work out whether a Hand is good enough from the highlighted cards and the Enemy or Journey values alone. This is untested and rests on owner judgement.
