# Contract: Rulebook UI

This adds to `specs/001-ui-polish/contracts/screens-and-interaction.md` and `specs/002-split-game-setup/contracts/setup-screens.md`. The overlay table gains one row:

| Overlay | Opened by | Closes on |
|---|---|---|
| Rulebook | "How to Play" on the title screen or in the in-game menu; `H` | Close button, Escape, Android back |

## Intent

`main.dispatch()` accepts one new intent:

```
{"type": "rulebook", "section": String (optional)}
```

- It adds a `RulebookOverlay` to `_overlays` and calls `open(plan.content.grow(-T.M), section)`.
- With no `section`, it opens at `Rulebook.position`. With a valid section id, it opens at page 0 of that section. An unknown id is ignored and treated as no `section`.
- It never reads or writes `game`, `draft`, `vs`, `menu` or `Settings`.
- As with every intent, it does nothing but skip the sequence if one is playing.

The existing `help` intent is reused unchanged for the terms chips: `{"type": "help", "id": <glossary id>, "source": <chip>}`.

## Overlay: `ui/overlays/rulebook_overlay.gd`

Extends `overlay.gd`, with `close_outside = false` like the full Glossary, so a stray press can't close a long read.

- `signal intent(data: Dictionary)`: emits `help` for chips. `main` connects it to `dispatch`.
- `func open(content: Rect2, section_id := "") -> void`: builds the panel to fill `content` and shows the position. It grabs focus for Next, or for Close on the last page.
- `func show_page(section: int, page: int) -> void`: draws a page, writes `Rulebook.position` and cross-fades over `T.FAST`.
- `func next() -> void`, `func previous() -> void`: step via `Rulebook.step`. They do nothing at either end, where the button is disabled.
- `func toggle_contents() -> void`: swaps the body for the contents grid and back.
- `close()` is inherited and frees the overlay. Position is already saved.

**Layout** (R13): header row, then body (a text column of about 60% and an aside column of about 40%), then footer row, all inside `content`. The contents grid replaces the body.

**Header**: `book` icon · section title (`T.HEADING`, gold) · "Section *s* of *S* · Page *p* of *P*" (`T.LABEL`, muted; the page part is left out for one-page sections) · Contents button · Close button.

**Footer**: Previous (`quiet`), then a spacer, then Next (`normal`). On the first page Previous is disabled. On the last page Next is disabled and reads "End of rulebook".

**Contents**: one button per section, labelled "*n*. *Title*". The current section uses the `active` style. Choosing one shows its page 0 and closes the contents. A Back to page button closes the contents without moving.

**Terms column**: at the foot of the aside, a "Terms on this page" label, then one chip per term marked in the page's *text* (terms inside an aside's table are explained by the table, so they get no chip). A chip is a button with the term's icon and Glossary name, height ≥ 44, `set_meta("help_target", true)`. Pressing it emits `help` with the chip as `source`.

**Keys** (handled in the overlay's `_unhandled_key_input`, only while it is the top overlay):

| Key | Does |
|---|---|
| Right, Page Down | `next()` |
| Left, Page Up | `previous()` |
| C | `toggle_contents()` |
| Escape | Handled by `main` (closes the top overlay) |
| Tab, Shift+Tab, Enter, Space | Godot focus navigation and button press, as elsewhere |

**Motion**: fades only (`T.FAST`), in both motion settings.

## Entry points

**Title screen** (`ui/screens/title_screen.gd`): in the right column's bottom row, at the left beside Continue, a button "How to Play" (`normal`, icon `book`) that emits `{"type": "rulebook"}`. The left column has no room for another row at 1280 × 720.

**In-game menu** (`ui/overlays/menu_overlay.gd`, `in_game == true`): the buttons become two rows, How to Play and Glossary, then Leave game and Resume. How to Play closes the menu and emits `{"type": "rulebook"}`, as Glossary does today. The title's Settings variant is unchanged.

**Keyboard** (`main._unhandled_key_input`): with no overlay open, `H` dispatches `{"type": "rulebook"}` on any screen.

## Figures: `ui/widgets/rulebook_figure.gd`

```
static func make(kind: String, db, size: Vector2, on_help: Callable) -> Control
```

- `"mage"`: a `CardFace` for a fixed real card and Level, plus labelled rows for every figure (FR-022). The rows use the names `card_detail.gd` uses.
- `"enemy"` and `"journey"`: one `EncounterFace` for a real Region 1 enemy or Journey, from `ViewState.encounter_model`, scaled to the aside width, with its figures named underneath. They are separate figures because one face already fills the aside column.
- `"dragon"`: an art crop and name for one dragon, with `DragonStats.make(d)`.

`size` is the aside width and the body height left after the terms chips, so every figure fits at every matrix size. The figure chips (`StatChip`s inside `EncounterFace` and `DragonStats`) keep their Glossary presses: `make` connects them to a `help` callback that the overlay forwards through its `intent` signal. The `CardFace` ignores mouse input.

## Shared builder: `ViewState.encounter_model`

```
static func encounter_model(db, region: int, kind: String, index: int, hardship, key_card: Dictionary) -> Dictionary
```

This returns the dictionary `_encounter()` returns today for a Region Encounter. `_encounter()` becomes a thin call to it, passing the live game's Key Card (`{id, name, level, element}`). The rulebook example passes a real Mage Card whose Level 2 Key Card names that Encounter, found from `CardDB`, so the caption under the face ("Enemy 1 · Key Card *name*, Level 2") teaches what a Key Card does. `EncounterFace` is unchanged.

## Verification hooks

- `tests/test_rulebook.gd` covers content, structure, tokens, wording, length and the not-verbatim check (research R11).
- In `tools/ui_check.gd`, at every matrix size:
  - Open the rulebook from the title screen and walk every page and the contents, applying `_inspect_screen` on each.
  - Start a game, place two cards, open the rulebook from the menu, change page, close, and assert `draft.to_action()` and `vs` are unchanged.
  - Open a terms chip's popover over the rulebook and inspect it.
  - Extend `_inspect_screen` to apply the Label checks to `RichTextLabel`.
  - Treat a page body whose minimum size exceeds its rect as a failure.
- `tools/shot.gd`: add shots of the rulebook's first page, the contents, a figure page and a table page.
