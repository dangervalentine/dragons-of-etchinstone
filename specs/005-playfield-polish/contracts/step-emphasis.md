# Contract: Step Emphasis

**Module**: `ui/model/emphasis.gd` (pure, `extends RefCounted`, static functions only)
**Consumer**: `ui/model/view_state.gd` → `cards[id].focus`, `next_role`, `input_region`
**Tests**: `tests/test_emphasis.gd`

## Interface

```gdscript
## Focus for one card. `c` is the card model built so far by ViewState._card()
## (state, role, eligible, match, alt, …); `ctx` is the step context below.
static func focus(c: Dictionary, lv: Dictionary, ctx: Dictionary) -> Dictionary
    # → {"regions": Array[String], "mark": String, "changed": Array[String]}

## The step context, built once per view state.
static func context(game, draft) -> Dictionary
    # → {"phase", "mode", "next_role", "kinds", "sets", "journey_ether", "xp"}
```

`kinds` is the action types the current Encounter accepts (as `Rules.action`
expects): `["attack"]`, `["attack", "move"]` for a Slow enemy, `["move"]` for a
journey or the Final Journey. `sets` gives each Action Set's placed Element Ether
(or `""`) so a placed Spell's action in effect can be worked out.

## Step table (normative)

| Phase / mode | Card | `regions` | `mark` |
|---|---|---|---|
| `setup` | any | `[]` | `""` |
| building, mode `none`, next role `spell` | in Hand, not placed | `basic`, `enhanced` | `""` |
| building, mode `none`, next role `element` | in Hand, not placed | `ether`, `initiative` | `""` |
| building, mode `none`, next role `boost` | in Hand, not placed | `boost` | `""` |
| building, all slots full | in Hand, not placed, not Reserve | `[]` | `""` |
| building, any mode | placed as Spell | the plate in effect: `enhanced` if `Rules.action(...).enhanced`, else `basic`; both while the set has no Element | `""` |
| building, any mode | placed as Element | `ether`, `initiative` | `""` |
| building, any mode | placed as Boost | `boost` | `""` |
| building, journey or Final Journey | the Reserve | `boost` when the set's Spell is enhanced and its Ether equals the journey's MP Ether; else `[]` | `""` |
| `fuse_pick`, `fuse_element` | in Hand | `ether` | `""` |
| `divert`, `regroup` | in Hand | `[]` | `""` |
| `penalty`, `poison`, `final_soak` | any eligible or selected | `armor` | `soaks_more` when `c.match` |
| `upgrade` | cost affordable | `cost` + `alt.changed` regions | `affordable` |
| `upgrade` | cost > XP | `cost` | `unaffordable` |
| `upgrade` | at max Level | `cost` | `max_level` |
| `upgrade` | Downgraded | `[]` | `""` |
| `won`, `lost` | any | `[]` | `""` |

"Building" means phase `challenge`, `final_journey` or `final_enemy`. The next role is
`draft.active[1]` when `draft.active` points at an empty slot, else `""`.

Region-key mapping from `alt.changed` (ViewState keys → region keys):
`initiative→initiative`, `basic→basic`, `enhanced→enhanced`, `boost→boost`,
`armor→armor`, `upgrade_cost→cost`, `encounter→key`, `hardship→key`.

## input_region

`commit` when `prompt.primary.enabled` and no card choice is pending: building with
mode `none` and the preview `ready`; Soak `covered`; setup with all picks made;
Upgrade with no affordable card. Otherwise `hand`.

## Guarantees (tested)

1. Pure: building focus twice from the same game and draft gives equal results.
2. Every row of the step table, using seeded games driven to each phase.
3. Reserve Boost emphasis agrees with the engine: for every journey preview in a
   seeded run, emphasis on the Reserve's `boost` is set exactly when adding the
   Reserve's Boost changes `game.preview(action).move`.
4. A placed Spell's emphasised plate agrees with `game.preview(action).enhanced`.
5. Upgrade `mark` agrees with the existing `eligible`/`reason` fields.
6. Unavailable cards (`eligible == false`) may carry a focus, but the face draws
   them unavailable (covered by the face contract, not this module).
