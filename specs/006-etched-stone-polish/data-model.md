# Data Model: Etched Stone and Ether Rifts

Presentation-only entities. Nothing here is saved, and the engine's state is
untouched. Each entity is either derived from the view state (`ui/model/view_state.gd`)
or a fixed table.

## Zone

A place on a screen with one job, drawn as a well cut into the stone.

| Field | Type | Notes |
|---|---|---|
| `key` | String | Play screen: `header`, `encounter`, `preview`, `rail`, `hand` (measured as the panel around the cards), `actions`, `commit`. Other screens: `slab` (an overlay or screen body), `lintel` (title or banner band), `tile` (a choice) |
| `rect` | Rect2 | From `layout_solver.gd` (play screen) or the screen's own layout |
| `style` | String | `well` (zone), `plinth` (button), `slab` (overlay), `inset` (chip), `lintel` (band). Selects the `StoneStyle` depth and bevel |
| `depth` | float 0–1 | How deeply it reads as cut. `hand` and `encounter` are deepest, `header` shallowest. Active adds depth |
| `glow` | float 0–1 | Rim light. 1 for the active zone, 0 otherwise; tweened, or set instantly under reduced motion |
| `glow_colour` | Color | `T.FOCUS` for the active zone; an Ether's lit shade during a response |

**Rules**
- On the play screen, exactly one zone has `glow = 1` at rest: the one named by
  `vs.input_region` (D9), which is `hand` or `commit`.
- A zone's text must keep contrast against its brightest fill plus maximum glow
  (D5; `test_stone_contrast.gd`).
- Zone rects are passed to the backdrop (≤ 8) so the rift seams fade beneath them.

## RoleToken (role rail)

One token per role per Action Set, plus the Boost-to toggle. Shaped from the view
state's existing `sets`, `active_slot`, `mode` and `played`. It is pure and tested
in `test_role_rail.gd`.

| Field | Type | Notes |
|---|---|---|
| `set` | int | 0 or 1 (Final Battle) |
| `role` | String | `spell`, `element`, `boost`, or `reserve` (recap only) |
| `state` | String | `empty`, `next` (the active slot), `filled`, `played`, `kept` (Reserve stays), `discarded` |
| `card_id` | String or null | Placed or played card |
| `contribution` | Array | What to draw: Spell `[basic, enhanced, element]`, Element `[element, initiative]`, Boost `[boost]`. Values come from the card's current Level, as in `slot_row._contribution` today |
| `ether` | String or null | Tint for a filled token |
| `tap` | Dictionary or null | The intent a tap sends: `select_slot {set, role}` when empty, `take_back {id}` when filled, `inspect {id}` in the recap when the token has a card, else null |
| `tooltip` | String | Role and set, plus the card's name when filled |

**Boost-to toggle**: `{set, target: "attack" | "initiative", tap: toggle_boost_to}`.
It is present when `sets[set].show_boost_to` is set.

**State transitions** (per token, while building):
`empty → next` (selected or next in order) → `filled` (card placed) → `empty` (take
back). After commit, the rail switches to the recap: `played` or `discarded` per
role, and `kept` or `discarded` for the Reserve. While the recap shows, each played
card in the Hand carries `played_role` (`[set, role]`), drawn as a muted "played as"
ribbon, so the role-to-card link stays visible without a name in the token.

**Rules**
- Never shows a card's name as visible text (FR-002); the name appears only in the
  tooltip.
- The rail is exactly `TAP_MIN` tall; tokens are at least `TAP_MIN` on their shorter
  side.
- The rail is absent (height 0) when `layout_solver.slot_rows(vs) == 0`, as the band
  is today.

## RiftLight

The Ether light glowing through the stone. One per screen, held by `rift_layer.gd`
and fed to `backdrop.gdshader`.

| Field | Type | Notes |
|---|---|---|
| `ether` | String or null | The current Encounter's Ether; the dragon's in the Final Battle; null means neutral |
| `tint` | Color | `T.ether_shade(ether, "lit")`, or the neutral cold violet |
| `behaviour` | int | Per-Ether shimmer character (D6): fire flicker, water swell, lightning jolt, shadow pinprick; neutral is a plain shimmer |
| `source` | Vector2 | The bloom point: the Encounter frame's centre on play, the dragon tiles on the title, the slab's top on overlays |
| `intensity` | float | Base 1. Responses push it briefly up (win, Play) or down (loss) |
| `motion` | bool | False under reduced motion: shimmer frozen at its mean, no motes |

**Transitions**: a change of `ether` tweens `tint` over `T.REVEAL`; it never snaps.

## BoardResponse

What the board does for each game or draft event. A pure table in
`ui/model/board_response.gd`, tested in `test_board_responses.gd`.

| Field | Type | Notes |
|---|---|---|
| `event` | String | `place`, `take_back`, `fuse`, `divert`, `regroup`, `play`, `hit_enemy`, `take_damage`, `soak`, `upgrade`, `encounter_won`, `encounter_lost` |
| `target` | String | A zone key, `rail_token`, `seams` or `rift` |
| `colour` | String | `ether` (of the card or Encounter), `focus`, `gold`, `bad` or `neutral` |
| `motion` | Dictionary | The animated form: kind (`flare`, `surge`, `shudder`, `burst`, `sweep`, `dim`), duration within `T.FAST`…`T.REVEAL` |
| `still` | Dictionary | The reduced-motion form: a held tint or rim for `T.BASE`, with no movement |

**Rules**
- Every event the animator and draft can produce has exactly one entry, with both
  `motion` and `still` (FR-015, FR-016).
- During an animator sequence, responses queue behind the sequence's own steps;
  they never cover the card flight.

## LoreFrame

The in-world identity a screen takes (FR-012). A fixed table; see
[contracts/screens-and-lore.md](contracts/screens-and-lore.md).

| Field | Type | Notes |
|---|---|---|
| `screen` | String | `title`, `rules`, `play`, `banner`, `ending`, `rulebook`, `glossary`, `inspect`, `menu`, `confirm`, `size_notice` |
| `frame` | String | `tear`, `proclamation`, `board`, `lintel`, `inscribed_slab`, `scroll`, `slab` |
| `ornaments` | Array | Ornament icons used (D10) |
| `rift_source` | String | Where that screen's light comes from |
| `must_keep` | Array | Every control and value shown today (FR-020) |
