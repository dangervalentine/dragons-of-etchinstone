# Data Model: Two-Step Game Setup

This feature adds no new stored data. It changes how the existing options dictionary moves between screens.

## Game setup choices (`options`)

The same dictionary as today, defined by `Settings.DEFAULT_OPTIONS` (`ui/model/settings.gd`).

| Field | Type | Values | Default |
|---|---|---|---|
| `dragon` | String | an id from `db.dragon_ids()` | `"rodving"` |
| `difficulty` | String | `casual`, `easy`, `normal`, `hard`, `impossible`, `dont_even_try` | `"normal"` |
| `cavalier` | bool | | `false` |
| `glass_cannon` | bool | | `false` |

**Validation**
- Exactly one dragon and one difficulty are always set. The tiles act as radio choices and can't be cleared.
- If a remembered `dragon` isn't in `db.dragon_ids()`, the dragon screen falls back to `Settings.DEFAULT_OPTIONS.dragon` (spec edge case). The same goes for an unknown `difficulty`, which falls back to the default.

**Where it lives**
- `main.menu`: the working copy for the game about to start. It is loaded from `Settings.last_options` at launch and updated by each setup move.
- Each setup screen keeps a private copy (`options`), taken in `setup()`, and sends it back in its intents.
- `Settings.last_options`: written only by `start_game()`, as today.

## Setup flow (state transitions)

```text
            launch / to_title / leave game
                        │
                        ▼
 ┌──────────────── Dragon screen ◄─────────────┐
 │  (choose dragon; Settings, Glossary)        │
 │                                             │ setup_dragon(options)
 │ setup_rules(options)                        │   Back button, Escape,
 ▼                                             │   Android back
 Rules screen ─────────────────────────────────┘
 (choose difficulty, toggle rules)
        │
        │ start(options)  → Settings.last_options = options
        ▼
   Play screen
```

Settings and Glossary are overlays. Opening and closing them leaves the current setup screen and its options as they were.
