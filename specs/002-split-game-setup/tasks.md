---

description: "Task list for Two-Step Game Setup"
---

# Tasks: Two-Step Game Setup

**Input**: Design documents from `/specs/002-split-game-setup/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/setup-screens.md, quickstart.md

**Tests**: The spec doesn't ask for test-first work, so there are no TDD tasks. The plan verifies through the existing UI check (`tools/ui_check.gd`, run by `./tools/test.sh`), and each story extends it in its own phase.

**Organization**: Tasks are grouped by user story so each one can be built and checked on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

This is a single Godot 4.7.2 project, and paths are from the repository root. Screens live in `ui/screens/`, and `ui/main.gd` is the only place that switches screens and handles intents. Follow the style of `ui/screens/title_screen.gd`: tabs, preloaded consts `T`, `UI`, `ChoiceTile`, `Game`, `Art`, `Creature`, `##` doc comments, and `signal intent(data: Dictionary)`.

---

## Phase 1: Setup

**Purpose**: None needed. The project, engine, theme and test tooling all exist. Start at Phase 2.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The second screen's shell and `main.gd` wiring. US1 needs a screen to continue to, and US2 fills it in.

- [X] T001 Create `ui/screens/rules_screen.gd` as a screen shell that matches the screen interface in `contracts/setup-screens.md`:
  - `extends Control`, with a `##` doc comment ("The second setup step: difficulty and alternate rules, then set out.").
  - The same preloads as `title_screen.gd`, plus `signal intent(data: Dictionary)` and `var db`, `var options := {}`, `var _tiles := {}`, `var _layout := Control.new()`, `var _content := Rect2(16, 16, 1248, 688)`.
  - `func setup(card_db, opts: Dictionary)`, which stores `db` and `options = opts.duplicate()`, then calls `_build()`.
  - `func apply_layout(content: Rect2)`, copied from `title_screen.gd`.
  - `func _build()`, which for now clears children and adds `_layout` holding a primary `UI.button("Set out", "primary")` that emits `{"type": "start", "options": options.duplicate()}`.
- [X] T002 In `ui/main.gd`:
  - Preload `const RulesScreen = preload("res://ui/screens/rules_screen.gd")` next to `TitleScreen`.
  - Add `func _show_rules()`, mirroring `_show_title()`: set `game = null`, `vs = {}` and `play = null`, create `RulesScreen.new()`, call `setup(db, menu)`, connect `intent` to `dispatch`, then `_switch()`.
  - In `dispatch()`, add the `"setup_rules"` case (`menu = intent.options.duplicate()`, then `_show_rules()`) and the `"setup_dragon"` case (`menu = intent.options.duplicate()`, then `_show_title()`).
- [X] T003 In `ui/main.gd` `_ready()`, check the remembered options right after `menu = Settings.last_options.duplicate()`:
  - If `menu.get("dragon")` is not in `db.dragon_ids()`, set it to `Settings.DEFAULT_OPTIONS.dragon`.
  - If `menu.get("difficulty")` is not a key of `Game.DIFFICULTY`, set it to `Settings.DEFAULT_OPTIONS.difficulty`.
  - Data-model rule: "Exactly one dragon and one difficulty are always set."

**Checkpoint**: `godot --path .` still launches to the old title screen. Running `ui.dispatch({"type": "setup_rules", "options": ui.menu})` shows the shell with a working Set out.

---

## Phase 3: User Story 1 - Choose a dragon on its own screen (Priority: P1) 🎯 MVP

**Goal**: The title screen offers only the dragon choice (plus title, Settings, Glossary and credits) and a Continue button that leads to the second step.

**Independent Test**: Launch. Only dragons are offered, with no difficulty or rule tiles. Pick a dragon and press Continue: the rules screen appears, and `ui.menu.dragon` is the picked dragon.

- [X] T004 [P] [US1] In `ui/widgets/choice_tile.gd`, add an optional last parameter `emblem_side := 56.0` to `static func make(...)` and use it in place of the hard-coded `56` in `UI.icon_rect(emblem, 56, ...)`. Existing callers keep their current look.
- [X] T005 [US1] Rework `ui/screens/title_screen.gd` `_build()`:
  - Keep the left column exactly as it is.
  - In the right column, keep the "Hunt a dragon" heading and the 2-column dragon grid, which stays `SIZE_EXPAND_FILL` vertically. Each tile uses `emblem_side` 96 and `custom_minimum_size.y` 160.
  - Remove the Difficulty heading and grid, the Alternate rules heading and the Cavalier/Glass Cannon tiles.
  - Replace the bottom row with a right-aligned `UI.button("Continue", "primary")` with `custom_minimum_size.x = 240`, which emits `{"type": "setup_rules", "options": options.duplicate()}`.
  - Focus it with `grab_focus.call_deferred()`.
  - Update the file's `##` doc comment to "The title screen and first setup step: choose a dragon, then continue."
- [X] T006 [US1] In `ui/screens/title_screen.gd`:
  - Delete `DIFFICULTIES` and `_difficulty_text()`; T008 moves them to `rules_screen.gd`.
  - Reduce `_refresh()` to the dragon tiles only.
  - Simplify `_choose(key, value)` to `_choose(id)` for dragons only: set `options.dragon` and call `_build()`.
  - Remove the now-unused `Game` preload if nothing else uses it.
- [X] T007 [US1] In `tools/ui_check.gd` `_screens_and_overlays()`, after `_inspect_screen("%s title" % where)`, add:
  - `_ok(ui.screen.get_script() == load("res://ui/screens/title_screen.gd"), "%s: launch shows the dragon screen" % where)`.
  - `_ok(not ui.screen._tiles.keys().any(func(k): return not k.begins_with("dragon:")), "%s: dragon screen offers only dragons" % where)`.

**Checkpoint**: The dragon screen passes `./tools/test.sh` at every matrix size, and Continue reaches the Phase 2 shell.

---

## Phase 4: User Story 2 - Choose difficulty and alternate rules together, then set out (Priority: P1)

**Goal**: The second screen shows the chosen dragon, all six difficulty levels and both alternate rules, and Set out starts the game with all choices.

**Independent Test**: From the rules screen, pick a difficulty, toggle each rule and press Set out. The game starts with that dragon, difficulty and those rules, and `Settings.last_options` matches.

- [X] T008 [US2] In `ui/screens/rules_screen.gd`, move in from the old title screen:
  - `const DIFFICULTIES` (the six `[key, label]` pairs, unchanged).
  - `func _difficulty_text(key)` (unchanged).
  - `func _heading(text)` (unchanged).
- [X] T009 [US2] Build the full layout in `ui/screens/rules_screen.gd` `_build()`, with the same root `UI.hbox(T.XL)` inside `_layout` as the title screen.
  - **Left column**: `UI.vbox(T.M)`, `custom_minimum_size.x = 380`, `size_flags_stretch_ratio = 0.6`. It holds the chosen dragon (FR-006):
    - A `Creature` crest of 170×170, set up as the title screen's crest from `db.dragon(options.dragon)`.
    - `d.name` in `["display_bold", 54]` `T.GOLD`.
    - `d.title` in `T.BODY` `T.INK`.
    - `"Initiative %d · early damage %d"` in `T.LABEL` `T.INK_MUTED`.
    - A `UI.spacer()`.
  - **Right column**: `UI.vbox(T.S)` expanding, containing:
    - The "Difficulty" heading and a 3-column `GridContainer` of `ChoiceTile.make(label, _difficulty_text(key))` tiles, with separations `T.S` and vertical `SIZE_EXPAND_FILL`, stored as `_tiles["difficulty:" + key]`.
    - The "Alternate rules" heading and a `UI.hbox(T.S)` row of `ChoiceTile.make("Cavalier", "No Fusing")` and `ChoiceTile.make("Glass Cannon", "Matching Armor Soaks only +1")`, stored as `_tiles["cavalier"]` and `_tiles["glass_cannon"]`.
    - A bottom `UI.hbox(T.S)` with `custom_minimum_size.y = T.TAP_MIN`, holding a `UI.spacer()` and then `UI.button("Set out", "primary")` with `custom_minimum_size.x = 240`, which emits `{"type": "start", "options": options.duplicate()}` and is focused with `grab_focus.call_deferred()`.
- [X] T010 [US2] In `ui/screens/rules_screen.gd`, add `_choose(key, value)` and `_refresh()` following the old title screen. Data-model rules: "Exactly one dragon and one difficulty are always set"; each rule toggles on its own.
  - `_choose`: a `null` value toggles the bool, otherwise sets `options[key]`; then call `_refresh()`, with no rebuild.
  - `_refresh`: marks `selected` on the difficulty tiles and the two rule tiles.
  - Connect each tile's `pressed` to `_choose.bind(...)`, and call `_refresh()` at the end of `_build()`.
- [X] T011 [P] [US2] In `tools/ui_check.gd` `_screens_and_overlays()`, after the dragon screen checks, add:
  - `ui.dispatch({"type": "setup_rules", "options": ui.menu})`, `await _settle()`, then `_inspect_screen("%s rules" % where)`.
  - `_ok` checks that the screen is `rules_screen.gd`, and that `_tiles` holds all six `difficulty:*` keys plus `cavalier` and `glass_cannon`.
  - Open settings over it, inspect it, then close it with `ui._close_overlays()`.
  - Set out: `ui.screen._choose("difficulty", "hard")`, `ui.screen._choose("cavalier", null)`, then `ui.dispatch({"type": "start", "options": ui.screen.options})`.
  - `_ok` checks that `ui.game != null` and that `Settings.last_options` has `difficulty == "hard"` and `cavalier == true`.
  - Then reset state with `ui.dispatch({"type": "to_title"})` before the existing `ui.start_game(...)` overlay checks.
- [X] T012 [P] [US2] In `tools/design_shots.gd` `_game()`, after `await _shot("title")`, add `ui.dispatch({"type": "setup_rules", "options": ui.menu})` and `await _shot("rules")`.

**Checkpoint**: Launch → Continue → Set out plays a game with remembered options (SC-001: two presses). `./tools/test.sh` passes.

---

## Phase 5: User Story 3 - Go back to change the dragon (Priority: P2)

**Goal**: The player can return from the rules screen to the dragon screen with the on-screen Back button, Escape or Android system back, without losing any choice.

**Independent Test**: On the rules screen, change the difficulty and turn on a rule, then go back. Pick a different dragon and continue: the difficulty and rule are unchanged.

- [X] T013 [US3] In `ui/screens/rules_screen.gd`:
  - Add `func back() -> void`, which emits `{"type": "setup_dragon", "options": options.duplicate()}`.
  - In the bottom row, before the spacer, add `UI.button("Back", "quiet")` with `custom_minimum_size.x = 200`, whose `pressed` calls `back`.
- [X] T014 [US3] In `ui/main.gd` `_unhandled_key_input()`, in the `KEY_ESCAPE` branch after the overlay check, add `elif screen != null and screen.get_script() == RulesScreen: screen.back()` before the play-screen branches. Contract: Escape on the rules screen is "same as Back".
- [X] T015 [US3] Handle Android system back in `ui/main.gd`:
  - In `_ready()`, add `get_tree().quit_on_go_back = false`.
  - In `_notification()`, handle `NOTIFICATION_WM_GO_BACK_REQUEST`:
    - Skip the animator if it is playing.
    - Otherwise, if `_top_overlay()` is not null, close it.
    - Otherwise, if the screen is a `RulesScreen`, call `screen.back()`.
    - Otherwise, call `get_tree().quit()`, so every other screen still quits as today (research R4).
- [X] T016 [US3] In `tools/ui_check.gd`, add a round-trip check in `_screens_and_overlays()` before Set out:
  - Record `var kept: Dictionary = ui.screen.options.duplicate()` after changing the difficulty and rule.
  - Call `ui.screen.back()` and `await _settle()`, then `_ok` that the screen is the dragon screen.
  - Pick a different dragon with `ui.screen._choose(<another id from ui.db.dragon_ids()>)`, then `ui.dispatch({"type": "setup_rules", "options": ui.screen.options})` and `await _settle()`.
  - `_ok` that `ui.screen.options.difficulty == kept.difficulty and ui.screen.options.cavalier == kept.cavalier` (SC-005).
  - Also check that Escape goes back: send an Escape `InputEventKey` through `ui._unhandled_key_input`, then `_ok` that the screen is the dragon screen, then dispatch `setup_rules` again.

**Checkpoint**: All three stories work; `./tools/test.sh` passes at every matrix size.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T017 [P] Update the "Title screen" section of `specs/001-ui-polish/contracts/screens-and-interaction.md` to point at `specs/002-split-game-setup/contracts/setup-screens.md`, and add the Rules row to its screen table.
- [X] T018 Run `./tools/test.sh` and confirm `ui check: N checks, 0 failed` with no script errors.
- [X] T019 Run `godot --path . -s tools/design_shots.gd` and review the `title` and `rules` shots for layout and legibility.
- [ ] T020 Walk the by-hand checks in `specs/002-split-game-setup/quickstart.md`, using the `install-on-emulators` skill to check Android system back and the iOS layout.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: T001 → T002 (T002 preloads the file T001 creates). T003 is independent of both but is also in `main.gd`, so do it after T002.
- **US1 (Phase 3)**: Depends on Phase 2, because Continue needs `setup_rules` to land somewhere.
- **US2 (Phase 4)**: Depends on Phase 2. It can be built alongside US1, apart from shared `tools/ui_check.gd` edits (T007 before T011).
- **US3 (Phase 5)**: Depends on US2 (it adds to the rules screen's bottom row and to the rules checks in `ui_check.gd`).
- **Polish (Phase 6)**: After all stories.

### Within Each Story

- Screen code before its UI check task.
- US1: T004 → T005 → T006 → T007.
- US2: T008 → T009 → T010, then T011 and T012.
- US3: T013 → T014 → T015 → T016.

### Parallel Opportunities

- T004 (`choice_tile.gd`) can run alongside the Phase 2 tasks.
- US1 (T005–T006, `title_screen.gd`) and US2 (T008–T010, `rules_screen.gd`) touch different files and can run in parallel once Phase 2 is done.
- T011 (`ui_check.gd`) and T012 (`design_shots.gd`) can run in parallel.
- T017 can run alongside T018–T020.

## Parallel Example: after Phase 2

```text
Agent A: T004, T005, T006   (ui/widgets/choice_tile.gd, ui/screens/title_screen.gd)
Agent B: T008, T009, T010   (ui/screens/rules_screen.gd)
Then:    T007 → T011, with T012 alongside
```

## Implementation Strategy

### MVP

Phase 2, then US1 and US2 together. Both are P1, and the split isn't playable without both screens. Stop and validate with `./tools/test.sh` and a launch → Continue → Set out run.

### Incremental Delivery

1. Phase 2: the shell is reachable, and nothing visible changes yet.
2. US1: the dragon screen is split out, and Continue leads to the bare Set out shell. Playable.
3. US2: the full rules screen. This completes the feature as the user described it.
4. US3: Back, Escape and Android back. Closes the "can't change my dragon" trap.
5. Polish: docs, shots, device checks.
