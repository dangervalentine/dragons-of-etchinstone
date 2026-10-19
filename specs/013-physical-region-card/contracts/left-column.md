# Contract: The Left Column

> The stack's edges are drawn per [specs/014 contracts/deck-pile.md](../../014-card-draw-key-reveal/contracts/deck-pile.md): rounded, card-stock card sides with a soft shadow.

This replaces `specs/012-deck-region-card/contracts/deck-stack.md`'s "Layers", "Per phase, settled" and "Space" sections, and retires `specs/011-card-contribution-highlights/contracts/left-box.md`. 012's Peek, Interaction and Anchors sections stand, except as noted.

## Region

- `layout_solver.solve` returns no `preview` region.
- `regions.encounter` spans the left column's whole body: from under the header to the bottom margin, `left_w` wide.
- `play_screen` fills it with `DeckStack` alone. `PreviewPanel`, `SoakMeter` and `XpPurse` are children of the `TableNote`.

## Layers, back to front

1. Card edges: `edges(vs.piles.deck)` outlines, as in 012, hung from whatever is on top (the card, the landed panel's face rect, or the note).
2. Key Card peek.
3. Top card: the Region Card, the Dragon Card, or none in setup.
4. Face: the landed `RegionPanel` with its reading strip, or `dragon_face`.
5. Note: `TableNote`, when a note is on show.

## Per phase, settled

| Phase | Top card | View | Face | Note |
|---|---|---|---|---|
| `setup` | none | — | none | `setup` |
| Region `challenge`, building | Region Card | `face` | the landed panel for `vs.zoom` | none |
| Region `challenge`, Fuse/Divert/Regroup | Region Card | `face` | as above | `mode` |
| Region `penalty` | Region Card | `face` | as above | `result` (until Cleanup's `zoom_out`) |
| Region `upgrade` | Region Card | `face` | as above | `upgrade` |
| `final_journey`, `final_enemy` | Dragon Card | `face` | `dragon_face` | none, or `mode` (Regroup) |
| `final_soak` | Dragon Card | `face` | `dragon_face` | `soak` |
| `won`, `lost` | as last | as last | as last | as last |

## The note

- **Size and shape**: the face rect, with the card outline and `StoneStyle("well")` of a face.
- **Content**: centred vertically when short and top-aligned when long. It clips nothing: `ui_check` asserts content height ≤ note height for every kind at every shape.
- **In**: from `x + T.DECK_EDGE` to rest, alpha 0 → 1, over `T.BASE`, `TRANS_CUBIC` ease out. In reduced motion: alpha only.
- **Out**: the reverse.
- **Swap**: when one kind replaces another, the content cross-fades in place, with no slide.
- **Hold**: a press-and-hold lifts it aside to 60% off the right and 0.25 alpha. Release returns it. It never emits an intent.
- **Refusal**: shows for `T.NOTE_HOLD` (2.4 s), then returns to the persistent note or none. The hand card shake and haptics are unchanged. `play_screen.toast` is removed.

## The sequence (additions to 012's `reveal-sequence.md`)

| Step | Note behaviour |
|---|---|
| `tally` | `result` note in (if not already), `preview.reveal()`, `play_tally(d)` |
| `verdict` | `reveal_verdict(d)` within the note |
| `zoom_out` | Any `result` or `upgrade` note out over the first third of `d`, then the zoom |
| `_finish` | The note is set from `after.note`, or keeps `result` if the after phase is `penalty` |

No Sequencer step is added. The animator drives the note from the existing steps, so `test_sequencer`'s invariants are untouched.

## Anchors (changes)

| Anchor | Point |
|---|---|
| `xp` | `xp_purse.point()` inside the note when the purse shows, else the note's centre |
| `preview` | The note's centre |

## Nothing else on the left

`ui_check` asserts that no visible Control in the left column lies outside `DeckStack`, and that no visible `Label` anywhere on the play screen contains `DOE-` or any of the removed tip strings.
