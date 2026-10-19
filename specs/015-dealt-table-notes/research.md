# Research: Notes Dealt On and Discarded Off Like Cards

All decisions below come from reading the code as it stands after 014:
- `ui/widgets/deck_stack.gd` (the note section, `_slide_note`, `_discard_note`, `_lift_note`, `turn_to`, `finish`, `_place`)
- `ui/widgets/table_note.gd`
- `ui/screens/play_screen.gd`, `ui/fx/animator.gd`, `ui/model/view_state.gd` (`note_for`)
- `tools/ui_check.gd` (`_check_note`), `tools/space_audit.gd`, `tools/design_shots.gd`
- `specs/013-physical-region-card/contracts/left-column.md` ("The note")

There are no open NEEDS CLARIFICATION items.

## How the note works today

- `DeckStack` owns **one** `TableNote` (`deck.note`). It can show several kinds at once in one column: `note_kinds(state_note, result_held)` returns `["result", <state kind>]`, so after a lost fight the one note shows the result with the Soak meter under it, then the result with the XP purse under it.
- `ViewState.note_for` gives the state's kind: `mode` (Fuse/Divert/Regroup), `soak`, `upgrade` or `setup`, or `null`.
- The result is held from the `tally` step (`show_result()`) until `zoom_out` (`clear_result(d * 0.3)`).
- A refusal replaces the note's content (`set_refusal`) for `T.NOTE_HOLD`, then the content comes back.
- **In/out**: `_slide_note` slides `T.DECK_EDGE` in from the right with alpha 0 → 1 over `T.BASE`, and the reverse.
- **Swap**: `_update_note` dims to 0.6 and back when the kinds change.
- **The exception**: `turn_to` calls `_discard_note(d)` when the first Region Card is laid. It throws the note to `x = -global_position.x - 1.2 w`, turns it to −14°, fades it over the last 30%, and turns off the Deck's `clip_contents` meanwhile.
- `PlayScreen` keeps `preview`, `soak_meter` and `xp_purse` as fixed references into `deck.note`. The animator uses them at `tally`, `verdict`, `gain_xp`, the XP spend and the Soak.

## R1 — One card per kind, kept in a pile

**Decision**:
- A new widget, `ui/widgets/note_pile.gd` (`NotePile`), replaces the single note. It holds an ordered list of `TableNote` cards, bottom to top. **Each card shows one kind**: `result`, `mode`, `setup`, `soak` or `upgrade`. `TableNote.show_kinds` already handles a one-kind array.
- A **refused move** is its own card, kept apart from the list and always on top (R5).
- A card is created when it is dealt and freed once its discard lands.
- Only cards whose kind is currently wanted are re-rendered from the new state. A card whose kind is no longer wanted (the Soak card once the Soak is done) keeps its last content, as a card on a table would.
- With the result on its own card, the XP card now shows the XP purse **with** its recap (`_without_recap` is no longer needed), since the result lies covered under it.

**Rationale**: the clarification asks for each piece of information to be a new card laid on top. One card per kind keeps `TableNote` almost unchanged and makes the pile a plain list.

**Alternatives rejected**:
- **One note, faked as a pile by drawing card slivers under it.** It cannot show the new card arriving over the old one with the old content still under it.
- **Moving the shared `preview`/`soak_meter`/`xp_purse` panels from card to card.** The result and a step card both need a `PreviewPanel`. Swapping parents mid-flight is fragile.
- **A new `DeckStack` inner class.** `deck_stack.gd` is already over 1,200 lines. The pile is its own concern, with its own motion and rules.

## R2 — Which cards to deal and which to discard

**Decision**: a pure static `NotePile.plan(pile: Array, wanted: Array) -> Dictionary` returns `{"throw": int, "deal": Array}`.
- `pile` is the kinds lying down, bottom to top, without the refusal.
- `wanted` is `DeckStack.note_kinds(vs.note, result_held)`, unchanged.
- `throw` is how many cards come off the top, as one discard.
- `deal` is the kinds to lay on top, in order.

The rules:
1. If `wanted` is empty, throw the whole pile (the interaction is complete).
2. Otherwise, if the last wanted kind is already in the pile below the top, throw every card above it. This is an undo back to an earlier step.
3. Then deal each wanted kind that is not in the pile, in `wanted` order.

| pile | wanted | throw | deal | When |
|---|---|---|---|---|
| `[]` | `["result"]` | 0 | `result` | the tally |
| `["result"]` | `["result","soak"]` | 0 | `soak` | damage to Soak |
| `["result","soak"]` | `["result","upgrade"]` | 0 | `upgrade` | the Soak done, XP to spend |
| `["result","soak","upgrade"]` | `[]` | 3 | — | zoom out to the next Encounter |
| `["result","soak","upgrade"]` | `["result","soak"]` | 1 | — | undo back to the Soak |
| `["mode"]` | `[]` | 1 | — | a Fuse cancelled or done |
| `[]` | `["result","soak"]` | 0 | `result`, `soak` | a skip straight to the after state |

**Rationale**: "the interaction is complete" is exactly when `wanted` becomes empty, the moment the last note is taken off today (spec Assumptions). It is a pure function, so it is tested headless like `note_kinds`.

**Alternatives rejected**: tracking an explicit "interaction" id from the engine. The view state already says when nothing is wanted, and no rules change is needed.

## R3 — An unclipped layer for cards in flight

**Today**: `DeckStack.clip_contents = true`, and `_discard_note` turns it off for the throw. Clipping is off for the whole Deck meanwhile, which is harmless at setup but not during `zoom_out`, when the result is now thrown while the card zooms.

**Decision**:
- The Deck's clip moves from `DeckStack` itself to a new child, `_table`, which holds `_edges`, `_peek_clip`, `_tops` and `_faces`.
- The `NotePile` is a sibling of `_table`, after it, and unclipped. A card can travel past the Deck's edge (FR-005) without anything else spilling out.
- `DeckStack.clip_contents` becomes `false` and is never toggled again.
- The left column's region (`_regions.encounter`) does not clip, so nothing else changes.
- The Hand is added after the left column in `PlayScreen`, but notes enter and leave on the left, away from it.

**Alternatives rejected**:
- **`top_level` on a card in flight.** Whether the parent's clip still applies to it is not something to rely on.
- **A layer on `PlayScreen`.** It splits the Deck's own visuals across two owners.

## R4 — The deal and the discard

**Decision**: both are one shared shape, mirrored.
- **Off-table point**: `x = -deck.global_position.x - 1.2 w` in the pile's coordinates, the same `y` as the card's rest. This is the setup discard's point today, so the card starts and ends fully off screen.
- **Deal**: from the off-table point at `-T.NOTE_TURN` (14°) to the rest at 0°, over `T.NOTE_DEAL` (0.35 s), `TRANS_CUBIC`, `EASE_OUT` (it slows as it lands). Alpha is 1 throughout.
- **Discard**: from where it lies to the off-table point, turning by `-T.NOTE_TURN`, over `T.NOTE_DISCARD` (0.35 s), `TRANS_CUBIC`, `EASE_IN` (it speeds up as it is thrown). Alpha is 1 throughout. The card hides and is freed once it lands.
- **Pivot**: the card's centre.
- **Throwing the pile**: every card thrown together leaves on the same path. Each card below the top is delayed by `T.NOTE_PILE_STAGGER` (0.04 s), so the pile fans a little but reads as one throw.
- **The setup throw**: `turn_to` keeps its trigger, but calls `pile.throw_all()`, so it is the same motion as every other discard (FR-006, SC-003). The Region Card's lay keeps its own `d`.
- **The zoom out**: `clear_result` keeps its trigger. Rule 1 throws the pile at the start of `zoom_out`, at `T.NOTE_DISCARD`, so it is never shrunk with the card.

**Rationale**:
- 0.35 s matches `T.MOVE`. It covers a longer path than the old 24-unit slide at about the same time, so no waiting is added (SC-005).
- The fade at the end of the old setup throw goes, because FR-002 asks for a fully opaque card in flight. The card is off screen by the end anyway.

## R5 — The pile on the table, and a refused move

**Decision**:
- **The tilt**: the top card lies square. Each card under it keeps a small fixed tilt by depth, `T.NOTE_TILT = [0.0, -1.2, 0.9, -0.6]` degrees (deeper cards repeat the last), about its centre. Its corners show a sliver past the top card (FR-007a).
  - At the Deck's smallest face (about 340 × 476), 1.2° moves a corner by about 5 units, within the `T.DECK_EDGE` margin.
  - When a new card lands, the one it covers eases into its tilt over `T.FAST`.
- **The shadow**: each card draws a soft shadow under it, using the same layers as the Deck's pile (`DeckStack.SHADOW`, moved to `T.CARD_SHADOW`) (FR-002).
- `TableNote` stops clipping itself, so the shadow can fall outside its rect. Its content goes in a clipped child `_body`.
- **A refused move**:
  - `show_refusal(text)` deals a refusal card on top of whatever lies there and starts `T.NOTE_HOLD`.
  - A second refusal while one lies there updates its text and restarts the timer. No second card is dealt (FR-009).
  - `clear_refusal()` throws that card alone, uncovering the pile under it.
  - The refusal card is never part of `plan()`'s `pile`, and is never thrown with the pile unless the pile is thrown while it lies on top. In that case they leave together.

## R6 — The panels the screen and the animator reach

**Today**: `play_screen.preview`, `.soak_meter` and `.xp_purse` are fixed references into `deck.note`.

**Decision**:
- They become read-only properties on `PlayScreen` (`get:` accessors) that ask `deck.panel(name)`:
  - `"preview"`: the result card's `PreviewPanel`, or else the step card's (`mode`/`setup`);
  - `"soak_meter"`: the Soak card's;
  - `"xp_purse"`: the XP card's.
- When there is no such card, `deck.panel` returns a detached, hidden spare of that panel, owned by `NotePile`. Every existing `screen.X.visible` check keeps working, and no caller changes.
- `deck.note_point()` is the top card's centre (refusal excluded). `"xp"` stays `xp_purse.point()` when it shows.

## R7 — Holding, finishing, resizing and reduced motion

- **Hold**: a press-and-hold on the top card lifts the whole pile aside, 60% of a width to the right and alpha 0.25. Release lays it back down, as today but for every card (FR-010). The intent is never emitted.
- **`DeckStack.finish()`** calls `pile.finish()`. Every card in flight lands at once: dealt cards at rest, thrown cards freed. Every lying card returns to its rest and tilt, scale 1, alpha 1.
- **Resize**: `DeckStack._place()` calls `pile.lay_out(_note_rect())`. A resize finishes the pile's motion first (FR-012).
- **Going to the background** already calls `animator.skip()` → `_finish()` → `deck.finish()`.
- **Reduced motion** (FR-011):
  - a deal is the card at rest, alpha 0 → 1 over `T.FAST`;
  - a discard is alpha 1 → 0 where it lies, over `T.FAST`;
  - the pile's tilt is kept, since it is a still pose, not motion.

## R8 — Tests and tools

- `tests/test_deck_stack.gd`: `note_kinds` is unchanged. New tests for `NotePile.plan` (the table in R2, plus refusal exclusion) and `NotePile.tilt(depth)`.
- New `tests/test_note_pile.gd`, headless:
  - dealing, throwing and `finish()` give the expected card count, kinds and rest rects;
  - the refusal is single;
  - `panel()` returns the hidden spare when absent.
- `tools/ui_check.gd` `_check_note`:
  - asserts the pile's top kinds match `wanted` and that only the refusal can lie above them;
  - checks every lying card is within the left region, grown by the tilt allowance;
  - checks every card's content fits;
  - checks that after `_settle()` no card is in flight.
  - The Boost refusal check reads `deck.pile.refusal_text()`.
  - A new check at one shape follows a lost fight and asserts the pile goes 1 → 2 → 3 → 0 cards across tally, Soak, XP and zoom out.
- `tools/space_audit.gd` reads the result card via `deck.pile.card("result")`.
- `tools/design_shots.gd`: a `notes` shot with three cards piled (the result, the Soak, the XP).

## R9 — Documents

`specs/013-physical-region-card/contracts/left-column.md`, "The note": a note at its head saying In, Out, Swap and Refusal are superseded by `specs/015-dealt-table-notes/contracts/note-pile.md`.
