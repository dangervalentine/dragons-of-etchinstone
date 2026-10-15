# Contract: Role Rail (US1)

Replaces `ui/widgets/slot_row.gd` and the slots region. Data shape:
[data-model.md § RoleToken](../data-model.md#roletoken-role-rail).

## Placement

- **Region**: `rail` in `layout_solver.gd`, replacing `slots`. It sits above `hand` in
  the right column.
- **Height**: exactly `T.TAP_MIN` (88) when `slot_rows(vs) > 0`, otherwise 0. There is
  no spare-height top-up; the old `slots_h += …spare…` rule is removed.
- **Width**: the tokens' total, centred over the Hand's card row. It is not stretched
  to the column.
  - One set: 3 tokens of `RAIL_TOKEN_W` (about 132) plus the toggle.
  - Two sets: 6 tokens of `TAP_MIN` plus up to 2 toggles.
- **Freed height**: it goes to `hand` (D2). Cards are re-fitted by `_fit_cards` as
  today.

## What each token shows

| State | Shows | Tap |
|---|---|---|
| `empty` | Role icon, muted; set pip with two sets | `select_slot` |
| `next` | Role icon and rim in `T.FOCUS`; set pip | `select_slot` (already selected; no-op) |
| `filled` | Role icon plus contribution numerals, tinted by the card's Ether. **No card name.** | `take_back` |
| `played` | Role icon plus a struck mark | none |
| `kept` (Reserve) | Reserve icon in `T.GOLD` | none |
| `discarded` | Role or Reserve icon, muted, struck | none |

Contribution, by role (from the card's current Level):
- Spell: `basic` / `enhanced`, the enhanced value in its Ether's ink, plus the Ether
  icon.
- Element: the Ether icon, plus Initiative.
- Boost: `+n` and the Boost icon.

**Boost-to toggle**: it shows the target icon (Attack or Initiative). In one-set mode
it also shows the word. Tapping it sends `toggle_boost_to {set}`, and the tooltip
names the target. It keeps the same intent and semantics as today.

**Tooltip**: `"Spell 2: Destruction"`, or `"Spell 2"` when the token is empty.

## Guarantees

- Every intent the old slots could send can still be sent from the rail (FR-004).
- What the Boost card boosts stays visible (FR-003).
- No visible card name (FR-002).
- Each token is ≥ `TAP_MIN` on its shorter side, and text is ≥ `T.TEXT_MIN`.
- Card flights that aimed at a slot (`SlotRow.slot_rect`) aim at the matching token
  (`RoleRail.token_rect(set, role)`).
- `tools/ui_check.gd` sees no overflow, scroll or undersized control at any matrix
  size.

## Tests (`tests/test_role_rail.gd`)

- Token shaping:
  - one set, all states;
  - two sets with pips;
  - the recap with the Reserve kept and with it discarded;
  - no name in the visible text.
- Tap intents map one to one with the old `slot_row` intents for the same view state.
- Layout: the rail is 88 tall at every matrix size when present and 0 when absent. At
  `phone-16x9` with one set, its area is ≤ 50% of the old band's (824 × 154).
