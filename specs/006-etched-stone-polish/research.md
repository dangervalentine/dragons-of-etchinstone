# Research: Raised Stone and the Math in Plain Sight (revision 2)

Revision 1 researched carved stone lit by Ether rifts. At the stage 2 review the owner
kept the raised boxes and set the glowing effects aside (quickstart.md, "Stage 2
sign-off (T040)"). This file records what carries over and the new decisions. No item
is left as NEEDS CLARIFICATION.

## Carried over from revision 1 (built and kept)

| Was | Decision kept | Where it lives |
|---|---|---|
| D2 | **Left column split by content.** The preview asks for the height of its fullest look for the current Encounter and step; the Encounter takes the rest. Stable while cards are placed | `layout_solver.gd` (`preview_needed`), `preview_panel.gd` `needed_height()` |
| D2 | **Rail and Hand centred as a pair** when the cards are width-bound | `layout_solver.gd` |
| D3 | **Stone grain as a fallback.** Seamless noise, remapped to the luminance band; a bitmap at `art/stone/grain.png` overrides it | `ui/theme/stone.gd` |
| D4 | **`StoneStyle`.** Chamfered raised and recessed boxes with a bevel, an edge colour and a rim glow | `ui/theme/stone_style.gd` |
| D5 | **Contrast checked against the brightest and darkest ground** | `tests/test_stone_contrast.gd` |
| D8 | **The board-response table**, now rim-only | `ui/model/board_response.gd` |
| D10 | **Woodcut ornaments** | `art/icons/orn_*` |
| D12 | **Space measured as rows that nothing crosses.** Zones are drawn panels, judged at the minimum sizes | `layout_solver.empty_fraction`, `tools/space_audit.gd`, `tools/ui_check.gd` |
| — | **`ui_check` hosts the game in a sized `SubViewport`**, so every matrix size is really checked | `tools/ui_check.gd` |

**Dropped**: D6 rift light, D7 ambient motes and shimmer, D9's preview and rail zones,
and D11's per-screen rift sources.

## R1. Where the math comes from

**Need**: FR-008 and FR-010. The box shows every term of the result, and its totals
must be the engine's own. The engine returns only totals today (`Rules.resolve_enemy`,
`resolve_journey`, `Game._final_journey`, `_final_enemy`). The intermediate values
the box must show live only inside those functions: Armor removed, the Boost after
Night Travel, the Reserve's Boost, MP after Steep.

**Decision**: add **reporting-only** `terms` to those result dictionaries, built from
the same local variables that make the totals. Each term is `{sum, label, source,
value, card, note}` (data-model.md § Term).
- Armor: `act.value + boost − armor` is clamped at 0, so the Armor term is
  `−min(armor, value + boost)` and the terms always add up to the shown total.
- Night Travel: the Boost term is the card's Boost, followed by a Night Travel term of
  `−min(boost, initiative)`.
- Steep: the target is itself a sum, `mp` and then `+reserve_boost`, in the `target`
  sum.
- Consequences: Combat damage, Early damage (×2 under Ambush), Storm and the Hazards
  time each become a term of a `damage` or `time` sum, so the box can explain the
  costs as well.

`Game.explain(action)` and `explain_final(action)` run the same rules on an
**incomplete** set. They skip only the "every role filled" check, and the result
carries `complete: false`. FR-011 needs this: the box shows the terms placed so far.

**Rationale**:
- One source of truth. The UI cannot drift from the rules, which a UI-side
  recomputation could.
- The change is additive. Existing fields keep their values, which the existing
  engine tests check, plus `test_terms.gd` comparing every field before and after
  over seeded sets.

**Alternatives**:
- *Recompute terms in `view_state.gd`.* Rejected: it duplicates the rules (FR-010).
- *A separate `explain` module in the engine that re-derives the terms.* Rejected for
  the same reason: two code paths to keep in step.

**Test** (`test_terms.gd`):
- For every Enemy and Journey in the card data, each Hardship and each ability, and a
  spread of Spell, Element and Boost combinations (both Boost targets, matching and
  unmatched Ethers, Fuse):
  - per sum, `Σ terms == total`;
  - outcome, XP, damage, time and poison are equal to the result without terms.
- The same holds for both Final Battle steps.

## R2. Role slots: numbers, not names

**Decision**: the compact rail (`role_rail.gd`) becomes `role_slots.gd`. Each slot is a
raised box at least `TAP_MIN` tall and at least `SLOT_W_MIN` wide, holding:
- the role icon, small, at the top;
- the number, large (display bold, about 44 units);
- the stat it counts toward, as an icon.

**Where the number comes from**:
- **Spell**: the value of the Spell term from the engine's explanation, so it is the
  enhanced value once the Element's Ether matches, or 1 when no action fits.
- **Element**: the card's Ether and Initiative.
- **Boost**: the card's Boost, with the Attack/Initiative switch built into the slot
  (tapping the target icon toggles it; FR-005).

The view model stays `ViewState.rail_tokens()`, renamed `role_slots()`. It reads the
explanation instead of the card's raw stats, so a later placement that changes a
number (FR-004) shows at once. Recap tokens keep their inspect taps, and the Hand
keeps its played-as tags.

**Number flight (FR-003)**: `FlightLayer` gains `fly_text(text, from, to, duration,
colour, size)`. It creates a label at `from`, tweens it to `to` and frees it.
`play_screen` calls it on placement, from the card to the slot, before the slot shows
the number. Under reduced motion it does nothing, and the slot shows the number at
once.

## R3. Where the actions and Play go

**Measured** (layout solver, 1280 × 720):
- **Action column.** At most four secondary actions show at once (Fuse, Divert, Give
  up Reserve, Cancel; `view_state._secondary`). A 2 × 2 grid of tap targets beside the
  slots is `2 × 88 + 8 = 184` tall and about `2 × 120 + 8 = 248` wide. With two or
  fewer actions, they stack as two full-width rows.
- **Slots.** The right column is 824 wide. The slots get `824 − 248 − 12 = 564`: three
  one-set slots of 180, or six Final Battle slots of about 88. The Final Battle shows
  three actions at most (Fuse, Regroup, Cancel), so the grid there can be one column
  of icon-over-label buttons 100 wide, giving six slots of about 112. The slot band is
  184 tall.
- **Hand.** It gets everything below: 628 − 184 − 12 = 432. The cards (197 × 275,
  bound by width) fit with room. In the two-row Final Battle Hand the cards are bound
  by height, and they gain from the button row's removal (96 + 12).
- **Play.** The spec puts it at the foot of the math box. Left column at 1280 × 720:
  body 628 = Encounter + 12 + math box. An Enemy's math box with Play inside is about
  24 margin + 64 Attack row + 64 Initiative row + 44 consequences + 88 Play +
  4 × 6 gaps = **308**, leaving the Encounter **308**. Today it is 352–360.

**Decision**: Play sits at the foot of the math box and carries the verdict
("Play · Narrow victory", gold, or red when it would end the game). This replaces the
separate verdict line, which saves 36.
- **Gate.** The Encounter face must still fit at the minimum size: `ui_check` already
  fails on clipped or undersized content, and a solver test asserts
  `encounter.size.y ≥ ENCOUNTER_MIN`. `ENCOUNTER_MIN` is the face's own minimum: its
  stat column plus its band, measured once and recorded in `tokens.gd`.
- **Fallback, if the gate fails.** Play moves to the bottom-right corner of the right
  column, under the Hand (where the thumb rests on a phone held sideways). The math
  box keeps the verdict line. The solver keeps this as a branch chosen by
  `ENCOUNTER_MIN`, so either layout passes the same tests.

**Outcome (T009, 2026-10-15)**: the gate failed, and the planned fallback did too.
- **Measured.** `ENCOUNTER_MIN` is 310: an Enemy with four badge rows at their
  52-unit minimum. A Journey needs 202. The Enemy box with Play inside needs about
  336, which leaves the Encounter 280. The Final Enemy's rows wrap at the 400-unit
  column and need more.
- **The corner fallback costs cards.** Play in the bottom-right corner under the
  Hand would take 108 units from the Hand. The Final Battle's two rows of cards
  would then drop to 107 wide, under their 137 baseline.
- **Taken instead: Play in the action column.** Play takes the column's bottom-right
  cells: two cells (244 × 88) beside one set, one cell (118 × 88) beside the Final
  Battle's two sets. The secondary actions fill the other cells. The Hand keeps the
  full height under the slots. The math box keeps its verdict line.
- **Bigger slots.** Where a four-card Hand is bound by width, the slot band takes
  half the spare height, up to 264.

## R4. The math box layout

**Decision**: one **equation row** per sum, read left to right.
- Each term is a number with its source label in small type under it (for example `8`
  over "Spell", `+2` over "Boost", `−1` over "Armor"), then `=` and the total, then the
  target ("/ 11 HP").
- A row that does not fit the column wraps after a term; it uses an `HFlowContainer`
  of term cells.
- The total's colour carries the outcome (good, caution or bad, as today).
- Against an Enemy there is a second row for Initiative and a note: "You strike first",
  or the Early damage.
- Under the rows: the consequence pills from today (XP, damage, time, poison,
  Reserve), whose tap help stays.
- An incomplete set shows the placed terms and, in place of the total, "Still needed:
  Element, Boost".
- The Final Battle Move or Attack row adds the terms of both sets (labels "Spell 1",
  "Boost 2"), then shows the tier reached and its cost.
- Counting: a new or changed total counts up over `T.COUNT`, as `play_tally` does
  today; it is instant under reduced motion.

**Rationale**: an equation is the most literal way to show "the math involved", and
each term keeps its source in view, which a list of totals does not.

**Alternative**: a vertical ledger, one term per line. It is clearer for long sums but
twice as tall, which the left column cannot afford with Play inside (R3).

## R5. The flat ground pattern

**Decision**:
1. **Generate.** `tools/generate_art.py pattern ground [--seed N] [--count 4]` runs the
   existing ComfyUI/FLUX pipeline with a pattern prompt: "a seamless repeating pattern
   of carved woodcut lines on dark stone, flat, two tones, no shading, no glow, evenly
   spaced engraved strokes, linocut texture, tileable", at 1024². This runs on this
   Mac (allowed; about 4 minutes an image at Q4, so `--count 4` takes about 16
   minutes).
2. **Post-process.** A headless Godot tool, `tools/make_ground.gd <in.png>`
   (`Image` is available there; PIL is not):
   - makes the tile seamless by offsetting half a tile and cross-fading a band across
     the seams;
   - quantises to 3 flat tones;
   - remaps those tones into the `[STONE_L_MIN, STONE_L_MAX]` luminance band in the
     stone hue;
   - scales to 512²;
   - writes `art/stone/grain.png`.
3. **Pick.** The owner picks one of the four candidates at the US3 review; the chosen
   tile is committed then. Generation may run during stage A, but the candidates stay
   in `build/` until the pick, because `stone.gd` uses `art/stone/grain.png` as soon
   as it exists and FR-026 keeps the ground unchanged through stage A.

**Rationale**:
- "Flat lines, maybe a consistent pattern generated in comfy" (owner). Generation
  gives the hand-carved character that noise lacks.
- Post-processing guarantees the properties the game needs (seamless, flat, inside
  the contrast band) whatever the model returns. `stone.gd` already loads the override
  file, so no code changes are needed to use it.
- The contrast test reads whichever ground ships.

**Alternatives**:
- *Procedural lines in a shader.* Cheaper, but it reads as computer-drawn: the very
  objection to the cracks.
- *ComfyUI's seamless-tiling custom nodes.* An extra dependency. The offset-and-blend
  post-process is simpler and dependable.

## R6. Raised boxes, finished

**Decision**: `StoneStyle` keeps its kinds. The changes:
- **Flat lines, no glow.** Its rim glow becomes a **flat edge colour change**: a solid
  2–3-unit line in the focus or response colour, with no soft outer line. Glow is the
  thing set aside.
- **Stronger raise.** A deeper drop shadow (6–8 units, hard-edged) and a light top
  bevel.
- **Faces.** Boxes take a flat face colour: `BG_RAISED` for zones and `BG_SURFACE` for
  insets. The ground pattern no longer shows through them, so "strong boxes on a
  patterned ground" reads clearly. The grain stays on the ground only.

The play screen's slots, math box, action buttons, Hand well, Encounter frame and
header all use it.

## R7. Responses without ambient effects

**Decision**:
- **Kept**: the response table and `play_screen.flare()`, now as flat edge-colour
  changes (R6), plus the waiting zone's slow edge breath (FR-019 allows it).
- **Added**: the flying number (R2) and the counting totals (R4).
- **Already gone**: motes, shimmer and the backdrop seam responses.

`test_board_responses.gd` stays: the zone-only targets, and a still form for each
response.

## R8. Staging

**Decision**: the order is A (US1 + US2), then B (US3 + US4), then C (US5), as in the
plan.
- Stage A works on the current raised boxes, so the owner sees the layout change
  first.
- The ComfyUI tile can be generated during stage A in the background (about 16
  minutes), so it is ready for stage B.
- The tasks for revision 1's remaining Phase 6 are replaced by stage C.
