# Research: Card Contribution Highlights

Decisions behind [plan.md](plan.md). Each has the decision, why it was chosen, and what else was weighed. Code references are to the state at commit `c47ffa9`.

## R1 — Lifted parts come from the engine's own terms

**Decision**: `Emphasis` works out a building card's lifted regions from the terms of `game.explain(action)`, the same terms the math box adds up today. It no longer applies its own role table. Each term maps to a region:

- **Spell term**: lifts `enhanced` when its note starts with "enhanced", `basic` when the basic action counts, and nothing when the note says "counts as 1".
- **Element term in the Initiative sum**: lifts `initiative`.
- **Boost term**: lifts `boost` on the card in that set's Boost position.
- **Reserve term in the Move sum**: lifts the Reserve's `boost`.

The Element's `ether` is always lifted, because the Ether decides the Spell's action. A Spell with no Element yet keeps today's behaviour of lifting both actions, since the outcome is undecided. `explain` sets `card` only on the Spell, Element and Boost terms (`game._note_cards`), so the Reserve is matched through the draft's `reserve_card`.

**Rationale**: FR-008 requires the lift to follow "the same count the game uses". `explain` is that count, and `view_state.math` already reads it. Today's `Emphasis._building` uses a role table that:
- lifts the Boost whatever its aim;
- lifts the Element's Initiative on a Journey, where it does not count;
- lifts a Spell's action even when it counts as 1.

**Alternatives considered**:
- *Patch the role table* with aim and Night Travel cases. Rejected: it would be a second copy of the rules that drifts from the engine, which is the gap SC-003 tests for.
- *A new per-card engine API*. Rejected: the terms already carry what is needed, and FR-024 keeps the engine unchanged.

## R2 — Impact marks: a small rule table keyed by the Encounter's effects

**Decision**: `Emphasis` adds `impacts` to a card's focus: a list of `{region, icon}`. They are worked out from the Encounter's `effects` (Hardship, Enemy ability, peril), which `view_state` already lists, and from the draft:

| Effect | Position | Region marked |
|---|---|---|
| `night_travel` | each set's Boost | `boost` |
| `night_travel` | each set's Element | `initiative` |
| `steep` | Reserve | `boost` |
| `ranged` | Reserve, while not given up | `boost` |
| `freeze` | Reserve | `boost` |
| Armor | Spell, when an `Armor` term is in the Attack sum | `enhanced` |

Ranged and Freeze bear on the Reserve card as a whole. The mark sits beside its Boost badge because that is the Reserve's one figure, and it puts every Reserve mark in the same place.

**Rationale**: these are exactly the effects the engine applies to a card value (`rules.gd`: `_boost` for Night Travel, `resolve_journey` for Steep, `dodge_ranged` and `discard_reserve` for Ranged and Freeze, `_armor`). Armor is the only one whose presence depends on the arrangement, so it is read from the terms (an `Armor` term exists only when the enhanced attack meets Armor). The others depend only on the Encounter and the positions.

**Alternatives considered**:
- *Read every impact from the terms*. Rejected: Ranged and Freeze produce no term until the outcome happens, and Night Travel's term is dropped when its value is 0, but the mark should still show.
- *A text-colour change*. Rejected by the owner in favour of the icon. It would also break 001's "never colour alone" rule.

The Reserve place label keeps its Steep and Freeze rule icon (`place_labels.gd`). It is the label's statement of the Encounter rule and is harmless beside the card mark.

## R3 — Where the marks are drawn on the card

**Decision**: `CardFace` draws the impact icons and the aim mark in a strip just to the right of the marked region's plate, inside the Ether field:
- each mark is a square `row × 0.72` high, vertically centred on the plate;
- they are set left to right, aim mark first, then impact icons;
- each sits on a small dark disc so it reads over the painted field.

The space checks out:
- **Boost plate:** 0.317w wide, leaving about 0.6w (≈ 130 at 220 wide, ≈ 118 at 197) of field to its right. Two marks of ≈ 30 each fit with room to spare.
- **Initiative pennant:** a `row`-wide square, with the field to its right.
- **Enhanced plate:** 0.44w wide, leaving about 0.5w.

**Rationale**: the owner asked for the icon "to the right of the badges", and confirmed that two fit. The discs keep the marks legible on any Ether's art without changing the field (006: the field keeps one brightness).

**Alternatives considered**:
- *Marks on the place label*. Rejected: the owner wants them on the card, and labels are 36 tall with no room for per-badge marks.
- *The `_ink_for` text-colour hook*. Kept unused, for the reason in R2.

## R4 — Boost aim: a tap zone on the Boost card's lower band

**Decision**:
- **Zone:** against an Enemy, a card in a Boost position has an aim zone. It is a rectangle the full width of the card and `T.TAP_MIN` (88) tall, anchored to the card's bottom edge, so it covers the Boost and Armor rows (`CardView.aim_rect()`).
- **Tap:** a tap whose press and release both fall in the zone, with no drag (movement under `DRAG_START`, 12) and no hold (`HOLD_SECONDS`, 0.35), emits a new `aim_tapped(id)` signal instead of `tapped(id)`.
- **Drag and hold:** a drag or hold starting in the zone behaves as today.
- **Order:** the aim cycles unset → Attack → Initiative → Attack. Attack comes first, as the keyboard's `B` already does (`main.gd`).
- **Mark:** the aim mark shows the current aim's icon (`attack` or `initiative`), or a `?` mark in gold while unset.

**Rationale**:
- **Tap target size:** 88 meets `T.TAP_MIN` on every shape. At phone-tall (308 tall) the zone is the lower 29% of the card; at the desktop baseline (275) it is 32%.
- **Swaps still work:** the rest of the card still picks it up. Every drag still swaps, because drag detection comes before the tap test in `_gui_input`. So an aim tap never starts a swap, and a swap never changes an aim (SC-005).
- **Final Battle:** each Boost card has its own zone, which settles the two-Boost case without the `boost_target_set` guess that 010 needed (010 FR-018c).

**Alternatives considered**:
- *A Boost button in the action row*. Rejected: there is no sixth cell, and it cannot address two Boosts (assessment concept, Option A).
- *Two side-by-side targets (Attack | Initiative)*. Rejected: two 88-wide targets do not fit the ≈ 130 of field beside the plate.
- *A tap target the size of the Boost badge itself*. Rejected: at 41 tall it is under the minimum (010 R4).

**Spec effect**: User Story 3's scenario 2 now reads "taps once → Attack; taps again → Initiative". SC-004 is unchanged: aiming takes one tap and switching one more.

## R5 — The box: a step tip before Play, the sum after Play

**Decision**:
- **Before Play:** while the phase is `challenge`, `final_journey` or `final_enemy` and nothing has been played, `PreviewPanel` renders only the step tip (`prompt.step` eyebrow and `prompt.text`, plus the swap/aim hint). There are no rows, verdict, pills or red edge.
- **At Play:** the animator's `tally` step calls a new `PreviewPanel.reveal(math)`. It builds the equation rows and the verdict from the **pre-Play** view state's `math` and `preview`, which the screen still holds while the sequence plays. Then it counts the totals up (`play_tally`), and the `verdict` step reveals the verdict as today.
- **After Play:** when the sequence finishes, the screen renders the after-state (the Upgrade phase), and the XP purse shows the recap as today.
- **Play button:** `view_state` stops setting `primary.kind = "warning"` from `pv.fatal`. `_aim` and `PreviewPanel._aim_row` are removed.

**Rationale**: the owner's answer (spec Clarifications): "a summary is shown on screen with the numbers added up. they don't need to come from the cards". The existing rows, `play_tally` and `reveal_verdict` already are that summary. Showing them only from the `tally` step on keeps the box free of predictions (FR-001) and reuses tested code. The animator already holds the pre-Play state (`screen.vs`) until `_finish`.

**Alternatives considered**:
- *Summarise in a floating banner over the board*. Rejected: it covers the cards, and the box's space is free at that moment anyway.
- *Keep the rows but hide the totals*. Rejected: partial sums still predict.

## R6 — The box keeps its height; the space check is retuned

**Decision**: `PreviewPanel.needed_height` keeps sizing for its fullest look (the summary). The left column then does not re-layout at Play, and the follow-up pass inherits the same region. `tools/ui_check.gd`'s `_check_space` and `tools/space_audit.gd` measure the preview zone in the post-Play summary state (driven through the animator's `reveal`), not the tip state. The tip state is checked for overlap and text size only.

**Rationale**: re-laying out the column at Play would move the Encounter face mid-animation. The check's purpose, no wasted space in the column, is met by the state that fills it. The empty tip state is the interim the owner accepted (spec Assumptions).

**Alternatives considered**:
- *Shrink the box to the tip*. Rejected: the column re-lays out at Play, and the follow-up pass would have to claim the space back.
- *Waive the check*. Rejected: the summary state still needs it.

## R7 — XP stars ride the existing flight layer

**Decision**:
- **Level-up:** `Sequencer._level_steps` adds `spent` (XP before minus XP after) to each `upgrade` step's values. The animator's `upgrade` step flies `spent` stars (`flight.ghost("xp", …)`, staggered by `d * 0.08` as `gain_xp` already does) from `xp_purse.point()` to the card's centre. Meanwhile the purse's number counts down from the old value to the new one (a `count_to(n, d)` on `XpPurse`, reusing the `_count` pattern from the math box).
- **Undo:** it produces a `downgrade` step (`main.gd` `"undo"`), which gets no stars. The purse renders the restored number when the sequence finishes.
- **End of the Upgrade step:** the `finish` sequence gains an `xp_lost` step when XP was left unspent. It fades the purse's number out with a short `float_text` "−N XP" in `T.INK_MUTED`. Under reduced motion, `ghost` already snaps and fades, and `xp_lost` is a plain fade.

**Rationale**: the flight layer, the step timing and the reduced-motion handling all exist. `gain_xp` already flies XP motes into the purse, so this is the same motion in reverse.

**Alternatives considered**:
- *Up to 9 stars resting in the purse*. Dropped by the owner during assessment.
- *Stars fly back on undo*. Rejected by the owner: the number simply restores.

## R8 — Tests and tools to change

**Decision**: update, don't delete, the checks that encode the box.

| File | Change |
|---|---|
| `tests/test_view_state.gd` | The preview and math tests (`incomplete_preview…`, `preview_figures…`, `final_battle_preview…`, `math_box_sums…`) keep checking `vs.preview` and `vs.math`, which still feed the summary. The two aim tests become card-aim tests. A new test checks that Play has no `warning` kind. |
| `tests/test_emphasis.gd` | New table tests per R1 and R2 against `game.explain` across every encounter type, Hardship and ability (SC-003, SC-006). `test_reserve_boost_only_when_it_counts` is kept. |
| `tests/test_turn_draft.gd` | Aim tests move to `cycle_boost_to(set)`. `boost_target_set` stays for the keyboard. |
| `tests/test_sequencer.gd` | `upgrade` steps carry `spent`; `finish` adds `xp_lost`. |
| `tests/test_layout_solver.gd` | `test_preview_takes_what_it_needs` is unchanged (R6). |
| `tests/test_terms.gd`, `tests/test_board_responses.gd` | Unchanged: the terms and the tally/verdict steps remain. |
| `tools/ui_check.gd` | The aim-row checks become aim-zone checks (zone ≥ 88 on every shape, inside the card, under the Boost plate). It checks that no mark overlaps a value. `_check_space` follows R6. |
| `tools/space_audit.gd`, `tools/design_shots.gd` | Measure and shoot the summary state. Shots for the card marks per effect. |

**Rationale**: SC-008 requires the suite to pass with its requirements updated rather than skipped.

## R9 — Earlier documents this feature supersedes

**Decision**: add a dated "Superseded in part by 011" note in each, rather than rewriting history:
- 001's outcome-preview story and its SC-002;
- 006's `contracts/math-box.md` (before-Play display);
- 010's FR-004, FR-010 and FR-018–FR-018c, and its assumption that values are read in the preview panel.

Update README lines 28–30 to describe the cards' lifted parts and marks, and the after-Play summary.

**Rationale**: FR-025.
