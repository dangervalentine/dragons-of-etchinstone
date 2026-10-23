# Data Model: Unified Design System

This feature has no game data and no saved state of its own. Its "data" is the token
catalogue and the few view-state values that decide which state a thing is drawn in.

## Design token (`ui/theme/tokens.gd`)

| Field | Meaning | Rule |
|---|---|---|
| name | `UPPER_SNAKE` form of the design system's name (`stone-raised` → `STONE_RAISED`) | one per entry in `design-system/tokens.json`, plus the extension tokens of research R12 |
| value | `Color`, an int in design units, a float (seconds, opacity) or a type style | colours equal `tokens.json`; sizes = round(points × 1.85) |
| note | the `##` comment above it: where it may be used | taken from the token's `usage`, cut to the game's terms |

Groups: colour, Ether (`ETHER[element] = {base, bright}`), Region
(`REGION[1..4]`, `REGION_LAIR`), type styles, space, chamfer, radius, border, shadow,
opacity, size, motion. Full list: [contracts/tokens.md](contracts/tokens.md).

**Validation** (`tests/test_design_tokens.gd`): every colour and size in `tokens.json`
has its token with the translated value; no token from the old palette is left
(`BG_BASE`, `BG_SURFACE`, `BG_RAISED`, `BG_BAND`, `LINE_SOFT`, `INK`, `INK_MUTED`,
`GOLD`, `GOLD_FACE`, `FOCUS`, `ACCENT_MUTE`, `GOOD`, `CAUTION`, `BAD`, `HP`, `BRONZE*`,
`STONE_L_*`).

## Type style

`{family: "display" | "sans", size: int, weight: int, opsz: int (display only),
spacing: float (em), upper: bool}`. There are 12 of them: `BANNER`, `TITLE`, `HEADING`,
`CARD_NAME`, `NUMERAL_XL`, `NUMERAL`, `NUMERAL_SM`, `LABEL`, `BUTTON`, `BODY`, `BODY_SM`,
`CAPTION`. Each resolves to one cached `FontVariation`. See
[contracts/type-styles.md](contracts/type-styles.md).

**Validation**: `size >= TEXT_MIN` for every style except `CARD_NAME`
(`>= CARD_NAME_MIN`); display styles set `SOFT` 50 and `WONK` 0.

## Region tint

Derived from `vs.stage` (view_state.gd:449): `kind == "region"` → `REGION[stage.region]`;
`kind == "final"` → `REGION_LAIR`; no game → none. It is used by the backdrop wash, the
banner rim and the banner medallion.

## Place state (Slot)

`view_state.places()` gives each Action Set place one state:

| State | When | Drawn |
|---|---|---|
| `empty` | nothing in it, not where the next tap goes | `PARCHMENT_MUTED` header, `WELL` with a `LINE` rim |
| `open` | a card is held and may go here | `PARCHMENT` header, `WELL` with an `EDGE` rim |
| `target` | **at most one at a time**: while a card is held, the place it is aimed at by the keyboard or the mouse (none while nothing is aimed, as on touch); with nothing held, `next_role`, the empty Role the next card goes to | `BRASS` header and underline, `BRASS` 6-unit rim, its name inside the well |
| `filled` | a card is in it | `PARCHMENT` header |
| `inactive` | not used this turn (given up, a Journey's unused role) | `PARCHMENT_FAINT` header, no rim |

**Transitions**: picking up a card turns `empty` places into `open` and the aimed one
into `target`. Dropping or placing the card turns them back, and `next_role` moves on
(TurnDraft's `_advance`). The rule is at most one `target` in the whole view.

## Control state (Button, Tab, Slot well, Card)

| State | Applies to | Look |
|---|---|---|
| rest | all | the material's own (slab, plinth, well, paper, card) |
| pressed | buttons, tabs | bevel collapsed, moved down 4 units |
| selected | tabs, cards, tiles | `BRASS` 6-unit rim (cards: plus the lift shadow) |
| target | slots | as above |
| disabled | buttons | `STONE` face, `LINE` rim, no bevel, `PARCHMENT_FAINT` label kept |
| out of play | cards | greyscale at `OUT_OF_PLAY` (0.45) |
| focus | anything focusable | `JADE` 6-unit rim |

**Primary**: a button with meta `primary` is drawn brass. There is at most one visible
per screen.

## Removed setting

`Settings.ground` and `Settings.GROUNDS` are deleted. A config file holding
`display/ground` still loads, and the key is ignored.
