# Contract: The Left Box

The box under the Encounter face (`PreviewPanel`) in this interim, before the follow-up pass redesigns the column. The soak meter and the XP purse share its region, as today.

## Before Play: the step tip (FR-001 to FR-003)

| Step | Eyebrow | Tip (≤ 2 lines) |
|---|---|---|
| Setup | `SETUP` | today's setup prompt, and "Hold a card to see its other Levels." |
| Building, Journey | — | "Tap two cards to swap their Roles. Hold a card to inspect it." |
| Building, Enemy, a Boost unaimed | — | "Tap the bottom of the Boost card to aim it at Attack or Initiative." |
| Building, Enemy, all aimed | — | "Tap two cards to swap their Roles. Tap the bottom of the Boost card to re-aim it." |
| Fuse, Divert, Regroup | today's `Fuse · step n of 3` etc. | today's step text |
| Blocked (the engine refuses the set) | — | the engine's reason, in `T.BAD`, as today |

The box never shows Attack, Initiative, Move or Tier figures, targets, "Still needed" lists, verdicts, cost pills or a red edge before Play. Play's look never depends on the outcome.

## At Play: the summary (FR-023)

Sequence: `play_cards` → **`tally`**: `reveal(math, preview)` builds today's rows and outcome row from the pre-Play state, then the totals count up from 0 → **`verdict`**: the verdict scales in → `gain_xp`, and so on.

- There are no aim rows; the Boost's term sits in the sum it was aimed at.
- No number flies from the cards.
- At `_finish` the screen renders the after-state: the XP purse with the recap (unchanged).
- Under reduced motion, totals show at once and the verdict fades in.

## Upgrade: the XP purse (FR-019 to FR-022)

| Event | Purse | Flight layer |
|---|---|---|
| Level-up costing N | number counts down by N over the step | N `xp` stars, staggered, purse → card |
| Undo | number restores at `_finish` | none |
| Finish with N unspent | number fades out | "−N XP" floats up from the purse in `T.INK_MUTED` |
| Reduced motion | numbers change at once | stars and float snap or fade (flight layer's existing reduced path) |

## Space

`needed_height` sizes the box for its summary, so the column does not re-layout at Play. `ui_check._check_space` and `space_audit` measure the preview zone in the summary state. The tip state is checked for overlap and minimum text size only.
