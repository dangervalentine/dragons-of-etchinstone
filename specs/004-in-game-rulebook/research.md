# Research: In-Game Rulebook

All Technical Context items were resolved from the codebase; none remain open. Each decision below names the code it builds on.

## R1. Overlay, not a screen

**Decision**: The rulebook is an overlay (`ui/overlays/rulebook_overlay.gd`, extending `overlay.gd`) added to `main._overlays`, the same way as the full Glossary (`GlossaryPopover.show_all`).

**Rationale**: Overlays sit above the current screen and never touch `game`, `draft` or `vs`; `overlay.gd` documents this ("never changes the game"). So opening and closing the rulebook mid-game leaves the Encounter, the half-built Action Set and any Upgrade choices exactly as they were (FR-002, FR-003, SC-003) without saving or restoring anything. Escape and Android back already close the top overlay (`main._unhandled_key_input`, `NOTIFICATION_WM_GO_BACK_REQUEST`), and a Glossary popover opened from inside the rulebook stacks above it and closes back to it.

**Alternatives considered**: A new screen through `main._switch()`. Rejected: switching away from `play` frees the play screen, so the game view would have to be rebuilt on return, and the title-screen path would also lose the dragon screen's state.

## R2. Pages, never scrolling

**Decision**: Sections are written as one or more pages, each sized to fit the smallest content area whole. Previous and Next step through pages and cross into the next or previous section at a section's end. The header shows "Section 6 of 18 · Page 2 of 3". The spec's FR-009 was amended to match.

**Rationale**: The project rule is that nothing scrolls: `tools/ui_check.gd` fails any visible `ScrollContainer`, and the Glossary already pages its entries (`PER_PAGE := 8`). Pages also give stable positions to remember (R8) and to show in the header.

**Alternatives considered**:
- A `ScrollContainer` per section. Rejected because it breaks the project rule and `ui_check`.
- Flowing blocks into pages at run time by measuring text at the current window size. Rejected: page counts would change with window size, so "page 2 of 3" and the remembered position would shift on resize. It would also need a text measurer. Authored pages are deterministic, and `ui_check` proves each one fits at every size.

## R3. Where the text lives

**Decision**: A GDScript content module, `ui/model/rulebook.gd`, holding `const SECTIONS` (an ordered array of sections, each with pages of blocks) and static helpers. It sits next to `ui/model/glossary.gd` and follows its pattern.

**Rationale**: The Glossary is already written this way, checked against the rulebook and tested headless (`tests/test_glossary.gd`). A const module needs no parser, loads on every platform with no file access, and works offline (FR-025). Tests can inspect it directly.

**Alternatives considered**: A Markdown or JSON file under `data/` with a parser. Markdown is pleasanter to write prose in, but it needs a parser and its tests, and nothing else in the project reads text assets. JSON prose is hard to edit. Neither is worth it for roughly 3,500 words.

## R4. Light markup inside the text

**Decision**: Paragraph and list strings use three tokens, which the model expands before display:

| Token | Meaning | Expands to |
|---|---|---|
| `[[id]]` or `[[id\|shown words]]` | A Glossary term | The term in bold. The id is added to the page's terms column (R6) |
| `{icon:id}` | A game icon | The icon inline at text height (`art/icons/<id>.svg`) |
| `{n:NAME}` | A number from the engine | The value of a whitelisted engine constant, e.g. `{n:MAX_DIVERTS}` → `2` |

The difficulty table is not written by hand. It is generated from `Game.DIFFICULTY` (cards offered, cards changed, new Level).

**Rationale**: The engine already exposes the numbers the rules depend on (`HAND_SIZE`, `FINAL_JOURNEY_HAND`, `MAX_DIVERTS`, `KNOCK_OUT_DISCARD`, `DIFFICULTY`). Pulling them in means the rulebook cannot disagree with the engine on those figures (FR-013, SC-005). Marking terms once gives bold emphasis, the terms column and a testable link to the Glossary from a single source.

**Alternatives considered**: Plain text with numbers typed in. Simpler, but the text would drift from the engine with nothing to catch it.

## R5. Paragraphs drawn as rich text

**Decision**: Paragraphs and list items are `RichTextLabel`s with `bbcode_enabled`, `fit_content = true`, autowrap, the theme's body font at `T.BODY`, and `mouse_filter = IGNORE`. They need bold for terms and `[img]` for inline icons. Headings, table cells and captions stay as `UI.label()`. `tools/ui_check.gd` is extended to apply its Label checks (minimum text size, inside the view and the safe area) to `RichTextLabel` too.

**Rationale**: `Label` cannot mix bold runs or inline images (FR-024). No existing widget uses `RichTextLabel`, so the UI check has to learn about it, or rulebook text would escape the text-size and clipping checks.

**Alternatives considered**: Labels only, with icons placed only in tables and the terms column. This needs no `ui_check` change, but inline icons are the point of FR-024 and bold terms help skimming.

## R6. Glossary terms as a column of chips, not inline links

**Decision**: Each page has a "Terms on this page" column: one pressable chip per `[[term]]` on the page (icon and name), in first-use order, at least `HELP_MIN` (44) units on the short side and tagged `help_target`. Pressing a chip emits `{"type": "help", "id": id, "source": chip}`, and `main` opens the existing Glossary popover beside it. Inline terms are bold but do not respond to presses.

**Rationale**: Inline links in 26-unit body text would be tap targets about 30 units tall, under the project's 44-unit floor for help targets that `ui_check` enforces. The chip column meets the floor, reuses the existing `help` intent and popover unchanged, and leaves the reader in the same spot after dismissal (FR-023). A term with no Glossary entry cannot reach the column, because a test requires every `[[id]]` to exist in the Glossary (the spec's edge case).

**Alternatives considered**: `RichTextLabel` `[url]` meta links. They are too small to tap on phones and invisible to `ui_check`.

## R7. Labelled card examples from the game's own widgets

**Decision**: A widget `ui/widgets/rulebook_figure.gd` draws four examples:

- **mage**: a `CardFace` for a real card at a fixed Level from `CardDB`, beside rows naming each figure (Level, Key Card Encounter and Hardship, Initiative, Basic and Enhanced action, Boost, Armor, Upgrade Cost) in the same icon-and-label row style as `card_detail.gd`.
- **enemy** and **journey**: an `EncounterFace` for a real Region 1 enemy or Journey (one per figure, since one face fills the aside column), built by a new static `ViewState.encounter_model(db, region, kind, index, hardship, key_card)`. `ViewState._encounter()` is refactored to call it. The example passes a real Mage Card whose Level 2 Key Card names that Encounter, so `EncounterFace` (which captions the Key Card) needs no change.
- **dragon**: the dragon's art crop and name with `DragonStats.make(d)` (its Armor and both tier ladders).

**Rationale**: These match exactly what the player sees in play (FR-022), stay correct if the card data changes, and need no new art. Factoring `encounter_model` out of `_encounter` lets the example and the play screen share one builder.

**Alternatives considered**: Static images of cards. They would go stale, need producing for each size, and the printed book's illustrations can't be reused.

## R8. Reading position: a static variable

**Decision**: `Rulebook.position` is a `static var` (`{"section": int, "page": int}`, default `{0, 0}`) on the content module. The overlay reads it on open and writes it on every page change. It is not saved.

**Rationale**: A static variable lives as long as the process, so it is kept across opens and closes within a session and starts fresh on relaunch (FR-004 and the session-only assumption). `UI.reduced_motion` uses the same pattern.

**Alternatives considered**: Saving it in `Settings`. The spec chose session-only.

## R9. Ways in, naming, keys

**Decision**:
- **Title screen**: a "How to Play" button (`normal` style, new `book` icon) in the bottom row of the right column, beside Continue. It was first placed in the left column, but that made the column too tall for 1280 × 720, and the UI check failed it.
- **In-game menu**: a "How to Play" button. The four buttons become two rows: How to Play, Glossary / Leave game, Resume.
- **Keyboard**: `H` opens the rulebook from any screen when no overlay is open (`?` stays the Glossary). Inside the rulebook: Left/Right and Page Up/Down for previous/next page, `C` for the contents, Escape to close. Buttons are focusable for Tab and Enter, as elsewhere.
- **Intent**: `{"type": "rulebook", "section": <optional id>}` in `main.dispatch`.
- **Names**: "rulebook" in code and "How to Play" on screen. `RulesScreen` already names the difficulty/alternate-rules setup step, so "rules" is avoided.
- **Ending screen**: not offered in this version (the spec makes it optional).

**Rationale**: These are the entry points the spec requires (FR-001, FR-002). The three steps menu → How to Play → contents entry meet SC-002. The keys follow how `main` already routes keyboard input: the overlay sees unhandled keys before `main`, because it is deeper in the tree.

## R10. A sequence playing when the menu is opened

**Finding**: No change needed. `main.dispatch()` skips a playing sequence and returns before handling the intent, and `_input()` makes the first press during a sequence only skip it. So the menu, and the rulebook through it, can only open once the sequence has finished, and no result is lost or repeated (the spec's edge case).

## R11. Checking the content

**Decision**: A new headless test file, `tests/test_rulebook.gd`, checks:

1. **Structure**: unique section ids, at least one page each, the reading order of FR-005, and the required section ids for SC-004.
2. **Coverage**: every Hardship, Ability and Peril id in `data/cards.json` appears as a `[[term]]` (same harvest as `test_glossary.gd`). Every key of `Game.DIFFICULTY` and both alternate rules appear.
3. **Links**: every `[[id]]` has a Glossary entry, every `{icon:id}` file exists, every `{n:NAME}` is whitelisted, and no unexpanded token survives expansion.
4. **Digital wording** (SC-006, FR-014, FR-019): no page contains "rotate", "flip", "left hand", "right hand", "behind the", "DIZED", "co-op", "Tracking Crystal" or "Challenge Mode". "orient" and "shuffle" may appear only in a sentence that says "the game" does it.
5. **Length** (SC-008): at most 3,500 words in all (about 15 minutes at 250 words a minute), and at most 130 words in a page's text column, as an early warning before `ui_check`.
6. **Not verbatim** (FR-012): if `reference/rulebook.txt` is present (it is gitignored), no run of 8 consecutive words matches it. When the file is absent the test records a skip as a passing assertion.

Fit at every window size is proved by `tools/ui_check.gd`, which opens the rulebook from the title screen and from a game in progress at every matrix size and walks every page and the contents. It applies the existing checks: tap sizes, text sizes, inside the safe area, nothing scrolls. It also confirms the draft and view state are unchanged after closing (SC-003).

**Rationale**: These turn the spec's checkable claims into failing tests. Accuracy beyond the engine-sourced numbers (SC-005) still needs a read-through against the engine, which the quickstart lists.

## R12. Motion

**Decision**: Page and contents changes cross-fade over `T.FAST`, and the overlay appears with `overlay.appear()`. There is no sliding, so the same behaviour satisfies both motion settings (FR-027).

## R13. Page layout and budget

**Decision**: Every page uses one layout inside the content rect:

- **Header row** (`T.TAP_MIN` tall): book icon, section title, position text, Contents and Close buttons.
- **Body**: a text column (about 60% of the width, holding paragraphs, steps, lists and notes) and an aside column (about 40%, holding a figure or table, then the terms chips).
- **Footer row** (`T.TAP_MIN` tall): Previous, page dots or position, Next.

The tightest content rects are 1248 units wide (`phone-16x9`) and 665 tall (`phone-tall`, after its home-indicator inset). Combined, after panel padding (2 × 20), header and footer (2 × 88) and gaps, that leaves about 415 units of body height and a text column about 720 units wide: about 12 lines of about 11 words at `T.BODY`, so about 130 words. Pages over the budget are split when the content is written.

**Contents view**: replaces the body while open. It shows every section as a button in a grid, with as many columns as needed to fit (4 columns × 5 rows covers 18 sections at `T.TAP_MIN`). The current section is marked.

## R14. A book icon

**Decision**: Add a `book` icon to `tools/gen_icons.py` (an open book, 48-unit white SVG like the rest) and to `Glossary.NOT_SYMBOLS`, so `test_every_game_icon_has_an_entry` treats it as a control, not a game symbol.
