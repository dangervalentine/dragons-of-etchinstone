# Contract: The Note Pile

This replaces "In", "Out", "Swap", "Hold" and "Refusal" in `specs/013-physical-region-card/contracts/left-column.md`, "The note". Size, shape, content layout and the sequence triggers there still hold.

## What lies on the Deck

- One card per kind: `result`, `mode`, `setup`, `soak` or `upgrade`, plus at most one refusal card on top.
- The kinds wanted are `DeckStack.note_kinds(vs.note, result_held)`, unchanged.
- What is dealt and what is thrown is decided by `NotePile.plan` alone:

| Rule | Condition | Effect |
|---|---|---|
| 1 | `wanted` is empty | Throw the whole pile, plus the refusal card if one lies on it |
| 2 | The last wanted kind lies below the top | Throw every card above it |
| 3 | Always, after 1 and 2 | Deal each wanted kind not lying, in `wanted` order |

A lying card whose kind is no longer wanted keeps its last content and stays until rule 1 or 2 throws it.

## Motion

| | Normal | Reduced motion |
|---|---|---|
| **Deal** | From `off_table(rest)` at −`NOTE_TURN`° to rest at the top's tilt (0°), over `NOTE_DEAL`, cubic ease out, alpha 1 | At rest, alpha 0 → 1 over `T.FAST` |
| **Covered** | The card beneath eases to `tilt(depth)` over `T.FAST` | Set at once |
| **Discard** | From where it lies to `off_table(rest)`, turning by −`NOTE_TURN`°, over `NOTE_DISCARD`, cubic ease in, alpha 1. Then freed | Alpha 1 → 0 where it lies over `T.FAST`. Then freed |
| **Pile thrown** | As Discard, all cards together, each below the top `NOTE_PILE_STAGGER` later | As Discard, all at once |
| **Hold** | The whole pile to `rest + (0.6 w, 0)` at alpha 0.25 over `T.FAST`. Release returns it | Alpha only |

- A card in flight is never clipped by the Deck: `NotePile` sits outside `_table`.
- A card in flight is never partly transparent outside reduced motion.
- A new deal during a throw starts a new pile on the bare Deck. The thrown cards keep flying.

## Triggers (unchanged in timing)

| Moment | Call | Usual effect |
|---|---|---|
| `tally` step | `deck.show_result()` | Deal `result` |
| `render(after)` with Soak to take | `_update_note` | Deal `soak` on the result |
| `render(after)` in `upgrade` | `_update_note` | Deal `upgrade` on top |
| `zoom_out` | `clear_result(d * 0.3)` | Rule 1: throw the pile |
| First Region Card laid (`turn_to`, `was == null`) | `pile.throw_all` | Throw the `setup` card |
| Fuse/Divert/Regroup begins or ends | `_update_note` | Deal `mode`, or throw it (rule 1) |
| A refused move | `deck.show_refusal(text)` | Deal the refusal card, or restart its `NOTE_HOLD` |
| `NOTE_HOLD` passes, or any intent | `deck.clear_refusal()` | Throw the refusal card alone |
| Undo to an earlier step | `_update_note` | Rule 2 throws the cards above it |

## Settling

- `DeckStack.finish()` → `NotePile.finish()`: every dealt card is at rest, every thrown card is freed, and the pile is laid down (not lifted).
- A change of `rest` (resize) finishes first, then lays every card out at the new rest.
- At rest, `ui_check` holds:
  - `pile.kinds()` ends with the wanted kinds, as `plan()` gives;
  - the refusal card lies only while `refusal_text() != ""`;
  - every lying card is within the left region (grown by the tilt allowance);
  - every card's content fits it.

## Anchors

| Anchor | Point |
|---|---|
| `preview` | The top card's centre |
| `xp` | `xp_purse.point()` on the XP card when it shows, else the top card's centre |
