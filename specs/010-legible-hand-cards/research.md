# Research: Legible Hand Cards

Figures are design units. "phone-tall" is the `layout_solver.MATRIX` row (1558 × 720 view, 87-unit side insets, 39-unit bottom inset); "baseline" is 1280 × 720.

## R1 — The engine stays untouched; the draft keeps its shape

**Decision**: `TurnDraft` keeps `sets`, `reserve`, `held` and `boost_to`. A "position" is not stored: it is the role a card holds, read through `place_of()`. Three functions are added:

- `deal(hand)`: fills the positions in draw order (R2). It is called after every `reset()` in a building phase.
- `settle(hand)`: repairs the positions after the Hand or the Fuse changes (R3).
- `swap(a, b)`: two cards trade positions. This covers the Final Enemy's extra cards, which have no role.

`to_action()` is unchanged, so the engine receives the same dictionaries (FR-020).

**Rationale**: 009's `put` already swaps an occupant into the held card's old place. Adding a fill step and a repair step is smaller than replacing the model, and every existing draft test still applies.

**Alternatives**: an explicit `positions: Array` of card ids. Rejected because it duplicates `sets` and `reserve`, which the engine needs, and two copies would drift apart.

## R2 — Fill order at the deal

**Decision**: when the Hand has at least as many cards as role positions, card *k* in `game.hand` order goes to position *k* in rulebook order:

| Stage | Positions, left to right |
|---|---|
| Region | Reserve · Element · Spell · Boost |
| Final Journey | Reserve · E1 · S1 · B1 · E2 · S2 · B2 |
| Final Enemy | E1 · S1 · B1 · E2 · S2 · B2, then extra cards with no role |

When the Hand is shorter, cards fill Spell, Element, Boost and then the Reserve, per set. This only happens at the end of a short deck, or when cards arrive after a Divert.

**Rationale**: "in the order they are drawn" (clarification). Filling Spell first keeps a short Hand legal, since the rules require a Spell.

## R3 — Keeping positions valid after the Hand changes

**Decision**: `settle(hand)` runs after `drop()` (Divert), `choose_fuse_element()`, `unfuse()` and `deal()`:

1. If the Reserve is not on offer (`reserve_offered` is false) and the Reserve holds a card, move that card to the first empty role, in the order Spell, Element, Boost. This covers a Divert down to 3 cards, and a Fuse in a 4-card Hand, where the engine's `_reserve` leaves no Reserve.
2. If a role is empty and an extra card (Final Enemy) or the Reserve is free, nothing moves. The player fills it. The label shows the empty state.
3. After `unfuse()`, the tucked card goes into the first empty position: Spell, Element, Boost, then the Reserve.

**Rationale**: the board never shows a card in a position the engine will not treat as that role.

## R4 — Aiming the Boost from the preview panel

**Decision**:

- Against an Enemy, `view_state.math` marks the Attack and Initiative sums `aim: {set, to}`. Each `preview_panel` row then becomes a button. It emits `{type: "aim_boost", to}`, and `main` resolves the set as FR-018c says: the held card's set if that card is a Boost, else the first unaimed set, else set 0 in a Region. In the Final Enemy, with both aimed and nothing held, the tap is refused with "Pick up a Boost card, then tap where it goes."
- **Row height**: rows the player can aim at are `ROW_H_AIM` = 88 tall (`T.TAP_MIN`); other rows keep 64 (Region) and 52 (Final).
- **Height budget**:
  - Region Enemy at phone-tall: the preview may take 273 (601 body − 12 − `ENCOUNTER_MIN` 316). Today's fullest Enemy box is 272. Two 88 rows would add 48. To pay for them:
    - the Initiative note is drawn inside the Initiative row's 88, under its cells (64 + 20), instead of on its own line (−32);
    - the Region's "Playing this ends the game in defeat" line is dropped, as the Final Battle already does; the red edge, the verdict and Play's warning look still say it (−32).
    - Result: 88 + 88 + 44 + 2 × 6 + 24 = **256 ≤ 273**.
  - Final Enemy: 88 + 88 + 44 + 48 + 4 + 12 + 24 = **308 ≤ 313** (phone-tall: 601 − 12 − `DRAGON_MIN` 276) and ≤ 340 at the baseline.
- The Boost's term already sits in the row it adds to (the engine's `explain` puts it there). An unaimed Boost has no term yet. Both rows then show a dimmed "Boost?" cell and a gold edge inviting the tap.
- Keyboard: `B` keeps switching the active set's aim between Attack and Initiative (`toggle_boost_to`). It is the keyboard path for FR-019. `I` stays card inspect, so no letter is given to Initiative.

**Alternatives**:

- A toggle on the Boost label: the label would grow to 88, costing card height. Rejected in clarification.
- Per-set aim chips in the Final Enemy rows: chips at 88 force the terms to wrap, giving a box of about 358, which is over the 313 budget.

## R5 — The action row shares its width by cell count

**Decision**: Divert and Regroup stay in the action row (user, 2026-10-17). `layout_solver` lays the row out from the number of cells *k* the phase uses. `view_state` reports *k* as `action_cells`: Play plus the secondary entries, with blank cells counted while *k* ≤ 3.

| Cells | Secondary cells | Play |
|---|---|---|
| 1–3 | ¼ each, blank when not on offer | right ½ |
| 4 | ¼ each | right ¼ |
| 5 | ⅕ each | right ⅕ |

Cell order from the left:

1. Fuse, or Undo Upgrade in the Upgrade phase.
2. Divert, or Regroup in the Final Journey.
3. Give up Reserve.
4. Play.

Cancel replaces the action that started it, in the same cell.

*k* = 4 only arises against a Ranged Enemy while the Reserve holds a card. From the deal (R2) that is the whole Encounter, unless a Divert leaves three cards. Then Give up Reserve leaves the row and Play widens back to half. No phase uses five cells yet; the rule is there so a later action fits without a redesign.

**Rationale**: this is the user's rule. Play stays the rightmost button, so it stays under the right thumb even when it narrows. A quarter of the card side is still ≥ 200 wide at every shape, well over `T.TAP_MIN`.

**Alternatives**:

- Divert in an encounter-action cell at the top-left of the card side: this costs the cards nothing, but the user prefers the row.
- Divert inside the left column: no height to spare (316 + 12 + 273 = 601 at phone-tall).

## R6 — One-row layout and card size

**Decision**: `layout_solver.solve` replaces the `slots` region and the places/floating bands with:

- `hand`: from `body_y` to `actions.y − GAP` (501 tall at phone-tall, 528 at the baseline).
- `positions`: one cell per position, each `LABEL_H` = 36 of label over a card. Labels are dropped in setup, Soak and Upgrade (`label_h = 0`).
- `actions`, `commit`, `secondary`: laid out by cell count (R5). `solve` takes `action_cells`.

Card size: for `n` = max(Hand size, role positions), try 1, 2 and 3 rows. With `cols = ceil(n / rows)`:

- `w = min(CARD_MAX_W, (band.x − (cols − 1)·gap) / cols)`
- `h = w / CARD_ASPECT`, reduced if `rows·(LABEL_H + h) + (rows − 1)·GAP > band.y`

Keep the arrangement with the widest card. On a tie, prefer the arrangement whose row break falls on a set boundary (the Final Journey's 4 + 3). Positions fill rows left to right, top to bottom, centred.

Resulting sizes:

| Shape | Stage | 009 | 010 |
|---|---|---|---|
| phone-tall | Region | 138 × 194 | **220 × 308** (1 row) |
| baseline | Region | 148 × 207 | **197 × 275** (1 row) |
| phone-tall | Final Journey (7) | — | 148 × 208 (2 rows, 4 + 3) |
| baseline | Final Journey (7) | ≈ 117 wide | **158 × 222** (2 rows, 4 + 3) |
| baseline | Final Enemy (9) | ≈ 101 wide | about 158 × 222 (2 rows, 5 + 4) |

`card_size_for`, `_stages_fit`, `floating_rects`, `outline_height` and `PLACE_EMPTY_H` go. There are no longer any stages of placing to fit.

**Name size check** (`card_face.name_size` = 0.43 × name band, where the band is 15.5% of `h` minus 4): at h = 308, 0.43 × (48 − 4) ≈ **18.9** ≥ 17 (SC-002). At h = 275, about 16.6, against about 11 in 009.

## R7 — Place labels replace the role strip

**Decision**: `role_slots.gd` becomes `place_labels.gd`: one short label per position, drawn on the position's `LABEL_H` band over its card. Each label shows the role icon, the role name and the state. There is no number and no choices. The label tap and drop are forwarded to the position. Set 2's first label carries the set divider. The Reserve label carries the Steep or Freeze rule mark. `view_state.places` drops `number`, `counts_to`, `choices` and `toggle_tap`, and adds `rect_index`, the position's slot in the solver's `positions`.

Board responses that flew a number to the strip (`number_rect`) now fly it to the preview row's total, where the value is now read.

## R8 — Give up Reserve in the action row

**Decision**: `view_state._secondary` returns `[Fuse | Undo Upgrade, Divert | Regroup, Give up Reserve?]`, with Cancel in place of the action under way. The third entry is present only against a Ranged Enemy while the Reserve holds a card. Give up Reserve is a toggle button (`active` while on), and the `R` key still toggles it. `action_bar` builds as many secondary buttons as entries and asks the solver's cells for their rects.

## R9 — Tests and checks

- `test_turn_draft`: `deal` order for 4, 3 and 1 cards, the Final Journey and the Final Enemy with extras; `settle` after a Divert to 3 cards and a Fuse in 4; `unfuse` refill; `swap` with an extra card.
- `test_layout_solver`: the R6 table at every `MATRIX` row; cards ≥ the 009 size per shape (FR-013); labels and cards inside `hand`; the R5 splits for 3, 4 and 5 cells within 2%, Play's right edge on the row's.
- `test_view_state`: no `number` on places; the aim rows against an Enemy, none on a Journey; Give up Reserve as `secondary[2]` only against a Ranged Enemy with a Reserve; `action_cells` 3 or 4.
- `test_card_face_layout`: the longest name ≥ 17 at h = 308.
- `test_role_slots` → `test_place_labels`.
- `ui_check`: building driven through swaps; aim-row tap size ≥ 88; preview fits its region at every shape; no overlap.
- `design_shots`: phone-tall Region and Final Battle, for the eye check of SC-003.
