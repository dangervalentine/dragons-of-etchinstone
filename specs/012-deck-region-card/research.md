# Research: The Deck and Region Card on the Playfield

There were no open NEEDS CLARIFICATION items. The spec's Clarifications settled the reveal (lift, slide back, zoom) and the Final Battle (zoom into MP Tiers, then HP Tiers, with no lift). These decisions cover how to build it in the existing code.

## R1 — The left side's structure

**Decision**: The `encounter` region becomes the Deck. A new `ui/widgets/deck_stack.gd` fills it and owns, from back to front:

- the stack's card edges;
- the Key Card peek (R4);
- the top card: a new `region_card.gd`, or a new `dragon_card.gd` in the Final Battle;
- the existing `encounter_face`, `dragon_face` and `setup_face`, which now sit on the stack.

`play_screen.gd` fills `_regions.encounter` with the `DeckStack` instead of the three faces directly, and `encounter_node()` asks the stack for its face. The math box region (`preview`) is untouched (FR-007).

**Rationale**: One owner for everything that can sit on the Deck keeps the zoom (R3) and the peek (R4) in one coordinate space, clipped to one rect. The faces keep their code, layout and tests, and `rulebook_figure.gd` keeps using them as they are.

**Alternatives considered**:
- Drawing the stack in `play_screen.gd`. Rejected: it spreads the zoom state across the screen and the animator.
- A new layout region for the Deck beside the Encounter. Rejected: the left column (400–548 wide, 380 in the Final Battle) has no room, and the spec wants the face *on* the Deck.

## R2 — The stack's depth

**Decision**:
- `DeckStack.edges(count) = clampi(ceili(count / 2.0), 1, 8)`: card edges drawn 3 units apart, down and to the right of the top card. It shows 1 edge at 1–2 cards and 8 edges at 15–16.
- The stack takes a fixed `DECK_EDGE := 24` units on the right and bottom of the region, so the top card is `region − DECK_EDGE` in each axis whatever the count.
- `T.ENCOUNTER_MIN` and `T.DRAGON_MIN` rise by `DECK_EDGE`, so the faces keep at least the height they have today.
- With 0 cards (Final Enemy), no edges show; only the Dragon Card does.

**Rationale**: The depth reads as more or fewer cards without moving the top card as the count changes. It reaches 8 edges at a full Deck of 16, and it agrees with the header count by construction (SC-004).

**Alternatives considered**:
- One edge per card. Rejected: 16 edges at 3 units each is 48 units of the left column.
- A stack that grows the top card's offset. Rejected: the face would move every draw.

## R3 — The zoom

**Decision**: A shared-element zoom between the top card and a face:

- **Zoom in**: the top card scales about the chosen tile's centre by `k = face_rect.size / tile_rect.size` and fades out over its last 40%. At the same time, the face starts at the tile's rect (scale `1/k`) and grows to its home, fading in over its first 40%. The stack's top-card area clips its children, so neither spills.
- **Zoom out**: the reverse.
- Both last 0.55 s (`TRANS_CUBIC`, `EASE_IN_OUT`).
- **Reduced motion**: a cross-fade of `2 × T.FAST`, with no scaling.
- Each tile has the face rect's aspect ratio, so `k` is uniform and nothing stretches.

**Rationale**:
- The settled face is today's `encounter_face`/`dragon_face`, so FR-006 holds exactly.
- The zoom is an illusion between two real widgets, not a magnified picture of the Region Card, so text stays sharp at both ends.
- The pattern already exists in the code: Godot `scale` tweens on `pivot_offset`, like the animator's `_pulse`.

**Alternatives considered**:
- A Region Card drawn at the full face's resolution and actually magnified. Rejected: its tiles would then have to contain the full face's badges and layout at 1/4 size, which can't be done.
- A `SubViewport` camera. Rejected: it adds a render target on phones for a 0.55 s effect.

## R4 — The Key Card peek

**Decision**: The peek is a `CardFace` of the Key Card at its current Level, drawn at the Hand's card width (`plan.positions[0].card.size`), centred horizontally behind the top card.

- It rises until its title band and Key Card strip (`g.band + g.strip`, about 19% of its height) clear the top card's top edge.
- It holds there, then slides back down.
- Timing: rises 0.25 s (`EASE_OUT`), holds 0.4 s, falls 0.2 s (`EASE_IN`).
- While zoomed out, the top card sits `peek_h − dip` below the region's top, where `peek_h` is the peek card's `band + strip` (from `card_face` geometry) and `dip = min(DECK_EDGE, peek_h / 2)`. As the Key Card rises, the top card and its edges dip by `dip`, so exactly the band and strip clear it. *Found in implementation*: leaving the whole `peek_h` above the card shrank the tiles to about 66 × 57 on the 1280 × 720 shapes, too small for two rows of 22-point figures. The dip keeps them at about 76 × 66. So the peek stays inside the region.
- The strip's Encounter icon, number and Hardship get the existing `_ring` highlight while it holds.
- **Reduced motion**: the peek fades in already raised, holds, and fades out.

**Rationale**:
- This is the rulebook's Key Card: the same card face the player knows from the Hand, read at the same strip.
- At Hand width, the peek is 45–70 units tall on every `MATRIX` shape, not ~130 at the Region Card's width.

**Alternatives considered**:
- A Key Card the Region Card's width. Rejected: its band and strip alone would take a third of the region on small shapes.
- Lifting only the strip. Rejected: the physical card lifts whole; the band shows it is a Mage Card.

The stack edges are drawn at the top card's footprint, not the Mage Card's. The Region Card is shown larger than the Mage Cards so its tiles can be read, which the physical game doesn't need to do.

## R5 — The Region Card face

**Decision**: `region_card.gd`, built on `face_frame.gd`'s stone, band and edge:

- **Band**: the `sigil_region` icon beside two lines: the Region's name (stepping down to fit), and under it "REGION n · DOE-R0x" in gold. The code is what pairs Regions 1–2 and 3–4 (FR-003).
- **Body**: two rows of four tiles, Enemies 1–4 above Journeys 1–4 (the printed card's order).
- **Each tile**:
  - the Encounter icon and its number (≥ 22, `T.LABEL_BOLD`);
  - the creature or landscape art, cropped as the face crops it (`EncounterFace.enemy_crop` / `Art.FULL`) and held still;
  - its headline stat: the HP icon and value for an Enemy, or the MP icon in its Ether and value for a Journey (22-point labels on a dark strip; a stat badge would be too small to hold a 22-point figure);
  - one icon for an Ability or Peril, if it has one.
- Tile aspect = face rect aspect (R3). Gaps are `T.XS`.

Only the current Region's side is drawn; the other side is not shown. The pairing shows in the turn (R6) and the code.

**Rationale**:
- The printed card's eight columns of figures can't be read at 400–548 wide. Spec Edge Cases accept that the Region Card need only read *as* a Region Card, with the chosen slot readable once enlarged.
- The art makes each slot recognisable, so the zoom visibly *arrives* at the creature the player then plays against.

**Alternatives considered**:
- Printing every stat in each tile. Rejected: text drops under 22 (the project's text floor) on 1280 × 720.
- The upside-down other Region dimmed. Rejected: it halves the tile height for something the player never reads.

## R6 — Turning to the next Region, and the Dragon Card

**Decision**: A new `turn_card` step:

- **Regions 1→2 and 3→4** (same card): the Region Card half-turns. It scales y 1→0, swaps to the new side, then 0→1, 0.5 s.
- **2→3** (other card): the old card slides down-right behind the stack and fades. The new card rises from the back, 0.5 s.
- **Region 4 → Final Battle**: as 2→3, with `dragon_card.gd` arriving.
- **Reduced motion**: a cross-fade.

The step plays after `gather_shuffle` and before `stage_banner`, so the banner announces the card already on top.

`dragon_card.gd` reuses `dragon_stats.gd` (already the "both ladders side by side" figure from the dragon choice) inside a `face_frame` band with the dragon's name and title. Its MP column and HP column are the two zoom targets.

**Rationale**: It mirrors the physical card's two-Regions-per-card turn (rulebook End of the Region, step 3) and reuses the figure players already learned when choosing their dragon.

## R7 — Holding the creature still until the zoom lands

**Decision**:
- `creature.gd` gains `var held := false`. `_apply_motion()` is still when `UI.reduced_motion or held`, and `_process` watches both.
- `face_frame.gd` gains `set_held(on)`, which passes it through.
- `DeckStack` holds the face's creature from the moment the face is shown hidden until `zoom_in` settles, then releases it (FR-005a).
- The tiles' creatures are always held; only the zoomed Encounter moves.

**Rationale**: The user's first choice. Eight more live shaders and particle systems on the Region Card cost frame time on phones for a card that is on screen under 2 s per Encounter. Animating all of them continuously was allowed as a fallback but isn't needed.

## R8 — Sequencing

**Decision**: `sequencer.gd` gains four steps. None of them change state; `apply()` passes them through.

| Step | Values | Anchor | Duration |
|---|---|---|---|
| `zoom_out` | `{}` | `deck` | 0.55 |
| `turn_card` | `{from, to}`: region numbers, or `"dragon"` | `deck` | 0.5 |
| `key_peek` | `{key, kind, index, hardship}` | `deck` | 0.85 (0.25 + 0.4 + 0.2) |
| `zoom_in` | `{target}`: `"enemy:2"`, `"journey:3"`, `"mp"`, `"hp"` | `deck` | 0.55 |

Where they go is set out in [contracts/reveal-sequence.md](contracts/reveal-sequence.md).

`key_peek` + `zoom_in` (1.4 s, within SC-003's 2 s) form the **reveal**. `_fit_time` shortens only the steps before the reveal to `T.SEQUENCE_MAX`. The reveal keeps its own timing, so a long Region change can't squeeze the peek's hold below readability.

The animator's existing rule still applies: any press during a sequence skips it and shows the final state (SC-003), so the reveal is skippable.

**Holding the view**:
- While a sequence with a `zoom_in` plays, `DeckStack.hold_card(true)` keeps the top card showing whatever `render` is called with. The `draw` step re-renders `_after`, which already carries the new Encounter.
- `zoom_in` releases it.
- `_finish()` (end or skip) releases it at once, so `screen.render(_after)` shows the zoomed face. How a sequence ends never depends on the animation code.

**Rationale**:
- It keeps the Sequencer pure and its replay test (`apply` on before == after) valid.
- The reveal is fed by `after.deck[0]` and `after`'s encounter, which the engine already decided.
- Undo never builds a sequence (upgrade undo and draft changes re-render only), so the reveal can't replay on undo (FR-012).

## R9 — Where cards travel

**Decision**: `play_screen.point()`:
- `"deck"` → the top of the stack, under the top card's top edge (the Key Card's place). Draws come from there (`hand.sync(..., arrive_from)`), as do `pay_time`'s and Divert's card backs.
- `"discard"`, `"trash"` → the back of the stack: its bottom-right edge.
- `header.bump()` still updates the counts, and the header keeps its Deck, Discard and Trash figures.

**Rationale**:
- This is FR-008 with no animator code change beyond the anchors. Every existing flight already goes through `screen.point()`.
- The header figures stay as the exact counts (spec Assumptions).

## R10 — Tests and tools

- **`tests/test_sequencer.gd`**:
  - every action's steps carry the reveal rules in the contract;
  - `key_peek.values.key == after.deck[0]` and its kind/index/hardship equal the engine's `encounter()`;
  - `zoom_in.target` matches `after`'s Encounter;
  - no reveal on `upgrade`, `soak` or `play` (unless the phase changes to `final_enemy`);
  - the reveal is excluded from `_fit_time`.
- **`tests/test_region_card.gd`** (new, model only):
  - `RegionCard.tiles(db, region)` returns 8 tiles in order with the right headline stats and effects;
  - `card_code` pairs 1–2 and 3–4;
  - `side(region)` alternates.
- **`tests/test_deck_stack.gd`** (new): `edges(count)` boundaries (0, 1, 2, 5, 15, 16), tile rect aspect, the zoom scale `k`, and the peek height is inside the region for every `MATRIX` shape's Hand card size.
- **`tests/test_layout_solver.gd`**: the raised `ENCOUNTER_MIN`/`DRAGON_MIN` still solve at every shape.
- **`tools/ui_check.gd`**: at every `MATRIX` shape, during seeded games:
  - after each settle, the stack's edges equal `edges(vs.piles.deck)` (SC-004);
  - the zoomed face's values equal today's (compare `encounter_face._shown` with `vs.encounter`) (SC-005);
  - mid-sequence, the peek and the top card stay inside the deck region and never cover the header, Hand or action row (SC-006);
  - tile text ≥ 22.
- **`tools/design_shots.gd`**: add shots of the zoomed-out Region Card, the peek at hold, a Region turn and the Dragon Card, at 1280 × 720 and one phone shape.

## R11 — Documents

- The header comments of `play_screen.gd` and `encounter_face.gd` describe the Deck.
- The README's play-screen description gains the Deck and Region Card.
- `specs/005-playfield-polish/contracts/playfield-layout.md` gets a superseded-in-part note for the left side.
