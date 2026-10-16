# Data Model: Landing Page and Dragon Selection

## Flavor text — `data/flavor.json` (new, hand-edited)

```json
{
  "subtitle": "Cross the four Regions of Vale, hunt the dragon, and earn the name of Ether Mage.",
  "dragons": {
    "grimroch": "…",
    "helsang": "…",
    "rodving": "…",
    "vuurhast": "…"
  }
}
```

| Field | Type | Rule |
|---|---|---|
| `subtitle` | string | Shown under the title on the landing page. Missing or empty → the old tagline. |
| `dragons` | object, dragon id → string | One or two sentences per dragon, keyed by the ids in `cards.json`. Missing → card shows no flavour line. |

Initial values are the drafts in [spec.md § Clarifications](spec.md#clarifications); the user rewrites them after implementation.

## Dragon (existing, `data/cards.json`, unchanged)

`id`, `name`, `title`, `initiative`, `early_damage {value, element}`, `armor[]`, `mp_tiers[]`, `hp_tiers[]`. Primary Ether = `early_damage.element`. Head crop from `Art.head`.

## Setup choices (existing `menu` / `Settings.last_options`)

`{dragon, difficulty, cavalier, glass_cannon}`. Carried landing → dragon page → rules page and back; saved on Set Out.

### State transitions

```text
Landing ──Play──▶ Dragon page ──Continue──▶ Rules page ──Set Out──▶ Game
   ▲                 │  ▲                       │
   └──Back/Esc/sys───┘  └──────Back/Esc/sys─────┘
Landing ◀── game ends / leave game / Records back
```

Invariant: on the dragon page exactly one dragon is chosen; if `menu.dragon` is not in `cards.json`, it becomes the first dragon id.
