---

description: "Task list for Raised Stone and the Math in Plain Sight (revision 2)"
---

# Tasks: Raised Stone and the Math in Plain Sight (revision 2)

**Input**: Design documents from `/specs/006-etched-stone-polish/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Included. The plan names `test_terms.gd` and `test_role_slots.gd` as the
gates for FR-002–FR-011 and SC-002, and extends the layout and contrast tests. Each is
written before the code it checks.

**Organization**: By user story:
- US1, slots and numbers (P1)
- US2, the math box (P2)
- US3, raised boxes and flat ground (P3)
- US4, a board that answers (P4)
- US5, every screen (P5)

Stages (plan.md): A = US1 + US2; B = US3 + US4, ending in the owner's sign-off; C = US5.

## Already done under revision 1 (kept; commits `02004c7`…`2ef4ccb`)

- The space-audit tool and its baseline.
- The tokens.
- The content-sized left column.
- `StoneStyle` raised boxes on the play screen.
- The board-response table and zone flares.
- The waiting zone's breathing edge.
- The rail-and-Hand pairing.
- The `ui_check` `SubViewport` fix and its space check.
- The ornament icons.
- The rift effects, which were built and then removed.

The revision 1 task list is in git history (`git show 2ef4ccb:specs/006-etched-stone-polish/tasks.md`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Paths are relative to the repository root. Run all tests with `./tools/test.sh`.

## Conventions every task follows

- **The engine gains reporting only** (plan Complexity Tracking). Never change a rule
  or an existing result field's value. `data/cards.json` is never edited.
- **GDScript style**: tabs, `##` doc comments on every function and file, typed
  locals, and preload constants like `const T = preload("res://ui/theme/tokens.gd")`.
  Match the surrounding file.
- **Tests** extend `"res://tests/base.gd"` and use `eq()` / `ok()`. Build games as
  `tests/test_view_state.gd` does.
- **Floors**: minimum text 22 (`T.TEXT_MIN`; term labels may be 18 with
  `set_meta("small_ok", …)`), tap target 88 (`T.TAP_MIN`), contrast ≥ 4.5:1 for text
  and ≥ 3:1 for numerals ≥ 32.
- **Motion**: anything that moves checks `UI.reduced_motion` and applies the end state
  at once when it is true.
- **No ambient effects**: nothing glows, flickers or moves on the ground.
- **Generation**: ComfyUI runs on this Mac are allowed (memory). Keep them to the
  four-candidate run in T030, and say how long it takes.
- **Commits**: commit at the end of each phase, with no Claude attribution lines.

---

## Phase 1: Setup

- [X] T001 Commit the revised spec and design documents as they stand
  (`specs/006-etched-stone-polish/`: spec, plan, research, data-model, contracts,
  quickstart, checklist, this file). Message: "006 revision 2: slots with numbers, the
  math box, raised boxes on a flat ground".
- [X] T002 Take the revision 1 reference screenshots:
  `godot --path . -s tools/shot.gd -- build/006-rev1 phone-16x9 desktop`.
  Confirm `build/006-rev1/phone-16x9/05_challenge_assigned.png` exists. build/ is
  git-ignored.

---

## Phase 2: Foundational (the engine's terms; blocks US1 and US2)

**Purpose**: Every number in the slots and the math box comes from the engine
(FR-010). This adds the reporting the UI reads.

**⚠️ CRITICAL**: US1 and US2 read `terms`; complete this phase first.

### Tests (write first; they must fail)

- [X] T003 Create `tests/test_terms.gd`. For a game built per seed in `range(1, 13)` with
  each dragon, walk every Region Encounter by forcing the Key Card: set the game's Key
  Card the way `tests/test_rules.gd` and `tests/test_game.gd` already do; reuse their
  helpers.
  - **Sets to try**: for each Encounter, build Action Sets from Hand combinations
    (every Spell in the Hand, each with every other card as Element, the rest as
    Boost), both `boost_to` values against Enemies, and one Fused set when the Hand
    allows.
  - **Per result of `game.explain(action)`**:
    - (a) for each `sum` present in `terms`, `Σ value == total`, where the total is:
      `attack` → `r.attack`, `initiative` → `r.initiative`, `move` → `r.move`,
      `target` → `r.mp`, `damage` → `r.damage`, `time` → `r.time_penalty`. And the
      other way: every one of those totals that is present in `r` and non-zero has
      its sum present in `terms` (`target` only when Steep raised the MP), so a
      missing sum fails rather than passing vacuously. No term has `value == 0`;
    - (b) every key of `game.preview(action)` has the same value in
      `game.explain(action)`, except `terms` and `complete`;
    - (c) `complete == true`;
    - (d) for the Fused set, the term whose `card` is the fused Element (or the Spell
      term, when the fused Ether is what enables the enhanced action) has a `note`
      containing "fused".
  - **Incomplete sets**: a set with only a Spell gives `complete == false` and still
    has a `move` or `attack` sum equal to the Spell term.
  - **Final Battle**: force `final_journey` and `final_enemy` as `tests/test_view_state.gd`
    `_to_final` does, and check (a) and (b) against `preview_final` for
    `explain_final`, over two-set combinations.
  - **Coverage**: assert, over the whole run, that at least one result each had an
    Armor term, a Night Travel term, a Steep term, a Reserve term, an Ambush term, a
    Storm or Hazards term, an Early damage term noted "Ranged" while the player's
    Initiative was ahead, and a Poison result whose `poison` > 0. That proves the
    modifiers and abilities were reached. If the seeds miss one, add a forced case:
    build the encounter dictionary directly and call `Rules.resolve_enemy` /
    `resolve_journey` with that Hardship or ability.

### Implementation

- [X] T004 In `engine/rules.gd` `resolve_enemy`, build `var terms := []` from the
  existing locals and add `"terms": terms` to the result. Each term is
  `{"sum", "label", "source", "value", "card": null, "note"}`.
  - **`attack`**:
    - Spell: `act.value`. Note "enhanced" when `act.enhanced`, and "counts as 1: no
      action fits" when the basic action does not fit either.
    - Boost, when not to Initiative: `s.boost`. Under Night Travel, follow it with a
      Night Travel term of `-(s.boost - _boost(s, hardship))`.
    - Armor, when `act.enhanced and act.type == "attack"`:
      `-(pre_armor - attack)`, where `pre_armor` is the value before `maxi(0, …)`.
  - **`initiative`**: Element `s.initiative`; Boost when to Initiative (with the Night
    Travel line).
  - **`damage`**: Early damage `enemy.attack.value`, plus an Ambush term of the same
    value when doubled; Combat damage. (Against an Enemy, Storm never adds damage:
    `time_penalty` is non-zero only under Hazards, so no Storm term is emitted here.)
    - When `early` is forced by **Ranged** (`enemy.ability == "ranged"` and not
      dodged, while `enemy.initiative <= initiative`), the Early damage term's `note`
      is "Ranged: strikes first whatever the Initiative" and its `source` is
      `ability`. When Ranged was dodged by giving up the Reserve, add no term; the
      Reserve pill says it (T020).
  - **`time`**: Hazards.
  - **Emit only non-zero terms**, except the Spell term, which is always present.
  - Do not change any other line's arithmetic.
- [X] T005 In `engine/rules.gd` `resolve_journey`, do the same:
  - **`move`**: Spell; Boost (with the Night Travel line); Reserve `reserve_boost`,
    when the enhanced action matches the MP's Ether.
  - **`target`**: MP `journey.mp.value`, plus Steep `reserve_boost` when the peril is
    Steep.
  - **`damage`**: Treacherous 1; Storm.
  - **`time`**: the time penalty, labelled "Time Penalty".
- [X] T006 In `engine/game.gd`:
  - **Final Battle terms.** Add `terms` to `_final_journey` (`move`: "Spell 1",
    "Boost 1", "Spell 2", "Boost 2", "Reserve") and to `_final_enemy`:
    - `attack`: "Spell 1", "Boost 1", "Spell 2", "Boost 2" (Boosts only when to
      Attack), then **one** Armor term on the combined sum, `-(pre_armor - attack)`,
      as the engine removes Armor once from the total (`game.gd` `_final_enemy`);
    - `initiative`: "Element 1", "Element 2", and each Boost sent to Initiative;
    - `damage`: "Tier attack", "Early damage", "Carried damage", only when a tier is
      reached.
  - **`explain(action)`**: identical to `preview(action)` except that the "Assign a
    Spell, an Element and a Boost." and "An Action Set needs a Spell." errors are
    skipped. Resolve with whatever roles are filled (`_set_stats` already tolerates
    nulls), then set `complete` to whether those checks would have passed.
  - **`explain_final(action)`**: the same for `preview_final`.
  - **Fuse note.** Fuse lives in `game.gd` (`_set_stats`), which `rules.gd` never
    sees. In `explain` and `explain_final`, after the rules return, set `card` on the
    Spell, Element and Boost terms from the set's ids. When the set has a `fuse` whose
    `top` is the set's Element, append "fused: <Ether>" to the note of the Element's
    `initiative` term, and to the Spell term's note when the action is enhanced
    (the fused Ether is what matched). Fuse adds no line of its own
    (contracts/math-box.md).
  - Doc comments on each.

  Run `./tools/test.sh`: `test_terms`, `test_rules`, `test_game` and
  `test_playthrough` must all pass.

**Checkpoint**: Commit "Engine: report the terms behind each result".

---

## Phase 3: User Story 1 - Numbers that go where they count (Priority: P1) 🎯 MVP

**Goal**: Full-size role slots that carry the engine's numbers, flying in on
placement; actions beside the slots; no button row under the Hand
(contracts/role-slots.md).

**Independent Test**: quickstart §2 steps 1–7.

### Tests for User Story 1 (write first)

- [X] T007 [P] [US1] Replace `tests/test_role_rail.gd` with `tests/test_role_slots.gd`
  (delete the old file and its `.uid`). It tests a new `ViewState.role_slots(vs)`
  (renamed from `rail_tokens`, same entry point in `build()` as `vs["slots"]`).
  - (a) **Nothing placed**: three slots, `spell` `next`, others `empty`, each `tap`
    `select_slot`.
  - (b) **After a Spell**: Spell `state == "filled"`, `number ==` the Spell term's value
    from `game.explain(draft.to_action()).terms`, `counts_to` `attack` or `move`, and
    `tap == {"type": "take_back", "id": id}`.
  - (c) **The Spell number changes**: choose a Spell whose enhanced Ether is in the
    Hand on another card. Place that card as the Element and assert the Spell slot's
    `number` changes to the enhanced value.
  - (d) **Element**: `number == initiative`, `ether` = the card's Ether.
  - (e) **Boost**: `number == boost`, and `boost_to` is set against an Enemy and null on
    a Journey.
  - (f) **No names**: no slot has a `name` key; only `tooltip` names the card.
  - (g) **Final Battle**: six slots with `set` 0 and 1.
  - (h) **Recap**: recap slots with `inspect` taps; Hand cards carry `played_role`
    (carried over from `test_role_rail`).
  - (i) **Intent parity**: the non-null taps equal the old intent set (`select_slot`,
    `take_back`, `toggle_boost_to`).
- [X] T008 [P] [US1] Update `tests/test_layout_solver.gd` for research R3:
  - **Regions**: in `ORDER` and every test, rename the `rail` region to `slots`, and
    turn the rail-height tests into slot band tests. (`actions` and `commit` are
    already in `ORDER`; they move.)
  - `test_slot_band_and_action_column()`: for every matrix size with sets 1 and 2,
    - `regions.slots.size.y == Solver.SLOT_BAND_H` and
      `regions.actions.size.y == regions.slots.size.y`;
    - `actions` is right of `slots` with `GAP` between, and both fit the right column;
    - each slot is at least `T.TAP_MIN` wide: `regions.slots.size.x / (3 * sets)`.
  - `test_no_button_row_under_the_hand()`: `regions.hand.end.y == content.end.y`
    unless the R3 fallback is active.
  - `test_play_sits_at_the_foot_of_the_math_box()`:
    `regions.commit.position.y == regions.preview.end.y + GAP`, and
    `regions.commit.end.y == content.end.y`, in the left column. If
    `Solver.PLAY_IN_COLUMN` is false (the fallback), assert instead the bottom-right
    corner.
  - `test_the_encounter_keeps_its_height()`:
    `regions.encounter.size.y >= T.ENCOUNTER_MIN` at every non-upright size, with the
    largest preview the solver allows.
  - Keep `test_hand_cards_are_no_smaller_than_before` and the coverage test passing.

### Implementation for User Story 1

- [X] T009 [US1] **Measure `ENCOUNTER_MIN`**. With a scratch script in the session
  scratchpad, not the repo: render `EncounterFace` for an Enemy with an ability, a
  Hardship and full stats, and a Journey with a Peril, at width 400. Shrink the height
  until any child's rect leaves the face. Record the smallest height that fits for
  both as `const ENCOUNTER_MIN := <n>` in `ui/theme/tokens.gd`, with a comment.
  - **The R3 gate**: compute the math box height for the fullest composition of
    **every** kind, with equation rows wrapped at the real left-column width at
    1280 × 720 (term cells about 64 wide, "=", total and target included):
    - Enemy: 2 rows (research R3's estimate is 308);
    - Journey with Steep: 1 row plus the target sub-row;
    - Final Journey: 1 row of 5 terms plus the tier line;
    - Final Enemy: an Attack row of 5 terms (4 + Armor) and an Initiative row of 4,
      plus the tier line;
    each plus 24 margin, 44 consequences, 88 Play and the gaps. Take the **maximum**
    `M`. If `628 − 12 − M >= ENCOUNTER_MIN` (using the Dragon face's own minimum for
    the Final kinds, measured as above), set `PLAY_IN_COLUMN := true` in
    `ui/model/layout_solver.gd`. Otherwise set it to `false`. Either way, write the
    per-kind heights, `M` and the decision under "Results" in `quickstart.md`.
- [X] T010 [US1] In `ui/model/layout_solver.gd` implement research R3:
  - **Constants**: `SLOT_BAND_H := 184`, `ACTION_COL_W := 248` (one set) and
    `ACTION_COL_W_FINAL := 100` (two sets), `PLAY_IN_COLUMN` (T009).
  - **Right column**: `slots` = top band, width `right_w - action_w - GAP`; `actions`
    = the band's right part. The rail-and-Hand centring is replaced: the slots sit at
    the top, and the Hand takes from `body_y + SLOT_BAND_H + GAP` to `c.end.y`
    (`bottom_y` minus the commit row only in the fallback).
  - **Left column** when `PLAY_IN_COLUMN`: `encounter`, then `preview` (content-sized
    as today), then `commit` (`T.TAP_MIN` tall) at the bottom. `preview_needed`
    includes the commit's height so the Encounter keeps the rest.
  - **Fallback**: `commit` keeps today's bottom-right rect, and the Hand ends above it.
  - **Every playing step** uses the same regions, not only the challenge:
    - In Soak and Upgrade, the slot band holds the recap of the set just played (the
      `slots` region, same height), and the action column holds that step's
      secondary actions exactly as `view_state._secondary` lists them today (for
      example Undo Upgrade, Cancel).
    - The `preview` region holds the Soak meter or the XP purse, sized by their
      `needed_height()` as today, and `commit` stays under it at the foot of the left
      column, carrying that step's existing primary, unchanged.
    - Before the first Encounter and between Regions (no set yet), the slots show
      three `empty` slots and the actions column is empty but keeps its width, so
      the Hand does not jump.
  - Update the doc comments. Make T008 pass, and add to T008 one case each for the
    Soak and Upgrade steps asserting the same `slots`, `actions` and `commit` rects.
- [X] T011 [US1] In `ui/model/view_state.gd`:
  - In `build()`, while playing, call `game.explain(draft.to_action())` (or
    `explain_final`) and store it as `vs.explain`, next to `vs.preview`.
  - Rename `rail_tokens` → `role_slots`, stored as `vs["slots"]`. Shape it per
    data-model.md § RoleSlot:
    - `number` for Spell from the `explain.terms` entry with `source == "spell"` (and
      label "Spell 1"/"Spell 2" per set in the Final Battle);
    - Element from the card's Initiative; Boost from the card's Boost;
    - `counts_to` from the Encounter kind and `boost_to`;
    - `boost_to` only when the set's `show_boost_to`.
  - **The toggle** moves into the Boost slot: no separate `boost_to` token. The slot's
    target icon carries `{"type": "toggle_boost_to", "set": n}` as `toggle_tap`.
  - Make T007 pass.
- [X] T012 [P] [US1] In `ui/fx/flight_layer.gd` add
  `func fly_text(text: String, from: Vector2, to: Vector2, colour: Color, font_size := 44, duration := T.MOVE) -> Tween`.
  It makes a `display_bold` label at `from` (global, centred), tweens its position to
  `to` with `TRANS_CUBIC`/`EASE_OUT` and a slight scale-down, then frees it. It
  returns null and does nothing under `UI.reduced_motion`.
- [X] T013 [US1] Rename `ui/widgets/role_rail.gd` → `ui/widgets/role_slots.gd` (`git mv`;
  regenerate the `.uid`) and rebuild it per contracts/role-slots.md:
  - **Layout**: an `HBoxContainer` filling the slots region. Each slot is a `Button`
    with `StoneStyle` `plinth` styles (normal / hover / pressed), expanding to share
    the width equally, and at least `T.TAP_MIN` square.
  - **Content**, top to bottom:
    - the role icon (24) and name in `T.LABEL` (the name only when the slot is ≥ 140
      wide; otherwise a set pip in the Final Battle);
    - the number in `["display_bold", 44]` (`+n` for Boost; Ether icon and number for
      Element);
    - a row with the `counts_to` icon (24). For the Boost against an Enemy, this is a
      small `Button` with the target icon whose `pressed` emits `toggle_tap`. It is at
      least 44 × 44 and marked `help_target`, like the existing small hit areas, so
      `ui_check` applies its 44 minimum.
  - **Edges**: the `next` slot has a 3-unit `T.FOCUS` edge, a filled one an edge in
    its card's Ether, a recap one is muted with the number struck.
  - **Interface**: `func slot_rect(set_index, role) -> Rect2` (global) and
    `func number_rect(set_index, role) -> Rect2` (the number label's global rect, for
    flights), and keep `flare(card_id, colour, duration)`.
  - No card names.
- [X] T014 [US1] In `ui/widgets/action_bar.gd`, lay out the secondary actions in the
  `actions` region:
  - more than two → a `GridContainer` with 2 columns (1 column in the Final Battle),
    each button `T.TAP_MIN` tall, icon above a short label in `T.LABEL`;
  - two or fewer → stacked full-width rows.
  - **Primary**: the action bar always places `primary` in the `commit` rect it is
    given, wherever the solver puts it: at the foot of the left column when
    `Solver.PLAY_IN_COLUMN`, else the bottom-right corner. So at the US1 checkpoint
    Play is already under the box and fully usable, before T020 exists. Expose
    `primary` so T020 can give it the verdict text.
  - `apply_layout(actions, commit)` keeps its signature.
- [X] T015 [US1] In `ui/screens/play_screen.gd`:
  - **Regions**: rename the `rail` region to `slots`, use `RoleSlots`, and add the
    `commit` region to `_regions` when `PLAY_IN_COLUMN`.
  - **Number flight**: on `render(state, animate)` after a placement, compare each
    slot's `card_id` and `number` with the previous `vs.slots`.
    - For a newly filled slot, call `flight.fly_text(str(number), <the card view's
      centre>, rail.number_rect(...).get_center(), T.ether_ink(ether) or T.INK)`, and
      show the slot's number only when the flight lands (a `T.MOVE` timer); at once
      under reduced motion.
    - For a slot whose number changed while still filled, count it from the old value
      to the new over `T.COUNT` (a `tween_method` on the label's text) and call
      `flare("rail_token", …)`.
  - **Flight layer access**: reach it through a `var flight: Control` that `main.gd`
    sets, as `animator.flight` is set.
  - Keep `board_changed` removed.
- [X] T016 [US1] In `ui/main.gd`:
  - set `play.flight = _flight` when the play screen is created;
  - pass `preview_needed` including the commit height (done in the solver; check the
    call in `_on_resize`);
  - update the `"slots"` / `"rail"` references found by
    `grep -rn '"rail"\|regions.rail\|rail_tokens\|RoleRail' ui tools tests`.
  - `tools/space_audit.gd` and `tools/ui_check.gd`'s `_check_space` measure the
    `slots` region (rename from `rail`).
- [X] T017 [US1] Run `./tools/test.sh` (green) and the space audit (PASS). Take
  `godot --path . -s tools/shot.gd -- build/006-us1r2 phone-16x9 desktop`, look at
  every state, and drive the quickstart §2 steps with a scratch script against the
  real buttons, as the revision 1 walkthrough did. Fix defects.

**Outcome**:
- **T009 set `PLAY_IN_COLUMN` false**, and the bottom-right fallback would have
  shrunk the Final Battle's cards. So Play sits in the action column's bottom-right
  cells (research R3, Outcome). T010 and T014 were built that way.
- **T020's Play step** therefore only labels Play. The math box keeps its verdict
  line.
- **Board responses** already target `slot` (T028's rename, done here; I3).

**Checkpoint**: Commit "Role slots with the engine's numbers; actions beside them".

---

## Phase 4: User Story 2 - The math, shown (Priority: P2)

**Goal**: The box beside the Encounter becomes equation rows built from the engine's
terms, with the consequences and Play at its foot (contracts/math-box.md).

**Independent Test**: quickstart §3 steps 1–5.

### Tests for User Story 2 (write first)

- [X] T018 [P] [US2] In `tests/test_view_state.gd` add `test_the_math_box_sums_come_from_the_engine()`:
  - For a placed set against an Enemy, `vs.math.sums` has `attack` and `initiative`.
    Each sum's `terms` are exactly `vs.explain.terms` filtered by `sum`, in order.
    `total` equals `vs.explain.attack` / `.initiative`, and `target.value` equals the
    Enemy's HP or Initiative.
  - For a Journey, a `move` sum and `target` with its terms.
  - For an incomplete set, `total == null` and `missing` lists the empty roles.
  - For the Final Battle, a `tier` is present.

### Implementation for User Story 2

- [X] T019 [US2] In `ui/model/view_state.gd` add
  `static func math(game, draft, explain: Dictionary) -> Dictionary`, called in
  `build()` as `vs["math"]`. It shapes per data-model.md § Sum:
  - `sums` in display order (`attack`, `initiative` for Enemies and the Final Enemy;
    `move` for Journeys and the Final Journey), each `{id, terms, total, target,
    result, missing, tier}`;
  - `consequences` reusing today's `preview().costs` / `rewards`;
  - `verdict` and `fatal` from today's preview.
  - It does no arithmetic: totals and term values are copied from `explain`. Make T018
    pass.
- [X] T020 [US2] Rebuild `ui/widgets/preview_panel.gd` as the math box, keeping its
  `needed_height()` contract and its prompt mode for the steps that are not
  challenges:
  - **Equation rows**: for each sum, an `HFlowContainer` of term cells. A cell is a
    `VBoxContainer`: the signed value in `["display_bold", 34]` (green, red or ink by
    sign and source), over the `label` in `["body_medium", 18]` with `small_ok`.
    Then a cell "=", then the total in `["display_bold", 40]` coloured by `result`,
    then "/ target" with its icon (and the Steep terms as a small sub-row).
  - **Incomplete**: in place of "= total", a muted cell "Still needed: Element,
    Boost".
  - **Initiative note**: as today's comparison note ("You strike first" / "Struck
    first: N early damage").
  - **Consequences**: today's `_outcome_row()` pills. Add each pill's matching `damage`
    or `time` terms to its tooltip, as "Early damage 2 + Ambush 2".
    - **Abilities** are named where they act: the Early damage term's "Ranged" note
      shows under the Initiative row in place of "You strike first" (so the row never
      shows the player ahead with no reason for the early hit); the poison pill reads
      "Poison"; the Reserve-lost pill names its cause, "Freeze" or "Gave up Reserve
      to dodge Ranged".
  - **Play**: the action bar's `primary` stays in the `commit` region T014 places it
    in, directly below the box when `PLAY_IN_COLUMN`. This task only changes its text
    to `"Play · " + verdict_text`, or the existing reason while incomplete; it keeps
    its gold, warning and disabled kinds.
  - **Counting**: `play_tally` and `settle` now count the totals (keep the method
    names, which the animator calls). A total that changes between renders counts
    over `T.COUNT`, unless reduced motion is on.
  - **Sizing**: `needed_height()` reports the fullest composition for the Encounter
    kind and step: Enemy 2 rows, Journey 1 row with a target sub-row, Final 1 row of
    5 terms, wrapped at the box width, plus consequences (and Play when it is not
    placed separately).
  - Remove the `_Compare` bar class once nothing uses it.
- [X] T021 [US2] Run `./tools/test.sh` and the space audit. Take screenshots at
  `phone-16x9` and `desktop`. Find, with `tools/shot.gd` seeds or a scratch script,
  one state each:
  - an Enemy with Armor in the Spell's Ether;
  - a Night Travel Journey;
  - a Steep Journey;
  - the Final Journey and the Final Enemy.

  Read each box: the terms visibly add up to the total. Fix defects. Record anything
  the R3 gate decided under "Results" in `quickstart.md`.

  **First-time viewer (SC-003)**: save the Hardship state's screenshot (the Night
  Travel or Armor one) and, with the stage A screenshots, ask the owner to show it to
  someone who has not seen the box and time how long they take to say what changed
  the result (quickstart §3 step 3; the target is 10 seconds). Record the answer under
  "Results"; if no viewer is available yet, record it as pending and ask again at
  T031.

**Checkpoint**: Commit "The math box: the engine's terms as equations, Play at its
foot". **Stage A is done.** Send the owner screenshots of the new layout (SendUserFile)
before stage B. This is a look, not a gate.

---

## Phase 5: User Story 3 - Strong raised boxes on a flat ground (Priority: P3)

**Goal**: Finished raised boxes with flat edges, and a generated flat ground
(contracts/boxes-and-ground.md).

**Independent Test**: quickstart §4 steps 1–2 and §5.

### Implementation for User Story 3

- [X] T022 [P] [US3] In `ui/theme/stone_style.gd` (research R6):
  - **No glow**: replace the glow drawing (the soft wide polyline and the interior
    wash) with a solid edge line. Width `2.0` at rest, `3.0` when `glow > 0`, in
    `edge` at rest and `glow_colour` when glowing, with alpha `0.6 + 0.4 * glow` so
    the waiting zone's breath still reads. `GLOW_MAX_UNDER_TEXT` becomes 0.
  - **Raised kinds** (`well`, `plinth`, `slab`, `lintel`): a hard drop shadow,
    offset `(0, 6)` (`(0, 8)` for `slab`), alpha 0.5, no blur; and the face filled
    flat with `T.BG_RAISED`, no texture.
  - **`inset`**: a flat `T.BG_SURFACE` face.
  - Keep chamfers, the bevel lines and `pressed`.
  - Update `tests/test_stone_contrast.gd` so its "bright" case is `T.BG_RAISED`, the
    face colour, instead of the grain blended with focus. Keep the ground-extremes
    checks.
- [X] T023 [P] [US3] Reverse the face change from revision 1 in `ui/widgets/face_frame.gd`.
  The Encounter frame keeps its `StoneStyle`, but `inset` → `well` so it reads as
  raised like the other zones.
- [X] T024 [US3] Add a `pattern` command to `tools/generate_art.py`:
  - **CLI**: `choices` gains `"pattern"`. `names` are pattern names from a new
    `PATTERNS` dict: `{"ground": "<prompt>"}`, with the prompt from research R5.
  - **Run**: `text_to_image(prompt, seed, "etch/pattern-" + name)` writes to
    `build/art/pattern/<name>-<seed>.png` for `seed .. seed+count`, skipping existing
    files.
  - Do not read `art/STYLE_PROMPT.md` for patterns.
  - **Docs**: update the module docstring's usage block with
    `python3 tools/generate_art.py pattern ground --count 4`.
- [X] T025 [P] [US3] Create `tools/make_ground.gd` (`extends SceneTree`, headless):
  `godot --headless --path . -s tools/make_ground.gd -- <in.png> [out.png]`.
  1. **Load** the image and convert it to luminance.
  2. **Make it seamless**: build an offset copy shifted by half the width and height
     (wrapping), and cross-fade the original and the offset copy with a weight that
     is 1 at the tile's centre and 0 at its edges.
  3. **Quantise** to 3 tones by the 33rd and 66th luminance percentiles.
  4. **Map** the tones to `Stone.shade(T.STONE_L_MIN)`, the middle of the band, and
     `Stone.shade(T.STONE_L_MAX)`.
  5. **Resize** to 512² with `INTERPOLATE_NEAREST`, to keep the lines flat.
  6. **Save** to `res://art/stone/grain.png` by default.

  Print the tile's luminance range and PASS when it lies inside
  `[STONE_L_MIN, STONE_L_MAX]`.
- [ ] T026 [US3] The ground candidates, in two parts. **Nothing is written to
  `art/stone/` before part 2** (FR-026: the ground must not change during stage A,
  and `stone.gd` uses `art/stone/grain.png` as soon as it exists).
  1. **Generate** (may run in the background during stage A, any time after T024).
     First check that ComfyUI is up at the `generate_art.py` default server; if not,
     start it the way `tools/setup_comfyui.sh --serve` documents, in the background.
     Tell the owner it takes about 16 minutes, then run
     `python3 tools/generate_art.py pattern ground --count 4`. The images stay in
     `build/art/pattern/` (git-ignored).
  2. **Pick** (stage B, after T022 and T023). For each candidate, run
     `make_ground.gd` with an explicit scratchpad output path, copy it in as
     `art/stone/grain.png`, take one play-screen screenshot, and remove it again.
     Send the four screenshots to the owner (SendUserFile) and ask which ground to
     keep (research R5 step 3). Only then write and commit the chosen
     `art/stone/grain.png` (and its `.import`).
- [ ] T027 [US3] Run `./tools/test.sh`, including `test_stone_contrast` on the shipped
  tile, plus the bench and the space audit. Take
  `godot --path . -s tools/shot.gd -- build/006-us3r2 phone-16x9 desktop`.

**Checkpoint**: Commit "Raised boxes with flat edges on a generated woodcut ground".

---

## Phase 6: User Story 4 - A board that answers (Priority: P4)

**Goal**: Responses as flat edge changes, the flying numbers and counting totals,
nothing ambient (contracts/board-life.md).

**Independent Test**: quickstart §4 steps 2–5.

- [X] T028 [P] [US4] In `ui/model/board_response.gd` and `tests/test_board_responses.gd`:
  - `place` and `take_back` target `slot` (renamed from `rail_token`);
  - add the `slot` target to the test's allowed zones;
  - check that no entry uses a kind other than `flare`, `shudder`, `sweep` or `dim`.
- [X] T029 [US4] In `ui/screens/play_screen.gd` `flare()`:
  - rename the `rail_token` target to `slot` (calls `slots.flare`);
  - make sure every response only changes `glow` and `glow_colour` on a `StoneStyle`,
    which now draws as a flat edge (T022), or calls `UI.shake` for `shudder`;
  - delete any leftover code path that draws soft light.

  Run the scratch idle check: render the play screen, wait 10 s, and diff two frames
  1 s apart over the ground region (outside the boxes). They must be identical.
- [ ] T030 [US4] Walk quickstart §4 steps 2–4 on desktop. Run step 5 (stutter) on the
  served web build and, if an Android emulator is running, there via the
  `install-on-emulators` skill. If none is running, record that in `quickstart.md`.
  Run `./tools/test.sh`.

**Checkpoint**: Commit "A board that answers with flat edges and moving numbers".

## Stage B sign-off (US3 scenario 4 — exit point)

- [ ] T031 Build before/after pairs for `05_challenge_assigned`, `12_final_journey` and
  `07_soak` (before from `build/006-before/phone-16x9`, after from a fresh
  `tools/shot.gd -- build/006-after phone-16x9`), with the scratchpad's `pair.gd` or
  any stacking script. Send them to the owner (SendUserFile) and ask which looks more
  like Dragons of Etchinstone, and more finished. Record the answer under "Results" in
  `quickstart.md`.
  - **Not preferred**: stop. Leave stages A and B committed unless the owner asks for
    a revert, and skip Phase 7.

---

## Phase 7: User Story 5 - Every screen in the same world (Priority: P5)

**Goal**: Raised boxes, the flat ground and lore framing on every other screen
(contracts/screens-and-lore.md). **Only after T031 approves.**

**Independent Test**: quickstart §6.

- [ ] T032 [US5] Make the stone global:
  - In `ui/main.gd`, call `backdrop_layer.set_stone(true)` on every screen.
  - In `ui/theme/theme.gd`, route `box`, `panel` and `raised_panel_box` to
    `StoneStyle`: `raised_panel_box("active")` → `well` with `glow` 1, `"rest"` →
    `well`, and `box`/`panel` → `inset` when the radius is ≤ `T.RADIUS_S`, else
    `well`. `style_button` delegates to `style_stone_button`.
  - Run `./tools/test.sh` and fix contrast or layout failures.
- [ ] T033 [P] [US5] Title as **The Tear**, in `ui/screens/title_screen.gd`: the title in a
  `lintel` via `UI.carved_label`, a flat `orn_rift` behind the dragon tiles, and the
  tiles as plinths. Keep every tile stat, Settings, Glossary, How to Play, Continue
  and the credits.
- [ ] T034 [P] [US5] Rules setup as **the elders' proclamation**, in
  `ui/screens/rules_screen.gd`: a slab headed by `orn_tower` and "By order of the
  Tower", `orn_divider` between groups, and `orn_seal` on Continue. Keep every option.
- [ ] T035 [P] [US5] Region banner as a **lintel**, in `ui/overlays/stage_banner.gd`.
  Keep the number, name and glyph.
- [ ] T036 [P] [US5] Ending as an **inscribed slab**, in `ui/screens/ending_screen.gd`,
  firing `encounter_won` or `encounter_lost` on the Encounter edge. Keep the verdict,
  summary, Play again and To title.
- [ ] T037 [P] [US5] Rulebook and glossary as **scrolls**, in
  `ui/overlays/rulebook_overlay.gd` and `ui/overlays/glossary_popover.gd`: a slab with
  `orn_scroll_end` caps, and a small slab for the popover. Keep all content and
  navigation.
- [ ] T038 [P] [US5] Inspect, menu, confirm and the size notice as **slabs**, in
  `ui/overlays/overlay.gd`, `inspect_overlay.gd`, `menu_overlay.gd`,
  `confirm_dialog.gd` and `size_notice.gd`. Keep every option and button.
- [ ] T039 [US5] Run `./tools/test.sh` and the space audit. Take full screenshots
  (`tools/shot.gd -- build/006-after`, `tools/design_shots.gd -- build/006-after/design`).
  Send the owner a before/after per row of contracts/screens-and-lore.md, record the
  answers in `quickstart.md`, and rework any screen where the before is preferred.

**Checkpoint**: Commit "Every screen on raised stone".

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T040 [P] Remove what revision 2 left unused:
  - `ui/fx/backdrop_layer.gd` comments about the rift;
  - any `rail` names;
  - the `_Compare` class if still present;
  - `orn_*` icons no screen uses;
  - the `SEAM_NEUTRAL` name, renamed `RESPONSE_NEUTRAL` with its two uses.
- [ ] T041 [P] Reduced-motion sweep (SC-009): with Menu → Motion → Reduced, open every
  screen and overlay and place cards. No flight, no counting, no breath; responses
  are held colours.
- [ ] T042 Run quickstart.md end to end on the desktop build, the served web build and
  any running emulator or simulator (`install-on-emulators` skill). Record the results
  and run `./tools/test.sh` a final time. Commit.

---

## Dependencies & Execution Order

- **Setup (T001–T002)** first.
- **Foundational (T003–T006)**: the engine's terms. They block US1 (Spell numbers)
  and US2 (the box).
- **US1 (T007–T017)** after Foundational.
- **US2 (T018–T021)** after US1 (T010's `commit` region and T014's primary hand-off).
- **US3 (T022–T027)** after US2: stage B starts after stage A. T024, T025 and T026
  part 1 (generation, into `build/`) can start any time after Setup, with
  generation in the background. T026 part 2 (the owner's pick and the commit of
  `art/stone/grain.png`) waits for T022 and T023 (FR-026).
- **US4 (T028–T030)** after US3 (the flat edges from T022).
- **Gate T031** after US4.
- **US5 (T032–T039)** only after T031 approves.
- **Polish (T040–T042)** last.

### Within stories

- Tests come before implementation: T003 → T004–T006; T007/T008 → T009–T016;
  T018 → T019–T020.
- US1: T009 → T010 → T011 → (T012 ∥ T013 ∥ T014) → T015 → T016 → T017.

### Parallel opportunities

- T007 ∥ T008.
- T012 ∥ T013 ∥ T014 (different files) once T011 is done.
- T022 ∥ T023 ∥ T025.
- T024 → T026 part 1 can run alongside all of stage A, with generation in the
  background into `build/`; no file under `art/stone/` changes until part 2.
- T033–T038 (one screen each) after T032.
- T040 ∥ T041.

## Parallel Example: User Story 1

```text
Task: "T012 [US1] FlightLayer.fly_text in ui/fx/flight_layer.gd"
Task: "T013 [US1] RoleSlots widget in ui/widgets/role_slots.gd"
Task: "T014 [US1] Action column grid in ui/widgets/action_bar.gd"
```

## Implementation Strategy

### MVP first

1. Setup and Foundational (T001–T006): the engine reports its terms, proven to add up.
2. US1 (T007–T017): slots with the engine's numbers flying in, and the actions beside
   them.
3. **Stop and validate** with quickstart §2. This is the layout change the owner asked
   for by name.

### Incremental delivery

1. US1, then US2: stage A. Show the owner.
2. US3 + US4: stage B. The **T031 gate**.
3. US5: stage C.
4. Polish.
