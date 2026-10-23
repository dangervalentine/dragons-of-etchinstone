# Implementation Plan: Developer Console

**Spec**: [spec.md](spec.md) · **Created**: 2026-10-22

**Goal:** `scripts/etch`, an arrow-key console for builds, uploads, art, tests and data.

**Architecture:** A Python package in `tools/console/`, run by `uv run --script` with
its dependencies declared in `main.py`. Every action is a plain function with arguments
that `argparse` calls directly. The menus only gather those arguments, so the tests call
the same functions the menus do.

**Tech stack:** Python 3.12 (managed by uv), questionary (menus), Pillow (art checks),
google-api-python-client + google-auth (Play upload), pytest. Godot 4.7.2 CLI for
exports and imports; `xcrun altool` for TestFlight.

## Findings that shape the plan (from Godot 4.7 source)

- **Signing variables.** Android release signing reads `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`,
  `_USER` and `_PASSWORD` when the preset leaves them empty. iOS reads
  `GODOT_APPLE_PLATFORM_PROVISIONING_PROFILE_UUID_RELEASE`, except that 4.7.2 looks up
  the *debug* variable for the release UUID (`editor_export_platform_apple_embedded.cpp`
  line 164), so the build sets both.
- **Presets.** The existing `iOS` and `Web` presets serve release exports as they are:
  `--export-release` uses `export_method_release` (App Store) and
  `code_sign_identity_release` (Apple Distribution) by default. So the spec's three
  release presets come down to one, `Android Release`, which uses the Gradle build with
  `export_format=1` (AAB). The signed APK comes from `--export-release Android` on the
  existing preset.
- **Android build template.** `--install-android-build-template` installs it on the first
  Gradle export. `android/` is git-ignored.
- **Version fields.** The version is `application/config/version` in `project.godot`.
  Android's `version/name` and iOS's `short_version` fall back to it when empty. The build
  number goes in `version/code` (both Android presets) and `application/version` (iOS).

## Files

| File | Responsibility |
|---|---|
| `scripts/etch`, `scripts/etch.cmd` | Launchers for sh and for cmd/PowerShell |
| `tools/console/main.py` | uv header, `argparse` commands, the menu tree |
| `tools/console/menu.py` | `choose`, `choose_many`, `confirm`, `ask`: questionary, or numbered input when it cannot run |
| `tools/console/run.py` | `ROOT`, `run()` (to a log or the terminal), `godot()`, `Failure` |
| `tools/console/env.py` | `load_env()` from `.env`, never logging values |
| `tools/console/cfg.py` | Read and set keys in Godot's `.cfg`/`project.godot` text, find a preset's options section by name |
| `tools/console/version.py` | `Version`: read, `next(step)`, `write()`, `restore()` |
| `tools/console/preflight.py` | `Check` results, `checks_for(platforms, upload)`, `report()` |
| `tools/console/build.py` | `build_android/ios/web(version, out)` returning artifact paths |
| `tools/console/publish.py` | `upload_android(aab, track)`, `upload_ios(ipa)`, `upload_web()` (placeholder) |
| `tools/console/art_import.py` | `slots()`, `clean_name()`, `scan()`, `check()`, `apply()` |
| `tools/console/test_console.py` | pytest suite |
| `tools/art_slots.gd` | Prints `art.gd`'s names as JSON |
| `tools/make_app_icon.gd` | Grimroch by default when given no dragon |
| `export_presets.cfg` | Adds `Android Release` (`preset.5`) |
| `.env.example`, `.gitignore`, `CLAUDE.md` | Credentials template, ignores (`art/staging/`, `android/`), docs |

## Tasks

1. **Core helpers** (`run.py`, `env.py`, `cfg.py`) with tests for `.env` parsing and
   cfg key setting (replace, insert, new section key, preset lookup by name).
2. **Version** with tests: missing version reads as 0.0.0; each step; build number is the
   highest of the presets' plus one; write then restore returns the exact text.
3. **Preflight** with tests using a fake environment: each check's failure names the
   missing piece and the fix; checks for a platform not chosen are not run.
4. **Release preset + build**: add `Android Release` to `export_presets.cfg`, then the
   build functions. Verify that a build without a keystore fails at preflight, before any
   version change.
5. **Publish**: Play edit → upload bundle → track → commit; altool with an API key; the
   web placeholder.
6. **Art import** with tests: name cleaning (`antler-horror-126-01` → `antler-horror`,
   `grimroch-140-full-01` → `grimroch-full`), unknown names with suggestions, figure
   checks (square, size, alpha), scene aspect warnings, rig head layer, apply moving the
   staged files to `.imported/`. `tools/art_slots.gd` for the names.
7. **Icon branch**: dragon menu, `make_app_icon.gd`, contact sheet to
   `build/icon-preview.png`.
8. **Menus and the other branches** (install, test & run, data) in `main.py`; launchers.
9. **Docs**: `.env.example`, `.gitignore`, the CLAUDE.md commands section.
10. **Verify**: pytest suite; `scripts/etch build android --step build` with no keystore
    (expect the preflight report, unchanged version files); `scripts/etch build web`
    (expect a zip); an art import round trip with a re-staged existing picture;
    `scripts/etch icon`; the menus by hand.

Tests run with `uv run --with pytest --with pillow pytest tools/console -q`.
