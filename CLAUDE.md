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
uv run --no-project --with fonttools python -I tools/make_figures.py  # recut the tabular figure fonts from Fraunces
scripts/etch [command]                                # the console: menus for all of the above, release builds, art import
```

`scripts/etch` (`scripts/etch.cmd` from PowerShell) is the developer console from
`specs/018-dev-console`: Python in `tools/console/`, run by `uv`. With no arguments it
shows arrow-key menus, which need a real terminal, so from the Bash tool always use the
commands (`scripts/etch --help`):

- `build <android|ios|web ...> [--step build|patch|minor|major] [--upload] [--yes]`
  makes signed release files in `build/release/<version>-<build>/` and bumps the version
  in `project.godot` and `export_presets.cfg` (put back if a build fails). Credentials
  come from `.env` (keys in `.env.example`). Every check runs first, and a missing one
  stops the run before anything changes. Never put real credentials in a command line.
- `art import|status`: reworked art staged in `art/staging/<kind>/<name>.png` (git- and
  Godot-ignored) goes to `art/painted/`, checked against `ui/model/art.gd`'s names via
  `tools/art_slots.gd`. Illustrator's numbers are dropped from names
  (`naga-122-01.png` fills `naga`), and `.ai` files beside their exports are skipped and
  left in place. Rigs (`rigs/<dragon>-parts.svg`) also run `tools/split_rig.py`.
- `icon [dragon]` remakes the app icon (`tools/make_app_icon.gd`, whose
  `DEFAULT_DRAGON` is the icon's dragon) and draws `build/icon-preview.png`. It writes
  every platform's variant: `icon.svg` (a full-bleed square; Android, iOS and web cut
  their own shape), Android's adaptive layers, iOS's dark and tinted icons and Windows'
  rounded tile, all in `art/launcher/`.

`godot --path .` does not re-import changed art: after editing anything under `art/`
by hand, run `godot --headless --path . --import` first (the editor, exports and
`scripts/etch art import` all re-import on their own).

On Windows the `adb` first on `PATH` is an old one that cannot see a phone on wireless
debugging; run `scripts/install.sh android` with
`$LOCALAPPDATA/Android/Sdk/platform-tools` put first on `PATH`.
- `selftest` runs the console's pytest suite (`tools/console/test_console.py`). Run it
  after changing anything in `tools/console/`.

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
  here instead of hard-coding them (no `Color("…")` anywhere else; a test fails on
  one). The values follow the "Inkstone and Brass" design system in
  `specs/019-unified-design-system/design-system/` (`tokens.json` is the source of
  truth, phone points × 1.85, enforced by `test_design_tokens`). Brass is only for the
  one primary action, the selected thing and the one target slot, bright brass only
  for rewards (`contracts/brass-and-states.md`); the UI check fails on two brass
  buttons or two targets, on a label in a colour or face outside the system, and on
  drawn text under its floor (`UI.drew_text`). `TEXT_MIN` (22) and `TAP_MIN` (88) are
  the floors that the UI check enforces.
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
- House rules (this edition's own, beyond the rulebook) are game options, each with
  its own check in the engine (`Game.keeps_xp()` for `persistent_xp`), so Classic is
  every house rule off and the engine knows nothing of editions. List each in
  `ui/model/editions.gd`'s `HOUSE_RULES`; the setup screens offer it only under House
  rules (the menu's Rules setting, `Settings.house_rules`), and rulebook lines starting
  `{house}` and Glossary `house` text appear only then.

### Feature workflow (Spec Kit)

Each feature lives in `specs/NNN-name/` (`spec.md`, `plan.md`, `research.md`,
`data-model.md`, `contracts/`, `tasks.md`) and is driven by the `speckit-*` skills.
Code comments cite these files, so read the cited spec or contract before changing
behaviour that one describes (for example `specs/005-playfield-polish/contracts/step-emphasis.md`
for `emphasis.gd`). `.specify/memory/constitution.md` is still the unfilled template.

### Release size: painted art and trimmed engine templates

The painted pictures (`art/painted/**`) import as lossy WebP at quality 0.8
(`compress/mode=1` in their `.import` files), which took the game data from 18 MB to
5 MB with no visible change. A new painting added under a new name imports lossless
by default; set the same two lines in its `.import` file.

Release exports for Windows and Android use engine templates compiled without
everything the game does not use (no 3D, physics, Vulkan, Direct3D 12 or XR), from the
build profile `tools/engine.gdbuild`, made with the editor's Project > Tools > Engine
Compilation Configuration Editor ("Script" was removed from its disabled classes by
hand). The Windows exe went from 109 MB to 40 MB and the Android release APK from
32 MB to 19 MB. Debug exports (`scripts/install.sh`) still use the official templates.

- The templates are built from Godot's source at `C:\dev\godot` (tag `4.7.2-stable`),
  and the presets point at them by absolute path (`custom_template/release` for
  `Windows Desktop` and `Android`, `gradle_build/android_source_template` for
  `Android Release`), so those exports work only on this Windows machine. The Mac
  needs its own templates, and iOS can only be built there.
- Web and iOS templates are built on the Mac from `~/dev/godot` (same tag, Emscripten
  4.0.11 from `~/dev/emsdk`) with `tools/build_templates.sh web|ios`, and the `Web` and
  `iOS` presets point at `/Users/danger/dev/godot/bin/`, so release exports of those two
  work only on the Mac. Web's `.wasm` went from 39.5 MB to 21.6 MB (10.1 MB to 5.5 MB
  gzipped), and the iOS app from 88 MB to 40 MB (30 MB to 15 MB zipped).
  `tools/build_templates.sh` also turns off every engine module except gdscript,
  freetype, svg (`creature.gd` loads SVG at run time), webp, regex, noise (unused since `specs/019` removed `stone.gd`; drop it at the next rebuild)
  and text_server_adv; a new use of any other module (audio, jpg, zip, networking...)
  needs it added there. The iOS exporter always links `MoltenVK.xcframework`, so the
  script puts an empty one in `godot_ios.zip`. The Windows and Android templates
  predate the module trimming; rebuilding them with
  `tools/build_templates.sh windows|android C:/dev/godot` should shrink them further.
- The editor's "detect" in the Engine Compilation Configuration Editor disables `Script`
  every time (a second pass on 2026-10-22 found nothing else new), so keep
  `tools/engine.gdbuild` and put `Script` back by hand after any re-detect.
- Rebuild a template after upgrading Godot (it must match the editor exactly), or when
  the game starts using an engine class the profile disables (sound, physics,
  `AnimationPlayer`, `Curve`...): re-detect in the editor, save over
  `tools/engine.gdbuild`, check it still keeps `Script`, and rebuild. A class the
  template lacks fails only when the game runs, not at export.
- Build (from `C:\dev\godot`; `uv tool install scons`; MSVC through Visual Studio 2022):
  `scons platform=windows target=template_release arch=x86_64 production=yes
  optimize=size d3d12=no vulkan=no angle=yes build_profile=<repo>/tools/engine.gdbuild`
  and `scons platform=android target=template_release arch=arm64 production=yes
  optimize=size generate_android_binaries=yes build_profile=<same>` (Android NDK
  `29.0.14206865`, `ANDROID_HOME` and `JAVA_HOME` set). Their dependencies were fetched
  once with `misc/scripts/install_accesskit.py`, `install_angle.py` and
  `install_swappy_android.py`. After an Android template change, delete `android/` so
  the next `.aab` build reinstalls it from the new `android_source.zip`.
- From the Bash tool, the Android build's last step (`gradlew.bat`) fails because the
  shell sets `NoDefaultCurrentDirectoryInExePath`; run it by hand from
  `platform/android/java`:
  `env -u NoDefaultCurrentDirectoryInExePath cmd //c "gradlew.bat generateGodotTemplates --quiet"`.

### Not in the repository

`reference/` (the rulebook and card scans, copyrighted), `.claude/`, `.env`
(the Hugging Face token for art generation and the store credentials listed in
`.env.example`), `build/`, `android/` (Godot's Gradle project, installed by the first
`.aab` build) and `art/staging/` are gitignored. The art
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
| Theme, colours, type, stone | `design_tokens palette_contrast card_contrast fonts` |
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
