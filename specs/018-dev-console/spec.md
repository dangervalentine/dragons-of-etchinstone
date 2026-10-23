# Feature Specification: Developer Console

**Feature Branch**: `018-dev-console`

**Created**: 2026-10-22

**Status**: Draft (design agreed in brainstorming; no plan yet)

**Input**: User description: "create a unified, interactive console script which prompts the user to what they are trying to accomplish with a menu setup and keyboard interactivity, using keyboard arrows to navigate the menus. we will want producing build artifacts - iOS and Android would need their keystores, provisioning profiles, publishing profiles, certs, etc... yes, but build as if we have them, failing if we don't with helpful errors. another fork in the top level of this script would be to update the app icon, refresh the art in the app (enemies, regions, anything else) by looking in a designated staging folder."

## Overview

The project's chores are spread over a dozen commands, each with its own arguments:
`scripts/install.sh`, `tools/test.sh`, `tools/make_app_icon.gd`, `tools/gen_cards.py`,
`tools/shot.gd`, and a by-hand routine for moving an Illustrator export into
`art/painted/`. There is no way at all to make a store build: the export presets are
debug-only and unsigned.

This feature adds one console, `scripts/etch`, that asks what you want to do through
arrow-key menus and then does it. It also adds the two missing jobs: signed release
builds with store uploads, and a predictable route for new art from Illustrator into the
game.

## Clarifications

### Session 2026-10-22

- Q: Should the build branch stop at signed files, or upload them too? → A: Upload too. Android goes to Google Play, iOS to TestFlight. Web upload is a placeholder for now: the menu item exists and says it is not implemented.
- Q: How does a reworked picture get from an Illustrator export into the game? → A: Through a staging folder whose subfolders name the kind of art, with the file named after the slot it fills (the names in `ui/model/art.gd`). Illustrator's suffixes are tolerated.
- Q: Where is the staging folder? → A: `art/staging/` in the repository, ignored by git and by Godot.
- Q: Which other top-level branches? → A: Install on device, Test & run, Regenerate data. There is no separate "doctor" item; each action checks what it needs first (preflight).
- Q: Language? → A: Python, run through `uv` with its dependencies declared inside the script, so neither machine needs a manual install.

## Menu

```
Dragons of Etchinstone
> Build & publish
  Art & icon
  Install on device
  Test & run
  Regenerate data
  Quit
```

Up and down arrows move, Enter chooses, Space ticks an item in a multi-select, and Esc or
"Back" goes up a level. Each branch ends on a summary and returns to its menu.

### 1. Build & publish

1. Choose platforms (multi-select): Android, iOS, Web.
2. Choose the version step: build number only, patch, minor, or major. The current
   version and the next one are shown before you choose.
3. Choose whether to upload after building (per platform; for Web it says "not
   implemented yet").
4. Preflight runs for every chosen platform **before anything is built or bumped**. If any
   check fails, nothing changes and every failure is listed at once.
5. The version is written, then each platform is built into
   `build/release/<version>/`, with logs in `build/release/<version>/logs/`.
6. If an upload is chosen, it runs after a successful build.

| Platform | Artifacts | Signing | Upload |
|---|---|---|---|
| Android | `dragons-of-etchinstone-<version>.aab` (for Play) and `.apk` (for side-loading) | Release keystore, passed to Godot through its own `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD` variables | Google Play Developer API with a service-account JSON key. The track is chosen from a menu (internal by default) |
| iOS | `dragons-of-etchinstone-<version>.ipa` | Team ID from the preset, the release provisioning profile through `GODOT_IOS_PROVISIONING_PROFILE_UUID_RELEASE`, the distribution certificate from the keychain | TestFlight through App Store Connect with an API key (key ID, issuer ID, `.p8`) |
| Web | `dragons-of-etchinstone-web-<version>.zip` (the export folder, zipped) | None | Placeholder: prints "Web upload is not implemented yet" and exits successfully |

The Android `.aab` needs Godot's Gradle build (`gradle_build/use_gradle_build`) and the
Android build template installed in `android/`. The release presets get their own
sections (`Android Release`, `iOS Release`, `Web Release`), so the debug presets that
`install.sh` uses are untouched.

**Version.** One version is kept in `project.godot` (`application/config/version`, e.g.
`1.4.2`) and one build number, which is written to Android's `version/code` and iOS's
`application/version`. The build number goes up on every release build, whatever the step,
since both stores refuse a number they have seen. If the build fails, the version is left
where it was before the run.

### 2. Art & icon

**Import staged art.** The staging folder:

```
art/staging/                       git-ignored, with a .gdignore
  enemies/    <enemy>.png          → art/painted/<enemy>.png
  dragons/    <dragon>.png         → art/painted/<dragon>.png          (the Dragon Card)
              <dragon>-full.png    → art/painted/<dragon>-full.png     (the ending)
              <dragon>-head.png    → art/painted/<dragon>-head.png     (the head pictures)
  backdrops/  <enemy>.png          → art/painted/backdrops/<enemy>.png
  journeys/   <journey>.png        → art/painted/journeys/<journey>.png
  lairs/      <dragon>.png         → art/painted/lairs/<dragon>.png
  roads/      <dragon>.png         → art/painted/roads/<dragon>.png
  rigs/       <dragon>-parts.svg   → art/creatures/<dragon>-parts.svg, then tools/split_rig.py
```

1. **Names.** The valid names come from `ui/model/art.gd` (`ENEMIES`, `JOURNEYS`,
   `DRAGONS`, and `FINAL_JOURNEY` for journeys), read by a small headless Godot script
   that prints them as JSON, so the list can never drift from the game's. A file's name
   is cleaned first: Illustrator's export suffix (`-01`) and a seed (`-126`) are removed,
   so `antler-horror-126-01.png` fills `antler-horror`. A name that still matches nothing
   is an error that lists the valid names for that folder, along with the nearest match.
2. **Checks**, per file, against the file it replaces (or the kind's usual size if
   there is none yet):
   - Figures and dragons: square, at least 1024 px, with transparency. Missing
     transparency is an error: the figure would draw as a box.
   - Backdrops, journeys, lairs and roads: same orientation, and an aspect ratio within
     10% of the current file. Outside that range is a warning, since the game crops to
     fill (cover) and a different shape loses more of the edges.
   - Rigs: a valid SVG that has a `head` layer.
3. **Preview.** A table of every file: its slot, old size → new size, and any warnings.
   You confirm the whole set, or pick which files to take.
4. **Apply.** Copy, re-import (`godot --headless --import`), run
   `tools/split_rig.py` for rigs (and remake the app icon if the rig is the icon's
   dragon), then run the matching tests (`unit art creature`, `ui marks play`).
   Afterwards the staged files move to `art/staging/.imported/<date-time>/`, so the
   staging folder is empty again and nothing is lost.
5. `git diff --stat` of `art/` is shown at the end. Nothing is committed.

**Update app icon.** Choose a dragon (the current icon's dragon is preselected), run
`tools/make_app_icon.gd -- <dragon>`, and render a contact sheet of every variant to
`build/icon-preview.png`. `make_app_icon.gd` gets Grimroch as its default when it is
given no argument.

### 3. Install on device

A menu of `scripts/install.sh`'s targets (Android, iOS, Web, All), run as they are today.
The console shows the script's OK, SKIP and FAIL lines.

### 4. Test & run

- Run the game (`godot --path .`).
- Tests: Quick, Full, Unit (multi-select of the areas in CLAUDE.md's "Unit tests by
  area" table), UI walks (multi-select of the walks). Each calls `tools/test.sh` with
  those arguments.
- Screenshot matrix (`tools/shot.gd` into `build/screenshots/matrix`).

### 5. Regenerate data

`tools/gen_cards.py data/cards.json` and `tools/gen_icons.py`, each followed by the unit
tests CLAUDE.md lists for card data.

## Credentials and preflight

Credentials are read from the git-ignored `.env` (which already holds `HF_TOKEN`). New
keys:

| Key | For |
|---|---|
| `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_PASSWORD` | Signing Android release builds |
| `PLAY_SERVICE_ACCOUNT_JSON`, `PLAY_TRACK` (optional, default `internal`) | Uploading to Google Play |
| `IOS_PROVISIONING_PROFILE_UUID` | Signing iOS release builds |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` | Uploading to TestFlight |

`.env.example` is checked in with every key, empty, each with a comment that says where
to get it.

Each check states what failed, why it matters, and the exact next step. For example:

```
FAIL  Android keystore
      ANDROID_KEYSTORE_PATH is not set in .env.
      Release builds must be signed with the same key forever; Play rejects updates signed
      with another. Create one with:
        keytool -genkeypair -v -keystore etchinstone-release.keystore -alias etchinstone \
          -keyalg RSA -keysize 2048 -validity 10000
      then set ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_ALIAS and ANDROID_KEYSTORE_PASSWORD.
```

| Platform | Checks |
|---|---|
| All | `godot` on PATH and at 4.7.2; export templates installed for that version |
| Android | SDK and JDK 17 found; the Gradle build template installed; the keystore file exists and `keytool -list` opens it with that alias and password |
| Android upload | The service-account JSON exists and parses; a dry request reaches the app's edit endpoint |
| iOS | Running on macOS; `xcodebuild` present; the profile UUID is installed under `~/Library/MobileDevice/Provisioning Profiles` and has not expired; a distribution identity is in the keychain (`security find-identity -p codesigning`) |
| iOS upload | The key ID, issuer and `.p8` are set and the `.p8` exists |
| Web | None beyond All |

A keystore, certificate or key is never printed, logged or copied into `build/`.

## Structure

```
scripts/etch                  launcher: uv run --script tools/console/main.py "$@"
tools/console/
  main.py                     the menu tree; uv script header with its dependencies
  menu.py                     arrow-key menus (questionary), and the plain fallback
  run.py                      runs commands, tees their output to a log, reports OK/FAIL
  env.py                      reads .env
  preflight.py                every check, each returning (ok, title, explanation)
  version.py                  reads, steps and writes the version and build number
  build.py                    release exports per platform
  publish.py                  Play upload, TestFlight upload, web placeholder
  art_import.py               staging: scan, clean names, check, preview, apply
  icon.py                     the icon branch
  test_console.py             the console's own unit tests (pytest)
tools/art_slots.gd            prints art.gd's names as JSON
```

Every menu item can also be run directly, without the menus (`scripts/etch build android
ios --step patch --upload`, `scripts/etch art import --yes`, `scripts/etch icon grimroch`),
and the menu just builds those same calls. When the terminal is not interactive (piped,
or CI), the console refuses to show menus and prints the direct form instead.

## Error handling

- A failed step stops its branch, names the log file, and returns to the menu. The
  console itself never exits on a failure.
- Release builds never leave a half-bumped version: the version files are restored if
  any build fails.
- The art import changes nothing until it is confirmed. If a copy fails partway, the
  files already copied are listed so `git checkout -- art/` can undo them.
- Ctrl+C at a menu goes back a level; at the top it quits.

## Testing

- `tools/console/test_console.py` (pytest, run with `uv run`): name cleaning and
  matching, the per-kind checks against small generated images, version stepping and
  writing to copies of `project.godot` and `export_presets.cfg`, `.env` parsing, and each
  preflight check's failure message with a fake environment.
- The direct (non-menu) commands are what the tests call, so the menu layer stays thin.
- Manual: one pass of each branch from the menus, on Windows and on the Mac.

## Out of scope

- Web upload (placeholder only), and a Windows desktop release.
- Store listings, screenshots for the stores, and release notes.
- Creating keystores, certificates or profiles: the console says how, but does not do it.
- Generating art (ComfyUI); the console starts from finished exports.

## Success criteria

- Every chore listed above can be done from `scripts/etch` without remembering a command.
- With credentials in place, one run of Build & publish produces signed `.aab`, `.apk`
  and `.ipa` files and uploads them. Without them, it stops before building, with one
  message per missing piece that says how to fix it.
- An Illustrator export dropped into the right staging folder reaches the game, is
  checked, and is tested, with one confirmation.
