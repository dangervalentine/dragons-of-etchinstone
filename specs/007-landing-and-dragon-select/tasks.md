---

description: "Task list for Landing Page and Dragon Selection"
---

# Tasks: Landing Page and Dragon Selection

**Input**: Design documents from `specs/007-landing-and-dragon-select/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/screens.md, quickstart.md

**Tests**: The plan calls for a unit test of the flavour loader (`tests/test_flavor.gd`) and for the UI check (`tools/ui_check.gd`) to walk the new pages at every layout size; those are included. Run everything with `./tools/test.sh` (expect `N tests, 0 failed` and `ui check: … 0 failed`; the "Lambda capture … was freed" lines and the trailing "script errors in output" are pre-existing and not caused by this feature).

**Conventions**: GDScript in tabs; screens are `extends Control` with `setup(db, opts)`, `apply_layout(content: Rect2)`, `signal intent(data: Dictionary)` and are routed by `dispatch` in `ui/main.gd`. Match the `##` doc-comment style of the neighbouring files. Do not commit unless the user asks.

## Phase 1: Setup

- [X] T001 Create `data/flavor.json` with exactly this shape (data-model.md): `{"subtitle": <string>, "dragons": {"grimroch": <string>, "helsang": <string>, "rodving": <string>, "vuurhast": <string>}}`. Fill it with the draft text from spec.md § Clarifications, verbatim: subtitle "Cross the four Regions of Vale, hunt the dragon, and earn the name of Ether Mage."; grimroch "Its scales are stone and the water behind them deep; it turns spells aside and is seldom slower than you."; helsang "It surges back from every wound, Shadow carrying it from the hunt to the kill and back without warning."; rodving "Slow to rise and thin of hide, but its fire is the last breath most mages ever draw."; vuurhast "It comes out of the dark on the storm, already moving, gone before the thunder." (The user rewrites this text after implementation — see T020.)

## Phase 2: Foundational

- [X] T002 Create `ui/model/flavor.gd` (`extends RefCounted`) that reads `res://data/flavor.json` once into a static cache and exposes `static func subtitle() -> String` and `static func line(dragon_id: String) -> String`. Rules from data-model.md: "`subtitle` Missing or empty → the old tagline" (`"A solo card game of four Regions and one dragon."`, keep it as a `const FALLBACK_SUBTITLE`); "`dragons` Missing → card shows no flavour line" (return `""`). A missing or unparsable file must not crash: treat it as `{}`. Header doc comment says the text is project-written and meant to be edited by hand.
- [X] T003 [P] Create `tests/test_flavor.gd` (`extends "res://tests/base.gd"`, style of `tests/test_dragon_stats.gd`): assert `Flavor.subtitle()` is non-empty and differs from the fallback; for every id in `CardDB.new().dragon_ids()`, `Flavor.line(id)` is non-empty; `Flavor.line("no-such-dragon") == ""`. Run `./tools/test.sh` and confirm these pass.

## Phase 3: User Story 1 — A landing page that only welcomes the player (P1) 🎯 MVP

**Goal**: Launch opens on title, subtitle, disclaimer, How to Play / Records / Play (Play primary) and small Settings / Glossary; no dragon cards or stats.

**Independent test**: Launch; the screen is `TitleScreen` with no dragon tiles or stats; each button goes where it says. (Play emits `setup_dragon`, which only reaches the new dragon page once T010 lands; US1 and US2 ship together, as the spec says.)

- [X] T004 [US1] Rewrite `_build()` in `ui/screens/title_screen.gd` as the landing page: keep the faint `orn_rift` tear and the carved lintel title; remove the dragon crest, the "Hunt a dragon" heading, the dragon grid, `_choose`, `_refresh` and the `ChoiceTile` / `DragonStats` / `Creature` / `Art` preloads that become unused; under the lintel show `Flavor.subtitle()` (preload `res://ui/model/flavor.gd`) in `T.BODY`, `T.INK`, wrapped. Keep `var options` (set by `setup`) and `var _tiles := {}` (left empty) since `tools/ui_check.gd` reads both. Update the file's header doc comment.
- [X] T005 [US1] In `ui/screens/title_screen.gd` lay out the three main buttons in a column under the subtitle, each at least `T.TAP_MIN` tall: "How to Play" (`"normal"`, icon `"book"`) → `{"type": "rulebook"}`; "Records" (`"normal"`, icon `"trophy"`) → `{"type": "records", "from": "title"}`; "Play" (`"primary"`) → `{"type": "setup_dragon", "options": options.duplicate()}`, focused on open with `grab_focus.call_deferred()`. Keep the Settings / Glossary `"quiet"` pair and the fan-made disclaimer label (text unchanged) at the foot. The page must fit every size in `LayoutSolver.MATRIX`, including `upright-browser` and `phone-small` (centre the column; cap its width so it does not stretch across ultrawide).
- [X] T006 [US1] Update `_screens_and_overlays` in `tools/ui_check.gd`: rename the launch assertion to "launch shows the landing page", assert `ui.screen._tiles.is_empty()`, and assert the landing page holds no `DragonStats` output (e.g. no label with text "Journey" or "Battle" via the existing `_has_label`). Keep the existing Records walk (`Back returns to the title`) and rulebook walk (`the title screen is unchanged after the rulebook`) working against the landing page.

**Checkpoint**: `./tools/test.sh` passes; landing page screenshot looks right.

## Phase 4: User Story 2 — Choose a dragon from four cards, seeing only the chosen one's stats (P1)

**Goal**: Play opens a dragon page: four cards (still head, name, title, flavour line); left column shows the chosen dragon's animated crest, name, title and stats only; Continue to the rules step.

**Independent test**: From the landing page press Play; four tiles each with a flavour line; one stats block, for `options.dragon`; choosing each other card moves the stats; Continue opens `RulesScreen` with that dragon.

- [X] T007 [US2] Create `ui/screens/dragon_screen.gd` (`extends Control`, same `setup` / `apply_layout` / `intent` / `_layout` / `_content` pattern as `ui/screens/rules_screen.gd`). In `setup`, if `options.dragon` is not in `db.dragon_ids()`, set it to `db.dragon_ids()[0]` (exactly one dragon is always chosen). Right side: heading "Hunt a dragon" (`["display", 24]`, `T.GOLD`, upper-case, as the old title screen did) and a 2-column `GridContainer` of `ChoiceTile.make(d.name, d.title, UI.art_crop(art, Art.head(art)), T.ether(d.early_damage.element), null, 80.0, flavour_label)` where `flavour_label` is `UI.label(Flavor.line(id), T.LABEL, T.INK_MUTED, true)` (omit `extra` when the line is empty); store tiles in `_tiles["dragon:" + id]`; set `tile.tooltip_text = DragonStats.ladder_text(d)`; connect `pressed` to `_choose.bind(id)`.
- [X] T008 [US2] In `ui/screens/dragon_screen.gd` build the left column in its own container (`var _side: VBoxContainer`, `size_flags_stretch_ratio` ≈ 0.6, min width ~380 as the old title screen): the animated `Creature` crest of the chosen dragon (`crest.setup(Art.dragon(id), T.ether(ether).lightened(0.15), ether)`), the dragon's name (`["display_bold", 40]`, `T.GOLD`) and title, then `var stats: Control = DragonStats.make(d)`. Write `func _choose(id)`: if `id == options.dragon` return; else set `options.dragon`, set each tile's `selected = (id == options.dragon)`, and rebuild only `_side` (free its children, rebuild) — do NOT rebuild the grid, so focus stays on the pressed card.
- [X] T009 [US2] In `ui/screens/dragon_screen.gd` add the bottom row under the grid: a "Back" button (`"normal"`) → `back()`, a spacer, and "Continue" (`"primary"`, min width 240) → `intent.emit({"type": "setup_rules", "options": options.duplicate()})`. On open, focus the chosen dragon's tile. Add `func back() -> void: intent.emit({"type": "to_title", "options": options.duplicate()})` with a `##` comment. Must fit every matrix size; if the stats and cards cannot both fit on `upright-browser`, stack the side column above the grid inside a `ScrollContainer` rather than clipping (spec edge case).
- [X] T010 [US2] In `ui/main.gd`: preload `const DragonScreen = preload("res://ui/screens/dragon_screen.gd")`; add `func _show_dragons()` mirroring `_show_rules()` (clears `game`, `vs`, `play`; `setup(db, menu)`; connects `intent`; `_switch`); change the `"setup_dragon"` branch of `dispatch` to `menu = intent.options.duplicate()` then `_show_dragons()`.
- [X] T011 [US2] In `tools/ui_check.gd`: preload `DragonScreen`; after the landing assertions in `_screens_and_overlays`, press Play (`ui.dispatch({"type": "setup_dragon", "options": ui.menu})`), `await _settle()`, `_inspect_screen("%s dragons" % where)`, and assert: the screen is `DragonScreen`; `_tiles` has exactly 4 keys all starting with `"dragon:"`; exactly one tile is `selected` and it is `"dragon:" + ui.screen.options.dragon`; `ui.screen.stats` is inside the tree and the side column's name label matches the chosen dragon. Then for each other dragon id call `ui.screen._choose(id)`, `await process_frame`, `_inspect_screen`, and assert the selected tile and the side name follow. Make `_setup_steps` start from the dragon page (Continue → `RulesScreen`) instead of dispatching `setup_rules` from the landing page, and change the existing `back shows the dragon screen` / `escape on the rules screen goes back` assertions to expect `DragonScreen` (they call `ui.screen._choose(other)`, which now lives on `DragonScreen`).
- [X] T012 [P] [US2] In `tools/shot.gd` `_game`: keep `01_title` (now the landing page), then add `_press({"type": "setup_dragon", "options": ui.menu})` and `await _shot(dir + "/01e_dragons")` before `ui.start_game(...)`; dispatch `to_title` afterwards if later shots expect the landing page.

**Checkpoint**: `./tools/test.sh` passes; Play → dragon page → Continue → rules → Set Out works.

## Phase 5: User Story 3 — Move back and forth between the pages (P2)

**Goal**: Dragon page Back / Escape / system back → landing, choice kept; rules page Back → dragon page, choice kept.

**Independent test**: Play, choose a dragon, Back, Play again → same dragon; Continue, Back → dragon page with that dragon.

- [X] T013 [US3] In `ui/main.gd` `dispatch`, make `"to_title"` set `menu = intent.options.duplicate()` when the intent has `"options"`, then `_show_title()` (the ending screen's `to_title` carries none and is unchanged).
- [X] T014 [US3] In `ui/main.gd`, in both `_unhandled_key_input` (Escape) and `_notification` (`NOTIFICATION_WM_GO_BACK_REQUEST`), add `DragonScreen` to the screens whose `back()` is called (beside `RulesScreen` and `RecordsScreen`).
- [X] T015 [US3] In `tools/ui_check.gd`, on the dragon page: choose a non-default dragon, send Escape (`ui._unhandled_key_input(esc)`), assert the screen is `TitleScreen`; dispatch Play again and assert `ui.screen.options.dragon` is the dragon just chosen and its tile is selected. Also press the on-screen Back once and assert the same. Keep the rules-page back assertions from T011 (rules Back → `DragonScreen`, dragon kept, difficulty and rules kept).

**Checkpoint**: `./tools/test.sh` passes.

## Phase 6: Polish & Cross-Cutting

- [X] T016 Run `./tools/test.sh`; fix any failure introduced by this feature (re-run once if only the known-flaky phone-tall records/ending checks fail, and report them if they persist).
- [X] T017 Run `godot --path . -s tools/shot.gd -- build/screenshots/matrix` and look at `01_title.png` and `01e_dragons.png` for every size (especially `upright-browser`, `phone-small`, `desktop-ultrawide`): nothing clipped or overlapping, Play stands out, only one stats block, flavour lines readable.
- [X] T018 [P] Update `README.md` where it describes the title screen / first setup step, and mention `data/flavor.json` as the place to edit the subtitle and dragon flavour lines.
- [X] T019 Mark spec.md `**Status**` as implemented and tick the quickstart scenarios that were verified.
- [ ] T020 (User, after all of the above) Rewrite the subtitle and the four flavour lines in `data/flavor.json` by hand; relaunch, then run `./tools/test.sh` to confirm every dragon still has a line. No code change is needed.

## Implementation notes

- T005: the three main buttons sit in one row (How to Play, Records, Play widest and last) rather than a column; a column pushed the disclaimer off the bottom at 1280×720.
- T009: no ScrollContainer was needed; the side-by-side layout fits every matrix size (upright browsers get the game's usual "Widen the window" notice).

- Follow-up (user request, 2026-10-16): on the dragon screen the chosen dragon sits on its own stone card, as tall as the four cards, with the crest growing to fill it and the centred name, title and figures at its foot; Back is at the screen's bottom left and Continue at its right. The rules screen no longer shows the dragon (replacing feature 002's reminder); its slab spans the full width and Back / Set out sit where Back / Continue sit on the dragon screen. `tools/shot.gd` also saves `01f_rules`.
- Follow-up (user request, 2026-10-16): the dragon cards run by Ether, Fire, Lightning, Water, Shadow (reading order); Play opens the dragon screen with none chosen, an empty placeholder card ("Choose a dragon") and Continue disabled, replacing FR-009's "exactly one chosen" and FR-014's pre-selection of the last dragon (the choice is still kept going back from the rules screen); the chosen dragon's figures explain themselves on hover (Initiative, Early Damage, Ether, each Armor, both ladders and each tier) via `DragonStats.make(d, true)` and the new `ui/widgets/tip_box.gd`.

## Dependencies & Execution Order

- T001 → T002 → T003. T002 blocks T004 and T007.
- US1 (T004–T006) and US2 (T007–T012) both touch the flow; do US1 first (MVP). T010 depends on T007–T009; T011 depends on T010; T012 depends on T010.
- US3 (T013–T015) depends on US2 (`DragonScreen.back()` exists).
- Polish (T016–T019) after all stories. T020 is last and belongs to the user.

## Parallel Opportunities

- T003 (test) alongside T004 once T002 is done.
- T012 (shot.gd) alongside T011 (ui_check.gd) — different files.
- T018 (README) alongside T016/T017.

## Implementation Strategy

1. **MVP**: Phases 1–4 — the landing page and the dragon page together (US1 alone leaves Play with nowhere to go); the game is fully playable through the new flow.
2. **Increment 2**: Phase 5 — back navigation preserving choices.
4. Polish, screenshots, README; then hand the text file to the user (T020).
