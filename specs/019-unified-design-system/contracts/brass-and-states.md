# Contract: what is brass, and how states look

## The rule

- `BRASS` is for exactly three things: **the primary action's fill**, **the selected thing's
  rim** (a tab, tile, card or section) and **the target slot** (the one place the next tap
  fills, and the coach mark's target ring).
- `BRASS_BRIGHT` is for **rewards and banner headlines** only: Score, XP figures, the XP
  star, 1st place, a won outcome, Level up, the upgrade and encounter-won board responses,
  the Region banner's headline, the game's name, and the victory verdict.
- Nothing else is brass, including panel or slab rims at rest, headings, eyebrows, icons,
  pointers, ornaments, hover tints, step emphasis and keyboard focus.

## Role mapping (research R6)

| Old use | New |
|---|---|
| `T.GOLD` / `T.FOCUS` as a rim on slabs, panels, tooltips, ornaments, note accents | `EDGE` (banners: the Region tint) |
| `T.GOLD` headings, eyebrows, list numerals, table header text | `LABEL` in `PARCHMENT_MUTED`, or `HEADING` in `PARCHMENT` |
| `icon_ink` default, rulebook inline icons, pointers, tags | `PARCHMENT` (`PARCHMENT_MUTED` when secondary); Ether icons keep `ether_shade(lit)` |
| Step emphasis: figure rings, lit Region panel, board response `focus`, `_glow_rim` | `PARCHMENT` ring/rim, no glow |
| Board response `gold` | `BRASS_BRIGHT`; `bad` → `DANGER`; `neutral` → `EDGE`; `ether` → `ether_shade(lit)` |
| Keyboard focus rings | `JADE`, 6 units, the control's own shape (chamfered or rounded) |
| Hover on flat icons and counters | `PARCHMENT` (from `PARCHMENT_MUTED` at rest) |
| `UI.flash` default | `PARCHMENT` |
| Soak meter fill before full | `PARCHMENT_MUTED`; full → `JADE` |
| Affordable upgrade cost on a card | `PARCHMENT`; unaffordable → `DANGER` with the minus sign |
| Reserve-boost dashed outline, "Stays in Hand" tag | `PARCHMENT_MUTED` |
| Zone edge of the XP purse | `EDGE`; the XP figure and icon are `BRASS_BRIGHT` |
| `action_bar` glow while Play is ready, Hand well breathing glow | removed (the brass fill is the signal) |
| `T.muted(...)` on any colour | removed: the colour is used as itself |

## One of each

- **Primary**: `UI.button(text, "primary")` sets meta `primary = true` and the brass style.
  The UI check fails if more than one Control with that meta is visible at once.
  - Boost aim's chosen aim is a selected **tab**, not a primary.
  - The Journey's fixed Move is a disabled tab.
  - The confirm dialog's answer is the primary. A destructive answer (Abandon run, Clear
    records) carries a `DANGER` icon.
- **Target**: at most one place in state `target` (data-model "Place state"). The UI
  check fails on two.

## Signals

`JADE` (good) and `DANGER` (harm) always travel with a tick, a minus sign, a heart, a
skull or the verdict icon. The audit's unaccompanied uses get one:

- `preview_panel` total: the verdict icon before the figure.
- `preview_panel:554`: the caution target sum gets its icon. CAUTION is gone; it becomes
  `PARCHMENT` with the narrow-victory icon.
- Screen tints in `animator` (damage red, win gold): kept as tints over the whole board,
  which already accompany the −N and verdict marks.
- Downgrade rings (`card_view:130`, `inspect_overlay:48`): the down-arrow icon.
- `card_face:481` unaffordable cost: the minus sign.
- Board response `bad`: drawn with the damage mark it accompanies.

## States

| State | Look | Reduced motion |
|---|---|---|
| pressed | bevel collapses, moves down `PRESS_DROP` over `PRESS`, back over `RELEASE` | style swap, no travel |
| selected | `BORDER_SELECT` `BRASS` rim; a card also takes `SHADOW_LIFT` | same |
| disabled | `STONE` face, `LINE` rim, no bevel, `PARCHMENT_FAINT` label (kept) | same |
| out of play | greyscale, `OUT_OF_PLAY` alpha | same |
| focus | `BORDER_SELECT` `JADE` rim in the control's shape | same |
| hover | face lightened 4% toward `PARCHMENT` | same |
