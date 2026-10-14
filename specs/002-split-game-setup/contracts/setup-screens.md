# Contract: Setup Screens

This replaces the "Title screen" section of `specs/001-ui-polish/contracts/screens-and-interaction.md` for the setup flow. Its screen table gains one row:

| Screen | Shown when | Primary action |
|---|---|---|
| Title (dragon) | No game in progress; first setup step | Continue |
| Rules | Second setup step | Set out |

## Screen interface (both screens)

Both follow the existing screen shape that `main._switch()` expects:

- `signal intent(data: Dictionary)`
- `func setup(card_db, opts: Dictionary) -> void`: takes a copy of `opts` and builds the screen.
- `func apply_layout(content: Rect2) -> void`: fits the screen to the safe content rect.

## Title (dragon) screen: `ui/screens/title_screen.gd`

Shows:
- The crest in the chosen dragon's Ether colour, "DRAGONS OF ETCHINSTONE", the tagline, Settings, Glossary and the credit/non-affiliation line.
- "Hunt a dragon": every dragon from `db.dragon_ids()`, each tile showing its art, name, title, Initiative and early damage. The chosen dragon is marked.
- Continue (primary). It has focus on build.

Does not show: difficulty or alternate-rule choices.

Emits:

| Press | Intent |
|---|---|
| Dragon tile | none (local: marks it and rebuilds the crest) |
| Continue | `{"type": "setup_rules", "options": options}` |
| Settings | `{"type": "settings"}` |
| Glossary | `{"type": "glossary"}` |

## Rules screen: `ui/screens/rules_screen.gd`

Shows:
- The chosen dragon: crest in its Ether colour, name, title, Initiative and early damage.
- "Difficulty": the six levels, each with the text from `_difficulty_text()` (moved here from the title screen). Exactly one is marked.
- "Alternate rules": Cavalier ("No Fusing") and Glass Cannon ("Matching Armor Soaks only +1"), each toggling on its own.
- Back (quiet) and Set out (primary). Set out has focus on build.

Emits:

| Press | Intent |
|---|---|
| Difficulty tile / rule tile | none (local: updates marks) |
| Back | `{"type": "setup_dragon", "options": options}` |
| Set out | `{"type": "start", "options": options}` (unchanged from today) |

## `main.gd` dispatch additions

| Intent | Effect |
|---|---|
| `setup_rules` | `menu = options`; show the Rules screen built from `menu` |
| `setup_dragon` | `menu = options`; show the Title screen built from `menu` |
| `to_title` (existing) | show the Title screen built from `menu`, as today |

## Back and Escape

| Context | Escape key | Android system back |
|---|---|---|
| Any overlay open | closes the top overlay (existing) | closes the top overlay |
| Rules screen | same as Back | same as Back |
| Title screen | nothing (existing) | quits the app (Godot's current default) |
| Play / Ending | unchanged | quits the app (Godot's current default, unchanged) |
