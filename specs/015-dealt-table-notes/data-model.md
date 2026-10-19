# Data Model: Notes Dealt On and Discarded Off Like Cards

No engine or `ViewState` change. `ViewState.note_for` and `DeckStack.note_kinds` stay as they are. Everything below is view-side.

## Tokens (`ui/theme/tokens.gd`)

| Token | Value | Meaning |
|---|---|---|
| `NOTE_DEAL` | 0.35 | A note's flight in from the left, to rest |
| `NOTE_DISCARD` | 0.35 | A note's flight off to the left |
| `NOTE_TURN` | 14.0 | Degrees a card is turned at the off-table point |
| `NOTE_TILT` | `[0.0, -1.2, 0.9, -0.6]` | Degrees each card lies tilted, by depth from the top; deeper cards repeat the last |
| `NOTE_PILE_STAGGER` | 0.04 | The delay of each card below the top when the pile is thrown |
| `CARD_SHADOW` | `[[2.0, 0.10], [4.0, 0.07], [6.0, 0.05], [8.0, 0.03]]` | The soft shadow's layers (moved from `DeckStack.SHADOW`) |

`NOTE_HOLD` (2.4) and `NOTE_ROOMY_H` are unchanged.

## NotePile (`ui/widgets/note_pile.gd`, new)

A `Control` that is a child of `DeckStack`, after `_table`. It does not clip and fills the Deck.

| Field | Type | Meaning |
|---|---|---|
| `cards` | `Array[TableNote]` | The cards lying down, bottom to top, refusal excluded |
| `refusal_card` | `TableNote` or `null` | A refused move's card, always on top while it lies |
| `leaving` | `Array[TableNote]` | Cards being thrown, freed when they land |
| `rest` | `Rect2` | Where a card lies: `DeckStack._note_rect()` |
| `lifted` | `bool` | Whether a press holds the pile aside |
| `_spares` | `Dictionary` | Detached, hidden `PreviewPanel`, `SoakMeter` and `XpPurse` for `panel()` |

### Pure functions (static)

- `plan(pile: Array, wanted: Array) -> {"throw": int, "deal": Array}`: research R2.
- `tilt(depth: int) -> float`: radians, from `T.NOTE_TILT`.
- `off_table(rest: Rect2, deck_global_x: float) -> Vector2`: `Vector2(-deck_global_x - 1.2 * rest.size.x, rest.position.y)`.

### Methods

- `sync(wanted: Array, vs: Dictionary, result_vs: Dictionary, animate: bool)`: applies `plan()`. It throws, then deals. It re-renders every lying card whose kind is in `wanted`.
- `deal(kind: String, vs, animate)`: a new `TableNote` with `[kind]`, laid on top.
- `throw_top(n: int, animate)`: throws the top `n` lying cards as one discard (the refusal card too, if it lies above them).
- `throw_all(animate)`: `throw_top(cards.size())`.
- `show_refusal(text)`: deals the refusal card or updates it in place. `clear_refusal()` throws only the refusal card.
- `lift(on: bool)`: the whole pile aside or back.
- `lay_out(rest: Rect2)`: sets every card's size and lying pose. It finishes motion first if `rest` changed.
- `finish()`: lands every flight at once.
- `top() -> TableNote` or `null`: the top lying card, refusal excluded.
- `card(kind) -> TableNote` or `null`.
- `panel(name) -> Control`: research R6.
- `is_showing() -> bool`: any lying card, or the refusal.
- `kinds() -> Array`: the lying cards' kinds, bottom to top.
- `refusal_text() -> String`.

### A card's states

```text
            deal               (lands)
  (none) ─────────► dealing ───────────► lying ◄──┐
                                           │      │ lift(false)
                                  lift(true)▼     │
                                         lifted ──┘
                                           │ throw
                                           ▼
                                        leaving ──(lands)──► freed
```

`finish()` takes `dealing` to `lying` and `leaving` to `freed` at once.

## DeckStack changes (`ui/widgets/deck_stack.gd`)

- **New `_table`**: a clipped child holding `_edges`, `_peek_clip`, `_tops` and `_faces`. `clip_contents` on `DeckStack` itself is `false`.
- **The note**:
  - `note` (`TableNote`) is replaced by `pile` (`NotePile`).
  - `note_on` becomes a getter: `pile.is_showing()`.
  - `_slide_note`, `_discard_note`, `_note_to`, `_lift_note` and `_note_tween` are removed.
  - `_update_note`, `show_result`, `clear_result`, `show_refusal` and `clear_refusal` keep their triggers and delegate to `pile.sync`, `pile.show_refusal` and `pile.clear_refusal`.
- **`face_node()`**: `pile.top()` when the pile shows, else as today.
- **`note_point()`**: the centre of `pile.top()`, or else of `_note_rect()`.
- **`panel(name)`**: `pile.panel(name)`.
- **`turn_to`**: `pile.throw_all(true)` in place of `_discard_note(d)`.
- **`finish()`**: also `pile.finish()`.
- **`_place()`**: `pile.lay_out(_note_rect())`.
- **The constant `SHADOW`** moves to `T.CARD_SHADOW`.

## TableNote changes (`ui/widgets/table_note.gd`)

- It does not clip itself. A child `_body` clips `_box` and `_creature` to the card.
- `_draw()` draws `T.CARD_SHADOW` under the rounded face.
- The XP purse renders with its recap: `_without_recap` is removed, since a card never holds the result and the XP together.
- `set_refusal` stays. A refusal card holds only its text.

## PlayScreen changes (`ui/screens/play_screen.gd`)

`preview`, `soak_meter` and `xp_purse` become read-only properties returning `deck.panel("preview")`, `deck.panel("soak_meter")` and `deck.panel("xp_purse")`.
