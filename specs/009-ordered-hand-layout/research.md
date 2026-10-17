# Research: Ordered Hand and Play-Board Layout

All figures are in design units at the 1280 × 720 baseline (content 1248 × 688, body 628 tall under the 48 header and 12 gap). `T.TAP_MIN` = 88, `T.S` = 8, `layout_solver.GAP` = 12, `T.CARD_ASPECT` = 190 / 266.

## R1 — The engine stays as it is

**Decision**: No change to `engine/`. The Hand order is a display and interaction concern held in `ui/model/turn_draft.gd`. `to_action()` keeps sending the same `{spell, element, boost, boost_to, ranged_discard, fuse}` (or `{sets: [...]}`) the engine takes now.

**Rationale**: `Game._reserve()` already derives the Reserve as the one Hand card left without a Role, and the base game scores nothing on order (spec FR-026). Recorded playthroughs and rules tests then hold unchanged (SC-006).

**Alternatives considered**: Store the order in the engine for future expansions. Rejected: nothing in the base rules reads it, and it would change the save and replay surface for no gain now.

## R2 — Draft model: pick up, then put down

**Decision**: Replace "tap fills the active slot" with a two-step model on `TurnDraft`:

- `held`: the card picked up, or null.
- `pick(id)`: picks a card up. Picking the held card again puts it down.
- `put(target)`: target is a role place `[set, role]`, `"reserve"` or `"floating"`. Putting a card on a filled place swaps the two cards: the card already there goes to where the held card came from (a place, or the floating row). `"floating"` sends a placed card back.
- `reserve`: the card the player put in the Reserve place, or null. When every role place is filled and exactly one card is still floating, that card is shown in the Reserve place (derived, not stored; spec US1-4, FR-003).
- `sets` (role → card id) is unchanged, so `slot_of`, `empty_slots`, `is_filled`, `to_action` and every preview path keep working.
- `active` stays, now meaning only the hinted next place (spec FR-017): the first empty place in Spell, Element, Boost order, as today.

**Rationale**: The clarification rejects auto-placing, because a random arrangement would reveal the outcome. Keeping `sets` as the single source of Roles means the preview, emphasis, math box and board responses need no new inputs.

**Alternatives considered**: Store a full ordered list of Hand positions. Rejected: it duplicates `sets` and needs keeping in sync with it.

**Validity of a put**: The engine stays the judge. A put that the engine would refuse at Play is still allowed while building (for example, no Spell yet), and the preview reports it as today. Only two puts are refused: putting a fused partner (the tucked card) anywhere, and putting a card in the Reserve when fewer than four cards are in the Hand. With three cards the rules fill all three Roles; with fewer, the Reserve stays empty and inactive (spec edge case).

## R3 — Places and the floating row in the view state

**Decision**: `view_state.build` gains:

- `places`: an array in display order, one per place. Each has `{key, set, role, card_id, state, number, counts_to, ether, boost_to, tap, toggle_tap, tooltip}`, where `role` ∈ reserve, element, spell, boost. Order:
  - Region: reserve, element, spell, boost.
  - Final Journey: reserve, then Set 1's element, spell, boost, then Set 2's.
  - Final Enemy: Set 1's and Set 2's three Roles only (spec FR-025).
- `floating`: the unplaced card ids, in dealt order.
- `held`: the held card id, or null.
- Each card model gains `place`, its place key or null.

States are `empty`, `next`, `target` (a valid put while a card is held), `filled`, and the recap's `played`, `kept`, `discarded`, plus `given_up` on the Reserve. `role_slots()` becomes `places()`. Its numbers, tooltips and recap logic carry over, with the Reserve now a place in every state, not only the recap.

**Rationale**: One list drives the role strip, the place rectangles and the keyboard order, so all three line up by index.

## R4 — Right-side layout and the Region card size

**Decision**: From the top down, the card side holds:

| Band | Height |
|---|---|
| role strip | `STRIP_H` = 88 (one tap target) |
| places row | card height when any place is filled; `PLACE_EMPTY_H` = 56 outline when all are empty |
| floating row(s) | card height per row |
| action row | `ACTION_ROW_H` = 88 |

The bands are separated by `GAP`. Every band spans the card side's full width.

The strip is 88 tall. Today's slot band is 184–249 at the baseline, so the strip is at most half of it (FR-018).

The card size is chosen once per Hand, as the largest that fits the worst stage of placing. Cards do not resize mid-build.

- Region, four cards: both rows full at once (for example, 2 placed and 2 floating) gives (628 − 88 − 88 − 3 × 12) / 2 = 208 tall, so **≈ 148 × 207**. Width allows 197.
- Today's Region Hand card is 197 × 275, so this is about 75% of its linear size. Spec SC-004 accepts this (clarified: "fully visible, legible").

**Legibility check**: Card numerals scale with width (`card_face.numeral_size`, 30.1 at 197), giving about 22.6 at 148. That is above the 22-unit text floor the layout already uses (`LEGIBLE_SCALE`). Card name lines are smaller and rely on the existing hover detail (`_show_detail`) and hold-to-inspect overlay for close reading. Add a `148 × 207` case to `test_card_face_layout.SIZES`.

**Alternatives considered**:
- (a) One card row, with "floating" shown as cards dropped and dimmed under the badges. Rejected: a card under the Spell badge reads as the Spell, which is the problem the clarification raised.
- (b) A floating row about two-thirds the size. This was option C in the clarification, and the user did not choose it.

## R5 — Action row geometry

**Decision**: One row, `ACTION_ROW_H` tall, the card side's full width. With w = row width, it splits into:

- `secondary[0]` = (w − 2·S) / 4
- `secondary[1]` = (w − 2·S) / 4
- `commit` = (w − 2·S) / 2

`commit` is Play, and it never moves. An unused cell is left blank (FR-021).

What the two secondary cells hold:

| Phase | Cells |
|---|---|
| Challenge | Fuse, Divert |
| Final Journey | Fuse, Regroup |
| Final Enemy | Fuse, — |
| Upgrade | Undo Upgrade, — |

A step under way turns its own action into Cancel in place (as `_secondary` does now). Give up Reserve leaves this list and becomes the Reserve place's toggle (`toggle_tap: {"type": "toggle_give_up_reserve"}`). That leaves at most two secondary actions in every phase (spec edge case), so `action_bar._cells` reduces to fixed cells. Under Cavalier, Fuse's cell is blank.

## R6 — Final Battle: narrower left side and card sizes

**Decision**: In `final_journey` and `final_enemy` (and their Soak), `solve()` uses `FINAL_LEFT_W` = 340 in place of `clamp(32%, 400, 548)`. The card side grows from 824 to 884.

- **Final Journey** (7 places, 7 cards). Places row at 7 columns gives w ≤ (884 − 6·10) / 7 = 117. Floating row of up to 7 at the same width fits one row. Height for 2 rows of 164 is fine. **≈ 117 × 164.** Today's Final Battle card is 145 × 203.
- **Final Enemy** (6 places, up to 9 cards: 16 Mage Cards less 7 discarded after the Final Journey, fewer if any were Trashed or Regroup ran). The floating row wraps to a second row only when it cannot hold the remaining cards at the chosen width. The solver tries widths from the largest down and keeps the first for which every stage k = 0…min(6, n) fits: places row (outline if k = 0), ⌈(n − k) / cols⌉ floating rows, strip and action row, all within the body.
  - n ≤ 8: ≈ 117 × 164.
  - n = 9 (no card Trashed, no Regroup): ≈ 101 × 141. Stage k = 1 needs the places row plus 8 floating cards, and two floating rows would not fit in height, so all 8 must fit one row: (884 − 7·10) / 8 ≈ 101.

**Outcome of the check (T037)**: At 340 the dragon face clipped: its HP tiers ran past the panel's edge and "THE FINAL ENEMY" overran it. At 360 the heading still touched the edge. **`FINAL_LEFT_W` is 380**, where nothing clips. The card side is then 844 wide, and the measured sizes are:
- Region: 149 × 208.
- Final Journey and an 8-card Final Enemy: 112 × 156.
- A 9-card Final Enemy: 96 × 134.

All three sizes are in `test_card_face_layout.SIZES`. The Final Journey's "still needs" list now wraps; before this change it ran past the box at 400 too.

**Rationale**: The clarification asks for every card on screen at once, without scrolling. A narrower left side is the clarified way to buy room. 340 is the provisional width.

**To verify (planned task)**: Render the dragon face and preview at 340 with `tools/design_shots.gd` and `tools/space_audit.gd`. Confirm:
- the dragon stats, the tier ladders and the math box's `ROW_H_FINAL` rows stay unclipped;
- text stays at or above 22.

If 340 clips, step up by 20 until it does not, and recompute the sizes above.

**Risk to surface**: Final Battle cards get smaller than today (117 wide, or 101 with a full 9-card Final Enemy Hand, against 145 today). Hover detail and inspect carry the reading load. If that is not acceptable, the next lever is putting the role badge on the place outline itself in the Final Battle, which would drop the 88 strip and give ≈ 130 wide. That needs a spec change (FR-014/FR-018), so it is not planned.

## R7 — Dragging

**Decision**: `CardView` gains a drag that starts after the pointer moves more than `DRAG_START` = 12 units with the button held, before the hold-to-inspect timer fires. Dragging cancels the hold. The card follows the pointer on the top layer. On release, `hand_tray` hit-tests the place and floating rects and emits `{"type": "put", "id", "target"}`. A miss emits nothing, and the card glides home (FR-006, US2-4). A fused top card drags its tucked partner along (spec edge case).

**Rationale**: Godot's built-in `_get_drag_data` / `_drop_data` needs a drop target per Control and gives a preview copy, not the card itself. The tray already owns every card's position (`home`, `_glide`), so a manual drag keeps the glide and reduced-motion rules in one place (FR-009).

**Alternatives considered**: Godot's built-in drag and drop. Rejected for the reasons above.

## R8 — Keyboard

**Decision** (FR-007):

- `1`–`9` picks the card at that index in on-screen order: the places left to right, then the floating row.
- While a card is held, `Tab` / `Shift+Tab` moves the target highlight across the places and the floating row, `Space` puts the card there, and `Esc` puts it down (Esc already cancels modes).
- With nothing held, `Tab` keeps moving the hinted next place.
- `Enter` stays Play, and `B` stays the Boost target.
- `R` toggles Give up Reserve against a Ranged enemy.

**Rationale**: This extends the existing bindings in `main._unhandled_key_input` without taking keys from them.

## R9 — Tests and checks to change

- `tests/test_turn_draft.gd`: pick and put, swap, send back to floating, the derived Reserve, refusals (tucked card, Reserve with fewer than four cards), `to_action` unchanged.
- `tests/test_role_slots.gd` → places shaping: order per phase, Reserve states including `given_up`, numbers unchanged from today's cases.
- `tests/test_layout_solver.gd`:
  - strip ≤ half of the old band;
  - action row split within 2% (SC-003);
  - every stage fits, with no overlap, for hand sizes 1–4 (Region) and 7, 8, 9 (Final);
  - Final left side is `FINAL_LEFT_W`.
  - Replace "Hand cards no smaller than before" with a legibility floor.
- `tests/test_view_state.gd`, `test_emphasis.gd`, `test_board_responses.gd`: update for `places` and the new intents.
- `tools/ui_check.gd`: drive placement through `pick` / `put` intents; keep the overlap and space checks at every `MATRIX` window.
