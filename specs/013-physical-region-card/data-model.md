# Data Model: The Left Side as the Physical Region Card and Deck

These are view-side models only. `engine/` and `data/cards.json` are unchanged.

## Region Card model (`view_state.region_card_model(db, region)`)

```text
{
  kind: "region",
  region: int,               # 1–4
  name: String,              # "Jade Mountains"
  pair: String,              # which physical card (was `code`); never rendered (R8)
  side: int,                 # (region - 1) % 2
  panels: [Panel × 8]        # Enemies 1–4, then Journeys 1–4 (was `tiles`)
}
```

The `code` field is removed. `turn_to` compares `pair` to choose between a turn of the same card and a swap for the other card.

## Panel (one Encounter on the card)

```text
{
  key: "enemy:1" … "journey:4",
  kind: "enemy" | "journey",
  index: int,                # 1–4: the Encounter number, from position
  title: String,             # the Encounter's name (reading strip only)
  art: String,               # creature or landscape art name, may be ""
  element: String,           # the panel's Ether: Attack's for an Enemy, MP's for a Journey
  xp: int,                   # XP Reward, in the star
  effect: String | null,     # Ability (Enemy) or Peril (Journey), a Glossary id
  enemy:   { hp, initiative, attack: {value, element}, armor: [{value, element}, …] },
  journey: { mp: {value, element}, time_penalty }
}
```

Only the block matching `kind` is present.

**Validation** (`test_view_state`, `test_region_card`):
- Every value equals `db.encounter(region, kind, index)`.
- `xp` matches the data.
- `effect` is null when the data has none.

## Landed face (`vs.encounter`, unchanged source)

The landed `RegionPanel` renders the Panel for `vs.zoom`, plus the Key Card's `hardship` from `vs.encounter.effects` (data-model unchanged since 012).

The reading strip reads:
- `vs.encounter.title` and `index`;
- the Hardship from `vs.encounter.effects`;
- the panel's `effect`.

## Dragon Card model (`view_state.dragon_card_model(dragon)`)

`code` is removed. Everything else is unchanged: `{kind: "dragon", id, name, title, element, dragon, art, targets: ["mp", "hp"]}`.

## Note (`vs.note`, new)

```text
vs.note = null | { kind: "setup" | "mode" | "upgrade" | "soak" }
```

`view_state.note_for(game, draft, vs)` derives `vs.note` from the state:

| Condition (first match) | kind |
|---|---|
| `draft.mode != "none"` | `mode` |
| `vs.soak != null` | `soak` |
| `phase == "upgrade"` | `upgrade` |
| `phase == "setup"` | `setup` |
| otherwise | null |

Two kinds are transient and are not in the view state:

- `result`: set by the animator at `tally` and cleared at the next `zoom_out`, or when a persistent note (such as `upgrade`) takes over at `_finish`.
- `refusal`: set by `play_screen.refuse(text)`. It lasts for `T.NOTE_HOLD`, or until the next intent.

`DeckStack` holds the note on show, in this order:
`refusal` > `mode` > `result` > `soak` > `upgrade` > `setup`.

## DeckStack state (additions to 012's)

| Field | Meaning |
|---|---|
| `landed: RegionPanel` | The full-size panel shown when `view == "face"` in a Region |
| `strip: Control` | The reading strip under or beside `landed` |
| `note: TableNote` | The note layer, above everything but the peek |
| `note_kind: String` | The kind on show, or `""` |
| `lifted: bool` | True while a press holds the note aside |

**View transitions** (012's are kept; changes in bold):

```text
card --zoom_in(key)--> face   [card scales about the panel to panel_rect; **landed panel swaps in**]
face --zoom_out-->     card   [**landed hides; card appears scaled at panel_rect** and shrinks]
any  --note(kind)-->   any    [note slides in over the stack; the view underneath is unchanged]
note --clear-->        —      [note slides off]
```

## Pure geometry (static, tested headless)

| Function | Returns |
|---|---|
| `RegionCard.card_size(width)` | `Vector2(width, width * 7/5)` |
| `RegionCard.panel_rect(card_size, key)` | The printed rect of a panel (R1 `LAYOUT`) |
| `RegionPanel.parts(size, kind, armor_count)` | Rects for art, badges, effect disc, XP star and number marker |
| `DeckStack.panel_fit(face_rect, aspect)` | `{panel: Rect2, strip: Rect2}`: the panel fitted with the strip below it, or beside it when the face is wide |
| `DeckStack.zoom_scale(panel_fit, panel_on_card)` | The scale taking the card's panel to the landed rect |
| `DeckStack.card_rect(...)` | As in 012, now with the card's 5 : 7 aspect instead of the face's |
| `DragonCard.target_rect(card_size, "mp" or "hp")` | The printed tier column rects |
