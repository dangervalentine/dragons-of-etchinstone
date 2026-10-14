---

description: "Task list for the UI polish and presentation overhaul"
---

# Tasks: UI Polish and Presentation Overhaul

**Input**: Design documents from `/specs/001-ui-polish/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Scope note**: **Landscape only.** There is one arrangement, minimum design size
1280 x 720, on every target. No portrait arrangement is built. The design documents
were amended to match before these tasks were generated.

**Tests**: Included for the pure UI model (`ui/model/`) and as a UI check script,
because the plan (research R11) and SC-012 depend on them. Widgets and visuals are
verified with the screenshot matrix and quickstart.md, not unit tests.

**Organization**: Tasks are grouped by user story so each story can be implemented
and verified on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: The user story the task belongs to (US1 to US6)
- All paths are relative to the repository root

## Rules that apply to every task

- Do not modify anything in `engine/`, `data/cards.json`, or the existing
  `tests/test_card_db.gd`, `tests/test_game.gd`, `tests/test_playthrough.gd`,
  `tests/test_rules.gd`.
- Take every size, colour, font and duration from `ui/theme/tokens.gd`
  (contracts/design-tokens.md). No literals in widgets.
- Minimum text size 22 units; minimum interactive size 88 units on the shorter side.
- Widgets render a `ViewState` and emit intents. Only `ui/model/view_state.gd` reads
  the `Game` object.
- Nothing scrolls.
- Match the existing GDScript style: tabs, typed where the current code is typed,
  `##` doc comments on scripts and public functions, code-built nodes.
- Run `./tools/test.sh` after every task that touches code; it must exit 0.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Branch, folders, assets and project settings.

- [X] T001 Create and switch to git branch `001-ui-polish` from `main`; add `specs/` to the first commit on the branch only if the user asks for a commit — done: branch created, nothing committed
- [X] T002 Create the folders `ui/theme/`, `ui/model/`, `ui/screens/`, `ui/widgets/`, `ui/overlays/`, `ui/fx/shaders/` and `art/fonts/`
- [X] T003 [P] Add fonts to `art/fonts/`: Cinzel (Regular, SemiBold, Bold, or the variable file) and Alegreya Sans (Regular, Medium, Bold) from the Google Fonts repository, each with its `OFL.txt` saved as `art/fonts/OFL-Cinzel.txt` and `art/fonts/OFL-AlegreyaSans.txt`; let Godot import them. If Alegreya Sans cannot render lining figures through a `FontVariation` OpenType feature (`lnum`), use Source Sans 3 instead and note the swap in `specs/001-ui-polish/research.md` R7 — done; lining figures render on desktop, Android and iOS; not yet checked in a browser (see T083)
- [X] T004 Switch the project to landscape in `project.godot`: `window/size/viewport_width=1280`, `viewport_height=720`, `window_width_override=1280`, `window_height_override=720`, `window/handheld/orientation=4` (sensor landscape); keep `stretch/mode="canvas_items"` and `aspect="expand"`. Check `export_presets.cfg` for any per-platform orientation keys (iOS `orientation/*`) and set them to allow landscape left and right only
- [X] T005 [P] Extend `tools/gen_icons.py` with the icons listed in contracts/design-tokens.md under Icons (deck, discard, trash, reserve, spell, element_role, fuse, divert, regroup, inspect, menu, settings, help, skip, victory, narrow_victory, loss, down_arrow, sigil_fire, sigil_water, sigil_lightning, sigil_shadow, sigil_grimroch, sigil_helsang, sigil_rodving, sigil_vuurhast), in the same single-colour style and viewBox as the existing set; run it to write the SVGs to `art/icons/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Tokens and theme, the pure UI model, the layout solver, and a root that
hosts screens. After this phase the game starts on the new structure with empty
regions in the right places.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T006 [P] Create `ui/theme/tokens.gd` (`extends RefCounted`, constants only) holding every token in contracts/design-tokens.md: the space, radius and `TAP_MIN := 88` values; type tokens as `{font, size}` pairs; the colour roles with the listed hex values; `ETHER := {fire, water, lightning, shadow}`; the motion durations and `SEQUENCE_MAX := 3.0`
- [X] T007 Create `ui/theme/theme.gd`: static functions that load the fonts from `art/fonts/` (with lining and tabular figures enabled), build one Godot `Theme` from the tokens (Button, Label and PanelContainer styles for idle, hover, pressed, focus with a 3-unit gold ring, and disabled at 45% opacity), and a cached `icon(name) -> Texture2D` loader for `art/icons/`; plus small builders `label(text, type_token, color)`, `panel(bg, border)` and `icon_rect(name, side, color)` to replace the helpers at the bottom of the current `ui/main.gd`
- [X] T008 [P] Create `ui/model/turn_draft.gd` (`extends RefCounted`) from the loose variables in the current `ui/main.gd` (`sets`, `active`, `boost_to`, `fuse`, `fuse_pick`, `mode`, `ranged_discard`, `picks`), with fields exactly as data-model.md TurnDraft and methods: `reset()`, `set_count_for(phase)`, `place(card_id)`, `take_back(card_id)`, `select_slot(set_index, role)`, `toggle_boost_to(set_index)`, `begin_mode(mode)`, `cancel_mode()`, `pick_for_fuse(card_id, card_db) -> String`, `choose_fuse_element(element)`, `unfuse()`, `toggle_pick(card_id)`, `slot_of(card_id)`, `is_filled(phase)`, `to_action(phase) -> Dictionary`. Enforce the rules verbatim: "A card fills at most one role across all sets; a fused-bottom card fills none", "Filling a slot advances `active_slot` to the next empty slot", "Any mode can be cancelled, returning to `none` without changing the game". `to_action` must return exactly the dictionaries `_current_action()` returns today for one and two sets
- [X] T009 [P] Create `tests/test_turn_draft.gd` (extends `tests/base.gd` like the existing tests) covering: place and auto-advance, take back, one card one role across two sets, fuse flow including the different-Ether refusal, cancel from every mode leaves the draft as it was, and `to_action` output for one set and two sets
- [X] T010 Create `ui/model/view_state.gd`: `static func build(game, draft, db) -> Dictionary` returning the ViewState of data-model.md, including `cards` (CardModel with `state`, `role`, `fuse`, `eligible`, `reason`, `note`, `selection_order`), `encounter` (EncounterModel for enemy, journey, final_journey, final_enemy), `prompt`, `secondary_actions`, `soak`, `xp`, `piles`, `stage`, `progress` and `ending`. This is the only file allowed to read `game._soak_value`, `game._reserve` and `game._regrouped`. `build` must be deterministic: "a ViewState built twice from the same game and draft is identical". Also `static func snapshot(game) -> Dictionary` returning just `zones`, card Levels, `phase`, `region`, `xp`, `damage_due` for diffing
- [X] T011 Add the PreviewModel to `ui/model/view_state.gd`: `static func preview(game, draft) -> Dictionary` with `status` (`incomplete` with the list of empty slots, `ready`, or `blocked` with the reason), `comparisons`, `verdict`, `rewards`, `costs`, `fatal` and `changed` (figures that differ from a previous PreviewModel passed in). Every figure must come from `game.preview()` or `game.preview_final()`: "the model reshapes; it never recomputes". Map an engine `{"error": ...}` for a merely unfilled draft to `incomplete`, not `blocked`
- [X] T012 Create `tests/test_view_state.gd`: build twice and compare equal; card states for a placed card, a reserve card, a fused pair, a Downgraded card and an ineligible card with its reason; EncounterModel for an enemy with an Ability and a journey with a Peril; PreviewModel figures equal the engine's `preview()` result for ten seeded positions; `incomplete` names the empty slots; `fatal` is true for a Final Battle draft below the first tier
- [X] T013 [P] Create `ui/model/layout_solver.gd`: `static func solve(window_px: Vector2, safe_px: Rect2, hand_count: int, set_count: int, screen_scale: float) -> Dictionary` returning the LayoutPlan of data-model.md (`scale`, `design_size`, `regions` for header, encounter, preview, slots, hand, actions, commit, `card_size`, `hand_rows`, `undersized`). Scale is `min(safe.w / 1280, safe.h / 720)`; the design size grows on the unconstrained axis up to 1760 x 990 and is centred beyond that. Regions follow contracts/screens-and-interaction.md: header 56 across the top, 16 margins, left column about one third (420 at minimum) holding encounter above preview, right column holding slots, hand, and one bottom row with actions on the left and commit in the bottom right corner. Use the budgets in research.md R5 for one set with four cards and for two sets side by side with seven cards in rows of four and three. Extra height goes to card size first. `undersized` is true when the window is taller than wide or the scale puts 22-unit text under about 9 points
- [X] T014 [P] Create `tests/test_layout_solver.gd`: for each row of the size matrix in quickstart.md assert the expected design size or `undersized` value; every region lies inside the safe area; regions do not overlap; `card_size` is at least 140 x 188; commit is at least 88 tall; the same region order holds for (4 cards, 1 set) and (7 cards, 2 sets); a safe area inset on the left and one inset on the right both keep regions clear
- [X] T015 Replace `ui/main.gd` with a root (`extends Control`) that: applies the theme from `ui/theme/theme.gd`; draws the backdrop; owns `game`, a `TurnDraft` and the current `ViewState`; calls the layout solver on start and on `get_window().size_changed` and sets `content_scale_factor` and the screen's region rectangles from the plan; hosts one screen at a time and an overlay layer above it; exposes `start_game(opts)` as today; and handles intents through one `dispatch(intent: Dictionary)` function that either edits the draft or calls the engine, then rebuilds the ViewState and passes it to the screen. Keep the public names `tools/shot.gd` uses (`menu`, `game`, `start_game`) or update that tool in the same task. Move the old file's screen-building code out; it is replaced by the tasks below
- [X] T016 Create `ui/screens/play_screen.gd`: a Control with the seven named regions as child Controls, a `apply_layout(plan)` that positions them from the LayoutPlan, and a `render(view_state)` that will forward to region widgets as they are added. Regions keep their space when empty. No ScrollContainer anywhere
- [X] T017 [P] Create `ui/screens/title_screen.gd` as a functional port of the current menu (dragon, difficulty, alternate rules, start, credit line) using theme styles and 88-unit controls in a landscape two-column layout; it emits a `start` intent with the chosen options. User Story 5 replaces its presentation
- [X] T018 [P] Create `ui/screens/ending_screen.gd` as a functional port of the current end screen (won or lost headline, score, New game) using theme styles. User Story 5 replaces its presentation
- [X] T019 Create `tools/ui_check.gd` (`extends SceneTree`, run headless): instantiates `scenes/main.tscn` at each window size in the quickstart.md matrix, and for now asserts that the solver's regions as applied to `PlayScreen` are inside the viewport and that the title screen's controls are at least 88 units; prints one line per failure and exits non-zero on any. Add it to `tools/test.sh` as a second step after the test runner, with the same script-error grep
- [X] T020 Update `tools/shot.gd` to take screenshots at every size in the quickstart.md matrix into `<out>/<size-name>/`, driving the game through `dispatch` intents instead of the old private handlers

**Checkpoint**: `godot --path .` opens a landscape window, the title screen starts a
game, and the play screen shows seven empty regions that resize with the window.
`./tools/test.sh` passes.

---

## Phase 3: User Story 1 - Read the turn at a glance (Priority: P1) 🎯 MVP

**Goal**: A fixed seven-region landscape play screen on which the Encounter, the
Action Set, a visual outcome preview, the Hand and the commit control are all
visible at once, for every step from setup to the Final Battle.

**Independent Test**: Start a game at 1280 x 720, reach the first Encounter, and
confirm all regions are visible together and the verdict can be read in a few
seconds (quickstart.md steps 1 to 3). A full game can be played to the end.

### Tests for User Story 1

- [X] T021 [US1] Extend `tools/ui_check.gd` to play a seeded game to completion through `dispatch` intents (place the first legal cards, soak with the first sufficient cards, upgrade nothing) at 1280 x 720 and at 2532 x 1170, asserting at every step that all seven regions and every visible control are inside the viewport and safe area, that no control is under 88 units, and that the final `game.phase`, `game.cards` Levels and zones equal those of the same choices applied directly to a second `Game` with the same seed (SC-012)

### Implementation for User Story 1

- [X] T022 [P] [US1] Create `ui/widgets/stat_chip.gd`: a number drawn on an icon shape (port of `_chip` and `_pill` from the old `ui/main.gd`) taking `{icon, value, color, ink, glossary_id}`, sized from tokens, with a `pressed` signal carrying `glossary_id` (wired in User Story 6)
- [X] T023 [P] [US1] Create `ui/widgets/header_bar.gd`: stage name (`Region N · name` or `Final Battle · dragon, title`) in `type.heading`, a progress indicator from `ViewState.progress`, three pile counters (deck, discard, trash) each an icon plus count with a stable node name so cards can later fly to them, and a menu button (88 units) that emits a `menu` intent
- [X] T024 [P] [US1] Create `ui/widgets/encounter_face.gd`: renders an EncounterModel of kind enemy or journey as a framed face in the Encounter's Ether colour with its Ether icon: title, targets as stat chips (enemy: HP, Initiative, Attack with element, each Armor entry; journey: MP with element, time penalty), XP reward, and one row per effect (Hardship, Ability, Peril) with icon and name. Laid out for the left column (about 420 x 340 at minimum size) and growing with the region
- [X] T025 [P] [US1] Create `ui/widgets/dragon_face.gd`: renders the final_journey and final_enemy EncounterModels as a tier ladder of three rungs (Move needed and time penalty; or Attack needed and damage taken), with the dragon's name, title, Ether colour and icon, and for the Final Enemy its Initiative, early damage, Armor entries and any carried damage. A `set_reached(tier)` call highlights the rung the current preview reaches
- [X] T026 [P] [US1] Create `ui/widgets/preview_panel.gd` rendering a PreviewModel per contracts/screens-and-interaction.md, Outcome preview: for `incomplete` the names of the empty slots; for `ready` one comparison row per entry (label, player value in `type.numeral_l`, target, a bar filled proportionally, result), the verdict in `type.banner` with its icon and state colour, rewards on one side and each cost as an icon and number on the other; for `fatal` a defeat warning that replaces the verdict. Figures listed in `changed` pulse once. Also shows the current `prompt` text when the step is not a challenge
- [X] T027 [P] [US1] Create `ui/widgets/slot_row.gd`: one Action Set as three slots (Spell, Element, Boost), each at least 88 units, showing the role icon and name when empty and a compact card summary (name, Ether icon, the value that role contributes) when filled; the active slot is ringed in gold; tapping emits `select_slot`, tapping a filled slot emits `take_back`; when the Encounter is an enemy the Boost slot carries a toggle between Attack and Initiative that emits `toggle_boost_to`. Accepts a set index so two rows can sit side by side in the Final Battle
- [X] T028 [P] [US1] Create `ui/widgets/card_view.gd`: one node per card id that persists while the card is visible, rendering a CardModel with a first-pass face (crown and Level, name, Ether icon, Key Card strip, then Initiative, basic action, enhanced action, Boost, Armor down the left edge, Upgrade cost at the foot: the arrangement of `_card` in the old `ui/main.gd`, at token sizes), a role or state ribbon, 45% opacity plus the `reason` caption when not eligible, the `note` when present, and a `pressed` signal with the card id. User Story 2 replaces the face drawing
- [X] T029 [US1] Create `ui/widgets/hand_tray.gd`: owns the `card_view` nodes for the Hand, keyed by card id (create on arrival, reuse while present, free on departure), lays them out in one row for up to four cards or two rows of four and three for five to seven at the LayoutPlan's `card_size`, and forwards card presses as `card` intents
- [X] T030 [P] [US1] Create `ui/widgets/action_bar.gd`: the secondary actions from `ViewState.secondary_actions` (Fuse or Unfuse, Divert with remaining count, Regroup, Give up Reserve, Cancel when a mode is active) as 88-unit buttons that are hidden when not `visible`, show the `reason` when disabled, and are highlighted when `active`; and the single primary action from `ViewState.prompt` in gold in the bottom right corner, restyled as a warning when the preview is `fatal`. Fuse is absent under the Cavalier rule
- [X] T031 [P] [US1] Create `ui/widgets/soak_meter.gd`: damage owed with its element icon, a bar that fills with `ViewState.soak.total` toward the amount owed, and a "covered" state; shown in the preview region during penalty, poison and final_soak
- [X] T032 [P] [US1] Create `ui/widgets/xp_purse.gd`: XP available in `type.numeral_l` with the XP icon and a one-line recap of the Encounter just resolved (verdict and costs from `game.result` via the ViewState); shown in the preview region during the upgrade phase
- [X] T033 [US1] Wire the regions in `ui/screens/play_screen.gd`: header_bar in header; encounter_face or dragon_face in encounter; preview_panel, soak_meter or xp_purse in preview according to the Steps table in contracts/screens-and-interaction.md; one or two slot_rows in slots (hidden content, kept space, outside challenge and Final Battle steps); hand_tray in hand (showing `setup_offer` cards during setup); action_bar across actions and commit. `render(view_state)` updates widgets in place and never frees and rebuilds a region
- [X] T034 [US1] Implement every intent in `ui/main.gd` `dispatch`: `card` (routes by phase and draft mode exactly as `_on_hand_card`, `_on_pick_card` and `_on_upgrade_card` do today), `select_slot`, `take_back`, `toggle_boost_to`, `mode`, `fuse`, `fuse_element`, `give_up_reserve`, `cancel`, `primary` (confirm setup, play, play final, confirm soak, finish upgrade), `start`, `new_game`. An engine refusal is shown as a message beside the control pressed and changes nothing. The Ether choice for a fuse appears in the actions region as four Ether buttons with icons
- [X] T035 [US1] Verify the fit at 1280 x 720 for a Region Encounter, the setup step with seven offered cards, both soak phases, the upgrade step and both Final Battle stages by running `godot --path . -s tools/shot.gd -- build/screenshots/matrix` and reading the `phone-16x9` images; adjust `ui/model/layout_solver.gd` budgets (and its tests) until nothing is clipped. If the Final Battle does not fit, move the commit control under the preview for that step as research.md R5 allows

**Checkpoint**: A complete game is playable in landscape with every region visible
at 1280 x 720. This is the MVP.

---

## Phase 4: User Story 2 - Cards that look and handle like cards (Priority: P2)

**Goal**: Mage Cards drawn as cards in the printed layout, with every state visible
on the card, a fused pair shown as one piece, and an inspect view.

**Independent Test**: Lay a Hand beside the scans in `reference/sheets-official/`
and confirm each value sits in the corresponding position; confirm each card state
is distinguishable without reading a label (quickstart.md steps 4 to 6).

- [X] T036 [P] [US2] Create `ui/fx/shaders/ether_field.gdshader`: a single-pass, texture-free `canvas_item` shader that fills a card's field with a subtle concentric swirl pattern in a uniform Ether colour, darkening toward the edges; must compile under the Compatibility renderer and run in the web export
- [X] T037 [P] [US2] Create `ui/fx/shaders/backdrop.gdshader`: a single-pass vignette over `bg.base` for the screen background; apply it in `ui/main.gd`
- [X] T038 [US2] Create `ui/widgets/card_face.gd`: a Control that draws a Mage Card face at any size from a CardModel, following the printed card's arrangement (see `reference/sheets-official/o1a.png`): a dark top band with the Level crown and the name in `type.card_name` beside the Ether icon; under it the Key Card strip (Encounter type icon, index, Hardship icon); the Ether field from T036 with the card's Ether sigil large and faint in the centre; down the left edge in this order Initiative banner, basic action plate, enhanced action plate in the enhanced action's Ether colour with its Ether icon, Boost plate, Armor shield (coloured with its Ether icon when the Armor has an element); the Upgrade cost with the XP icon at the foot, or "max". Only the current Level is drawn. Numerals in `type.numeral`, scaled down with the card but never under 22 units at the minimum Hand card size
- [X] T039 [US2] Use `card_face.gd` inside `ui/widgets/card_view.gd` and implement every state in the Elevation and state table of contracts/design-tokens.md: available, assigned (lifted, gold edge, ribbon with the role's icon and set number when there are two sets), reserve (dashed edge, ribbon), selected (gold edge, order number), downgraded (cracked-edge overlay and down-arrow on the crown), unavailable (desaturated, 45% opacity, reason caption). States must combine (for example assigned and downgraded) and none may rely on text or colour alone
- [X] T040 [US2] Show a fused pair as one piece in `ui/widgets/hand_tray.gd` and `ui/widgets/card_view.gd`: the bottom card sits behind and offset from the top card with its edge and name visible, the top card carries a badge with the chosen Ether icon, the pair occupies one Hand position plus the offset, and tapping the bottom card explains that it is tucked. While picking for a fuse, picked cards show the selected state
- [X] T041 [US2] Create `ui/overlays/inspect_overlay.gd`: a dimmed full-screen overlay showing the card large, with three faces side by side from `db.mage_level`: the Level below (labelled as what a Downgrade leaves, or "Trashed" at Level 1), the current Level (emphasised), and the next Level with its Upgrade cost (or "Highest Level"); values that differ from the current Level are highlighted. Dismissed by tapping outside, a close button, or Escape. It never changes the draft or the game
- [X] T042 [US2] Add press-and-hold (0.35 s) and right-click to `ui/widgets/card_view.gd` emitting an `inspect` intent, and open the overlay from `ui/main.gd`; a hold must not also count as a tap. Make cards in slots and setup offers inspectable the same way — done for Hand cards and setup offers; cards shown in slots are summaries, not cards, and open no inspect view
- [X] T043 [US2] Restyle `ui/widgets/encounter_face.gd` and `ui/widgets/dragon_face.gd` as card faces using the same frame, top band and Ether field as `card_face.gd`, with the Region's or dragon's sigil in the field, and show the Key Card's name and Level in the top band so the Encounter reads as the face of that card (spec User Story 2, scenario 6)
- [X] T044 [US2] Check SC-010: for the eight cards on `reference/sheets-official/o1a.png` at Levels 1 and 2, compare a screenshot of each rendered card with the scan and confirm every value appears in the corresponding position; fix `ui/widgets/card_face.gd` where it does not

**Checkpoint**: Cards are recognisable against the physical cards and every state is
visible on the card.

---

## Phase 5: User Story 3 - Motion that shows what happened (Priority: P3)

**Goal**: Committing plays an ordered, skippable resolution sequence; every card
movement is shown; controls and screens respond with motion; a reduced-motion mode
shows the same information without travel.

**Independent Test**: Play an enemy and a journey to a complete victory, a narrow
victory and a loss, and confirm an observer can say what happened from the sequence
alone; tap during a sequence and confirm it completes at once (quickstart.md steps
7 to 10).

### Tests for User Story 3

- [X] T045 [P] [US3] Create `tests/test_sequencer.gd`: for a seeded game played to the end, at every engine action build the StepList and assert that "applying every step of a list to the before state yields the after state exactly" (zones and Levels); that step kinds appear in the order of the table in data-model.md; that total duration is at most 3.0; that a Knock Out produces `knock_out`, a Level 1 Downgrade produces `trash`, a Region change produces `gather_shuffle` then `stage_banner` then `draw`, and a draft-only change produces an empty list

### Implementation for User Story 3

- [X] T046 [US3] Create `ui/model/sequencer.gd`: `static func build(before: Dictionary, intent: Dictionary, result: Dictionary, after: Dictionary) -> Array` producing Steps (`kind`, `cards`, `from`, `to`, `values`, `anchor`, `duration`) for every kind in the data-model.md table, derived as that table states, using the snapshots from `view_state.snapshot`. Durations come from the motion tokens; when the sum exceeds `SEQUENCE_MAX` compress all durations proportionally. Include `static func apply(state, step) -> Dictionary` used by the test
- [X] T047 [P] [US3] Create `ui/model/settings.gd`: loads and saves `user://settings.cfg` with `motion` (`system`, `reduced`, `full`; default `system`) and `last_options`; `static func reduced_motion() -> bool` resolves `system` with `DisplayServer.accessibility_should_reduce_animation()` (treat -1 as unknown) and, on web, falls back to `JavaScriptBridge.eval` of the `prefers-reduced-motion` media query
- [X] T048 [P] [US3] Create `ui/fx/flight_layer.gd`: a full-rect Control above the screen and below overlays in which a `card_view` (or a card-back placeholder for cards the player does not see face up) can be positioned freely; `fly(node, from_global_rect, to_global_rect, duration) -> Tween` reparents the node in, tweens position and size, and hands it back or frees it at the end
- [X] T049 [P] [US3] Create `ui/fx/number_roll.gd`: a Label helper that counts from one integer to another over a duration and jumps straight to the value in reduced motion — done inside `ui/widgets/preview_panel.gd` (totals count up) and `ui/screens/ending_screen.gd` (score rolls up); no separate file was needed
- [X] T050 [US3] Create `ui/fx/animator.gd`: `play(steps, screen, after_view_state)` runs the steps in order with Tweens; `skip()` kills every tween, clears the flight layer and calls `screen.render(after_view_state)` so the end state never depends on animation code; a `finished` signal fires in both cases; `is_playing()`. In reduced motion each step becomes a `motion.fast` cross-fade or an instant change, with no step removed
- [X] T051 [US3] Change `dispatch` in `ui/main.gd` so every engine call is wrapped: snapshot before, call the engine, snapshot after, build the StepList, and if it is not empty play it through the Animator instead of rendering at once. While playing, a full-rect input catcher above everything turns the first press or key into `skip()` and consumes it, so "a press that skips an animation does nothing else"
- [X] T052 [US3] Implement the play steps in `ui/fx/animator.gd` with `ui/screens/play_screen.gd`: `play_cards` flies the assigned cards from the slots and Hand to the Encounter face; `tally` rolls the player's totals up against the targets in the preview panel (and lights the rung reached on the dragon ladder); `verdict` reveals the verdict with `motion.reveal`
- [X] T053 [US3] Implement the consequence steps, each at its `anchor`: `gain_xp` (XP motes from the Encounter to the XP purse, count rolls up), `damage` (the Encounter strikes the Hand, a brief shake, the amount shown with its Ether icon; early and combat damage as separate hits), `pay_time` (card backs fly from the deck counter to the discard counter, counts change as each lands), `poison_pending` (a poison marker settles on the deck), `knock_out` (all Hand cards crack together, then four card backs leave the deck)
- [X] T054 [US3] Implement the card steps: `downgrade` and `upgrade` (the card flips or pulses, the crown number changes, and the stat plates whose values changed flash), `trash` (the card shatters and flies to the trash counter), `discard` (cards fly to the discard counter), `gather_shuffle` (Hand and discard sweep into the deck, the deck riffles), `draw` (cards arrive from the deck counter one at a time with `motion.stagger`). Pile counts in `ui/widgets/header_bar.gd` change as each card arrives or leaves, not all at once
- [X] T055 [US3] Add small feedback motion from tokens: press scale to 0.96 on every Button and `card_view` within `motion.instant`, including when the action is then refused; a short shake plus the refusal message for refused actions; lift on assign and settle on take back; a gold pulse on the primary action when it becomes enabled; a 0.25 s cross-fade between screens and when the preview region swaps between preview, soak meter and XP purse (in `ui/theme/theme.gd`, `ui/widgets/card_view.gd`, `ui/screens/play_screen.gd`, `ui/main.gd`) — done except the cross-fade when the preview region swaps between preview, Soak meter and XP purse, which is an instant swap
- [X] T056 [US3] Make sequences safe against interruption in `ui/main.gd` and `ui/fx/animator.gd`: on window resize, on `NOTIFICATION_APPLICATION_PAUSED` or focus loss, and on any new `dispatch` while playing, call `skip()` first; confirm with `tools/ui_check.gd` by dispatching intents back to back with animation enabled and asserting the same final state as with animation skipped

**Checkpoint**: Turns resolve as a visible sequence of at most 3 seconds that can be
skipped with one press and that reads the same in reduced motion.

---

## Phase 6: User Story 4 - At home on every screen (Priority: P4)

**Goal**: The single landscape arrangement grows to use tablets and desktop
windows, respects safe areas in both landscape directions, survives resizing, works
with mouse and keyboard, and explains itself in a window it does not suit.

**Independent Test**: Open the same mid-game position at every size in the
quickstart.md matrix and confirm each is fully usable and none is more than one
third empty (quickstart.md steps 11 to 13).

- [X] T057 [US4] Tune growth in `ui/model/layout_solver.gd` and `tests/test_layout_solver.gd`: at 1280 x 960 (tablet) and 1280 x 800 (desktop) the extra height enlarges Hand cards and the Encounter face; on wide phones (about 1460 x 720) the extra width goes to the right column and card spacing; at the 1760 x 990 cap the content is centred on the backdrop. Assert in the test that at every landscape size in the matrix the regions cover at least two thirds of the safe area (SC-008)
- [X] T058 [US4] Apply safe areas in `ui/main.gd`: read `DisplayServer.get_display_safe_area()` on start and on every size change, convert to window pixels, and pass to the solver, so that the notch on the left and the notch on the right both keep every region and overlay clear, and the home indicator is clear at the bottom. Remove the old portrait-only top and bottom margin code
- [X] T059 [US4] Preserve state across resize in `ui/main.gd` and `ui/screens/play_screen.gd`: a size change re-solves the layout and calls `apply_layout` and `render` with the existing ViewState and TurnDraft; open overlays reposition; nothing is rebuilt from scratch. Verify by resizing mid-draft and mid-mode
- [X] T060 [P] [US4] Create `ui/overlays/size_notice.gd`: shown when the LayoutPlan is `undersized`; a dismissible banner with an icon that says "Turn your device sideways" on touch devices and "Widen the window" otherwise; it reappears only if the window becomes undersized again after being adequate. The game stays drawn and playable underneath
- [X] T061 [US4] Add hover states for mouse in `ui/theme/theme.gd`, `ui/widgets/card_view.gd`, `ui/widgets/slot_row.gd` and `ui/widgets/stat_chip.gd`: border brightens and the control lifts 2 units; cards lift further and show a pointer cursor; hover does nothing on touch devices
- [X] T062 [US4] Add the keyboard map from contracts/screens-and-interaction.md in `ui/main.gd` `_unhandled_key_input`: `1` to `7` choose Hand cards by position, `Tab` and `Shift+Tab` cycle slots, `B` toggles the Boost target, `Enter` runs the primary action, `Escape` cancels the mode or closes the top overlay, `I` inspects the focused or last-touched card, `?` opens the glossary; the focused control shows the gold ring. Keys act as skip while a sequence is playing
- [X] T063 [US4] Extend `tools/ui_check.gd` to run the seeded playthrough at every size in the quickstart.md matrix, including a left-notch and a right-notch safe area for `phone-tall`, a mid-game resize from 1440 x 900 to 1280 x 720 that must keep the draft, and the `upright-browser` size, where it asserts the notice is shown and the game still completes

**Checkpoint**: The game fills phones, tablets and desktop windows in landscape and
is playable by touch, mouse or keyboard.

---

## Phase 7: User Story 5 - A sense of occasion (Priority: P5)

**Goal**: A title screen whose choices explain themselves, announced Region changes
and Final Battle, and an ending that shows the score or the cause of loss.

**Independent Test**: Play one complete game and confirm the title screen, each
Region change, the start of the Final Battle and the ending are each visually
distinct from an ordinary turn (quickstart.md steps 14 to 17).

- [X] T064 [P] [US5] Create `ui/widgets/choice_tile.gd`: a selectable tile of at least 88 units with a title, an optional icon or sigil in an accent colour, a one- or two-line description in `type.label`, and selected, hover and focus states; supports single-choice groups and independent toggles
- [X] T065 [US5] Rebuild `ui/screens/title_screen.gd` for landscape per contracts/screens-and-interaction.md: the game title in `type.title` over the backdrop; four dragon tiles each with name, title, Ether colour, Ether icon and sigil, and its Initiative, early damage and Armor entries from `db.dragon`; six difficulty tiles each stating what it changes, derived from `Game.DIFFICULTY` (for example "Choose 2 of 5 cards to start at Level 3"); two alternate-rule toggles with their effect in plain words; the gold "Start the adventure" action in the bottom right; the credit and non-affiliation line; buttons for Settings and Glossary. Preselect `Settings.last_options` and save them on start
- [X] T066 [P] [US5] Create `ui/overlays/stage_banner.gd`: a full-width banner that sweeps in, holds and leaves within 1.2 s (cross-fade in reduced motion), skippable by a press; one form for a Region ("Region 2" over the Region's name from `db.region`) and one for the Final Battle (the dragon's sigil, name and title, then "The Final Journey" or "The Final Enemy")
- [X] T067 [US5] Play the `stage_banner` step in `ui/fx/animator.gd` using `ui/overlays/stage_banner.gd`: after `gather_shuffle` and before `draw` on a Region change; on entering final_journey; and again on entering final_enemy. Also show the Region 1 banner when a new game starts
- [X] T068 [US5] Add score breakdown and cause of loss to `ViewState.ending` in `ui/model/view_state.gd` and `tests/test_view_state.gd`: on a win, the count of surviving cards at each Level, their contribution, the number of trashed cards, and the total, which must equal `game.score()`; on a loss, where it happened (Region and Encounter, Final Journey or Final Enemy) and why, from `game.result` (below the first tier, or damage that could not be Soaked). Record the Encounter in `ui/main.gd` at the moment of the losing action, since the engine does not keep it
- [X] T069 [US5] Rebuild `ui/screens/ending_screen.gd`: on a win the dragon's sigil, "<Dragon> is defeated", the score in `type.numeral_l` rolling up, and the breakdown as rows; on a loss "You have perished" with where and why; "Play again" (gold, same options with a new seed, one press) and "Change options" (back to the title). Play the `ending` step in `ui/fx/animator.gd` as the transition into this screen, with a restrained particle burst on a win using CPU particles
- [X] T070 [P] [US5] Create `ui/overlays/confirm_dialog.gd`: a modal with a message, a confirm action and a cancel action, each at least 88 units; Escape cancels
- [X] T071 [US5] Create `ui/overlays/menu_overlay.gd`, opened by the header's menu button and by Escape when nothing else is open: Resume, Settings (the motion choice: Follow device, Reduced, Full, saved through `ui/model/settings.gd` and applied immediately), Glossary, and Leave game, which asks through `confirm_dialog.gd` and then returns to the title screen. Make the Settings part reusable from the title screen

**Checkpoint**: The game has a beginning, announced stages and an ending.

---

## Phase 8: User Story 6 - Help where the question arises (Priority: P6)

**Goal**: Every icon and term explains itself on demand, and the multi-step actions
guide the player and can be cancelled.

**Independent Test**: A person who has never played can find out what every symbol
on the first Encounter means without outside help (quickstart.md steps 18 to 20).

### Tests for User Story 6

- [X] T072 [P] [US6] Create `tests/test_glossary.gd`: every Hardship, Ability and Peril id present in `data/cards.json` has an entry; every icon file in `art/icons/` that is shown to the player has an entry; every entry has a non-empty `name` and a `text` of at most two sentences

### Implementation for User Story 6

- [X] T073 [US6] Create `ui/model/glossary.gd`: entries `{id, name, icon, text}` for hp, initiative, attack, move, mp, time, xp, armor, boost, crown (Level), the four Ethers, the four Hardships, four Abilities and two Perils (start from the one-line descriptions in the old `ui/main.gd`), and the terms Key Card, Action Set, Spell, Element, Boost role, Reserve, enhanced action, Fuse, Divert, Regroup, Soak, Downgrade, Upgrade, Knock Out, Trash, complete victory, narrow victory, time penalty, early damage. Write each in original wording of one or two sentences and check each against `reference/rulebook.txt`; do not copy rulebook sentences
- [X] T074 [P] [US6] Create `ui/overlays/glossary_popover.gd`: a small panel anchored beside the thing pressed, kept inside the safe area, showing the entry's icon, name and text; dismissed by a press anywhere or Escape, and that press does nothing else. Also a full-list mode (a paged two-column list, not a scrolling one) for the `?` key and the menu's Glossary item
- [X] T075 [US6] Make every icon and named effect pressable: `ui/widgets/stat_chip.gd` emits `help` with its `glossary_id`; add the same to the effect rows and targets in `ui/widgets/encounter_face.gd` and `ui/widgets/dragon_face.gd`, the pile counters in `ui/widgets/header_bar.gd`, the costs and rewards in `ui/widgets/preview_panel.gd`, the role icons in `ui/widgets/slot_row.gd` and the stat plates in `ui/overlays/inspect_overlay.gd`; `ui/main.gd` opens the popover. Pressable help targets get an expanded hit area so they meet 88 units without changing how they look. Stat plates on Hand cards stay part of the card's own press; help for them is reached through inspect — done for Encounter and dragon figures, effect rows, pile counters, rewards and costs; role icons in slots and stat plates in the inspect view do not open help
- [X] T076 [US6] Guide the multi-step actions per contracts/screens-and-interaction.md, in `ui/model/view_state.gd` (prompt text, per-card `eligible` and `reason`) and `ui/widgets/preview_panel.gd` (prompt display): Fuse shows "Step 1 of 3: choose the card to play", then "Step 2 of 3: choose a card of the same Ether to tuck behind it" with cards of other Ethers marked unavailable and why, then "Step 3 of 3: choose the Ether it counts as"; Divert and Regroup state what will be discarded and redrawn; Cancel is always in the actions region during a mode. Extend `tests/test_view_state.gd` for the per-step eligibility and for cancel at each Fuse step leaving the draft unchanged
- [X] T077 [US6] Finish the Soak step in `ui/widgets/soak_meter.gd`, `ui/widgets/card_view.gd` and `ui/model/view_state.gd`: each Hand card shows what it would Soak, with matching Armor called out by its Ether icon; the meter fills as cards are chosen, in order; cards already Downgraded this Encounter are unavailable with the reason; once covered, further cards are unavailable with "The damage is already covered"; the primary action enables exactly when covered. When no selection can cover the damage the screen says so (the engine applies Knock Out itself; this state should not be reachable, so assert it in `tools/ui_check.gd`)
- [X] T078 [US6] Finish the Upgrade step in `ui/widgets/xp_purse.gd`, `ui/widgets/card_view.gd` and `ui/model/view_state.gd`: each card shows its Upgrade cost; affordable cards are available, others unavailable with the reason ("Costs 5 XP", "Downgraded this Encounter", "Highest Level"); the purse says "Unspent XP is lost" while XP remains and the primary action reads "Continue"; when nothing is affordable the prompt says so

**Checkpoint**: All six user stories work on their own and together.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Whole-game review on every target, performance, documentation.

- [X] T079 Remove dead code: confirm nothing from the old single-file UI remains in `ui/main.gd`, that no widget defines its own colour, size or duration literal (grep `ui/` for `Color("` and `font_size` outside `ui/theme/`), and that no `ScrollContainer` exists in `ui/`
- [X] T080 Run `godot --path . -s tools/shot.gd -- build/screenshots/matrix` and review every image at every size for clipping, overlap, truncated names (check the longest card, Region and effect names), more than one gold action on a screen, and any screen more than one third empty; fix what is found
- [X] T081 Colour check (SC-011): convert the `phone-16x9` screenshots to greyscale and confirm every Ether, verdict, cost and card state is still identifiable by icon, shape or word; fix any that rely on colour alone — done on the 1280 x 720 play screen
- [ ] T082 Performance check (SC-006): run the web build and the Android emulator build through three Encounters with Godot's frame-time monitor visible; confirm no frame-time spikes during sequences and no per-frame node creation outside the flight layer; reduce particle counts or shader cost in `ui/fx/` if needed — not done: no frame-time measurement on a device yet
- [ ] T083 Build and launch on all targets with `scripts/install.sh` (the `install-on-emulators` skill); on the iOS simulator check both landscape directions for safe areas and confirm the app does not rotate upright; in the web build confirm the fonts' lining figures render and the reduced-motion media query is honoured (the two open items in research.md) — partly done: Android emulator and iPhone 17e simulator checked by screenshot (landscape, safe areas clear); web build served but not yet viewed in a browser, so lining figures and the reduced-motion media query there are unverified
- [ ] T084 Run the full quickstart.md walkthrough (section 3, steps 1 to 21) on a phone target and in a desktop browser and fix any defect found — not done: screens reviewed through the screenshot matrix, not walked through by hand
- [X] T085 Confirm the frozen parts are untouched: `git diff --stat main -- engine data tests/test_card_db.gd tests/test_game.gd tests/test_playthrough.gd tests/test_rules.gd` must be empty, and `./tools/test.sh` must exit 0
- [X] T086 [P] Update `README.md`: the Status section (landscape presentation, card faces, animation, help, settings), the Layout table for the new `ui/` folders and `art/fonts/`, the Tests section for the UI check and the screenshot matrix, and a credit line for the bundled OFL fonts
- [X] T087 [P] Update `.claude/skills/install-on-emulators/` notes if they mention portrait orientation or the old screenshot names — done: the skill notes do not mention orientation; nothing to change

---

## Phase 10: Feedback from the first build

**Purpose**: Changes asked for after playing the first build on web and devices.

- [X] T088 Title screen tiles grow to fit their wrapped descriptions, and the dragon and Glass Cannon descriptions are shorter, so no text spills out of a tile, in `ui/widgets/choice_tile.gd` and `ui/screens/title_screen.gd`
- [X] T089 Choosing the Ether for a Fuse happens in a picker that floats above the two cards instead of in the action bar; the second card leans in behind the first while you choose, then tucks behind it with a flourish, in `ui/widgets/ether_picker.gd`, `ui/widgets/hand_tray.gd` and `ui/screens/play_screen.gd`
- [X] T090 Secondary action buttons never wrap their labels, in `ui/widgets/action_bar.gd`
- [X] T091 After a battle (Soak and Upgrade steps) the slots region recaps the Action Set just played and the Reserve, and each card is tagged "Discarded after" or "Stays in Hand", with the staying card lifted, in `ui/model/view_state.gd`, `ui/widgets/slot_row.gd` and `ui/widgets/card_view.gd`
- [X] T092 Hovering a card in the Soak or Upgrade step shows it at the Level it would become, with the figures that would change ringed, or that it would be Trashed, in `ui/model/view_state.gd`, `ui/widgets/card_face.gd` and `ui/widgets/card_view.gd`
- [X] T093 Upgrades can be undone until Continue is pressed, in `ui/model/upgrade_undo.gd` (tested in `tests/test_upgrade_undo.gd`) and `ui/main.gd`
- [X] T094 The menu button has no tooltip covering the stage name, in `ui/widgets/header_bar.gd`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: needs Setup. Blocks every user story.
- **US1 (Phase 3)**: needs Foundational. Everything after builds on its play screen.
- **US2 (Phase 4)**: needs US1 (`card_view`, `hand_tray`, the faces it restyles).
- **US3 (Phase 5)**: needs US1. Independent of US2 in code, but the card steps look
  right only with US2's faces, so do US2 first.
- **US4 (Phase 6)**: needs US1. T062's inspect key needs US2; T063's animated run
  needs US3.
- **US5 (Phase 7)**: needs Foundational for the screens; T067 and T069 need US3's
  Animator; T071's motion setting needs T047.
- **US6 (Phase 8)**: needs US1; T075's inspect stat plates need US2.
- **Polish (Phase 9)**: needs every story that is being shipped.

### Within Foundational

- T006 before T007. T008 before T010. T010 before T011 and T012.
- T013 and T014 are independent of the model tasks.
- T015 needs T007, T010 and T013. T016 needs T013. T017 and T018 need T007.
- T019 and T020 need T015 to T018.

### Within Each User Story

- US1: T022 to T028 and T030 to T032 are separate files and can go in parallel;
  T029 needs T028; T033 needs all the widgets; T034 needs T033; T021 and T035 last.
- US2: T036 and T037 in parallel; T038 needs T036; T039 needs T038; T040 to T043
  need T039; T044 last.
- US3: T045, T047, T048 and T049 in parallel; T046 with T045; T050 needs T048 and
  T049; T051 needs T046 and T050; T052 to T054 need T051; T055 and T056 last.
- US4: T057 first; T058 and T059 then; T060 in parallel; T061 and T062 any time
  after T057; T063 last.
- US5: T064, T066 and T070 in parallel; T065 needs T064; T067 needs T066; T069
  needs T068; T071 needs T070.
- US6: T072 and T074 in parallel; T073 makes T072 pass; T075 needs T073 and T074;
  T076 to T078 are independent of the popover.

### Parallel Opportunities

- Setup: T003 and T005 alongside T004.
- Foundational: T006, T008, T009, T013, T014 together; then T017 and T018 together.
- US1: nine widget files at once (T022 to T028, T030, T031, T032).
- US5 and US6 can be worked by different people at the same time once US3 is done,
  since they touch different files apart from `ui/main.gd` and
  `ui/model/view_state.gd`.

---

## Parallel Example: User Story 1

```text
# After T021 is written, launch the widget files together:
Task: "Create ui/widgets/stat_chip.gd ..."        (T022)
Task: "Create ui/widgets/header_bar.gd ..."       (T023)
Task: "Create ui/widgets/encounter_face.gd ..."   (T024)
Task: "Create ui/widgets/dragon_face.gd ..."      (T025)
Task: "Create ui/widgets/preview_panel.gd ..."    (T026)
Task: "Create ui/widgets/slot_row.gd ..."         (T027)
Task: "Create ui/widgets/card_view.gd ..."        (T028)
Task: "Create ui/widgets/action_bar.gd ..."       (T030)
Task: "Create ui/widgets/soak_meter.gd ..."       (T031)
Task: "Create ui/widgets/xp_purse.gd ..."         (T032)

# Then, in order: T029 (hand_tray), T033 (wire regions), T034 (intents), T035 (fit)
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1: Setup.
2. Phase 2: Foundational. The game is not playable between T015 and the end of US1,
   because the old screen code is removed before the new play screen is wired. Do
   Phases 2 and 3 on the branch without merging in between.
3. Phase 3: User Story 1.
4. **Stop and validate**: play a full game at 1280 x 720 and on a phone target;
   `./tools/test.sh` passes, including the seeded playthrough equality check.

### Incremental Delivery

Each later story leaves the game shippable:

1. US1: readable landscape play screen (MVP).
2. US2: real card faces, states and inspect.
3. US3: resolution sequence, feedback motion, reduced motion.
4. US4: tablets, desktop, safe areas, mouse and keyboard.
5. US5: title, banners, ending, menu and settings.
6. US6: glossary and guided steps.
7. Polish: review on every target, README.

### Notes

- Commit only when the user asks; a natural point is each checkpoint.
- The Final Battle at 1280 x 720 has about 8 units of slack. T035 is where that is
  settled; do not defer it.
- If a rules defect is noticed, report it; do not fix it under this feature.
