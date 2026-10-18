# Contract: The Math Box (US2)

> **Superseded in part by 011 (2026-10-17)**: before Play the box shows only a tip for the step; these rows and the verdict appear only once Play is pressed, as the summary of the set just played. The Boost is aimed on its card, not from the rows. See `specs/011-card-contribution-highlights/contracts/left-box.md`.

Replaces the preview's comparison bars in the challenge and Final Battle steps. Data
shapes: [data-model.md § Term, Explanation, Sum](../data-model.md).

## Engine side (reporting only; research R1)

- `Rules.resolve_enemy` and `Rules.resolve_journey` add `terms: Array[Term]` to their
  results.
- `Game._final_journey` and `_final_enemy` do the same.
- `Game.explain(action)` returns `preview(action)` plus `terms` and `complete`. For an
  incomplete set (a role empty) it still resolves, with `complete: false`, instead of
  returning the "Assign a Spell, an Element and a Boost" error. Other errors (an
  invalid Fuse, a card used twice) are returned as today.
- `Game.explain_final(action)` is the same for `preview_final`.
- **Invariant**: for each sum, `Σ terms.value == total`. Every other field equals what
  `preview` / `preview_final` return today.

### Terms each resolution produces

| Encounter | Sum | Terms (in order) |
|---|---|---|
| Enemy | `attack` | Spell (basic, enhanced, or 1), Boost if to Attack (with Night Travel's cut as its own line), Armor (negative, clamped) |
| Enemy | `initiative` | Element's Initiative, Boost if to Initiative (with Night Travel's cut) |
| Enemy | `damage` | Early damage (with Ambush's doubling as its own line), Combat damage, Storm |
| Enemy | `time` | Hazards |
| Journey | `move` | Spell, Boost (with Night Travel's cut), Reserve (enhanced action matching the MP's Ether) |
| Journey | `target` | MP, Steep (+ the Reserve's Boost) |
| Journey | `damage` | Treacherous, Storm |
| Final Journey | `move` | Spell 1, Boost 1, Spell 2, Boost 2, Reserve |
| Final Enemy | `attack` / `initiative` | Spell 1, Boost 1, Spell 2, Boost 2 (to Attack or Initiative per set), Armor |
| Final Enemy | `damage` | Tier attack, Early damage, Carried damage |

Fuse adds no line of its own. It shows as the Spell's `note` ("enhanced: fused
Ether") when it is what made the enhanced action apply.

## Box layout (research R4)

1. **Equation rows**: one per sum the step uses (`attack` + `initiative`, or `move`).
   Each term is a cell, the signed number over its label. Then `=` and the total, in
   its outcome colour, then `/ target` with its icon. A Steep target shows as its own
   small sum. Rows wrap after a term.
2. **Initiative note**: "You strike first", or "Struck first: N early damage".
3. **Consequences**: the existing pills (XP, damage, time, poison, Reserve), with their
   tap help. The `damage` and `time` terms appear in each pill's tooltip and help.
4. **Play**: a gold plinth across the box's foot reading "Play · <verdict>". It is red
   with "Ends the game" when fatal, and disabled with the reason while incomplete.
   (R3 fallback: a verdict line here, and Play in the bottom-right corner.)

- **Incomplete set**: the rows show the placed terms, and "Still needed: <roles>" in
  place of `= total`.
- **Final Battle**: the row adds both sets. After the total: "Tier N · <cost>", or
  "No tier: the dragon escapes".
- **Counting**: a changed total counts to its new value over `T.COUNT`; instant under
  reduced motion.
- **Sizing**: `needed_height()` reports the fullest composition for the Encounter kind
  and step (as today), so the box does not resize as cards are placed.

## Guarantees

- Every number in the box is an engine figure or term (FR-010).
- Text ≥ 22 units except term labels. Those are ≥ 18 and marked `small_ok`, as
  separators are today, because each sits under a large numeral it names.
- The box keeps the help taps on the consequences.

## Tests

- `tests/test_terms.gd`: the invariant over every Enemy and Journey in the data, each
  Hardship and ability, both Boost targets, matched and unmatched Ethers, and Fuse;
  both Final Battle steps; existing fields unchanged.
- `tests/test_view_state.gd`: the box's sums are shaped from `explain()`. An incomplete
  set gives `missing` and no total.
