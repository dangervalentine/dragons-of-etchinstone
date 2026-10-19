# Data Model: The Deck and Region Card on the Playfield

All of this is view data built from the engine's existing state. The engine (`engine/game.gd`) is unchanged: `deck[0]` is already the Key Card, and `encounter()` already reads it.

## View state additions (`ui/model/view_state.gd` → `build`)

| Field | Type | Present | Meaning |
|---|---|---|---|
| `top_card` | Dictionary or null | Always (null in setup) | The card on top of the Deck: a Region Card model or a Dragon Card model |
| `key_face` | Dictionary or null | `challenge`, `poison`, `penalty`, `upgrade` in a Region | The Key Card's full card model (`_card(game, draft, db, id, vs)`) for the peek. In `challenge` and `poison` it is `game.deck[0]`: `poison` follows the Cleanup draw, so the new Key Card is already on top. In `penalty`/`upgrade` it is the card that *was* the Key (`game.faced.key`) |
| `zoom` | String | Always | Where the settled view rests: `"enemy:N"`, `"journey:N"`, `"mp"`, `"hp"`, or `""` (setup: no top card) |

`piles.deck` already gives the Deck count. `encounter` is unchanged and is still what the settled face draws.

### `zoom` rules

| Phase | `zoom` |
|---|---|
| `setup` | `""` |
| `challenge`, `poison` (Region) | `"<kind>:<index>"` of `game.encounter()`: the Encounter the current Key Card names |
| `penalty`, `upgrade` (Region) | `"<kind>:<index>"` of `game.faced.encounter`: the Encounter just played |
| `final_journey` | `"mp"` |
| `final_enemy`, `final_soak` | `"hp"` |
| `won` | `"hp"`: the game is only won by beating the Final Enemy |
| `lost` | `"mp"` if `extra.lost_at == "the Final Journey"`, else `"hp"` |

`build` keeps no history, so the `lost` rule reads `extra.lost_at`, which `ui/main.gd` already passes (`_lost_at`, set when the game is lost). The engine only loses in the Final Battle (`engine/game.gd` sets `phase = "lost"` only on the Final Journey and Final Enemy), so no Region case is needed.

## Region Card model (`ui/model/view_state.gd` → static `region_card_model(db, region)`)

Built in the view state, the only UI file that reads the game; `region_card.gd` only draws it.

```text
{
  kind: "region",
  region: 1..4,
  name: "Jade Mountains",
  code: "DOE-R01" | "DOE-R02",   # from cards.json regions[].card
  side: 0 | 1,                    # (region - 1) % 2: which side of the physical card
  tiles: [Tile × 8]               # Enemies 1–4, then Journeys 1–4
}
```

### Tile

```text
{
  key: "enemy:2",                 # matches `zoom` and the zoom_in step's target
  kind: "enemy" | "journey",
  index: 1..4,
  title: Art.encounter_name(region, kind, index),
  art: Art.encounter(region, kind, index),
  element: attack.element | mp.element,
  stat: {icon: "hp" | "mp_badge", value: int, element},
  effect: ability | peril | null  # Hardships belong to the Key Card, not the tile
}
```

**Validation**:
- There are always exactly 8 tiles, in the order above.
- `code` is equal for Regions 1 and 2 and for Regions 3 and 4, and the two codes differ.
- `side` alternates between 0 and 1.

## Dragon Card model (`ui/model/view_state.gd` → static `dragon_card_model(game.dragon)`)

```text
{
  kind: "dragon",
  id, name, title, element,
  code: dragon.card,              # DOE-D01 / DOE-D02
  targets: ["mp", "hp"]           # the zoomable columns, MP Tiers then HP Tiers
}
```

## Deck stack state (`ui/widgets/deck_stack.gd`)

| State | Meaning |
|---|---|
| `count` | Deck count shown; edges = `edges(count)` |
| `view` | `"card"` (zoomed out: whole top card, room for the peek) or `"face"` (zoomed in on `zoom`) |
| `held` | While true, `render()` updates the count and the face's contents but leaves `view` as it is. The animator sets it for a sequence with a reveal (research R8) |
| `peek` | `"down"`, `"rising"`, `"up"`, `"falling"`; only `"down"` when settled |

### Transitions

```text
render(vs), not held        → view = "face" if vs.zoom != "" else "card"; top card = vs.top_card; face released (creature moves)
render(vs), held            → count and face contents update; view and the shown top card stay until turn_to/zoom_in
show_card()                 → view = "card" at once, no tween (start of game)
hold_card(true)             → held; if view == "face", zoom_out() must be called to go to "card"
set_count(n)                → the drawn count becomes n (gather_shuffle: the reshuffled Deck)
zoom_out()                  → view: face → card                (creature held)
turn_to(top_card)           → top card replaced/turned          (view must be "card")
peek(key_face)              → down → rising → up → falling → down
zoom_in(target)             → view: card → face; held = false; creature released when it lands
finish() (skip / end)       → stop tweens; held = false; view from vs.zoom; peek down
```

### Derived geometry (pure, testable)

- `edges(count) = clampi(ceili(count / 2.0), 1, 8)` for count ≥ 1, and `0` for count 0.
- `dip(peek_h) = min(DECK_EDGE, peek_h / 2)`: how far the Deck dips while the Key Card rises.
- `card_rect(region, view, peek_h)`:
  - `"face"`: `Rect2(0, 0, w − DECK_EDGE, h − DECK_EDGE)`.
  - `"card"`: the same rect moved down by `peek_h − dip(peek_h)` and scaled to fit, keeping its aspect ratio. The Key Card rises into that room while the Deck dips by the rest, so its band and strip clear the top card while the Region Card stays as large as it can (a full `peek_h` of room left tiles about 66 × 57, too small for two rows of 22-point figures).
- `tile_rect(card_rect, key)`: the tile's rect inside the Region Card body. Its aspect equals the face rect's.
- `zoom_scale(face_rect, tile_rect) = face_rect.size.x / tile_rect.size.x`. This is uniform because the aspects match.
- `peek_h(card_size) = round(0.155 h) + round(0.09 h)`: the band and strip of a `CardFace` of that size.
