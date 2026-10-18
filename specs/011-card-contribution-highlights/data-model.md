# Data Model: Card Contribution Highlights

Every model here is in memory and rebuilt from the game and the draft on each view state. Nothing is saved.

## Card focus (extends `Emphasis.focus`)

```
focus = {
  regions: [region],          # lifted parts (R1); unchanged key
  mark: "",                   # unchanged: soaks_more, affordable, …
  damage_element: "",         # unchanged
  impacts: [{region, icon}],  # NEW: effects working against a value (R2)
  aim: null | {to: null | "attack" | "initiative"},   # NEW: on a Boost-position card against an Enemy
}
region ∈ {"basic", "enhanced", "ether", "initiative", "boost", "armor", "cost", "key"}
icon   ∈ {"night_travel", "steep", "ranged", "freeze", "armor"}
```

**Rules** (while building: phases `challenge`, `final_journey`, `final_enemy`, with `draft.mode == "none"`):

- **`regions`, from the explain terms** (R1):

  | Card in position | Lifted when |
  |---|---|
  | Spell | `enhanced` if its term's note starts with "enhanced"; `basic` if it has a term without the "counts as 1" note; none if it counts as 1; both while no Element is placed |
  | Element | `ether` always; `initiative` if an `Element` term is in the Initiative sum |
  | Boost | `boost` if a `Boost` term for its set exists |
  | Reserve | `boost` if a `Reserve` term exists in the Move sum |

- **`impacts`**: per [contracts/card-marks.md](contracts/card-marks.md). They are tied to the position, so a swap moves them to the incoming card (FR-018).
- **`aim`**:
  - present only when `_boost_has_target(game)` holds and the card is in a Boost position;
  - `to` mirrors `draft.boost_to[set]`;
  - absent on Journeys and the Final Journey.
- **Other steps**: during a Fuse, Divert or Regroup, and in non-building phases, `impacts` is `[]`, `aim` is null, and `regions` follows today's rules.

**Context additions** (`Emphasis.context`): `terms` (from `game.explain`, the call `view_state.math` already makes), `effects` (`vs.encounter.effects`), `give_up_reserve`, and `boost_to`.

## Boost aim

- **State**: `TurnDraft.boost_to[set]` ∈ {null, "attack", "initiative"}. It starts null, as today.
- **`cycle_boost_to(set)`** (new):
  - null → "attack" → "initiative" → "attack";
  - it replaces the box-row `set_boost_to` calls;
  - `toggle_boost_to` (keyboard) stays and becomes `cycle_boost_to`.
- **Gating**: `boost_unchosen()` keeps blocking Play with "Choose whether the Boost adds to Attack or to Initiative." (FR-014).
- **Card tap**: `CardView.aim_tapped(id)` → `main._on_aim(id)` → `draft.cycle_boost_to(draft.slot_of(id)[0])` → refresh.

## Aim zone (`CardView`)

- `aim_rect() -> Rect2`: `Rect2(0, size.y − 88, size.x, 88)` when `model.focus.aim != null`, else empty.
- **Press-and-release in the zone**, with no drag and no hold → `aim_tapped(id)`. Otherwise `tapped`, `held`, `drag_*` and `dropped` behave as today.

## Box modes (`PreviewPanel`)

| Mode | When | Shows |
|---|---|---|
| `tip` | Every non-resolving render | `prompt.step` eyebrow, `prompt.text`, and the step hint. No rows, pills, verdict or red edge |
| `summary` | After `reveal(math, preview)` from the animator's `tally` step, until the screen re-renders at `_finish` | Today's equation rows (without aim rows) and the outcome row; totals count up; the verdict reveals at the `verdict` step |

`needed_height` is unchanged: sized for the summary (R6).

## Sequence steps (`Sequencer`)

| Step | Change |
|---|---|
| `upgrade` | `values.spent = before.xp − after.xp` (per level-up) |
| `downgrade` (undo) | unchanged; no stars |
| `xp_lost` | NEW, in the `finish` sequence when `before.xp > 0`: `values.amount = before.xp` |
| `tally`, `verdict` | unchanged; the animator now calls `preview.reveal` first |

## View state removals

- `vs.math.sums[*].aim` and `ViewState._aim` are removed.
- `prompt.primary.kind = "warning"` from `pv.fatal` is removed.
- `vs.preview` and `vs.math` stay and feed the summary.
