---

description: "Task list for the In-Game Rulebook feature"
---

# Tasks: In-Game Rulebook

**Input**: Design documents from `/specs/004-in-game-rulebook/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/rulebook-ui.md, quickstart.md

**Tests**: Included. The plan (research R11) and quickstart make `tests/test_rulebook.gd` and the `tools/ui_check.gd` additions part of the design. Within each story, write the test task first and confirm it fails before implementing.

**Organization**: Tasks are grouped by user story so each can be implemented and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: The user story the task belongs to (US1–US4, from spec.md)

## Conventions for every task

- Godot 4.7.2, GDScript. Match the surrounding code: `##` doc comments, tabs, `const X = preload(...)`, `UI.*` builders from `ui/theme/theme.gd`, sizes and colours only from `ui/theme/tokens.gd` (`T.*`).
- "Run the tests" means `./tools/test.sh` from the repo root. It must end with `0 failed` for both the unit suite and the UI check, with no `SCRIPT ERROR` lines.
- Never edit `engine/`. If rulebook text and engine behaviour disagree, stop and report it. Do not word around it.
- Rules text is paraphrased in the project's own words. Never copy sentences from `reference/rulebook.txt` (gitignored, local only); read it only to check meaning.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: The one asset every entry point needs.

- [X] T001 [P] Add a `book` icon (an open book, drawn white in the 48-unit box like the other icons) to the icon list in `tools/gen_icons.py`, run `python3 tools/gen_icons.py` to write `art/icons/book.svg`, then run `godot --headless --path . --import` so `art/icons/book.svg.import` is created
- [X] T002 [P] Add `"book"` to `NOT_SYMBOLS` in `ui/model/glossary.gd`, so `test_every_game_icon_has_an_entry` in `tests/test_glossary.gd` treats it as a control, not a game symbol

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The content model and its pure helpers, which every story draws from (data-model.md, "Rulebook").

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Write `tests/test_rulebook.gd` (extends `res://tests/base.gd`, preloads `res://ui/model/rulebook.gd`, `res://ui/model/glossary.gd` and `res://engine/game.gd`) with these tests, which fail until T004:
  - `test_sections_in_reading_order`: ids are exactly `welcome, mage_cards, regions, dragons, setup, encounter, challenge, action, enemies, journeys, penalty, upgrade_cleanup, region_end, final_journey, final_enemy, scoring, ethers, difficulty`, in that order. Every section has a non-empty `title` and "At least one" page.
  - `test_find`: `find("penalty") == 10` and `find("nope") == -1`.
  - `test_step`: stepping crosses section boundaries both ways; `step` at the first page with -1 and at the last page with +1 "returns `pos` unchanged".
  - `test_expand`: `[[soak]]` becomes bold BBCode with the Glossary name; `[[soak|Soaking]]` shows "Soaking"; `{icon:fire}` becomes an `[img]` of `res://art/icons/fire.svg`; `{n:MAX_DIVERTS}` becomes `str(Game.MAX_DIVERTS)`.
  - `test_terms`: `terms()` returns the page's term ids in first-use order with no repeats.
  - `test_numbers_whitelist`: `NUMBERS` keys are exactly `HAND_SIZE, FINAL_JOURNEY_HAND, MAX_DIVERTS, KNOCK_OUT_DISCARD`, each equal to the `Game` constant of that name.
  - `test_difficulty_rows`: one row per `Game.DIFFICULTY` key, in its order, carrying its three numbers.
  - `test_position_default`: `Rulebook.position == {"section": 0, "page": 0}`.
- [X] T004 Create `ui/model/rulebook.gd` (`extends RefCounted`) as specified in data-model.md, making T003 pass:
  - **Constants**: `const SECTIONS` holds the 18 sections with the ids and titles of the data-model "Section outline". Each has one stub page with a one-sentence `p` naming what the section will cover. Also `const CREDIT` ("Dragons of Etchinstone is designed by Joe Klipfel and published by Chip Theory Games. The rules belong to them; this is a fan-made digital version, not affiliated with or endorsed by Chip Theory Games.") and `const NUMBERS` (name → `Game` constant).
  - **Position**: `static var position := {"section": 0, "page": 0}`.
  - **Helpers**: the static helpers `section_count`, `page_count`, `page`, `terms`, `find`, `step`, `expand` and `difficulty_rows`.
  - **`page()`**: returns `{text, aside, terms}` with every string expanded, including list items and table cells.
  - **Tokens**: `[[id]]` → `[b]<Glossary name>[/b]`, `[[id|words]]` → `[b]words[/b]`, `{icon:id}` → `[img=28x28]res://art/icons/id.svg[/img]`, `{n:NAME}` → the number.
  - **Doc comment**: a `##` header saying the text is written for this project and checked against the rulebook, as `glossary.gd` does.
  - Run the tests.

**Checkpoint**: The content model exists and is tested; the UI can now be built on it.

---

## Phase 3: User Story 1 - Learn the game from the title screen (Priority: P1) 🎯 MVP

**Goal**: From the title screen, How to Play opens the rulebook at its first page. The player reads all 18 sections in order with Previous and Next, then closes back to an unchanged title screen.

**Independent Test**: From the title screen, open the rulebook, read every page from first to last using only its own navigation, close it, and confirm the title screen is unchanged (quickstart, walkthrough step 1).

### Tests for User Story 1 ⚠️

- [X] T005 [P] [US1] Extend `tools/ui_check.gd`, which fails until T006–T008 exist:
  - **Rich text checks**: in `_inspect_screen`, give `RichTextLabel` (non-empty `text`) the same checks as `Label`. Font size comes from `get_theme_font_size("normal_font_size")` and must be ≥ `T.TEXT_MIN`. The rect must be inside the view and inside the safe area (skip both when `ui.plan.undersized`).
  - **Overlay sweep**: add `"rulebook": func(): ui.dispatch({"type": "rulebook"})` to the `opens` dictionary in `_screens_and_overlays`.
  - **Page walk**: add `func _rulebook_walk(where: String)` and call it from `_screens_and_overlays` right after the settings check, while the title screen is showing. It records `ui.screen.options` and dispatches `{"type": "rulebook"}`, then waits for `_settle()`. It asserts the top overlay is a `RulebookOverlay` showing section 0, page 0. Then for every page it forces `modulate.a = 1.0` on the overlay and its children (as the `opens` loop does) and runs `_inspect_screen("%s rulebook s%d p%d")`. It asserts the page body's combined minimum size fits inside its rect ("Treat a page body whose minimum size exceeds its rect as a failure") and calls `next()`. At the last page it asserts the Next button is disabled and reads "End of rulebook". Finally it closes with an Escape key event through `ui._unhandled_key_input`, and asserts no overlay remains and `ui.screen.options` is unchanged.
  - **Rename**: preload the overlay as `RulebookOverlay`. `RulesScreen` is already taken by the setup screen.
- [X] T006 [P] [US1] Add coverage, length and not-verbatim tests to `tests/test_rulebook.gd`. They fail until the content tasks below are done.
  - `test_covers_every_effect`: reuse the `_effect_ids` harvest from `tests/test_glossary.gd`. Every Hardship, Ability and Peril id in `data/cards.json` appears as a `[[id]]` term somewhere in the rulebook.
  - `test_covers_difficulty_and_rules`: the `difficulty` section uses `{"table": "difficulty"}`, and "Cavalier" and "Glass Cannon" both appear in its text.
  - `test_terms_and_icons_resolve`: every `[[id]]` passes `Glossary.has(id)`, every `{icon:id}` file exists in `res://art/icons/`, every `{n:NAME}` is in `NUMBERS`, and no `[[`, `{icon:` or `{n:` survives `page()`.
  - `test_length`: "Total words ≤ 3,500, and words per page text column ≤ 130". Count words after stripping BBCode and tokens.
  - `test_not_verbatim`: if `res://reference/rulebook.txt` exists, compare lowercased word runs and fail on any run of 8 consecutive words shared with it. If the file is absent, record `ok(true, "reference rulebook absent; skipped")`.

### Implementation for User Story 1

- [X] T007 [US1] Create `ui/overlays/rulebook_overlay.gd` (`extends "res://ui/overlays/overlay.gd"`) per contracts/rulebook-ui.md:
  - **Setup**: `close_outside = false`; `signal intent(data: Dictionary)`; `func open(content: Rect2, section_id := "")`, which for now always opens at section 0, page 0 (US2 adds reading position).
  - **Layout**: a panel filling `content` with header row, body and footer row (R13). The body is an HBox: a text column with stretch ratio 0.6 and an aside column with ratio 0.4.
  - **Header**: `book` icon, section title (`T.HEADING`, `T.GOLD`), "Section *s* of *S* · Page *p* of *P*" (`T.LABEL`, `T.INK_MUTED`; drop the page part for one-page sections), and a Close button (`quiet`, icon `close`) calling `close()`.
  - **Footer**: Previous (`quiet`), spacer, Next (`normal`). Previous is disabled on the first page. On the last page Next is disabled and reads "End of rulebook".
  - **Blocks**:
    - `p`: `RichTextLabel`, `bbcode_enabled`, `fit_content = true`, autowrap smart, `mouse_filter = IGNORE`, font `UI.font("body")`/`"body_bold"` for normal/bold at `T.BODY[1]`, colour `T.INK`.
    - `steps`: the same per item, prefixed "1." "2." ….
    - `list`: the same per item, prefixed "•".
    - `note`: a `UI.panel(T.BG_RAISED, …)` holding a rich-text paragraph.
    - `table`: a `GridContainer` of `UI.label` cells. The head row is in `body_bold`. `"difficulty"` builds its rows from `Rulebook.difficulty_rows()` with the head "Difficulty / Cards offered / Changed / To Level" and human names ("Casual", "Easy", "Normal", "Hard", "Impossible", "Don't Even Try It").
  - **Credit**: on section 0, page 0, add `Rulebook.CREDIT` as a muted `T.LABEL` line at the foot of the text column.
  - **Paging**: `show_page(section, page)` rebuilds the header text, body and footer state, writes `Rulebook.position`, and fades the body in over `T.FAST`. `next()` and `previous()` use `Rulebook.step`.
  - **Keys**: in `_unhandled_key_input`, act only when this node is the last non-queued child of its parent: Right or Page Down calls `next()`, Left or Page Up calls `previous()`, then `get_viewport().set_input_as_handled()`.
  - **Focus**: Next grabs focus deferred, or Close on the last page.
  - Finish with `appear()`.
- [X] T008 [US1] Wire the intent in `ui/main.gd`:
  - Preload `RulebookOverlay`.
  - In `dispatch`, add `"rulebook":`. It creates the overlay, adds it to `_overlays`, connects its `intent` to `dispatch`, and calls `open(plan.content.grow(-T.M), intent.get("section", ""))`. It must not touch `game`, `draft`, `vs`, `menu` or `Settings`.
  - In `_unhandled_key_input`, after the `top != null` early return and beside the `?` Glossary key, make `KEY_H` dispatch `{"type": "rulebook"}` on any screen.
- [X] T009 [P] [US1] In `ui/screens/title_screen.gd` `_build()`, add a "How to Play" button (`UI.button("How to Play", "normal", "book")`, 260 wide) at the left of the bottom row of the right column, beside Continue. It emits `{"type": "rulebook"}`. (Placed there because a button in the left column made it too tall for the 1280 × 720 layout; the UI check caught the overflow.)
- [X] T010 [US1] Write sections 1–5 (`welcome`, `mage_cards`, `regions`, `dragons`, `setup`) in `ui/model/rulebook.gd`, replacing the stubs:
  - `welcome`: a short story setup in your own words; the goal (four Regions, then the Final Journey and Final Enemy); win by surviving the dragon, lose by falling short on the Final Journey or Final Enemy or being Knocked Out by the dragon.
  - `mage_cards`: Levels 1–4 and every figure on a card; the top card of the Deck is the Key Card.
  - `regions`: the four Regions; enemies and Journeys; which Encounter the Key Card names; XP.
  - `dragons`: Initiative, Early Damage, Armor, the three MP tiers and the three HP tiers.
  - `setup`: what the player chooses on the two setup screens (dragon, then difficulty and alternate rules), the difficulty card pick, and that the game builds the Deck and deals `{n:HAND_SIZE}` cards.
  - Mark every Glossary term at first use per page with `[[id]]`. Keep each page "≤ 130" words and split pages as needed.
- [X] T011 [US1] Write sections 6–8 (`encounter`, `challenge`, `action`) in `ui/model/rulebook.gd`:
  - `encounter`: the five phases at a glance as a table (Phase / What happens).
  - `challenge`: Scout Ahead, the four Hardships as a table (`{icon:ambush}` Ambush … with their effects), and Divert (up to `{n:MAX_DIVERTS}` times, discarding the Key Card and a Hand card, and its cost: fewer cards, less time to Upgrade).
  - `action`: the Spell, Element and Boost Roles; the Reserve card; the minimum value of 1 for the off-type action; flex cards; with fewer than three cards one Role must be the Spell; Fusing (once per Encounter, same Ether, choose any Ether, both cards discarded at Cleanup).
  - Check each rule against `engine/rules.gd` and `engine/game.gd`. Keep each page "≤ 130" words.
- [X] T012 [US1] Write sections 9–11 (`enemies`, `journeys`, `penalty`) in `ui/model/rulebook.gd`:
  - `enemies`: the four steps (Boost to Attack or Initiative, Initiative and Early Damage, Basic or Enhanced Attack, Armor on a matching Enhanced Attack); the outcome as a table (Attack vs HP: Complete / Narrow / Loss with consequences); and the Abilities Freeze, Poison, Ranged and Slow as a table or list on its own page.
  - `journeys`: Basic or Enhanced Move; Boost; the Reserve's Boost on an Enhanced Move matching the Journey's Ether; the outcome table (Move vs MP); and the Perils Steep and Treacherous.
  - `penalty`: everything totalled and applied at once, Time Penalties before Treacherous damage; Time Penalty discards from the Deck, with damage for any shortfall; Downgrading to Soak, Armor doubled against matching Ether; Level 1 is Trashed; each card at most once; Knock Out (every untouched card Downgraded, `{n:KNOCK_OUT_DISCARD}` cards discarded, play continues).
  - An aside holds "one figure or one table", so put a second table on its own page. Keep each page "≤ 130" words.
- [X] T013 [US1] Write sections 12–15 (`upgrade_cleanup`, `region_end`, `final_journey`, `final_enemy`) in `ui/model/rulebook.gd`:
  - `upgrade_cleanup`: spend XP on Hand cards; the Reserve and Fused cards can be Upgraded; cards Downgraded this Encounter cannot; the same card several times; unspent XP is lost; then discard the Action Set, keep the Reserve, and draw back to `{n:HAND_SIZE}`.
  - `region_end`: fewer than five cards left ends the Region; the game reshuffles and deals; Trashed cards stay out; after Region 4 comes the Final Battle.
  - `final_journey`: `{n:FINAL_JOURNEY_HAND}` cards; two Action Sets; one Fuse across both; Regroup once per game; the Reserve Boost bonus once; the MP tiers table (below the first tier: lose; each tier: its Time Penalty).
  - `final_enemy`: all remaining cards; two Action Sets; Total Attack and Total Initiative; Early Damage if Initiative falls short; Armor subtracted once per matching Ether; the HP tiers table; survive the total damage by Soaking with the whole Hand.
  - Keep each page "≤ 130" words.
- [X] T014 [US1] Write sections 16–18 (`scoring`, `ethers`, `difficulty`) in `ui/model/rulebook.gd`:
  - `scoring`: 0 on a loss; on a win, the total Levels of untrashed cards after the final Soak.
  - `ethers`: each Ether's strengths and weaknesses, with `{icon:water}` etc.; Shadow's actions flex between Attack and Move.
  - `difficulty`: the six levels via `{"table": "difficulty"}` and a sentence on where they are chosen (the second setup screen); Cavalier (no Fusing) and Glass Cannon (matching Armor gives +1, not double).
  - Run the tests. Fix any page that fails `test_length` or the `_rulebook_walk` fit checks by splitting it.

**Checkpoint**: The rulebook is complete and readable from the title screen at every window size. This is the MVP.

---

## Phase 4: User Story 2 - Look up a rule in the middle of a game (Priority: P1)

**Goal**: Mid-game, Menu → How to Play → Contents → a section, then close, with the game exactly as left. Reopening returns to the last page read.

**Independent Test**: Start a game, place two cards, open the rulebook from the menu, jump via the contents, close, and confirm the Encounter, Hand and placed cards are unchanged. Reopen and confirm it is on the same page (quickstart, walkthrough step 2).

### Tests for User Story 2 ⚠️

- [X] T015 [P] [US2] Add `func _rulebook_mid_game(where: String)` to `tools/ui_check.gd` and call it from `_screens_and_overlays` after the `opens` loop:
  - **Setup**: start a seeded game (`seed 3`, `rodving`, `normal`), `_settle()`, and press `{"type": "card"}` for `ui.game.hand[0]` and `hand[1]`. Record `ui.draft.to_action()`, `ui.vs.hand.duplicate()`, `ui.game.phase` and `ui.game.deck.duplicate()`.
  - **Open**: dispatch `{"type": "menu"}`, find the menu overlay's button with text "How to Play" and emit its `pressed`, then `_settle()`. Assert a `RulebookOverlay` is on top and the menu is gone.
  - **Contents**: call `toggle_contents()` and `_inspect_screen("%s rulebook contents")`. Assert 18 section buttons. Press the "Penalty Phase" button, assert the position is `{section: 10, page: 0}`, then call `next()`.
  - **Close**: send Escape. Assert the recorded draft, hand, phase and deck all equal the current values (SC-003).
  - **Reopen**: open the rulebook again and assert `Rulebook.position` and the shown page equal the page left.
  - Then `ui._close_overlays()`.

### Implementation for User Story 2

- [X] T016 [US2] In `ui/overlays/rulebook_overlay.gd`, add the contents view:
  - **Button and grid**: a Contents button in the header (`quiet`, before Close) calls `func toggle_contents()`. That swaps the body for a `GridContainer` of one button per section labelled "*n*. *Title*", with enough columns to fit (4 columns × 5 rows for 18). Each button is ≥ `T.TAP_MIN` tall, and the current section uses `UI.style_button(b, "active")`.
  - **Choosing**: a section button calls `show_page(i, 0)` and closes the contents. A "Back to page" button closes it without moving.
  - **Footer**: Previous and Next are disabled while the contents are open.
  - **Key**: `KEY_C` calls `toggle_contents()`.
- [X] T017 [US2] In `ui/overlays/rulebook_overlay.gd` `open()`, open at `Rulebook.position` when `section_id` is empty or unknown (`Rulebook.find(section_id) == -1`), and at `{find(section_id), 0}` otherwise (data-model "Reading position" lifecycle).
- [X] T018 [P] [US2] In `ui/overlays/menu_overlay.gd` `setup()`, when `in_game`, lay the buttons out in two rows: How to Play (`quiet`, icon `book`) and Glossary in the first, Leave game and Resume in the second. How to Play calls `close()` and then emits `{"type": "rulebook"}`, like Glossary does. The non-game Settings variant keeps only Done. Run the tests.

**Checkpoint**: US1 and US2 both work: the rulebook is reachable mid-game, jumps by contents, and never disturbs the game.

---

## Phase 5: User Story 3 - Rules that match what the digital game does (Priority: P2)

**Goal**: No page asks the player to physically handle cards. Automatic steps are stated in a sentence or less, every player decision is explained with its trade-offs, and nothing out of scope appears.

**Independent Test**: `test_digital_wording` and `test_explains_decisions` pass, and a read of every page finds no physical-handling instruction (quickstart, Content review).

### Tests for User Story 3 ⚠️

- [X] T019 [P] [US3] Add two tests to `tests/test_rulebook.gd`, run against the expanded text with BBCode stripped and lowercased:
  - `test_digital_wording`: no page contains `rotate`, `flip`, `left hand`, `right hand`, `behind the`, `dized`, `co-op`, `tracking crystal` or `challenge mode`. Any sentence containing `orient` or `shuffle` must also contain `the game`.
  - `test_explains_decisions`: each of the Glossary ids `divert`, `fuse`, `boost_role`, `regroup`, `upgrade`, `reserve` and `ranged` appears as a `[[term]]` somewhere (FR-015).

### Implementation for User Story 3

- [X] T020 [US3] Revise the content in `ui/model/rulebook.gd` until T019 passes and the stories' acceptance scenarios hold:
  - **Automatic steps**: add a one-sentence `note` block ("The game … for you.") where the printed rules describe a step the game does: building and shuffling the Deck in `setup`; dealing in `setup`; drawing back to a full Hand in `upgrade_cleanup`; reshuffling in `region_end`; setting out the Dragon card in `final_journey`.
  - **Decisions**: each player decision states its trade-off. Divert costs Hand size and time; Fusing loses a card you'd keep; the Boost goes to Attack or Initiative; Regroup can be used only once; Upgrading spends XP that can't be saved; giving up the Reserve answers a Ranged enemy.
  - **Leave out**: the printed book's "Ordering your Hand", DIZED, Variants and the Tracking Crystal.
  - Run the tests.

**Checkpoint**: The text reads as a guide to the digital game, not the card game in your hand.

---

## Phase 6: User Story 4 - Pictures and links that connect the rules to the screen (Priority: P3)

**Goal**: Labelled example cards drawn as in play; a terms column whose chips open the Glossary in place; icons beside their names; outcome rules as tables.

**Independent Test**: The Mage Cards, Regions and Encounters, The Dragons and Making a Journey pages show labelled examples matching play. Pressing a terms chip shows its Glossary entry and Escape returns to the same page (quickstart, walkthrough steps 5–6).

### Tests for User Story 4 ⚠️

- [X] T021 [P] [US4] In `tests/test_view_state.gd`, add `test_encounter_model_matches_live_encounter`. Start a seeded `Game` (as the other tests there do) in the `challenge` phase, and assert that `ViewState.encounter_model(db, game.region, enc.kind, enc.index, enc.hardship, <the key card dict>)` equals `ViewState.build(...).encounter` (or `_encounter(game, db)`). This fails until T024.
- [X] T022 [P] [US4] Add `test_figures` to `tests/test_rulebook.gd`. Every `figure` block names one of `mage`, `enemy`, `journey` or `dragon`. Sections `mage_cards`, `regions`, `dragons` and `journeys` each contain a figure of kind `mage`, `enemy`, `dragon` and `journey` respectively. Sections `enemies`, `journeys`, `final_journey` and `final_enemy` each contain a `table` block (FR-016). No page's `aside` holds more than one block.
- [X] T023 [P] [US4] Extend `tools/ui_check.gd` `_rulebook_walk`:
  - **Chips**: on each page, assert that every terms chip is ≥ 44 on its short side and has `help_target` meta. These are already covered by `_inspect_screen` once the meta is set; also assert the chip count equals `Rulebook.terms(s, p).size()`.
  - **Popover**: on the `mage_cards` page, emit the first chip's `pressed`, `_settle()`, and assert a `GlossaryPopover` is on top. Run `_inspect_screen("%s rulebook help")`, send Escape, and assert the rulebook is on top and still on the same page.

### Implementation for User Story 4

- [X] T024 [US4] In `ui/model/view_state.gd`, factor `static func encounter_model(db, region: int, kind: String, index: int, hardship, key_card: Dictionary) -> Dictionary` out of `_encounter()`. It returns exactly the Region-Encounter dictionary `_encounter` builds today, with `key_card` as passed. `_encounter` then calls it with the live Key Card (`{id, name, level, element}`). Its `game.encounter()` data comes from `db.encounter(region, kind, index)`. Run the tests so T021 and the existing view-state tests pass.
- [X] T025 [P] [US4] Create `ui/widgets/rulebook_figure.gd` (`extends RefCounted`) with `static func make(kind: String, db, width: float, on_help: Callable) -> Control`:
  - **`mage`**: a `CardFace` (from `ui/widgets/card_face.gd`) for `db.mage_ids()[0]` at Level 2, at height about 238 or less (`T.CARD_ASPECT`), modelled as `inspect_overlay.gd` `_face()` does. Beside it, rows in the `card_detail.gd` `_row` style (icon 26, `T.LABEL` muted label, bold value) for Level, As Key Card (Encounter and Hardship), Initiative, Basic action, Enhanced action, Boost, Armor (Soaks) and Upgrade.
  - **`enemy` and `journey`**: an `EncounterFace` (from `ui/widgets/encounter_face.gd`) rendered from `ViewState.encounter_model(db, 1, kind, 1, null, key)`. `key` is a Mage Card whose Level 2 `stats.encounter` is `{type: kind, index: 1}`, found by scanning `db.mage_ids()` (fall back to the first card), as `{id, name, level: 2, element}`. Size it to `width` and a height that fits the aside. Connect its `intent` signal so `help` intents call `on_help`.
  - **`dragon`**: the first dragon's head crop (`UI.art_crop(Art.dragon(id), Art.head(Art.dragon(id)))` in a `UI.texture_rect`), name and title, and `DragonStats.make(d)`.
  - **Mouse**: the `CardFace` and labels ignore mouse input; `StatChip`s keep their presses.
- [X] T026 [US4] In `ui/overlays/rulebook_overlay.gd`:
  - **Figures**: render `figure` blocks with `RulebookFigure.make(kind, db, aside_width, func(d): intent.emit(d))`. Add a `db` parameter to `open()` and pass `db` from `main.gd`'s `"rulebook"` dispatch.
  - **Terms column**: under the aside, show the "Terms on this page" label (`T.LABEL`, muted), then a flow of chips, one per id in `page.terms`. Each chip is `UI.button(Glossary.entry(id).name, "quiet", <entry icon or "help">)` with `custom_minimum_size.y = 52` and `set_meta("help_target", true)`, and on `pressed` emits `{"type": "help", "id": id, "source": chip}`.
  - **Overflow**: if the chips would overflow the aside, use a `GridContainer` of two columns.
- [X] T027 [US4] Update the content in `ui/model/rulebook.gd` for the figures and icons:
  - Add the asides `{"figure": "mage"}` to `mage_cards`, `{"figure": "enemy"}` to `regions`, `{"figure": "dragon"}` to `dragons`, and `{"figure": "journey"}` to the first page of `journeys`. Move any table that shared those pages onto a page of its own.
  - Confirm each outcome rule (Attack vs HP, Move vs MP, MP tiers, HP tiers) is a `table` block.
  - Add `{icon:id}` before the names of icon-bearing terms where they first appear on a page (Ethers, Attack, Move, HP, MP, Time Penalty, XP, Armor, Boost, Initiative, Hardships, Abilities, Perils).
  - Run the tests and split any page that no longer fits.

**Checkpoint**: All four user stories work on their own and together.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T028 [P] In `tools/shot.gd` `_game()`, after `01_title`, dispatch `{"type": "rulebook"}` and shoot `01a_rulebook`. Call `toggle_contents()` and shoot `01b_rulebook_contents`. Show the `mage_cards` page (`show_page(Rulebook.find("mage_cards"), 0)`) and shoot `01c_rulebook_figure`. Show the first page of `enemies` that has a table and shoot `01d_rulebook_table`. Then `ui._close_overlays()`.
- [X] T029 [P] In `README.md` under "Status", add a bullet: a How to Play rulebook, readable from the title screen and the in-game menu, written for the digital game, with labelled example cards and Glossary links.
- [X] T030 Content review per quickstart.md "Content review":
  - Read every section beside `engine/rules.gd` and `engine/game.gd` and confirm each rule matches the engine's resolution (SC-005).
  - Confirm nothing the game implements is missing compared with `reference/rulebook.txt` (FR-011).
  - Fix wording in `ui/model/rulebook.gd`. Report any engine/rules mismatch instead of changing `engine/`.
- [X] T031 Run `./tools/test.sh` (it must end `0 failed` twice). Generate screenshots with `godot --path . -s tools/shot.gd -- build/screenshots/rulebook phone-16x9 phone-tall desktop-ultrawide` and review the rulebook shots. Walk through quickstart.md "Manual walkthrough" steps 1–7.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none. T001 and T002 run in parallel.
- **Foundational (Phase 2)**: after Setup. T003, then T004. It blocks every story.
- **US1 (Phase 3)**: after Foundational.
- **US2 (Phase 4)**: after US1's T007 and T008 (it extends the overlay and the `rulebook` intent). It doesn't need US1's content tasks, so it can proceed beside T010–T014.
- **US3 (Phase 5)**: after US1's content tasks T010–T014 (it revises that text).
- **US4 (Phase 6)**: after US1's T007 and T008. T027 also waits for T010–T014.
- **Polish (Phase 7)**: after the stories being shipped.

### Within Each Story

- Test tasks first; they must fail before the implementation tasks.
- `rulebook.gd` content tasks (T010–T014, T020, T027) touch one file, so they run in order.
- `rulebook_overlay.gd` tasks (T007, T016, T017, T026) touch one file, so they run in order.

### User Story Dependencies

- **US1 (P1)**: the MVP; depends only on Foundational.
- **US2 (P1)**: builds on the US1 overlay; testable on its own via T015.
- **US3 (P2)**: revises US1 content; testable on its own via T019.
- **US4 (P3)**: builds on the US1 overlay; testable on its own via T021–T023.

## Parallel Opportunities

- T001 ∥ T002
- T005 ∥ T006 (different files), then T007 → T008, with T009 ∥ T007
- T015 ∥ T018 ∥ T016 (different files)
- T021 ∥ T022 ∥ T023 ∥ T025 (different files); T024 after T021
- T028 ∥ T029

## Parallel Example: User Story 1

```text
Task: "T005 Extend tools/ui_check.gd with RichTextLabel checks and _rulebook_walk"
Task: "T006 Add coverage, length and not-verbatim tests to tests/test_rulebook.gd"
Task: "T009 Add the How to Play button to ui/screens/title_screen.gd"
```

## Parallel Example: User Story 4

```text
Task: "T021 test_encounter_model_matches_live_encounter in tests/test_view_state.gd"
Task: "T022 test_figures in tests/test_rulebook.gd"
Task: "T023 Chip and popover checks in tools/ui_check.gd"
Task: "T025 Create ui/widgets/rulebook_figure.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 and Phase 2.
2. Phase 3 (US1): overlay, entry point and all 18 sections.
3. **Stop and validate**: `./tools/test.sh` and quickstart walkthrough step 1.

### Incremental Delivery

1. US1: readable rulebook from the title screen (MVP).
2. US2: in-game access, contents and reading position.
3. US3: wording pass for the digital game.
4. US4: figures, terms chips, inline icons.

Each step leaves `./tools/test.sh` passing.

---

## Notes

- `[P]` means a different file with no dependency on an incomplete task.
- Do not commit unless the user asks.
- If a page fails to fit at any matrix size, split the page in the content. Never shrink text below `T.TEXT_MIN` or add scrolling.
