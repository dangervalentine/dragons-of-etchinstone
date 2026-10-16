# Data Model: Raised Stone and the Math in Plain Sight (revision 2)

Presentation entities, plus the reporting the engine adds. Nothing is saved. The
engine's existing result fields and the game state are unchanged.

## Term (engine, reporting only)

One line of the math, produced by the rules functions beside the totals they already
compute (research R1).

| Field | Type | Notes |
|---|---|---|
| `sum` | String | Which sum it belongs to: `attack`, `initiative`, `move`, `target` (HP or MP, when it is itself a sum), `damage`, `time` |
| `label` | String | What the player reads under the number: "Spell", "Boost", "Armor", "Night Travel", "Reserve", "Steep", "Early damage", "Ambush", "Storm", "Hazards", "Spell 1"… |
| `source` | String | `spell`, `element`, `boost`, `reserve`, `hardship`, `ability`, `armor`, `fuse`, `enemy`, `dragon` |
| `value` | int | Signed contribution |
| `card` | String or null | The card id it came from, when there is one |
| `note` | String | Optional short reason: "enhanced: Ether matches", "no action fits: counts as 1", "fused" |

**Rules**
- For every sum `s` in a result, `Σ value of terms with sum == s` equals the result's
  total for `s` (`attack`, `initiative`, `move`; `mp` for the target; `damage`;
  `time_penalty`).
- A clamped total (Armor cannot take Attack below 0) clamps its term the same way, so
  the equality holds.
- Adding terms never changes any other field of the result.

## Explanation (engine)

The result of `Game.explain(action)` / `explain_final(action)`: the same dictionary
`preview` / `preview_final` returns, plus `terms` and `complete`.

| Field | Type | Notes |
|---|---|---|
| …existing fields | | `attack`, `initiative`, `move`, `mp`, `outcome`, `xp`, `damage`, `time_penalty`, `tier`… as today |
| `terms` | Array[Term] | As above |
| `complete` | bool | False when a role is still empty. Then `outcome`, `tier` and the consequences are not shown |

## Sum (view)

What the math box draws for one sum. Shaped in `view_state.gd` from an Explanation;
no arithmetic.

| Field | Type | Notes |
|---|---|---|
| `id` | String | `attack`, `initiative`, `move` |
| `terms` | Array | The Terms for this sum, in engine order |
| `total` | int or null | The engine's total; null while incomplete |
| `target` | Dictionary | `{value, icon, terms}`: HP, Initiative or MP, with its own terms when Steep changes it |
| `result` | String | `complete`, `narrow`, `loss`, or `first` / `early` for Initiative; "" while incomplete |
| `missing` | Array | Roles still needed, while incomplete |
| `tier` | Dictionary or null | Final Battle: `{index, cost}` |

## RoleSlot (view)

One role of one Action Set (replaces RoleToken).

| Field | Type | Notes |
|---|---|---|
| `set`, `role` | int, String | As before |
| `state` | String | `empty`, `next`, `filled`, `played`, `kept`, `discarded` |
| `card_id` | String or null | |
| `number` | int or null | From the Explanation's term for this role (Spell, Boost), or the card's Initiative (Element) |
| `counts_to` | String | `attack`, `move`, `initiative` (icon under the number) |
| `ether` | String or null | Edge colour; the Element's Ether for the Element slot |
| `boost_to` | String or null | Boost slot against an Enemy: `attack` or `initiative`; tapping the target icon toggles it |
| `tap` | Dictionary or null | `select_slot`, `take_back`, `inspect` (recap) |
| `tooltip` | String | Role and set; the card name when filled |

**Rules**
- No visible card name in a slot (FR-002).
- `number` changes when a later placement changes the engine's figure (FR-004).

## Zone

As in revision 1: a box with one job. It is drawn with `StoneStyle`, and its rim
colour changes flat when it waits on the player (`input_region`: `hand` or `commit`)
or answers an event.

## Ground

| Field | Type | Notes |
|---|---|---|
| `file` | String | `res://art/stone/ground-<n>.png`, n = `Settings.ground` (1–4, chosen in the menu); the noise grain is the fallback |
| `size` | int | 512 (tile) |
| `tones` | int | 3 flat tones |
| `luminance` | range | Inside `[STONE_L_MIN, STONE_L_MAX]` |
