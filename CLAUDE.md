# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Dragons of Etchinstone

A fan-made digital version of the solo card game, built with Godot 4.7.2 (standard
build, GDScript, GL Compatibility renderer) for web, Android and iOS. It is played
in landscape only. `engine/` holds the rules and has no dependency on the interface.
`ui/` is everything drawn. `tests/` holds the headless unit tests, and `tools/` holds
the UI check, the screenshot tools and the generators.

## Commands

`godot` must be on `PATH` (shims live in `~/.local/bin`). Run the shell scripts with
the Bash tool, not PowerShell.

```sh
godot --path .                                        # run the game
tools/test.sh [full | unit [name ...] | ui [full] [walk ...]]   # tests (see below)
godot --path . -s tools/shot.gd -- build/screenshots/matrix [size ...]  # screenshots at every window size
scripts/install.sh [android|ios|web|all]              # export, install, launch, screenshot (macOS, or Windows under Git Bash)
python3 tools/gen_cards.py data/cards.json            # regenerate card data (checks consistency too)
python3 tools/gen_icons.py                            # regenerate art/icons/
```

There is no linter. A parse error shows up as a `SCRIPT ERROR`/`Parse Error` in any
test run, which fails it.

## Architecture

### One action, from press to animation

`ui/main.gd` is the root (the only scene is `scenes/main.tscn`, which just attaches it).
It owns the `Game`, the player's `TurnDraft` and the current screen. Every player
action goes through `main._act(action, callable)`:

1. `ViewState.snapshot(game)` is taken **before** the call.
2. The engine call (`game.play()`, `divert()`, `soak()` and so on) returns `""` on
   success or a message saying why it was refused. A refused action changes nothing,
   and its message is shown as a note.
3. A second snapshot is taken **after** the call. The draft is reset or settled.
4. `Sequencer.build(before, action, game.result, after)` turns the difference into
   ordered steps `{kind, cards, from, to, values, anchor, duration}`.
5. `Animator.play(steps, play_screen, vs)` plays them. The game has already changed,
   so the screen is only catching up. `skip()` must always settle on exactly the same
   final state (the `skip` walk checks this).

### Layers and their rules

- **`engine/`**: `card_db.gd` reads `data/cards.json` and does nothing else.
  `rules.gd` is pure Encounter maths (static functions, no state). `game.gd` is one
  game's state machine. Its `phase` (`setup`, `challenge`, `penalty`, `upgrade`,
  `poison`, `final_journey`, `final_enemy`, `final_soak`, `won`, `lost`) decides
  which actions are open; the header comment of `game.gd` lists them. The engine
  must never preload anything from `ui/`.
- **`ui/model/`**: pure `RefCounted` logic with no nodes, so it can be tested
  headless. `view_state.gd` is **the only UI file that reads the engine's
  internals**: it turns game + draft into the dictionaries that screens draw.
  `turn_draft.gd` holds the uncommitted choices, and its `to_action()` is what gets
  sent to the engine. `sequencer.gd`, `emphasis.gd` (which card figures to lift in
  each step), `board_response.gd` (zone edge colours per event) and
  `layout_solver.gd` (where everything goes for a window size) are all pure
  functions of their inputs.
- **`ui/theme/tokens.gd`**: every size, colour, typeface and duration. Sizes are
  design units (one pixel of the 1280×720 layout). Widgets take their values from
  here instead of hard-coding them. `TEXT_MIN` (22) and `TAP_MIN` (88) are the floors
  that the UI check enforces.
- **`ui/screens/`, `ui/widgets/`, `ui/overlays/`**: nodes built in code (no `.tscn`
  per widget). They render the view-state dictionaries they are given and do not
  read a live game's state. A few screens preload `engine/game.gd` only for its
  constants, such as `DIFFICULTY`.
- **`ui/fx/`**: the animator, the flight layer, haptics, `creature.gd` (idling
  rigged silhouettes) and the shaders.

### Conventions

- No `class_name`. Scripts reference each other through
  `const X = preload("res://...")` at the top of the file.
- Indent with tabs in `.gd`, `.gdshader`, `.tscn` and `.sh`, and with 2 spaces in
  JSON/YAML (`.editorconfig`).
- Doc comments (`##`) explain *why* and point to the feature and research item they
  come from (for example `specs/014`, `research R8`). Keep that style.
- Tests extend `res://tests/base.gd` and use `eq(actual, expected, what)` and
  `ok(cond, what)`. Every `test_*` method in `tests/test_*.gd` runs, and a test that
  makes no assertion fails.
- Tools and tests that play games point `HistoryStore` at `user://tool_history/`
  so they never write to the player's records.
- Reduced motion is a first-class path. Every animated step and board response has
  a still form, and the UI check walks it.
- The README's "Rules interpretations" section records how the engine decides
  where the rulebook is silent. Update it when that behaviour changes.

### Feature workflow (Spec Kit)

Each feature lives in `specs/NNN-name/` (`spec.md`, `plan.md`, `research.md`,
`data-model.md`, `contracts/`, `tasks.md`) and is driven by the `speckit-*` skills.
Code comments cite these files, so read the cited spec or contract before changing
behaviour that one describes (for example `specs/005-playfield-polish/contracts/step-emphasis.md`
for `emphasis.gd`). `.specify/memory/constitution.md` is still the unfilled template.

### Not in the repository

`reference/` (the rulebook and card scans, copyrighted), `.claude/`, `.env`
(Hugging Face token for art generation) and `build/` are gitignored. The art
pipeline (`tools/generate_art.py`, `paint_art.py`, `frame_art.py`,
`vectorize_art.py`, `split_rig.py`) depends on a local ComfyUI. Its output goes to
`art/creatures/`, and the approved source images go to `art/source/`.

## Testing: run the narrowest tier that covers the change

The full suite takes about 3 minutes, most of it the UI check playing animations in
real time at all 8 window sizes. Do not run it after every change.

| When | Run | Time |
|---|---|---|
| After each edit | `tools/test.sh unit <name ...>`, the unit files for what changed (table below) | seconds |
| After a change to anything drawn or animated | `tools/test.sh ui <walk ...>`, the walks for what changed (table below) | 5–30 s |
| Once a change is finished, or it touches several areas | `tools/test.sh` (quick: all unit tests, every UI walk once at the smallest phone) | ~1 min |
| Before a commit, after a merge, or when the user asks | `tools/test.sh full` (every walk at every window size in the layout matrix) | ~3 min |
| A change to `ui/model/layout_solver.gd`, window sizes, safe areas or anything sized by the window | `tools/test.sh ui full screens` as well as the quick run, since quick mode checks only one size | ~30 s |

`unit` names match any part of a `tests/test_*.gd` file name (`unit rules game` runs
`test_rules.gd` and `test_game.gd`). With no names, every unit test runs; that takes
about 8 seconds and is fine whenever the right file is unclear.

### Unit tests by area

| Change in | `tools/test.sh unit ...` |
|---|---|
| `engine/` (rules, game, card data) | `rules game card_db terms playthrough` |
| `data/cards.json`, `data/flavor.json` | `card_db flavor terms dragon_stats` |
| `ui/model/view_state.gd`, `turn_draft.gd`, `emphasis.gd` | `view_state turn_draft emphasis terms` |
| `ui/model/sequencer.gd`, `board_response.gd`, `ui/fx/animator.gd` | `sequencer board_responses deck_stack` |
| `ui/model/layout_solver.gd`, `window_sizer.gd` | `layout_solver window_sizer` |
| History, records, clock | `history_store play_history play_clock` |
| Rulebook, glossary | `rulebook glossary` |
| Theme, colours, stone | `card_contrast stone_contrast` |
| A widget `ui/widgets/<name>.gd` | its own `test_<name>.gd` where one exists (`deck_stack`, `region_card`, `region_panel`, `note_pile`, `stat_chip`, `preview_panel`, `place_labels`, `card_face_layout`) |
| `ui/model/art.gd`, `ui/fx/creature.gd`, painted art | `art creature` |
| Lessons, the coach mark (`ui/model/lessons.gd`, `tutorial.gd`), `Game.stage` | `lessons tutorial game` |

### UI check walks

| Walk | Covers |
|---|---|
| `notes` | The notes as cards on the Deck: dealt, thrown off, held, reduced motion |
| `screens` | Landing page, setup screens and dragon choice, records, rulebook, each overlay over a game in progress |
| `marks` | Effect marks beside a card's figures |
| `play` | Seeded games played through the screens against the engine alone, still and animated |
| `deck` | The reveal frame by frame: draw, zoom, refill, Divert, reduced motion (the slowest walk) |
| `skip` | Skipping a draw or reveal settles exactly as playing it out |
| `look` | Zooming out to the whole Region Card and back in |
| `ending` | A won game's ending, placing and Leaderboard |
| `resize` | Resizing the window mid-turn |
| `divert` | A Divert taken through the screen, and a refused move's note |
| `arrange` | Ordering the Hand by tap, swap, drag and keyboard; a lifted card under an overlay; the unspent XP question |
| `lessons` | Learn to Play: the first Play's offer, all six lessons through the screens (each message and what it lights, one wrong move refused in each), the summary, the list and resuming, nothing recorded |

Pick the walks by what the change touches: a widget on the Deck → `deck skip look`;
the Hand or card placement → `arrange play`; notes → `notes divert`; a screen or
overlay → `screens`; card faces and marks → `marks play`; the lessons, the coach mark
or anything a lesson lights → `lessons`.

### Reading results

Script errors fail a run even when every check passes. Godot's reports of objects
or resources still allocated at exit are not errors and are ignored by `test.sh`.
