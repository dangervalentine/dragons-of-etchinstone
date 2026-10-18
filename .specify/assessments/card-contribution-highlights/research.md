# Idea Research: Card contribution highlights replace the outcome math box

- **Slug**: card-contribution-highlights
- **Created**: 2026-10-17
- **Evidence confidence (overall)**: medium — the codebase and prior specs give high-confidence facts about what exists and what would break; there is no player or playtest data on whether the math box helps or hurts.

> **Owner clarifications (2026-10-17):**
> - Only the player's predicted values and outcome under the Encounter go. The Enemy panel (left of its image) and the Journey's values stay.
> - Earlier specs that built the preview were ordinary iteration, not a commitment that constrains this one.
> - The soak meter and XP purse stay. The XP purse becomes a row of stars that fly to the card being levelled and fade out when left unspent.
>
> - Motive (owner correction): the change frees the math box's space for a follow-up pass without breaking current functionality. It is not meant to hide the answer from players. Findings below that cite spec 009's "don't show the outcome" concern are background, not the driver.
>
> The findings below are revised to match.

## Users & Demand

- The only demand signal is the project owner's stated direction ("they can figure out if they have it or not"). There are no tickets, playtest notes or usage data in the repo — [source: intake.md] (confidence: high that this is the only signal)
- Earlier specs made "seeing the outcome" an explicit player goal: the old UI was faulted because it "reads the predicted outcome as three lines of prose" and the fix was "what would happen if they committed right now… with an unmistakable verdict" — [source: specs/001-ui-polish/spec.md:16,41-43] (confidence: high)
- Spec 001's success criterion SC-002 is that a player "can state the predicted outcome… within 3 seconds". This idea deliberately drops that goal — [source: specs/001-ui-polish/spec.md:443] (confidence: high)
- Spec 009 already pushed against giving the answer away: "a random arrangement would show the outcome before the player has decided anything". This is a stated owner concern consistent with the new idea — [source: specs/009-ordered-hand-layout/spec.md:22] (confidence: high)
- The predicted-loss warning (red panel edge and `warning` look on Play) also gives the outcome away and would have to go to honour "no intended outcome" — [source: ui/widgets/preview_panel.gd:66-67; ui/model/view_state.gd:674-675] (confidence: high)

## Prior Art

- **Math box (spec 006, refined in 010)** — `ui/widgets/preview_panel.gd` shows these rows:
  - Enemy: Attack (Spell + Boost + Night Travel − Armor vs HP) and Initiative (Element + Boost vs Enemy).
  - Journey: Move (Spell + Boost + Night Travel + Reserve vs MP, Steep sub-sum).
  - Final Journey: Tier.
  - Final Enemy: both sets.
  - Below the rows: a verdict line with XP/Damage/Time/Poison/Reserve/Knocked-Out pills.

  Its stated purpose: "so the player sees the game's arithmetic happen… including whatever a Hardship or ability changes" — [source: specs/006-etched-stone-polish/spec.md:31-33; contracts/math-box.md; preview_panel.gd:304-437; view_state.gd:130-176,357-384]
- **Per-card emphasis already exists** — `ui/model/emphasis.gd` gives each placed card `focus.regions`:
  - Spell: `enhanced` or `basic`.
  - Element: `ether` and `initiative`.
  - Boost: `boost`.
  - Reserve: `boost` only when it counts.

  `card_face.gd` draws these as a raised part with a `T.FOCUS` rim. This is close to the "contributing" highlight the idea asks for. Two gaps: it ignores the Boost's aim, and it does not model Night Travel — [source: emphasis.gd:44-57,89-107; card_face.gd:560-598] (confidence: high)
- **A hook for text colour exists but is unused** — `card_face.gd` has `_ink_for` (per-part text colour, 552-555), currently a no-op (`_hush` returns 0, 110-111). It fits an "impacted" text-colour style — [source: card_face.gd] (confidence: high)
- **Existing "impacted" signals:**
  - The Reserve place label shows the Steep/Freeze rule icon in BAD and a strike-through once the Reserve is given up.
  - The Reserve card has a dashed outline, gold plus a "+N" ribbon when it boosts.
  - `_ring` outlines changed figures in gold or BAD. This is likely the "border around the badge" the idea wants to replace.

  [source: place_labels.gd:106-113; view_state.gd:450-455; card_view.gd:284-300; card_face.gd:600-611] (confidence: medium on the "border" match)
- **Boost aiming moved into the math box in spec 010** (`aim_boost` → `turn_draft.boost_target_set`). Its research weighed and rejected an on-card toggle: "A toggle on the Boost label: the label would grow to 88, costing card height" — [source: specs/010-legible-hand-cards/research.md:60; preview_panel.gd:304-348; main.gd:658-666] (confidence: high)
- **External precedent** — card games split between showing the computed result before commit (e.g. Balatro's hand score, Slay the Spire's damage numbers on intents) and leaving the sum to the player (most physical card games). This project's rulebook is physical-first — [ASSUMPTION] (confidence: low)

## Market & Context

- **Cost of doing nothing:** the math box stays. It meets the earlier legibility goals, but per the owner it hands players the answer, and its Boost aim couples it to the Hand — [source: intake.md; spec 010 FR-010] (confidence: medium)
- **What the left column holds besides the math box:** the preview region also holds `soak_meter` and `xp_purse` [source: ui/screens/play_screen.gd:31,64-65]. The owner ruled that both stay (confidence: high)
- **XP purse today:** a gold stone panel. At Upgrade it shows the recap (verdict icon and text, damage, time, Knocked Out) and the XP amount there is to spend — [source: ui/widgets/xp_purse.gd]. The star redesign replaces the amount display.
- **The stars follow the rules:** "Excess XP is lost at the end of [the] Encounter", which is what fading unspent stars shows — [source: reference/rulebook.txt:790] (confidence: high)
- **Stars can reuse the existing flight effects.** There is already a flight layer (`ui/fx/flight_layer.gd`) and number flights (spec 010 R7) that can carry stars to the levelled card — [source: ui/fx/flight_layer.gd; ui/fx/animator.gd] (confidence: medium)

## Data & Constraints

- **Rules that decide "contributing":**
  - **Spell enhanced action:** applies when the Element's Ether (or a Fuse substitute) equals the Spell's enhanced Ether **and** the enhanced type fits the encounter. Otherwise the basic action applies if it fits. Otherwise the value is 1. So "the ether position filled with the right card" means "an Element whose Ether matches" — [source: engine/rules.gd:17-25; game.gd:540-543; reference rulebook.txt:589-592] (confidence: high)
  - **Element:** gives Ether and, against an Enemy, Initiative.
  - **Boost:** goes to Attack or Initiative against an Enemy, and to Move on a Journey.
  - **Reserve:** its Boost adds to Move on a Journey when its enhanced Ether matches the MP's Ether.
  - **Key Card:** contributes no value.

  [source: rules.gd:44-45,97-100; game.gd:111-114,421-424] (confidence: high)
- **Hardships that "take a value from cards":**
  - Night Travel: Boost minus the Element's Initiative, minimum 0. It touches two cards.
  - Steep: MP rises by the Reserve's Boost.
  - Ambush, Hazards, Storm and Treacherous change only damage or time. They have no card part to mark.

  [source: rules.gd:55,60-61,101,104-107,169-172] (confidence: high)
- **Ranged and Freeze:** a Ranged enemy strikes early unless the Reserve is given up, which discards it. Freeze discards the Reserve if the enemy strikes early. Both put the Reserve card in an "impacted" state — [source: rules.gd:47-52,87] (confidence: high)
- **No per-card contribution API:** the engine returns totals plus `terms` (`{sum,label,source,value,card,note}`). `card` is filled only in `explain()`. Emphasis already derives regions per card, so highlights need no new rules math — [source: rules.gd:146-148; game.gd:168-174,210-224] (confidence: high)
- **Boost aim has no default:**
  - `boost_to` starts null.
  - Play is disabled with "Choose whether the Boost adds to Attack or to Initiative."
  - `to_action()` falls back to "attack".

  Whichever new control replaces the math box, it must keep this gate or define a default — [source: turn_draft.gd:15,167-177,295-298,383,391; view_state.gd:669] (confidence: high)
- **Room for a Boost button:**
  - **Action row:** 88 tall, ¼/¼/½ for three cells, ¼ each for four, ⅕ each for five. Against a Ranged Enemy, Fuse + Divert + Give up Reserve + Boost + Play makes five cells, about 180 wide each at phone-tall. Spec 010 left the five-cell rule in place "so a later action fits" — [source: layout_solver.gd:219-229; view_state.gd:723-733; specs/010-legible-hand-cards/research.md:82] (confidence: high)
  - **On-card button:** a card is 220×308 at phone-tall and 197×275 at baseline. The Boost plate is about 0.317w × 41 at y≈213, leaving about 136 of field to its right. The tap minimum is 88, so an on-card button would take about 29% of card height, the reason spec 010 rejected it — [source: card_face.gd:137-151; tokens.gd:16] (confidence: high)
- **Accessibility rule:** "Verdicts and costs never rely on colour alone". An "impacted" style made only of a text-colour change would break this unless paired with a non-colour cue — [source: specs/001-ui-polish/contracts/design-tokens.md:66] (confidence: high)
- **What depends on the math box and would break or need rewriting:**
  - test_view_state.gd: lines 156, 183, 223, 508, 536 and 550.
  - test_terms.gd: lines 78, 127 and 182.
  - test_layout_solver.gd:149.
  - test_emphasis.gd:127.
  - test_board_responses.gd: lines 13 and 42.
  - test_sequencer.gd:112.
  - The animator: `play_tally` / `reveal_verdict` (animator.gd:88,91) and number flights landing on preview totals.
  - tools/ui_check.gd: `_check_space` fails if the preview zone is more than ⅓ empty, so **an empty left column fails the UI check as written** (121-150). The aim checks are at 934-969.
  - tools/space_audit.gd:123-125.
  - tools/design_shots.gd:212,263.

  [source: as listed] (confidence: high)
- **Docs:** README.md:28-30 promises "a preview of the outcome (your totals against the targets, the verdict, and what it will earn and cost)" and would need updating — [source: README.md] (confidence: high)

## Evidence Against the Idea

- **Earlier specs set outcome-preview goals.** Specs 001, 006 and 010 built the preview, and 001's SC-002 measured it. The owner frames this as normal iteration, so the point is only that those specs' requirements (001 SC-002; 010 FR-004/010/018) and the README must be superseded explicitly — [source: specs/001 spec.md:41-43,443; specs/010 spec.md; README.md:28-30]
- **There is no warning before a losing Play.** Targets stay visible (the Enemy panel and the Journey values), so players can still compare. But the predicted costs (Damage, Time, Poison) and Knocked Out risk, and the red edge on a predicted loss, are the only pre-commit warning of a game-ending Play. That warning goes with the math box. This is intended per the owner ("they can figure out if they have it or not"); the impact on players is an ASSUMPTION — [source: preview_panel.gd:66-67,409-437; view_state.gd:674-675] (confidence: medium)
- **Highlights alone cannot show aim or Night Travel.** Emphasis lights the Boost whether it goes to Attack or Initiative, and does not reflect Night Travel's subtraction. Making highlights tell the truth needs new emphasis logic, not just restyling — [source: emphasis.gd:44-57,89-107]
- **The on-card Boost toggle was already rejected for space** (spec 010 R4), and the action-row option uses the five-cell layout no phase has used yet — [source: specs/010-legible-hand-cards/research.md:60,82]
- **A text-colour-only "impacted" style conflicts with the colour-blind rule** — [source: specs/001-ui-polish/contracts/design-tokens.md:66]
- **Space checks need retuning.** The math box becomes a short tip text, which is shorter than the rows it replaces. `ui_check`'s "more than ⅓ empty" rule (and space_audit) may need retuning to the tip's height. The owner's tip-text decision addresses this — [source: tools/ui_check.gd:121-150; tools/space_audit.gd:123-125]
- **Scope grows with the XP stars.** The XP purse redesign is a separate visual and animation feature (counting, layout of many stars, flight to the card, fade-out) bundled into a change that is otherwise about the Hand. That adds risk of scope creep — ASSUMPTION
- **Animations need a new landing spot.** Number flights and the tally/verdict reveal target the math box (spec 010 R7) — [source: animator.gd:88,91]

## Owner Answers (2026-10-17, second round)

1. **Loss warning:** the predicted-loss warning goes (red panel edge and the `warning` look on Play). The post-Play recap in the XP purse stays for now.
2. **XP stars:** one star per XP, at most 9 at once. They are drawn small enough to fit the purse.
3. **Star motion:**
   - On each level-up step, the spent stars fly to the card.
   - Undoing a level-up does not fly them back; they fade back in at the purse.
   - Unspent stars fade out at the end of the Encounter.
4. **Boost aim control:** the owner left the placement to Claude. The lean is recorded below and is to be confirmed in `/speckit-assess-shape`.
5. **Hardship mark:** the Hardship's icon appears to the right of each affected badge, on every card it touches. Night Travel shows on the Boost badge and on the Element's Initiative badge. This is an icon, not only a text-colour change, so it meets the "never colour alone" rule (design-tokens.md:66). The card face has about 136 of free width to the right of the Boost plate (card_face.gd:137-151).
6. **Final Battle:** the owner expects the two Boosts there to push the aim control onto the card itself.

### Lean on the Boost aim control (owner-delegated; shaped later)

- **Lean: on the card, at the Boost badge.**
- **Reasoning:**
  - The Final Enemy battle has two Boosts, one per set (preview_panel.gd Final Enemy rows), and each needs its own aim.
  - One button in the bottom row cannot address two Boosts. Two buttons, plus Give up Reserve, Fuse, Divert and Play, exceed the five-cell row (layout_solver.gd:219-229).
  - An on-card control scales to any number of Boosts and sits where the highlight already draws the eye.
- **The old objection and a way around it:** spec 010 R4 rejected a Boost-label toggle because an 88-tall tap target costs card height (research.md:60; tokens.gd:16). The badge could keep its drawn size and take a tap area that extends across the card's lower band. That would need care so a tap still differs from the card swap/drag gesture (spec 010 FR on tap-to-swap). This is an ASSUMPTION to be tested.
- **Aim icon:** an Attack or Initiative icon beside the Boost badge would show the current aim, in the same slot style as the Hardship icon (answer 5).
- **Only Enemy encounters need it.** On a Journey and the Final Journey the Boost always goes to Move (rules.gd), so no control appears.

### Owner revision (2026-10-17, during shape)

- The XP purse keeps its number; it does not become a row of 9 stars.
- On each level-up, as many stars as the step costs animate out of the number on the left and into the card on the right.
- This replaces answers 2 and 3 above.

## Gaps & Open Questions

- [NEEDS CLARIFICATION: Is there playtest evidence that the math box makes play too easy or cluttered, or is this a design-intent call?]
- ~~Loss warning / recap?~~ Resolved: the warning goes; the recap stays for now.
- ~~XP star rules?~~ Resolved: one star per XP, at most 9, flown per level-up, fading back in on undo.
- ~~Two icons beside one badge?~~ Resolved (owner): they are small, both fit.
- ~~Where do Ranged/Freeze and Hardship icons show?~~ Resolved (owner):
  - Enemy abilities (Ranged, Freeze) keep their icons next to the Enemy and also show beside the affected badge on the Hand card (the Reserve).
  - Journey Hardships likewise show on the Journey and beside the affected badges on the cards.
- ~~Where do targets stay visible?~~ Resolved: the Enemy panel beside its image, and the Journey's values.
- ~~Do soak_meter/xp_purse stay?~~ Resolved: yes; the XP purse becomes stars.
- [NEEDS CLARIFICATION: Should a Boost aimed at Initiative light differently from one aimed at Attack, and should Night Travel mark both the Boost and the Element as impacted?]
- ~~Boost aim default?~~ Resolved (owner): no default. The Boost must be aimed by hand, and Play stays gated until it is (as today: turn_draft.gd:15; view_state.gd:669).
- ~~ui_check empty-space rule?~~ Resolved (owner): the box keeps its place in the left column. Where the math box was, it holds generic tip text on how to proceed (e.g. place your cards, aim the Boost, press Play) until the follow-up spec redesigns the column. This keeps the zone filled and the space check satisfiable.
- ~~Final Battle aims?~~ Leaning: an on-card control per Boost (see Owner Answers 6 and the lean above).

## Sources

- Repository files cited inline (read-only, local): engine/rules.gd, engine/game.gd, ui/widgets/preview_panel.gd, ui/model/view_state.gd, ui/model/emphasis.gd, ui/model/turn_draft.gd, ui/widgets/card_face.gd, ui/widgets/card_view.gd, ui/widgets/place_labels.gd, ui/screens/play_screen.gd, ui/layout_solver.gd, ui/main.gd, ui/fx/animator.gd, tools/ui_check.gd, tools/space_audit.gd, tools/design_shots.gd, tests/*.gd, README.md, reference rulebook
- Prior specs: specs/001-ui-polish, specs/005-*, specs/006-etched-stone-polish, specs/009-ordered-hand-layout, specs/010-legible-hand-cards
- No web URLs fetched.
