# Contract: Screens and intents

Every screen is a `Control` with `setup(db, options)`, `apply_layout(content: Rect2)` and `signal intent(data: Dictionary)`, routed by `ui/main.gd` `dispatch`.

## TitleScreen (landing page) — `ui/screens/title_screen.gd`

Shows title, `Flavor.subtitle()`, disclaimer. No dragon tiles (`_tiles` empty).

| Control | Emits |
|---|---|
| How to Play | `{type: "rulebook"}` |
| Records | `{type: "records", from: "title"}` |
| Play (primary, focused on open) | `{type: "setup_dragon", options}` |
| Settings | `{type: "settings"}` |
| Glossary | `{type: "glossary"}` |

## DragonScreen (new) — `ui/screens/dragon_screen.gd`

Public state used by the UI check: `options: Dictionary`, `_tiles: {"dragon:<id>": Button}`, `stats: Control` (the chosen dragon's stats, rebuilt on each choice), `func _choose(id)`, `func back()`.

| Control | Emits / does |
|---|---|
| Dragon card | sets `options.dragon`, marks it chosen, refreshes crest and stats in place |
| Back / Escape / system back | `{type: "to_title", options}` |
| Continue (primary) | `{type: "setup_rules", options}` |

## main.gd routing changes

| Intent | Before | After |
|---|---|---|
| `setup_dragon` | title screen (dragon choice) | `DragonScreen` |
| `to_title` | title screen | landing; if `options` given, `menu = options` |
| `records_back`, `leave`, ending's `to_title` | title screen | landing (unchanged code path) |
| Escape / `NOTIFICATION_WM_GO_BACK_REQUEST` | `RulesScreen`, `RecordsScreen` call `back()` | also `DragonScreen` |

## Flavor — `ui/model/flavor.gd`

`static func subtitle() -> String`, `static func line(dragon_id: String) -> String`. Reads `res://data/flavor.json` once.
